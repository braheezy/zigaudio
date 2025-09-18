const std = @import("std");
const api = @import("root.zig");
const io = @import("io.zig");

// WAV format constants
const WAV_RIFF_MAGIC = 0x46464952; // "RIFF"
const WAV_WAVE_MAGIC = 0x45564157; // "WAVE"
const WAV_FMT_MAGIC = 0x20746d66; // "fmt "
const WAV_DATA_MAGIC = 0x61746164; // "data"

const WavInfo = struct {
    audio_format: u16, // 1 = PCM, 3 = IEEE float
    channels: u16,
    sample_rate: u32,
    bits_per_sample: u16,
    block_align: u16,
    data_offset: usize = 0,
    data_size: usize = 0,
};

fn parse_header_for_info(bytes: []const u8) api.ReadError!WavInfo {
    if (bytes.len < 12) return error.InvalidFormat;
    const riff_magic = std.mem.readInt(u32, bytes[0..4], .little);
    const wave_magic = std.mem.readInt(u32, bytes[8..12], .little);
    if (riff_magic != WAV_RIFF_MAGIC or wave_magic != WAV_WAVE_MAGIC) return error.InvalidFormat;

    var info: WavInfo = .{
        .audio_format = 0,
        .channels = 0,
        .sample_rate = 0,
        .bits_per_sample = 0,
        .block_align = 0,
    };

    var offset: usize = 12;
    while (offset + 8 <= bytes.len) {
        const chunk_id = std.mem.readInt(u32, bytes[offset..][0..4], .little);
        const chunk_size_u32 = std.mem.readInt(u32, bytes[offset + 4 ..][0..4], .little);
        const chunk_size: usize = @intCast(chunk_size_u32);
        const payload_start = offset + 8;
        const payload_end = payload_start + chunk_size;
        if (payload_end > bytes.len) break;

        if (chunk_id == WAV_FMT_MAGIC and chunk_size >= 16) {
            info.audio_format = std.mem.readInt(u16, bytes[payload_start + 0 ..][0..2], .little);
            info.channels = std.mem.readInt(u16, bytes[payload_start + 2 ..][0..2], .little);
            info.sample_rate = std.mem.readInt(u32, bytes[payload_start + 4 ..][0..4], .little);
            // byte_rate at +8 (unused directly)
            info.block_align = std.mem.readInt(u16, bytes[payload_start + 12 ..][0..2], .little);
            info.bits_per_sample = std.mem.readInt(u16, bytes[payload_start + 14 ..][0..2], .little);
        } else if (chunk_id == WAV_DATA_MAGIC) {
            info.data_offset = payload_start;
            info.data_size = chunk_size;
            // We do not break immediately; continue to allow fmt to be found if not yet
        }

        offset = payload_end + (chunk_size % 2);
    }

    if (info.channels == 0 or info.sample_rate == 0 or info.bits_per_sample == 0 or info.block_align == 0) {
        return error.InvalidFormat;
    }
    return info;
}

// Probe function - checks if the stream contains WAV data
fn probe_reader(stream: *io.ReadStream) api.ReadError!bool {
    const r = stream.reader();
    const header = r.peek(12) catch |e| switch (e) {
        error.EndOfStream => return false,
        else => return error.ReadFailed,
    };

    if (header.len < 12) return false;

    const riff_magic = std.mem.readInt(u32, header[0..4], .little);
    const wave_magic = std.mem.readInt(u32, header[8..12], .little);

    return riff_magic == WAV_RIFF_MAGIC and wave_magic == WAV_WAVE_MAGIC;
}

// Info function - extracts metadata without full decode
fn info_reader(stream: *io.ReadStream) api.ReadError!api.AudioInfo {
    const r = stream.reader();
    var request: usize = blk: {
        const size = stream.getEndPos() catch 0;
        if (size > 0 and size <= std.math.maxInt(usize)) break :blk @intCast(size);
        break :blk 4096;
    };
    var last_len: usize = 0;
    var found: ?WavInfo = null;
    while (true) {
        const header = r.peek(request) catch |e| switch (e) {
            error.EndOfStream => break,
            else => return error.ReadFailed,
        };
        if (header.len == 0) break;
        const tmp = parse_header_for_info(header) catch {
            // If header is incomplete for fmt/data, try to peek more
            if (header.len == last_len) break; // cannot get more
            last_len = header.len;
            request = @max(request * 2, header.len + 1);
            continue;
        };
        found = tmp;
        if (tmp.data_size != 0) break; // have data chunk
        if (header.len == last_len) break;
        last_len = header.len;
        request = @max(request * 2, header.len + 1);
    }
    const info = found orelse return error.InvalidFormat;
    const total_frames: usize = if (info.data_size != 0 and info.block_align != 0) info.data_size / info.block_align else 0;
    return .{ .sample_rate = info.sample_rate, .channels = @intCast(info.channels), .sample_type = .i16, .total_frames = total_frames };
}

