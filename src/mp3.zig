const std = @import("std");
const api = @import("root.zig");
const format = @import("formats.zig");
const io = @import("io.zig");
const frameheader = @import("mp3/frameheader.zig");
const frame_mod = @import("mp3/frame.zig");
const mp3_bits = @import("mp3/bits.zig");

const Mp3Info = struct {
    sample_rate: u32,
    channels: u8,
    total_frames: usize,
    total_samples: u64, // Total PCM samples (frames * 1152)
    duration_seconds: f64,
};

/// Count MP3 frames by parsing through the file
fn countFrames(stream: *io.ReadStream) api.ReadError!Mp3Info {
    const saved_pos = stream.getPos();
    defer stream.seekTo(saved_pos) catch {};

    skip_id3v2(stream) catch {};

    const r = stream.reader();
    const first_res = frameheader.readFrameHeader(r) catch return error.InvalidFormat;
    const first_header = first_res.header;
    const sr = first_header.samplingFrequencyValue() orelse return error.InvalidFormat;
    const ch = first_header.numberOfChannels();

    // Reset to start of first frame
    stream.seekTo(stream.getPos() - 4) catch return error.ReadFailed;

    const end_pos = stream.getEndPos() catch return error.ReadFailed;
    var total_frames: usize = 0;
    var scan_attempts: usize = 0;
    const max_scan_attempts: usize = 100000; // Safety limit

    while (stream.getPos() < end_pos and scan_attempts < max_scan_attempts) : (scan_attempts += 1) {
        const frame_start = stream.getPos();
        const frame_reader = stream.reader();

        const hdr_res = frameheader.readFrameHeader(frame_reader) catch |e| switch (e) {
            error.EndOfStream => break,
            else => {
                // Skip one byte and try again
                const new_pos = frame_start + 1;
                if (new_pos >= end_pos) break;
                stream.seekTo(new_pos) catch return error.ReadFailed;
                continue;
            },
        };

        const frame_size = hdr_res.header.frameSize() orelse {
            // Skip one byte and try again
            const new_pos = frame_start + 1;
            if (new_pos >= end_pos) break;
            stream.seekTo(new_pos) catch return error.ReadFailed;
            continue;
        };

        // Validate this is a consistent frame
        if (hdr_res.header.samplingFrequencyValue() != sr or
            hdr_res.header.numberOfChannels() != ch)
        {
            // Skip one byte and try again
            const new_pos = frame_start + 1;
            if (new_pos >= end_pos) break;
            stream.seekTo(new_pos) catch return error.ReadFailed;
            continue;
        }

        total_frames += 1;
        const next_pos = frame_start + frame_size;
        if (next_pos >= end_pos) break;
        stream.seekTo(next_pos) catch return error.ReadFailed;
    }

    // Each MP3 frame contains 1152 PCM samples
    const samples_per_frame: u64 = 1152;
    const total_samples = total_frames * samples_per_frame;
    const duration = @as(f64, @floatFromInt(total_samples)) / @as(f64, @floatFromInt(sr));

    return Mp3Info{
        .sample_rate = sr,
        .channels = ch,
        .total_frames = total_frames,
        .total_samples = total_samples,
        .duration_seconds = duration,
    };
}

fn skip_id3v2(stream: *io.ReadStream) api.ReadError!void {
    const r = stream.reader();
    const start = stream.getPos();
    const hdr = r.peek(10) catch |e| switch (e) {
        error.EndOfStream => return,
        else => return error.ReadFailed,
    };
    if (hdr.len < 10) return;
    if (!(hdr[0] == 'I' and hdr[1] == 'D' and hdr[2] == '3')) return;
    const version_major = hdr[3];
    const flags = hdr[5];
    // Syncsafe size
    const sz0: usize = @intCast(hdr[6] & 0x7F);
    const sz1: usize = @intCast(hdr[7] & 0x7F);
    const sz2: usize = @intCast(hdr[8] & 0x7F);
    const sz3: usize = @intCast(hdr[9] & 0x7F);
    const tag_size: usize = (sz0 << 21) | (sz1 << 14) | (sz2 << 7) | sz3;
    var total_skip: usize = 10 + tag_size;
    // ID3v2.4 footer flag (bit 4)
    if (version_major == 4 and (flags & 0x10) != 0) total_skip += 10;
    const new_pos = start + total_skip;
    stream.seekTo(@intCast(new_pos)) catch return error.ReadFailed;
}

/// Probe function to detect MP3 format
pub fn probe(stream: *io.ReadStream) api.ReadError!bool {
    const saved = stream.getPos();
    defer stream.seekTo(saved) catch {};
    skip_id3v2(stream) catch {};
    const r = stream.reader();
    _ = frameheader.readFrameHeader(r) catch return false;
    return true;
}

