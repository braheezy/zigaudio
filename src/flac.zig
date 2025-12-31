const std = @import("std");
const api = @import("root.zig");
const format = @import("formats.zig");
const BitReader = @import("BitReader.zig");
const c = @import("flac/flac.zig");
const build_options = @import("build_options");
const simd = @import("simd.zig");

const FLAC_MAGIC = "fLaC";
const default_max_block_size: usize = c.FLAC_SUBSET_MAX_BLOCK_SIZE;

const FoxenInstance = struct {
    mem: []u8,
    decoder: *c.fx_flac_t,
};

const Metadata = struct {
    sample_rate: u32,
    channels: u8,
    bits_per_sample: u8,
    total_samples: u64,
    max_block_size: usize,
};

const FlacDecoder = struct {
    br: *BitReader,
    foxen_mem: []u8,
    foxen: *c.fx_flac_t,
    sample_buffer: []i32,
    sample_index: usize = 0,
    sample_count: usize = 0,
    finished: bool = false,
    bits_per_sample: u8,
};

fn createFoxenInstance(allocator: std.mem.Allocator) !FoxenInstance {
    const size_u32 = c.fx_flac_size(c.FLAC_SUBSET_MAX_BLOCK_SIZE, c.FLAC_MAX_CHANNEL_COUNT);
    if (size_u32 == 0) return error.InvalidFormat;

    const size: usize = @intCast(size_u32);
    const mem = try allocator.alloc(u8, size);
    errdefer allocator.free(mem);

    const decoder = c.fx_flac_init(mem.ptr, c.FLAC_SUBSET_MAX_BLOCK_SIZE, c.FLAC_MAX_CHANNEL_COUNT) orelse {
        return error.InvalidFormat;
    };

    return .{ .mem = mem, .decoder = decoder };
}

fn convertSample(raw_sample: i32, bits_per_sample: u8) f32 {
    const effective_bps: u8 = if (bits_per_sample == 0) 16 else bits_per_sample;
    const clamped_bps = std.math.clamp(effective_bps, 1, 32);

    // FLAC stores samples left-aligned in the i32, so we need to shift right
    const back_shift: std.math.Log2Int(i32) = @intCast(32 - clamped_bps);
    const aligned_sample = if (back_shift == 0)
        raw_sample
    else
        raw_sample >> back_shift;

    // Normalize to [-1.0, 1.0] based on the bit depth
    const max_val: f32 = @floatFromInt(@as(i32, 1) << @intCast(clamped_bps - 1));
    return @as(f32, @floatFromInt(aligned_sample)) / max_val;
}

fn ensureInput(br: *BitReader) !bool {
    if (br.reader.seek < br.reader.end) return true;

    br.alignToByte();
    if (br.reader.seek < br.reader.end) return true;

    if (br.file != null) {
        br.reader.fillMore() catch |err| switch (err) {
            error.EndOfStream => return false,
            else => return err,
        };
        return br.reader.seek < br.reader.end;
    }

    return false;
}

fn requireBytes(br: *BitReader, count: usize) ![]const u8 {
    br.alignToByte();
    if (!try br.has(count * 8)) return error.InvalidFormat;
    if (br.reader.end - br.reader.seek < count) return error.InvalidFormat;
    return br.reader.buffer[br.reader.seek .. br.reader.seek + count];
}

fn readStreamInfo(decoder: *c.fx_flac_t, key: c.fx_flac_streaminfo_key_t) ?i64 {
    const value = c.fx_flac_get_streaminfo(decoder, key);
    if (value == c.FLAC_INVALID_METADATA_KEY) return null;
    return value;
}

fn clampBlockSize(value: ?i64) usize {
    if (value) |raw| {
        if (raw <= 0) return default_max_block_size;
        const as_usize: usize = @intCast(@min(raw, @as(i64, std.math.maxInt(u16))));
        return @max(@as(usize, 1), as_usize);
    }
    return default_max_block_size;
}

