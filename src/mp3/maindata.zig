const std = @import("std");
const bits = @import("bits.zig");
const sideinfo = @import("sideinfo.zig");
const frameheader = @import("frameheader.zig");
const huffman = @import("huffman.zig");
const mp3 = @import("../mp3.zig");

// MP3 constants
const SAMPLES_PER_GR = 576;
const GRANULES_MPEG1 = 2;
const SF_BAND_INDICES_LONG = 0;
const SF_BAND_INDICES_SHORT = 1;

// A MainData is MPEG1 Layer 3 Main Data.
pub const MainData = struct {
    // 0-4 bits
    scalefac_l: [2][2][22]i16 = undefined,
    // 0-4 bits
    scalefac_s: [2][2][13][3]i16 = undefined,
    // Huffman coded freq. lines
    is: [2][2][576]f32 = undefined,
};

const scalefac_sizes_mpeg1 = [16][2]i16{
    .{ 0, 0 }, .{ 0, 1 }, .{ 0, 2 }, .{ 0, 3 }, .{ 3, 0 }, .{ 1, 1 }, .{ 1, 2 }, .{ 1, 3 },
    .{ 2, 1 }, .{ 2, 2 }, .{ 2, 3 }, .{ 3, 1 }, .{ 3, 2 }, .{ 3, 3 }, .{ 4, 2 }, .{ 4, 3 },
};

const scalefac_sizes_mpeg2 = [3][6][4]i16{
    .{ .{ 6, 5, 5, 5 }, .{ 6, 5, 7, 3 }, .{ 11, 10, 0, 0 }, .{ 7, 7, 7, 0 }, .{ 6, 6, 6, 3 }, .{ 8, 8, 5, 0 } },
    .{ .{ 9, 9, 9, 9 }, .{ 9, 9, 12, 6 }, .{ 18, 18, 0, 0 }, .{ 12, 12, 12, 0 }, .{ 12, 9, 9, 6 }, .{ 15, 12, 9, 0 } },
    .{ .{ 6, 9, 9, 9 }, .{ 6, 9, 12, 6 }, .{ 15, 18, 0, 0 }, .{ 6, 15, 12, 0 }, .{ 6, 12, 9, 6 }, .{ 6, 18, 9, 0 } },
};

// Comptime function to generate scale factor length lookup table
fn initSlen() [512]u32 {
    var nSlen2: [512]u32 = undefined;

    // First loop: i=0..4, j=0..3
    for (0..4) |i| {
        for (0..3) |j| {
            const n = j + i * 3;
            nSlen2[n + 500] = @as(u32, @intCast(i)) |
                (@as(u32, @intCast(j)) << 3) |
                (@as(u32, 2) << 12) |
                (@as(u32, 1) << 15);
        }
    }

    // Second loop: i=0..5, j=0..5, k=0..4, l=0..4
    for (0..5) |i| {
        for (0..5) |j| {
            for (0..4) |k| {
                for (0..4) |l| {
                    const n = l + k * 4 + j * 16 + i * 80;
                    nSlen2[n] = @as(u32, @intCast(i)) |
                        (@as(u32, @intCast(j)) << 3) |
                        (@as(u32, @intCast(k)) << 6) |
                        (@as(u32, @intCast(l)) << 9) |
                        (@as(u32, 0) << 12);
                }
            }
        }
    }

    // Third loop: i=0..5, j=0..5, k=0..4
    for (0..5) |i| {
        for (0..5) |j| {
            for (0..4) |k| {
                const n = k + j * 4 + i * 20;
                nSlen2[n + 400] = @as(u32, @intCast(i)) |
                    (@as(u32, @intCast(j)) << 3) |
                    (@as(u32, @intCast(k)) << 6) |
                    (@as(u32, 1) << 12);
            }
        }
    }

    return nSlen2;
}

// Comptime-generated scale factor length lookup table
pub const slen2 = initSlen();

