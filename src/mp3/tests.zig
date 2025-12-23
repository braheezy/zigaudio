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
    try testing.expectEqual(SampleType.f32, info.sample_type);
    try testing.expect(info.total_frames > 0);
}

test "MP3 open + streaming" {
    const allocator = testing.allocator;
    const br_ptr = try makeReaderPtr();
    const decoder = mp3.vtable.open(allocator, br_ptr) catch |err| {
        destroyBitReader(br_ptr);
        return err;
    };
    defer decoder.deinit(allocator);

    try testing.expectEqual(@as(u32, 44100), decoder.info.sample_rate);
    try testing.expectEqual(@as(u8, 2), decoder.info.channels);
    try testing.expectEqual(SampleType.f32, decoder.info.sample_type);
    try testing.expect(decoder.info.total_frames > 0);

    var buf: [2048]f32 = undefined;
    const read = try decoder.read(&buf);
    try testing.expect(read > 0);
}

test "MP3 decodeMemory" {
    var audio = try api.decodeMemory(testing.allocator, test_mp3_data);
    defer audio.deinit(testing.allocator);

    try testing.expectEqual(@as(u32, 44100), audio.params.sample_rate);
    try testing.expectEqual(@as(u8, 2), audio.params.channels);
    try testing.expectEqual(SampleType.f32, audio.params.sample_type);
    try testing.expect(audio.data.len > 0);

    const frame_size = audio.params.channels * @sizeOf(f32);
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

// Encoder tests

const test_wav_data = @embedFile("../test-files/fanfare_heartcontainer.wav");

test "MP3 encode from WAV" {
    const allocator = testing.allocator;

    // Decode the WAV file
    var audio = try api.decodeMemory(allocator, test_wav_data);
    defer audio.deinit(allocator);

    try testing.expectEqual(@as(u32, 44100), audio.params.sample_rate);
    try testing.expectEqual(@as(u8, 2), audio.params.channels);

    // Encode to MP3 file
    const temp_path = "test_output.mp3";
    defer std.fs.cwd().deleteFile(temp_path) catch {};

    try api.encodeToPath(.mp3, temp_path, &audio);

    // Read back the MP3 file
    const file = try std.fs.cwd().openFile(temp_path, .{});
    defer file.close();
    const stat = try file.stat();
    const encoded_data = try allocator.alloc(u8, stat.size);
    defer allocator.free(encoded_data);
    _ = try file.readAll(encoded_data);

    // Verify the MP3 file is valid (starts with frame sync)
    try testing.expect(encoded_data.len > 0);
    try testing.expectEqual(@as(u8, 0xFF), encoded_data[0]);
    try testing.expectEqual(@as(u8, 0xFA), encoded_data[1] & 0xFE); // MPEG-1 Layer 3 (masked protection bit)

    // Verify SHA256 checksum for bit-exact output
    const Sha256 = std.crypto.hash.sha2.Sha256;
    var hasher = Sha256.init(.{});
    hasher.update(encoded_data);
    const hash = hasher.finalResult();

    const expected_hash = [_]u8{
        0xe4, 0x0f, 0x29, 0x71, 0x4c, 0xa7, 0x86, 0x58,
        0x28, 0x9c, 0xbb, 0xe8, 0x37, 0xdf, 0xe3, 0x26,
        0x12, 0x83, 0xb4, 0x1e, 0x4d, 0x06, 0x42, 0x32,
        0x9f, 0x75, 0x7f, 0xdf, 0xc1, 0x69, 0x55, 0xcc,
    };

    try testing.expectEqualSlices(u8, &expected_hash, &hash);
}
