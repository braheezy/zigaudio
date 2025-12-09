const std = @import("std");
const testing = std.testing;
const api = @import("root.zig");
const vorbis = @import("vorbis.zig");
const BitReader = @import("BitReader.zig");

const test_vorbis_data = @embedFile("test-files/fanfare_heartcontainer.ogg");

test "Vorbis probe" {
    var br = BitReader.initFromMemory(testing.allocator, test_vorbis_data);
    defer br.deinit();
    try testing.expect(try vorbis.vtable.probe(&br));

    var invalid = BitReader.initFromMemory(testing.allocator, "not a vorbis file");
    defer invalid.deinit();
    try testing.expect(!try vorbis.vtable.probe(&invalid));
}

test "Vorbis info" {
    var br = BitReader.initFromMemory(testing.allocator, test_vorbis_data);
    defer br.deinit();

    const info = try vorbis.vtable.info(&br);
    try testing.expectEqual(@as(u32, 44100), info.sample_rate);
    try testing.expectEqual(@as(u8, 2), info.channels);
    try testing.expectEqual(api.SampleType.f32, info.sample_type);
    try testing.expect(info.total_frames > 0);
}

test "Vorbis decode" {
    var audio = try api.decodeMemory(testing.allocator, test_vorbis_data);
    defer audio.deinit(testing.allocator);

    try testing.expectEqual(@as(u32, 44100), audio.params.sample_rate);
    try testing.expectEqual(@as(u8, 2), audio.params.channels);
    try testing.expectEqual(api.SampleType.f32, audio.params.sample_type);
    try testing.expect(audio.data.len > 0);

    const samples = audio.frameCount();
    const expected_frames = 44100 * 3;
    try testing.expect(samples > expected_frames * 9 / 10);
    try testing.expect(samples < expected_frames * 13 / 10);
}

test "Vorbis streaming API" {
    const decoder = try api.fromMemory(testing.allocator, test_vorbis_data);
    defer decoder.deinit(testing.allocator);

    try testing.expectEqual(@as(u32, 44100), decoder.info.sample_rate);
    try testing.expectEqual(@as(u8, 2), decoder.info.channels);
    try testing.expectEqual(api.SampleType.f32, decoder.info.sample_type);

    var adapter = api.DecoderReader.init(decoder);
    const reader = adapter.reader();
    var buffer: [2048]u8 = undefined;
    var tmp: [1][]u8 = .{buffer[0..]};
    const bytes_read = try reader.readVec(&tmp);
    try testing.expect(bytes_read > 0);
}

test "Vorbis error handling" {
    const invalid_data = "not a vorbis file";
    var br = BitReader.initFromMemory(testing.allocator, invalid_data);
    defer br.deinit();
    try testing.expectError(error.InvalidFormat, vorbis.vtable.info(&br));
    try testing.expectError(error.Unsupported, api.decodeMemory(testing.allocator, invalid_data));
}

test "Vorbis decoded audio has signal" {
    var audio = try api.decodeMemory(testing.allocator, test_vorbis_data);
    defer audio.deinit(testing.allocator);

    const samples = std.mem.bytesAsSlice(f32, audio.data);
    var non_zero: usize = 0;
    var max_sample: f32 = 0;
    for (samples) |sample| {
        if (sample != 0) non_zero += 1;
        const abs_sample = @abs(sample);
        if (abs_sample > max_sample) max_sample = abs_sample;
    }

    try testing.expect(non_zero > samples.len / 10);
    try testing.expect(max_sample > 0);
    try testing.expect(max_sample <= 1.0);
}
