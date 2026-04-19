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
pub const ReadError = Error || std.mem.Allocator.Error || std.Io.File.ReadStreamingError || std.Io.File.SeekError || std.Io.File.OpenError || error{
    EndOfStream,
    StreamTooLong,
    ReadFailed,
};

///! Error set for write/encode APIs.
pub const WriteError = Error || std.mem.Allocator.Error || std.Io.File.OpenError || std.Io.File.Writer.Error || std.Io.Writer.Error;

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
    pub fn duration(self: AudioInfo) f64 {
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

///! Full-buffer PCM audio. Caller manages memory lifetime.
pub const Audio = struct {
    params: AudioParams,
    data: []align(@alignOf(f32)) u8,

    pub fn deinit(self: *Audio, allocator: std.mem.Allocator) void {
        if (self.data.len != 0) allocator.free(self.data);
        self.* = .{ .params = self.params, .data = &.{} };
    }

    /// Get PCM samples as f32 slice (all formats decode to f32).
    /// Samples are interleaved: [L, R, L, R, ...] for stereo, in range [-1.0, 1.0].
    pub fn samples(self: *const Audio) []f32 {
        return std.mem.bytesAsSlice(f32, self.data);
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
            // Align to f32 boundary
            const aligned_len = vec.len & ~@as(usize, 3);
            if (aligned_len == 0) continue;

            const aligned_slice: []align(@alignOf(f32)) u8 = @alignCast(vec[0..aligned_len]);
            const samples = std.mem.bytesAsSlice(f32, aligned_slice);
            const n = self.decoder.read(samples) catch |e| switch (e) {
                else => return error.ReadFailed,
            };
            if (n == 0) {
                if (total == 0) return error.EndOfStream;
                break;
            }

            total += n * @sizeOf(f32);
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

/// Create a streaming decoder from a file path with automatic format detection.
/// The decoder can read PCM samples incrementally without loading the entire file.
/// Returns a decoder that must be cleaned up with decoder.deinit(allocator).
pub fn fromPath(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !*Decoder {
    const br = try allocator.create(BitReader);
    errdefer allocator.destroy(br);

    br.* = try BitReader.initFromFile(allocator, io, path);
    errdefer br.deinit();

    return try format.openDecoder(allocator, br);
}

/// Create a streaming decoder from an in-memory buffer with automatic format detection.
/// Useful for embedded audio or pre-loaded data.
/// Returns a decoder that must be cleaned up with decoder.deinit(allocator).
pub fn fromMemory(allocator: std.mem.Allocator, data: []const u8) !*Decoder {
    const br = try allocator.create(BitReader);
    errdefer allocator.destroy(br);

    br.* = BitReader.initFromMemory(allocator, data);
    errdefer br.deinit();

    return try format.openDecoder(allocator, br);
}

// Legacy aliases for backwards compatibility
pub const openFile = fromPath;
pub const openMemory = fromMemory;

/// Probe file format without opening decoder
pub fn probeFile(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !Id {
    var br = try BitReader.initFromFile(allocator, io, path);
    defer br.deinit();
    return (try format.probe(&br)) orelse error.Unsupported;
}

/// Probe memory buffer format
pub fn probeMemory(allocator: std.mem.Allocator, data: []const u8) !Id {
    var br = BitReader.initFromMemory(allocator, data);
    return (try format.probe(&br)) orelse error.Unsupported;
}

/// Get audio info from file without full decode
pub fn infoFile(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !AudioInfo {
    var br = try BitReader.initFromFile(allocator, io, path);
    defer br.deinit();
    return format.getInfo(&br);
}

/// Get audio info from memory
pub fn infoMemory(allocator: std.mem.Allocator, data: []const u8) !AudioInfo {
    var br = BitReader.initFromMemory(allocator, data);
    return format.getInfo(&br);
}

/// Decode entire file into memory as f32 PCM.
/// Convenience function that opens a decoder and reads all audio data.
/// For streaming or partial decoding, use fromPath() and decoder methods instead.
pub fn decodeFile(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !Audio {
    const decoder = try fromPath(allocator, io, path);
    defer decoder.deinit(allocator);
    return try decoder.toAudio(allocator);
}

/// Decode memory buffer into f32 PCM.
/// Convenience function that opens a decoder and reads all audio data.
/// For streaming, use fromMemory() and decoder methods instead.
pub fn decodeMemory(allocator: std.mem.Allocator, data: []const u8) !Audio {
    const decoder = try fromMemory(allocator, data);
    defer decoder.deinit(allocator);
    return try decoder.toAudio(allocator);
}

/// Encode managed audio to a file on disk using the requested format.
pub fn encodeToPath(id: Id, io: std.Io, path: []const u8, audio: *const Audio) WriteError!void {
    const file = try std.Io.Dir.cwd().createFile(io, path, .{ .truncate = true });
    defer file.close(io);

    var buffer: [4096]u8 = undefined;
    var file_writer = file.writer(io, &buffer);

    try format.encode(id, &file_writer.interface, audio);
    try file_writer.interface.flush();
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
