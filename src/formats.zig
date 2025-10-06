const std = @import("std");
const api = @import("root.zig");
const BitReader = @import("BitReader.zig");

// Simplified format registry - only WAV for now during migration
pub const supported_formats: []const VTable = &[_]VTable{
    @import("wav.zig").vtable,
};

pub const Id = enum {
    unknown,
    // qoa,
    wav,
    // flac,
    // vorbis,
    // mp3,
    // aac,
};

/// Unified decoder interface - all formats implement this
pub const Decoder = struct {
    vtable: *const DecoderVTable,
    context: *anyopaque,
    info: api.AudioInfo,
    allocator: std.mem.Allocator,
    id: Id,

    /// Read decoded PCM samples as interleaved i16
    pub fn read(self: *Decoder, dst: []i16) !usize {
        return self.vtable.read(self, dst);
    }

    /// Clean up decoder resources
    pub fn deinit(self: *Decoder) void {
        self.vtable.deinit(self);
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
    deinit: *const fn (*Decoder) void,
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