/// Read audio info from MP3 stream
pub fn info_reader(stream: *io.ReadStream) api.ReadError!api.AudioInfo {
    const mp3_info = try countFrames(stream);
    return .{ .sample_rate = mp3_info.sample_rate, .channels = mp3_info.channels, .sample_type = .i16, .total_frames = mp3_info.total_frames };
}

const Mp3StreamCtx = struct {
    allocator: std.mem.Allocator,
    stream: *io.ReadStream,
    prev_bits: ?mp3_bits.Bits = null,
    // overlap-add state across frames
    store: [2][32][18]f32 = std.mem.zeroes([2][32][18]f32),
    v_vec: [2][1024]f32 = std.mem.zeroes([2][1024]f32),
};

/// Stream decoder read function
fn mp3_stream_read(decoder: *format.AnyStreamDecoder, dst: []u8) api.ReadError!usize {
    const ctx: *Mp3StreamCtx = @ptrCast(@alignCast(decoder.context));
    if (dst.len == 0) return 0;

    var attempts: usize = 0;
    const max_attempts: usize = 1_000_000; // safety cap for damaged files

    while (attempts < max_attempts) : (attempts += 1) {
        // Try to assemble a frame
        var f: frame_mod.Frame = undefined;
        const pos_before = ctx.stream.getPos();
        const r0 = ctx.stream.reader();
        f = frame_mod.decodeFrame(ctx.allocator, r0, if (ctx.prev_bits) |*p| p else null) catch |e| switch (e) {
            error.EndOfStream => return error.EndOfStream,
            else => {
                // Resync on any error: advance one byte and retry
                const end = ctx.stream.getEndPos() catch 0;
                if (end != 0 and pos_before + 1 >= end) return error.EndOfStream;
                ctx.stream.seekTo(pos_before + 1) catch return error.ReadFailed;
                continue;
            },
        };

        // Drop previous reservoir now that a frame was assembled
        if (ctx.prev_bits) |*ob| {
            ob.vec.deinit();
            ctx.prev_bits = null;
        }

        // Carry overlap-add state into frame
        f.store = ctx.store;
        f.v_vec = ctx.v_vec;

        const pcm = f.decode(ctx.allocator) catch {
            // On synthesis failure, resync and retry
            f.deinit();
            const end = ctx.stream.getEndPos() catch 0;
            if (end != 0 and pos_before + 1 >= end) return error.EndOfStream;
            ctx.stream.seekTo(pos_before + 1) catch return error.ReadFailed;
            continue;
        };

        // Persist updated overlap state
        ctx.store = f.store;
        ctx.v_vec = f.v_vec;

        // Transfer reservoir ownership to ctx; prevent double free
        ctx.prev_bits = f.main_data_bits;
        f.main_data_bits.vec = std.array_list.Managed(u8).init(ctx.allocator);
        f.deinit();

        const n = @min(dst.len, pcm.len);
        std.mem.copyForwards(u8, dst[0..n], pcm[0..n]);
        ctx.allocator.free(pcm);
        return n;
    }

    std.debug.print("mp3(stream): giving up after {d} attempts\n", .{max_attempts});
    return error.ReadFailed;
}

/// Stream decoder deinit function
fn mp3_stream_deinit(decoder: *format.AnyStreamDecoder) void {
    const ctx: *Mp3StreamCtx = @ptrCast(@alignCast(decoder.context));
    const allocator = ctx.allocator;
    if (ctx.prev_bits) |*b| b.vec.deinit();
    allocator.destroy(ctx);
    allocator.destroy(decoder);
}

const mp3_stream_vtable = format.StreamDecoderVTable{
    .read = mp3_stream_read,
    .deinit = mp3_stream_deinit,
};

/// Open streaming MP3 decoder
pub fn open_stream(allocator: std.mem.Allocator, stream: *io.ReadStream) api.ReadError!*format.AnyStreamDecoder {
    // Position to the first frame (skip ID3v2 if present)
    skip_id3v2(stream) catch {};
    var found = false;
    var sr: u32 = 0;
    var ch: u8 = 0;
    var start_pos = stream.getPos();
    while (!found) {
        const saved = stream.getPos();
        const r = stream.reader();
        const hdr = frameheader.readFrameHeader(r) catch |e| switch (e) {
            error.EndOfStream => break,
            else => {
                // advance one byte and try again
                stream.seekTo(saved + 1) catch return error.ReadFailed;
                continue;
            },
        };
        sr = hdr.header.samplingFrequencyValue() orelse {
            stream.seekTo(saved + 1) catch return error.ReadFailed;
            continue;
        };
        ch = hdr.header.numberOfChannels();
        // success: reset to header start
        stream.seekTo(saved) catch return error.ReadFailed;
        start_pos = saved;
        found = true;
    }
    if (!found) return error.InvalidFormat;

    const ctx = try allocator.create(Mp3StreamCtx);
    ctx.* = .{ .allocator = allocator, .stream = stream };

    // Calculate total frames for streaming decoder
    const mp3_info = countFrames(stream) catch Mp3Info{
        .sample_rate = sr,
        .channels = ch,
        .total_frames = 0,
        .total_samples = 0,
        .duration_seconds = 0.0,
    };
    const total_frames = mp3_info.total_frames;

    const any = try allocator.create(format.AnyStreamDecoder);
    any.* = .{
        .vtable = &mp3_stream_vtable,
        .context = ctx,
        .info = .{ .sample_rate = sr, .channels = ch, .sample_type = .i16, .total_frames = total_frames },
    };
    // ensure stream at first header
    stream.seekTo(start_pos) catch return error.ReadFailed;
    return any;
}