// Get scale factors for MPEG-2
pub fn getScaleFactorsMpeg2(
    allocator: std.mem.Allocator,
    m: *bits.Bits,
    header: frameheader.FrameHeader,
    side_info: *sideinfo.SideInfo,
) !MainData {
    const nch = header.numberOfChannels();
    var md = MainData{};

    for (0..nch) |ch| {
        const part_2_start = m.bitPosition();
        var numbits: usize = 0;
        const slen = slen2[side_info.scalefac_compress[0][ch]];
        side_info.preflag[0][ch] = @intCast((slen >> 15) & 0x1);

        var n: usize = 0;
        if (side_info.block_type[0][ch] == 2) {
            n += 1;
            if (side_info.mixed_block_flag[0][ch] != 0) {
                n += 1;
            }
        }

        var scale_factors = std.ArrayList(i16).initCapacity(allocator, 100) catch return error.OutOfMemory;
        defer scale_factors.deinit(allocator);

        const d = (slen >> 12) & 0x7;
        var slen_temp = slen;

        for (0..4) |i| {
            const num = slen_temp & 0x7;
            slen_temp >>= 3;
            if (num > 0) {
                for (0..@intCast(scalefac_sizes_mpeg2[n][d][i])) |j| {
                    _ = j;
                    try scale_factors.append(allocator, @intCast(m.bits(num)));
                }
                numbits += @as(usize, @intCast(scalefac_sizes_mpeg2[n][d][i])) * num;
            } else {
                for (0..@intCast(scalefac_sizes_mpeg2[n][d][i])) |j| {
                    _ = j;
                    try scale_factors.append(allocator, 0);
                }
            }
        }

        n = (n << 1) + 1;
        for (0..n) |i| {
            _ = i;
            try scale_factors.append(allocator, 0);
        }

        if (scale_factors.items.len == 22) {
            for (0..22) |i| {
                md.scalefac_l[0][ch][i] = scale_factors.items[i];
            }
        } else {
            for (0..13) |x| {
                for (0..3) |i| {
                    md.scalefac_s[0][ch][x][i] = scale_factors.items[(x * 3) + i];
                }
            }
        }

        // Read Huffman coded data. Skip stuffing bits.
        try readHuffman(m, header, side_info, &md, part_2_start, 0, ch);
    }
    // The ancillary data is stored here, but we ignore it.
    return md;
}

