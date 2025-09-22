const std = @import("std");
const api = @import("../root.zig");
const mp3 = @import("../mp3.zig");
const io = @import("../io.zig");

// MP3 frame header structure
pub const FrameHeader = struct {
    raw: u32,

    pub fn init(raw: u32) FrameHeader {
        return .{ .raw = raw };
    }

    // Extract sync word (bits 31-21)
    pub fn syncWord(self: FrameHeader) u11 {
        return @truncate((self.raw >> 21) & 0x7FF);
    }

    // Extract version (bits 20-19)
    pub fn version(self: FrameHeader) mp3.Version {
        return @enumFromInt((self.raw >> 19) & 0x3);
    }

    // Extract layer (bits 18-17)
    pub fn layer(self: FrameHeader) mp3.Layer {
        return @enumFromInt((self.raw >> 17) & 0x3);
    }

    // Extract protection bit (bit 16)
    pub fn protectionBit(self: FrameHeader) u1 {
        return @truncate((self.raw >> 16) & 0x1);
    }

    // Extract bitrate index (bits 15-12)
    pub fn bitrateIndex(self: FrameHeader) u4 {
        return @truncate((self.raw >> 12) & 0xF);
    }

    // Extract sampling frequency (bits 11-10)
    pub fn samplingFrequency(self: FrameHeader) u2 {
        return @truncate((self.raw >> 10) & 0x3);
    }

    // Extract padding bit (bit 9)
    pub fn paddingBit(self: FrameHeader) u1 {
        return @truncate((self.raw >> 9) & 0x1);
    }

    // Extract private bit (bit 8)
    pub fn privateBit(self: FrameHeader) u1 {
        return @truncate((self.raw >> 8) & 0x1);
    }

    // Extract channel mode (bits 7-6)
    pub fn mode(self: FrameHeader) mp3.Mode {
        return @enumFromInt((self.raw >> 6) & 0x3);
    }

    // Extract mode extension (bits 5-4)
    pub fn modeExtension(self: FrameHeader) u2 {
        return @truncate((self.raw >> 4) & 0x3);
    }

    // Extract copyright bit (bit 3)
    pub fn copyright(self: FrameHeader) u1 {
        return @truncate((self.raw >> 3) & 0x1);
    }

    // Extract original/copy bit (bit 2)
    pub fn originalOrCopy(self: FrameHeader) u1 {
        return @truncate((self.raw >> 2) & 0x1);
    }

    // Extract emphasis (bits 1-0)
    pub fn emphasis(self: FrameHeader) u2 {
        return @truncate(self.raw & 0x3);
    }

    // Check if this is a low sampling frequency (MPEG-2/2.5)
    pub fn lowSamplingFrequency(self: FrameHeader) bool {
        return self.version() != .v1;
    }

    // Get actual sampling frequency value
    pub fn samplingFrequencyValue(self: FrameHeader) ?u32 {
        const freq_index = self.samplingFrequency();
        if (freq_index == 3) return null; // Reserved

        const base_freqs: [3]u32 = .{ 44100, 48000, 32000 };
        const base_freq = base_freqs[freq_index];

        return if (self.lowSamplingFrequency()) base_freq / 2 else base_freq;
    }

    // Get number of channels
    pub fn numberOfChannels(self: FrameHeader) u8 {
        return if (self.mode() == .single_channel) 1 else 2;
    }

    pub fn sideInfoSize(self: FrameHeader) u16 {
        const mono = self.mode() == .single_channel;
        if (self.lowSamplingFrequency()) {
            return if (mono) 9 else 17;
        } else {
            return if (mono) 17 else 32;
        }
    }

    // Check if header is valid
    pub fn isValid(self: FrameHeader) bool {
        const sync = 0x7FF; // 11 bits
        if (self.syncWord() != sync) return false;
        if (self.version() == .reserved) return false;
        if (self.bitrateIndex() == 15) return false; // Bad bitrate
        if (self.samplingFrequency() == 3) return false; // Reserved
        if (self.layer() == .reserved) return false;
        if (self.emphasis() == 2) return false; // Reserved emphasis
        return true;
    }

    // Get bitrate in bits per second
    pub fn bitrate(self: FrameHeader) ?u32 {
        const bitrates: [2][3][16]u32 = .{
            .{ // MPEG-1
                .{ // Layer 3
                    0,      32000,  40000,  48000,  56000,  64000,  80000,  96000,
                    112000, 128000, 160000, 192000, 224000, 256000, 320000, 0,
                },
                .{ // Layer 2
                    0,      32000,  48000,  56000,  64000,  80000,  96000,  112000,
                    128000, 160000, 192000, 224000, 256000, 320000, 384000, 0,
                },
                .{ // Layer 1
                    0,      32000,  64000,  96000,  128000, 160000, 192000, 224000,
                    256000, 288000, 320000, 352000, 384000, 416000, 448000, 0,
                },
            },
            .{ // MPEG-2/2.5
                .{ // Layer 3
                    0,     8000,  16000, 24000,  32000,  40000,  48000,  56000,
                    64000, 80000, 96000, 112000, 128000, 144000, 160000, 0,
                },
                .{ // Layer 2
                    0,     8000,  16000, 24000,  32000,  40000,  48000,  56000,
                    64000, 80000, 96000, 112000, 128000, 144000, 160000, 0,
                },
                .{ // Layer 1
                    0,      32000,  48000,  56000,  64000,  80000,  96000,  112000,
                    128000, 144000, 160000, 176000, 192000, 224000, 256000, 0,
                },
            },
        };

        const low_freq: usize = if (self.lowSamplingFrequency()) 1 else 0;
        const layer_idx = @intFromEnum(self.layer()) - 1; // Convert enum to 0-based index
        const bitrate_idx = self.bitrateIndex();

        if (layer_idx >= 3 or bitrate_idx >= 16) return null;
        return bitrates[low_freq][layer_idx][bitrate_idx];
    }

    pub fn granules(self: FrameHeader) u8 {
        // MPEG2 uses only 1 granule
        return mp3.granules_mpeg1 >> @intFromBool(self.lowSamplingFrequency());
    }

    // Calculate frame size in bytes
    pub fn frameSize(self: FrameHeader) ?usize {
        const bitrate_val = self.bitrate() orelse return null;
        const freq_val = self.samplingFrequencyValue() orelse return null;

        const samples_per_frame: u16 = if (self.layer() == .v1) 384 else 1152;
        const padding = self.paddingBit();

        const frame_size = ((samples_per_frame * bitrate_val) / (8 * freq_val)) + padding;
        return if (self.lowSamplingFrequency()) frame_size / 2 else frame_size;
    }
};

