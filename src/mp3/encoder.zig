const std = @import("std");
const BitWriter = @import("../BitWriter.zig").BitWriter;
const mp3 = @import("../mp3.zig");
const frameheader = @import("frameheader.zig");
const sideinfo = @import("sideinfo.zig");
const mdct_forward = @import("mdct_forward.zig");
const subband_analysis = @import("subband_analysis.zig");
const psycho = @import("psycho.zig");
const l3loop = @import("l3loop.zig");
const reservoir_mod = @import("reservoir.zig");
const huffman_encode = @import("huffman_encode.zig");
const tables = @import("tables.zig");

const GRANULE_SIZE: usize = 576;
const MAX_CHANNELS: usize = 2;
const MAX_GRANULES: usize = 2;
const SUBBAND_LIMIT: usize = 32;
const HAN_SIZE: usize = 512;

// Sample rates table (from Go)
// MP3 Encoder structure
pub const Encoder = struct {
    allocator: std.mem.Allocator,
    sample_rate: u32,
    channels: u8,
    bitrate: u32,
    version: mp3.Version,
    sample_rate_index: u8,
    bitrate_index: u4,
    granules_per_frame: u8,
    side_info_len: i64,
    mean_bits: i64,
    whole_slots_per_frame: i64,
    frac_slots_per_frame: f64,
    slot_lag: f64,
    padding: u1,

    // Components
    bitwriter: BitWriter,
    side_info: sideinfo.EncoderSideInfo,
    ratio: psycho.PsyRatio,
    scale_factor: psycho.ScaleFactor,
    perceptual_energy: [MAX_CHANNELS][MAX_GRANULES]f64,
    l3_encoding: [MAX_CHANNELS][MAX_GRANULES][GRANULE_SIZE]i64,
    l3_subband_samples: [MAX_CHANNELS][MAX_GRANULES + 1][18][SUBBAND_LIMIT]i32,
    mdct_frequency: [MAX_CHANNELS][MAX_GRANULES][GRANULE_SIZE]i32,
    reservoir: reservoir_mod.Reservoir,
    l3loop_state: l3loop.L3Loop,
    mdct: mdct_forward.MDCT,
    subband: subband_analysis.Subband,

    // Buffer management
    buffer: [MAX_CHANNELS]usize,
    buffer_data: []const i16,

    const Self = @This();

    /// Create a new encoder
    pub fn init(allocator: std.mem.Allocator, sample_rate: u32, channels: u8) !Self {
        // Find sample rate index
        var sample_rate_index: ?u8 = null;
        for (tables.sample_rates, 0..) |rate, i| {
            if (rate == sample_rate) {
                sample_rate_index = @intCast(i);
                break;
            }
        }
        const sri = sample_rate_index orelse return error.UnsupportedSampleRate;

        // Determine MPEG version
        const version: mp3.Version = if (sri < 3)
            .v1
        else if (sri < 6)
            .v2
        else
            .v2_5;

        // Determine granules per frame
        const granules_per_frame: u8 = if (version == .v1) 2 else 1;

        // Default bitrate (128 kbps)
        const default_bitrate: u32 = 128000;
        const mpeg_idx: usize = @intFromEnum(version);
        var bitrate_index: ?u4 = null;
        for (tables.bitrates, 0..) |br_row, i| {
            if (i < 16 and mpeg_idx < 4) {
                if (br_row[mpeg_idx] == @as(i32, @intCast(default_bitrate / 1000))) {
                    bitrate_index = @intCast(i);
                    break;
                }
            }
        }
        const bri = bitrate_index orelse 9; // Default to index 9 (128 kbps for MPEG-1)

        // Calculate frame parameters
        const avg_slots_per_frame = (@as(f64, @floatFromInt(granules_per_frame)) * @as(f64, @floatFromInt(GRANULE_SIZE)) / @as(f64, @floatFromInt(sample_rate))) * (@as(f64, @floatFromInt(default_bitrate)) / 8.0);
        const whole_slots = @as(i64, @intFromFloat(avg_slots_per_frame));
        const frac_slots = avg_slots_per_frame - @as(f64, @floatFromInt(whole_slots));

        // Calculate side info length
        const side_info_len: i64 = if (granules_per_frame == 2) blk: {
            const delta: usize = if (channels == 1) 4 + 9 else 4 + 32;
            break :blk @as(i64, @intCast(delta * 8));
        } else blk: {
            const delta: usize = if (channels == 1) 4 + 9 else 4 + 17;
            break :blk @as(i64, @intCast(delta * 8));
        };

        var mdct = mdct_forward.MDCT{};
        mdct.init();

        var subband = subband_analysis.Subband{};
        subband.init();

        var l3loop_state = l3loop.L3Loop{
            .xr = undefined,
            .xrsq = undefined,
            .xrabs = undefined,
            .xrmax = 0,
            .en_tot = undefined,
            .en = undefined,
            .xm = undefined,
            .xrmaxl = undefined,
            .step_table = undefined,
            .step_table_i = undefined,
            .int2idx = undefined,
        };
        l3loop.initL3Loop(&l3loop_state);

        // Match shine-mp3: reservoir max size is initialized before the MPEG version is known,
        // so MPEG-2 sizing is used even for MPEG-1 streams.
        const reservoir = reservoir_mod.Reservoir.init(channels, .mpeg2);

        return Self{
            .allocator = allocator,
            .sample_rate = sample_rate,
            .channels = channels,
            .bitrate = default_bitrate,
            .version = version,
            .sample_rate_index = sri,
            .bitrate_index = bri,
            .granules_per_frame = granules_per_frame,
            .side_info_len = side_info_len,
            .mean_bits = 0,
            .whole_slots_per_frame = whole_slots,
            .frac_slots_per_frame = frac_slots,
            .slot_lag = -frac_slots,
            .padding = 0,
            .bitwriter = BitWriter.init(allocator),
            .side_info = sideinfo.EncoderSideInfo{},
            .ratio = std.mem.zeroes(psycho.PsyRatio),
            .scale_factor = std.mem.zeroes(psycho.ScaleFactor),
            .perceptual_energy = .{.{0.0} ** MAX_GRANULES} ** MAX_CHANNELS,
            .l3_encoding = std.mem.zeroes([MAX_CHANNELS][MAX_GRANULES][GRANULE_SIZE]i64),
            .l3_subband_samples = std.mem.zeroes([MAX_CHANNELS][MAX_GRANULES + 1][18][SUBBAND_LIMIT]i32),
            .mdct_frequency = std.mem.zeroes([MAX_CHANNELS][MAX_GRANULES][GRANULE_SIZE]i32),
            .reservoir = reservoir,
            .l3loop_state = l3loop_state,
            .mdct = mdct,
            .subband = subband,
            .buffer = .{0} ** MAX_CHANNELS,
            .buffer_data = undefined,
        };
    }

    fn mdctSub(self: *Self, stride: usize) void {
        const channel_count = @as(usize, self.channels);
        const granules = @as(usize, self.granules_per_frame);
        var ch: usize = 0;
        while (ch < channel_count) : (ch += 1) {
            var gr: usize = 0;
            while (gr < granules) : (gr += 1) {
                var k: usize = 0;
                while (k < 18) : (k += 2) {
                    subband_analysis.windowFilterSubband(
                        &self.subband,
                        &self.l3_subband_samples[ch][gr + 1][k],
                        ch,
                        stride,
                        self.buffer_data,
                        &self.buffer[ch],
                    );
                    subband_analysis.windowFilterSubband(
                        &self.subband,
                        &self.l3_subband_samples[ch][gr + 1][k + 1],
                        ch,
                        stride,
                        self.buffer_data,
                        &self.buffer[ch],
                    );
                    var band: usize = 1;
                    while (band < SUBBAND_LIMIT) : (band += 2) {
                        self.l3_subband_samples[ch][gr + 1][k + 1][band] =
                            -self.l3_subband_samples[ch][gr + 1][k + 1][band];
                    }
                }
                mdct_forward.mdctForward(
                    &self.mdct,
                    self.l3_subband_samples[ch][gr],
                    self.l3_subband_samples[ch][gr + 1],
                    &self.mdct_frequency[ch][gr],
                );
            }
            var prev: usize = 0;
            while (prev < 18) : (prev += 1) {
                var band: usize = 0;
                while (band < SUBBAND_LIMIT) : (band += 1) {
                    self.l3_subband_samples[ch][0][prev][band] =
                        self.l3_subband_samples[ch][granules][prev][band];
                }
            }
        }
    }

    /// Encode a buffer of interleaved PCM samples
    pub fn encodeBuffer(self: *Self, data: []const i16) ![]const u8 {
        self.buffer_data = data;
        self.buffer[0] = 0;
        if (self.channels == 2) {
            self.buffer[1] = 1;
        }

        // Calculate padding
        if (self.frac_slots_per_frame != 0) {
            if (self.slot_lag <= (self.frac_slots_per_frame - 1.0)) {
                self.padding = 1;
            } else {
                self.padding = 0;
            }
            self.slot_lag += @as(f64, @floatFromInt(self.padding)) - self.frac_slots_per_frame;
        }

        const bits_per_frame = (@as(i64, self.whole_slots_per_frame) + @as(i64, self.padding)) * 8;
        self.mean_bits = @divTrunc((bits_per_frame - self.side_info_len), @as(i64, self.granules_per_frame));
        self.reservoir.mean_bits = self.mean_bits;

        self.mdctSub(@as(usize, self.channels));

        // Run iteration loop (quantization + huffman table selection)
        l3loop.iterationLoop(
            &self.ratio,
            &self.perceptual_energy,
            self.mdct_frequency,
            &self.l3_encoding,
            &self.l3loop_state,
            &self.side_info,
            &self.reservoir,
            @as(usize, self.sample_rate_index),
            @as(usize, self.granules_per_frame),
            @as(usize, self.channels),
            self.version == mp3.Version.v1,
        );

        try self.formatBitstream();
        const out = self.bitwriter.getData();
        self.bitwriter.data_position = 0;
        return out;
    }

    /// Format the bitstream (write frame header, side info, main data)
    fn formatBitstream(self: *Self) !void {
        // Write frame header
        const header_params = frameheader.HeaderParams{
            .version = self.version,
            .layer = .v3,
            .protection_bit = 1, // No CRC
            .bitrate_index = self.bitrate_index,
            .sampling_frequency = @truncate(self.sample_rate_index % 3),
            .padding = self.padding,
            .private_bit = 0,
            .mode = if (self.channels == 1) .single_channel else .stereo,
            .mode_extension = 0,
            .copyright = 0,
            .original = 1,
            .emphasis = 0,
        };
        try frameheader.writeFrameHeader(&self.bitwriter, header_params);

        // Write side info
        try sideinfo.writeSideInfo(
            &self.bitwriter,
            &self.side_info,
            self.version,
            self.channels,
            self.granules_per_frame,
        );

        try self.writeMainData();
    }

    fn writeMainData(self: *Self) !void {
        const channels = @as(usize, self.channels);
        const granules = @as(usize, self.granules_per_frame);
        const scale_factor_band_table = tables.scale_factor_band_index[@as(usize, self.sample_rate_index)][0..];

        var gr: usize = 0;
        while (gr < granules) : (gr += 1) {
            var ch: usize = 0;
            while (ch < channels) : (ch += 1) {
                const gran_info = &self.side_info.granules[gr].channels[ch].tt;
                const compress_idx = if (gran_info.scale_factor_compress < @as(u64, l3loop.sLen1Table.len)) @as(usize, gran_info.scale_factor_compress) else l3loop.sLen1Table.len - 1;
                const s_len1_val = l3loop.sLen1Table[compress_idx];
                const s_len2_val = l3loop.sLen2Table[compress_idx];
                const s_len1_u8: u8 = @truncate(s_len1_val);
                const s_len2_u8: u8 = @truncate(s_len2_val);
                const s_len1: u6 = @truncate(s_len1_u8);
                const s_len2: u6 = @truncate(s_len2_u8);
                const ix = &self.l3_encoding[ch][gr];

                var idx: usize = 0;
                while (idx < GRANULE_SIZE) : (idx += 1) {
                    if (self.mdct_frequency[ch][gr][idx] < 0 and ix[idx] > 0) {
                        ix[idx] = -ix[idx];
                    }
                }

                const scfsi = self.side_info.scale_factor_select_info[ch];
                if (gr == 0 or scfsi[0] == 0) {
                    for (0..6) |sfb| {
                        const c = self.scale_factor.l[gr][ch];
                        try self.bitwriter.putBits(@intCast(c[sfb]), s_len1);
                    }
                }
                if (gr == 0 or scfsi[1] == 0) {
                    for (6..11) |sfb| {
                        try self.bitwriter.putBits(@intCast(self.scale_factor.l[gr][ch][sfb]), s_len1);
                    }
                }
                if (gr == 0 or scfsi[2] == 0) {
                    for (11..16) |sfb| {
                        try self.bitwriter.putBits(@intCast(self.scale_factor.l[gr][ch][sfb]), s_len2);
                    }
                }
                if (gr == 0 or scfsi[3] == 0) {
                    for (16..21) |sfb| {
                        try self.bitwriter.putBits(@intCast(self.scale_factor.l[gr][ch][sfb]), s_len2);
                    }
                }

                try huffman_encode.huffmanCodeBits(
                    &self.bitwriter,
                    ix,
                    gran_info,
                    scale_factor_band_table,
                );
            }
        }
    }

    /// Clean up encoder resources
    pub fn deinit(self: *Self) void {
        self.bitwriter.deinit();
    }
};

const testing = std.testing;

test "encoder init" {
    var enc = try Encoder.init(testing.allocator, 44100, 2);
    defer enc.deinit();

    try testing.expectEqual(@as(u32, 44100), enc.sample_rate);
    try testing.expectEqual(@as(u8, 2), enc.channels);
    try testing.expect(enc.bitrate > 0);
}
