const std = @import("std");
const qoa = @import("qoa.zig");

pub const Error = error{
    Unsupported,
    InvalidFormat,
    CorruptedData,
    UnsupportedSampleRate,
    UnsupportedChannelCount,
    UnsupportedBitDepth,
};

// Common metadata returned by decoders without decoding full audio.
// Designed to contain everything a player typically needs to set up output.
pub const AudioInfo = struct {
    sample_rate: u32,
    channels: u8,
    // The PCM type returned by our decoder for this format
    // (not necessarily the on-disk encoding).
    sample_type: SampleType,
    // Total PCM frames in the stream when known (0 if unknown/streaming).
    total_frames: usize,

    pub fn bytesPerFrame(self: AudioInfo) usize {
        return (SampleFormat{ .sample_type = self.sample_type, .channel_count = self.channels }).bytesPerFrame();
    }
};

pub const ReadError = Error || std.mem.Allocator.Error || std.fs.File.OpenError || error{
    EndOfStream,
    StreamTooLong,
    ReadFailed,
};

pub const WriteError = Error || std.mem.Allocator.Error || error{
    WriteFailed,
    EndOfStream,
};

pub const SampleType = enum {
    u8,
    i16,
    i24,
    i32,
    f32,
    f64,
};

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

pub const EncodeOptions = struct {
    placeholder: u8 = 0,
};

pub const AudioParams = struct {
    sample_rate: u32,
    channels: u8,
    sample_type: SampleType,
};

