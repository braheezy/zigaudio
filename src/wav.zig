const std = @import("std");
const api = @import("root.zig");
const format = @import("formats.zig");
const BitReader = @import("BitReader.zig");

// WAV format constants
const RIFF_MAGIC = 0x46464952; // "RIFF" in little-endian
const WAVE_MAGIC = 0x45564157; // "WAVE"
const FMT_MAGIC = 0x20746d66; // "fmt "
const DATA_MAGIC = 0x61746164; // "data"

const FORMAT_PCM = 1;
const FORMAT_IEEE_FLOAT = 3;

const WavMetadata = struct {
    audio_format: u16,
    channels: u16,
    sample_rate: u32,
    bits_per_sample: u16,
    block_align: u16,
    data_offset: usize,
    data_size: usize,
};

// Decoder context
const WavDecoder = struct {
    br: *BitReader,
    metadata: WavMetadata,
    samples_read: usize,
    total_samples: usize,
};

fn read16(br: *BitReader) !u16 {
    // Read 2 bytes in little-endian order
    const b0 = try br.readBits(8);
    const b1 = try br.readBits(8);
    return @truncate(b0 | (b1 << 8));
}

fn read32(br: *BitReader) !u32 {
    // Read 4 bytes in little-endian order
    const b0 = try br.readBits(8);
    const b1 = try br.readBits(8);
    const b2 = try br.readBits(8);
    const b3 = try br.readBits(8);
    return b0 | (b1 << 8) | (b2 << 16) | (b3 << 24);
}

fn probe(br: *BitReader) !bool {
    const start_pos = br.tell();
    defer br.seekTo(start_pos);

    // Need at least 12 bytes: RIFF(4) + size(4) + WAVE(4)
    if (!try br.has(96)) return false; // 12 bytes = 96 bits

    br.alignToByte();
    const riff = try read32(br);
    _ = try read32(br); // file size
    const wave = try read32(br);

    return riff == RIFF_MAGIC and wave == WAVE_MAGIC;
}

fn parseMetadata(br: *BitReader) !WavMetadata {
    br.seekTo(0);
    br.alignToByte();

    // Read RIFF header
    const riff = try read32(br);
    const file_size = try read32(br);
    _ = file_size;
    const wave = try read32(br);

    if (riff != RIFF_MAGIC or wave != WAVE_MAGIC) {
        return error.InvalidFormat;
    }

    var metadata: WavMetadata = undefined;
    var found_fmt = false;
    var found_data = false;

    // Parse chunks
    while (try br.has(64)) { // chunk_id + chunk_size = 8 bytes
        const chunk_id = try read32(br);
        const chunk_size = try read32(br);
        const chunk_start = br.tell();

        if (chunk_id == FMT_MAGIC) {
            if (chunk_size < 16) return error.InvalidFormat;

            metadata.audio_format = try read16(br);
            metadata.channels = try read16(br);
            metadata.sample_rate = try read32(br);
            _ = try read32(br); // byte_rate
            metadata.block_align = try read16(br);
            metadata.bits_per_sample = try read16(br);

            found_fmt = true;

            // Skip any extra format bytes
            const bytes_read: usize = 16;
            if (chunk_size > bytes_read) {
                const skip_bytes = chunk_size - bytes_read;
                br.seekTo(chunk_start + skip_bytes);
            }
        } else if (chunk_id == DATA_MAGIC) {
            metadata.data_offset = br.tell();
            metadata.data_size = chunk_size;
            found_data = true;

            // Don't read data chunk, just skip it
            br.seekTo(br.tell() + chunk_size);
        } else {
            // Skip unknown chunk
            br.seekTo(chunk_start + chunk_size);
        }

        // Chunks are word-aligned (pad byte if odd size)
        if (chunk_size % 2 == 1) {
            br.seekTo(br.tell() + 1);
        }
    }

    if (!found_fmt or !found_data) {
        return error.InvalidFormat;
    }

    if (metadata.channels == 0 or metadata.sample_rate == 0 or
        metadata.bits_per_sample == 0 or metadata.block_align == 0)
    {
        return error.InvalidFormat;
    }

    return metadata;
}

