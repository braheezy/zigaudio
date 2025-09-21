const std = @import("std");
const qoa = @import("qoa.zig");
const wav = @import("wav.zig");
const api = @import("root.zig");
const io = @import("io.zig");

pub const supported_formats: []const VTable = &[_]VTable{
    qoa.vtable,
    wav.vtable,
};

pub const Id = enum { unknown, qoa, wav };

pub const ProbeFn = *const fn (stream: *io.ReadStream) api.ReadError!bool;
pub const InfoReaderFn = *const fn (stream: *io.ReadStream) api.ReadError!api.AudioInfo;
pub const DecodeBytesFn = *const fn (allocator: std.mem.Allocator, bytes: []const u8) api.ReadError!api.Audio;
pub const EncodeFn = *const fn (writer: *std.Io.Writer, audio: *const api.Audio) api.WriteError!void;

pub const StreamDecoderVTable = struct {
    read: *const fn (*AnyStreamDecoder, dst: []u8) api.ReadError!usize,
    deinit: *const fn (*AnyStreamDecoder) void,
};

pub const AnyStreamDecoder = struct {
    vtable: *const StreamDecoderVTable,
    context: *anyopaque,
    info: api.AudioInfo,

    pub fn read(self: *AnyStreamDecoder, dst: []u8) api.ReadError!usize {
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
    open_stream: *const fn (allocator: std.mem.Allocator, stream: *io.ReadStream) api.ReadError!*AnyStreamDecoder,
    encode: EncodeFn,
};
