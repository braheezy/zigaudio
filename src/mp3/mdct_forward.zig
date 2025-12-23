const std = @import("std");
const math = std.math;

// Constants from Go implementation
const PI36: f64 = 0.087266462599717; // PI/36
const PI: f64 = 3.14159265358979;
const GRANULE_SIZE: usize = 576;
const MAX_CHANNELS: usize = 2;
const MAX_GRANULES: usize = 2;
const SUBBAND_LIMIT: usize = 32;

// Aliasing reduction coefficients (table B.9)
fn mdctCA(coefficient: f64) i32 {
    const denom = math.sqrt(1.0 + (coefficient * coefficient));
    const result = (coefficient / denom) * @as(f64, @floatFromInt(std.math.maxInt(i32)));
    return @intFromFloat(result);
}

fn mdctCS(coefficient: f64) i32 {
    const denom = math.sqrt(1.0 + (coefficient * coefficient));
    const result = (1.0 / denom) * @as(f64, @floatFromInt(std.math.maxInt(i32)));
    return @intFromFloat(result);
}

pub const MDCT_CA: [8]i32 = .{
    mdctCA(-0.6),
    mdctCA(-0.535),
    mdctCA(-0.33),
    mdctCA(-0.185),
    mdctCA(-0.095),
    mdctCA(-0.041),
    mdctCA(-0.0142),
    mdctCA(-0.0037),
};

pub const MDCT_CS: [8]i32 = .{
    mdctCS(-0.6),
    mdctCS(-0.535),
    mdctCS(-0.33),
    mdctCS(-0.185),
    mdctCS(-0.095),
    mdctCS(-0.041),
    mdctCS(-0.0142),
    mdctCS(-0.0037),
};

// MDCT structure for encoder
pub const MDCT = struct {
    // CosL coefficients: [18][36]i32
    cos_l: [18][36]i32 = undefined,

    pub fn init(self: *MDCT) void {
        // Prepare the MDCT coefficients
        // combine window and mdct coefficients into a single table
        var m: usize = 0;
        while (m < 18) : (m += 1) {
            var k: usize = 0;
            while (k < 36) : (k += 1) {
                const k_f = @as(f64, @floatFromInt(k));
                const m_f = @as(f64, @floatFromInt(m));
                const sin_val = math.sin(PI36 * (k_f + 0.5));
                const cos_val = math.cos((PI / 72.0) * (k_f * 2.0 + 19.0) * (m_f * 2.0 + 1.0));
                const result = sin_val * cos_val * @as(f64, @floatFromInt(std.math.maxInt(i32)));
                self.cos_l[m][k] = @intFromFloat(result);
            }
        }
    }
};

// Multiply two i32 values with proper scaling (fixed point arithmetic)
// Shifts right by 31 bits (not 32) for proper scaling
fn mul(a: i32, b: i32) i32 {
    const a_i64: i64 = @intCast(a);
    const b_i64: i64 = @intCast(b);
    const result: i64 = (a_i64 * b_i64) >> 32;
    return @intCast(result);
}

// Complex multiply for aliasing reduction
// Computes: (a + j*b) * (cs + j*ca) = (a*cs - b*ca) + j*(a*ca + b*cs)
fn cmuls(
    a: *i32,
    b: *i32,
    cs: *const i32,
    ca: *const i32,
) struct { i32, i32 } {
    const a_i64: i64 = @intCast(a.*);
    const b_i64: i64 = @intCast(b.*);
    const cs_i64: i64 = @intCast(cs.*);
    const ca_i64: i64 = @intCast(ca.*);

    const u: i64 = ((a_i64 * cs_i64 - b_i64 * ca_i64) >> 31);
    const v: i64 = ((a_i64 * ca_i64 + b_i64 * cs_i64) >> 31);

    return .{ @intCast(u), @intCast(v) };
}

/// Perform forward MDCT on subband samples
/// Input: subband_samples[gr][18][32] - subband samples for previous and current granule
/// Output: mdct_frequency[576] - MDCT frequency domain output
pub fn mdctForward(
    mdct: *const MDCT,
    subband_samples_prev: [18][SUBBAND_LIMIT]i32,
    subband_samples_curr: [18][SUBBAND_LIMIT]i32,
    mdct_frequency: *[GRANULE_SIZE]i32,
) void {
    var mdct_in: [36]i32 = undefined;

    // Perform MDCT for each subband
    var band: usize = 0;
    while (band < SUBBAND_LIMIT) : (band += 1) {
        // Combine 18 previous + 18 current samples
        var k: usize = 0;
        while (k < 18) : (k += 1) {
            mdct_in[k] = subband_samples_prev[k][band];
            mdct_in[k + 18] = subband_samples_curr[k][band];
        }

        // Calculate MDCT (36 time domain -> 18 frequency domain)
        var k_out: usize = 0;
        while (k_out < 18) : (k_out += 1) {
            var vm = mul(mdct_in[35], mdct.cos_l[k_out][35]);
            var j: usize = 35;
            while (j > 0) {
                if (j >= 1) vm += mul(mdct_in[j - 1], mdct.cos_l[k_out][j - 1]);
                if (j >= 2) vm += mul(mdct_in[j - 2], mdct.cos_l[k_out][j - 2]);
                if (j >= 3) vm += mul(mdct_in[j - 3], mdct.cos_l[k_out][j - 3]);
                if (j >= 4) vm += mul(mdct_in[j - 4], mdct.cos_l[k_out][j - 4]);
                if (j >= 5) vm += mul(mdct_in[j - 5], mdct.cos_l[k_out][j - 5]);
                if (j >= 6) vm += mul(mdct_in[j - 6], mdct.cos_l[k_out][j - 6]);
                if (j >= 7) {
                    vm += mul(mdct_in[j - 7], mdct.cos_l[k_out][j - 7]);
                    j -= 7;
                } else {
                    break;
                }
            }
            mdct_frequency[band * 18 + k_out] = vm;
        }

        // Perform aliasing reduction butterfly (except for first band)
        if (band > 0) {
            var i: usize = 0;
            while (i < 8) : (i += 1) {
                const idx1 = band * 18 + i;
                const idx2 = (band - 1) * 18 + (17 - i);
                const result = cmuls(
                    &mdct_frequency[idx1],
                    &mdct_frequency[idx2],
                    &MDCT_CS[i],
                    &MDCT_CA[i],
                );
                mdct_frequency[idx1] = result[0];
                mdct_frequency[idx2] = result[1];
            }
        }
    }
}

const testing = std.testing;

test "MDCT initialization" {
    var mdct = MDCT{};
    mdct.init();

    // Check that coefficients are initialized
    try testing.expect(mdct.cos_l[0][0] != 0);
    try testing.expect(mdct.cos_l[17][35] != 0);
}

test "MDCT forward transform" {
    var mdct = MDCT{};
    mdct.init();

    var subband_prev: [18][SUBBAND_LIMIT]i32 = undefined;
    var subband_curr: [18][SUBBAND_LIMIT]i32 = undefined;
    var mdct_freq: [GRANULE_SIZE]i32 = undefined;

    // Initialize with test data
    for (&subband_prev) |*row| {
        for (row) |*val| {
            val.* = 0;
        }
    }
    for (&subband_curr) |*row| {
        for (row) |*val| {
            val.* = 1000; // Simple test value
        }
    }

    mdctForward(&mdct, subband_prev, subband_curr, &mdct_freq);

    // Check that output is non-zero
    var has_nonzero = false;
    for (mdct_freq) |val| {
        if (val != 0) {
            has_nonzero = true;
            break;
        }
    }
    try testing.expect(has_nonzero);
}
