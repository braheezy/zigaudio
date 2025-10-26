//! zigaudio: audio decode and stream playback API.
const std = @import("std");
const BitReader = @import("BitReader.zig");
const format = @import("formats.zig");

pub const Id = format.Id;
pub const Decoder = format.Decoder;

///! Common error set.
pub const Error = error{
    Unsupported,
    InvalidFormat,
    CorruptedData,
    UnsupportedSampleRate,
    UnsupportedChannelCount,
    UnsupportedBitDepth,
};

///! Error set for read/streaming APIs.
pub const ReadError = Error || std.mem.Allocator.Error || std.fs.File.ReadError || std.fs.File.SeekError || std.fs.File.OpenError || error{
    EndOfStream,
    StreamTooLong,
    ReadFailed,
};

///! Error set for write/encode APIs.
pub const WriteError = Error
    || std.mem.Allocator.Error
    || std.fs.File.OpenError
    || std.fs.File.WriteError
    || std.Io.Writer.Error;

///! Metadata about a decoded stream without requiring full decode.
/// Contains the parameters players typically need to set up output.
pub const AudioInfo = struct {
    sample_rate: u32,
    channels: u8,
    // The PCM type returned by our decoder for this format
    // (not necessarily the on-disk encoding).
    sample_type: SampleType,
    // Total PCM frames in the stream when known (0 if unknown/streaming).
    total_frames: usize,
    // Duration in seconds when known (0.0 if unknown/streaming).
    duration_seconds: f64,

    ///! Returns byte size of one interleaved PCM frame for this info.
    pub fn bytesPerFrame(self: AudioInfo) usize {
        return (SampleFormat{ .sample_type = self.sample_type, .channel_count = self.channels }).bytesPerFrame();
    }

    ///! Returns duration in seconds, calculating from total_frames if duration_seconds is 0.
    pub fn getDurationSeconds(self: AudioInfo) f64 {
        if (self.duration_seconds > 0.0) return self.duration_seconds;
        if (self.sample_rate == 0 or self.total_frames == 0) return 0.0;
        return @as(f64, @floatFromInt(self.total_frames)) / @as(f64, @floatFromInt(self.sample_rate));
    }
};

///! Canonical PCM sample types used by zigaudio decoders.
pub const SampleType = enum {
    u8,
    i16,
    i24,
    i32,
    f32,
    f64,
};

///! Convenience helpers for computing PCM layout sizes.
pub const SampleFormat = struct {
    sample_type: SampleType,
    channel_count: u8,

    pub fn bitsPerSample(self: SampleFormat) u8 {
        return switch (self.sample_type) {
            .u8 => 8,
            .i16 => 16,
            .i24 => 24,
            .i32 => 32,
            .f32 => 32,
            .f64 => 64,
        };
    }

    pub fn bytesPerFrame(self: SampleFormat) usize {
        return (self.bitsPerSample() * self.channel_count) / 8;
    }
};

///! Audio parameters describing a PCM signal.
pub const AudioParams = struct {
    sample_rate: u32,
    channels: u8,
    sample_type: SampleType,
};

///! Managed full-buffer PCM audio. Owns memory via allocator.
pub const Audio = struct {
    params: AudioParams,
    data: []u8,
    allocator: std.mem.Allocator,
    format_id: format.Id,

    pub fn initEmpty(allocator: std.mem.Allocator, params: AudioParams) Audio {
        return .{ .params = params, .data = &.{}, .allocator = allocator, .format_id = .unknown };
    }

    pub fn deinit(self: *Audio) void {
        if (self.data.len != 0) self.allocator.free(self.data);
        self.* = .{ .params = self.params, .data = &.{}, .allocator = self.allocator, .format_id = self.format_id };
    }

    pub fn frameBytes(self: *const Audio) usize {
        return (SampleFormat{ .sample_type = self.params.sample_type, .channel_count = self.params.channels }).bytesPerFrame();
    }

    pub fn frameCount(self: *const Audio) usize {
        const fb = self.frameBytes();
        return if (fb == 0) 0 else self.data.len / fb;
    }

    pub fn sampleCount(self: *const Audio) usize {
        return self.frameCount() * self.params.channels;
    }

    pub fn durationSeconds(self: *const Audio) f64 {
        if (self.params.sample_rate == 0) return 0;
        return @as(f64, @floatFromInt(self.frameCount())) / @as(f64, @floatFromInt(self.params.sample_rate));
    }
};

