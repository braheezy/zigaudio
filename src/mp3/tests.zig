const std = @import("std");
const testing = std.testing;
const mp3 = @import("../mp3.zig");
const api = @import("../root.zig");
const BitReader = @import("../BitReader.zig");
const SampleType = api.SampleType;

const test_mp3_data = @embedFile("../test-files/fanfare_heartcontainer.mp3");

fn makeReader() BitReader {
    return BitReader.initFromMemory(testing.allocator, test_mp3_data);
}

fn makeInvalidReader() BitReader {
    return BitReader.initFromMemory(testing.allocator, "not an mp3");
}

fn destroyBitReader(br_ptr: *BitReader) void {
    br_ptr.deinit();
    testing.allocator.destroy(br_ptr);
}

fn makeReaderPtr() !*BitReader {
    var br_ptr = try testing.allocator.create(BitReader);
    errdefer testing.allocator.destroy(br_ptr);
    br_ptr.* = BitReader.initFromMemory(testing.allocator, test_mp3_data);
    errdefer br_ptr.deinit();
    return br_ptr;
}

test {
    testing.refAllDecls(@This());
    _ = @import("frameheader.zig");
    _ = @import("bits.zig");
    _ = @import("imdct.zig");
    _ = @import("sideinfo.zig");
    _ = @import("maindata.zig");
}

test "MP3 probe" {
    var br = makeReader();
    defer br.deinit();
    try testing.expect(try mp3.vtable.probe(&br));

    var invalid = makeInvalidReader();
    defer invalid.deinit();
    try testing.expect(!try mp3.vtable.probe(&invalid));
}

test "MP3 info" {
    var br = makeReader();
    defer br.deinit();
    const info = try mp3.vtable.info(&br);

    try testing.expectEqual(@as(u32, 44100), info.sample_rate);
    try testing.expectEqual(@as(u8, 2), info.channels);
    try testing.expectEqual(SampleType.i16, info.sample_type);
    try testing.expect(info.total_frames > 0);
}

test "MP3 open + streaming" {
    const allocator = testing.allocator;
    const br_ptr = try makeReaderPtr();
    const decoder = mp3.vtable.open(allocator, br_ptr) catch |err| {
        destroyBitReader(br_ptr);
        return err;
    };
    defer decoder.deinit();

    try testing.expectEqual(@as(u32, 44100), decoder.info.sample_rate);
    try testing.expectEqual(@as(u8, 2), decoder.info.channels);
    try testing.expectEqual(SampleType.i16, decoder.info.sample_type);
    try testing.expect(decoder.info.total_frames > 0);

    var buf: [2048]i16 = undefined;
    const read = try decoder.read(&buf);
    try testing.expect(read > 0);
}

test "MP3 decodeMemory" {
    var audio = try api.decodeMemory(testing.allocator, test_mp3_data);
    defer audio.deinit();

    try testing.expectEqual(@as(u32, 44100), audio.params.sample_rate);
    try testing.expectEqual(@as(u8, 2), audio.params.channels);
    try testing.expectEqual(SampleType.i16, audio.params.sample_type);
    try testing.expect(audio.data.len > 0);

    const frame_size = audio.params.channels * @sizeOf(i16);
    try testing.expect(audio.data.len % frame_size == 0);
}

test "MP3 info invalid" {
    var br = makeInvalidReader();
    defer br.deinit();
    try testing.expectError(error.InvalidFormat, mp3.vtable.info(&br));
}

test "MP3 open invalid" {
    const allocator = testing.allocator;
    const br_ptr = try allocator.create(BitReader);
    br_ptr.* = BitReader.initFromMemory(testing.allocator, "not an mp3");
    defer destroyBitReader(br_ptr);
    const open_err = mp3.vtable.open(allocator, br_ptr);
    try testing.expectError(error.InvalidFormat, open_err);
}
