const std = @import("std");
const api = @import("root.zig");
const format = @import("formats.zig");
const BitReader = @import("BitReader.zig");

const max_channels = 8;
const slice_len = 20;
const slices_per_frame = 256;
const frame_len = slices_per_frame * slice_len;
const lms_len = 4;
const magic = 0x716f6166; // 'qoaf'

const quant_table = [17]i32{
    7, 7, 7, 5, 5, 3, 3, 1, // -8..-1
    0, // 0
    0, 2, 2, 4, 4, 6, 6, 6, // 1..8
};

const scalefactor_table = [16]i32{
    1,    7,    21,   45,   84,  138,
    211,  304,  421,  562,  731, 928,
    1157, 1419, 1715, 2048,
};

const reciprocal_table = [16]i32{
    65536, 9363, 3121, 1457, 781, 475,
    311,   216,  156,  117,  90,  71,
    57,    47,   39,   32,
};

const dequant_table = [16][8]i16{
    .{ 1, -1, 3, -3, 5, -5, 7, -7 },
    .{ 5, -5, 18, -18, 32, -32, 49, -49 },
    .{ 16, -16, 53, -53, 95, -95, 147, -147 },
    .{ 34, -34, 113, -113, 203, -203, 315, -315 },
    .{ 63, -63, 210, -210, 378, -378, 588, -588 },
    .{ 104, -104, 345, -345, 621, -621, 966, -966 },
    .{ 158, -158, 528, -528, 950, -950, 1477, -1477 },
    .{ 228, -228, 760, -760, 1368, -1368, 2128, -2128 },
    .{ 316, -316, 1053, -1053, 1895, -1895, 2947, -2947 },
    .{ 422, -422, 1405, -1405, 2529, -2529, 3934, -3934 },
    .{ 548, -548, 1828, -1828, 3290, -3290, 5117, -5117 },
    .{ 696, -696, 2320, -2320, 4176, -4176, 6496, -6496 },
    .{ 868, -868, 2893, -2893, 5207, -5207, 8099, -8099 },
    .{ 1064, -1064, 3548, -3548, 6386, -6386, 9933, -9933 },
    .{ 1286, -1286, 4288, -4288, 7718, -7718, 12005, -12005 },
    .{ 1536, -1536, 5120, -5120, 9216, -9216, 14336, -14336 },
};

pub const Lms = struct {
    history: [lms_len]i32,
    weights: [lms_len]i32,

    fn predict(self: *Lms) i32 {
        var prediction: i32 = 0;
        for (0..lms_len) |i| {
            const mul = @mulWithOverflow(self.weights[i], self.history[i]);
            const sum = @addWithOverflow(prediction, mul[0]);
            prediction = sum[0];
        }
        return prediction >> 13;
    }
    fn update(self: *Lms, sample: i16, residual: i16) void {
        const delta: i32 = @as(i32, residual) >> 4;
        for (0..lms_len) |i| {
            self.weights[i] += if (self.history[i] < 0) -delta else delta;
        }
        for (0..lms_len - 1) |i| {
            self.history[i] = self.history[i + 1];
        }
        self.history[lms_len - 1] = @intCast(sample);
    }
};

fn div(v: i32, scalefactor: i32) i32 {
    const reciprocal: i32 = reciprocal_table[@as(usize, @intCast(scalefactor))];
    const n64: i64 = (@as(i64, v) * @as(i64, reciprocal) + (@as(i64, 1) << 15)) >> 16;
    const n: i32 = @intCast(n64);
    const sgn_v: i32 = @as(i32, @intFromBool(v > 0)) - @as(i32, @intFromBool(v < 0));
    const sgn_n: i32 = @as(i32, @intFromBool(n > 0)) - @as(i32, @intFromBool(n < 0));
    return n + sgn_v - sgn_n; // round away from 0
}

