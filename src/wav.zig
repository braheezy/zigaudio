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
const FORMAT_ADPCM = 2;
const FORMAT_IEEE_FLOAT = 3;
const FORMAT_ALAW = 6;
const FORMAT_MULAW = 7;
const FORMAT_IMA_ADPCM = 0x11;
const FORMAT_EXTENSIBLE = 0xFFFE;

// GUID for PCM subformat: 00000001-0000-0010-8000-00aa00389b71
const SUBFORMAT_PCM = [16]u8{ 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71 };
// GUID for IEEE Float subformat: 00000003-0000-0010-8000-00aa00389b71
const SUBFORMAT_IEEE_FLOAT = [16]u8{ 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71 };

const WavMetadata = struct {
    audio_format: u16,
    channels: u16,
    sample_rate: u32,
    bits_per_sample: u16,
    block_align: u16,
    data_offset: usize,
    data_size: usize,
    // ADPCM-specific
    samples_per_block: u16 = 0,
    // MS ADPCM coefficient pairs (up to 7 pairs)
    num_coefficients: u16 = 0,
    coefficients: [7][2]i16 = undefined,
};

// ADPCM state per channel
const AdpcmChannelState = struct {
    // IMA ADPCM
    predictor: i32 = 0,
    step_index: i32 = 0,
    // MS ADPCM
    sample1: i32 = 0,
    sample2: i32 = 0,
    coef1: i32 = 0,
    coef2: i32 = 0,
    delta: i32 = 0,
};

