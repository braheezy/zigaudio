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

    const audio_path = args.next() orelse {
        std.debug.print("usage: player <path>\n", .{});
        return;
    };

    var audio = zigaudio.readFromPath(allocator, audio_path) catch |e| switch (e) {
        error.Unsupported => {
            std.debug.print("unsupported format: {s}\n", .{audio_path});
            return;
        },
        else => {
            std.debug.print("error: {}\n", .{e});
            return;
        },
    };
    defer audio.deinit();

    std.debug.print("frames: {}\n", .{audio.frameCount()});
    std.debug.print("samples: {}\n", .{audio.sampleCount()});
    std.debug.print("duration_s: {d:.3}\n", .{audio.durationSeconds()});

    const options = zoto.ContextOptions{
        .sample_rate = audio.params.sample_rate,
        .channel_count = audio.params.channels,
        .format = .int16_le,
    };

    const context = try zoto.newContext(allocator, options);
    defer context.deinit();

    context.waitForReady();

    // Wrap the decoded PCM bytes as a Reader for zoto
    var reader_iface = std.Io.Reader.fixed(audio.data);
    const player = try context.newPlayer(&reader_iface);
    defer player.deinit();

    std.debug.print("Starting playback...\n", .{});

    try player.play();

    while (player.isPlaying()) {
        std.Thread.sleep(std.time.ns_per_ms * 25);
    }

    std.debug.print("Playback finished.\n", .{});
}