fn clamp(v: i32, min: i32, max: i32) i32 {
    if (v < min) return min;
    if (v > max) return max;
    return v;
}
// This specialized clamp function for the signed 16 bit range improves decode
// performance quite a bit. The extra if() statement works nicely with the CPUs
// branch prediction as this branch is rarely taken.
fn clamp_s16(v: i32) i16 {
    if (v <= -32768) return -32768;
    if (v >= 32767) return 32767;
    return @truncate(v);
}

pub const Decoder = struct {
    channels: u32,
    sample_rate: u32,
    sample_count: u32,
    lms: [max_channels]Lms = undefined,

    fn decodeFrame(self: *Decoder, bytes: []const u8, target_size: usize, samples: []i16) !struct { frame_size: usize, frame_length: usize } {
        if (target_size < 8 * lms_len * 4 * self.channels) {
            return error.FrameTooSmall;
        }

        var p: usize = 0;
        var frame_size: usize = 0;
        // read and verify header
        const frame_header = std.mem.readInt(u64, bytes[0..8], .big);
        p += 8;
        const channels: u32 = @intCast((frame_header >> 56) & 0x000000FF);
        const sample_rate: u32 = @intCast((frame_header >> 32) & 0x00FFFFFF);
        const sample_count: u32 = @intCast((frame_header >> 16) & 0x0000FFFF);
        frame_size = @intCast(frame_header & 0x0000FFFF);

        const data_size = frame_size - 8 - (lms_len * 4 * self.channels);
        const num_slices = data_size / 8;
        const max_total_samples = num_slices * slices_per_frame;

        if (channels != self.channels or
            sample_rate != self.sample_rate or
            frame_size > target_size or
            (sample_count * channels) > max_total_samples)
        {
            return error.InvalidFrameHeader;
        }

        // Read the LMS state: 4 x 2 bytes history and 4 x 2 bytes weights per channel
        for (0..self.channels) |c| {
            const history_ptr = @as(*const [8]u8, @ptrCast(&bytes[p]));
            const weights_ptr = @as(*const [8]u8, @ptrCast(&bytes[p + 8]));
            var history = std.mem.readInt(u64, history_ptr, .big);
            var weights = std.mem.readInt(u64, weights_ptr, .big);
            p += 16;

            for (0..lms_len) |i| {
                const h_u16: u16 = @truncate(history >> 48);
                const h_i16: i16 = @bitCast(h_u16);
                self.lms[c].history[i] = @intCast(h_i16);
                history <<= 16;
                const w_u16: u16 = @truncate(weights >> 48);
                const w_i16: i16 = @bitCast(w_u16);
                self.lms[c].weights[i] = @intCast(w_i16);
                weights <<= 16;
            }
        }

        // Decode all slices for all channels in this frame
        var sample_index: usize = 0;
        while (sample_index < sample_count) : (sample_index += slice_len) {
            for (0..channels) |c| {
                const slice_ptr = @as(*const [8]u8, @ptrCast(&bytes[p]));
                var slice = std.mem.readInt(u64, slice_ptr, .big);
                p += 8;

                const scalefactor = (slice >> 60) & 0xF;
                slice <<= 4;
                const slice_start = (sample_index * channels) + c;
                const slice_end = @as(u32, @intCast(clamp(@intCast(sample_index + slice_len), 0, @intCast(sample_count)))) * channels + c;

                var si: usize = slice_start;
                while (si < slice_end) : (si += channels) {
                    const predicted = self.lms[c].predict();
                    const quantized: usize = @intCast((slice >> 61) & 0x7);
                    const dequantized = dequant_table[scalefactor][quantized];
                    const reconstructed = clamp_s16(predicted + dequantized);

                    samples[si] = reconstructed;
                    slice <<= 3;

                    self.lms[c].update(reconstructed, dequantized);
                }
            }
        }

        return .{ .frame_size = p, .frame_length = sample_count };
    }
};

const FileHeader = struct {
    channels: u32,
    sample_rate: u32,
    total_frames: usize,
};

fn readByte(br: *BitReader) !u8 {
    const value = br.readBits(8) catch |err| switch (err) {
        error.EndOfStream => return error.InvalidFormat,
        else => return err,
    };
    return @intCast(value);
}