fn info(br: *BitReader) !api.AudioInfo {
    const metadata = try parseMetadata(br);

    const bytes_per_sample = metadata.bits_per_sample / 8;
    const total_samples = metadata.data_size / bytes_per_sample;
    const total_frames = total_samples / metadata.channels;

    // All WAV decoded to i16
    const sample_type: api.SampleType = .i16;

    return .{
        .sample_rate = metadata.sample_rate,
        .channels = @intCast(metadata.channels),
        .sample_type = sample_type,
        .total_frames = total_frames,
        .duration_seconds = @as(f64, @floatFromInt(total_frames)) / @as(f64, @floatFromInt(metadata.sample_rate)),
    };
}

fn decoderRead(decoder: *format.Decoder, dst: []i16) !usize {
    const ctx: *WavDecoder = @ptrCast(@alignCast(decoder.context));

    if (ctx.samples_read >= ctx.total_samples) return 0;

    const samples_remaining = ctx.total_samples - ctx.samples_read;
    const samples_to_read = @min(dst.len, samples_remaining);

    // Decode based on format (BitReader maintains position between calls)
    if (ctx.metadata.audio_format == FORMAT_PCM) {
        try decodePCM(ctx.br, dst[0..samples_to_read], ctx.metadata.bits_per_sample);
    } else if (ctx.metadata.audio_format == FORMAT_IEEE_FLOAT) {
        try decodeFloat(ctx.br, dst[0..samples_to_read], ctx.metadata.bits_per_sample);
    } else {
        return error.UnsupportedFormat;
    }

    ctx.samples_read += samples_to_read;
    return samples_to_read;
}

fn decodePCM(br: *BitReader, dst: []i16, bits_per_sample: u16) !void {
    for (dst) |*sample| {
        // Convert to i16 with proper scaling (WAV is little-endian)
        sample.* = switch (bits_per_sample) {
            8 => blk: {
                // 8-bit PCM is unsigned (0-255), center at 128
                const raw = try br.readBits(8);
                const unsigned: i16 = @intCast(raw);
                break :blk (unsigned - 128) << 8;
            },
            16 => blk: {
                // 16-bit PCM is signed, little-endian
                const raw = try read16(br);
                const signed: i16 = @bitCast(raw);
                break :blk signed;
            },
            24 => blk: {
                // 24-bit to 16-bit: read 3 bytes little-endian, take top 16 bits
                const b0 = try br.readBits(8);
                const b1 = try br.readBits(8);
                const b2 = try br.readBits(8);
                const raw = b0 | (b1 << 8) | (b2 << 16);
                const signed: i32 = if (raw & 0x800000 != 0)
                    @as(i32, @bitCast(raw | 0xFF000000))
                else
                    @as(i32, @bitCast(raw));
                break :blk @intCast(signed >> 8);
            },
            32 => blk: {
                // 32-bit to 16-bit: take top 16 bits
                const raw = try read32(br);
                const signed: i32 = @bitCast(raw);
                break :blk @intCast(signed >> 16);
            },
            else => return error.UnsupportedBitDepth,
        };
    }
}

fn decodeFloat(br: *BitReader, dst: []i16, bits_per_sample: u16) !void {
    for (dst) |*sample| {
        if (bits_per_sample == 32) {
            const raw = try read32(br);
            const float_val: f32 = @bitCast(raw);
            // Clamp and convert float [-1.0, 1.0] to i16
            const scaled = float_val * 32767.0;
            const clamped = @max(-32768.0, @min(32767.0, scaled));
            sample.* = @intFromFloat(clamped);
        } else if (bits_per_sample == 64) {
            const raw1 = try read32(br);
            const raw2 = try read32(br);
            const raw64: u64 = (@as(u64, raw2) << 32) | raw1;
            const float_val: f64 = @bitCast(raw64);
            const scaled = float_val * 32767.0;
            const clamped = @max(-32768.0, @min(32767.0, scaled));
            sample.* = @intFromFloat(clamped);
        } else {
            return error.UnsupportedBitDepth;
        }
    }
}

fn decoderDeinit(decoder: *format.Decoder, allocator: std.mem.Allocator) void {
    const ctx: *WavDecoder = @ptrCast(@alignCast(decoder.context));
    ctx.br.deinit();
    allocator.destroy(ctx.br);
    allocator.destroy(ctx);
    allocator.destroy(decoder);
}