///! Unmanaged PCM view. Caller controls lifetime of underlying memory.
pub const AudioUnmanaged = struct {
    params: AudioParams,
    data: []const u8,

    pub fn frameBytes(self: *const AudioUnmanaged) usize {
        return (SampleFormat{ .sample_type = self.params.sample_type, .channel_count = self.params.channels }).bytesPerFrame();
    }
    pub fn frameCount(self: *const AudioUnmanaged) usize {
        const fb = self.frameBytes();
        return if (fb == 0) 0 else self.data.len / fb;
    }
    pub fn sampleCount(self: *const AudioUnmanaged) usize {
        return self.frameCount() * self.params.channels;
    }
    pub fn durationSeconds(self: *const AudioUnmanaged) f64 {
        if (self.params.sample_rate == 0) return 0;
        return @as(f64, @floatFromInt(self.frameCount())) / @as(f64, @floatFromInt(self.params.sample_rate));
    }
};

/// Reader adapter that wraps a Decoder to provide std.Io.Reader interface
pub const DecoderReader = struct {
    decoder: *Decoder,
    io_reader: std.Io.Reader,

    const Self = @This();

    pub fn init(decoder: *Decoder) Self {
        return .{
            .decoder = decoder,
            .io_reader = .{
                .vtable = &vtable,
                .buffer = &.{},
                .seek = 0,
                .end = 0,
            },
        };
    }

    pub fn reader(self: *Self) *std.Io.Reader {
        return &self.io_reader;
    }

    fn readVecFn(io_reader: *std.Io.Reader, vecs: [][]u8) std.Io.Reader.Error!usize {
        const self: *Self = @fieldParentPtr("io_reader", io_reader);

        var total: usize = 0;
        for (vecs) |vec| {
            // Align to i16 boundary
            const aligned_len = vec.len & ~@as(usize, 1);
            if (aligned_len == 0) continue;

            const aligned_slice: []align(@alignOf(i16)) u8 = @alignCast(vec[0..aligned_len]);
            const samples = std.mem.bytesAsSlice(i16, aligned_slice);
            const n = self.decoder.read(samples) catch |e| switch (e) {
                else => return error.ReadFailed,
            };
            if (n == 0) {
                if (total == 0) return error.EndOfStream;
                break;
            }

            total += n * @sizeOf(i16);
            if (n < samples.len) break; // EOF after partial read
        }

        if (total == 0) return error.EndOfStream;
        return total;
    }

    fn streamFn(r: *std.Io.Reader, w: *std.Io.Writer, limit: std.Io.Limit) std.Io.Reader.StreamError!usize {
        _ = r;
        _ = w;
        _ = limit;
        return error.EndOfStream;
    }

    fn discardFn(r: *std.Io.Reader, limit: std.Io.Limit) std.Io.Reader.Error!usize {
        _ = r;
        _ = limit;
        return error.EndOfStream;
    }

    fn rebaseFn(r: *std.Io.Reader, capacity: usize) std.Io.Reader.RebaseError!void {
        _ = r;
        _ = capacity;
        return error.EndOfStream;
    }

    const vtable = std.Io.Reader.VTable{
        .readVec = readVecFn,
        .stream = streamFn,
        .discard = discardFn,
        .rebase = rebaseFn,
    };
};

/// Open decoder from file path
pub fn openFile(allocator: std.mem.Allocator, path: []const u8) !*Decoder {
    const br = try allocator.create(BitReader);
    errdefer allocator.destroy(br);

    br.* = try BitReader.initFromFile(allocator, path);
    errdefer br.deinit();

    return try format.openDecoder(allocator, br);
}

/// Open decoder from memory buffer
pub fn openMemory(allocator: std.mem.Allocator, data: []const u8) !*Decoder {
    const br = try allocator.create(BitReader);
    errdefer allocator.destroy(br);

    br.* = BitReader.initFromMemory(allocator, data);
    errdefer br.deinit();

    return try format.openDecoder(allocator, br);
}

