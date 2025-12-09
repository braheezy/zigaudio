const std = @import("std");
const api = @import("root.zig");
const format = @import("formats.zig");
const BitReader = @import("BitReader.zig");
const ArrayList = std.ArrayList;

extern "c" fn NeAACDecOpen() ?*anyopaque;
extern "c" fn NeAACDecClose(handle: ?*anyopaque) void;
extern "c" fn NeAACDecInit(handle: ?*anyopaque, buffer: [*]const u8, buffer_size: c_ulong, samplerate: [*]c_ulong, channels: [*]u8) c_long;
extern "c" fn NeAACDecDecode(handle: ?*anyopaque, frame_info: [*]NeAACDecFrameInfo, buffer: [*]const u8, buffer_size: c_ulong) ?*anyopaque;
extern "c" fn NeAACDecGetCurrentConfiguration(handle: ?*anyopaque) [*]NeAACDecConfiguration;
extern "c" fn NeAACDecSetConfiguration(handle: ?*anyopaque, config: [*]NeAACDecConfiguration) u8;

const NeAACDecFrameInfo = extern struct {
    bytesconsumed: c_ulong,
    samples: c_ulong,
    channels: u8,
    err: u8,
    samplerate: c_ulong,
    sbr: u8,
    object_type: u8,
    header_type: u8,
    num_front_channels: u8,
    num_side_channels: u8,
    num_back_channels: u8,
    num_lfe_channels: u8,
    channel_position: [64]u8,
    ps: u8,
};

const NeAACDecConfiguration = extern struct {
    defObjectType: u8,
    defSampleRate: c_ulong,
    outputFormat: u8,
    downMatrix: u8,
    useOldADTSFormat: u8,
    dontUpSampleImplicitSBR: u8,
};

const ADTS_SYNC_WORD: u16 = 0xFFF0;
const ADTS_HEADER_SIZE: usize = 7;
const FAAD_FMT_16BIT: u8 = 1;

const HeaderInfo = struct {
    sample_rate: u32,
    channels: u8,
};

const AacDecoder = struct {
    handle: ?*anyopaque,

    fn init(allocator: std.mem.Allocator) !*AacDecoder {
        const decoder = try allocator.create(AacDecoder);
        decoder.handle = NeAACDecOpen();
        if (decoder.handle == null) {
            allocator.destroy(decoder);
            return error.InvalidFormat;
        }
        return decoder;
    }

    fn deinit(self: *AacDecoder, allocator: std.mem.Allocator) void {
        if (self.handle != null) {
            NeAACDecClose(self.handle);
            self.handle = null;
        }
        allocator.destroy(self);
    }
};

const DecoderContext = struct {
    samples: []f32,
    position: usize = 0,
    info: api.AudioInfo,
    bit_reader: *BitReader,
};

fn readHeaderBytes(br: *BitReader, header: []u8) !void {
    br.alignToByte();
    for (header) |*byte| {
        if (!try br.has(8)) return error.InvalidFormat;
        byte.* = @intCast(try br.readBits(8));
    }
}

fn parseAdtsHeader(bytes: []const u8) !HeaderInfo {
    if (bytes.len < ADTS_HEADER_SIZE) return error.InvalidFormat;

    const sync_word: u16 = (@as(u16, @intCast(bytes[0])) << 8) | @as(u16, @intCast(bytes[1]));
    if ((sync_word & ADTS_SYNC_WORD) != ADTS_SYNC_WORD) return error.InvalidFormat;

    const sample_freq_idx = (bytes[2] & 0x3C) >> 2;
    const channel_conf = ((bytes[2] & 0x03) << 2) | ((bytes[3] & 0xC0) >> 6);

    const sample_rates = [_]u32{
        96000, 88200, 64000, 48000, 44100, 32000, 24000, 22050,
        16000, 12000, 11025, 8000,  7350,  0,     0,     0,
    };

    if (sample_freq_idx >= sample_rates.len or sample_rates[sample_freq_idx] == 0) {
        return error.InvalidFormat;
    }

    const channels: u8 = @intCast(channel_conf);
    if (channels == 0 or channels > 8) return error.InvalidFormat;

    return .{
        .sample_rate = sample_rates[sample_freq_idx],
        .channels = channels,
    };
}

fn probe(br: *BitReader) !bool {
    const start_pos = br.tell();
    defer br.seekTo(start_pos);

    if (!try br.has(16)) return false;
    br.alignToByte();

    const b0 = try br.readBits(8);
    const b1 = try br.readBits(8);
    const sync_word: u16 = (@as(u16, @intCast(b0)) << 8) | @as(u16, @intCast(b1));
    return (sync_word & ADTS_SYNC_WORD) == ADTS_SYNC_WORD;
}

fn info(br: *BitReader) !api.AudioInfo {
    const start_pos = br.tell();
    const saved_bits = br.bit_index;
    defer {
        br.seekTo(start_pos);
        br.bit_index = saved_bits;
    }

    var header_bytes: [ADTS_HEADER_SIZE]u8 = undefined;
    readHeaderBytes(br, &header_bytes) catch return error.InvalidFormat;
    const header = parseAdtsHeader(&header_bytes) catch return error.InvalidFormat;

    return .{
        .sample_rate = header.sample_rate,
        .channels = header.channels,
        .sample_type = .f32,
        .total_frames = 0,
        .duration_seconds = 0.0,
    };
}