fn readU32BE(br: *BitReader) !u32 {
    br.alignToByte();
    var value: u32 = 0;
    var i: usize = 0;
    while (i < 4) : (i += 1) {
        value = (value << 8) | @as(u32, try readByte(br));
    }
    return value;
}

fn readU64BE(br: *BitReader) !u64 {
    br.alignToByte();
    var value: u64 = 0;
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        value = (value << 8) | @as(u64, try readByte(br));
    }
    return value;
}

fn readBytes(br: *BitReader, dst: []u8) !void {
    br.alignToByte();
    for (dst) |*byte| {
        byte.* = try readByte(br);
    }
}

fn readBytesExact(br: *BitReader, dst: []u8) !usize {
    br.alignToByte();
    if (dst.len == 0) return 0;

    var index: usize = 0;
    while (index < dst.len) : (index += 1) {
        const value = br.readBits(8) catch |err| switch (err) {
            error.EndOfStream => return index,
            else => return err,
        };
        dst[index] = @intCast(value);
    }
    return dst.len;
}

fn parseHeader(br: *BitReader) !FileHeader {
    br.alignToByte();
    const file_magic = try readU32BE(br);
    if (file_magic != magic) return error.InvalidFormat;

    const total_frames_u32 = try readU32BE(br);
    if (total_frames_u32 == 0) return error.InvalidFormat;

    const frame_header = try readU64BE(br);
    const channels: u32 = @intCast((frame_header >> 56) & 0x000000FF);
    const sample_rate: u32 = @intCast((frame_header >> 32) & 0x00FFFFFF);

    if (channels == 0 or channels > max_channels) return error.InvalidFormat;
    if (sample_rate == 0) return error.InvalidFormat;

    return .{
        .channels = channels,
        .sample_rate = sample_rate,
        .total_frames = @as(usize, total_frames_u32),
    };
}

const QoaContext = struct {
    allocator: std.mem.Allocator,
    br: *BitReader,
    decoder: Decoder,
    samples: []i16,
    frame_buf: []u8,
    sample_offset: usize,
    sample_count: usize,
    frames_decoded: usize,
    reached_eof: bool,
};

fn channelCount(decoder: *const Decoder) usize {
    return @as(usize, @intCast(decoder.channels));
}

fn maxFrameSize(channels: u32) usize {
    return 8 + (lms_len * 4 * @as(usize, @intCast(channels))) + (8 * slices_per_frame * @as(usize, @intCast(channels)));
}

fn decodeNextFrame(ctx: *QoaContext) !void {
    if (ctx.reached_eof) {
        ctx.sample_count = 0;
        return;
    }

    if (ctx.decoder.sample_count != 0) {
        const total_frames = @as(usize, ctx.decoder.sample_count);
        if (ctx.frames_decoded >= total_frames) {
            ctx.sample_count = 0;
            ctx.reached_eof = true;
            return;
        }
    }

    const header_slice = ctx.frame_buf[0..8];
    const header_read = try readBytesExact(ctx.br, header_slice);
    if (header_read == 0) {
        ctx.sample_count = 0;
        ctx.reached_eof = true;
        return;
    }
    const frame_header = std.mem.readInt(u64, ctx.frame_buf[0..8], .big);
    const channels: u32 = @intCast((frame_header >> 56) & 0x000000FF);
    const frame_size: usize = @intCast(frame_header & 0x0000FFFF);

    if (channels != ctx.decoder.channels) return error.InvalidFormat;
    if (frame_size < 8 or frame_size > ctx.frame_buf.len) return error.InvalidFormat;

    if (frame_size > ctx.frame_buf.len) return error.InvalidFormat;
    const payload_slice = ctx.frame_buf[8..frame_size];
    const payload_read = try readBytesExact(ctx.br, payload_slice);
    if (payload_read < payload_slice.len) {
        ctx.sample_count = 0;
        ctx.reached_eof = true;
        return;
    }

    const result = ctx.decoder.decodeFrame(ctx.frame_buf[0..frame_size], frame_size, ctx.samples) catch |err| switch (err) {
        error.FrameTooSmall, error.InvalidFrameHeader => return error.InvalidFormat,
    };

    const channel_count = channelCount(&ctx.decoder);
    var frames_from_result = result.frame_length;
    if (ctx.decoder.sample_count != 0) {
        const remaining = @as(usize, ctx.decoder.sample_count) - ctx.frames_decoded;
        if (frames_from_result > remaining) frames_from_result = remaining;
    }

    ctx.sample_count = frames_from_result * channel_count;
    ctx.sample_offset = 0;
    ctx.frames_decoded += frames_from_result;
}