/// Probe file format without opening decoder
pub fn probeFile(allocator: std.mem.Allocator, path: []const u8) !Id {
    var br = try BitReader.initFromFile(allocator, path);
    defer br.deinit();
    return (try format.probe(&br)) orelse error.Unsupported;
}

/// Probe memory buffer format
pub fn probeMemory(allocator: std.mem.Allocator, data: []const u8) !Id {
    var br = BitReader.initFromMemory(allocator, data);
    return (try format.probe(&br)) orelse error.Unsupported;
}

/// Get audio info from file without full decode
pub fn infoFile(allocator: std.mem.Allocator, path: []const u8) !AudioInfo {
    var br = try BitReader.initFromFile(allocator, path);
    defer br.deinit();
    return format.getInfo(&br);
}

/// Get audio info from memory
pub fn infoMemory(allocator: std.mem.Allocator, data: []const u8) !AudioInfo {
    var br = BitReader.initFromMemory(allocator, data);
    return format.getInfo(&br);
}

/// Decode entire file into memory as i16 PCM
pub fn decodeFile(allocator: std.mem.Allocator, path: []const u8) !Audio {
    const decoder = try openFile(allocator, path);
    defer decoder.deinit();

    const info = decoder.info;
    const total_samples = if (info.total_frames > 0)
        info.total_frames * @as(usize, info.channels)
    else
        4096 * @as(usize, info.channels); // Default buffer for unknown length

    var samples = try std.ArrayList(i16).initCapacity(allocator, total_samples);
    defer samples.deinit(allocator);

    var chunk: [4096]i16 = undefined;
    while (true) {
        const n = try decoder.read(&chunk);
        if (n == 0) break;
        try samples.appendSlice(allocator, chunk[0..n]);
    }

    const data = try allocator.alloc(u8, samples.items.len * @sizeOf(i16));
    @memcpy(data, std.mem.sliceAsBytes(samples.items));

    return Audio{
        .params = .{
            .sample_rate = info.sample_rate,
            .channels = info.channels,
            .sample_type = .i16,
        },
        .data = data,
        .allocator = allocator,
        .format_id = decoder.id,
    };
}

/// Decode memory buffer into i16 PCM
pub fn decodeMemory(allocator: std.mem.Allocator, data: []const u8) !Audio {
    const decoder = try openMemory(allocator, data);
    defer decoder.deinit();

    const info = decoder.info;
    const total_samples = if (info.total_frames > 0)
        info.total_frames * @as(usize, info.channels)
    else
        4096 * @as(usize, info.channels);

    var samples = try std.ArrayList(i16).initCapacity(allocator, total_samples);
    defer samples.deinit(allocator);

    var chunk: [4096]i16 = undefined;
    while (true) {
        const n = try decoder.read(&chunk);
        if (n == 0) break;
        try samples.appendSlice(allocator, chunk[0..n]);
    }

    const pcm_data = try allocator.alloc(u8, samples.items.len * @sizeOf(i16));
    @memcpy(pcm_data, std.mem.sliceAsBytes(samples.items));

    return Audio{
        .params = .{
            .sample_rate = info.sample_rate,
            .channels = info.channels,
            .sample_type = .i16,
        },
        .data = pcm_data,
        .allocator = allocator,
        .format_id = decoder.id,
    };
}

/// Encode managed audio to a file on disk using the requested format.
pub fn encodeToPath(id: Id, path: []const u8, audio: *const Audio) WriteError!void {
    const file = try std.fs.cwd().createFile(path, .{ .truncate = true });
    defer file.close();

    var buffer: [4096]u8 = undefined;
    var file_writer = file.writer(&buffer);
    const writer = &file_writer.interface;

    try format.encode(id, writer, audio);
    try writer.flush();
}

test {
    @import("std").testing.refAllDecls(@This());
    _ = @import("qoa_test.zig");
    _ = @import("wav_test.zig");
    _ = @import("aac_test.zig");
    _ = @import("flac_test.zig");
    _ = @import("mp3/tests.zig");
    _ = @import("vorbis_test.zig");
}
