//! zigaudio: audio decode and stream playback API.
const std = @import("std");
const io = @import("io.zig");
const format = @import("formats.zig");

pub const Id = format.Id;

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
pub const ReadError = Error || std.mem.Allocator.Error || std.fs.File.OpenError || error{
    EndOfStream,
    StreamTooLong,
    ReadFailed,
};

///! Error set for write/encode APIs.
pub const WriteError = Error || std.mem.Allocator.Error || error{
    WriteFailed,
    EndOfStream,
};

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

/// Streaming handle wrapping a decoder and I/O buffers. Caller owns it.
pub const ManagedAudioStream = struct {
    allocator: std.mem.Allocator,
    reader: AudioReader,
    buffer: []u8,
    // Optional input buffer used by file-backed readers; freed on deinit
    input_buffer: []u8 = &.{},
    // Owned stream and file for true streaming decoders
    stream: ?*io.ReadStream = null,
    file: ?std.fs.File = null,
    decoder: *AnyStreamDecoder,
    info: AudioInfo,
    // Present when opened from memory
    source_bytes: ?[]const u8 = null,

    /// Returns a std.Io.Reader that streams interleaved int16 PCM.
    pub fn readerInterface(self: *ManagedAudioStream) *std.Io.Reader {
        return &self.reader.interface;
    }

    /// Releases all resources owned by the stream. Must be called.
    pub fn deinit(self: *ManagedAudioStream) void {
        self.decoder.deinit();
        self.allocator.free(self.buffer);
        if (self.input_buffer.len != 0) self.allocator.free(self.input_buffer);
        if (self.file) |*f| f.close();
        if (self.stream) |s| self.allocator.destroy(s);
    }

    /// Fully decode this stream into managed PCM `Audio` using provided allocator.
    pub fn toAudio(self: *ManagedAudioStream, allocator: std.mem.Allocator) ReadError!Audio {
        if (self.file) |_| {
            // Re-decode from file path by seeking to start using a fresh reader
            // Note: reuse of existing file handle risks interfering with active decoder.
            // Open a fresh reader over the same file descriptor.
            var dup = self.file.?; // duplicate handle semantics are OS-specific; reopen via path is safer but path not stored
            // Fallback: seek to start and decode via temporary buffer
            dup.seekTo(0) catch return error.ReadFailed;
            const buf = try allocator.alloc(u8, DEFAULT_STREAM_BUFFER_SIZE);
            defer allocator.free(buf);
            var fr = dup.reader(buf);
            return try decode(allocator, &fr.interface);
        }
        if (self.source_bytes) |bytes| {
            return try decode(allocator, &std.Io.Reader.fixed(bytes));
        }
        // As a generic fallback, drain current decoder to an Audio buffer using stream info
        const bytes_per_frame = (SampleFormat{ .sample_type = self.info.sample_type, .channel_count = self.info.channels }).bytesPerFrame();
        const total_frames = self.info.total_frames;
        if (total_frames == 0) return error.Unsupported; // unknown length; caller should decode from source
        const total_bytes = total_frames * bytes_per_frame;
        var out = try allocator.alloc(u8, total_bytes);
        errdefer allocator.free(out);
        var written: usize = 0;
        var tmp_reader = self.readerInterface();
        while (written < total_bytes) {
            const dst = out[written..];
            var tmp: [1][]u8 = .{dst};
            const n = tmp_reader.readVec(&tmp) catch |e| switch (e) {
                error.EndOfStream => break,
                else => return error.ReadFailed,
            };
            if (n == 0) break;
            written += n;
        }
        return .{ .params = .{ .sample_rate = self.info.sample_rate, .channels = self.info.channels, .sample_type = self.info.sample_type }, .data = out, .allocator = allocator };
    }

    /// Read up to dst capacity worth of PCM frames into dst and return frames written.
    /// dst length must be a multiple of info.bytesPerFrame().
    pub fn readFramesInto(self: *ManagedAudioStream, dst: []u8) ReadError!usize {
        const frame_bytes = (SampleFormat{ .sample_type = self.info.sample_type, .channel_count = self.info.channels }).bytesPerFrame();
        const allowed = dst.len - (dst.len % frame_bytes);
        if (allowed == 0) return 0;
        var reader_ptr = self.readerInterface();
        var tmp: [1][]u8 = .{dst[0..allowed]};
        const n = reader_ptr.readVec(&tmp) catch |e| switch (e) {
            error.EndOfStream => 0,
            else => return error.ReadFailed,
        };
        return n / frame_bytes;
    }

    /// Fully decode up to max_frames (or EOF) into a managed Audio buffer.
    pub fn toAudioLimit(self: *ManagedAudioStream, allocator: std.mem.Allocator, max_frames: usize) ReadError!Audio {
        const frame_bytes = (SampleFormat{ .sample_type = self.info.sample_type, .channel_count = self.info.channels }).bytesPerFrame();
        const max_bytes = max_frames * frame_bytes;
        var out = try allocator.alloc(u8, max_bytes);
        errdefer allocator.free(out);
        var written: usize = 0;
        var reader_ptr = self.readerInterface();
        while (written < max_bytes) {
            var tmp: [1][]u8 = .{out[written..max_bytes]};
            const n = reader_ptr.readVec(&tmp) catch |e| switch (e) {
                error.EndOfStream => break,
                else => return error.ReadFailed,
            };
            if (n == 0) break;
            written += n;
        }
        // Shrink to bytes actually read
        const used_frames = written / frame_bytes;
        const used_bytes = used_frames * frame_bytes;
        const data = out[0..used_bytes];
        return .{ .params = .{ .sample_rate = self.info.sample_rate, .channels = self.info.channels, .sample_type = self.info.sample_type }, .data = data, .allocator = allocator };
    }
};

