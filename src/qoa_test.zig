const std = @import("std");
const testing = std.testing;
const api = @import("root.zig");
const qoa = @import("qoa.zig");
const io = @import("io.zig");
const SampleType = api.SampleType;

// Embedded test QOA file
const test_qoa_data = @embedFile("test-files/fanfare_heartcontainer.qoa");

test "QOA probe" {
    var stream = io.ReadStream.initMemory(test_qoa_data);
    try testing.expect(try qoa.vtable.probe(&stream));

    const invalid_data = "not a qoa file";
    stream = io.ReadStream.initMemory(invalid_data);
    try testing.expect(!try qoa.vtable.probe(&stream));
}

test "QOA info" {
    var stream = io.ReadStream.initMemory(test_qoa_data);
    const info = try qoa.vtable.info_reader(&stream);

    try testing.expectEqual(@as(u32, 44100), info.sample_rate);
    try testing.expectEqual(@as(u8, 2), info.channels);
    try testing.expectEqual(SampleType.i16, info.sample_type);
    try testing.expectEqual(@as(usize, 155127), info.total_frames);
}

test "QOA decode" {
    var audio = try qoa.vtable.decode_from_bytes(testing.allocator, test_qoa_data);
    defer audio.deinit();

    try testing.expectEqual(@as(u32, 44100), audio.params.sample_rate);
    try testing.expectEqual(@as(u8, 2), audio.params.channels);
    try testing.expectEqual(SampleType.i16, audio.params.sample_type);

    // Calculate expected bytes based on data length and verify it's reasonable
    const expected_bytes_per_frame = audio.params.channels * @sizeOf(i16);
    const frame_count = audio.data.len / expected_bytes_per_frame;
    try testing.expect(frame_count > 0);
}

test "QOA streaming API" {
    var stream = try api.fromMemory(testing.allocator, test_qoa_data);
    defer stream.deinit();

    try testing.expectEqual(@as(u32, 44100), stream.info.sample_rate);
    try testing.expectEqual(@as(u8, 2), stream.info.channels);
    try testing.expectEqual(SampleType.i16, stream.info.sample_type);
    try testing.expectEqual(@as(usize, 155127), stream.info.total_frames);

    const reader = stream.readerInterface();
    var buffer: [1024]u8 = undefined;
    var tmp: [1][]u8 = .{&buffer};
    const bytes_read = try reader.readVec(&tmp);
    try testing.expect(bytes_read > 0);
}

test "QOA error handling" {
    const invalid_data = "not a qoa file";
    try testing.expectError(error.InvalidFormat, qoa.vtable.decode_from_bytes(testing.allocator, invalid_data));
    try testing.expectError(error.Unsupported, api.fromMemory(testing.allocator, invalid_data));
}