// Decode function - placeholder implementation
fn wav_decode_from_bytes(allocator: std.mem.Allocator, bytes: []const u8) api.ReadError!api.Audio {
    const info = parse_header_for_info(bytes) catch return error.InvalidFormat;
    if (!(info.audio_format == 1 or info.audio_format == 3)) return error.Unsupported; // PCM or IEEE float
    if (info.channels == 0 or info.block_align == 0) return error.InvalidFormat;

    const channels: usize = info.channels;
    const source = bytes[info.data_offset .. info.data_offset + info.data_size];
    const total_frames = @divTrunc(source.len, info.block_align);
    const total_samples = total_frames * channels;

    // Output always i16 interleaved little-endian
    const out_bytes_len = total_samples * @sizeOf(i16);
    const out = try allocator.alloc(u8, out_bytes_len);
    errdefer allocator.free(out);
    var out_i16 = std.mem.bytesAsSlice(i16, out);

    switch (info.audio_format) {
        1 => { // PCM integer
            switch (info.bits_per_sample) {
                8 => {
                    // Unsigned 8-bit to signed 16-bit
                    var si: usize = 0;
                    var di: usize = 0;
                    while (si < source.len) : ({
                        si += 1;
                        di += 1;
                    }) {
                        const u: u8 = source[si];
                        const s: i16 = @as(i16, @intCast(@as(i32, @intCast(u)) - 128)) << 8;
                        out_i16[di] = s;
                    }
                },
                16 => {
                    if (source.len % 2 != 0) return error.CorruptedData;
                    var si: usize = 0;
                    var di: usize = 0;
                    while (si + 1 < source.len) : ({
                        si += 2;
                        di += 1;
                    }) {
                        const p = @as(*const [2]u8, @ptrCast(&source[si]));
                        const s = std.mem.readInt(i16, p, .little);
                        out_i16[di] = s;
                    }
                },
                24 => {
                    // 24-bit little-endian signed -> i16 (truncate high precision)
                    if (source.len % 3 != 0) return error.CorruptedData;
                    var si: usize = 0;
                    var di: usize = 0;
                    while (si + 2 < source.len) : ({
                        si += 3;
                        di += 1;
                    }) {
                        const b0: u32 = source[si + 0];
                        const b1: u32 = source[si + 1];
                        const b2: u32 = source[si + 2];
                        var v_u: u32 = (b0) | (b1 << 8) | (b2 << 16);
                        // Sign-extend 24-bit to 32-bit in unsigned domain then cast
                        if ((b2 & 0x80) != 0) {
                            v_u |= 0xFF000000;
                        }
                        const v: i32 = @bitCast(v_u);
                        out_i16[di] = @truncate(v >> 8);
                    }
                },
                32 => {
                    if (source.len % 4 != 0) return error.CorruptedData;
                    var si: usize = 0;
                    var di: usize = 0;
                    while (si + 3 < source.len) : ({
                        si += 4;
                        di += 1;
                    }) {
                        const p = @as(*const [4]u8, @ptrCast(&source[si]));
                        const v = std.mem.readInt(i32, p, .little);
                        out_i16[di] = @truncate(v >> 16);
                    }
                },
                else => return error.UnsupportedBitDepth,
            }
        },
        3 => { // IEEE float
            switch (info.bits_per_sample) {
                32 => {
                    if (source.len % 4 != 0) return error.CorruptedData;
                    var si: usize = 0;
                    var di: usize = 0;
                    while (si + 3 < source.len) : ({
                        si += 4;
                        di += 1;
                    }) {
                        const p = @as(*const [4]u8, @ptrCast(&source[si]));
                        const bits = std.mem.readInt(u32, p, .little);
                        const f: f32 = @bitCast(bits);
                        const scaled: f32 = if (f < -1.0) -1.0 else if (f > 1.0) 1.0 else f;
                        out_i16[di] = @intFromFloat(scaled * 32767.0);
                    }
                },
                64 => {
                    if (source.len % 8 != 0) return error.CorruptedData;
                    var si: usize = 0;
                    var di: usize = 0;
                    while (si + 7 < source.len) : ({
                        si += 8;
                        di += 1;
                    }) {
                        const p = @as(*const [8]u8, @ptrCast(&source[si]));
                        const bits = std.mem.readInt(u64, p, .little);
                        const f: f64 = @bitCast(bits);
                        var scaled: f64 = f;
                        if (scaled < -1.0) scaled = -1.0;
                        if (scaled > 1.0) scaled = 1.0;
                        out_i16[di] = @intFromFloat(scaled * 32767.0);
                    }
                },
                else => return error.UnsupportedBitDepth,
            }
        },
        else => return error.Unsupported,
    }

    return .{
        .params = .{ .sample_rate = info.sample_rate, .channels = @intCast(info.channels), .sample_type = .i16 },
        .data = out,
        .allocator = allocator,
    };
}

// Encode function - placeholder implementation
fn wav_encode(_writer: *std.Io.Writer, _audio: *const api.Audio, _options: api.EncodeOptions) api.WriteError!void {
    _ = _writer;
    _ = _audio;
    _ = _options;

    // TODO: Implement WAV encoding
    return error.Unsupported;
}

// WAV format vtable
pub const vtable: api.FormatVTable = .{
    .id = .wav,
    .probe = probe_reader,
    .info_reader = info_reader,
    .decode_from_bytes = wav_decode_from_bytes,
    .encode = wav_encode,
};
