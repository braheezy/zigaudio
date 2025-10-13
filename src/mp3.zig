const std = @import("std");
const api = @import("root.zig");
const format = @import("formats.zig");
const BitReader = @import("BitReader.zig");
const frameheader = @import("mp3/frameheader.zig");
const frame_mod = @import("mp3/frame.zig");
const mp3_bits = @import("mp3/bits.zig");

const ArrayList = std.ArrayList;
const mem = std.mem;
const math = std.math;

const samples_per_frame: u64 = 1152;
const max_sync_scan_attempts: usize = 100_000;

const Mp3Info = struct {
    sample_rate: u32,
    channels: u8,
    total_frames: usize,
    total_samples: u64,
    duration_seconds: f64,
};

fn skipBits(br: *BitReader, bits: usize) !void {
    var remaining_bits = bits;
    while (remaining_bits > 0) {
        const chunk_bits = @min(remaining_bits, 0x1000 * 8);
        const enough = br.has(chunk_bits) catch |err| switch (err) {
            error.EndOfStream => false,
            else => return err,
        };
        if (!enough) return error.InvalidFormat;

        br.skip(chunk_bits);
        remaining_bits -= chunk_bits;
    }
}

fn skipBytes(br: *BitReader, bytes: usize) !void {
    const bits = math.mul(usize, bytes, 8) catch return error.InvalidFormat;
    try skipBits(br, bits);
}

inline fn skipOneByte(br: *BitReader) !void {
    try skipBits(br, 8);
}

fn skipId3(br: *BitReader) !void {
    br.alignToByte();
    if (!try br.has(80)) return;

    const peek = br.reader.peek(10) catch return;
    if (!(peek[0] == 'I' and peek[1] == 'D' and peek[2] == '3')) return;

    const version_major = peek[3];
    const flags = peek[5];
    const sz0: usize = @intCast(peek[6] & 0x7F);
    const sz1: usize = @intCast(peek[7] & 0x7F);
    const sz2: usize = @intCast(peek[8] & 0x7F);
    const sz3: usize = @intCast(peek[9] & 0x7F);
    const tag_size: usize = (sz0 << 21) | (sz1 << 14) | (sz2 << 7) | sz3;

    var total_skip: usize = 10 + tag_size;
    if (version_major == 4 and (flags & 0x10) != 0) total_skip += 10;

    if (br.file) |*file| {
        file.seekBy(@intCast(total_skip)) catch return error.InvalidFormat;
        br.reader.seek = 0;
        br.reader.end = 0;
        br.bit_index = 0;
        br.reader.fillMore() catch |err| switch (err) {
            error.EndOfStream => return error.InvalidFormat,
            else => return err,
        };
    } else {
        try skipBytes(br, total_skip);
    }
}

fn absoluteBytePosition(br: *BitReader) !usize {
    if (br.file) |*file| {
        const pos = try file.getPos();
        const buffered = br.reader.end - br.reader.seek;
        const buffered_u64: u64 = @intCast(buffered);
        if (pos < buffered_u64) return error.InvalidFormat;
        return @intCast(pos - buffered_u64);
    }
    return br.tell();
}

const ScanResult = struct {
    info: Mp3Info,
    first_frame: usize,
};

const scan_buffer_limit: usize = 512 * 1024;

