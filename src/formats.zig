const std = @import("std");
const qoa = @import("qoa.zig");
const wav = @import("wav.zig");
const mp3 = @import("mp3.zig");
const aac = @import("aac.zig");
const vorbis = @import("vorbis.zig");
const api = @import("root.zig");
const io = @import("io.zig");

pub const supported_formats: []const VTable = &[_]VTable{
    qoa.vtable,
    wav.vtable,
    vorbis.vtable, // Vorbis has strong Ogg magic bytes, check before MP3
    aac.vtable,
    mp3.vtable, // MP3 has weak magic and can false-positive, check last
};

pub const Id = enum {
    unknown,
    qoa,
    wav,
    vorbis,
    mp3,
    aac,
};

pub const ProbeFn = *const fn (stream: *io.ReadStream) anyerror!bool;
pub const InfoReaderFn = *const fn (stream: *io.ReadStream) anyerror!api.AudioInfo;
pub const DecodeBytesFn = *const fn (allocator: std.mem.Allocator, bytes: []const u8) anyerror!api.Audio;
pub const EncodeFn = *const fn (writer: *std.Io.Writer, audio: *const api.Audio) anyerror!void;

pub const StreamDecoderVTable = struct {
    read: *const fn (*AnyStreamDecoder, dst: []u8) anyerror!usize,
    deinit: *const fn (*AnyStreamDecoder) void,
};

pub const AnyStreamDecoder = struct {
    vtable: *const StreamDecoderVTable,
    context: *anyopaque,
    info: api.AudioInfo,

    pub fn read(self: *AnyStreamDecoder, dst: []u8) !usize {
        return self.vtable.read(self, dst);
    }
    pub fn deinit(self: *AnyStreamDecoder) void {
        self.vtable.deinit(self);
    }
};

pub const VTable = struct {
    id: Id,
    probe: ProbeFn,
    info_reader: InfoReaderFn,
    decode_from_bytes: DecodeBytesFn,
    open_stream: *const fn (allocator: std.mem.Allocator, stream: *io.ReadStream) anyerror!*AnyStreamDecoder,
    encode: EncodeFn,
};
