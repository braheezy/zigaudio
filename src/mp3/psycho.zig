const std = @import("std");
const math = std.math;
const tables = @import("tables.zig");

const GRANULE_SIZE: usize = 576;
const MAX_CHANNELS: usize = 2;
const MAX_GRANULES: usize = 2;
const SCALE_FACTOR_BAND_L_MAX: usize = 22;
const PSY_BAND_MAX: usize = 21;

const psycho_energy_floor: f64 = 1e-9;
const tonal_mask_constant: f64 = 0.158;
const noise_mask_constant: f64 = 0.0631;
pub const psychoEnergyFloor: f64 = psycho_energy_floor;


pub const PsyRatio = struct {
    l: [MAX_GRANULES][MAX_CHANNELS][PSY_BAND_MAX]f64,
};

pub const PsyXMin = struct {
    l: [MAX_GRANULES][MAX_CHANNELS][PSY_BAND_MAX]f64,
};

pub const ScaleFactor = struct {
    l: [MAX_GRANULES][MAX_CHANNELS][SCALE_FACTOR_BAND_L_MAX]i32,
    s: [MAX_GRANULES][MAX_CHANNELS][13][3]i32,
};

pub fn updatePsychoModel(
    ratio: *PsyRatio,
    scale_factor: *ScaleFactor,
    perceptual_energy: *[MAX_CHANNELS][MAX_GRANULES]f64,
    mdct_frequency: [MAX_CHANNELS][MAX_GRANULES][GRANULE_SIZE]i32,
    sample_rate_index: u8,
    sample_rate: u32,
    channels: u8,
    granules_per_frame: u8,
) void {
    const band_layout = tables.scale_factor_band_index[@as(usize, sample_rate_index)];
    var band_limit: usize = band_layout.len - 1;
    if (band_limit > PSY_BAND_MAX) {
        band_limit = PSY_BAND_MAX;
    }

    const sample_rate_f = @as(f64, @floatFromInt(sample_rate));
    var band_bark: [SCALE_FACTOR_BAND_L_MAX]f64 = undefined;
    var band_center: [SCALE_FACTOR_BAND_L_MAX]f64 = undefined;

    var band: usize = 0;
    while (band < band_limit) : (band += 1) {
        const start = @as(usize, band_layout[band]);
        const end = @as(usize, band_layout[band + 1]);
        band_center[band] = bandCenterFrequency(sample_rate_f, start, end);
        band_bark[band] = hzToBark(band_center[band]);
    }

    var ch_idx: usize = 0;
    while (ch_idx < @as(usize, channels)) : (ch_idx += 1) {
        var gr_idx: usize = 0;
        while (gr_idx < @as(usize, granules_per_frame)) : (gr_idx += 1) {
            var band_energy: [SCALE_FACTOR_BAND_L_MAX]f64 = undefined;
            var tonality: [SCALE_FACTOR_BAND_L_MAX]f64 = undefined;
            var masking: [SCALE_FACTOR_BAND_L_MAX]f64 = undefined;

            const spectrum = mdct_frequency[ch_idx][gr_idx];

            band = 0;
            while (band < band_limit) : (band += 1) {
                const start = @as(usize, band_layout[band]);
                var end = @as(usize, band_layout[band + 1]);
                if (end > spectrum.len) {
                    end = spectrum.len;
                }
                const result = analyzeBand(spectrum[start..end]);
                band_energy[band] = result.energy;
                tonality[band] = result.tonality;
            }

            band = 0;
            while (band < band_limit) : (band += 1) {
                var sum: f64 = 0.0;
                var other: usize = 0;
                while (other < band_limit) : (other += 1) {
                    const delta = band_bark[other] - band_bark[band];
                    const weight = spreadingFunction(delta);
                    sum += band_energy[other] * weight;
                }

                const tonal_mask = sum * tonal_mask_constant;
                const noise_mask = sum * noise_mask_constant;
                var mask = tonality[band] * tonal_mask + (1.0 - tonality[band]) * noise_mask;
                const ath = athEnergy(band_center[band]);
                if (mask < ath) {
                    mask = ath;
                }
                masking[band] = mask;
            }

            var pe: f64 = 0.0;
            band = 0;
            while (band < band_limit) : (band += 1) {
                var mask = masking[band];
                const energy = band_energy[band];
                if (mask < psycho_energy_floor) {
                    mask = psycho_energy_floor;
                }
                ratio.l[gr_idx][ch_idx][band] = mask;
                const smr = energy / mask;
                if (smr > 1.0) {
                    pe += math.log2(smr);
                }
                scale_factor.l[gr_idx][ch_idx][band] = encodeScaleFactorFromSMR(smr);
            }

            band = band_limit;
            while (band < SCALE_FACTOR_BAND_L_MAX) : (band += 1) {
                resetBandPsyData(ratio, scale_factor, gr_idx, ch_idx, band);
            }
            perceptual_energy[ch_idx][gr_idx] = pe;

        }
    }
}

