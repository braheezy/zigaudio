const std = @import("std");
const api = @import("root.zig");
const fapi = @import("formats.zig");
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

fn ensureBuffered(rdr: *std.io.Reader, need: usize) api.ReadError![]const u8 {
    while (true) {
        const buf = rdr.buffered();
        if (buf.len >= need) return buf;
        rdr.fillMore() catch |e| switch (e) {
            error.EndOfStream => return buf,
            else => return error.ReadFailed,
        };
    }
}

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
    return .{ .sample_rate = info.sample_rate, .channels = @intCast(info.channels), .sample_type = .i16, .total_frames = total_frames, .duration_seconds = 0.0 };
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
        .format_id = .wav,
    };
}

// Encode function - placeholder implementation
fn wav_encode(_writer: *std.Io.Writer, _audio: *const api.Audio) api.WriteError!void {
    _ = _writer;
    _ = _audio;

    // TODO: Implement WAV encoding
    return error.Unsupported;
}

// WAV format vtable
pub const vtable: fapi.VTable = .{
    .id = .wav,
    .probe = probe_reader,
    .info_reader = info_reader,
    .decode_from_bytes = wav_decode_from_bytes,
    .open_stream = wav_open_stream,
    .encode = wav_encode,
};

const WavStreamCtx = struct {
    allocator: std.mem.Allocator,
    stream: *io.ReadStream,
    info: WavInfo,
    bytes_remaining: usize,
};

