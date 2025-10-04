const std = @import("std");
const api = @import("root.zig");
const fapi = @import("formats.zig");
const io = @import("io.zig");
// External C functions from faad2 library
extern "c" fn NeAACDecOpen() ?*anyopaque;
extern "c" fn NeAACDecClose(handle: ?*anyopaque) void;
extern "c" fn NeAACDecInit(handle: ?*anyopaque, buffer: [*]const u8, buffer_size: c_ulong, samplerate: [*]c_ulong, channels: [*]u8) c_long;
extern "c" fn NeAACDecDecode(handle: ?*anyopaque, frame_info: [*]NeAACDecFrameInfo, buffer: [*]const u8, buffer_size: c_ulong) ?*anyopaque;
extern "c" fn NeAACDecGetCurrentConfiguration(handle: ?*anyopaque) [*]NeAACDecConfiguration;
extern "c" fn NeAACDecSetConfiguration(handle: ?*anyopaque, config: [*]NeAACDecConfiguration) u8;

// C structs (simplified versions)
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

// AAC format constants
const ADTS_SYNC_WORD = 0xFFF0; // 12-bit sync word
const ADTS_HEADER_SIZE = 7;

// faad2 constants
const FAAD_FMT_16BIT = 1;
const FAAD_MIN_STREAMSIZE = 768;

