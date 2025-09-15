const std = @import("std");
const zigaudio = @import("zigaudio");

const embedded: []const u8 = @embedFile("jungle_dash__pogo.qoa");

pub fn main() !void {
    const allocator = std.heap.smp_allocator;
    // Embed a fixed input for apples-to-apples memory decode
    var r = std.Io.Reader.fixed(embedded);
    var audio = try zigaudio.decode(allocator, &r);
    audio.deinit();
}
