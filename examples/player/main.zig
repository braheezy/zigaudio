const std = @import("std");
const builtin = @import("builtin");
const zigaudio = @import("zigaudio");
const zoto = @import("zoto");

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

pub fn main() !void {
    const allocator, const is_debug = gpa: {
        if (builtin.os.tag == .wasi) break :gpa .{ std.heap.wasm_allocator, false };
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    // pop program name
    _ = args.next();

    var full_decode_first: bool = false;
    var audio_path: ?[]const u8 = null;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--full")) {
            full_decode_first = true;
        } else if (audio_path == null) {
            audio_path = arg;
        }
    }
    if (audio_path == null) {
        std.debug.print("usage: player [--full] <path>\n", .{});
        std.debug.print("  --full : decode entire file to memory first\n", .{});
        return;
    }

    var stdin_file = std.fs.File.stdin();
    var stdin_buf: [1]u8 = .{0};

    if (full_decode_first) {
        const path = audio_path.?;
        std.debug.print("Performing full decode\n", .{});

        var pcm = zigaudio.decodeFile(allocator, path) catch |e| switch (e) {
            error.Unsupported => {
                std.debug.print("unsupported format: {s}\n", .{path});
                return;
            },
            error.ReadFailed => {
                std.debug.print("full decode failed: ReadFailed\n", .{});
                return;
            },
            else => {
                std.debug.print("error: {}\n", .{e});
                return;
            },
        };
        defer pcm.deinit();

        std.debug.print("Audio Info:\n", .{});
        std.debug.print("  Format: {s}\n", .{@tagName(pcm.format_id)});
        std.debug.print("  Sample Rate: {d} Hz\n", .{pcm.params.sample_rate});
        std.debug.print("  Channels: {d}\n", .{pcm.params.channels});
        std.debug.print("  Sample Type: {s}\n", .{@tagName(pcm.params.sample_type)});
        const total_frames = pcm.frameCount();
        std.debug.print("  Total Frames: {d}\n", .{total_frames});
        std.debug.print("  Total Bytes: {d}\n", .{pcm.data.len});
        const total_seconds_f = @as(f64, @floatFromInt(total_frames)) / @as(f64, @floatFromInt(pcm.params.sample_rate));
        const total_seconds: u64 = @intFromFloat(@floor(total_seconds_f));
        if (total_seconds >= 60) {
            const minutes: u64 = total_seconds / 60;
            const seconds: u64 = total_seconds % 60;
            std.debug.print("  Duration: {d}m {d}s\n", .{ minutes, seconds });
        } else {
            std.debug.print("  Duration: {d}s\n", .{total_seconds});
        }
        const options = zoto.ContextOptions{
            .sample_rate = pcm.params.sample_rate,
            .channel_count = pcm.params.channels,
            .format = .int16_le,
        };
        const context = try zoto.newContext(allocator, options);
        defer context.deinit();
        context.waitForReady();

        var fixed_reader = std.Io.Reader.fixed(pcm.data);
        const player = try context.newPlayer(&fixed_reader);
        defer player.deinit();

        std.debug.print("Starting playback...\n", .{});
        try player.play();
        while (player.isPlaying()) {
            std.Thread.sleep(std.time.ns_per_ms * 25);
        }
        std.debug.print("Playback finished.\n", .{});
        return;
    }

    const path = audio_path.?;

    std.debug.print("Opening {s}\n", .{path});

    const decoder = try zigaudio.openFile(allocator, path);
    defer decoder.deinit();

    const info = decoder.info;
    const total_seconds_f = info.getDurationSeconds();
    const total_seconds: u64 = @intFromFloat(@floor(total_seconds_f));

    std.debug.print("Format: {d} Hz, {d} channels, {s}", .{
        info.sample_rate,
        info.channels,
        @tagName(info.sample_type),
    });
    if (total_seconds_f > 0.0) {
        if (total_seconds >= 60) {
            const minutes: u64 = total_seconds / 60;
            const seconds: u64 = total_seconds % 60;
            std.debug.print(", {d}m {d}s\n", .{ minutes, seconds });
        } else {
            std.debug.print(", {d}s\n", .{total_seconds});
        }
    } else {
        std.debug.print(" (duration unknown)\n", .{});
    }

    const options = zoto.ContextOptions{
        .sample_rate = info.sample_rate,
        .channel_count = info.channels,
        .format = .int16_le,
    };

    const context = try zoto.newContext(allocator, options);
    defer context.deinit();
    context.waitForReady();

    var decoder_reader = zigaudio.DecoderReader.init(decoder);
    const player = try context.newPlayer(decoder_reader.reader());
    defer player.deinit();

    std.debug.print("Starting playback...\n", .{});
    try player.play();

    var quit_requested = false;

    while (player.isPlaying() and !quit_requested) {
        std.Thread.sleep(std.time.ns_per_ms * 25);
        switch (builtin.os.tag) {
            .windows, .wasi => {},
            else => {
                var fds = [_]std.posix.pollfd{
                    .{ .fd = stdin_file.handle, .events = std.posix.POLL.IN, .revents = 0 },
                };
                const poll_res = std.posix.poll(&fds, 0) catch 0;
                if (poll_res > 0 and (fds[0].revents & std.posix.POLL.IN) != 0) {
                    const read_bytes = stdin_file.read(&stdin_buf) catch |err| switch (err) {
                        error.InputOutput => 0,
                        else => return err,
                    };
                    if (read_bytes > 0 and (stdin_buf[0] == 'q' or stdin_buf[0] == 'Q')) {
                        quit_requested = true;
                        break;
                    }
                }
            },
        }
    }

    if (quit_requested) {
        std.debug.print("Playback stopped by user.\n", .{});
    } else {
        std.debug.print("Playback finished.\n", .{});
    }
}
