const std = @import("std");
const testing = std.testing;
const api = @import("root.zig");
const qoa = @import("qoa.zig");
const BitReader = @import("BitReader.zig");
const SampleType = api.SampleType;

// Embedded test QOA file
const test_qoa_data = @embedFile("test-files/fanfare_heartcontainer.qoa");

test "QOA probe" {
    var br = BitReader.initFromMemory(testing.allocator, test_qoa_data);
    defer br.deinit();
    try testing.expect(try qoa.vtable.probe(&br));

    var invalid_br = BitReader.initFromMemory(testing.allocator, "not a qoa file");
    defer invalid_br.deinit();
    try testing.expect(!try qoa.vtable.probe(&invalid_br));
}

test "QOA info" {
    var br = BitReader.initFromMemory(testing.allocator, test_qoa_data);
    defer br.deinit();
    const info = try qoa.vtable.info(&br);

    try testing.expectEqual(@as(u32, 44100), info.sample_rate);
    try testing.expectEqual(@as(u8, 2), info.channels);
    try testing.expectEqual(SampleType.i16, info.sample_type);
    try testing.expectEqual(@as(usize, 155127), info.total_frames);
}

test "QOA decode" {
    var audio = try api.decodeMemory(testing.allocator, test_qoa_data);
    defer audio.deinit(testing.allocator);

    try testing.expectEqual(@as(u32, 44100), audio.params.sample_rate);
    try testing.expectEqual(@as(u8, 2), audio.params.channels);
    try testing.expectEqual(SampleType.i16, audio.params.sample_type);

    // Calculate expected bytes based on data length and verify it's reasonable
    const expected_bytes_per_frame = audio.params.channels * @sizeOf(i16);
    const frame_count = audio.data.len / expected_bytes_per_frame;
    try testing.expect(frame_count > 0);
}

test "QOA streaming API" {
    const decoder = try api.fromMemory(testing.allocator, test_qoa_data);
    defer decoder.deinit(testing.allocator);

    try testing.expectEqual(@as(u32, 44100), decoder.info.sample_rate);
    try testing.expectEqual(@as(u8, 2), decoder.info.channels);
    try testing.expectEqual(SampleType.i16, decoder.info.sample_type);
    try testing.expectEqual(@as(usize, 155127), decoder.info.total_frames);

    var adapter = api.DecoderReader.init(decoder);
    const reader = adapter.reader();
    var buffer: [1024]u8 = undefined;
    var tmp: [1][]u8 = .{buffer[0..]};
    const bytes_read = try reader.readVec(&tmp);
    try testing.expect(bytes_read > 0);
}

test "QOA error handling" {
    var invalid_br = BitReader.initFromMemory(testing.allocator, "not a qoa file");
    defer invalid_br.deinit();
    try testing.expectError(error.InvalidFormat, qoa.vtable.info(&invalid_br));

    try testing.expectError(error.Unsupported, api.fromMemory(testing.allocator, "not a qoa file"));
}

fn decodeAll(allocator: std.mem.Allocator, data: []const u8) ![]i16 {
    var audio = try api.decodeMemory(allocator, data);
    defer audio.deinit(testing.allocator);

    const samples = std.mem.bytesAsSlice(i16, audio.data);
    const copy = try allocator.alloc(i16, samples.len);
    @memcpy(copy, samples);
    return copy;
}

test "QOA encode from WAV decodes equal to golden" {
    const wav_bytes = @embedFile("test-files/fanfare_heartcontainer.wav");
    const golden_qoa = @embedFile("test-files/fanfare_heartcontainer.qoa");

    var audio = try api.decodeMemory(testing.allocator, wav_bytes);
    defer audio.deinit(testing.allocator);

    const out_path = "test_out.qoa";
    defer std.fs.cwd().deleteFile(out_path) catch {};
    const file = try std.fs.cwd().createFile(out_path, .{});
    defer file.close();
    try qoa.encodeToFile(file, &audio);

    const actual_bytes = try std.fs.cwd().readFileAlloc(testing.allocator, out_path, std.math.maxInt(usize));
    defer testing.allocator.free(actual_bytes);

    const dec_golden = try decodeAll(testing.allocator, golden_qoa);
    defer testing.allocator.free(dec_golden);
    const dec_actual = try decodeAll(testing.allocator, actual_bytes);
    defer testing.allocator.free(dec_actual);

    try testing.expectEqual(dec_golden.len, dec_actual.len);
    var i: usize = 0;
    while (i < dec_golden.len) : (i += 1) {
        const da = dec_golden[i];
        const db = dec_actual[i];
        try testing.expect(@abs(da - db) <= 1024);
    }
}

test "QOA encode from WAV matches golden bytes" {
    const wav_bytes = @embedFile("test-files/fanfare_heartcontainer.wav");
    const golden_qoa = @embedFile("test-files/fanfare_heartcontainer.qoa");

    var audio = try api.decodeMemory(testing.allocator, wav_bytes);
    defer audio.deinit(testing.allocator);

    const out_path = "test_out_exact.qoa";
    defer std.fs.cwd().deleteFile(out_path) catch {};
    const file = try std.fs.cwd().createFile(out_path, .{});
    defer file.close();
    try qoa.encodeToFile(file, &audio);

    const actual_bytes = try std.fs.cwd().readFileAlloc(testing.allocator, out_path, std.math.maxInt(usize));
    defer testing.allocator.free(actual_bytes);

    try testing.expectEqualSlices(u8, golden_qoa, actual_bytes);
}