fn processMetadata(br: *BitReader, decoder: *c.fx_flac_t) !Metadata {
    const magic = try requireBytes(br, 4);
    if (!std.mem.eql(u8, magic, FLAC_MAGIC)) {
        return error.InvalidFormat;
    }

    var iterations: usize = 0;
    const max_iterations: usize = 1_000;

    while (iterations < max_iterations) : (iterations += 1) {
        if (!try ensureInput(br)) return error.InvalidFormat;

        br.alignToByte();
        const available = br.reader.buffer[br.reader.seek..br.reader.end];
        if (available.len == 0) return error.InvalidFormat;

        var in_len: u32 = @intCast(available.len);
        const state = c.fx_flac_process(decoder, available.ptr, &in_len, null, null);
        const consumed = @as(usize, @intCast(in_len));
        br.reader.seek += consumed;
        br.bit_index = 0;

        switch (state) {
            c.FLAC_ERR => return error.InvalidFormat,
            c.FLAC_END_OF_METADATA, c.FLAC_SEARCH_FRAME, c.FLAC_IN_FRAME, c.FLAC_DECODED_FRAME, c.FLAC_END_OF_FRAME => {
                if (state == c.FLAC_END_OF_METADATA or state >= c.FLAC_SEARCH_FRAME) {
                    break;
                }
            },
            else => {},
        }

        if (consumed == 0) {
            if (!try ensureInput(br)) return error.InvalidFormat;
        }
    } else {
        return error.InvalidFormat;
    }

    const sample_rate = readStreamInfo(decoder, c.FLAC_KEY_SAMPLE_RATE) orelse return error.InvalidFormat;
    const channels_i64 = readStreamInfo(decoder, c.FLAC_KEY_N_CHANNELS) orelse return error.InvalidFormat;
    const sample_size_i64 = readStreamInfo(decoder, c.FLAC_KEY_SAMPLE_SIZE) orelse return error.InvalidFormat;
    const total_samples_i64 = readStreamInfo(decoder, c.FLAC_KEY_N_SAMPLES) orelse 0;
    const max_block_i64 = readStreamInfo(decoder, c.FLAC_KEY_MAX_BLOCK_SIZE);

    if (channels_i64 <= 0 or sample_rate <= 0) return error.InvalidFormat;

    const metadata = Metadata{
        .sample_rate = @intCast(sample_rate),
        .channels = @intCast(channels_i64),
        .bits_per_sample = @intCast(sample_size_i64),
        .total_samples = if (total_samples_i64 > 0) @intCast(total_samples_i64) else 0,
        .max_block_size = clampBlockSize(max_block_i64),
    };

    return metadata;
}

fn flacProbe(br: *BitReader) !bool {
    const start_pos = br.tell();
    const start_bit = br.bit_index;
    defer {
        br.seekTo(start_pos);
        br.bit_index = start_bit;
    }

    const magic = requireBytes(br, 4) catch return false;
    return std.mem.eql(u8, magic, FLAC_MAGIC);
}

fn flacInfo(br: *BitReader) !api.AudioInfo {
    const start_pos = br.tell();
    const start_bit = br.bit_index;
    defer {
        br.seekTo(start_pos);
        br.bit_index = start_bit;
    }

    const foxen = try createFoxenInstance(br.allocator);
    defer br.allocator.free(foxen.mem);

    const metadata = try processMetadata(br, foxen.decoder);

    const total_frames: usize = if (metadata.total_samples > 0)
        @intCast(metadata.total_samples)
    else
        0;

    const duration = if (metadata.sample_rate != 0 and metadata.total_samples > 0)
        @as(f64, @floatFromInt(metadata.total_samples)) / @as(f64, @floatFromInt(metadata.sample_rate))
    else
        0.0;

    return .{
        .sample_rate = metadata.sample_rate,
        .channels = metadata.channels,
        .sample_type = .f32,
        .total_frames = total_frames,
        .duration_seconds = duration,
    };
}

