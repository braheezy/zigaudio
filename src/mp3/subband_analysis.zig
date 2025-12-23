const std = @import("std");
const math = std.math;
const tables = @import("tables.zig");

const PI64: f64 = 0.049087385212; // PI/64
const HAN_SIZE: usize = 512;
const SUBBAND_LIMIT: usize = 32;
const enWindow = tables.enWindow;

// Subband filter structure
pub const Subband = struct {
    // Filter coefficients [32][64]i32
    fl: [SUBBAND_LIMIT][64]i32 = undefined,
    // Window buffer [2][512]i32
    x: [2][HAN_SIZE]i32 = undefined,
    // Offset for circular buffer [2]usize
    off: [2]usize = .{0} ** 2,

    pub fn init(self: *Subband) void {
        self.x = std.mem.zeroes([2][HAN_SIZE]i32);
        self.off = .{0} ** 2;
        // Calculate analysis filterbank coefficients
        var i: usize = 0;
        while (i < SUBBAND_LIMIT) : (i += 1) {
            var j: usize = 0;
            while (j < 64) : (j += 1) {
                const i_f = @as(f64, @floatFromInt(i));
                const j_f = @as(f64, @floatFromInt(j));
                var filter = math.cos((i_f * 2.0 + 1.0) * (16.0 - j_f) * PI64) * 1e9;

                // Round to nearest integer
                if (filter >= 0) {
                    filter = @floor(filter + 0.5);
                } else {
                    filter = @ceil(filter - 0.5);
                }

                // Scale and convert to fixed point
                const result = filter * (@as(f64, @floatFromInt(std.math.maxInt(i32))) * 1e-9);
                self.fl[i][j] = @intFromFloat(result);
            }
        }
    }
};

// Multiply two i32 values with proper scaling (fixed point arithmetic)
fn mul(a: i32, b: i32) i32 {
    const a_i64: i64 = @intCast(a);
    const b_i64: i64 = @intCast(b);
    const result: i64 = (a_i64 * b_i64) >> 32;
    return @intCast(result);
}

/// Window and filter subband samples
/// Processes 32 PCM samples and produces 32 subband samples
pub fn windowFilterSubband(
    subband: *Subband,
    s: *[SUBBAND_LIMIT]i32,
    ch: usize,
    stride: usize,
    buffer_data: []const i16,
    buffer_pos: *usize,
) void {
    var y: [64]i32 = undefined;

    // Replace 32 oldest samples with 32 new samples
    var i: usize = 32;
    while (i > 0) {
        i -= 1;
        var sample: i16 = 0;
        if (buffer_pos.* < buffer_data.len) {
            sample = buffer_data[buffer_pos.*];
        }
        buffer_pos.* += stride;
        // Scale to fixed point (left shift by 16)
        subband.x[ch][i + subband.off[ch]] = @as(i32, sample) << 16;
    }

    // Window the samples
    var j: usize = 0;
    while (j < 64) : (j += 1) {
        var s_value: i32 = 0;
        var k: usize = 0;
        while (k < 8) : (k += 1) {
            const idx = (subband.off[ch] + j + (k << 6)) & (HAN_SIZE - 1);
            s_value += mul(subband.x[ch][idx], enWindow[j + (k << 6)]);
        }
        y[j] = s_value;
    }

    // Update offset for circular buffer
    subband.off[ch] = (subband.off[ch] + 480) & (HAN_SIZE - 1);

    // Filter to produce subband samples
    var band: usize = 0;
    while (band < SUBBAND_LIMIT) : (band += 1) {
        var s_value: i32 = mul(subband.fl[band][63], y[63]);
        var j_idx: usize = 63;
        while (j_idx > 0) {
            if (j_idx >= 1) s_value += mul(subband.fl[band][j_idx - 1], y[j_idx - 1]);
            if (j_idx >= 2) s_value += mul(subband.fl[band][j_idx - 2], y[j_idx - 2]);
            if (j_idx >= 3) s_value += mul(subband.fl[band][j_idx - 3], y[j_idx - 3]);
            if (j_idx >= 4) s_value += mul(subband.fl[band][j_idx - 4], y[j_idx - 4]);
            if (j_idx >= 5) s_value += mul(subband.fl[band][j_idx - 5], y[j_idx - 5]);
            if (j_idx >= 6) s_value += mul(subband.fl[band][j_idx - 6], y[j_idx - 6]);
            if (j_idx >= 7) {
                s_value += mul(subband.fl[band][j_idx - 7], y[j_idx - 7]);
                j_idx -= 7;
            } else {
                break;
            }
        }
        s[band] = s_value;
    }
}

const testing = std.testing;

test "Subband initialization" {
    var subband = Subband{};
    subband.init();

    // Check that filter coefficients are initialized
    try testing.expect(subband.fl[0][0] != 0);
    try testing.expect(subband.fl[31][63] != 0);
}

test "Window filter subband" {
    var subband = Subband{};
    subband.init();

    var buffer_data = [_]i16{1000} ** 64;
    var buffer_pos: usize = 0;
    var s: [SUBBAND_LIMIT]i32 = undefined;

    windowFilterSubband(&subband, &s, 0, 1, &buffer_data, &buffer_pos);

    // Check that subband samples are produced
    var has_nonzero = false;
    for (s) |val| {
        if (val != 0) {
            has_nonzero = true;
            break;
        }
    }
    try testing.expect(has_nonzero);
}