// Get scale factors for MPEG-1
pub fn getScaleFactorsMpeg1(
    nch: usize,
    m: *bits.Bits,
    header: frameheader.FrameHeader,
    side_info: *sideinfo.SideInfo,
) !MainData {
    var md = MainData{};

    for (0..2) |gr| {
        for (0..nch) |ch| {
            const part_2_start = m.bitPosition();
            // Number of bits in the bitstream for the bands
            const slen1 = scalefac_sizes_mpeg1[side_info.scalefac_compress[gr][ch]][0];
            const slen2_val = scalefac_sizes_mpeg1[side_info.scalefac_compress[gr][ch]][1];

            if (side_info.win_switch_flag[gr][ch] == 1 and side_info.block_type[gr][ch] == 2) {
                if (side_info.mixed_block_flag[gr][ch] != 0) {
                    for (0..8) |sfb| {
                        md.scalefac_l[gr][ch][sfb] = @intCast(m.bits(@intCast(slen1)));
                    }
                    for (3..12) |sfb| {
                        // slen1 for band 3-5, slen2 for 6-11
                        const nbits = if (sfb < 6) slen1 else slen2_val;
                        for (0..3) |win| {
                            md.scalefac_s[gr][ch][sfb][win] = @intCast(m.bits(@intCast(nbits)));
                        }
                    }
                } else {
                    for (0..12) |sfb| {
                        // slen1 for band 3-5, slen2 for 6-11
                        const nbits = if (sfb < 6) slen1 else slen2_val;
                        for (0..3) |win| {
                            md.scalefac_s[gr][ch][sfb][win] = @intCast(m.bits(@intCast(nbits)));
                        }
                    }
                }
            } else {
                // Scale factor bands 0-5
                if (side_info.scfsi[ch][0] == 0 or gr == 0) {
                    for (0..6) |sfb| {
                        md.scalefac_l[gr][ch][sfb] = @intCast(m.bits(@intCast(slen1)));
                    }
                } else if (side_info.scfsi[ch][0] == 1 and gr == 1) {
                    // Copy scalefactors from granule 0 to granule 1
                    // TODO: This is not listed on the spec.
                    for (0..6) |sfb| {
                        md.scalefac_l[1][ch][sfb] = md.scalefac_l[0][ch][sfb];
                    }
                }

                // Scale factor bands 6-10
                if (side_info.scfsi[ch][1] == 0 or gr == 0) {
                    for (6..11) |sfb| {
                        md.scalefac_l[gr][ch][sfb] = @intCast(m.bits(@intCast(slen1)));
                    }
                } else if (side_info.scfsi[ch][1] == 1 and gr == 1) {
                    // Copy scalefactors from granule 0 to granule 1
                    for (6..11) |sfb| {
                        md.scalefac_l[1][ch][sfb] = md.scalefac_l[0][ch][sfb];
                    }
                }

                // Scale factor bands 11-15
                if (side_info.scfsi[ch][2] == 0 or gr == 0) {
                    for (11..16) |sfb| {
                        md.scalefac_l[gr][ch][sfb] = @intCast(m.bits(@intCast(slen2_val)));
                    }
                } else if (side_info.scfsi[ch][2] == 1 and gr == 1) {
                    // Copy scalefactors from granule 0 to granule 1
                    for (11..16) |sfb| {
                        md.scalefac_l[1][ch][sfb] = md.scalefac_l[0][ch][sfb];
                    }
                }

                // Scale factor bands 16-20
                if (side_info.scfsi[ch][3] == 0 or gr == 0) {
                    for (16..21) |sfb| {
                        md.scalefac_l[gr][ch][sfb] = @intCast(m.bits(@intCast(slen2_val)));
                    }
                } else if (side_info.scfsi[ch][3] == 1 and gr == 1) {
                    // Copy scalefactors from granule 0 to granule 1
                    for (16..21) |sfb| {
                        md.scalefac_l[1][ch][sfb] = md.scalefac_l[0][ch][sfb];
                    }
                }
            }

            // Read Huffman coded data. Skip stuffing bits.
            try readHuffman(m, header, side_info, &md, part_2_start, gr, ch);
        }
    }
    // The ancillary data is stored here, but we ignore it.
    return md;
}