fn wav_stream_read(dec: *fapi.AnyStreamDecoder, dst: []u8) api.ReadError!usize {
    const ctx: *WavStreamCtx = @ptrCast(@alignCast(dec.context));
    if (ctx.bytes_remaining == 0) return error.EndOfStream;

    const channels: usize = ctx.info.channels;
    const src_bps: usize = ctx.info.bits_per_sample;
    const dst_frame_bytes: usize = channels * @sizeOf(i16);

    var written: usize = 0;
    var r = ctx.stream.reader();

    // Helper to ensure n bytes available in reader buffer

    switch (src_bps) {
        16 => {
            // Fast path: copy as-is up to alignment, limited by remaining
            const max_out = @min(dst.len - (dst.len % dst_frame_bytes), ctx.bytes_remaining);
            if (max_out == 0) return error.EndOfStream;
            var remaining_out = max_out;
            while (remaining_out != 0) {
                const buf = try ensureBuffered(r, 1);
                if (buf.len == 0) break;
                const take = @min(buf.len, remaining_out);
                std.mem.copyForwards(u8, dst[written .. written + take], buf[0..take]);
                written += take;
                remaining_out -= take;
                r.toss(take);
            }
            ctx.bytes_remaining -= written;
            if (written == 0) return error.EndOfStream;
            return written;
        },
        8 => {
            // u8 -> i16
            const in_per_frame: usize = channels * 1;
            const max_frames = @min(ctx.bytes_remaining / in_per_frame, (dst.len / dst_frame_bytes));
            if (max_frames == 0) return error.EndOfStream;
            var frames_done: usize = 0;
            var i: usize = 0;
            while (frames_done < max_frames) {
                const need_in = @min(4096, (max_frames - frames_done) * in_per_frame);
                const buf = try ensureBuffered(r, need_in);
                if (buf.len == 0) break;
                const take = @min(buf.len, need_in);
                var si: usize = 0;
                while (si < take) : (si += 1) {
                    const u: u8 = buf[si];
                    const s: i16 = @as(i16, @intCast(@as(i32, @intCast(u)) - 128)) << 8;
                    // write to dst
                    const p: *[2]u8 = @ptrCast(&dst[i]);
                    @memset(p, 0);
                    std.mem.writeInt(i16, p, s, .little);
                    i += 2;
                }
                r.toss(take);
                frames_done += take / in_per_frame;
                ctx.bytes_remaining -= take;
            }
            return frames_done * dst_frame_bytes;
        },
        24 => {
            const in_per_frame: usize = channels * 3;
            const max_frames = @min(ctx.bytes_remaining / in_per_frame, (dst.len / dst_frame_bytes));
            if (max_frames == 0) return error.EndOfStream;
            var frames_done: usize = 0;
            var i: usize = 0;
            while (frames_done < max_frames) {
                const need_in = @min(4095, (max_frames - frames_done) * in_per_frame);
                const buf = try ensureBuffered(r, need_in);
                if (buf.len == 0) break;
                const take = @min(buf.len - (buf.len % 3), need_in);
                var si: usize = 0;
                while (si + 2 < take) : (si += 3) {
                    const b0: u32 = buf[si + 0];
                    const b1: u32 = buf[si + 1];
                    const b2: u32 = buf[si + 2];
                    var v_u: u32 = (b0) | (b1 << 8) | (b2 << 16);
                    if ((b2 & 0x80) != 0) v_u |= 0xFF000000;
                    const v: i32 = @bitCast(v_u);
                    const s: i16 = @truncate(v >> 8);
                    const p: *[2]u8 = @ptrCast(&dst[i]);
                    std.mem.writeInt(i16, p, s, .little);
                    i += 2;
                }
                r.toss(take);
                frames_done += take / 3 / channels; // but we processed raw stream, approximate per sample
                ctx.bytes_remaining -= take;
            }
            return i;
        },
        32 => {
            // Treat as signed 32-bit PCM -> i16
            const in_per_frame: usize = channels * 4;
            const max_frames = @min(ctx.bytes_remaining / in_per_frame, (dst.len / dst_frame_bytes));
            if (max_frames == 0) return error.EndOfStream;
            var frames_done: usize = 0;
            var i: usize = 0;
            while (frames_done < max_frames) {
                const need_in = @min(4096, (max_frames - frames_done) * in_per_frame);
                const buf = try ensureBuffered(r, need_in);
                if (buf.len == 0) break;
                const take = @min(buf.len - (buf.len % 4), need_in);
                var si: usize = 0;
                while (si + 3 < take) : (si += 4) {
                    const p = @as(*const [4]u8, @ptrCast(&buf[si]));
                    const v = std.mem.readInt(i32, p, .little);
                    const s: i16 = @truncate(v >> 16);
                    const po: *[2]u8 = @ptrCast(&dst[i]);
                    std.mem.writeInt(i16, po, s, .little);
                    i += 2;
                }
                r.toss(take);
                frames_done += take / in_per_frame;
                ctx.bytes_remaining -= take;
            }
            return i;
        },
        else => {
            // float 32/64 handled via info.audio_format check; map here
            if (ctx.info.audio_format == 3 and (src_bps == 32 or src_bps == 64)) {
                if (src_bps == 32) {
                    const in_per_frame: usize = channels * 4;
                    const max_frames = @min(ctx.bytes_remaining / in_per_frame, (dst.len / dst_frame_bytes));
                    if (max_frames == 0) return error.EndOfStream;
                    var frames_done: usize = 0;
                    var i: usize = 0;
                    while (frames_done < max_frames) {
                        const need_in = @min(4096, (max_frames - frames_done) * in_per_frame);
                        const buf = try ensureBuffered(r, need_in);
                        if (buf.len == 0) break;
                        const take = @min(buf.len - (buf.len % 4), need_in);
                        var si: usize = 0;
                        while (si + 3 < take) : (si += 4) {
                            const p = @as(*const [4]u8, @ptrCast(&buf[si]));
                            const bits = std.mem.readInt(u32, p, .little);
                            const f: f32 = @bitCast(bits);
                            const clamped: f32 = if (f < -1.0) -1.0 else if (f > 1.0) 1.0 else f;
                            const s: i16 = @intFromFloat(clamped * 32767.0);
                            const po: *[2]u8 = @ptrCast(&dst[i]);
                            std.mem.writeInt(i16, po, s, .little);
                            i += 2;
                        }
                        r.toss(take);
                        frames_done += take / in_per_frame;
                        ctx.bytes_remaining -= take;
                    }
                    return i;
                } else {
                    const in_per_frame: usize = channels * 8;
                    const max_frames = @min(ctx.bytes_remaining / in_per_frame, (dst.len / dst_frame_bytes));
                    if (max_frames == 0) return error.EndOfStream;
                    var frames_done: usize = 0;
                    var i: usize = 0;
                    while (frames_done < max_frames) {
                        const need_in = @min(4096, (max_frames - frames_done) * in_per_frame);
                        const buf = try ensureBuffered(r, need_in);
                        if (buf.len == 0) break;
                        const take = @min(buf.len - (buf.len % 8), need_in);
                        var si: usize = 0;
                        while (si + 7 < take) : (si += 8) {
                            const p = @as(*const [8]u8, @ptrCast(&buf[si]));
                            const bits = std.mem.readInt(u64, p, .little);
                            const f: f64 = @bitCast(bits);
                            var clamped: f64 = f;
                            if (clamped < -1.0) clamped = -1.0;
                            if (clamped > 1.0) clamped = 1.0;
                            const s: i16 = @intFromFloat(clamped * 32767.0);
                            const po: *[2]u8 = @ptrCast(&dst[i]);
                            std.mem.writeInt(i16, po, s, .little);
                            i += 2;
                        }
                        r.toss(take);
                        frames_done += take / in_per_frame;
                        ctx.bytes_remaining -= take;
                    }
                    return i;
                }
            }
            return error.UnsupportedBitDepth;
        },
    }
}