fn scanMp3Mutable(br: *BitReader) !ScanResult {
    try skipId3(br);

    const remaining = br.reader.buffer[br.reader.seek..br.reader.end];
    if (remaining.len < 4) return error.InvalidFormat;
    if (remaining[0] != 0xFF and !(remaining.len >= 3 and remaining[0] == 'I' and remaining[1] == 'D' and remaining[2] == '3')) {
        return error.InvalidFormat;
    }

    var sr: ?u32 = null;
    var ch: ?u8 = null;
    var first_frame: ?usize = null;
    var total_frames: usize = 0;
    var scanned_bytes: usize = 0;

    while (scanned_bytes < max_sync_scan_attempts) {
        const has_enough = br.has(32) catch |err| switch (err) {
            error.EndOfStream => false,
            else => return err,
        };
        if (!has_enough) break;

        br.alignToByte();
        const available_bytes = br.reader.end - br.reader.seek;
        if (available_bytes < 4) break;
        const first_byte = br.reader.buffer[br.reader.seek];
        if (first_byte != 0xFF) {
            try skipOneByte(br);
            scanned_bytes += 1;
            continue;
        }
        const probe_start = try absoluteBytePosition(br);

        const hdr_res = frameheader.readFrameHeader(&br.reader) catch {
            try skipOneByte(br);
            scanned_bytes += 1;
            continue;
        };

        const header_pos = try absoluteBytePosition(br);
        if (header_pos < probe_start) return error.InvalidFormat;
        scanned_bytes += header_pos - probe_start;

        const header = hdr_res.header;
        const frame_sr = header.samplingFrequencyValue() orelse {
            try skipOneByte(br);
            scanned_bytes += 1;
            continue;
        };
        const frame_ch = header.numberOfChannels();

        if (sr) |fixed_sr| {
            if (frame_sr != fixed_sr or frame_ch != ch.?) {
                try skipOneByte(br);
                scanned_bytes += 1;
                continue;
            }
        } else {
            sr = frame_sr;
            ch = frame_ch;
            first_frame = header_pos;
        }

        const frame_size = header.frameSize() orelse {
            try skipOneByte(br);
            scanned_bytes += 1;
            continue;
        };
        if (frame_size < 4) {
            try skipOneByte(br);
            scanned_bytes += 1;
            continue;
        }

        try skipBytes(br, frame_size);

        const after_frame = try absoluteBytePosition(br);
        if (after_frame <= header_pos) return error.InvalidFormat;
        scanned_bytes += after_frame - header_pos;
        total_frames += 1;
    }

    if (sr == null or ch == null or total_frames == 0 or first_frame == null) {
        return error.InvalidFormat;
    }

    const sample_rate = sr.?;
    const channels = ch.?;
    const total_samples = @as(u64, total_frames) * samples_per_frame;
    const scan_info = Mp3Info{
        .sample_rate = sample_rate,
        .channels = channels,
        .total_frames = total_frames,
        .total_samples = total_samples,
        .duration_seconds = if (sample_rate != 0)
            @as(f64, @floatFromInt(total_samples)) / @as(f64, @floatFromInt(sample_rate))
        else
            0.0,
    };

    return ScanResult{ .info = scan_info, .first_frame = first_frame.? };
}

fn scanWithClone(br: *BitReader) !ScanResult {
    if (br.file) |*file| {
        const saved_pos = try file.getPos();
        defer file.seekTo(saved_pos) catch {};

        const total_size = br.totalSize() orelse return error.InvalidFormat;
        const read_len = @min(total_size, scan_buffer_limit);
        var buffer = try br.allocator.alloc(u8, read_len);
        defer br.allocator.free(buffer);

        try file.seekTo(0);
        var filled: usize = 0;
        while (filled < read_len) {
            const amt = try file.read(buffer[filled..read_len]);
            if (amt == 0) break;
            filled += amt;
        }
        if (filled == 0) return error.InvalidFormat;

        var mem_br = BitReader.initFromMemory(br.allocator, buffer[0..filled]);
        defer mem_br.deinit();
        return scanMp3Mutable(&mem_br);
    }

    var clone = try br.clone(br.allocator);
    defer BitReader.deinitClone(&clone);
    return scanMp3Mutable(&clone);
}

fn countFrames(br: *BitReader) !Mp3Info {
    if (br.file != null) {
        return (try scanWithClone(br)).info;
    }
    return (try scanMp3Mutable(br)).info;
}

pub fn probe(br: *BitReader) !bool {
    const meta = countFrames(br) catch return false;
    return meta.total_frames > 0;
}

fn info(br: *BitReader) !api.AudioInfo {
    const meta = try countFrames(br);
    return .{
        .sample_rate = meta.sample_rate,
        .channels = meta.channels,
        .sample_type = .i16,
        .total_frames = meta.total_frames,
        .duration_seconds = meta.duration_seconds,
    };
}

const Mp3Decoder = struct {
    allocator: std.mem.Allocator,
    br: *BitReader,
    prev_bits: ?mp3_bits.Bits = null,
    store: [2][32][18]f32 = std.mem.zeroes([2][32][18]f32),
    v_vec: [2][1024]f32 = std.mem.zeroes([2][1024]f32),
    pending: std.ArrayList(u8) = std.ArrayList(u8).empty,
    sample_rate: u32,
    channels: u8,
    total_frames: usize,
    frames_decoded: usize = 0,
    finished: bool = false,
};