fn decoderRead(decoder: *format.Decoder, dst: []f32) !usize {
    const ctx: *QoaContext = @ptrCast(@alignCast(decoder.context));
    if (dst.len == 0) return 0;

    var written: usize = 0;
    while (written < dst.len) {
        if (ctx.sample_offset < ctx.sample_count) {
            const available = ctx.sample_count - ctx.sample_offset;
            const to_copy = @min(available, dst.len - written);
            // Convert i16 samples to f32
            for (ctx.samples[ctx.sample_offset .. ctx.sample_offset + to_copy], 0..) |s, i| {
                dst[written + i] = @as(f32, @floatFromInt(s)) / 32768.0;
            }
            ctx.sample_offset += to_copy;
            written += to_copy;
            continue;
        }

        try decodeNextFrame(ctx);
        if (ctx.sample_count == 0) break;
    }

    return written;
}

fn decoderDeinit(decoder: *format.Decoder, allocator: std.mem.Allocator) void {
    const ctx: *QoaContext = @ptrCast(@alignCast(decoder.context));

    ctx.br.deinit();
    allocator.destroy(ctx.br);
    allocator.free(ctx.samples);
    allocator.free(ctx.frame_buf);
    allocator.destroy(ctx);
    allocator.destroy(decoder);
}

const decoder_vtable = format.DecoderVTable{
    .read = decoderRead,
    .deinit = decoderDeinit,
};

fn probe(br: *BitReader) !bool {
    const start = br.tell();
    defer br.seekTo(start);

    _ = parseHeader(br) catch return false;
    return true;
}

fn info(br: *BitReader) !api.AudioInfo {
    const start = br.tell();
    defer br.seekTo(start);

    const header = try parseHeader(br);
    const duration = if (header.sample_rate == 0)
        0.0
    else
        @as(f64, @floatFromInt(header.total_frames)) / @as(f64, @floatFromInt(header.sample_rate));

    return .{
        .sample_rate = header.sample_rate,
        .channels = @intCast(header.channels),
        .sample_type = .f32,
        .total_frames = header.total_frames,
        .duration_seconds = duration,
    };
}

pub fn open(allocator: std.mem.Allocator, br: *BitReader) !*format.Decoder {
    const header = parseHeader(br) catch |err| {
        br.seekTo(0);
        return err;
    };

    br.seekTo(0);
    _ = try readU32BE(br); // magic
    _ = try readU32BE(br); // total frames (already validated)

    const channel_count = channelCount(&Decoder{ .channels = header.channels, .sample_rate = header.sample_rate, .sample_count = @intCast(header.total_frames) });
    const samples_per_frame = slices_per_frame * slice_len * channel_count;
    const sample_buf = try allocator.alloc(i16, samples_per_frame);
    errdefer allocator.free(sample_buf);

    const frame_buf_len = maxFrameSize(header.channels);
    const frame_buf = try allocator.alloc(u8, frame_buf_len);
    errdefer allocator.free(frame_buf);

    const ctx = try allocator.create(QoaContext);
    errdefer allocator.destroy(ctx);

    ctx.* = .{
        .allocator = allocator,
        .br = br,
        .decoder = .{
            .channels = header.channels,
            .sample_rate = header.sample_rate,
            .sample_count = @intCast(header.total_frames),
        },
        .samples = sample_buf,
        .frame_buf = frame_buf,
        .sample_offset = 0,
        .sample_count = 0,
        .frames_decoded = 0,
        .reached_eof = false,
    };

    const decoder = try allocator.create(format.Decoder);
    errdefer allocator.destroy(decoder);

    const duration = if (header.sample_rate == 0)
        0.0
    else
        @as(f64, @floatFromInt(header.total_frames)) / @as(f64, @floatFromInt(header.sample_rate));

    decoder.* = .{
        .vtable = &decoder_vtable,
        .context = ctx,
        .info = .{
            .sample_rate = header.sample_rate,
            .channels = @intCast(header.channels),
            .sample_type = .f32,
            .total_frames = header.total_frames,
            .duration_seconds = duration,
        },
        .id = .qoa,
    };

    return decoder;
}