fn readAllBytes(br: *BitReader, allocator: std.mem.Allocator) ![]u8 {
    if (br.file) |*file| {
        const total = br.totalSize() orelse return error.InvalidFormat;
        if (total == 0) return error.InvalidFormat;

        const pos = try file.getPos();
        defer file.seekTo(pos) catch {};

        try file.seekTo(0);
        const buffer = try allocator.alloc(u8, total);
        errdefer allocator.free(buffer);

        var read_total: usize = 0;
        while (read_total < total) {
            const amt = try file.read(buffer[read_total..]);
            if (amt == 0) break;
            read_total += amt;
        }
        return buffer[0..read_total];
    }

    const data = br.reader.buffer[0..br.reader.end];
    if (data.len == 0) return error.InvalidFormat;
    const copy = try allocator.alloc(u8, data.len);
    @memcpy(copy, data);
    return copy;
}

fn decodeEntireStream(allocator: std.mem.Allocator, data: []const u8) !struct {
    info: api.AudioInfo,
    samples: []f32,
} {
    var decoder = try AacDecoder.init(allocator);
    defer decoder.deinit(allocator);

    var sample_rate: c_ulong = 0;
    var channels: u8 = 0;
    const init_result = NeAACDecInit(
        decoder.handle,
        data.ptr,
        @intCast(data.len),
        @as([*]c_ulong, @ptrCast(&sample_rate)),
        @as([*]u8, @ptrCast(&channels)),
    );
    if (init_result < 0) return error.Unsupported;

    const config = NeAACDecGetCurrentConfiguration(decoder.handle);
    if (@intFromPtr(config) != 0) {
        config[0].outputFormat = FAAD_FMT_16BIT;
        _ = NeAACDecSetConfiguration(decoder.handle, config);
    }

    var samples = ArrayList(f32).empty;
    defer samples.deinit(allocator);

    var offset: usize = 0;
    var total_samples: usize = 0;
    var decoded_info = api.AudioInfo{
        .sample_rate = @intCast(sample_rate),
        .channels = channels,
        .sample_type = .f32,
        .total_frames = 0,
        .duration_seconds = 0.0,
    };

    while (offset < data.len) {
        var frame_info: NeAACDecFrameInfo = undefined;
        const decoded_ptr = NeAACDecDecode(
            decoder.handle,
            @as([*]NeAACDecFrameInfo, @ptrCast(&frame_info)),
            data.ptr + offset,
            @intCast(data.len - offset),
        );

        if (frame_info.err != 0) return error.InvalidFormat;

        const consumed = @as(usize, @intCast(frame_info.bytesconsumed));
        if (consumed == 0) break;
        offset += consumed;

        if (decoded_ptr != null and frame_info.samples > 0) {
            const sample_count = @as(usize, @intCast(frame_info.samples));
            const pcm = @as([*]const i16, @ptrCast(@alignCast(decoded_ptr)))[0..sample_count];
            // Convert i16 to f32
            try samples.ensureTotalCapacity(allocator, samples.items.len + sample_count);
            for (pcm) |s| {
                samples.appendAssumeCapacity(@as(f32, @floatFromInt(s)) / 32768.0);
            }
            total_samples += sample_count;

            if (decoded_info.sample_rate == 0) decoded_info.sample_rate = @intCast(frame_info.samplerate);
            if (decoded_info.channels == 0) decoded_info.channels = frame_info.channels;
        }
    }

    if (decoded_info.sample_rate == 0 or decoded_info.channels == 0 or samples.items.len == 0) {
        return error.InvalidFormat;
    }

    decoded_info.total_frames = total_samples / decoded_info.channels;

    const owned = try samples.toOwnedSlice(allocator);
    return .{
        .info = decoded_info,
        .samples = owned,
    };
}

fn open(allocator: std.mem.Allocator, br: *BitReader) !*format.Decoder {
    const data = try readAllBytes(br, allocator);
    errdefer allocator.free(data);

    var header_bytes: [ADTS_HEADER_SIZE]u8 = undefined;
    const start_pos = br.tell();
    const saved_bits = br.bit_index;
    defer {
        br.seekTo(start_pos);
        br.bit_index = saved_bits;
    }

    readHeaderBytes(br, &header_bytes) catch return error.InvalidFormat;
    _ = parseAdtsHeader(&header_bytes) catch return error.InvalidFormat;

    const decoded = try decodeEntireStream(allocator, data);
    allocator.free(data);

    const ctx = try allocator.create(DecoderContext);
    ctx.* = .{
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
        .id = .aac,
    };
    return decoder;
}

fn decoderRead(decoder: *format.Decoder, dst: []f32) !usize {
    const ctx: *DecoderContext = @ptrCast(@alignCast(decoder.context));
    if (ctx.position >= ctx.samples.len) return 0;

    const remaining = ctx.samples[ctx.position..];
    const copy_count = @min(dst.len, remaining.len);
    std.mem.copyForwards(f32, dst[0..copy_count], remaining[0..copy_count]);
    ctx.position += copy_count;
    return copy_count;
}

fn decoderDeinit(decoder: *format.Decoder, allocator: std.mem.Allocator) void {
    const ctx: *DecoderContext = @ptrCast(@alignCast(decoder.context));
    ctx.bit_reader.deinit();
    allocator.destroy(ctx.bit_reader);
    allocator.free(ctx.samples);
    allocator.destroy(ctx);
    allocator.destroy(decoder);
}

const decoder_vtable = format.DecoderVTable{
    .read = decoderRead,
    .deinit = decoderDeinit,
};

pub const vtable = format.VTable{
    .id = .aac,
    .probe = probe,
    .info = info,
    .open = open,
};
