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

    if (builtin.os.tag != .windows) {
        const action = std.posix.Sigaction{
            .handler = .{ .handler = handleSigInt },
            .mask = std.posix.sigemptyset(),
            .flags = 0,
        };
        std.posix.sigaction(std.posix.SIG.INT, &action, null);
        std.posix.sigaction(std.posix.SIG.TERM, &action, null);
        std.posix.sigaction(std.posix.SIG.USR1, &action, null);
    }

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    // pop program name
    _ = args.next();

    var play_from_memory: bool = false;
    var full_decode_first: bool = false;
    var audio_path: ?[]const u8 = null;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--mem")) {
            play_from_memory = true;
        } else if (std.mem.eql(u8, arg, "--full")) {
            full_decode_first = true;
        } else if (audio_path == null) {
            audio_path = arg;
        }
    }
    const embedded: []const u8 = @embedFile("fanfare_heartcontainer.qoa");
    if (!play_from_memory and audio_path == null) {
        std.debug.print("usage: player [--mem] [--full] <path>\n", .{});
        return;
    }

    if (full_decode_first and !play_from_memory) {
        const path = audio_path.?;
        // Read entire file then decode from memory
        var file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
        defer file.close();
        const input_bytes = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
        defer allocator.free(input_bytes);
        std.debug.print("player: read {d} bytes\n", .{input_bytes.len});
        var pcm = zigaudio.decodeMemory(allocator, input_bytes) catch |e| switch (e) {
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

    var stream = blk: {
        if (play_from_memory) {
            break :blk zigaudio.fromMemory(allocator, embedded) catch |e| switch (e) {
                error.Unsupported => {
                    std.debug.print("unsupported format (embedded)\n", .{});
                    return;
                },
                else => {
                    std.debug.print("error: {}\n", .{e});
                    return;
                },
            };
        } else {
            const path = audio_path.?;

            break :blk zigaudio.fromPath(allocator, path) catch |e| switch (e) {
                error.Unsupported => {
                    std.debug.print("unsupported format: {s}\n", .{path});
                    return;
                },
                else => {
                    std.debug.print("error: {}\n", .{e});
                    return;
                },
            };
        }
    };

    // Calculate duration
    const total_seconds_f = stream.info.getDurationSeconds();
    const total_seconds: u64 = @intFromFloat(@floor(total_seconds_f));

    // Print platform
    std.debug.print("Platform: {s}\n", .{@tagName(builtin.os.tag)});

    // Display clean audio info
    std.debug.print("Playing: {s}\n", .{if (play_from_memory) "embedded audio" else audio_path.?});
    std.debug.print("Format: {d} Hz, {d} channels, ", .{ stream.info.sample_rate, stream.info.channels });
    if (total_seconds >= 60) {
        const minutes: u64 = total_seconds / 60;
        const seconds: u64 = total_seconds % 60;
        std.debug.print("{d}m {d}s\n", .{ minutes, seconds });
    } else {
        std.debug.print("{d}s\n", .{total_seconds});
    }

    const options = zoto.ContextOptions{
        .sample_rate = stream.info.sample_rate,
        .channel_count = stream.info.channels,
        .format = .int16_le,
    };

    const context = try zoto.newContext(allocator, options);
    defer context.deinit();

    context.waitForReady();

    const player = try context.newPlayer(stream.readerInterface());
    defer player.deinit();

    std.debug.print("Starting playback...\n", .{});

    try player.play();

    while (player.isPlaying()) {
        std.Thread.sleep(std.time.ns_per_ms * 25);
    }

    std.debug.print("Playback finished.\n", .{});
}

fn handleSigInt(sig_num: c_int) callconv(.c) void {
    _ = sig_num;
    std.debug.print("\rBye!\n", .{});
    std.process.exit(0);
}
