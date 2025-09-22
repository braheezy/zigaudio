const std = @import("std");
const api = @import("../root.zig");
const mp3 = @import("../mp3.zig");
const frameheader = @import("frameheader.zig");
const bits = @import("bits.zig");

// A SideInfo is MPEG1 Layer 3 Side Information.
// [2][2] means [gr][ch].
pub const SideInfo = struct {
    main_data_begin: u9 = 0, // 9 bits
    private_bits: u3 = 0, // 3 bits in mono, 5 in stereo
    scfsi: [2][4]u1 = undefined, // 1 bit
    part2_3_length: [2][2]u12 = undefined, // 12 bits
    big_values: [2][2]u9 = undefined, // 9 bits
    global_gain: [2][2]u8 = undefined, // 8 bits
    scalefac_compress: [2][2]u4 = undefined, // 4 bits
    win_switch_flag: [2][2]u1 = undefined, // 1 bit

    block_type: [2][2]u2 = undefined, // 2 bits
    mixed_block_flag: [2][2]u1 = undefined, // 1 bit
    table_select: [2][2][3]u5 = undefined, // 5 bits
    subblock_gain: [2][2][3]u3 = undefined, // 3 bits

    region0_count: [2][2]u4 = undefined, // 4 bits
    region1_count: [2][2]u3 = undefined, // 3 bits

    preflag: [2][2]u1 = undefined, // 1 bit
    scalefac_scale: [2][2]u1 = undefined, // 1 bit
    count1_table_select: [2][2]u1 = undefined, // 1 bit
    count1: [2][2]u1 = undefined, // Not in file, calc by huffman decoder
};

const side_info_bits_to_read = [2][4]u8{
    .{ 9, 5, 3, 4 }, // MPEG 1
    .{ 8, 1, 2, 9 }, // MPEG 2
};

// Read side information from a reader
pub fn readAll(allocator: std.mem.Allocator, reader: *std.Io.Reader, header: frameheader.FrameHeader) !SideInfo {
    const nch = header.numberOfChannels();
    const framesize = header.frameSize() orelse return error.InvalidFormat;

    if (framesize > 2000) {
        return error.InvalidFormat;
    }

    const sideinfo_size = header.sideInfoSize();

    // Main data size is the rest of the frame, including ancillary data
    var main_data_size = framesize - sideinfo_size - 4; // sync+header
    // CRC is 2 bytes
    if (header.protectionBit() == 0) {
        main_data_size -= 2;
    }

    // Read sideinfo from bitstream into buffer used by Bits()
    const buf = try allocator.alloc(u8, sideinfo_size);
    defer allocator.free(buf);

    try reader.readSliceAll(buf);

    var bit_reader = bits.Bits.init(allocator, buf);
    defer bit_reader.vec.deinit();

    const mpeg1_frame = !header.lowSamplingFrequency();
    const bits_to_read = side_info_bits_to_read[if (header.lowSamplingFrequency()) 1 else 0];

    // Parse audio data
    // Pointer to where we should start reading main data
    var si = SideInfo{};

    si.main_data_begin = @intCast(bit_reader.bits(bits_to_read[0]));

    // Get private bits. Not used for anything.
    if (header.mode() == .single_channel) {
        si.private_bits = @intCast(bit_reader.bits(bits_to_read[1]));
    } else {
        si.private_bits = @intCast(bit_reader.bits(bits_to_read[2]));
    }

    if (mpeg1_frame) {
        // Get scale factor selection information
        for (0..nch) |ch| {
            for (0..4) |scfsi_band| {
                si.scfsi[ch][scfsi_band] = @intCast(bit_reader.bits(1));
            }
        }
    }

    // Get the rest of the side information
    for (0..header.granules()) |gr| {
        for (0..nch) |ch| {
            si.part2_3_length[gr][ch] = @intCast(bit_reader.bits(12));
            si.big_values[gr][ch] = @intCast(bit_reader.bits(9));
            si.global_gain[gr][ch] = @intCast(bit_reader.bits(8));
            si.scalefac_compress[gr][ch] = @intCast(bit_reader.bits(bits_to_read[3]));
            si.win_switch_flag[gr][ch] = @intCast(bit_reader.bits(1));

            if (si.win_switch_flag[gr][ch] == 1) {
                si.block_type[gr][ch] = @intCast(bit_reader.bits(2));
                si.mixed_block_flag[gr][ch] = @intCast(bit_reader.bits(1));

                for (0..2) |region| {
                    si.table_select[gr][ch][region] = @intCast(bit_reader.bits(5));
                }

                for (0..3) |window| {
                    si.subblock_gain[gr][ch][window] = @intCast(bit_reader.bits(3));
                }

                // TODO: This is not listed on the spec. Is this correct??
                if (si.block_type[gr][ch] == 2 and si.mixed_block_flag[gr][ch] == 0) {
                    si.region0_count[gr][ch] = 8; // Implicit
                } else {
                    si.region0_count[gr][ch] = 7; // Implicit
                }
                // The standard is wrong on this!!!
                // Implicit
                si.region1_count[gr][ch] = @intCast(20 - @as(u8, si.region0_count[gr][ch]));
            } else {
                for (0..3) |region| {
                    si.table_select[gr][ch][region] = @intCast(bit_reader.bits(5));
                }
                si.region0_count[gr][ch] = @intCast(bit_reader.bits(4));
                si.region1_count[gr][ch] = @intCast(bit_reader.bits(3));
                si.block_type[gr][ch] = 0; // Implicit
                if (!mpeg1_frame) {
                    si.mixed_block_flag[0][ch] = 0;
                }
            }

            if (mpeg1_frame) {
                si.preflag[gr][ch] = @intCast(bit_reader.bits(1));
            }
            si.scalefac_scale[gr][ch] = @intCast(bit_reader.bits(1));
            si.count1_table_select[gr][ch] = @intCast(bit_reader.bits(1));
        }
    }

    return si;
}

const testing = std.testing;

test "sideinfo read basic structure" {
    const allocator = testing.allocator;

    // Create a test MP3 header (MPEG-1, Layer III, 128kbps, 44.1kHz, Stereo)
    const header_raw: u32 = 0xFFFB9000;
    const header = frameheader.FrameHeader.init(header_raw);

    // Create minimal sideinfo data for testing
    // For MPEG-1 stereo, sideinfo is 32 bytes
    const test_data = [_]u8{0} ** 32;
    var reader = std.Io.Reader.fixed(&test_data);

    const si = try readAll(allocator, &reader, header);

    // Basic structure validation
    try testing.expectEqual(@as(usize, 0), si.main_data_begin);
    try testing.expectEqual(@as(usize, 0), si.private_bits);

    // Test that arrays are properly sized
    try testing.expectEqual(@as(usize, 2), si.scfsi.len);
    try testing.expectEqual(@as(usize, 4), si.scfsi[0].len);
    try testing.expectEqual(@as(usize, 2), si.part2_3_length.len);
    try testing.expectEqual(@as(usize, 2), si.part2_3_length[0].len);
}