pub const vtable = format.VTable{
    .id = .qoa,
    .probe = probe,
    .info = info,
    .open = open,
};

fn writeAllConst(writer: *std.Io.Writer, src: []const u8) api.WriteError!void {
    var remaining = src;
    while (remaining.len != 0) {
        const dst = try writer.writableSliceGreedy(1);
        if (dst.len == 0) return error.WriteFailed;
        const n: usize = @min(dst.len, remaining.len);
        std.mem.copyForwards(u8, dst[0..n], remaining[0..n]);
        writer.advance(n);
        remaining = remaining[n..];
    }
}

fn writeU64BE(writer: *std.Io.Writer, v: u64) api.WriteError!void {
    var buf: [8]u8 = undefined;
    buf[0] = @truncate(v >> 56);
    buf[1] = @truncate(v >> 48);
    buf[2] = @truncate(v >> 40);
    buf[3] = @truncate(v >> 32);
    buf[4] = @truncate(v >> 24);
    buf[5] = @truncate(v >> 16);
    buf[6] = @truncate(v >> 8);
    buf[7] = @truncate(v >> 0);
    try writeAllConst(writer, &buf);
}

fn fileWriteAllConst(file: std.fs.File, src: []const u8) api.WriteError!void {
    file.writeAll(src) catch return error.WriteFailed;
}

fn fileWriteU64BE(file: std.fs.File, v: u64) api.WriteError!void {
    var buf: [8]u8 = undefined;
    buf[0] = @truncate(v >> 56);
    buf[1] = @truncate(v >> 48);
    buf[2] = @truncate(v >> 40);
    buf[3] = @truncate(v >> 32);
    buf[4] = @truncate(v >> 24);
    buf[5] = @truncate(v >> 16);
    buf[6] = @truncate(v >> 8);
    buf[7] = @truncate(v >> 0);
    try fileWriteAllConst(file, &buf);
}

