const std = @import("std");
const formats = @import("formats.zig");
const io = @import("io.zig");

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

// Unmanaged audio: caller controls lifetime of data; no allocator stored
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

pub const DEFAULT_STREAM_BUFFER_SIZE: usize = 64 * 1024;

// Managed streaming handle: owns decoder and I/O buffer
pub const ManagedAudioStream = struct {
    allocator: std.mem.Allocator,
    reader: AudioReader,
    buffer: []u8,
    decoder: *AnyStreamDecoder,
    info: AudioInfo,

    pub fn readerInterface(self: *ManagedAudioStream) *std.Io.Reader {
        return &self.reader.interface;
    }

    pub fn deinit(self: *ManagedAudioStream) void {
        self.decoder.deinit();
        self.allocator.free(self.buffer);
    }
};

pub const FormatId = enum { unknown, qoa };

// Decoder/Encoder vtable. New formats register implementations here.
pub const ProbeFn = *const fn (stream: *io.ReadStream) ReadError!bool;
pub const InfoReaderFn = *const fn (stream: *io.ReadStream) ReadError!AudioInfo;
pub const DecodeBytesFn = *const fn (allocator: std.mem.Allocator, bytes: []const u8) ReadError!Audio;
pub const EncodeFn = *const fn (writer: *std.Io.Writer, audio: *const Audio, options: EncodeOptions) WriteError!void;

pub const FormatVTable = struct {
    id: FormatId,
    probe: ProbeFn,
    info_reader: InfoReaderFn,
    decode_from_bytes: DecodeBytesFn,
    encode: EncodeFn,
};

const known_formats = formats.supported_formats;

pub fn probe(reader: *std.Io.Reader) ReadError!FormatId {
    for (known_formats) |fmt| {
        var s = io.ReadStream{ .memory = reader.* };
        const is_match = fmt.probe(&s) catch |e| switch (e) {
            error.EndOfStream => false,
            else => return error.ReadFailed,
        };
        if (is_match) return fmt.id;
    }
    return error.Unsupported;
}

pub fn decode(allocator: std.mem.Allocator, reader: *std.Io.Reader) ReadError!Audio {
    var selected: ?FormatVTable = null;
    for (known_formats) |fmt| {
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
    if (selected) |format| {
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
        return format.decode_from_bytes(allocator, slice);
    } else return error.Unsupported;
}

// Generic streaming decoder interface
pub const StreamDecoderVTable = struct {
    read: *const fn (*AnyStreamDecoder, dst: []u8) ReadError!usize,
    deinit: *const fn (*AnyStreamDecoder) void,
};

pub const AnyStreamDecoder = struct {
    vtable: *const StreamDecoderVTable,
    context: *anyopaque,
    info: AudioInfo,

    pub fn read(self: *AnyStreamDecoder, dst: []u8) ReadError!usize {
        return self.vtable.read(self, dst);
    }
    pub fn deinit(self: *AnyStreamDecoder) void {
        self.vtable.deinit(self);
    }
};

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

pub fn openStreamDecoder(allocator: std.mem.Allocator, reader: *io.ReadStream) ReadError!*AnyStreamDecoder {
    // Select format using streaming probe
    var selected: ?FormatVTable = null;
    for (known_formats) |fmt| {
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

    // Read remaining to memory and decode to PCM, then expose as a streaming decoder
    var data: []u8 = &.{};
    var cap: usize = 0;
    var len: usize = 0;
    defer if (cap != 0) allocator.free(data);
    const r = reader.reader();
    while (true) {
        const buffered = r.buffered();
        if (buffered.len == 0) {
            r.fillMore() catch |e| switch (e) {
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
        r.tossBuffered();
    }
    const bytes = data[0..len];
    var audio = try selected.?.decode_from_bytes(allocator, bytes);

    const ctx = try allocator.create(MemoryPcmCtx);
    ctx.* = .{ .audio = audio, .position = 0 };

    const any = try allocator.create(AnyStreamDecoder);
    any.* = .{ .vtable = &memory_stream_vtable, .context = ctx, .info = .{
        .sample_rate = audio.params.sample_rate,
        .channels = audio.params.channels,
        .sample_type = audio.params.sample_type,
        .total_frames = audio.frameCount(),
    } };
    return any;
}

// AudioReader: implements std.Io.Reader over a streaming decoder producing PCM
pub const AudioReader = struct {
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

pub fn fromPath(allocator: std.mem.Allocator, path: []const u8) ReadError!ManagedAudioStream {
    var file = std.fs.cwd().openFile(path, .{ .mode = .read_only }) catch |e| switch (e) {
        error.FileNotFound => return error.InvalidFormat,
        else => return error.ReadFailed,
    };
    defer file.close();
    // Allocate internal buffer
    const buf = try allocator.alloc(u8, DEFAULT_STREAM_BUFFER_SIZE);
    errdefer allocator.free(buf);
    const freader = file.reader(buf);
    var stream = io.ReadStream{ .file = freader };
    const dec = try openStreamDecoder(allocator, &stream);
    const reader = AudioReader.init(dec, buf);
    return .{
        .allocator = allocator,
        .reader = reader,
        .buffer = buf,
        .decoder = dec,
        .info = dec.info,
    };
}

pub fn fromMemory(allocator: std.mem.Allocator, bytes: []const u8) ReadError!ManagedAudioStream {
    // Allocate internal buffer for output Reader interface
    const buf = try allocator.alloc(u8, DEFAULT_STREAM_BUFFER_SIZE);
    errdefer allocator.free(buf);
    var stream = io.ReadStream.initMemory(bytes);
    const dec = try openStreamDecoder(allocator, &stream);
    const reader = AudioReader.init(dec, buf);
    return .{ .allocator = allocator, .reader = reader, .buffer = buf, .decoder = dec, .info = dec.info };
}