fn analyzeBand(samples: []const i32) struct { energy: f64, tonality: f64 } {
    if (samples.len == 0) {
        return .{ .energy = psycho_energy_floor, .tonality = 0.0 };
    }

    var energy: f64 = 0.0;
    var log_sum: f64 = 0.0;
    var abs_sum: f64 = 0.0;

    for (samples) |sample| {
        const v = @as(f64, @floatFromInt(sample));
        const abs = (if (v < 0.0) -v else v) + psycho_energy_floor;
        energy += v * v;
        abs_sum += abs;
                log_sum += math.log(f64, math.e, abs);
    }

    const mean_abs = abs_sum / @as(f64, @floatFromInt(samples.len));
    const geom_mean = math.exp(log_sum / @as(f64, @floatFromInt(samples.len)));
    var sfm = geom_mean / (mean_abs + psycho_energy_floor);
    if (sfm < 0.0) {
        sfm = 0.0;
    } else if (sfm > 1.0) {
        sfm = 1.0;
    }
    const tonality = 1.0 - sfm;
    return .{ .energy = energy + psycho_energy_floor, .tonality = tonality };
}

fn bandCenterFrequency(sample_rate: f64, start: usize, end: usize) f64 {
    const end_pos = if (end <= start) start + 1 else end;
    const bin = (@as(f64, @floatFromInt(start)) + @as(f64, @floatFromInt(end_pos))) / 2.0;
    const freq_step = sample_rate / (2.0 * @as(f64, @floatFromInt(GRANULE_SIZE)));
    return bin * freq_step;
}

fn hzToBark(freq: f64) f64 {
    const f = freq / 1000.0;
    return 13.0 * math.atan(0.00076 * freq) + 3.5 * math.atan(math.pow(f64, f / 7.5, 2.0));
}

fn spreadingFunction(delta_bark: f64) f64 {
    if (delta_bark >= 0.0) {
        return math.pow(f64, 10.0, -1.5 * delta_bark);
    }
    return math.pow(f64, 10.0, 0.5 * delta_bark);
}

fn athEnergy(freq: f64) f64 {
    if (freq <= 0.0) {
        return psycho_energy_floor;
    }
    const f = freq / 1000.0;
    const ath_db = 3.64 * math.pow(f64, f, -0.8) - 6.5 * math.exp(-0.6 * math.pow(f64, f - 3.3, 2.0)) + 0.001 * math.pow(f64, f, 4.0);
    const linear = psycho_energy_floor * math.pow(f64, 10.0, ath_db / 10.0);
    return if (linear < psycho_energy_floor) psycho_energy_floor else linear;
}

fn resetBandPsyData(
    ratio: *PsyRatio,
    scale_factor: *ScaleFactor,
    gr_idx: usize,
    ch_idx: usize,
    band: usize,
) void {
    if (band < PSY_BAND_MAX) {
        ratio.l[gr_idx][ch_idx][band] = psycho_energy_floor;
    }
    scale_factor.l[gr_idx][ch_idx][band] = 0;
}

fn encodeScaleFactorFromSMR(smr: f64) i32 {
    if (smr <= 1.0) return 0;
    const db = 10.0 * math.log10(smr);
    const sf_raw: i32 = @intFromFloat(db / 1.5);
    return @max(0, @min(63, sf_raw));
}