/// Unmanaged streaming handle: caller supplies both input and output buffers.
pub const AudioStream = struct {
    reader: AudioReader,
    buffer: []u8,
    input_buffer: []u8,
    stream: io.ReadStream,
    file: std.fs.File,
    decoder: *AnyStreamDecoder,
    info: AudioInfo,

    pub fn readerInterface(self: *AudioStream) *std.Io.Reader {
        return &self.reader.interface;
    }
    pub fn deinit(self: *AudioStream) void {
        self.decoder.deinit();
        self.file.close();
        // buffers are unmanaged, caller owns them
    }
    /// Read up to dst capacity worth of PCM frames into dst and return frames written.
    /// dst length must be a multiple of info.bytesPerFrame(). Caller owns dst.
    pub fn readFramesInto(self: *AudioStream, dst: []u8) ReadError!usize {
        const frame_bytes = (SampleFormat{ .sample_type = self.info.sample_type, .channel_count = self.info.channels }).bytesPerFrame();
        const allowed = dst.len - (dst.len % frame_bytes);
        if (allowed == 0) return 0;
        var reader_ptr = self.readerInterface();
        var tmp: [1][]u8 = .{dst[0..allowed]};
        const n = reader_ptr.readVec(&tmp) catch |e| switch (e) {
            error.EndOfStream => 0,
            else => return error.ReadFailed,
        };
        return n / frame_bytes;
    }
    pub fn toAudio(self: *AudioStream, allocator: std.mem.Allocator) ReadError!Audio {
        // Re-decode from file start with a fresh reader using caller allocator
        self.file.seekTo(0) catch return error.ReadFailed;
        const buf = try allocator.alloc(u8, DEFAULT_STREAM_BUFFER_SIZE);
        defer allocator.free(buf);
        var fr = self.file.reader(buf);
        return try decode(allocator, &fr.interface);
    }
};

/// Probes a generic reader and returns the detected format id.
pub fn probe(reader: *std.Io.Reader) ReadError!format.Id {
    for (format.supported_formats) |fmt| {
        var s = io.ReadStream{ .memory = reader.* };
        const is_match = fmt.probe(&s) catch |e| switch (e) {
            error.EndOfStream => false,
            else => return error.ReadFailed,
        };
        if (is_match) return fmt.id;
    }
    return error.Unsupported;
}