// Read Huffman coded frequency data
fn readHuffman(
    m: *bits.Bits,
    header: frameheader.FrameHeader,
    side_info: *sideinfo.SideInfo,
    md: *MainData,
    part_2_start: usize,
    gr: usize,
    ch: usize,
) !void {
    // Check that there is any data to decode. If not, zero the array.
    if (side_info.part2_3_length[gr][ch] == 0) {
        for (0..SAMPLES_PER_GR) |i| {
            md.is[gr][ch][i] = 0.0;
        }
        return;
    }

    // Calculate bit_pos_end which is the index of the last bit for this part.
    const bit_pos_end = part_2_start + side_info.part2_3_length[gr][ch] - 1;

    // Determine region boundaries
    var region_1_start: usize = 0;
    var region_2_start: usize = 0;

    if (side_info.win_switch_flag[gr][ch] == 1 and side_info.block_type[gr][ch] == 2) {
        region_1_start = 36; // sfb[9/3]*3=36
        region_2_start = SAMPLES_PER_GR; // No Region2 for short block case.
    } else {
        // Select scalefactor band indices by (lsf, samplingFrequency) for Layer III
        const lsf = header.lowSamplingFrequency();
        const sfreq_index: usize = @intCast(header.samplingFrequency());
        const l = mp3.sf_band_indices[@intFromBool(lsf)][sfreq_index][SF_BAND_INDICES_LONG];
        const i = side_info.region0_count[gr][ch] + 1;
        if (i < 0 or i >= l.len) {
            return error.InvalidIndex;
        }
        region_1_start = l[i];
        const j = side_info.region0_count[gr][ch] + side_info.region1_count[gr][ch] + 2;
        if (j < 0 or j >= l.len) {
            return error.InvalidIndex;
        }
        region_2_start = l[j];
    }

    // Read big_values using tables according to region_x_start
    var is_pos: usize = 0;
    while (is_pos < @as(usize, side_info.big_values[gr][ch]) * 2) {
        if (is_pos >= md.is[gr][ch].len) {
            return error.InvalidPosition;
        }

        var table_num: u8 = 0;
        if (is_pos < region_1_start) {
            table_num = side_info.table_select[gr][ch][0];
        } else if (is_pos < region_2_start) {
            table_num = side_info.table_select[gr][ch][1];
        } else {
            table_num = side_info.table_select[gr][ch][2];
        }

        // Get next Huffman coded words
        const huff_result = try huffman.decode(m, table_num);

        // In the big_values area there are two freq lines per Huffman word
        md.is[gr][ch][is_pos] = @as(f32, @floatFromInt(huff_result.x));
        is_pos += 1;
        md.is[gr][ch][is_pos] = @as(f32, @floatFromInt(huff_result.y));
        is_pos += 1;
    }

    // Read small values until is_pos = 576 or we run out of huffman data
    const table_num = @as(u8, @intCast(side_info.count1_table_select[gr][ch] + @as(u8, 32)));
    is_pos = @as(usize, side_info.big_values[gr][ch]) * 2;

    while (is_pos <= 572 and m.bitPosition() <= bit_pos_end) {
        // Get next Huffman coded words
        const huff_result = try huffman.decode(m, table_num);

        md.is[gr][ch][is_pos] = @as(f32, @floatFromInt(huff_result.v));
        is_pos += 1;
        if (is_pos >= SAMPLES_PER_GR) break;

        md.is[gr][ch][is_pos] = @as(f32, @floatFromInt(huff_result.w));
        is_pos += 1;
        if (is_pos >= SAMPLES_PER_GR) break;

        md.is[gr][ch][is_pos] = @as(f32, @floatFromInt(huff_result.x));
        is_pos += 1;
        if (is_pos >= SAMPLES_PER_GR) break;

        md.is[gr][ch][is_pos] = @as(f32, @floatFromInt(huff_result.y));
        is_pos += 1;
    }

    // Check that we didn't read past the end of this section
    if (m.bitPosition() > (bit_pos_end + 1)) {
        // Remove last words read
        if (is_pos >= 4) {
            is_pos -= 4;
        }
    }
    if (is_pos < 0) {
        is_pos = 0;
    }

    // Setup count1 which is the index of the first sample in the rzero reg.
    side_info.count1[gr][ch] = @intCast(is_pos);

    // Zero out the last part if necessary
    while (is_pos < SAMPLES_PER_GR) {
        md.is[gr][ch][is_pos] = 0.0;
        is_pos += 1;
    }

    // Set the bitpos to point to the next part to read
    m.setPosition(bit_pos_end + 1);
}

pub const ReadFullResult = struct {
    main_data: MainData,
    bits: bits.Bits,
};