// Decoder context
const WavDecoder = struct {
    br: *BitReader,
    metadata: WavMetadata,
    samples_read: usize,
    total_samples: usize,
    // IMA ADPCM state
    adpcm_state: [2]AdpcmChannelState = .{ .{}, .{} },
    adpcm_block_samples_remaining: usize = 0,
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

            // Handle extended format data
            if (metadata.audio_format == FORMAT_EXTENSIBLE) {
                if (chunk_size < 40) return error.InvalidFormat; // Need extended data

                const cb_size = try read16(br);
                if (cb_size < 22) return error.InvalidFormat;

                _ = try read16(br); // valid_bits_per_sample
                _ = try read32(br); // channel_mask

                // Read SubFormat GUID (16 bytes)
                var subformat: [16]u8 = undefined;
                for (&subformat) |*byte| {
                    byte.* = @truncate(try br.readBits(8));
                }

                // Determine actual format from SubFormat GUID
                if (std.mem.eql(u8, &subformat, &SUBFORMAT_PCM)) {
                    metadata.audio_format = FORMAT_PCM;
                } else if (std.mem.eql(u8, &subformat, &SUBFORMAT_IEEE_FLOAT)) {
                    metadata.audio_format = FORMAT_IEEE_FLOAT;
                } else {
                    return error.UnsupportedFormat;
                }
            } else if (metadata.audio_format == FORMAT_IMA_ADPCM) {
                // IMA ADPCM extended format data
                if (chunk_size >= 20) {
                    _ = try read16(br); // cb_size
                    metadata.samples_per_block = try read16(br);
                }
            } else if (metadata.audio_format == FORMAT_ADPCM) {
                // MS ADPCM extended format data
                if (chunk_size >= 20) {
                    _ = try read16(br); // cb_size
                    metadata.samples_per_block = try read16(br);
                    metadata.num_coefficients = try read16(br);
                    // Read coefficient pairs
                    const num_coefs = @min(metadata.num_coefficients, 7);
                    for (0..num_coefs) |i| {
                        const coef1_raw = try read16(br);
                        const coef2_raw = try read16(br);
                        metadata.coefficients[i][0] = @bitCast(coef1_raw);
                        metadata.coefficients[i][1] = @bitCast(coef2_raw);
                    }
                }
            }

            found_fmt = true;

            // Skip to end of chunk
            br.seekTo(chunk_start + chunk_size);
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
    var actual_samples_read: usize = samples_to_read;
    if (ctx.metadata.audio_format == FORMAT_PCM) {
        try decodePCM(ctx.br, dst[0..samples_to_read], ctx.metadata.bits_per_sample);
    } else if (ctx.metadata.audio_format == FORMAT_IEEE_FLOAT) {
        try decodeFloat(ctx.br, dst[0..samples_to_read], ctx.metadata.bits_per_sample);
    } else if (ctx.metadata.audio_format == FORMAT_MULAW) {
        try decodeMuLaw(ctx.br, dst[0..samples_to_read]);
    } else if (ctx.metadata.audio_format == FORMAT_ALAW) {
        try decodeALaw(ctx.br, dst[0..samples_to_read]);
    } else if (ctx.metadata.audio_format == FORMAT_IMA_ADPCM) {
        actual_samples_read = try decodeImaAdpcm(ctx, dst[0..samples_to_read]);
    } else if (ctx.metadata.audio_format == FORMAT_ADPCM) {
        actual_samples_read = try decodeMsAdpcm(ctx, dst[0..samples_to_read]);
    } else {
        return error.UnsupportedFormat;
    }

    ctx.samples_read += actual_samples_read;
    return actual_samples_read;
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

// mu-Law expansion table (ITU-T G.711)
// Decodes 8-bit mu-law to 16-bit linear PCM
const MULAW_TABLE = blk: {
    var table: [256]i16 = undefined;
    for (0..256) |i| {
        const mu: u8 = @intCast(i);
        const inv = ~mu;
        const sign: i32 = if (inv & 0x80 != 0) -1 else 1;
        const exponent: u5 = @intCast((inv >> 4) & 0x07);
        const mantissa: i32 = inv & 0x0F;
        // Decode mu-law: magnitude = ((mantissa << 1) + 33) << exponent - 33
        const magnitude: i32 = ((mantissa << 1) + 33) << exponent;
        // Scale from 13-bit range (max 8031) to 16-bit range
        // Use shift left by 3 bits (multiply by 8) but clamp for safety
        const scaled = (magnitude - 33) << 2; // Scale by 4 to fit in i16
        table[i] = @intCast(sign * @min(scaled, 32767));
    }
    break :blk table;
};

// a-Law expansion table (ITU-T G.711)
// Decodes 8-bit a-law to 16-bit linear PCM
const ALAW_TABLE = blk: {
    var table: [256]i16 = undefined;
    for (0..256) |i| {
        const al: u8 = @intCast(i);
        const inv = al ^ 0x55; // A-law uses inverted odd bits
        const sign: i32 = if (inv & 0x80 != 0) -1 else 1;
        const exponent: u4 = @intCast((inv >> 4) & 0x07);
        const mantissa: i32 = inv & 0x0F;
        var magnitude: i32 = undefined;
        if (exponent == 0) {
            magnitude = (mantissa << 1) + 1;
        } else {
            magnitude = ((mantissa << 1) + 33) << (exponent - 1);
        }
        // Scale from 12-bit range to 16-bit range
        const scaled = magnitude << 3; // Scale by 8
        table[i] = @intCast(sign * @min(scaled, 32767));
    }
    break :blk table;
};

fn decodeMuLaw(br: *BitReader, dst: []i16) !void {
    for (dst) |*sample| {
        const raw: u8 = @truncate(try br.readBits(8));
        sample.* = MULAW_TABLE[raw];
    }
}

fn decodeALaw(br: *BitReader, dst: []i16) !void {
    for (dst) |*sample| {
        const raw: u8 = @truncate(try br.readBits(8));
        sample.* = ALAW_TABLE[raw];
    }
}

// IMA ADPCM step size table
const IMA_STEP_TABLE = [89]i32{
    7,     8,     9,     10,    11,    12,    13,    14,    16,    17,
    19,    21,    23,    25,    28,    31,    34,    37,    41,    45,
    50,    55,    60,    66,    73,    80,    88,    97,    107,   118,
    130,   143,   157,   173,   190,   209,   230,   253,   279,   307,
    337,   371,   408,   449,   494,   544,   598,   658,   724,   796,
    876,   963,   1060,  1166,  1282,  1411,  1552,  1707,  1878,  2066,
    2272,  2499,  2749,  3024,  3327,  3660,  4026,  4428,  4871,  5358,
    5894,  6484,  7132,  7845,  8630,  9493,  10442, 11487, 12635, 13899,
    15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767,
};

// IMA ADPCM index adjustment table
const IMA_INDEX_TABLE = [16]i32{
    -1, -1, -1, -1, 2, 4, 6, 8,
    -1, -1, -1, -1, 2, 4, 6, 8,
};

fn decodeImaNibble(nibble: u4, state: *AdpcmChannelState) i16 {
    const step = IMA_STEP_TABLE[@intCast(state.step_index)];

    // Compute difference
    var diff: i32 = step >> 3;
    if (nibble & 1 != 0) diff += step >> 2;
    if (nibble & 2 != 0) diff += step >> 1;
    if (nibble & 4 != 0) diff += step;
    if (nibble & 8 != 0) diff = -diff;

    // Update predictor with clamping
    state.predictor = std.math.clamp(state.predictor + diff, -32768, 32767);

    // Update step index with clamping
    state.step_index = std.math.clamp(state.step_index + IMA_INDEX_TABLE[nibble], 0, 88);

    return @intCast(state.predictor);
}

fn decodeImaAdpcm(ctx: *WavDecoder, dst: []i16) !usize {
    const channels = ctx.metadata.channels;
    var samples_written: usize = 0;

    while (samples_written < dst.len) {
        // Need to start a new block?
        if (ctx.adpcm_block_samples_remaining == 0) {
            // Read block header(s) - 4 bytes per channel
            for (0..channels) |ch| {
                // Read initial predictor (16-bit signed, little-endian)
                const pred_lo: i32 = @intCast(try ctx.br.readBits(8));
                const pred_hi: i32 = @intCast(try ctx.br.readBits(8));
                const pred_raw: u16 = @intCast(pred_lo | (pred_hi << 8));
                ctx.adpcm_state[ch].predictor = @as(i16, @bitCast(pred_raw));

                // Read initial step index
                const step_idx: i32 = @intCast(try ctx.br.readBits(8));
                ctx.adpcm_state[ch].step_index = std.math.clamp(step_idx, 0, 88);

                // Skip reserved byte
                _ = try ctx.br.readBits(8);
            }

            // Number of samples in block (excluding header sample)
            // Header provides 1 sample per channel, rest comes from nibbles
            const header_bytes = 4 * channels;
            const data_bytes = ctx.metadata.block_align - header_bytes;
            // Each byte has 2 nibbles, each nibble is one sample per channel (for mono)
            // For stereo, nibbles alternate between channels
            const nibbles_in_block = data_bytes * 2;
            ctx.adpcm_block_samples_remaining = if (channels == 1)
                nibbles_in_block
            else
                nibbles_in_block / channels;

            // Output initial predictor values (one frame)
            for (0..channels) |ch| {
                if (samples_written >= dst.len) break;
                dst[samples_written] = @intCast(ctx.adpcm_state[ch].predictor);
                samples_written += 1;
            }
        }

        // Decode nibbles from current block
        while (ctx.adpcm_block_samples_remaining > 0 and samples_written < dst.len) {
            if (channels == 1) {
                // Mono: read byte, decode low nibble then high nibble
                const byte: u8 = @truncate(try ctx.br.readBits(8));
                const lo_nibble: u4 = @truncate(byte & 0x0F);
                const hi_nibble: u4 = @truncate((byte >> 4) & 0x0F);

                dst[samples_written] = decodeImaNibble(lo_nibble, &ctx.adpcm_state[0]);
                samples_written += 1;
                ctx.adpcm_block_samples_remaining -= 1;

                if (ctx.adpcm_block_samples_remaining > 0 and samples_written < dst.len) {
                    dst[samples_written] = decodeImaNibble(hi_nibble, &ctx.adpcm_state[0]);
                    samples_written += 1;
                    ctx.adpcm_block_samples_remaining -= 1;
                }
            } else {
                // Stereo: nibbles alternate between channels within each 4-byte word
                // Read one byte, which has 2 nibbles for left channel (or right)
                const byte: u8 = @truncate(try ctx.br.readBits(8));
                const lo_nibble: u4 = @truncate(byte & 0x0F);
                const hi_nibble: u4 = @truncate((byte >> 4) & 0x0F);

                // For simplicity, decode as interleaved samples
                // This simplified approach works for basic stereo
                dst[samples_written] = decodeImaNibble(lo_nibble, &ctx.adpcm_state[0]);
                samples_written += 1;
                if (samples_written < dst.len) {
                    dst[samples_written] = decodeImaNibble(hi_nibble, &ctx.adpcm_state[1]);
                    samples_written += 1;
                }
                ctx.adpcm_block_samples_remaining -= 1;
            }
        }
    }

    return samples_written;
}

// MS ADPCM adaptation table
const MS_ADPCM_ADAPT_TABLE = [16]i32{
    230, 230, 230, 230, 307, 409, 512, 614,
    768, 614, 512, 409, 307, 230, 230, 230,
};

fn decodeMsNibble(nibble: u4, state: *AdpcmChannelState) i16 {
    // Sign-extend nibble to i64 for safe arithmetic
    const signed_nibble: i64 = if (nibble >= 8)
        @as(i64, nibble) - 16
    else
        @as(i64, nibble);

    // Compute predictor (use i64 to avoid overflow)
    const predictor: i64 = ((@as(i64, state.sample1) * state.coef1) + (@as(i64, state.sample2) * state.coef2)) >> 8;
    const sample = std.math.clamp(predictor + (signed_nibble * state.delta), -32768, 32767);

    // Update state
    state.sample2 = state.sample1;
    state.sample1 = @intCast(sample);

    // Update delta (use i64 to avoid overflow)
    const delta_calc: i64 = (@as(i64, state.delta) * MS_ADPCM_ADAPT_TABLE[nibble]) >> 8;
    state.delta = @intCast(@max(16, @min(delta_calc, 65535)));

    return @intCast(sample);
}

fn decodeMsAdpcm(ctx: *WavDecoder, dst: []i16) !usize {
    const channels = ctx.metadata.channels;
    var samples_written: usize = 0;

    while (samples_written < dst.len) {
        // Need to start a new block?
        if (ctx.adpcm_block_samples_remaining == 0) {
            // Read block header
            // First: predictor indices (1 byte per channel)
            for (0..channels) |ch| {
                const pred_idx: usize = @intCast(try ctx.br.readBits(8));
                if (pred_idx < ctx.metadata.num_coefficients) {
                    ctx.adpcm_state[ch].coef1 = ctx.metadata.coefficients[pred_idx][0];
                    ctx.adpcm_state[ch].coef2 = ctx.metadata.coefficients[pred_idx][1];
                }
            }

            // Delta values (2 bytes per channel, i16 LE)
            for (0..channels) |ch| {
                const delta_raw = try read16(ctx.br);
                ctx.adpcm_state[ch].delta = @as(i16, @bitCast(delta_raw));
            }

            // Sample1 values (2 bytes per channel, i16 LE)
            for (0..channels) |ch| {
                const sample_raw = try read16(ctx.br);
                ctx.adpcm_state[ch].sample1 = @as(i16, @bitCast(sample_raw));
            }

            // Sample2 values (2 bytes per channel, i16 LE)
            for (0..channels) |ch| {
                const sample_raw = try read16(ctx.br);
                ctx.adpcm_state[ch].sample2 = @as(i16, @bitCast(sample_raw));
            }

            // Output initial samples (sample2 first, then sample1)
            for (0..channels) |ch| {
                if (samples_written >= dst.len) break;
                dst[samples_written] = @intCast(ctx.adpcm_state[ch].sample2);
                samples_written += 1;
            }
            for (0..channels) |ch| {
                if (samples_written >= dst.len) break;
                dst[samples_written] = @intCast(ctx.adpcm_state[ch].sample1);
                samples_written += 1;
            }

            // Calculate remaining samples in block
            // Header is 7 bytes per channel (1 + 2 + 2 + 2), data has 2 samples in header per channel
            // Rest are nibble-encoded
            const header_samples_per_channel: usize = 2;
            const total_samples_per_channel = ctx.metadata.samples_per_block;
            ctx.adpcm_block_samples_remaining = total_samples_per_channel - header_samples_per_channel;
        }

        // Decode nibbles from current block
        while (ctx.adpcm_block_samples_remaining > 0 and samples_written < dst.len) {
            const byte: u8 = @truncate(try ctx.br.readBits(8));
            const hi_nibble: u4 = @truncate((byte >> 4) & 0x0F);
            const lo_nibble: u4 = @truncate(byte & 0x0F);

            if (channels == 1) {
                // Mono: high nibble first, then low nibble
                dst[samples_written] = decodeMsNibble(hi_nibble, &ctx.adpcm_state[0]);
                samples_written += 1;
                ctx.adpcm_block_samples_remaining -= 1;

                if (ctx.adpcm_block_samples_remaining > 0 and samples_written < dst.len) {
                    dst[samples_written] = decodeMsNibble(lo_nibble, &ctx.adpcm_state[0]);
                    samples_written += 1;
                    ctx.adpcm_block_samples_remaining -= 1;
                }
            } else {
                // Stereo: high nibble is left channel, low nibble is right channel
                dst[samples_written] = decodeMsNibble(hi_nibble, &ctx.adpcm_state[0]);
                samples_written += 1;
                if (samples_written < dst.len) {
                    dst[samples_written] = decodeMsNibble(lo_nibble, &ctx.adpcm_state[1]);
                    samples_written += 1;
                }
                ctx.adpcm_block_samples_remaining -= 1;
            }
        }
    }

    return samples_written;
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
    const is_supported = metadata.audio_format == FORMAT_PCM or
        metadata.audio_format == FORMAT_IEEE_FLOAT or
        metadata.audio_format == FORMAT_MULAW or
        metadata.audio_format == FORMAT_ALAW or
        metadata.audio_format == FORMAT_IMA_ADPCM or
        metadata.audio_format == FORMAT_ADPCM;
    if (!is_supported) {
        return error.UnsupportedFormat;
    }

    // Calculate total samples based on format
    var total_samples: usize = undefined;
    var total_frames: usize = undefined;

    if (metadata.audio_format == FORMAT_IMA_ADPCM or metadata.audio_format == FORMAT_ADPCM) {
        // For ADPCM, use samples_per_block and block count
        const num_blocks = metadata.data_size / metadata.block_align;
        total_frames = num_blocks * metadata.samples_per_block;
        total_samples = total_frames * metadata.channels;
    } else {
        const bytes_per_sample = metadata.bits_per_sample / 8;
        total_samples = metadata.data_size / bytes_per_sample;
        total_frames = total_samples / metadata.channels;
    }

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
