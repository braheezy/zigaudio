const std = @import("std");
const zigaudio = @import("zigaudio");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args_iter = try std.process.argsWithAllocator(allocator);
    defer args_iter.deinit();

    _ = args_iter.next(); // program name
    const in_path = args_iter.next() orelse {
        std.debug.print("usage: convert <input> <output>\n", .{});
        return error.InvalidUsage;
    };
    const out_path = args_iter.next() orelse {
        std.debug.print("usage: convert <input> <output>\n", .{});
        return error.InvalidUsage;
    };

    var audio = try zigaudio.decodeFile(allocator, in_path);
    defer audio.deinit(allocator);

    try zigaudio.encodeToPath(.wav, out_path, &audio);
}
