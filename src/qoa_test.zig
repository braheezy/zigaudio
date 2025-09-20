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

test "QOA encode from WAV decodes equal to golden" {
    const wav_bytes = @embedFile("test-files/fanfare_heartcontainer.wav");
    const golden_qoa = @embedFile("test-files/fanfare_heartcontainer.qoa");

    var reader = std.Io.Reader.fixed(wav_bytes);
    var audio = try api.decode(testing.allocator, &reader);
    defer audio.deinit();

    const out_path = "test_out.qoa";
    defer std.fs.cwd().deleteFile(out_path) catch {};
    try api.encodeToPath(.qoa, out_path, &audio, .{});

    const actual_bytes = try std.fs.cwd().readFileAlloc(testing.allocator, out_path, std.math.maxInt(usize));
    defer testing.allocator.free(actual_bytes);

    // Decode both our encoded QOA and the golden QOA and compare PCM
    const dec_golden = try qoa.decode(testing.allocator, golden_qoa);
    defer testing.allocator.free(dec_golden.samples);
    const dec_actual = try qoa.decode(testing.allocator, actual_bytes);
    defer testing.allocator.free(dec_actual.samples);

    try testing.expectEqual(dec_golden.decoder.channels, dec_actual.decoder.channels);
    try testing.expectEqual(dec_golden.decoder.sample_rate, dec_actual.decoder.sample_rate);
    try testing.expectEqual(dec_golden.decoder.sample_count, dec_actual.decoder.sample_count);

    const a = dec_golden.samples;
    const b = dec_actual.samples;
    var max_abs_diff: i32 = 0;
    var i: usize = 0;
    while (i < a.len and i < b.len) : (i += 1) {
        const da: i32 = a[i];
        const db: i32 = b[i];
        const d: i32 = if (da > db) da - db else db - da;
        if (d > max_abs_diff) max_abs_diff = d;
    }
    // Allow small per-sample deviation due to encoder heuristics
    try testing.expect(max_abs_diff <= 1024);
}

test "QOA encode from WAV matches golden bytes" {
    const wav_bytes = @embedFile("test-files/fanfare_heartcontainer.wav");
    const golden_qoa = @embedFile("test-files/fanfare_heartcontainer.qoa");

    var reader = std.Io.Reader.fixed(wav_bytes);
    var audio = try api.decode(testing.allocator, &reader);
    defer audio.deinit();

    const out_path = "test_out_exact.qoa";
    defer std.fs.cwd().deleteFile(out_path) catch {};
    try api.encodeToPath(.qoa, out_path, &audio, .{});

    const actual_bytes = try std.fs.cwd().readFileAlloc(testing.allocator, out_path, std.math.maxInt(usize));
    defer testing.allocator.free(actual_bytes);

    try testing.expectEqualSlices(u8, golden_qoa, actual_bytes);
}
