const std = @import("std");
const testing = std.testing;
const api = @import("root.zig");
const wav = @import("wav.zig");
const io = @import("io.zig");
const SampleType = api.SampleType;

// Embedded test WAV file
const test_wav_data = @embedFile("test-files/fanfare_heartcontainer.wav");

test "WAV probe" {
    var stream = io.ReadStream.initMemory(test_wav_data);
    try testing.expect(try wav.vtable.probe(&stream));

    const invalid_data = "not a wav file";
    stream = io.ReadStream.initMemory(invalid_data);
    try testing.expect(!try wav.vtable.probe(&stream));
}

test "WAV info" {
    var stream = io.ReadStream.initMemory(test_wav_data);
    const info = try wav.vtable.info_reader(&stream);

    try testing.expectEqual(@as(u32, 44100), info.sample_rate);
    try testing.expectEqual(@as(u8, 2), info.channels);
    try testing.expectEqual(SampleType.i16, info.sample_type);
    try testing.expect(info.total_frames > 0);
}

test "WAV decode" {
    var audio = try wav.vtable.decode_from_bytes(testing.allocator, test_wav_data);
    defer audio.deinit();

    try testing.expectEqual(@as(u32, 44100), audio.params.sample_rate);
    try testing.expectEqual(@as(u8, 2), audio.params.channels);
    try testing.expectEqual(SampleType.i16, audio.params.sample_type);

    const expected_bytes_per_frame = audio.params.channels * @sizeOf(i16);
    const frame_count = audio.data.len / expected_bytes_per_frame;
    try testing.expect(frame_count > 0);
}

test "WAV streaming API" {
    var stream = try api.fromMemory(testing.allocator, test_wav_data);
    defer stream.deinit();

    try testing.expectEqual(@as(u32, 44100), stream.info.sample_rate);
    try testing.expectEqual(@as(u8, 2), stream.info.channels);
    try testing.expectEqual(SampleType.i16, stream.info.sample_type);
    try testing.expect(stream.info.total_frames > 0);

    const reader = stream.readerInterface();
    var buffer: [1024]u8 = undefined;
    var tmp: [1][]u8 = .{&buffer};
    const bytes_read = try reader.readVec(&tmp);
    try testing.expect(bytes_read > 0);
}

test "WAV error handling" {
    const invalid_data = "not a wav file";
    try testing.expectError(error.InvalidFormat, wav.vtable.decode_from_bytes(testing.allocator, invalid_data));
    try testing.expectError(error.Unsupported, api.fromMemory(testing.allocator, invalid_data));
}
