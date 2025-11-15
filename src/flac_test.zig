const std = @import("std");
const testing = std.testing;
const api = @import("root.zig");
const flac = @import("flac.zig");
const BitReader = @import("BitReader.zig");

const test_flac_data = @embedFile("test-files/fanfare_heartcontainer.flac");

test "FLAC probe" {
    var br = BitReader.initFromMemory(testing.allocator, test_flac_data);
    defer br.deinit();
    try testing.expect(try flac.vtable.probe(&br));

    var invalid = BitReader.initFromMemory(testing.allocator, "not a flac");
    defer invalid.deinit();
    try testing.expect(!try flac.vtable.probe(&invalid));
}

test "FLAC info" {
    var br = BitReader.initFromMemory(testing.allocator, test_flac_data);
    defer br.deinit();

    const info = try flac.vtable.info(&br);
    try testing.expectEqual(@as(u32, 44100), info.sample_rate);
    try testing.expectEqual(@as(u8, 2), info.channels);
    try testing.expectEqual(api.SampleType.i16, info.sample_type);
    try testing.expect(info.total_frames > 0);
}

test "FLAC decode full buffer" {
    var audio = try api.decodeMemory(testing.allocator, test_flac_data);
    defer audio.deinit(testing.allocator);

    try testing.expectEqual(@as(u32, 44100), audio.params.sample_rate);
    try testing.expectEqual(@as(u8, 2), audio.params.channels);
    try testing.expectEqual(api.SampleType.i16, audio.params.sample_type);
    try testing.expect(audio.data.len > 0);
}

test "FLAC decode matches WAV reference" {
    var flac_audio = try api.decodeMemory(testing.allocator, test_flac_data);
    defer flac_audio.deinit(testing.allocator);

    const wav_data = @embedFile("test-files/fanfare_heartcontainer.wav");
    var wav_audio = try api.decodeMemory(testing.allocator, wav_data);
    defer wav_audio.deinit(testing.allocator);

    try testing.expectEqual(wav_audio.data.len, flac_audio.data.len);
    try testing.expectEqualSlices(u8, wav_audio.data, flac_audio.data);
}

test "FLAC streaming reader" {
    const decoder = try api.fromMemory(testing.allocator, test_flac_data);
    defer decoder.deinit(testing.allocator);

    try testing.expectEqual(@as(u32, 44100), decoder.info.sample_rate);
    try testing.expectEqual(@as(u8, 2), decoder.info.channels);
    try testing.expectEqual(api.SampleType.i16, decoder.info.sample_type);

    var adapter = api.DecoderReader.init(decoder);
    const reader = adapter.reader();
    var buffer: [2048]u8 = undefined;
    var tmp: [1][]u8 = .{buffer[0..]};
    const bytes_read = try reader.readVec(&tmp);
    try testing.expect(bytes_read > 0);
}

test "FLAC invalid info" {
    var br = BitReader.initFromMemory(testing.allocator, "flac?");
    defer br.deinit();
    try testing.expectError(error.InvalidFormat, flac.vtable.info(&br));
}