// Decoder state
const AacDecoder = struct {
    handle: ?*anyopaque,
    sample_rate: u32,
    channels: u8,
    initialized: bool,

    fn init(allocator: std.mem.Allocator) !*AacDecoder {
        const decoder = try allocator.create(AacDecoder);
        decoder.handle = NeAACDecOpen();
        if (decoder.handle == null) {
            allocator.destroy(decoder);
            return error.InvalidFormat;
        }
        decoder.sample_rate = 0;
        decoder.channels = 0;
        decoder.initialized = false;
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

// Probe function - checks if the stream contains AAC data
fn probe_reader(stream: *io.ReadStream) api.ReadError!bool {
    const reader = stream.reader();

    // Read first few bytes to check for ADTS sync word
    var header_buffer: [8]u8 = undefined;
    var tmp: [1][]u8 = .{&header_buffer};
    const bytes_read = try reader.readVec(&tmp);

    if (bytes_read < 2) {
        const current_pos = stream.getPos();
        try stream.seekTo(current_pos - bytes_read);
        return false;
    }

    // Check for ADTS sync word (0xFFFx) in first 2 bytes
    const sync_word = @as(u16, @intCast(header_buffer[0])) << 8 | header_buffer[1];
    const is_adts = (sync_word & 0xFFF0) == ADTS_SYNC_WORD;

    // Reset stream position
    const current_pos = stream.getPos();
    try stream.seekTo(current_pos - bytes_read);

    return is_adts;
}

// Parse ADTS header to extract audio info (similar to QOA/WAV header parsing)
fn parse_adts_header(header: []const u8) !struct { sample_rate: u32, channels: u8 } {
    if (header.len < 7) return error.InvalidFormat;

    // Check ADTS sync word
    const sync_word = (@as(u16, @intCast(header[0])) << 8) | header[1];
    if ((sync_word & 0xFFF0) != ADTS_SYNC_WORD) return error.InvalidFormat;

    // Parse ADTS header fields
    // const protection_absent = (header[1] & 0x01) != 0;
    // const profile = ((header[2] & 0xF8) >> 6) + 1; // AAC profile (1-4)
    const sample_freq_idx = (header[2] & 0x3C) >> 2;
    const channel_conf = ((header[2] & 0x03) << 2) | ((header[3] & 0xC0) >> 6);

    // Sample rate table from ADTS spec
    const sample_rates = [_]u32{ 96000, 88200, 64000, 48000, 44100, 32000, 24000, 22050, 16000, 12000, 11025, 8000, 7350, 0, 0, 0 };
    if (sample_freq_idx >= sample_rates.len or sample_rates[sample_freq_idx] == 0) {
        return error.InvalidFormat;
    }

    const channels = @as(u8, @intCast(channel_conf));
    if (channels == 0 or channels > 8) return error.InvalidFormat;

    return .{
        .sample_rate = sample_rates[sample_freq_idx],
        .channels = channels,
    };
}

// Info function - extracts metadata without full decode
fn info_reader(stream: *io.ReadStream) api.ReadError!api.AudioInfo {
    const reader = stream.reader();

    // Read enough data to parse ADTS header
    const header = reader.peek(ADTS_HEADER_SIZE) catch |e| switch (e) {
        error.EndOfStream => return error.InvalidFormat,
        else => return error.ReadFailed,
    };

    const info = parse_adts_header(header) catch return error.InvalidFormat;

    // Estimate duration from file size
    const file_size = stream.getEndPos() catch 0;
    const estimated_total_frames = if (file_size > 0) blk: {
        // Typical AAC bitrates for music are 128-320 kbps, use 128kbps as conservative estimate
        // AAC files are typically 60-80% smaller than equivalent MP3
        const estimated_bitrate_bps = 128000; // 128 kbps
        const estimated_duration_seconds = (@as(f64, @floatFromInt(file_size * 8)) / @as(f64, @floatFromInt(estimated_bitrate_bps)));
        const estimated_frames = @as(usize, @intFromFloat(estimated_duration_seconds * @as(f64, @floatFromInt(info.sample_rate))));
        break :blk estimated_frames;
    } else 0;

    return api.AudioInfo{
        .sample_rate = info.sample_rate,
        .channels = info.channels,
        .sample_type = .i16, // faad2 outputs 16-bit PCM
        .total_frames = estimated_total_frames,
        .duration_seconds = 0.0, // Let framework calculate from total_frames
    };
}

// Decode function - fully decodes AAC data to PCM
fn decode_from_bytes(allocator: std.mem.Allocator, bytes: []const u8) api.ReadError!api.Audio {
    var decoder = try AacDecoder.init(allocator);
    defer decoder.deinit(allocator);

    // Initialize decoder
    var sample_rate: c_ulong = 0;
    var channels: u8 = 0;
    const init_result = NeAACDecInit(decoder.handle, bytes.ptr, @intCast(bytes.len), @as([*]c_ulong, @ptrCast(&sample_rate)), @as([*]u8, @ptrCast(&channels)));

    if (init_result < 0) {
        return error.Unsupported;
    }

    decoder.sample_rate = @intCast(sample_rate);
    decoder.channels = channels;
    decoder.initialized = true;

    // Set output format to 16-bit PCM
    const config = NeAACDecGetCurrentConfiguration(decoder.handle);
    if (@intFromPtr(config) != 0) {
        config[0].outputFormat = FAAD_FMT_16BIT;
        _ = NeAACDecSetConfiguration(decoder.handle, config);
    }

    // Collect all decoded samples
    var samples = std.ArrayList(i16).empty;
    defer samples.deinit(allocator);

    var offset: usize = 0;
    while (offset < bytes.len) {
        var frame_info: NeAACDecFrameInfo = undefined;
        const decoded_samples = @as([*c]i16, @ptrCast(@alignCast(NeAACDecDecode(
            decoder.handle,
            @as([*]NeAACDecFrameInfo, @ptrCast(&frame_info)),
            bytes.ptr + offset,
            @intCast(bytes.len - offset),
        ))));

        if (@field(frame_info, "err") != 0) {
            return error.InvalidFormat;
        }

        if (decoded_samples != null and frame_info.samples > 0) {
            const sample_count = @as(usize, @intCast(frame_info.samples));
            const decoded_ptr = @as([*]const i16, @ptrCast(decoded_samples));
            try samples.appendSlice(allocator, decoded_ptr[0..sample_count]);
        }

        if (frame_info.bytesconsumed == 0) {
            break; // No more data to consume
        }

        offset += frame_info.bytesconsumed;
    }

    return api.Audio{
        .params = .{
            .sample_rate = decoder.sample_rate,
            .channels = decoder.channels,
            .sample_type = .i16,
        },
        .data = std.mem.sliceAsBytes(try samples.toOwnedSlice(allocator)),
        .allocator = allocator,
        .format_id = .aac,
    };
}

// Stream decoder state
const AacStreamDecoder = struct {
    allocator: std.mem.Allocator,
    decoder: *AacDecoder,
    stream: *io.ReadStream,
    buffer: std.ArrayList(u8),
    samples_buffer: std.ArrayList(i16),
    bytes_fed: usize,
    initialized: bool,

    fn init(allocator: std.mem.Allocator, stream: *io.ReadStream) !*AacStreamDecoder {
        const decoder = try AacDecoder.init(allocator);
        const self = try allocator.create(AacStreamDecoder);
        self.decoder = decoder;
        self.stream = stream;
        self.buffer = std.ArrayList(u8).empty;
        self.samples_buffer = std.ArrayList(i16).empty;
        self.bytes_fed = 0;
        self.initialized = false;
        self.allocator = allocator;
        return self;
    }

    fn deinit(self: *AacStreamDecoder, allocator: std.mem.Allocator) void {
        self.decoder.deinit(allocator);
        self.buffer.deinit();
        self.samples_buffer.deinit();
        allocator.destroy(self);
    }
};

// Stream decoder functions
fn stream_read(dec: *fapi.AnyStreamDecoder, dst: []u8) api.ReadError!usize {
    const self = @as(*AacStreamDecoder, @ptrCast(@alignCast(dec.context)));

    // First check if we have buffered samples to return
    if (self.samples_buffer.items.len > 0) {
        const requested_bytes = dst.len;
        const available_samples_bytes = self.samples_buffer.items.len * @sizeOf(i16);
        const bytes_to_copy = @min(requested_bytes, available_samples_bytes);

        if (bytes_to_copy > 0) {
            const samples_to_copy = bytes_to_copy / @sizeOf(i16);

            // Copy samples to destination buffer as bytes
            std.mem.copyForwards(
                u8,
                dst[0..bytes_to_copy],
                std.mem.sliceAsBytes(self.samples_buffer.items[0..samples_to_copy]),
            );

            // Remove copied samples from buffer
            std.mem.copyForwards(i16, self.samples_buffer.items, self.samples_buffer.items[samples_to_copy..]);
            self.samples_buffer.shrinkRetainingCapacity(self.samples_buffer.items.len - samples_to_copy);
            return bytes_to_copy;
        }
    }

    // Read more data from stream if needed
    if (self.buffer.items.len < FAAD_MIN_STREAMSIZE) {
        const reader = self.stream.reader();
        var temp_buffer: [4096]u8 = undefined;
        var tmp: [1][]u8 = .{&temp_buffer};
        const bytes_read = reader.readVec(&tmp) catch |e| switch (e) {
            error.EndOfStream => return 0,
            else => return error.ReadFailed,
        };
        if (bytes_read > 0) {
            self.buffer.appendSlice(self.allocator, temp_buffer[0..bytes_read]) catch return error.ReadFailed;
        } else {
            return 0;
        }
    }

    // Initialize decoder on first call
    if (!self.initialized and self.buffer.items.len > 0) {
        var sample_rate: c_ulong = 0;
        var channels: u8 = 0;
        const init_result = NeAACDecInit(
            self.decoder.handle,
            self.buffer.items.ptr,
            @intCast(self.buffer.items.len),
            @as([*]c_ulong, @ptrCast(&sample_rate)),
            @as([*]u8, @ptrCast(&channels)),
        );

        if (init_result >= 0) {
            self.decoder.sample_rate = @intCast(sample_rate);
            self.decoder.channels = channels;
            self.decoder.initialized = true;
            self.initialized = true;
            // Set output format to 16-bit PCM
            const config = NeAACDecGetCurrentConfiguration(self.decoder.handle);
            if (@intFromPtr(config) != 0) {
                config[0].outputFormat = FAAD_FMT_16BIT;
                _ = NeAACDecSetConfiguration(self.decoder.handle, config);
            }
        }
    }

    if (!self.initialized or self.buffer.items.len == 0) {
        return 0;
    }

    // Decode frame
    var frame_info: NeAACDecFrameInfo = undefined;
    const decoded_samples = @as([*c]i16, @ptrCast(@alignCast(NeAACDecDecode(
        self.decoder.handle,
        @as([*]NeAACDecFrameInfo, @ptrCast(&frame_info)),
        self.buffer.items.ptr,
        @intCast(self.buffer.items.len),
    ))));

    // Handle errors
    if (@field(frame_info, "err") != 0) {
        const error_code = @field(frame_info, "err");

        // If we get a syntax error and have very little data left, we've likely reached the end
        if (error_code == 13 and self.buffer.items.len < 2048) {
            self.buffer.clearRetainingCapacity();
            return 0;
        }

        return 0;
    }

    // Remove consumed bytes from buffer
    if (frame_info.bytesconsumed > 0) {
        std.mem.copyForwards(u8, self.buffer.items, self.buffer.items[frame_info.bytesconsumed..]);
        self.buffer.shrinkRetainingCapacity(self.buffer.items.len - frame_info.bytesconsumed);
    } else {
        // If no bytes were consumed, we must advance by at least 1 byte to prevent an infinite loop.
        // This can happen if the decoder cannot make sense of the current buffer.
        // This mirrors behavior seen in faad2's frontend/main.c (advance_buffer function).
        if (self.buffer.items.len > 0) {
            std.mem.copyForwards(u8, self.buffer.items, self.buffer.items[1..]);
            self.buffer.shrinkRetainingCapacity(self.buffer.items.len - 1);
        } else {
            return 0; // No more data to consume and buffer is empty
        }
    }

    if (decoded_samples != null and frame_info.samples > 0) {
        const sample_count = @as(usize, @intCast(frame_info.samples));
        if (sample_count > 0) {
            self.samples_buffer.appendSlice(
                self.allocator,
                decoded_samples[0..sample_count],
            ) catch return error.InvalidFormat;
        }

        // Now try to return some samples
        const requested_bytes = dst.len;
        const available_samples_bytes = self.samples_buffer.items.len * @sizeOf(i16);
        const bytes_to_copy = @min(requested_bytes, available_samples_bytes);

        if (bytes_to_copy > 0) {
            const samples_to_copy = bytes_to_copy / @sizeOf(i16);

            // Copy samples to destination buffer as bytes
            std.mem.copyForwards(
                u8,
                dst[0..bytes_to_copy],
                std.mem.sliceAsBytes(self.samples_buffer.items[0..samples_to_copy]),
            );

            // Remove copied samples from buffer
            std.mem.copyForwards(i16, self.samples_buffer.items, self.samples_buffer.items[samples_to_copy..]);
            self.samples_buffer.shrinkRetainingCapacity(self.samples_buffer.items.len - samples_to_copy);
            return bytes_to_copy;
        }
    }

    return 0;
}

// Note: We need to get allocator from somewhere - this will need to be fixed in the framework
fn stream_deinit(dec: *fapi.AnyStreamDecoder) void {
    const self = @as(*AacStreamDecoder, @ptrCast(@alignCast(dec.context)));
    // TODO: Need access to allocator for proper cleanup
    // For now, just leak resources
    _ = self;
}

const stream_vtable: fapi.StreamDecoderVTable = .{
    .read = stream_read,
    .deinit = stream_deinit,
};

// Open stream function - creates a streaming decoder
fn open_stream(allocator: std.mem.Allocator, stream: *io.ReadStream) api.ReadError!*fapi.AnyStreamDecoder {
    const stream_decoder = try AacStreamDecoder.init(allocator, stream);

    // Get audio info from the stream
    const info = try info_reader(stream);

    const any_decoder = try allocator.create(fapi.AnyStreamDecoder);
    any_decoder.vtable = &stream_vtable;
    any_decoder.context = stream_decoder;
    any_decoder.info = info;
    return any_decoder;
}

// Encode function - not implemented for AAC
fn encode(writer: *std.Io.Writer, audio: *const api.Audio) api.WriteError!void {
    _ = writer;
    _ = audio;
    return error.Unsupported;
}

// AAC format vtable
pub const vtable: fapi.VTable = .{
    .id = .aac,
    .probe = probe_reader,
    .info_reader = info_reader,
    .decode_from_bytes = decode_from_bytes,
    .open_stream = open_stream,
    .encode = encode,
};