pub fn encodeToFile(file: std.fs.File, audio: *const api.Audio) api.WriteError!void {
    if (audio.params.sample_type != .f32) return error.UnsupportedBitDepth;
    if (audio.params.channels == 0 or audio.params.channels > max_channels) return error.UnsupportedChannelCount;
    if (audio.params.sample_rate == 0 or audio.params.sample_rate > 0x00FF_FFFF) return error.UnsupportedSampleRate;

    const channels: usize = audio.params.channels;
    const total_frames: usize = audio.frameCount();
    if (total_frames > std.math.maxInt(u32)) return error.Unsupported;

    var lms: [max_channels]Lms = undefined;
    for (0..channels) |c| {
        for (0..lms_len) |i| lms[c].history[i] = 0;
        lms[c].weights[0] = 0;
        lms[c].weights[1] = 0;
        lms[c].weights[2] = -(@as(i16, 1) << 13);
        lms[c].weights[3] = (@as(i16, 1) << 14);
    }
    const file_header: u64 = (@as(u64, magic) << 32) | @as(u64, @intCast(total_frames));
    try fileWriteU64BE(file, file_header);

    var frame_start: usize = 0;
    while (frame_start < total_frames) : (frame_start += frame_len) {
        var prev_scalefactor: [max_channels]i32 = [_]i32{0} ** max_channels;
        const remaining: usize = total_frames - frame_start;
        const this_frame_len: usize = if (remaining < frame_len) remaining else frame_len;
        const slices: usize = (this_frame_len + slice_len - 1) / slice_len;
        const frame_size: usize = 8 + (lms_len * 4 * channels) + (8 * slices * channels);

        var fh: u64 = 0;
        fh |= (@as(u64, @intCast(channels)) & 0xff) << 56;
        fh |= (@as(u64, audio.params.sample_rate) & 0x00ff_ffff) << 32;
        fh |= (@as(u64, @intCast(this_frame_len)) & 0x0000_ffff) << 16;
        fh |= (@as(u64, @intCast(frame_size)) & 0x0000_ffff);
        try fileWriteU64BE(file, fh);

        for (0..channels) |c| {
            var history_be: u64 = 0;
            var weights_be: u64 = 0;
            for (0..lms_len) |i| {
                const h: u16 = @bitCast(@as(i16, @truncate(lms[c].history[i])));
                const w: u16 = @bitCast(@as(i16, @truncate(lms[c].weights[i])));
                history_be = (history_be << 16) | (@as(u64, h) & 0xffff);
                weights_be = (weights_be << 16) | (@as(u64, w) & 0xffff);
            }
            try fileWriteU64BE(file, history_be);
            try fileWriteU64BE(file, weights_be);
        }

        var sample_index: usize = 0;
        while (sample_index < this_frame_len) : (sample_index += slice_len) {
            for (0..channels) |c| {
                const slice_actual_len_i32: i32 = @intCast(@min(slice_len, this_frame_len - sample_index));
                const slice_len_i32: i32 = slice_actual_len_i32;

                var best_rank: u64 = std.math.maxInt(u64);
                var best_slice: u64 = 0;
                var best_lms: Lms = lms[c];
                var best_scalefactor: i32 = 0;

                var sfi: i32 = 0;
                while (sfi < 16) : (sfi += 1) {
                    const scalefactor: i32 = (sfi + prev_scalefactor[c]) & 15;
                    var state = lms[c];
                    var slice_bits: u64 = @intCast(@as(u4, @intCast(scalefactor)));
                    var current_rank: u64 = 0;
                    var current_error: u64 = 0;
                    var k: i32 = 0;
                    while (k < slice_len_i32) : (k += 1) {
                        const f: usize = frame_start + sample_index + @as(usize, @intCast(k));
                        if (f >= frame_start + this_frame_len) break;
                        const sample_pos: usize = f * channels + c;
                        const sample: i32 = @intCast(readSampleAsI16(audio, sample_pos));
                        const predicted: i32 = state.predict();
                        const residual: i32 = sample - predicted;
                        const scaled: i32 = div(residual, scalefactor);
                        const clamped: i32 = clamp(scaled, -8, 8);
                        const quantized: i32 = quant_table[@as(usize, @intCast(clamped + 8))];
                        const dequantized_i16: i16 = dequant_table[@as(usize, @intCast(scalefactor))][@as(usize, @intCast(quantized))];
                        const dequantized: i32 = @intCast(dequantized_i16);
                        const reconstructed_i16: i16 = clamp_s16(predicted + dequantized);
                        const reconstructed: i32 = @intCast(reconstructed_i16);
                        var wp: i32 =
                            @as(i32, @intCast(state.weights[0])) * @as(i32, @intCast(state.weights[0])) +
                            @as(i32, @intCast(state.weights[1])) * @as(i32, @intCast(state.weights[1])) +
                            @as(i32, @intCast(state.weights[2])) * @as(i32, @intCast(state.weights[2])) +
                            @as(i32, @intCast(state.weights[3])) * @as(i32, @intCast(state.weights[3]));
                        wp = (wp >> 18) - 0x8ff;
                        if (wp < 0) wp = 0;
                        const err_i: i64 = @as(i64, sample) - @as(i64, reconstructed);
                        const err_sq: u64 = @intCast(err_i * err_i);
                        const pen_sq: u64 = @intCast(@as(i64, wp) * @as(i64, wp));
                        current_rank += err_sq + pen_sq;
                        current_error += err_sq;
                        if (current_error >= best_rank) break;
                        state.update(@intCast(reconstructed), @intCast(dequantized));
                        slice_bits = (slice_bits << 3) | @as(u64, @intCast(@as(u3, @intCast(quantized))));
                    }
                    if (current_error < best_rank) {
                        best_rank = current_error;
                        best_slice = slice_bits;
                        best_lms = state;
                        best_scalefactor = scalefactor;
                    }
                }
                prev_scalefactor[c] = best_scalefactor;
                lms[c] = best_lms;
                const pad_samples_i32: i32 = slice_len - slice_len_i32;
                if (pad_samples_i32 > 0) {
                    const shift: u6 = @as(u6, @intCast(@as(u32, @intCast(pad_samples_i32 * 3))));
                    best_slice <<= shift;
                }
                try fileWriteU64BE(file, best_slice);
            }
        }
    }
}

