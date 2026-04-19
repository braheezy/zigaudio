const std = @import("std");
const zigaudio = @import("zigaudio");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if (args.len < 3) {
        std.debug.print("usage: convert <input> <output>\n", .{});
        return error.InvalidUsage;
    }
    const in_path = args[1];
    const out_path = args[2];

    var audio = try zigaudio.decodeFile(allocator, init.io, in_path);
    defer audio.deinit(allocator);

    // Determine format from output file extension
    const format: zigaudio.Id = if (std.mem.endsWith(u8, out_path, ".mp3"))
        .mp3
    else if (std.mem.endsWith(u8, out_path, ".wav"))
        .wav
    else
        return error.UnsupportedFormat;

    try zigaudio.encodeToPath(format, init.io, out_path, &audio);
}