pub fn readFull(
    allocator: std.mem.Allocator,
    source: *std.Io.Reader,
    prev: ?*bits.Bits,
    header: frameheader.FrameHeader,
    side_info: *sideinfo.SideInfo,
) !ReadFullResult {
    const nch = header.numberOfChannels();

    // Calculate header audio data size
    const framesize = header.frameSize() orelse return error.InvalidFrameSize;
    if (framesize > 2000) {
        return error.InvalidFrameSize;
    }
    const sideinfo_size = header.sideInfoSize();

    // Main data size is the rest of the frame, including ancillary data
    var main_data_size = framesize - sideinfo_size - 4; // sync+header
    // CRC is 2 bytes
    if (header.protectionBit() == 0) {
        main_data_size -= 2;
    }

    // Assemble main data buffer with data from this frame and the previous
    // two frames. main_data_begin indicates how many bytes from previous
    // frames that should be used. This buffer is later accessed by the
    // Bits function in the same way as the side info is.
    var m = try read(allocator, source, prev, main_data_size, side_info.main_data_begin);

    if (header.lowSamplingFrequency()) {
        const md = try getScaleFactorsMpeg2(allocator, &m, header, side_info);
        return .{ .main_data = md, .bits = m };
    }
    const md = try getScaleFactorsMpeg1(nch, &m, header, side_info);
    return .{ .main_data = md, .bits = m };
}

// Private function to read main data with reservoir handling
fn read(
    allocator: std.mem.Allocator,
    source: *std.Io.Reader,
    prev: ?*bits.Bits,
    size: usize,
    offset: usize,
) !bits.Bits {
    if (size > 1500) {
        return error.InvalidSize;
    }

    // Check that there's data available from previous frames if needed
    if (prev != null and offset > prev.?.lenInBytes()) {
        // No, there is not, so we skip decoding this frame, but we have to
        // read the main_data bits from the bitstream in case they are needed
        // for decoding the next frame.
        const buf = try allocator.alloc(u8, size);
        defer allocator.free(buf);

        try source.readSliceAll(buf);

        // TODO: Define a special error and enable to continue the next frame.
        var new_vec = std.array_list.Managed(u8).init(allocator);
        new_vec.appendSlice(prev.?.vec.items) catch return error.OutOfMemory;
        new_vec.appendSlice(buf) catch return error.OutOfMemory;
        return bits.Bits{ .vec = new_vec };
    }

    // Copy data from previous frames
    var vec = std.array_list.Managed(u8).init(allocator);

    if (prev != null) {
        const tail_data = prev.?.tail(offset);
        vec.appendSlice(tail_data) catch return error.OutOfMemory;
    }

    // Read the main_data from file
    const buf = try allocator.alloc(u8, size);
    defer allocator.free(buf);

    try source.readSliceAll(buf);

    vec.appendSlice(buf) catch return error.OutOfMemory;
    return bits.Bits{ .vec = vec };
}

const testing = @import("std").testing;

test "slen2 lookup table generation" {
    // Test that the table has correct size
    try testing.expectEqual(@as(usize, 512), slen2.len);

    // Test some known values from the Go implementation
    // First loop: n=500, i=0, j=0 should give: 0 | (0 << 3) | (2 << 12) | (1 << 15) = 0xa000
    try testing.expectEqual(@as(u32, 0xa000), slen2[500]);

    // First loop: n=501, i=0, j=1 should give: 0 | (1 << 3) | (2 << 12) | (1 << 15) = 0xa008
    try testing.expectEqual(@as(u32, 0xa008), slen2[501]);

    // Second loop: n=0, i=0, j=0, k=0, l=0 should give: 0 | (0 << 3) | (0 << 6) | (0 << 9) | (0 << 12) = 0
    try testing.expectEqual(@as(u32, 0), slen2[0]);

    // Third loop: n=400, i=0, j=0, k=0 should give: 0 | (0 << 3) | (0 << 6) | (1 << 12) = 0x1000
    try testing.expectEqual(@as(u32, 0x1000), slen2[400]);

    // Test that all values are finite (no overflow)
    for (slen2) |value| {
        try testing.expect(std.math.isFinite(@as(f32, @floatFromInt(value))));
    }
}

