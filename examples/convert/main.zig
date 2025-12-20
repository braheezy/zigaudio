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

    // Determine format from output file extension
    const format: zigaudio.Id = if (std.mem.endsWith(u8, out_path, ".mp3"))
        .mp3
    else if (std.mem.endsWith(u8, out_path, ".wav"))
        .wav
    else
        return error.UnsupportedFormat;

    try zigaudio.encodeToPath(format, out_path, &audio);
}