// Read MP3 frame header from stream
pub fn readFrameHeader(reader: *std.Io.Reader) api.ReadError!struct { header: FrameHeader, position: u64 } {
    // Read 4 bytes for the header
    const header_bytes = try reader.peek(4);
    var header_raw: u32 = 0;

    // Convert bytes to big-endian u32
    header_raw = (@as(u32, header_bytes[0]) << 24) |
        (@as(u32, header_bytes[1]) << 16) |
        (@as(u32, header_bytes[2]) << 8) |
        @as(u32, header_bytes[3]);

    var header = FrameHeader.init(header_raw);
    var position: u64 = 0;

    // Search for valid sync word by shifting bytes
    while (!header.isValid()) {
        // Shift bytes left and read next byte
        header_raw = (header_raw << 8) & 0xFFFFFF00;

        const next_byte = reader.peek(1) catch |e| switch (e) {
            error.EndOfStream => return error.EndOfStream,
            else => return error.ReadFailed,
        };

        header_raw |= next_byte[0];
        header = FrameHeader.init(header_raw);
        position += 1;

        // Advance reader past the byte we just peeked
        reader.toss(1);
    }

    // Check for free bitrate format (not supported)
    if (header.bitrateIndex() == 0) {
        return error.InvalidFormat;
    }

    return .{ .header = header, .position = position };
}

const testing = std.testing;

test "frame header parsing" {
    // Test with a valid MP3 frame header: 0xFF 0xFB 0x90 0x00
    // This represents: MPEG-1, Layer III, 128kbps, 44.1kHz, Stereo
    // Layer III = 01 in bits 18-17
    const test_data = [_]u8{ 0xFF, 0xFB, 0x90, 0x00 };
    var reader = std.Io.Reader.fixed(&test_data);

    const result = try readFrameHeader(&reader);
    const header = result.header;

    try testing.expectEqual(mp3.Version.v1, header.version());
    try testing.expectEqual(mp3.Layer.v3, header.layer());
    try testing.expectEqual(@as(u4, 9), header.bitrateIndex()); // 128kbps
    try testing.expectEqual(@as(u2, 0), header.samplingFrequency()); // 44.1kHz
    try testing.expectEqual(mp3.Mode.stereo, header.mode());
    try testing.expectEqual(@as(u8, 2), header.numberOfChannels());

    const freq = header.samplingFrequencyValue();
    try testing.expectEqual(@as(u32, 44100), freq.?);

    const bitrate = header.bitrate();
    try testing.expectEqual(@as(u32, 128000), bitrate.?);

    try testing.expect(header.isValid());
}

test "frame header validation" {
    // Test invalid header (wrong sync word)
    const invalid_data = [_]u8{ 0x00, 0x00, 0x00, 0x00 };
    var reader = std.Io.Reader.fixed(&invalid_data);

    const result = readFrameHeader(&reader);
    try testing.expectError(error.EndOfStream, result);
}

test "frame header bit extraction" {
    // Test individual bit extractions
    const header = FrameHeader.init(0xFFFB9000);

    try testing.expectEqual(@as(u11, 0x7FF), header.syncWord());
    try testing.expectEqual(mp3.Version.v1, header.version());
    try testing.expectEqual(mp3.Layer.v3, header.layer());
    try testing.expectEqual(@as(u4, 9), header.bitrateIndex());
    try testing.expectEqual(@as(u2, 0), header.samplingFrequency());
    try testing.expectEqual(@as(u1, 0), header.paddingBit());
    try testing.expectEqual(@as(u1, 0), header.privateBit());
    try testing.expectEqual(mp3.Mode.stereo, header.mode());
    try testing.expectEqual(@as(u2, 0), header.modeExtension());
    try testing.expectEqual(@as(u1, 0), header.copyright());
    try testing.expectEqual(@as(u1, 0), header.originalOrCopy());
    try testing.expectEqual(@as(u2, 0), header.emphasis());
}