/// Fully decodes an entire stream into managed PCM `Audio`.
pub fn decode(allocator: std.mem.Allocator, reader: *std.Io.Reader) ReadError!Audio {
    var selected: ?format.VTable = null;
    for (format.supported_formats) |fmt| {
        var s = io.ReadStream{ .memory = reader.* };
        const is_match = fmt.probe(&s) catch |e| switch (e) {
            error.EndOfStream => false,
            else => return error.ReadFailed,
        };
        if (is_match) {
            selected = fmt;
            break;
        }
    }
    if (selected) |fmt_tbl| {
        // Stream remaining bytes into a growable buffer without consuming the header
        var data: []u8 = &.{};
        var cap: usize = 0;
        var len: usize = 0;
        defer if (cap != 0) allocator.free(data);

        while (true) {
            const buffered = reader.buffered();
            if (buffered.len == 0) {
                reader.fillMore() catch |e| switch (e) {
                    error.EndOfStream => break,
                    else => return error.ReadFailed,
                };
                continue;
            }

            const need = len + buffered.len;
            if (need > cap) {
                const new_cap = if (cap == 0) @max(@as(usize, 4096), need) else @max(cap * 2, need);
                if (cap == 0) {
                    data = try allocator.alloc(u8, new_cap);
                } else {
                    data = allocator.realloc(data, new_cap) catch return error.OutOfMemory;
                }
                cap = new_cap;
            }
            std.mem.copyForwards(u8, data[len .. len + buffered.len], buffered);
            len += buffered.len;
            reader.tossBuffered();
        }

        const slice = data[0..len];
        return fmt_tbl.decode_from_bytes(allocator, slice);
    } else return error.Unsupported;
}

/// Encodes managed PCM `Audio` to a writer using the given format.
pub fn encodeToWriter(format_id: format.Id, writer: *std.Io.Writer, audio: *const Audio) WriteError!void {
    const fmt = findFormatById(format_id) orelse return error.Unsupported;
    return fmt.encode(writer, audio);
}

/// Encodes managed PCM `Audio` directly to a file path using the given format.
pub fn encodeToPath(format_id: format.Id, path: []const u8, audio: *const Audio) WriteError!void {
    var file = std.fs.cwd().createFile(path, .{ .truncate = true }) catch return error.WriteFailed;
    defer file.close();
    // Bypass buffered writer to avoid partial flush issues: write directly to file
    switch (format_id) {
        .qoa => {
            // Use direct file encoder to control flushing/size
            @import("qoa.zig").encodeToFile(file, audio) catch return error.WriteFailed;
        },
        else => {
            const buf = try std.heap.page_allocator.alloc(u8, DEFAULT_STREAM_BUFFER_SIZE);
            defer std.heap.page_allocator.free(buf);
            var fw = file.writer(buf);
            try encodeToWriter(format_id, &fw.interface, audio);
        },
    }
}

/// High-level: open a path as a streaming PCM source.
/// Open a streaming handle from a file path.
/// If `out_buffer` is null, an internal buffer is allocated.
pub fn fromPathWithBuffer(allocator: std.mem.Allocator, path: []const u8, out_buffer: ?[]u8) ReadError!ManagedAudioStream {
    const file = std.fs.cwd().openFile(path, .{ .mode = .read_only }) catch |e| switch (e) {
        error.FileNotFound => return error.FileNotFound,
        else => return error.ReadFailed,
    };
    // Allocate input buffer and use caller buffer or internal for output
    const in_buf = try allocator.alloc(u8, DEFAULT_STREAM_BUFFER_SIZE);
    errdefer allocator.free(in_buf);
    const out_buf = out_buffer orelse blk: {
        const tmp = try allocator.alloc(u8, DEFAULT_STREAM_BUFFER_SIZE);
        errdefer allocator.free(tmp);
        break :blk tmp;
    };
    const stream_local = io.ReadStream.initFile(file, in_buf);
    const stream_ptr = try allocator.create(io.ReadStream);
    errdefer allocator.destroy(stream_ptr);
    stream_ptr.* = stream_local;
    const dec = try openStreamDecoder(allocator, stream_ptr);
    const reader = AudioReader.init(dec, out_buf);
    return .{
        .allocator = allocator,
        .reader = reader,
        .buffer = out_buf,
        .input_buffer = in_buf,
        .stream = stream_ptr,
        .file = file,
        .decoder = dec,
        .info = dec.info,
    };
}
/// Unmanaged stream: caller supplies both input and output buffers and owns them.
pub fn fromPathUnmanaged(path: []const u8, input_buffer: []u8, output_buffer: []u8) ReadError!AudioStream {
    const file = std.fs.cwd().openFile(path, .{ .mode = .read_only }) catch |e| switch (e) {
        error.FileNotFound => return error.FileNotFound,
        else => return error.ReadFailed,
    };
    var stream_local = io.ReadStream.initFile(file, input_buffer);
    const dec = try openStreamDecoder(std.heap.page_allocator, &stream_local);
    const reader = AudioReader.init(dec, output_buffer);
    return .{ .reader = reader, .buffer = output_buffer, .input_buffer = input_buffer, .stream = stream_local, .file = file, .decoder = dec, .info = dec.info };
}