fn drainPending(ctx: *Mp3Decoder, dst: []i16) usize {
    if (dst.len == 0) return 0;
    const available_samples = ctx.pending.items.len / 2;
    if (available_samples == 0) return 0;

    const to_copy = @min(available_samples, dst.len);
    var i: usize = 0;
    while (i < to_copy) : (i += 1) {
        const base = i * 2;
        const b0: u16 = ctx.pending.items[base];
        const b1: u16 = ctx.pending.items[base + 1];
        const combined: u16 = b0 | (b1 << 8);
        dst[i] = @as(i16, @bitCast(combined));
    }

    const consumed_bytes = to_copy * 2;
    const remaining = ctx.pending.items.len - consumed_bytes;
    if (remaining == 0) {
        ctx.pending.clearRetainingCapacity();
    } else {
        const ptr = ctx.pending.items.ptr;
        mem.copyForwards(u8, ptr[0..remaining], ptr[consumed_bytes .. consumed_bytes + remaining]);
        ctx.pending.items = ptr[0..remaining];
    }
    return to_copy;
}

fn decoderRead(decoder: *format.Decoder, dst: []i16) !usize {
    const ctx: *Mp3Decoder = @ptrCast(@alignCast(decoder.context));
    if (dst.len == 0) return 0;

    var written: usize = drainPending(ctx, dst);
    if (written == dst.len) return written;
    if (ctx.finished) return written;

    var attempts: usize = 0;

    while (written < dst.len and attempts < max_sync_scan_attempts) : (attempts += 1) {
        const frame_start_abs = try absoluteBytePosition(ctx.br);
        ctx.br.alignToByte();

        var frame = frame_mod.decodeFrame(ctx.allocator, &ctx.br.reader, if (ctx.prev_bits) |*p| p else null) catch |err| switch (err) {
            error.EndOfStream => {
                ctx.finished = true;
                break;
            },
            else => {
                const total_size = ctx.br.totalSize();
                const new_pos = frame_start_abs + 1;
                if (total_size != null and new_pos >= total_size.?) {
                    ctx.finished = true;
                    break;
                }
                ctx.br.seekTo(new_pos);
                continue;
            },
        };

        if (ctx.prev_bits) |*pb| pb.vec.deinit();
        ctx.prev_bits = null;

        frame.store = ctx.store;
        frame.v_vec = ctx.v_vec;

        const pcm = frame.decode(ctx.allocator) catch {
            frame.deinit();
            const total_size = ctx.br.totalSize();
            const new_pos = frame_start_abs + 1;
            if (total_size != null and new_pos >= total_size.?) {
                ctx.finished = true;
                break;
            }
            ctx.br.seekTo(new_pos);
            continue;
        };

        ctx.store = frame.store;
        ctx.v_vec = frame.v_vec;

        ctx.prev_bits = frame.main_data_bits;
        frame.main_data_bits.vec = std.array_list.Managed(u8).init(ctx.allocator);
        frame.deinit();

        try ctx.pending.appendSlice(ctx.allocator, pcm);
        ctx.allocator.free(pcm);

        ctx.frames_decoded += 1;
        written += drainPending(ctx, dst[written..]);
        if (written == dst.len) break;
    }

    if (written == 0 and attempts >= max_sync_scan_attempts) return error.CorruptedData;
    return written;
}

fn decoderDeinit(decoder: *format.Decoder) void {
    const ctx: *Mp3Decoder = @ptrCast(@alignCast(decoder.context));
    if (ctx.prev_bits) |*b| b.vec.deinit();
    ctx.pending.deinit(ctx.allocator);
    ctx.br.deinit();
    const allocator = decoder.allocator;
    allocator.destroy(ctx.br);
    allocator.destroy(ctx);
    allocator.destroy(decoder);
}

const decoder_vtable = format.DecoderVTable{
    .read = decoderRead,
    .deinit = decoderDeinit,
};

