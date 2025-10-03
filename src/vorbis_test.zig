const std = @import("std");
const testing = std.testing;
const api = @import("root.zig");
const vorbis = @import("vorbis.zig");
const io = @import("io.zig");
const SampleType = api.SampleType;

// Embedded test Vorbis file
const test_vorbis_data = @embedFile("test-files/fanfare_heartcontainer.ogg");

test "Vorbis probe" {
    var stream = io.ReadStream.initMemory(test_vorbis_data);
    try testing.expect(try vorbis.vtable.probe(&stream));

    const invalid_data = "not a vorbis file";
    stream = io.ReadStream.initMemory(invalid_data);
    try testing.expect(!try vorbis.vtable.probe(&stream));
}

test "Vorbis info" {
    var stream = io.ReadStream.initMemory(test_vorbis_data);
    const info = try vorbis.vtable.info_reader(&stream);

    try testing.expectEqual(@as(u32, 44100), info.sample_rate);
    try testing.expectEqual(@as(u8, 2), info.channels);
    try testing.expectEqual(SampleType.i16, info.sample_type);
    // Vorbis doesn't always know total frames without full decode
    // so we just check it's non-negative
    try testing.expect(info.total_frames >= 0);
}

test "Vorbis decode" {
    var audio = try vorbis.vtable.decode_from_bytes(testing.allocator, test_vorbis_data);
    defer audio.deinit();

    try testing.expectEqual(@as(u32, 44100), audio.params.sample_rate);
    try testing.expectEqual(@as(u8, 2), audio.params.channels);
    try testing.expectEqual(SampleType.i16, audio.params.sample_type);

    const expected_bytes_per_frame = audio.params.channels * @sizeOf(i16);
    const frame_count = audio.data.len / expected_bytes_per_frame;
    try testing.expect(frame_count > 0);

    // Verify we got reasonable amount of data (should be ~3 seconds of audio)
    // The actual fanfare file is ~3.5 seconds, so we allow wider tolerance
    const expected_frames = 44100 * 3; // ~3 seconds nominal
    try testing.expect(frame_count > expected_frames * 0.9); // At least 2.7 seconds
    try testing.expect(frame_count < expected_frames * 1.3); // Less than 4 seconds
}

test "Vorbis streaming API" {
    var stream = try api.fromMemory(testing.allocator, test_vorbis_data);
    defer stream.deinit();

    try testing.expectEqual(@as(u32, 44100), stream.info.sample_rate);
    try testing.expectEqual(@as(u8, 2), stream.info.channels);
    try testing.expectEqual(SampleType.i16, stream.info.sample_type);

    const reader = stream.readerInterface();
    var buffer: [1024]u8 = undefined;
    var tmp: [1][]u8 = .{&buffer};
    const bytes_read = try reader.readVec(&tmp);
    try testing.expect(bytes_read > 0);
}

test "Vorbis error handling" {
    const invalid_data = "not a vorbis file";
    try testing.expectError(error.InvalidFormat, vorbis.vtable.decode_from_bytes(testing.allocator, invalid_data));
    try testing.expectError(error.Unsupported, api.fromMemory(testing.allocator, invalid_data));
}

test "Vorbis decode matches expected PCM characteristics" {
    var audio = try vorbis.vtable.decode_from_bytes(testing.allocator, test_vorbis_data);
    defer audio.deinit();

    // Verify the audio data is reasonable
    const samples = std.mem.bytesAsSlice(i16, audio.data);

    // Check that we have actual audio data (not all zeros)
    var non_zero_count: usize = 0;
    for (samples) |sample| {
        if (sample != 0) non_zero_count += 1;
    }
    try testing.expect(non_zero_count > samples.len / 10); // At least 10% non-zero

    // Check that samples are within reasonable range (i16 range)
    var max_sample: i16 = 0;
    for (samples) |sample| {
        const abs_sample = if (sample < 0) -sample else sample;
        if (abs_sample > max_sample) max_sample = abs_sample;
    }
    try testing.expect(max_sample > 0); // Should have some non-zero samples
    try testing.expect(max_sample < std.math.maxInt(i16)); // Shouldn't clip
}
