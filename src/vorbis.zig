const std = @import("std");
const api = @import("root.zig");
const format = @import("formats.zig");
const io = @import("io.zig");

const c = @import("vorbis/vorbis.zig");

const SampleType = api.SampleType;

fn translateError(code: c_int) api.ReadError {
    return switch (code) {
        c.VORBIS_need_more_data => error.EndOfStream,
        c.VORBIS_invalid_stream, c.VORBIS_invalid_setup, c.VORBIS_bad_packet_type, c.VORBIS_invalid_first_page, c.VORBIS_missing_capture_pattern, c.VORBIS_invalid_stream_structure_version => api.Error.InvalidFormat,
        c.VORBIS_unexpected_eof, c.VORBIS_seek_failed, c.VORBIS_seek_invalid => api.Error.CorruptedData,
        c.VORBIS_feature_not_supported, c.VORBIS_ogg_skeleton_not_supported => api.Error.Unsupported,
        c.VORBIS_too_many_channels => api.Error.UnsupportedChannelCount,
        c.VORBIS_outofmem => error.OutOfMemory,
        else => api.Error.InvalidFormat,
    };
}

fn infoFromHandle(handle: *c.stb_vorbis) api.AudioInfo {
    const info = c.stb_vorbis_get_info(handle);
    const sample_rate: u32 = @intCast(info.sample_rate);
    const channels: u8 = @intCast(info.channels);
    const total_samples = c.stb_vorbis_stream_length_in_samples(handle);
    const total_frames: usize = if (total_samples == 0) 0 else @intCast(total_samples);
    const duration_seconds: f64 = if (sample_rate != 0 and total_frames != 0)
        @as(f64, @floatFromInt(total_frames)) / @as(f64, @floatFromInt(sample_rate))
    else
        0.0;
    return .{
        .sample_rate = sample_rate,
        .channels = channels,
        .sample_type = SampleType.i16,
        .total_frames = total_frames,
        .duration_seconds = duration_seconds,
    };
}

fn openMemory(allocator: std.mem.Allocator, bytes: []const u8) !*c.stb_vorbis {
    _ = allocator; // Not needed when using null alloc
    var err: c_int = 0;
    // Pass null for alloc config to let stb_vorbis use malloc
    const handle = try c.stb_vorbis_open_memory(bytes.ptr, @intCast(bytes.len), &err, null);
    if (handle == null) {
        return translateError(err);
    }
    return handle;
}

fn readAllFromFile(allocator: std.mem.Allocator, stream: *io.ReadStream) ![]u8 {
    // For file streams, go directly to the file handle to read efficiently
    if (stream.* == .file) {
        const file = stream.file.file;
        const file_size = file.getEndPos() catch return error.ReadFailed;
        const bytes = file.readToEndAlloc(allocator, file_size) catch return error.ReadFailed;
        return bytes;
    }

    return error.ReadFailed;
}

pub fn probe(stream: *io.ReadStream) !bool {
    const pos = stream.getPos();
    defer stream.seekTo(pos) catch {};

    // Simple magic byte check for Ogg container format
    // Ogg magic: "OggS" (0x4f 0x67 0x67 0x53)
    switch (stream.*) {
        .memory => |mem| {
            if (mem.buffer.len < 4) return false;
            return mem.buffer[0] == 0x4f and
                mem.buffer[1] == 0x67 and
                mem.buffer[2] == 0x67 and
                mem.buffer[3] == 0x53;
        },
        .file => |*fr| {
            var header: [4]u8 = undefined;
            var tmp: [1][]u8 = .{&header};
            const n = fr.interface.readVec(&tmp) catch return false;
            if (n < 4) return false;
            return header[0] == 0x4f and
                header[1] == 0x67 and
                header[2] == 0x67 and
                header[3] == 0x53;
        },
    }
}

pub fn info_reader(stream: *io.ReadStream) !api.AudioInfo {
    const pos = stream.getPos();
    defer stream.seekTo(pos) catch {};

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const temp_allocator = gpa.allocator();

    return switch (stream.*) {
        .memory => |mem| blk: {
            const handle = try openMemory(temp_allocator, mem.buffer);
            defer c.stb_vorbis_close(handle);
            break :blk infoFromHandle(handle);
        },
        .file => blk: {
            const bytes = try readAllFromFile(temp_allocator, stream);
            defer temp_allocator.free(bytes);
            const handle = try openMemory(temp_allocator, bytes);
            defer c.stb_vorbis_close(handle);
            break :blk infoFromHandle(handle);
        },
    };
}