fn open(allocator: std.mem.Allocator, br: *BitReader) !*format.Decoder {
    const initial_state = br.*;
    var initial_pos: ?u64 = null;
    if (br.file) |*file| {
        initial_pos = try file.getPos();
    }

    const scan_result = try scanWithClone(br);
    const meta_info = scan_result.info;

    if (br.file) |*file| {
        if (initial_pos) |pos| file.seekTo(pos) catch {};
    }
    br.* = initial_state;

    br.seekTo(scan_result.first_frame);
    br.alignToByte();
    if (br.file != null) {
        br.reader.fillMore() catch {};
    }

    const ctx = try allocator.create(Mp3Decoder);
    ctx.* = .{
        .allocator = allocator,
        .br = br,
        .pending = std.ArrayList(u8).empty,
        .sample_rate = meta_info.sample_rate,
        .channels = meta_info.channels,
        .total_frames = meta_info.total_frames,
    };

    const decoder = try allocator.create(format.Decoder);
    decoder.* = .{
        .vtable = &decoder_vtable,
        .context = ctx,
        .info = .{
            .sample_rate = meta_info.sample_rate,
            .channels = meta_info.channels,
            .sample_type = .i16,
            .total_frames = meta_info.total_frames,
            .duration_seconds = meta_info.duration_seconds,
        },
        .allocator = allocator,
        .id = .mp3,
    };

    return decoder;
}

pub const vtable = format.VTable{
    .id = .mp3,
    .probe = probe,
    .info = info,
    .open = open,
};

// MP3 constants
pub const Version = enum(u2) {
    v2_5,
    reserved,
    v2,
    v1,
};

pub const Layer = enum(u2) {
    reserved,
    v3,
    v2,
    v1,
};

pub const Mode = enum(u2) {
    stereo,
    joint_stereo,
    dual_channel,
    single_channel,
};

pub const samples_per_granule = 576;
pub const granules_mpeg1: u8 = 2;
pub const sf_band_indices_long = 0;
pub const sf_band_indices_short = 1;

pub const SamplingFrequency = enum(u2) {
    reserved = 3,
};

pub const sf_band_indices = [2][3][2][23]u16{
    .{ // MPEG 1
        .{ // Layer 3
            .{ 0, 4, 8, 12, 16, 20, 24, 30, 36, 44, 52, 62, 74, 90, 110, 134, 162, 196, 238, 288, 342, 418, 576 },
            .{ 0, 4, 8, 12, 16, 22, 30, 40, 52, 66, 84, 106, 136, 192, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        },
        .{ // Layer 2
            .{ 0, 4, 8, 12, 16, 20, 24, 30, 36, 42, 50, 60, 72, 88, 106, 128, 156, 190, 230, 276, 330, 384, 576 },
            .{ 0, 4, 8, 12, 16, 22, 28, 38, 50, 64, 80, 100, 126, 192, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        },
        .{ // Layer 1
            .{ 0, 4, 8, 12, 16, 20, 24, 30, 36, 44, 54, 66, 82, 102, 126, 156, 194, 240, 296, 364, 448, 550, 576 },
            .{ 0, 4, 8, 12, 16, 22, 30, 42, 58, 78, 104, 138, 180, 192, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        },
    },
    .{ // MPEG 2
        .{ // Layer 3
            .{ 0, 6, 12, 18, 24, 30, 36, 44, 54, 66, 80, 96, 116, 140, 168, 200, 238, 284, 336, 396, 464, 522, 576 },
            .{ 0, 4, 8, 12, 18, 24, 32, 42, 56, 74, 100, 132, 174, 192, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        },
        .{ // Layer 2
            .{ 0, 6, 12, 18, 24, 30, 36, 44, 54, 66, 80, 96, 114, 136, 162, 194, 232, 278, 332, 394, 464, 540, 576 },
            .{ 0, 4, 8, 12, 18, 26, 36, 48, 62, 80, 104, 136, 180, 192, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        },
        .{ // Layer 1
            .{ 0, 6, 12, 18, 24, 30, 36, 44, 54, 66, 80, 96, 116, 140, 168, 200, 238, 284, 336, 396, 464, 522, 576 },
            .{ 0, 4, 8, 12, 18, 26, 36, 48, 62, 80, 104, 134, 174, 192, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        },
    },
};
