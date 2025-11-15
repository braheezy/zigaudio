const std = @import("std");
const api = @import("root.zig");
const BitReader = @import("BitReader.zig");

// Simplified format registry - only WAV for now during migration
pub const supported_formats: []const VTable = &[_]VTable{
    @import("wav.zig").vtable,
    @import("flac.zig").vtable,
    @import("aac.zig").vtable,
    @import("mp3.zig").vtable,
    @import("qoa.zig").vtable,
    @import("vorbis.zig").vtable,
};

pub const Id = enum {
    unknown,
    qoa,
    wav,
    flac,
    mp3,
    aac,
    vorbis,
};

/// Unified decoder interface - all formats implement this
pub const Decoder = struct {
    vtable: *const DecoderVTable,
    context: *anyopaque,
    info: api.AudioInfo,
    id: Id,

    /// Read decoded PCM samples as interleaved i16
    pub fn read(self: *Decoder, dst: []i16) !usize {
        return self.vtable.read(self, dst);
    }

    /// Read decoded PCM frames into a byte buffer.
    /// The buffer should be sized as: frames * channels * sizeof(i16)
    /// Returns the number of frames read (not bytes).
    pub fn readFramesInto(self: *Decoder, dst: []u8) !usize {
        if (dst.len < 2) return 0; // Need at least one i16
        const aligned_len = dst.len & ~@as(usize, 1); // Align to i16 boundary
        const samples_slice: []i16 = @alignCast(std.mem.bytesAsSlice(i16, dst[0..aligned_len]));
        const samples_read = try self.read(samples_slice);
        return samples_read / @as(usize, self.info.channels);
    }

    /// Decode all remaining audio into a managed Audio buffer.
    /// Returns an Audio struct that must be freed with audio.deinit(allocator).
    pub fn toAudio(self: *Decoder, allocator: std.mem.Allocator) !api.Audio {
        const total_samples = if (self.info.total_frames > 0)
            self.info.total_frames * @as(usize, self.info.channels)
        else
            4096 * @as(usize, self.info.channels);

        var samples = try std.ArrayList(i16).initCapacity(allocator, total_samples);
        defer samples.deinit(allocator);

        var chunk: [4096]i16 = undefined;
        while (true) {
            const n = try self.read(&chunk);
            if (n == 0) break;
            try samples.appendSlice(allocator, chunk[0..n]);
        }

        const data = try allocator.alloc(u8, samples.items.len * @sizeOf(i16));
        @memcpy(data, std.mem.sliceAsBytes(samples.items));

        return api.Audio{
            .params = .{
                .sample_rate = self.info.sample_rate,
                .channels = self.info.channels,
                .sample_type = .i16,
            },
            .data = data,
        };
    }

    /// Decode up to max_frames into a managed Audio buffer.
    /// Useful for loading previews or limiting memory usage.
    /// Returns an Audio struct that must be freed with audio.deinit(allocator).
    pub fn toAudioLimit(self: *Decoder, allocator: std.mem.Allocator, max_frames: usize) !api.Audio {
        const max_samples = max_frames * @as(usize, self.info.channels);
        var samples = try std.ArrayList(i16).initCapacity(allocator, max_samples);
        defer samples.deinit(allocator);

        var chunk: [4096]i16 = undefined;
        while (samples.items.len < max_samples) {
            const remaining = max_samples - samples.items.len;
            const to_read = @min(chunk.len, remaining);
            const n = try self.read(chunk[0..to_read]);
            if (n == 0) break;
            try samples.appendSlice(allocator, chunk[0..n]);
        }

        const data = try allocator.alloc(u8, samples.items.len * @sizeOf(i16));
        @memcpy(data, std.mem.sliceAsBytes(samples.items));

        return api.Audio{
            .params = .{
                .sample_rate = self.info.sample_rate,
                .channels = self.info.channels,
                .sample_type = .i16,
            },
            .data = data,
        };
    }

    /// Get a std.Io.Reader interface for reading PCM data.
    /// Useful for integration with audio playback libraries.
    pub fn reader(self: *Decoder) api.DecoderReader {
        return api.DecoderReader.init(self);
    }

    /// Clean up decoder resources
    pub fn deinit(self: *Decoder, allocator: std.mem.Allocator) void {
        self.vtable.deinit(self, allocator);
    }

    /// Seek to frame position (optional, may return error.Unseekable)
    pub fn seekTo(self: *Decoder, frame: usize) !void {
        if (self.vtable.seek) |seek_fn| {
            return seek_fn(self, frame);
        }
        return error.Unseekable;
    }
};

/// Function signatures for decoder operations
pub const DecoderVTable = struct {
    read: *const fn (*Decoder, dst: []i16) anyerror!usize,
    deinit: *const fn (*Decoder, allocator: std.mem.Allocator) void,
    seek: ?*const fn (*Decoder, frame: usize) anyerror!void = null,
};

/// Format detection and decoder factory
pub const VTable = struct {
    id: Id,

    /// Probe if BitReader contains this format (should not consume data)
    probe: *const fn (*BitReader) anyerror!bool,

    /// Read audio metadata without full decode
    info: *const fn (*BitReader) anyerror!api.AudioInfo,

    /// Create streaming decoder from BitReader
    open: *const fn (allocator: std.mem.Allocator, *BitReader) anyerror!*Decoder,

    /// Encode managed audio via std.Io.Writer
    encode: ?*const fn (*std.Io.Writer, *const api.Audio) api.WriteError!void = null,
};

/// Probe all formats to find a match
pub fn probe(br: *BitReader) !?Id {
    const start_pos = br.tell();
    defer br.seekTo(start_pos); // Reset position after probing

    for (supported_formats) |fmt| {
        br.seekTo(start_pos);
        if (fmt.probe(br) catch false) {
            return fmt.id;
        }
    }
    return null;
}

/// Get audio info for detected format
pub fn getInfo(br: *BitReader) !api.AudioInfo {
    const start_pos = br.tell();
    defer br.seekTo(start_pos);

    for (supported_formats) |fmt| {
        br.seekTo(start_pos);
        if (fmt.probe(br) catch false) {
            br.seekTo(start_pos);
            return fmt.info(br);
        }
    }
    return error.Unsupported;
}

/// Open decoder for detected format
pub fn openDecoder(allocator: std.mem.Allocator, br: *BitReader) !*Decoder {
    const start_pos = br.tell();

    for (supported_formats) |fmt| {
        br.seekTo(start_pos);
        if (fmt.probe(br) catch false) {
            br.seekTo(start_pos);
            return fmt.open(allocator, br);
        }
    }
    return error.Unsupported;
}

/// Encode audio using the specified format id
pub fn encode(id: Id, writer: *std.Io.Writer, audio: *const api.Audio) api.WriteError!void {
    for (supported_formats) |fmt| {
        if (fmt.id == id) {
            if (fmt.encode) |encode_fn| {
                return encode_fn(writer, audio);
            } else {
                return error.Unsupported;
            }
        }
    }
    return error.Unsupported;
}
