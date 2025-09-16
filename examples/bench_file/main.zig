const std = @import("std");
const zigaudio = @import("zigaudio");

pub fn main() !void {
    const allocator = std.heap.smp_allocator;
    var it = std.process.args();
    defer it.deinit();
    _ = it.next(); // program
    const path = it.next() orelse {
        std.debug.print("usage: bench_file <path>\n", .{});
        return;
    };

    var stream = try zigaudio.fromPath(allocator, path);
    defer stream.deinit();
}
