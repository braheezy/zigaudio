const std = @import("std");
const testing = std.testing;
const api = @import("root.zig");
const aac = @import("aac.zig");
const BitReader = @import("BitReader.zig");
const SampleType = api.SampleType;

const test_aac_data = @embedFile("test-files/fanfare_heartcontainer.aac");

fn initBitReader() !BitReader {
    return BitReader.initFromMemory(testing.allocator, test_aac_data);
}

test "AAC probe" {
    var br = try initBitReader();
    defer br.deinit();
    try testing.expect(try aac.vtable.probe(&br));

    var invalid = BitReader.initFromMemory(testing.allocator, "not aac");
    defer invalid.deinit();
    try testing.expect(!try aac.vtable.probe(&invalid));
}

test "AAC info" {
    var br = try initBitReader();
    defer br.deinit();
    const info = try aac.vtable.info(&br);
    try testing.expectEqual(@as(u32, 44100), info.sample_rate);
    try testing.expectEqual(@as(u8, 2), info.channels);
    try testing.expectEqual(SampleType.i16, info.sample_type);
}

test "AAC decode" {
    var audio = try api.decodeMemory(testing.allocator, test_aac_data);
    defer audio.deinit();

    try testing.expectEqual(@as(u32, 44100), audio.params.sample_rate);
    try testing.expectEqual(@as(u8, 2), audio.params.channels);
    try testing.expectEqual(SampleType.i16, audio.params.sample_type);
    try testing.expect(audio.data.len > 0);
}

test "AAC streaming API" {
    const decoder = try api.openMemory(testing.allocator, test_aac_data);
    defer decoder.deinit();

    try testing.expectEqual(@as(u32, 44100), decoder.info.sample_rate);
    try testing.expectEqual(@as(u8, 2), decoder.info.channels);
    try testing.expectEqual(SampleType.i16, decoder.info.sample_type);

    var adapter = api.DecoderReader.init(decoder);
    const reader = adapter.reader();
    var buffer: [4096]u8 = undefined;
    var tmp: [1][]u8 = .{buffer[0..]};
    const bytes_read = try reader.readVec(&tmp);
    try testing.expect(bytes_read > 0);
}
