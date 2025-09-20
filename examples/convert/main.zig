const std = @import("std");
const zigaudio = @import("zigaudio");

fn detectFormatIdFromPath(path: []const u8) zigaudio.FormatId {
    const ext = std.fs.path.extension(path);
    if (std.ascii.eqlIgnoreCase(ext, ".qoa")) return .qoa;
    if (std.ascii.eqlIgnoreCase(ext, ".wav")) return .wav;
    return .unknown;
}

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

    const out_fmt = detectFormatIdFromPath(out_path);
    if (out_fmt == .unknown) {
        std.debug.print("error: unsupported output extension for: {s}\n", .{out_path});
        return error.InvalidUsage;
    }

    // Read input file fully to memory and decode via high-level API
    var file = try std.fs.cwd().openFile(in_path, .{ .mode = .read_only });
    defer file.close();
    const input_bytes = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(input_bytes);

    var mem_reader = std.Io.Reader.fixed(input_bytes);
    var pcm = try zigaudio.decode(allocator, &mem_reader);
    defer pcm.deinit();

    // Encode to requested format using high-level API
    try zigaudio.encodeToPath(out_fmt, out_path, &pcm, .{});
}