fn readSampleAsI16(audio: *const api.Audio, sample_index: usize) i16 {
    const byte_index = sample_index * 4;
    const p = @as(*const [4]u8, @ptrCast(&audio.data[byte_index]));
    const f: f32 = @bitCast(std.mem.readInt(u32, p, .little));
    // Convert f32 to i16 with clamping
    const scaled = f * 32767.0;
    const clamped = @max(-32768.0, @min(32767.0, scaled));
    return @intFromFloat(clamped);
}

pub fn encode(writer: *std.Io.Writer, audio: *const api.Audio) api.WriteError!void {
    if (audio.params.sample_type != .f32) return error.UnsupportedBitDepth;
    if (audio.params.channels == 0 or audio.params.channels > max_channels) return error.UnsupportedChannelCount;
    if (audio.params.sample_rate == 0 or audio.params.sample_rate > 0x00FF_FFFF) return error.UnsupportedSampleRate;

    const channels: usize = audio.params.channels;
    const total_frames: usize = audio.frameCount();
    if (total_frames > std.math.maxInt(u32)) return error.Unsupported;

    // Initialize LMS per channel
    var lms: [max_channels]Lms = undefined;
    for (0..channels) |c| {
        for (0..lms_len) |i| {
            lms[c].history[i] = 0;
        }
        lms[c].weights[0] = 0;
        lms[c].weights[1] = 0;
        lms[c].weights[2] = -(@as(i16, 1) << 13);
        lms[c].weights[3] = (@as(i16, 1) << 14);
    }

    // File header
    const file_header: u64 = (@as(u64, magic) << 32) | @as(u64, @intCast(total_frames));
    try writeU64BE(writer, file_header);

    var frame_start: usize = 0;
    while (frame_start < total_frames) : (frame_start += frame_len) {
        var prev_scalefactor: [max_channels]i32 = [_]i32{0} ** max_channels;
        const remaining: usize = total_frames - frame_start;
        const this_frame_len: usize = if (remaining < frame_len) remaining else frame_len;
        const slices: usize = (this_frame_len + slice_len - 1) / slice_len;
        const frame_size: usize = 8 + (lms_len * 4 * channels) + (8 * slices * channels);

        // Frame header: channels (8), samplerate (24), frame_len (16), frame_size (16)
        var fh: u64 = 0;
        fh |= (@as(u64, @intCast(channels)) & 0xff) << 56;
        fh |= (@as(u64, audio.params.sample_rate) & 0x00ff_ffff) << 32;
        fh |= (@as(u64, @intCast(this_frame_len)) & 0x0000_ffff) << 16;
        fh |= (@as(u64, @intCast(frame_size)) & 0x0000_ffff);
        try writeU64BE(writer, fh);

        // Write current LMS state per channel
        for (0..channels) |c| {
            var history_be: u64 = 0;
            var weights_be: u64 = 0;
            for (0..lms_len) |i| {
                const h: u16 = @bitCast(@as(i16, @truncate(lms[c].history[i])));
                const w: u16 = @bitCast(@as(i16, @truncate(lms[c].weights[i])));
                history_be = (history_be << 16) | (@as(u64, h) & 0xffff);
                weights_be = (weights_be << 16) | (@as(u64, w) & 0xffff);
            }
            try writeU64BE(writer, history_be);
            try writeU64BE(writer, weights_be);
        }

        // Encode all slices for all channels
        var sample_index: usize = 0;
        while (sample_index < this_frame_len) : (sample_index += slice_len) {
            for (0..channels) |c| {
                const slice_actual_len_i32: i32 = @intCast(@min(slice_len, this_frame_len - sample_index));
                const slice_len_i32: i32 = slice_actual_len_i32;

                var best_rank: u64 = std.math.maxInt(u64);
                var best_slice: u64 = 0;
                var best_lms: Lms = lms[c];
                var best_scalefactor: i32 = 0;

                var sfi: i32 = 0;
                while (sfi < 16) : (sfi += 1) {
                    const scalefactor: i32 = (sfi + prev_scalefactor[c]) & (16 - 1);
                    var state = lms[c];
                    var slice_bits: u64 = @intCast(@as(u4, @intCast(scalefactor)));
                    var current_rank: u64 = 0;

                    var k: i32 = 0;
                    while (k < slice_len_i32) : (k += 1) {
                        const f: usize = frame_start + sample_index + @as(usize, @intCast(k));
                        if (f >= frame_start + this_frame_len) break;
                        const sample_pos: usize = f * channels + c;
                        const sample: i32 = @intCast(readSampleAsI16(audio, sample_pos));
                        const predicted: i32 = state.predict();
                        const residual: i32 = sample - predicted;
                        const scaled: i32 = div(residual, scalefactor);
                        const clamped: i32 = clamp(scaled, -8, 8);
                        const quantized: i32 = quant_table[@as(usize, @intCast(clamped + 8))];
                        const dequantized_i16: i16 = dequant_table[@as(usize, @intCast(scalefactor))][@as(usize, @intCast(quantized))];
                        const dequantized: i32 = @intCast(dequantized_i16);
                        const reconstructed_i16: i16 = clamp_s16(predicted + dequantized);
                        const reconstructed: i32 = @intCast(reconstructed_i16);

                        // penalty
                        var wp: i32 =
                            @as(i32, @intCast(state.weights[0])) * @as(i32, @intCast(state.weights[0])) +
                            @as(i32, @intCast(state.weights[1])) * @as(i32, @intCast(state.weights[1])) +
                            @as(i32, @intCast(state.weights[2])) * @as(i32, @intCast(state.weights[2])) +
                            @as(i32, @intCast(state.weights[3])) * @as(i32, @intCast(state.weights[3]));
                        wp = (wp >> 18) - 0x8ff;
                        if (wp < 0) wp = 0;

                        const err_i: i64 = @as(i64, sample) - @as(i64, reconstructed);
                        const err_sq: u64 = @intCast(err_i * err_i);
                        const pen_sq: u64 = @intCast(@as(i64, wp) * @as(i64, wp));
                        current_rank += err_sq + pen_sq;
                        if (current_rank > best_rank) break;

                        state.update(@intCast(reconstructed), @intCast(dequantized));
                        slice_bits = (slice_bits << 3) | @as(u64, @intCast(@as(u3, @intCast(quantized))));
                    }

                    if (current_rank < best_rank) {
                        best_rank = current_rank;
                        best_slice = slice_bits;
                        best_lms = state;
                        best_scalefactor = scalefactor;
                    }
                }

                prev_scalefactor[c] = best_scalefactor;
                lms[c] = best_lms;

                // pad remaining 3-bits for short slices in last frame
                const pad_samples_i32: i32 = slice_len - slice_len_i32;
                if (pad_samples_i32 > 0) {
                    const shift: u6 = @as(u6, @intCast(@as(u32, @intCast(pad_samples_i32 * 3))));
                    best_slice <<= shift;
                }
                try writeU64BE(writer, best_slice);
            }
        }
    }
}
