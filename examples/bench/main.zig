const std = @import("std");
const zigaudio = @import("zigaudio");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    // Parse command line args
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    var show_metrics = false;
    var file_path: ?[]const u8 = null;

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--metrics")) {
            show_metrics = true;
        } else if (!std.mem.startsWith(u8, arg, "-")) {
            file_path = arg;
        }
    }

    if (file_path == null) {
        std.debug.print("Usage: bench [--metrics] <audio_file>\n", .{});
        return error.MissingFilePath;
    }

    // Load entire file into memory first (minimize syscall impact on benchmark)
    const file = try std.Io.Dir.cwd().openFile(init.io, file_path.?, .{});
    defer file.close(init.io);

    const file_size = (try file.stat(init.io)).size;
    const file_data = try allocator.alloc(u8, file_size);
    defer allocator.free(file_data);

    const bytes_read = try file.readPositionalAll(init.io, file_data, 0);
    if (bytes_read != file_size) return error.IncompleteRead;

    // Decode from memory (this is what we're benchmarking)
    var audio = try zigaudio.decodeMemory(allocator, file_data);
    defer audio.deinit(allocator);

    // Optionally output metrics (disabled by default for clean benchmarking)
    if (show_metrics) {
        var stdout_buffer: [4096]u8 = undefined;
        var file_writer = std.Io.File.stdout().writer(init.io, &stdout_buffer);
        const writer = &file_writer.interface;

        const duration = audio.durationSeconds();
        const bitrate_kbps = if (duration > 0)
            @as(f64, @floatFromInt(file_size * 8)) / duration / 1000.0
        else
            0.0;

        try writer.print("Sample Rate: {d} Hz\n", .{audio.params.sample_rate});
        try writer.print("Channels: {d}\n", .{audio.params.channels});
        try writer.print("Sample Type: {s}\n", .{@tagName(audio.params.sample_type)});
        try writer.print("Duration: {d:.2} seconds\n", .{duration});
        try writer.print("Frames: {d}\n", .{audio.frameCount()});
        try writer.print("File Size: {d} bytes\n", .{file_size});
        try writer.print("Bitrate: {d:.1} kbps\n", .{bitrate_kbps});
        try writer.flush();
    }
}