pub const Audio = struct {
    params: AudioParams,
    data: []u8,
    allocator: std.mem.Allocator,

    pub fn initEmpty(allocator: std.mem.Allocator, params: AudioParams) Audio {
        return .{ .params = params, .data = &.{}, .allocator = allocator };
    }

    pub fn deinit(self: *Audio) void {
        if (self.data.len != 0) self.allocator.free(self.data);
        self.* = .{ .params = self.params, .data = &.{}, .allocator = self.allocator };
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

pub const FormatId = enum { unknown, qoa };

// Decoder/Encoder vtable. New formats register implementations here.
const ProbeFn = *const fn (bytes: []const u8) bool;
const InfoFn = *const fn (bytes: []const u8) ReadError!AudioInfo;
const DecodeBytesFn = *const fn (allocator: std.mem.Allocator, bytes: []const u8) ReadError!Audio;
const EncodeFn = *const fn (writer: *std.Io.Writer, audio: *const Audio, options: EncodeOptions) WriteError!void;

const FormatVTable = struct {
    id: FormatId,
    name: []const u8,
    probe: ProbeFn,
    info: InfoFn,
    decode_from_bytes: DecodeBytesFn,
    encode: EncodeFn,
};

// QOA adapter implementing the vtable using functions from qoa.zig
fn qoa_probe(bytes: []const u8) bool {
    // Treat only canonical header errors as non-match; anything else means not qoa
    _ = qoa.decodeHeader(bytes) catch return false;
    return true;
}

fn qoa_info(bytes: []const u8) ReadError!AudioInfo {
    const hdr = qoa.decodeHeader(bytes) catch return error.InvalidFormat;
    // qoa decoder produces i16 PCM
    return .{
        .sample_rate = hdr.sample_rate,
        .channels = @intCast(hdr.channels),
        .sample_type = .i16,
        .total_frames = hdr.sample_count,
    };
}

fn qoa_decode_from_bytes(allocator: std.mem.Allocator, bytes: []const u8) ReadError!Audio {
    return decodeQoaFromBytes(allocator, bytes) catch |e| switch (e) {
        error.InvalidMagicNumber, error.InvalidHeader, error.InvalidFileSize, error.InvalidSamples, error.InvalidFrameHeader, error.FrameTooSmall => return error.InvalidFormat,
        error.OutOfMemory => return error.OutOfMemory,
    };
}

fn qoa_encode(_writer: *std.Io.Writer, _audio: *const Audio, _options: EncodeOptions) WriteError!void {
    _ = _writer;
    _ = _audio;
    _ = _options;
    return error.Unsupported;
}

const known_formats = [_]FormatVTable{
    .{ .id = .qoa, .name = "qoa", .probe = qoa_probe, .info = qoa_info, .decode_from_bytes = qoa_decode_from_bytes, .encode = qoa_encode },
};

pub fn probe(reader: *std.Io.Reader) ReadError!FormatId {
    // Read a small prefix for probing, but fall back to full file if small
    var buf: [64]u8 = undefined;
    const n = reader.read(&buf) catch return error.ReadFailed;
    if (n == 0) return error.EndOfStream;
    for (known_formats) |fmt| {
        if (fmt.probe(buf[0..n])) return fmt.id;
    }
    return error.Unsupported;
}

pub fn decode(allocator: std.mem.Allocator, reader: *std.Io.Reader) ReadError!Audio {
    // For now, slurp the full stream then dispatch
    // Keep the cap conservative for now.
    const max_size: usize = 256 * 1024 * 1024; // 256 MiB
    const bytes = try reader.readAllAlloc(allocator, max_size);
    defer allocator.free(bytes);

    for (known_formats) |fmt| {
        if (fmt.probe(bytes)) {
            return try fmt.decode_from_bytes(allocator, bytes);
        }
    }
    return error.Unsupported;
}

pub fn encode(writer: *std.Io.Writer, audio: *const Audio, options: EncodeOptions) WriteError!void {
    // Choose an encoder by sample_type or explicit options in the future.
    // For now, only QOA could be supported later.
    for (known_formats) |fmt| {
        if (fmt.id == .qoa) return fmt.encode(writer, audio, options);
    }
    return error.Unsupported;
}

pub fn readFromPath(allocator: std.mem.Allocator, path: []const u8) ReadError!Audio {
    // Read the entire file into memory to allow format probing.
    const max_size: usize = 256 * 1024 * 1024; // 256 MiB
    const bytes = std.fs.cwd().readFileAlloc(allocator, path, max_size) catch |e| switch (e) {
        error.FileNotFound => return error.InvalidFormat,
        error.OutOfMemory => return error.OutOfMemory,
        else => return error.ReadFailed,
    };
    defer allocator.free(bytes);

    for (known_formats) |fmt| {
        if (fmt.probe(bytes)) {
            return try fmt.decode_from_bytes(allocator, bytes);
        }
    }
    return error.Unsupported;
}

pub fn writeToPath(path: []const u8, audio: *const Audio, options: EncodeOptions) WriteError!void {
    var file = try std.fs.cwd().createFile(path, .{ .read = false, .truncate = true, .exclusive = false });
    defer file.close();
    var buf: [4096]u8 = undefined;
    var file_writer = file.writer(&buf);
    const w: *std.Io.Writer = &file_writer.interface;
    try encode(w, audio, options);
    try w.flush();
}

fn decodeQoaFromBytes(allocator: std.mem.Allocator, bytes: []const u8) !Audio {
    const result = try qoa.decode(allocator, bytes);
    defer allocator.free(result.samples);

    // Prepare Audio with i16 interleaved samples.
    const ch: u8 = @intCast(result.decoder.channels);
    const total_samples: usize = @as(usize, result.decoder.sample_count) * @as(usize, result.decoder.channels);
    const total_bytes: usize = total_samples * @sizeOf(i16);

    const data = try allocator.alloc(u8, total_bytes);
    errdefer allocator.free(data);
    const src_bytes = std.mem.sliceAsBytes(result.samples);
    std.mem.copyForwards(u8, data, src_bytes);

    return .{
        .params = .{ .sample_rate = result.decoder.sample_rate, .channels = ch, .sample_type = .i16 },
        .data = data,
        .allocator = allocator,
    };
}