/// Convenience: open a streaming handle with an internal buffer.
pub fn fromPath(allocator: std.mem.Allocator, path: []const u8) ReadError!ManagedAudioStream {
    const file = std.fs.cwd().openFile(path, .{ .mode = .read_only }) catch |e| switch (e) {
        error.FileNotFound => return error.FileNotFound,
        else => return error.ReadFailed,
    };
    const in_buf = try allocator.alloc(u8, DEFAULT_STREAM_BUFFER_SIZE);
    errdefer allocator.free(in_buf);
    const out_buf = try allocator.alloc(u8, DEFAULT_STREAM_BUFFER_SIZE);
    errdefer allocator.free(out_buf);
    const stream_local = io.ReadStream.initFile(file, in_buf);
    const stream_ptr = try allocator.create(io.ReadStream);
    errdefer allocator.destroy(stream_ptr);
    stream_ptr.* = stream_local;
    const dec = try openStreamDecoder(allocator, stream_ptr);
    const reader = AudioReader.init(dec, out_buf);
    return .{
        .allocator = allocator,
        .reader = reader,
        .buffer = out_buf,
        .input_buffer = in_buf,
        .stream = stream_ptr,
        .file = file,
        .decoder = dec,
        .info = dec.info,
    };
}

/// Fully decode a file at path into managed PCM `Audio`.
pub fn decodePath(allocator: std.mem.Allocator, path: []const u8) ReadError!Audio {
    var file = std.fs.cwd().openFile(path, .{ .mode = .read_only }) catch |e| switch (e) {
        error.FileNotFound => return error.FileNotFound,
        else => return error.ReadFailed,
    };
    defer file.close();
    const buf = try allocator.alloc(u8, DEFAULT_STREAM_BUFFER_SIZE);
    defer allocator.free(buf);
    var fr = file.reader(buf);
    return try decode(allocator, &fr.interface);
}

/// High-level: open an in-memory buffer as a streaming PCM source.
/// Test-only helper retained for compatibility: open from embedded bytes.
/// Not intended for downstream callers; prefer `fromPath(..., .{ .mode = .stream })`.
pub fn fromMemory(allocator: std.mem.Allocator, bytes: []const u8) ReadError!ManagedAudioStream {
    const buf = try allocator.alloc(u8, DEFAULT_STREAM_BUFFER_SIZE);
    errdefer allocator.free(buf);
    const stream_local = io.ReadStream.initMemory(bytes);
    const stream_ptr = try allocator.create(io.ReadStream);
    errdefer allocator.destroy(stream_ptr);
    stream_ptr.* = stream_local;
    const dec = try openStreamDecoder(allocator, stream_ptr);
    const reader = AudioReader.init(dec, buf);
    return .{ .allocator = allocator, .reader = reader, .buffer = buf, .stream = stream_ptr, .decoder = dec, .info = dec.info };
}

/// Convenience: fully decode in-memory bytes to managed PCM `Audio`.
pub fn decodeMemory(allocator: std.mem.Allocator, bytes: []const u8) ReadError!Audio {
    var r = std.Io.Reader.fixed(bytes);
    return try decode(allocator, &r);
}

/// Default size for internal streaming buffers.
const DEFAULT_STREAM_BUFFER_SIZE: usize = 64 * 1024;

fn findFormatById(id: format.Id) ?format.VTable {
    for (format.supported_formats) |fmt| {
        if (fmt.id == id) return fmt;
    }
    return null;
}

// Generic streaming decoder interface
const StreamDecoderVTable = format.StreamDecoderVTable;
const AnyStreamDecoder = format.AnyStreamDecoder;

const MemoryPcmCtx = struct {
    audio: Audio,
    position: usize,
};

fn memory_read(dec: *AnyStreamDecoder, dst: []u8) ReadError!usize {
    const ctx: *MemoryPcmCtx = @ptrCast(@alignCast(dec.context));
    const remaining = ctx.audio.data.len - ctx.position;
    if (remaining == 0) return error.EndOfStream;
    const n = @min(dst.len, remaining);
    std.mem.copyForwards(u8, dst[0..n], ctx.audio.data[ctx.position .. ctx.position + n]);
    ctx.position += n;
    return n;
}

