const std = @import("std");

pub const ReadStream = union(enum) {
    memory: std.Io.Reader,
    file: std.fs.File.Reader,

    pub const SeekError = std.fs.File.Reader.SeekError;
    pub const SizeError = std.fs.File.Reader.SizeError;

    pub fn initMemory(buffer: []const u8) ReadStream {
        return .{ .memory = std.Io.Reader.fixed(buffer) };
    }

    pub fn initFile(file: std.fs.File, buffer: []u8) ReadStream {
        return .{ .file = file.reader(buffer) };
    }

    pub fn reader(self: *ReadStream) *std.io.Reader {
        return switch (self.*) {
            .memory => |*mem| mem,
            .file => |*fr| &fr.interface,
        };
    }

    pub fn seekTo(self: *ReadStream, offset: u64) SeekError!void {
        switch (self.*) {
            .memory => |*mem| {
                if (offset > mem.end) return SeekError.Unseekable;
                mem.seek = @intCast(offset);
            },
            .file => |*fr| {
                try fr.seekTo(offset);
            },
        }
    }

    pub fn getPos(self: *const ReadStream) u64 {
        return switch (self.*) {
            .memory => |*mem| mem.seek,
            .file => |*fr| fr.logicalPos(),
        };
    }

    pub fn getEndPos(self: *ReadStream) SizeError!u64 {
        return switch (self.*) {
            .memory => |*mem| mem.buffer.len,
            .file => |*fr| fr.getSize(),
        };
    }
};