pub fn decode_from_bytes(allocator: std.mem.Allocator, bytes: []const u8) !api.Audio {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const handle = try openMemory(arena_allocator, bytes);
    defer c.stb_vorbis_close(handle);

    const info = c.stb_vorbis_get_info(handle);
    const channels: usize = @intCast(info.channels);
    const frame_bytes = (api.SampleFormat{ .sample_type = SampleType.i16, .channel_count = @intCast(channels) }).bytesPerFrame();

    const total_samples = c.stb_vorbis_stream_length_in_samples(handle);
    if (total_samples == 0) return error.ReadFailed;
    const total_frames: usize = @intCast(total_samples);
    const total_bytes = total_frames * frame_bytes;

    var out = try allocator.alloc(u8, total_bytes);
    errdefer allocator.free(out);

    var offset: usize = 0;
    while (offset < out.len) {
        const samples_written = c.stb_vorbis_get_frame_short_interleaved(
            handle,
            @intCast(channels),
            @as([*c]c.int16, @ptrCast(@alignCast(out[offset..].ptr))),
            @intCast((out.len - offset) / @sizeOf(i16)),
        );
        if (samples_written <= 0) break;
        offset += @as(usize, @intCast(samples_written)) * channels * @sizeOf(i16);
    }

    return .{
        .params = .{
            .sample_rate = @intCast(info.sample_rate),
            .channels = @intCast(channels),
            .sample_type = SampleType.i16,
        },
        .data = out,
        .allocator = allocator,
        .format_id = .vorbis,
    };
}

const StreamCtx = struct {
    allocator: std.mem.Allocator,
    vorbis_buffer: []u8, // Buffer used by vorbis decoder
    bytes: []u8,
    vorbis: *c.stb_vorbis,
    info: api.AudioInfo,
};

fn streamRead(dec: *format.AnyStreamDecoder, dst: []u8) api.ReadError!usize {
    const ctx: *StreamCtx = @ptrCast(@alignCast(dec.context));
    if (dst.len == 0) return 0;
    const channels = ctx.info.channels;
    const samples_cap = dst.len / @sizeOf(i16);
    if (samples_cap == 0) return 0;
    const written = c.stb_vorbis_get_frame_short_interleaved(
        ctx.vorbis,
        @intCast(channels),
        @as([*c]c.int16, @ptrCast(@alignCast(dst.ptr))),
        @intCast(samples_cap),
    );
    if (written <= 0) return error.EndOfStream;
    return @as(usize, @intCast(written)) * channels * @sizeOf(i16);
}

fn streamDeinit(dec: *format.AnyStreamDecoder) void {
    const ctx: *StreamCtx = @ptrCast(@alignCast(dec.context));
    c.stb_vorbis_close(ctx.vorbis);
    ctx.allocator.free(ctx.vorbis_buffer);
    ctx.allocator.free(ctx.bytes);
    ctx.allocator.destroy(ctx);
    ctx.allocator.destroy(dec);
}

const stream_vtable = format.StreamDecoderVTable{
    .read = streamRead,
    .deinit = streamDeinit,
};

pub fn open_stream(allocator: std.mem.Allocator, stream: *io.ReadStream) !*format.AnyStreamDecoder {
    const pos = stream.getPos();
    defer stream.seekTo(pos) catch {};

    const bytes = switch (stream.*) {
        .memory => |mem| blk: {
            const buf = try allocator.alloc(u8, mem.buffer.len);
            std.mem.copyForwards(u8, buf, mem.buffer);
            break :blk buf;
        },
        .file => blk: {
            const result = try readAllFromFile(allocator, stream);
            break :blk result;
        },
    };

    var err: c_int = 0;
    const buffer_size = 256 * 1024;
    const vorbis_buffer = try allocator.alloc(u8, buffer_size);
    // errdefer allocator.free(vorbis_buffer);

    var alloc_config = c.stb_vorbis_alloc{
        .alloc_buffer = vorbis_buffer.ptr,
        .alloc_buffer_length_in_bytes = @intCast(vorbis_buffer.len),
    };
    const handle = try c.stb_vorbis_open_memory(bytes.ptr, @intCast(bytes.len), &err, &alloc_config);
    if (handle == null) {
        allocator.free(vorbis_buffer);
        return translateError(err);
    }

    const ctx = try allocator.create(StreamCtx);
    errdefer allocator.destroy(ctx);
    ctx.* = .{
        .allocator = allocator,
        .vorbis_buffer = vorbis_buffer,
        .bytes = bytes,
        .vorbis = handle,
        .info = infoFromHandle(handle),
    };

    const any = try allocator.create(format.AnyStreamDecoder);
    any.* = .{
        .vtable = &stream_vtable,
        .context = ctx,
        .info = ctx.info,
    };
    return any;
}

pub fn encode(writer: *std.Io.Writer, audio: *const api.Audio) !void {
    _ = writer;
    _ = audio;
    return error.Unsupported;
}

pub const vtable = format.VTable{
    .id = .vorbis,
    .probe = probe,
    .info_reader = info_reader,
    .decode_from_bytes = decode_from_bytes,
    .open_stream = open_stream,
    .encode = encode,
};