fn memory_deinit(dec: *AnyStreamDecoder) void {
    const ctx: *MemoryPcmCtx = @ptrCast(@alignCast(dec.context));
    var audio = ctx.audio;
    audio.deinit();
    const allocator = audio.allocator; // kept for freeing ctx and dec
    allocator.destroy(ctx);
    allocator.destroy(dec);
}

const memory_stream_vtable: StreamDecoderVTable = .{
    .read = memory_read,
    .deinit = memory_deinit,
};

/// Opens a true streaming decoder over an input `ReadStream`.
fn openStreamDecoder(allocator: std.mem.Allocator, reader: *io.ReadStream) ReadError!*AnyStreamDecoder {
    // Select format using streaming probe
    var selected: ?format.VTable = null;
    for (format.supported_formats) |fmt| {
        const is_match = fmt.probe(reader) catch |e| switch (e) {
            error.EndOfStream => false,
            else => return error.ReadFailed,
        };
        if (is_match) {
            selected = fmt;
            break;
        }
    }
    if (selected == null) return error.Unsupported;
    // Delegate to the format's true streaming open
    return selected.?.open_stream(allocator, reader);
}

// AudioReader: implements std.Io.Reader over a streaming decoder producing PCM
const AudioReader = struct {
    interface: std.Io.Reader,
    decoder: *AnyStreamDecoder,
    start_ms: i64,

    pub fn init(decoder: *AnyStreamDecoder, buffer: []u8) AudioReader {
        const r: AudioReader = .{
            .interface = .{
                .vtable = &.{
                    .stream = AudioReader.stream,
                    .readVec = AudioReader.readVec,
                    .discard = AudioReader.discard,
                },
                .buffer = buffer,
                .seek = 0,
                .end = 0,
            },
            .decoder = decoder,
            .start_ms = std.time.milliTimestamp(),
        };
        return r;
    }

    fn stream(reader: *std.Io.Reader, w: *std.Io.Writer, limit: std.io.Limit) std.Io.Reader.StreamError!usize {
        const dst = limit.slice(try w.writableSliceGreedy(1));
        var tmp: [1][]u8 = .{dst};
        const n = try AudioReader.readVec(reader, &tmp);
        w.advance(n);
        return n;
    }

    fn readVec(reader: *std.Io.Reader, data: [][]u8) std.Io.Reader.Error!usize {
        const self: *AudioReader = @alignCast(@fieldParentPtr("interface", reader));
        // Try to fill from decoder directly into the largest provided slice
        var total_written: usize = 0;
        const frame_bytes = (SampleFormat{ .sample_type = self.decoder.info.sample_type, .channel_count = self.decoder.info.channels }).bytesPerFrame();
        for (data) |buf| {
            if (buf.len == 0) continue;
            const allowed_len = buf.len - (buf.len % frame_bytes);
            if (allowed_len == 0) continue;
            const n = self.decoder.read(buf[0..allowed_len]) catch |e| switch (e) {
                error.EndOfStream => {
                    if (total_written == 0) return error.EndOfStream;
                    return total_written;
                },
                error.ReadFailed => return error.ReadFailed,
                else => return error.ReadFailed,
            };
            total_written += n;
            if (n < allowed_len) break; // short read
        }
        return total_written;
    }

    fn discard(reader: *std.Io.Reader, limit: std.io.Limit) std.Io.Reader.Error!usize {
        const self: *AudioReader = @alignCast(@fieldParentPtr("interface", reader));
        var to_discard = @intFromEnum(limit);
        var total: usize = 0;
        var sink_buf: [4096]u8 = undefined;
        while (to_discard != 0) {
            const chunk = @min(sink_buf.len, to_discard);
            const n = self.decoder.read(sink_buf[0..chunk]) catch |e| switch (e) {
                error.EndOfStream => return total,
                else => return error.ReadFailed,
            };
            total += n;
            to_discard -= n;
        }
        return total;
    }
};

test {
    @import("std").testing.refAllDecls(@This());
    _ = @import("qoa_test.zig");
    _ = @import("wav_test.zig");
    _ = @import("mp3/tests.zig");
}
