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
    try testing.expectEqual(SampleType.f32, info.sample_type);
    try testing.expect(info.total_frames > 0);
}

test "WAV decode" {
    var audio = try api.decodeMemory(testing.allocator, test_wav_data);
    defer audio.deinit(testing.allocator);

    try testing.expectEqual(@as(u32, 44100), audio.params.sample_rate);
    try testing.expectEqual(@as(u8, 2), audio.params.channels);
    try testing.expectEqual(SampleType.f32, audio.params.sample_type);

    const expected_bytes_per_frame = audio.params.channels * @sizeOf(f32);
    const frame_count = audio.data.len / expected_bytes_per_frame;
    try testing.expect(frame_count > 0);
}

test "WAV streaming API" {
    const decoder = try api.fromMemory(testing.allocator, test_wav_data);
    defer decoder.deinit(testing.allocator);

    try testing.expectEqual(@as(u32, 44100), decoder.info.sample_rate);
    try testing.expectEqual(@as(u8, 2), decoder.info.channels);
    try testing.expectEqual(SampleType.f32, decoder.info.sample_type);
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
    defer std.Io.Dir.cwd().deleteFile(std.testing.io, temp_path) catch {};

    try api.encodeToPath(.wav, std.testing.io, temp_path, &audio);

    // Verify the file was created and has valid WAV structure
    const file = try std.Io.Dir.cwd().openFile(std.testing.io, temp_path, .{});
    defer file.close(std.testing.io);

    var header: [44]u8 = undefined;
    const bytes_read = try file.readPositionalAll(std.testing.io, &header, 0);
    try testing.expect(bytes_read >= 44);
    try testing.expectEqualSlices(u8, "RIFF", header[0..4]);
    try testing.expectEqualSlices(u8, "WAVE", header[8..12]);
}

// Small non-silent fixtures exercise byte offsets for each supported sample width.
fn seekFixture(tag: u16, bits: u16, channels: u16, extensible: bool) ![]u8 {
    const fmt_size: usize = if (extensible) 40 else if (tag == 2 or tag == 0x11) 22 else 16;
    const data_offset = 28 + fmt_size;
    const sample_bytes = bits / 8;
    const data_size = 16 * @as(usize, sample_bytes);
    const data = try testing.allocator.alloc(u8, data_offset + data_size);
    @memset(data, 0);
    @memcpy(data[0..4], "RIFF");
    std.mem.writeInt(u32, data[4..8], @intCast(data.len - 8), .little);
    @memcpy(data[8..16], "WAVEfmt ");
    std.mem.writeInt(u32, data[16..20], @intCast(fmt_size), .little);
    std.mem.writeInt(u16, data[20..22], if (extensible) 0xfffe else tag, .little);
    std.mem.writeInt(u16, data[22..24], channels, .little);
    std.mem.writeInt(u32, data[24..28], 48000, .little);
    std.mem.writeInt(u32, data[28..32], @as(u32, 48000) * channels * sample_bytes, .little);
    std.mem.writeInt(u16, data[32..34], channels * sample_bytes, .little);
    std.mem.writeInt(u16, data[34..36], bits, .little);
    if (extensible) {
        std.mem.writeInt(u16, data[36..38], 22, .little);
        std.mem.writeInt(u16, data[38..40], bits, .little);
        @memcpy(data[44..60], &[_]u8{ 0, 0, 0, 0, 0, 0, 0x10, 0, 0x80, 0, 0, 0xaa, 0, 0x38, 0x9b, 0x71 });
        std.mem.writeInt(u16, data[44..46], tag, .little);
    } else if (tag == 2 or tag == 0x11) {
        std.mem.writeInt(u16, data[36..38], 4, .little);
        std.mem.writeInt(u16, data[38..40], 9, .little);
    }
    @memcpy(data[data_offset - 8 ..][0..4], "data");
    std.mem.writeInt(u32, data[data_offset - 4 ..][0..4], @intCast(data_size), .little);
    for (0..16) |i| {
        const dst = data[data_offset + i * sample_bytes ..][0..sample_bytes];
        if (tag == 3) {
            const value: f32 = @as(f32, @floatFromInt(i)) / 16 - 0.5;
            if (bits == 32) {
                std.mem.writeInt(u32, dst[0..4], @bitCast(value), .little);
            } else {
                std.mem.writeInt(u64, dst[0..8], @bitCast(@as(f64, value)), .little);
            }
        } else {
            for (dst, 0..) |*byte, j| byte.* = @intCast(i * 7 + j * 11);
        }
    }
    return data;
}

