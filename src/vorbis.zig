const std = @import("std");
const api = @import("root.zig");
const format = @import("formats.zig");
const BitReader = @import("BitReader.zig");
const c = @import("vorbis/vorbis.zig");

const SampleType = api.SampleType;
const ArrayList = std.ArrayList;

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
    const vorbis_info = c.stb_vorbis_get_info(handle);
    const sample_rate: u32 = @intCast(vorbis_info.sample_rate);
    const channels: u8 = @intCast(vorbis_info.channels);
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

fn openVorbis(bytes: []const u8, alloc_buffer: ?[]u8) !*c.stb_vorbis {
    var err: c_int = 0;
    if (bytes.len == 0) return error.InvalidFormat;

    var alloc_cfg: ?c.stb_vorbis_alloc = null;
    if (alloc_buffer) |buf| {
        alloc_cfg = c.stb_vorbis_alloc{
            .alloc_buffer = buf.ptr,
            .alloc_buffer_length_in_bytes = @intCast(buf.len),
        };
    }

    const alloc_ptr = if (alloc_cfg) |*cfg| cfg else null;
    const handle_opt = c.stb_vorbis_open_memory(bytes.ptr, @intCast(bytes.len), &err, alloc_ptr) catch {
        return translateError(err);
    };

    const handle = handle_opt orelse return translateError(err);
    return handle;
}

fn readAllBytes(br: *BitReader, allocator: std.mem.Allocator) ![]u8 {
    if (br.file) |*file| {
        const total = br.totalSize() orelse return error.InvalidFormat;
        try file.seekTo(0);
        const buffer = try allocator.alloc(u8, total);
        var read_total: usize = 0;
        while (read_total < total) {
            const amt = try file.read(buffer[read_total..]);
            if (amt == 0) break;
            read_total += amt;
        }
        return buffer[0..read_total];
    }

    const data = br.reader.buffer[0..br.reader.end];
    const copy = try allocator.alloc(u8, data.len);
    @memcpy(copy, data);
    return copy;
}

fn decodeEntireStream(allocator: std.mem.Allocator, bytes: []const u8) !struct {
    info: api.AudioInfo,
    samples: []i16,
} {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    // Don't provide an allocation buffer - let stb_vorbis use malloc
    const handle = try openVorbis(bytes, null);
    defer c.stb_vorbis_close(handle);

    const base_info = infoFromHandle(handle);
    if (base_info.channels == 0) return error.InvalidFormat;

    var samples = ArrayList(i16).empty;
    defer samples.deinit(allocator);

    const frame_samples: usize = 4096;
    const channel_count: usize = base_info.channels;
    const buffer_len = frame_samples * channel_count;
    var temp = try allocator.alloc(i16, buffer_len);
    defer allocator.free(temp);

    while (true) {
        const written = c.stb_vorbis_get_frame_short_interleaved(
            handle,
            @intCast(channel_count),
            @as([*c]c.int16, @ptrCast(@alignCast(temp.ptr))),
            @intCast(frame_samples),
        );
        if (written <= 0) break;
        const per_channel = @as(usize, @intCast(written));
        const total = per_channel * channel_count;
        try samples.appendSlice(allocator, temp[0..total]);
    }

    if (samples.items.len == 0) return error.InvalidFormat;

    var decoded_info = base_info;
    const total_frames = samples.items.len / channel_count;
    decoded_info.total_frames = total_frames;
    decoded_info.duration_seconds = if (decoded_info.sample_rate != 0)
        @as(f64, @floatFromInt(total_frames)) / @as(f64, @floatFromInt(decoded_info.sample_rate))
    else
        0.0;

    const owned = try samples.toOwnedSlice(allocator);
    return .{ .info = decoded_info, .samples = owned };
}

fn decoderRead(decoder: *format.Decoder, dst: []i16) !usize {
    const ctx: *DecoderContext = @ptrCast(@alignCast(decoder.context));
    if (ctx.position >= ctx.samples.len) return 0;

    const remaining = ctx.samples[ctx.position..];
    const copy_count = @min(dst.len, remaining.len);
    std.mem.copyForwards(i16, dst[0..copy_count], remaining[0..copy_count]);
    ctx.position += copy_count;
    return copy_count;
}

fn decoderDeinit(decoder: *format.Decoder) void {
    const ctx: *DecoderContext = @ptrCast(@alignCast(decoder.context));
    ctx.bit_reader.deinit();
    ctx.allocator.destroy(ctx.bit_reader);
    ctx.allocator.free(ctx.samples);
    ctx.allocator.destroy(ctx);
    decoder.allocator.destroy(decoder);
}

const decoder_vtable = format.DecoderVTable{
    .read = decoderRead,
    .deinit = decoderDeinit,
};

const DecoderContext = struct {
    allocator: std.mem.Allocator,
    samples: []i16,
    position: usize = 0,
    info: api.AudioInfo,
    bit_reader: *BitReader,
};

fn probe(br: *BitReader) !bool {
    const start_pos = br.tell();
    const saved_bits = br.bit_index;
    defer {
        br.seekTo(start_pos);
        br.bit_index = saved_bits;
    }

    if (!try br.has(32)) return false;
    br.alignToByte();
    const b0 = try br.readBits(8);
    const b1 = try br.readBits(8);
    const b2 = try br.readBits(8);
    const b3 = try br.readBits(8);
    return b0 == 'O' and b1 == 'g' and b2 == 'g' and b3 == 'S';
}

fn info(br: *BitReader) !api.AudioInfo {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var clone = try br.clone(arena.allocator());
    defer BitReader.deinitClone(&clone);

    const data = clone.reader.buffer[0..clone.reader.end];
    if (data.len == 0) return error.InvalidFormat;
    const handle = try openVorbis(data, null);
    defer c.stb_vorbis_close(handle);
    return infoFromHandle(handle);
}

fn open(allocator: std.mem.Allocator, br: *BitReader) !*format.Decoder {
    const data = try readAllBytes(br, allocator);
    defer allocator.free(data);

    const decoded = try decodeEntireStream(allocator, data);

    const ctx = try allocator.create(DecoderContext);
    ctx.* = .{
        .allocator = allocator,
        .samples = decoded.samples,
        .position = 0,
        .info = decoded.info,
        .bit_reader = br,
    };

    const decoder = try allocator.create(format.Decoder);
    decoder.* = .{
        .vtable = &decoder_vtable,
        .context = ctx,
        .info = ctx.info,
        .allocator = allocator,
        .id = .vorbis,
    };
    return decoder;
}

pub fn encode(writer: *std.Io.Writer, audio: *const api.Audio) !void {
    _ = writer;
    _ = audio;
    return error.Unsupported;
}

pub const vtable = format.VTable{
    .id = .vorbis,
    .probe = probe,
    .info = info,
    .open = open,
};
