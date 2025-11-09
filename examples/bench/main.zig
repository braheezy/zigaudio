const std = @import("std");
const zigaudio = @import("zigaudio");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command line args
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

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
    const file = try std.fs.cwd().openFile(file_path.?, .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    const file_data = try allocator.alloc(u8, file_size);
    defer allocator.free(file_data);

    const bytes_read = try file.readAll(file_data);
    if (bytes_read != file_size) return error.IncompleteRead;

    // Decode from memory (this is what we're benchmarking)
    const audio = try zigaudio.decodeMemory(allocator, file_data);
    defer {
        var mut_audio = audio;
        mut_audio.deinit();
    }

    // Optionally output metrics (disabled by default for clean benchmarking)
    if (show_metrics) {
        var stdout_buffer: [4096]u8 = undefined;
        var stdout_file = std.fs.File.stdout();
        var file_writer = stdout_file.writer(&stdout_buffer);
        const writer = &file_writer.interface;

        const format_name = switch (audio.format_id) {
            .qoa => "QOA",
            .wav => "WAV",
            .flac => "FLAC",
            .mp3 => "MP3",
            .aac => "AAC",
            .vorbis => "Vorbis",
            .unknown => "Unknown",
        };

        const duration = audio.durationSeconds();
        const bitrate_kbps = if (duration > 0)
            @as(f64, @floatFromInt(file_size * 8)) / duration / 1000.0
        else
            0.0;

        try writer.print("Format: {s}\n", .{format_name});
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