fn ensureSamples(decoder: *FlacDecoder) !usize {
    decoder.sample_index = 0;
    decoder.sample_count = 0;

    while (true) {
        if (!try ensureInput(decoder.br)) {
            decoder.finished = true;
            return 0;
        }

        decoder.br.alignToByte();
        const available = decoder.br.reader.buffer[decoder.br.reader.seek..decoder.br.reader.end];
        if (available.len == 0) {
            decoder.finished = true;
            return 0;
        }

        var in_len: u32 = @intCast(available.len);
        var out_len: u32 = @intCast(decoder.sample_buffer.len);

        const state = c.fx_flac_process(decoder.foxen, available.ptr, &in_len, decoder.sample_buffer.ptr, &out_len);
        const consumed = @as(usize, @intCast(in_len));
        decoder.br.reader.seek += consumed;
        decoder.br.bit_index = 0;
        decoder.sample_count = @intCast(out_len);
        decoder.sample_index = 0;

        if (state == c.FLAC_ERR) return error.InvalidFormat;

        if (decoder.sample_count > 0) return decoder.sample_count;

        if (consumed == 0 and !(try ensureInput(decoder.br))) {
            decoder.finished = true;
            return 0;
        }

        if (state == c.FLAC_END_OF_FRAME or state == c.FLAC_END_OF_METADATA) {
            continue;
        }

        if (decoder.br.reader.seek >= decoder.br.reader.end and decoder.br.file == null) {
            decoder.finished = true;
            return 0;
        }
    }
}

fn decoderRead(dec: *format.Decoder, dst: []f32) !usize {
    const ctx: *FlacDecoder = @ptrCast(@alignCast(dec.context));
    if (ctx.finished and ctx.sample_index >= ctx.sample_count) return 0;

    var written: usize = 0;
    while (written < dst.len) {
        if (ctx.sample_index < ctx.sample_count) {
            const available = ctx.sample_count - ctx.sample_index;
            const to_write = @min(available, dst.len - written);
            const src_slice = ctx.sample_buffer[ctx.sample_index .. ctx.sample_index + to_write];
            const dst_slice = dst[written .. written + to_write];
            var processed: usize = 0;

            if (build_options.simd and simd.is_neon) {
                processed = simd.convertFlacSamplesNeon(dst_slice, src_slice, ctx.bits_per_sample);
            }

            while (processed < to_write) : (processed += 1) {
                dst_slice[processed] = convertSample(src_slice[processed], ctx.bits_per_sample);
            }

            ctx.sample_index += to_write;
            written += to_write;
            continue;
        }

        const decoded = try ensureSamples(ctx);
        if (decoded == 0) break;
    }

    return written;
}

fn decoderDeinit(dec: *format.Decoder, allocator: std.mem.Allocator) void {
    const ctx: *FlacDecoder = @ptrCast(@alignCast(dec.context));

    ctx.br.deinit();
    allocator.destroy(ctx.br);
    allocator.free(ctx.sample_buffer);
    allocator.free(ctx.foxen_mem);
    allocator.destroy(ctx);
    allocator.destroy(dec);
}

const decoder_vtable = format.DecoderVTable{
    .read = decoderRead,
    .deinit = decoderDeinit,
};

fn flacOpen(allocator: std.mem.Allocator, br: *BitReader) !*format.Decoder {
    const foxen = try createFoxenInstance(allocator);
    errdefer allocator.free(foxen.mem);

    const metadata = try processMetadata(br, foxen.decoder);

    const buffer_channels = @max(@as(usize, 1), @as(usize, metadata.channels));
    const buffer_samples = metadata.max_block_size * buffer_channels;
    const sample_buffer = try allocator.alloc(i32, buffer_samples);
    errdefer allocator.free(sample_buffer);

    const ctx = try allocator.create(FlacDecoder);
    errdefer allocator.destroy(ctx);
    ctx.* = .{
        .br = br,
        .foxen_mem = foxen.mem,
        .foxen = foxen.decoder,
        .sample_buffer = sample_buffer,
        .bits_per_sample = if (metadata.bits_per_sample == 0) 16 else metadata.bits_per_sample,
    };

    const total_frames: usize = if (metadata.total_samples > 0)
        @intCast(metadata.total_samples)
    else
        0;

    const duration = if (metadata.sample_rate != 0 and metadata.total_samples > 0)
        @as(f64, @floatFromInt(metadata.total_samples)) / @as(f64, @floatFromInt(metadata.sample_rate))
    else
        0.0;

    const decoder = try allocator.create(format.Decoder);
    decoder.* = .{
        .vtable = &decoder_vtable,
        .context = ctx,
        .info = .{
            .sample_rate = metadata.sample_rate,
            .channels = metadata.channels,
            .sample_type = .f32,
            .total_frames = total_frames,
            .duration_seconds = duration,
        },
        .id = .flac,
    };

    return decoder;
}

pub const vtable = format.VTable{
    .id = .flac,
    .probe = flacProbe,
    .info = flacInfo,
    .open = flacOpen,
};