pub const decoder_vtable = format.DecoderVTable{
    .read = decoderRead,
    .deinit = decoderDeinit,
};

fn encode(writer: *std.Io.Writer, audio: *const api.Audio) api.WriteError!void {
    if (audio.params.sample_type != .i16) return error.UnsupportedBitDepth;
    if (audio.params.channels == 0) return error.UnsupportedChannelCount;

    const channels_u8 = audio.params.channels;
    const channels: u16 = @intCast(channels_u8);
    const sample_rate: u32 = audio.params.sample_rate;
    if (sample_rate == 0) return error.UnsupportedSampleRate;

    const bits_per_sample: u16 = 16;
    const bytes_per_sample: usize = bits_per_sample / 8;
    const bytes_per_sample_u16: u16 = @intCast(bytes_per_sample);

    const block_align: u16 = channels * bytes_per_sample_u16;
    const block_align_u32: u32 = @intCast(block_align);
    const byte_rate: u32 = sample_rate * block_align_u32;

    const data_len = audio.data.len;
    if (data_len % bytes_per_sample != 0) return error.InvalidFormat;
    if (data_len > std.math.maxInt(u32)) return error.Unsupported;
    const data_len_u32: u32 = @intCast(data_len);

    const total_frames = audio.frameCount();
    if (total_frames > std.math.maxInt(u32)) return error.Unsupported;

    const chunk_size: u32 = 36 + data_len_u32;

    var header: [44]u8 = undefined;
    std.mem.copyForwards(u8, header[0..4], "RIFF");
    std.mem.writeInt(u32, header[4..8], chunk_size, .little);
    std.mem.copyForwards(u8, header[8..12], "WAVE");
    std.mem.copyForwards(u8, header[12..16], "fmt ");
    std.mem.writeInt(u32, header[16..20], 16, .little);
    std.mem.writeInt(u16, header[20..22], 1, .little);
    std.mem.writeInt(u16, header[22..24], channels, .little);
    std.mem.writeInt(u32, header[24..28], sample_rate, .little);
    std.mem.writeInt(u32, header[28..32], byte_rate, .little);
    std.mem.writeInt(u16, header[32..34], block_align, .little);
    std.mem.writeInt(u16, header[34..36], bits_per_sample, .little);
    std.mem.copyForwards(u8, header[36..40], "data");
    std.mem.writeInt(u32, header[40..44], data_len_u32, .little);

    try writer.writeAll(&header);
    try writer.writeAll(audio.data);
}

fn open(allocator: std.mem.Allocator, br: *BitReader) !*format.Decoder {
    const metadata = try parseMetadata(br);

    // Validate format
    if (metadata.audio_format != FORMAT_PCM and metadata.audio_format != FORMAT_IEEE_FLOAT) {
        return error.UnsupportedFormat;
    }

    const bytes_per_sample = metadata.bits_per_sample / 8;
    const total_samples = metadata.data_size / bytes_per_sample;
    const total_frames = total_samples / metadata.channels;

    // Create decoder context - transfer ownership of BitReader
    // Position BitReader at start of PCM data
    br.seekTo(metadata.data_offset);
    br.alignToByte();

    const ctx = try allocator.create(WavDecoder);
    errdefer allocator.destroy(ctx);

    ctx.* = .{
        .br = br,
        .metadata = metadata,
        .samples_read = 0,
        .total_samples = total_samples,
    };

    const decoder = try allocator.create(format.Decoder);
    decoder.* = .{
        .vtable = &decoder_vtable,
        .context = ctx,
        .info = .{
            .sample_rate = metadata.sample_rate,
            .channels = @intCast(metadata.channels),
            .sample_type = .i16,
            .total_frames = total_frames,
            .duration_seconds = @as(f64, @floatFromInt(total_frames)) / @as(f64, @floatFromInt(metadata.sample_rate)),
        },
        .id = .wav,
    };

    return decoder;
}

pub const vtable = format.VTable{
    .id = .wav,
    .probe = probe,
    .info = info,
    .open = open,
    .encode = encode,
};