/// Decode MP3 from bytes (full decode)
pub fn decode_from_bytes(allocator: std.mem.Allocator, bytes: []const u8) api.ReadError!api.Audio {
    var stream = io.ReadStream.initMemory(bytes);
    skip_id3v2(&stream) catch {};

    const end_pos = stream.getEndPos() catch return error.ReadFailed;

    // Find first valid header by scanning forward if necessary
    var sr: u32 = 0;
    var ch: u8 = 0;
    var start_pos = stream.getPos();
    var found = false;
    var scan_steps: usize = 0;
    while (!found) {
        const saved = stream.getPos();
        scan_steps += 1;
        const r0 = stream.reader();
        const hdr_try = frameheader.readFrameHeader(r0) catch |e| switch (e) {
            error.EndOfStream => break,
            else => {
                if (saved + 1 >= end_pos) break;
                stream.seekTo(saved + 1) catch return error.ReadFailed;
                continue;
            },
        };
        sr = hdr_try.header.samplingFrequencyValue() orelse {
            if (saved + 1 >= end_pos) break;
            stream.seekTo(saved + 1) catch return error.ReadFailed;
            continue;
        };
        ch = hdr_try.header.numberOfChannels();
        stream.seekTo(saved) catch return error.ReadFailed;
        start_pos = saved;
        found = true;
    }
    if (!found) {
        return error.ReadFailed;
    }

    // Rewind to first frame header for decode loop
    stream.seekTo(start_pos) catch return error.ReadFailed;

    var out = std.ArrayList(u8).initCapacity(allocator, 0) catch return error.OutOfMemory;
    defer out.deinit(allocator);

    var prev_bits: ?mp3_bits.Bits = null;
    var store: [2][32][18]f32 = std.mem.zeroes([2][32][18]f32);
    var v_vec: [2][1024]f32 = std.mem.zeroes([2][1024]f32);

    var frames_decoded: usize = 0;
    while (true) {
        const pos_before = stream.getPos();
        if (pos_before >= end_pos) break;
        const rr = stream.reader();
        var f = frame_mod.decodeFrame(allocator, rr, if (prev_bits) |*p| p else null) catch |e| switch (e) {
            error.EndOfStream => break,
            else => {
                if (pos_before + 1 >= end_pos) break;
                stream.seekTo(pos_before + 1) catch return error.ReadFailed;
                continue;
            },
        };
        // Release previous reservoir
        if (prev_bits) |*pb| pb.vec.deinit();
        prev_bits = null;

        // carry state
        f.store = store;
        f.v_vec = v_vec;

        const pcm = f.decode(allocator) catch {
            f.deinit();
            if (pos_before + 1 >= end_pos) break;
            stream.seekTo(pos_before + 1) catch return error.ReadFailed;
            continue;
        };
        frames_decoded += 1;
        // persist state
        store = f.store;
        v_vec = f.v_vec;

        // capture reservoir for next frame
        prev_bits = f.main_data_bits;
        f.main_data_bits.vec = std.array_list.Managed(u8).init(allocator);
        f.deinit();

        out.appendSlice(allocator, pcm) catch {
            allocator.free(pcm);
            return error.OutOfMemory;
        };
        allocator.free(pcm);
    }

    if (prev_bits) |*pb| pb.vec.deinit();

    if (frames_decoded == 0) {
        return error.ReadFailed;
    }

    const data = out.toOwnedSlice(allocator) catch return error.OutOfMemory;
    return .{
        .params = .{ .sample_rate = sr, .channels = ch, .sample_type = .i16 },
        .data = data,
        .allocator = allocator,
    };
}

/// Encode PCM audio to MP3 format
pub fn encode(writer: *std.Io.Writer, audio: *const api.Audio) api.WriteError!void {
    // TODO: Implement MP3 encoding
    _ = writer;
    _ = audio;
    return error.WriteFailed;
}

/// MP3 format vtable
pub const vtable = format.VTable{
    .id = .mp3,
    .probe = probe,
    .info_reader = info_reader,
    .decode_from_bytes = decode_from_bytes,
    .open_stream = open_stream,
    .encode = encode,
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