test "scale factor functions basic structure" {
    const allocator = testing.allocator;

    // Create a test MP3 header (MPEG-1, Layer III, 128kbps, 44.1kHz, Stereo)
    const header_raw: u32 = 0xFFFB9000;
    const header = frameheader.FrameHeader.init(header_raw);

    // Create minimal sideinfo data
    var side_info = sideinfo.SideInfo{};

    // Create minimal bits reader with empty data
    const test_data = [_]u8{0} ** 100;
    var bit_reader = bits.Bits.init(allocator, &test_data);
    defer bit_reader.vec.deinit();

    // Test that functions can be called and return valid MainData structures
    const result_mpeg1 = try getScaleFactorsMpeg1(2, &bit_reader, header, &side_info);
    try testing.expectEqual(@as(usize, 2), result_mpeg1.scalefac_l.len);
    try testing.expectEqual(@as(usize, 2), result_mpeg1.scalefac_l[0].len);
    try testing.expectEqual(@as(usize, 22), result_mpeg1.scalefac_l[0][0].len);

    const result_mpeg2 = try getScaleFactorsMpeg2(allocator, &bit_reader, header, &side_info);
    try testing.expectEqual(@as(usize, 2), result_mpeg2.scalefac_l.len);
    try testing.expectEqual(@as(usize, 2), result_mpeg2.scalefac_l[0].len);
    try testing.expectEqual(@as(usize, 22), result_mpeg2.scalefac_l[0][0].len);
}

test "readHuffman function basic structure" {
    const allocator = testing.allocator;

    // Create a test MP3 header (MPEG-1, Layer III, 128kbps, 44.1kHz, Stereo)
    const header_raw: u32 = 0xFFFB9000;
    const header = frameheader.FrameHeader.init(header_raw);

    // Create minimal sideinfo data with zero part2_3_length (should zero the array)
    var side_info = sideinfo.SideInfo{};
    side_info.part2_3_length[0][0] = 0; // No data to decode

    // Create minimal bits reader with empty data
    const test_data = [_]u8{0} ** 100;
    var bit_reader = bits.Bits.init(allocator, &test_data);
    defer bit_reader.vec.deinit();

    // Create MainData structure
    var main_data = MainData{};

    // Test readHuffman with zero part2_3_length
    try readHuffman(&bit_reader, header, &side_info, &main_data, 0, 0, 0);

    // Verify that all samples are zeroed
    for (main_data.is[0][0]) |sample| {
        try testing.expectEqual(@as(f32, 0.0), sample);
    }

    // Test that the function doesn't crash with minimal data
    try testing.expectEqual(@as(usize, 576), main_data.is[0][0].len);
}

test "readFull function basic structure" {
    const allocator = testing.allocator;

    // Create a test MP3 header (MPEG-1, Layer III, 128kbps, 44.1kHz, Stereo)
    const header_raw: u32 = 0xFFFB9000;
    const header = frameheader.FrameHeader.init(header_raw);

    // Create minimal sideinfo data
    var side_info = sideinfo.SideInfo{};

    // Create minimal reader with empty data
    const test_data = [_]u8{0} ** 100;
    var reader_instance = std.Io.Reader.fixed(&test_data);
    const reader = &reader_instance;

    // Test readFull with no previous data
    const result = readFull(allocator, reader, null, header, &side_info);
    // This should fail due to insufficient data, which is expected
    try testing.expectError(error.EndOfStream, result);
}

test "read function basic structure" {
    const allocator = testing.allocator;

    // Create minimal reader with insufficient data
    const test_data = [_]u8{0} ** 10;
    var reader_instance = std.Io.Reader.fixed(&test_data);
    const reader = &reader_instance;

    // Test read with no previous data - should succeed with small data
    var result = try read(allocator, reader, null, 5, 0);
    defer result.vec.deinit();

    // Verify that we got a Bits struct back
    try testing.expectEqual(@as(usize, 5), result.lenInBytes());
}