fn checkWavSeeks(decoder: *api.Decoder, expected: *const api.Audio) !void {
    const frames = expected.frameCount();
    const channels: usize = expected.params.channels;
    var output: [3]f32 = undefined;
    // First seek skips data that this decoder has never read.
    for ([_]usize{ frames - 1, 0, frames / 2, 1 }) |frame| {
        try decoder.seekTo(frame);
        const offset = frame * channels;
        const n = try decoder.read(&output);
        try testing.expectEqual(@min(output.len, expected.samples().len - offset), n);
        try testing.expectEqualSlices(f32, expected.samples()[offset..][0..n], output[0..n]);
    }
    try decoder.seekTo(frames);
    try testing.expectEqual(@as(usize, 0), try decoder.read(&output));
    try decoder.seekTo(1);
    try testing.expectError(error.InvalidSeekPosition, decoder.seekTo(frames + 1));
    try testing.expectError(error.InvalidSeekPosition, decoder.seekTo(std.math.maxInt(usize)));
    const n = try decoder.read(&output);
    try testing.expectEqualSlices(f32, expected.samples()[channels..][0..n], output[0..n]);
}

test "WAV memory seeking supports PCM and float widths including extensible" {
    for ([_]u16{ 1, 3 }) |tag| {
        for ([_]u16{ 8, 16, 24, 32, 64 }) |bits| {
            if ((tag == 1 and bits == 64) or (tag == 3 and bits < 32)) continue;
            for ([_]u16{ 1, 2 }) |channels| {
                for ([_]bool{ false, true }) |extensible| {
                    const data = try seekFixture(tag, bits, channels, extensible);
                    defer testing.allocator.free(data);
                    var expected = try api.decodeMemory(testing.allocator, data);
                    defer expected.deinit(testing.allocator);
                    const decoder = try api.fromMemory(testing.allocator, data);
                    defer decoder.deinit(testing.allocator);
                    try checkWavSeeks(decoder, &expected);
                }
            }
        }
    }
}

test "WAV file seeking resets buffered input across distant positions" {
    var temp = testing.tmpDir(.{});
    defer temp.cleanup();
    try temp.dir.writeFile(testing.io, .{ .sub_path = "seek.wav", .data = test_wav_data });
    const path = try temp.dir.realPathFileAlloc(testing.io, "seek.wav", testing.allocator);
    defer testing.allocator.free(path);
    var expected = try api.decodeMemory(testing.allocator, test_wav_data);
    defer expected.deinit(testing.allocator);
    const decoder = try api.fromPath(testing.allocator, testing.io, path);
    defer decoder.deinit(testing.allocator);
    try checkWavSeeks(decoder, &expected);
}

test "compressed WAV seeking remains unsupported" {
    for ([_]u16{ 2, 6, 7, 0x11 }) |tag| {
        const data = try seekFixture(tag, 8, 1, false);
        defer testing.allocator.free(data);
        const decoder = try api.fromMemory(testing.allocator, data);
        defer decoder.deinit(testing.allocator);
        try testing.expectError(error.Unseekable, decoder.seekTo(0));
    }
}

test "WAV seek rejects invalid frame layout without moving the cursor" {
    const data = try seekFixture(1, 16, 2, false);
    defer testing.allocator.free(data);
    var expected = try api.decodeMemory(testing.allocator, data);
    defer expected.deinit(testing.allocator);
    // The linear decoder reads packed samples; a contradictory frame stride
    // must not be used to calculate seek positions.
    std.mem.writeInt(u16, data[32..34], 6, .little);
    const decoder = try api.fromMemory(testing.allocator, data);
    defer decoder.deinit(testing.allocator);
    try testing.expectError(error.InvalidFormat, decoder.seekTo(1));
    var output: [3]f32 = undefined;
    try testing.expectEqual(output.len, try decoder.read(&output));
    try testing.expectEqualSlices(f32, expected.samples()[0..3], &output);
}
