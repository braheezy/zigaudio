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

    var play_from_memory: bool = false;
    var audio_path: ?[]const u8 = null;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--mem")) {
            play_from_memory = true;
        } else if (audio_path == null) {
            audio_path = arg;
        }
    }
    const embedded: []const u8 = @embedFile("fanfare_heartcontainer.qoa");
    if (!play_from_memory and audio_path == null) {
        std.debug.print("usage: player [--mem] <path>\n", .{});
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
    defer stream.deinit();

    std.debug.print("Audio Info:\n", .{});
    std.debug.print("  Sample Rate: {d} Hz\n", .{stream.info.sample_rate});
    std.debug.print("  Channels: {d}\n", .{stream.info.channels});
    std.debug.print("  Sample Type: {s}\n", .{@tagName(stream.info.sample_type)});
    std.debug.print("  Total Frames: {d}\n", .{stream.info.total_frames});
    std.debug.print("  Duration: {d:.2} seconds\n", .{@as(f64, @floatFromInt(stream.info.total_frames)) / @as(f64, @floatFromInt(stream.info.sample_rate))});

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
