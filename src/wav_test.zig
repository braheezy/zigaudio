const std = @import("std");
const testing = std.testing;
const api = @import("root.zig");
const wav = @import("wav.zig");
const BitReader = @import("BitReader.zig");
const SampleType = api.SampleType;

// Embedded test WAV file
const test_wav_data = @embedFile("test-files/fanfare_heartcontainer.wav");

test "WAV probe" {
    var br = BitReader.initFromMemory(testing.allocator, test_wav_data);
    defer br.deinit();
    try testing.expect(try wav.vtable.probe(&br));

    var invalid_br = BitReader.initFromMemory(testing.allocator, "not a wav file");
    defer invalid_br.deinit();
    try testing.expect(!try wav.vtable.probe(&invalid_br));
}

test "WAV info" {
    var br = BitReader.initFromMemory(testing.allocator, test_wav_data);
    defer br.deinit();
    const info = try wav.vtable.info(&br);

    try testing.expectEqual(@as(u32, 44100), info.sample_rate);
    try testing.expectEqual(@as(u8, 2), info.channels);
    try testing.expectEqual(SampleType.i16, info.sample_type);
    try testing.expect(info.total_frames > 0);
}

test "WAV decode" {
    var audio = try api.decodeMemory(testing.allocator, test_wav_data);
    defer audio.deinit(testing.allocator);

    try testing.expectEqual(@as(u32, 44100), audio.params.sample_rate);
    try testing.expectEqual(@as(u8, 2), audio.params.channels);
    try testing.expectEqual(SampleType.i16, audio.params.sample_type);

    const expected_bytes_per_frame = audio.params.channels * @sizeOf(i16);
    const frame_count = audio.data.len / expected_bytes_per_frame;
    try testing.expect(frame_count > 0);
}

test "WAV streaming API" {
    const decoder = try api.fromMemory(testing.allocator, test_wav_data);
    defer decoder.deinit(testing.allocator);

    try testing.expectEqual(@as(u32, 44100), decoder.info.sample_rate);
    try testing.expectEqual(@as(u8, 2), decoder.info.channels);
    try testing.expectEqual(SampleType.i16, decoder.info.sample_type);
    try testing.expect(decoder.info.total_frames > 0);

    var adapter = api.DecoderReader.init(decoder);
    const reader = adapter.reader();
    var buffer: [1024]u8 = undefined;
    var tmp: [1][]u8 = .{buffer[0..]};
    const bytes_read = try reader.readVec(&tmp);
    try testing.expect(bytes_read > 0);
}

test "WAV error handling" {
    const invalid_data = "not a wav file";
    var invalid_br = BitReader.initFromMemory(testing.allocator, invalid_data);
    defer invalid_br.deinit();
    try testing.expectError(error.InvalidFormat, wav.vtable.info(&invalid_br));
}

test "WAV encode to file" {
    var audio = try api.decodeMemory(testing.allocator, test_wav_data);
    defer audio.deinit(testing.allocator);

    const temp_path = "test_output.wav";
    defer std.fs.cwd().deleteFile(temp_path) catch {};

    try api.encodeToPath(.wav, temp_path, &audio);

    // Verify the file was created and has valid WAV structure
    const file = try std.fs.cwd().openFile(temp_path, .{});
    defer file.close();

    var header: [44]u8 = undefined;
    const bytes_read = try file.readAll(&header);
    try testing.expect(bytes_read >= 44);
    try testing.expectEqualSlices(u8, "RIFF", header[0..4]);
    try testing.expectEqualSlices(u8, "WAVE", header[8..12]);
}
