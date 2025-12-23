const std = @import("std");
const sideinfo = @import("sideinfo.zig");

const MAX_CHANNELS: usize = 2;

/// Bit reservoir management for Layer III encoder.
pub const Reservoir = struct {
    reservoir_size: i64 = 0,
    reservoir_max_size: i64 = 0,
    mean_bits: i64 = 0,
    channels: u8,

    pub const MpegVersion = enum { mpeg1, mpeg2 };

    pub fn init(channels: u8, _: MpegVersion) Reservoir {
        // const max_size: i64 = if (mpeg_version == .mpeg1) 511 * 8 else 255 * 8;
        return .{
            .reservoir_size = 0,
            .mean_bits = 0,
            .channels = channels,
        };
    }

    pub fn maxReservoirBits(self: *const Reservoir, perceptual_entropy: *const f64) i64 {
        const mean_bits = @divTrunc(self.mean_bits, @as(i64, self.channels));
        var max_bits = mean_bits;
        if (max_bits > 4095) max_bits = 4095;
        if (self.reservoir_max_size == 0) return max_bits;

        const more_bits = @as(i64, @intFromFloat(perceptual_entropy.* * 3.1 - @as(f64, @floatFromInt(mean_bits))));
        var add_bits: i64 = 0;

        if (more_bits > 100) {
            const frac = @divTrunc(self.reservoir_size * 6, 10);
            if (frac < more_bits) {
                add_bits = frac;
            } else {
                add_bits = more_bits;
            }
        }

        const div_result = @divTrunc(self.reservoir_max_size << 3, 10);
        const over_bits = self.reservoir_size - div_result - add_bits;
        if (over_bits > 0) {
            add_bits += over_bits;
        }

        max_bits += add_bits;
        if (max_bits > 4095) max_bits = 4095;
        return max_bits;
    }

    pub fn reservoirAdjust(self: *Reservoir, granule_info: *sideinfo.EncoderGranuleInfo) void {
        const mean_bits_per_channel = @divTrunc(self.mean_bits, @as(i64, self.channels));
        const part2_3_length_i64: i64 = @intCast(granule_info.part2_3_length);
        self.reservoir_size += mean_bits_per_channel - part2_3_length_i64;
    }

    pub fn reservoirFrameEnd(
        self: *Reservoir,
        side_info: *sideinfo.EncoderSideInfo,
        granules_per_frame: u8,
    ) void {
        const ancillary_pad: i64 = 0;

        if (self.channels == 2 and (self.mean_bits & 1) != 0) {
            self.reservoir_size += 1;
        }

        var over_bits = self.reservoir_size - self.reservoir_max_size;
        if (over_bits < 0) over_bits = 0;
        self.reservoir_size -= over_bits;
        var stuffing_bits = over_bits + ancillary_pad;

        over_bits = @mod(self.reservoir_size, 8);
        if (over_bits != 0) {
            stuffing_bits += over_bits;
            self.reservoir_size -= over_bits;
        }

        if (stuffing_bits > 0) {
            var gran_info = &side_info.granules[0].channels[0].tt;
            if (gran_info.part2_3_length + @as(u64, @intCast(stuffing_bits)) < 4095) {
                gran_info.part2_3_length += @as(u64, @intCast(stuffing_bits));
            } else {
                var remaining = stuffing_bits;
                var gr: usize = 0;
                while (gr < @as(usize, granules_per_frame)) : (gr += 1) {
                    var ch: usize = 0;
                    while (ch < @as(usize, self.channels)) : (ch += 1) {
                        if (remaining == 0) break;
                        var target = &side_info.granules[gr].channels[ch].tt;
                        const extra_bits = @as(i64, 4095) - @as(i64, @intCast(target.part2_3_length));
                        if (extra_bits <= 0) continue;
                        const bits_this_granule = if (extra_bits < remaining) extra_bits else remaining;
                        target.part2_3_length += @intCast(bits_this_granule);
                        remaining -= bits_this_granule;
                    }
                    if (remaining == 0) break;
                }
                side_info.reservoir_drain = remaining;
            }
        }
    }
};

const testing = std.testing;

test "reservoir init" {
    // reservoir_max_size is intentionally 0 to match shine-mp3 behavior
    // (shine-mp3 initializes reservoir before MPEG version is known)
    const res = Reservoir.init(2, .mpeg1);
    try testing.expectEqual(@as(i64, 0), res.reservoir_max_size);
    try testing.expectEqual(@as(u8, 2), res.channels);

    const res2 = Reservoir.init(1, .mpeg2);
    try testing.expectEqual(@as(i64, 0), res2.reservoir_max_size);
    try testing.expectEqual(@as(u8, 1), res2.channels);
}

test "max reservoir bits" {
    var res = Reservoir.init(2, .mpeg1);
    res.mean_bits = 1000;
    const pe: f64 = 100.0;
    const max = res.maxReservoirBits(&pe);
    try testing.expect(max > 0);
}

test "reservoir adjust" {
    var res = Reservoir.init(2, .mpeg1);
    res.mean_bits = 1000;
    var granule_info = sideinfo.EncoderGranuleInfo{};
    granule_info.part2_3_length = 400;
    res.reservoirAdjust(&granule_info);
    try testing.expect(res.reservoir_size != 0);
}
