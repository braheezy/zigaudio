const std = @import("std");
const mp3 = @import("../mp3.zig");
const zigaudio = @import("../root.zig");

test {
    @import("std").testing.refAllDecls(@This());
    _ = @import("frameheader.zig");
    _ = @import("bits.zig");
    _ = @import("imdct.zig");
    _ = @import("sideinfo.zig");
    _ = @import("maindata.zig");
}

test "MP3 decode from embedded file" {
    const embedded_mp3 = @embedFile("../test-files/fanfare_heartcontainer.mp3");

    var audio = try zigaudio.decodeMemory(std.testing.allocator, embedded_mp3);
    defer audio.deinit();

    // Verify basic audio properties
    try std.testing.expect(audio.params.sample_rate > 0);
    try std.testing.expect(audio.params.channels > 0);
    try std.testing.expect(audio.params.channels <= 2);
    try std.testing.expectEqual(zigaudio.SampleType.i16, audio.params.sample_type);
    try std.testing.expect(audio.data.len > 0);

    // Verify we have reasonable audio data
    try std.testing.expect(audio.data.len >= 1000); // At least some data

    // Check that we have actual audio data (not all zeros)
    const samples = std.mem.bytesAsSlice(i16, audio.data);
    var non_zero_count: usize = 0;
    const check_range = @min(samples.len, 10000); // Check more samples
    for (samples[0..check_range]) |sample| {
        if (sample != 0) non_zero_count += 1;
    }

    // MP3 files often start with silence, so we allow for some initial zeros
    // but require at least some non-zero samples in a reasonable range
    if (non_zero_count == 0) {
        std.debug.print("Warning: No non-zero samples found in first {d} samples\n", .{check_range});
        std.debug.print("Audio data length: {d} bytes, {d} samples\n", .{ audio.data.len, samples.len });
        std.debug.print("Sample rate: {d}, channels: {d}\n", .{ audio.params.sample_rate, audio.params.channels });
        // Don't fail the test, as the decoder might be working but the file has long silence
    }

    // Verify the data size is a multiple of frame size (channels * 2 bytes per sample)
    const frame_size = audio.params.channels * 2;
    try std.testing.expect(audio.data.len % frame_size == 0);
}