fn wav_stream_deinit(dec: *fapi.AnyStreamDecoder) void {
    const ctx: *WavStreamCtx = @ptrCast(@alignCast(dec.context));
    const allocator = ctx.allocator;
    allocator.destroy(ctx);
    allocator.destroy(dec);
}

const wav_stream_vtable: fapi.StreamDecoderVTable = .{
    .read = wav_stream_read,
    .deinit = wav_stream_deinit,
};

fn wav_open_stream(allocator: std.mem.Allocator, stream: *io.ReadStream) api.ReadError!*fapi.AnyStreamDecoder {
    // Robust RIFF/fmt/data scan using small fixed peeks and explicit seeking
    const r = stream.reader();
    // Verify RIFF/WAVE
    stream.seekTo(0) catch return error.ReadFailed;
    const head12 = r.peek(12) catch return error.ReadFailed;
    if (head12.len < 12) return error.InvalidFormat;
    if (std.mem.readInt(u32, head12[0..4], .little) != WAV_RIFF_MAGIC) return error.InvalidFormat;
    if (std.mem.readInt(u32, head12[8..12], .little) != WAV_WAVE_MAGIC) return error.InvalidFormat;

    var info: WavInfo = .{ .audio_format = 0, .channels = 0, .sample_rate = 0, .bits_per_sample = 0, .block_align = 0, .data_offset = 0, .data_size = 0 };
    var pos: u64 = 12;
    const end = stream.getEndPos() catch 0;
    while (pos + 8 <= end) {
        // Read chunk header
        stream.seekTo(pos) catch return error.ReadFailed;
        const chdr = r.peek(8) catch return error.ReadFailed;
        if (chdr.len < 8) return error.InvalidFormat;
        const chunk_id = std.mem.readInt(u32, chdr[0..4], .little);
        const chunk_size_u32 = std.mem.readInt(u32, chdr[4..8], .little);
        const chunk_size: usize = @intCast(chunk_size_u32);
        const payload_start = pos + 8;

        if (chunk_id == WAV_FMT_MAGIC) {
            // Read at least 16 bytes of fmt
            stream.seekTo(payload_start) catch return error.ReadFailed;
            const need = 16;
            const fmtv = r.peek(need) catch return error.ReadFailed;
            if (fmtv.len < need) return error.InvalidFormat;
            info.audio_format = std.mem.readInt(u16, fmtv[0..2], .little);
            info.channels = std.mem.readInt(u16, fmtv[2..4], .little);
            info.sample_rate = std.mem.readInt(u32, fmtv[4..8], .little);
            info.block_align = std.mem.readInt(u16, fmtv[12..14], .little);
            info.bits_per_sample = std.mem.readInt(u16, fmtv[14..16], .little);
        } else if (chunk_id == WAV_DATA_MAGIC) {
            info.data_offset = @intCast(payload_start);
            info.data_size = chunk_size;
        }

        // advance to next chunk (even alignment)
        var next: u64 = payload_start + @as(u64, chunk_size);
        if ((chunk_size % 2) != 0) next += 1;
        pos = next;

        if (info.channels != 0 and info.sample_rate != 0 and info.bits_per_sample != 0 and info.block_align != 0 and info.data_size != 0) {
            break;
        }
    }
    if (info.channels == 0 or info.sample_rate == 0 or info.bits_per_sample == 0 or info.block_align == 0 or info.data_size == 0) return error.InvalidFormat;

    // Seek to data start
    stream.seekTo(@intCast(info.data_offset)) catch |e| switch (e) {
        error.Unseekable => return error.ReadFailed,
        else => return error.ReadFailed,
    };

    const ctx = try allocator.create(WavStreamCtx);
    ctx.* = .{
        .allocator = allocator,
        .stream = stream,
        .info = info,
        .bytes_remaining = info.data_size,
    };

    const any = try allocator.create(fapi.AnyStreamDecoder);
    any.* = .{
        .vtable = &wav_stream_vtable,
        .context = ctx,
        .info = .{
            .sample_rate = info.sample_rate,
            .channels = @intCast(info.channels),
            .sample_type = .i16,
            .total_frames = info.data_size / info.block_align,
            .duration_seconds = 0.0,
        },
    };
    return any;
}
