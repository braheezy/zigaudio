fn useMSStereo(h: frameheader.FrameHeader) bool {
    return h.mode() == .joint_stereo and ((h.modeExtension() >> 1) & 0x1) == 1;
}

fn useIntensityStereo(h: frameheader.FrameHeader) bool {
    return h.mode() == .joint_stereo and (h.modeExtension() & 0x1) == 1;
}

fn getSfBandIndicesArray(h: *const frameheader.FrameHeader) struct { long: []const u16, short: []const u16 } {
    const lsf_index: usize = @intFromBool(h.lowSamplingFrequency());
    const sfreq: usize = @intCast(h.samplingFrequency());
    const long_bands = mp3.sf_band_indices[lsf_index][sfreq][mp3.sf_band_indices_long][0..];
    const short_bands = mp3.sf_band_indices[lsf_index][sfreq][mp3.sf_band_indices_short][0..];
    return .{ .long = long_bands, .short = short_bands };
}

fn requantizeProcessLong(self: *Frame, gr: usize, ch: usize, is_pos: usize, sfb: usize) void {
    var sf_mult: f64 = 0.5;
    if (self.side_info.scalefac_scale[gr][ch] != 0) sf_mult = 1.0;
    const pf_x_pt: f64 = @as(f64, @floatFromInt(self.side_info.preflag[gr][ch])) * pretab[sfb];
    const idx: f64 = -(sf_mult * (@as(f64, @floatFromInt(self.main_data.scalefac_l[gr][ch][sfb])) + pf_x_pt)) +
        0.25 * (@as(f64, @floatFromInt(self.side_info.global_gain[gr][ch])) - 210.0);
    const tmp1: f64 = std.math.pow(f64, 2.0, idx);
    const v: f32 = self.main_data.is[gr][ch][is_pos];
    const a = @as(usize, @intFromFloat(@abs(v)));
    const p34 = getPowtab34();
    const tmp2: f64 = if (v < 0) -p34[a] else p34[a];
    self.main_data.is[gr][ch][is_pos] = @floatCast(tmp1 * tmp2);
}

fn requantizeProcessShort(self: *Frame, gr: usize, ch: usize, is_pos: usize, sfb: usize, win: usize) void {
    var sf_mult: f64 = 0.5;
    if (self.side_info.scalefac_scale[gr][ch] != 0) sf_mult = 1.0;
    const idx: f64 = -(sf_mult * @as(f64, @floatFromInt(self.main_data.scalefac_s[gr][ch][sfb][win]))) +
        0.25 * (@as(f64, @floatFromInt(self.side_info.global_gain[gr][ch])) - 210.0 -
            8.0 * @as(f64, @floatFromInt(self.side_info.subblock_gain[gr][ch][win])));
    const tmp1: f64 = std.math.pow(f64, 2.0, idx);
    const v: f32 = self.main_data.is[gr][ch][is_pos];
    const a = @as(usize, @intFromFloat(@abs(v)));
    const p34 = getPowtab34();
    const tmp2: f64 = if (v < 0) -p34[a] else p34[a];
    self.main_data.is[gr][ch][is_pos] = @floatCast(tmp1 * tmp2);
}

fn requantize(self: *Frame, gr: usize, ch: usize) void {
    const sfb = getSfBandIndicesArray(&self.header);
    if (self.side_info.win_switch_flag[gr][ch] == 1 and self.side_info.block_type[gr][ch] == 2) {
        if (self.side_info.mixed_block_flag[gr][ch] != 0) {
            var scalefac_band: usize = 0;
            var next_sfb = sfb.long[scalefac_band + 1];
            var i: usize = 0;
            while (i < 36) : (i += 1) {
                if (i == next_sfb) {
                    scalefac_band += 1;
                    next_sfb = sfb.long[scalefac_band + 1];
                }
                requantizeProcessLong(self, gr, ch, i, scalefac_band);
            }
            scalefac_band = 3;
            var next_sfb_s = sfb.short[scalefac_band + 1] * 3;
            var win_len: usize = sfb.short[scalefac_band + 1] - sfb.short[scalefac_band];
            var pos: usize = 36;
            while (pos < @as(usize, self.side_info.count1[gr][ch])) {
                if (pos == next_sfb_s) {
                    scalefac_band += 1;
                    next_sfb_s = sfb.short[scalefac_band + 1] * 3;
                    win_len = sfb.short[scalefac_band + 1] - sfb.short[scalefac_band];
                }
                var win: usize = 0;
                while (win < 3) : (win += 1) {
                    var j: usize = 0;
                    while (j < win_len) : (j += 1) {
                        requantizeProcessShort(self, gr, ch, pos, scalefac_band, win);
                        pos += 1;
                    }
                }
            }
        } else {
            var scalefac_band: usize = 0;
            var next_sfb_s = sfb.short[scalefac_band + 1] * 3;
            var win_len: usize = sfb.short[scalefac_band + 1] - sfb.short[scalefac_band];
            var pos: usize = 0;
            while (pos < @as(usize, self.side_info.count1[gr][ch])) {
                if (pos == next_sfb_s) {
                    scalefac_band += 1;
                    next_sfb_s = sfb.short[scalefac_band + 1] * 3;
                    win_len = sfb.short[scalefac_band + 1] - sfb.short[scalefac_band];
                }
                var win: usize = 0;
                while (win < 3) : (win += 1) {
                    var j: usize = 0;
                    while (j < win_len) : (j += 1) {
                        requantizeProcessShort(self, gr, ch, pos, scalefac_band, win);
                        pos += 1;
                    }
                }
            }
        }
    } else {
        var scalefac_band: usize = 0;
        var next_sfb = sfb.long[scalefac_band + 1];
        var i: usize = 0;
        while (i < @as(usize, self.side_info.count1[gr][ch])) : (i += 1) {
            if (i == next_sfb) {
                scalefac_band += 1;
                next_sfb = sfb.long[scalefac_band + 1];
            }
            requantizeProcessLong(self, gr, ch, i, scalefac_band);
        }
    }
}

fn reorder(self: *Frame, gr: usize, ch: usize) void {
    var re: [mp3.samples_per_granule]f32 = undefined;
    const sfb = getSfBandIndicesArray(&self.header);
    if (self.side_info.win_switch_flag[gr][ch] == 1 and self.side_info.block_type[gr][ch] == 2) {
        var scalefac_band: usize = 0;
        if (self.side_info.mixed_block_flag[gr][ch] != 0) scalefac_band = 3;
        var next_sfb = sfb.short[scalefac_band + 1] * 3;
        var win_len: usize = sfb.short[scalefac_band + 1] - sfb.short[scalefac_band];
        var i: usize = if (scalefac_band == 0) 0 else 36;
        while (i < mp3.samples_per_granule) {
            if (i == next_sfb) {
                const j = 3 * sfb.short[scalefac_band];
                for (0..3 * win_len) |k| self.main_data.is[gr][ch][j + k] = re[k];
                if (i >= self.side_info.count1[gr][ch]) return;
                scalefac_band += 1;
                next_sfb = sfb.short[scalefac_band + 1] * 3;
                win_len = sfb.short[scalefac_band + 1] - sfb.short[scalefac_band];
            }
            var win: usize = 0;
            while (win < 3) : (win += 1) {
                var j: usize = 0;
                while (j < win_len) : (j += 1) {
                    if (i >= mp3.samples_per_granule) break;
                    re[j * 3 + win] = self.main_data.is[gr][ch][i];
                    i += 1;
                }
            }
        }
        const j = 3 * sfb.short[12];
        for (0..3 * win_len) |k| self.main_data.is[gr][ch][j + k] = re[k];
    }
}

fn stereoProcessIntensityLong(self: *Frame, gr: usize, sfb_index: usize) void {
    var is_ratio_l: f32 = 0;
    var is_ratio_r: f32 = 0;
    const is_pos = self.main_data.scalefac_l[gr][0][sfb_index];
    if (is_pos < 7) {
        const bands = getSfBandIndicesArray(&self.header).long;
        const sfb_start = bands[sfb_index];
        const sfb_stop = bands[sfb_index + 1];
        if (is_pos == 6) {
            is_ratio_l = 1.0;
            is_ratio_r = 0.0;
        } else {
            const r = is_ratios[@as(usize, @intCast(is_pos))];
            is_ratio_l = r / (1.0 + r);
            is_ratio_r = 1.0 / (1.0 + r);
        }
        var i = sfb_start;
        while (i < sfb_stop) : (i += 1) {
            self.main_data.is[gr][0][i] *= is_ratio_l;
            self.main_data.is[gr][1][i] *= is_ratio_r;
        }
    }
}

fn stereoProcessIntensityShort(self: *Frame, gr: usize, sfb_index: usize) void {
    var is_ratio_l: f32 = 0;
    var is_ratio_r: f32 = 0;
    const bands = getSfBandIndicesArray(&self.header).short;
    const win_len = bands[sfb_index + 1] - bands[sfb_index];
    var win: usize = 0;
    while (win < 3) : (win += 1) {
        const is_pos = self.main_data.scalefac_s[gr][0][sfb_index][win];
        if (is_pos < 7) {
            const sfb_start = bands[sfb_index] * 3 + win_len * win;
            const sfb_stop = sfb_start + win_len;
            if (is_pos == 6) {
                is_ratio_l = 1.0;
                is_ratio_r = 0.0;
            } else {
                const r = is_ratios[@as(usize, @intCast(is_pos))];
                is_ratio_l = r / (1.0 + r);
                is_ratio_r = 1.0 / (1.0 + r);
            }
            var i = sfb_start;
            while (i < sfb_stop) : (i += 1) {
                self.main_data.is[gr][0][i] *= is_ratio_l;
                self.main_data.is[gr][1][i] *= is_ratio_r;
            }
        }
    }
}

const DEBUG_TRACE = false;
const DEBUG_DISABLE_STEREO = false;
const DEBUG_DISABLE_ANTIALIAS = false;
const DEBUG_DISABLE_FREQUENCY_INVERSION = false;

fn stereo(self: *Frame, gr: usize) void {
    if (DEBUG_DISABLE_STEREO) return;
    if (useMSStereo(self.header)) {
        var i_sel: usize = 1;
        if (self.side_info.count1[gr][0] > self.side_info.count1[gr][1]) i_sel = 0;
        const max_pos = @as(usize, self.side_info.count1[gr][i_sel]);
        const inv_sqrt2: f32 = @as(f32, std.math.sqrt2) / 2.0;
        var i: usize = 0;
        while (i < max_pos) : (i += 1) {
            const left = (self.main_data.is[gr][0][i] + self.main_data.is[gr][1][i]) * inv_sqrt2;
            const right = (self.main_data.is[gr][0][i] - self.main_data.is[gr][1][i]) * inv_sqrt2;
            self.main_data.is[gr][0][i] = left;
            self.main_data.is[gr][1][i] = right;
        }
    }
    if (useIntensityStereo(self.header)) {
        const sfb = getSfBandIndicesArray(&self.header);
        if (self.side_info.win_switch_flag[gr][0] == 1 and self.side_info.block_type[gr][0] == 2) {
            if (self.side_info.mixed_block_flag[gr][0] != 0) {
                var sfb_i: usize = 0;
                while (sfb_i < 8) : (sfb_i += 1) if (sfb.long[sfb_i] >= self.side_info.count1[gr][1]) stereoProcessIntensityLong(self, gr, sfb_i);
                var sfb_s: usize = 3;
                while (sfb_s < 12) : (sfb_s += 1) if (sfb.short[sfb_s] * 3 >= self.side_info.count1[gr][1]) stereoProcessIntensityShort(self, gr, sfb_s);
            } else {
                var sfb_s: usize = 0;
                while (sfb_s < 12) : (sfb_s += 1) if (sfb.short[sfb_s] * 3 >= self.side_info.count1[gr][1]) stereoProcessIntensityShort(self, gr, sfb_s);
            }
        } else {
            var sfb_l: usize = 0;
            while (sfb_l < 21) : (sfb_l += 1) if (sfb.long[sfb_l] >= self.side_info.count1[gr][1]) stereoProcessIntensityLong(self, gr, sfb_l);
        }
    }
}

fn antialias(self: *Frame, gr: usize, ch: usize) void {
    if (DEBUG_DISABLE_ANTIALIAS) return;
    if (self.side_info.win_switch_flag[gr][ch] == 1 and self.side_info.block_type[gr][ch] == 2 and self.side_info.mixed_block_flag[gr][ch] == 0) return;
    var sblim: usize = 32;
    if (self.side_info.win_switch_flag[gr][ch] == 1 and self.side_info.block_type[gr][ch] == 2 and self.side_info.mixed_block_flag[gr][ch] == 1) sblim = 2;
    var sb: usize = 1;
    while (sb < sblim) : (sb += 1) {
        for (0..8) |i| {
            const li = 18 * sb - 1 - i;
            const ui = 18 * sb + i;
            const lb = self.main_data.is[gr][ch][li] * cs[i] - self.main_data.is[gr][ch][ui] * ca[i];
            const ub = self.main_data.is[gr][ch][ui] * cs[i] + self.main_data.is[gr][ch][li] * ca[i];
            self.main_data.is[gr][ch][li] = lb;
            self.main_data.is[gr][ch][ui] = ub;
        }
    }
}

fn imdctWin(in: []const f32, block_type: usize) [36]f32 {
    var out: [36]f32 = .{0} ** 36;
    if (block_type == 2) {
        const iwd = imdct.win_data[block_type];
        const N: usize = 12;
        var i: usize = 0;
        while (i < 3) : (i += 1) {
            var p: usize = 0;
            while (p < N) : (p += 1) {
                var sum: f32 = 0.0;
                var m: usize = 0;
                while (m < N / 2) : (m += 1) sum += in[i + 3 * m] * imdct.cos_n12[m][p];
                out[6 * i + p + 6] += sum * iwd[p];
            }
        }
        return out;
    }
    const N: usize = 36;
    const iwd = imdct.win_data[block_type];
    var p: usize = 0;
    while (p < N) : (p += 1) {
        var sum: f32 = 0.0;
        var m: usize = 0;
        while (m < N / 2) : (m += 1) sum += in[m] * imdct.cos_n36[m][p];
        out[p] = sum * iwd[p];
    }
    return out;
}

fn hybridSynthesis(self: *Frame, gr: usize, ch: usize) void {
    var sb: usize = 0;
    while (sb < 32) : (sb += 1) {
        var bt = @as(usize, self.side_info.block_type[gr][ch]);
        if (self.side_info.win_switch_flag[gr][ch] == 1 and self.side_info.mixed_block_flag[gr][ch] == 1 and sb < 2) bt = 0;
        var input: [18]f32 = undefined;
        for (0..18) |i| input[i] = self.main_data.is[gr][ch][sb * 18 + i];
        const rawout = imdctWin(&input, bt);
        for (0..18) |i| {
            self.main_data.is[gr][ch][sb * 18 + i] = rawout[i] + self.store[ch][sb][i];
            self.store[ch][sb][i] = rawout[i + 18];
        }
    }
}

fn frequencyInversion(self: *Frame, gr: usize, ch: usize) void {
    if (DEBUG_DISABLE_FREQUENCY_INVERSION) return;
    var sb: usize = 1;
    while (sb < 32) : (sb += 2) {
        var i: usize = 1;
        while (i < 18) : (i += 2) self.main_data.is[gr][ch][sb * 18 + i] = -self.main_data.is[gr][ch][sb * 18 + i];
    }
}

fn subbandSynthesis(self: *Frame, gr: usize, ch: usize, out: []u8) void {
    var u_vec: [512]f32 = undefined;
    var s_vec: [32]f32 = undefined;
    const nch = self.header.numberOfChannels();
    var ss: usize = 0;
    while (ss < 18) : (ss += 1) {
        // Shift v_vec by 64 (copy v[0..960] to v[64..1024])
        std.mem.copyBackwards(f32, self.v_vec[ch][64..1024], self.v_vec[ch][0 .. 1024 - 64]);
        const d = self.main_data.is[gr][ch];
        for (0..32) |i| s_vec[i] = d[i * 18 + ss];
        for (0..64) |i| {
            var sum: f32 = 0;
            const snw = getSynthNWin();
            for (0..32) |j| sum += snw[i][j] * s_vec[j];
            self.v_vec[ch][i] = sum;
            if (DEBUG_TRACE and gr == 1 and ch == 1 and ss == 17 and i == 6) {
                std.debug.print("dbg target sum={d}\n", .{sum});
            }
        }
        const v = self.v_vec[ch];
        var idx: usize = 0;
        while (idx < 512) : (idx += 64) {
            for (0..32) |c| u_vec[idx + c] = v[(idx << 1) + c];
            for (0..32) |c| u_vec[idx + 32 + c] = v[(idx << 1) + 96 + c];
        }
        for (0..512) |i| u_vec[i] *= synthDtbl[i];
        for (0..32) |i| {
            var sum: f32 = 0;
            var j: usize = 0;
            while (j < 512) : (j += 32) sum += u_vec[j + i];
            var samp = @as(i32, @intFromFloat(sum * 32767.0));
            if (samp > 32767) samp = 32767 else if (samp < -32767) samp = -32767;
            const s: i16 = @intCast(samp);
            const base = 4 * (32 * ss + i);
            if (DEBUG_TRACE and gr == 1 and ch == 1 and ss == 17 and i == 6) {
                std.debug.print("dbg target pcm={d} sum={d}\n", .{ s, sum });
            }
            if (nch == 1) {
                const p0: *[2]u8 = @ptrCast(&out[base]);
                std.mem.writeInt(i16, p0, s, .little);
                const p1: *[2]u8 = @ptrCast(&out[base + 2]);
                std.mem.writeInt(i16, p1, s, .little);
            } else if (ch == 0) {
                const pL: *[2]u8 = @ptrCast(&out[base]);
                std.mem.writeInt(i16, pL, s, .little);
            } else {
                const pR: *[2]u8 = @ptrCast(&out[base + 2]);
                std.mem.writeInt(i16, pR, s, .little);
            }
        }
    }
}
const std = @import("std");
const bits = @import("bits.zig");
const frameheader = @import("frameheader.zig");
const sideinfo = @import("sideinfo.zig");
const maindata = @import("maindata.zig");
const imdct = @import("imdct.zig");
const mp3 = @import("../mp3.zig");

// Port of references/go-mp3/internal/frame/frame.go (Hajime Hoshi)

var powtab34_table: [8207]f64 = undefined;
var powtab34_inited: bool = false;
fn getPowtab34() *[8207]f64 {
    if (!powtab34_inited) {
        var i: usize = 0;
        while (i < powtab34_table.len) : (i += 1) {
            powtab34_table[i] = std.math.pow(f64, @as(f64, @floatFromInt(i)), 4.0 / 3.0);
        }
        powtab34_inited = true;
    }
    return &powtab34_table;
}

const pretab: [22]f64 = .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 3, 3, 3, 2, 0 };

const is_ratios: [6]f32 = .{ 0.000000, 0.267949, 0.577350, 1.000000, 1.732051, 3.732051 };
const cs: [8]f32 = .{ 0.857493, 0.881742, 0.949629, 0.983315, 0.995518, 0.999161, 0.999899, 0.999993 };
const ca: [8]f32 = .{ -0.514496, -0.471732, -0.313377, -0.181913, -0.094574, -0.040966, -0.014199, -0.003700 };

var synthNWin_table: [64][32]f32 = undefined;
var synthNWin_inited: bool = false;
fn getSynthNWin() *[64][32]f32 {
    if (!synthNWin_inited) {
        var i: usize = 0;
        while (i < 64) : (i += 1) {
            var j: usize = 0;
            while (j < 32) : (j += 1) {
                const angle: f64 = @as(f64, @floatFromInt((16 + @as(i32, @intCast(i))) * (2 * @as(i32, @intCast(j)) + 1))) * (std.math.pi / 64.0);
                synthNWin_table[i][j] = @floatCast(@cos(angle));
            }
        }
        synthNWin_inited = true;
    }
    return &synthNWin_table;
}

// Window table used by subband synthesis (from go-mp3)
const synthDtbl: [512]f32 = .{
    0.000000000,  -0.000015259, -0.000015259, -0.000015259,
    -0.000015259, -0.000015259, -0.000015259, -0.000030518,
    -0.000030518, -0.000030518, -0.000030518, -0.000045776,
    -0.000045776, -0.000061035, -0.000061035, -0.000076294,
    -0.000076294, -0.000091553, -0.000106812, -0.000106812,
    -0.000122070, -0.000137329, -0.000152588, -0.000167847,
    -0.000198364, -0.000213623, -0.000244141, -0.000259399,
    -0.000289917, -0.000320435, -0.000366211, -0.000396729,
    -0.000442505, -0.000473022, -0.000534058, -0.000579834,
    -0.000625610, -0.000686646, -0.000747681, -0.000808716,
    -0.000885010, -0.000961304, -0.001037598, -0.001113892,
    -0.001205444, -0.001296997, -0.001388550, -0.001480103,
    -0.001586914, -0.001693726, -0.001785278, -0.001907349,
    -0.002014160, -0.002120972, -0.002243042, -0.002349854,
    -0.002456665, -0.002578735, -0.002685547, -0.002792358,
    -0.002899170, -0.002990723, -0.003082275, -0.003173828,
    0.003250122,  0.003326416,  0.003387451,  0.003433228,
    0.003463745,  0.003479004,  0.003479004,  0.003463745,
    0.003417969,  0.003372192,  0.003280640,  0.003173828,
    0.003051758,  0.002883911,  0.002700806,  0.002487183,
    0.002227783,  0.001937866,  0.001617432,  0.001266479,
    0.000869751,  0.000442505,  -0.000030518, -0.000549316,
    -0.001098633, -0.001693726, -0.002334595, -0.003005981,
    -0.003723145, -0.004486084, -0.005294800, -0.006118774,
    -0.007003784, -0.007919312, -0.008865356, -0.009841919,
    -0.010848999, -0.011886597, -0.012939453, -0.014022827,
    -0.015121460, -0.016235352, -0.017349243, -0.018463135,
    -0.019577026, -0.020690918, -0.021789551, -0.022857666,
    -0.023910522, -0.024932861, -0.025909424, -0.026840210,
    -0.027725220, -0.028533936, -0.029281616, -0.029937744,
    -0.030532837, -0.031005859, -0.031387329, -0.031661987,
    -0.031814575, -0.031845093, -0.031738281, -0.031478882,
    0.031082153,  0.030517578,  0.029785156,  0.028884888,
    0.027801514,  0.026535034,  0.025085449,  0.023422241,
    0.021575928,  0.019531250,  0.017257690,  0.014801025,
    0.012115479,  0.009231567,  0.006134033,  0.002822876,
    -0.000686646, -0.004394531, -0.008316040, -0.012420654,
    -0.016708374, -0.021179199, -0.025817871, -0.030609131,
    -0.035552979, -0.040634155, -0.045837402, -0.051132202,
    -0.056533813, -0.061996460, -0.067520142, -0.073059082,
    -0.078628540, -0.084182739, -0.089706421, -0.095169067,
    -0.100540161, -0.105819702, -0.110946655, -0.115921021,
    -0.120697021, -0.125259399, -0.129562378, -0.133590698,
    -0.137298584, -0.140670776, -0.143676758, -0.146255493,
    -0.148422241, -0.150115967, -0.151306152, -0.151962280,
    -0.152069092, -0.151596069, -0.150497437, -0.148773193,
    -0.146362305, -0.143264771, -0.139450073, -0.134887695,
    -0.129577637, -0.123474121, -0.116577148, -0.108856201,
    0.100311279,  0.090927124,  0.080688477,  0.069595337,
    0.057617188,  0.044784546,  0.031082153,  0.016510010,
    0.001068115,  -0.015228271, -0.032379150, -0.050354004,
    -0.069168091, -0.088775635, -0.109161377, -0.130310059,
    -0.152206421, -0.174789429, -0.198059082, -0.221984863,
    -0.246505737, -0.271591187, -0.297210693, -0.323318481,
    -0.349868774, -0.376800537, -0.404083252, -0.431655884,
    -0.459472656, -0.487472534, -0.515609741, -0.543823242,
    -0.572036743, -0.600219727, -0.628295898, -0.656219482,
    -0.683914185, -0.711318970, -0.738372803, -0.765029907,
    -0.791213989, -0.816864014, -0.841949463, -0.866363525,
    -0.890090942, -0.913055420, -0.935195923, -0.956481934,
    -0.976852417, -0.996246338, -1.014617920, -1.031936646,
    -1.048156738, -1.063217163, -1.077117920, -1.089782715,
    -1.101211548, -1.111373901, -1.120223999, -1.127746582,
    -1.133926392, -1.138763428, -1.142211914, -1.144287109,
    1.144989014,  1.144287109,  1.142211914,  1.138763428,
    1.133926392,  1.127746582,  1.120223999,  1.111373901,
    1.101211548,  1.089782715,  1.077117920,  1.063217163,
    1.048156738,  1.031936646,  1.014617920,  0.996246338,
    0.976852417,  0.956481934,  0.935195923,  0.913055420,
    0.890090942,  0.866363525,  0.841949463,  0.816864014,
    0.791213989,  0.765029907,  0.738372803,  0.711318970,
    0.683914185,  0.656219482,  0.628295898,  0.600219727,
    0.572036743,  0.543823242,  0.515609741,  0.487472534,
    0.459472656,  0.431655884,  0.404083252,  0.376800537,
    0.349868774,  0.323318481,  0.297210693,  0.271591187,
    0.246505737,  0.221984863,  0.198059082,  0.174789429,
    0.152206421,  0.130310059,  0.109161377,  0.088775635,
    0.069168091,  0.050354004,  0.032379150,  0.015228271,
    -0.001068115, -0.016510010, -0.031082153, -0.044784546,
    -0.057617188, -0.069595337, -0.080688477, -0.090927124,
    0.100311279,  0.108856201,  0.116577148,  0.123474121,
    0.129577637,  0.134887695,  0.139450073,  0.143264771,
    0.146362305,  0.148773193,  0.150497437,  0.151596069,
    0.152069092,  0.151962280,  0.151306152,  0.150115967,
    0.148422241,  0.146255493,  0.143676758,  0.140670776,
    0.137298584,  0.133590698,  0.129562378,  0.125259399,
    0.120697021,  0.115921021,  0.110946655,  0.105819702,
    0.100540161,  0.095169067,  0.089706421,  0.084182739,
    0.078628540,  0.073059082,  0.067520142,  0.061996460,
    0.056533813,  0.051132202,  0.045837402,  0.040634155,
    0.035552979,  0.030609131,  0.025817871,  0.021179199,
    0.016708374,  0.012420654,  0.008316040,  0.004394531,
    0.000686646,  -0.002822876, -0.006134033, -0.009231567,
    -0.012115479, -0.014801025, -0.017257690, -0.019531250,
    -0.021575928, -0.023422241, -0.025085449, -0.026535034,
    -0.027801514, -0.028884888, -0.029785156, -0.030517578,
    0.031082153,  0.031478882,  0.031738281,  0.031845093,
    0.031814575,  0.031661987,  0.031387329,  0.031005859,
    0.030532837,  0.029937744,  0.029281616,  0.028533936,
    0.027725220,  0.026840210,  0.025909424,  0.024932861,
    0.023910522,  0.022857666,  0.021789551,  0.020690918,
    0.019577026,  0.018463135,  0.017349243,  0.016235352,
    0.015121460,  0.014022827,  0.012939453,  0.011886597,
    0.010848999,  0.009841919,  0.008865356,  0.007919312,
    0.007003784,  0.006118774,  0.005294800,  0.004486084,
    0.003723145,  0.003005981,  0.002334595,  0.001693726,
    0.001098633,  0.000549316,  0.000030518,  -0.000442505,
    -0.000869751, -0.001266479, -0.001617432, -0.001937866,
    -0.002227783, -0.002487183, -0.002700806, -0.002883911,
    -0.003051758, -0.003173828, -0.003280640, -0.003372192,
    -0.003417969, -0.003463745, -0.003479004, -0.003479004,
    -0.003463745, -0.003433228, -0.003387451, -0.003326416,
    0.003250122,  0.003173828,  0.003082275,  0.002990723,
    0.002899170,  0.002792358,  0.002685547,  0.002578735,
    0.002456665,  0.002349854,  0.002243042,  0.002120972,
    0.002014160,  0.001907349,  0.001785278,  0.001693726,
    0.001586914,  0.001480103,  0.001388550,  0.001296997,
    0.001205444,  0.001113892,  0.001037598,  0.000961304,
    0.000885010,  0.000808716,  0.000747681,  0.000686646,
    0.000625610,  0.000579834,  0.000534058,  0.000473022,
    0.000442505,  0.000396729,  0.000366211,  0.000320435,
    0.000289917,  0.000259399,  0.000244141,  0.000213623,
    0.000198364,  0.000167847,  0.000152588,  0.000137329,
    0.000122070,  0.000106812,  0.000106812,  0.000091553,
    0.000076294,  0.000076294,  0.000061035,  0.000061035,
    0.000045776,  0.000045776,  0.000030518,  0.000030518,
    0.000030518,  0.000030518,  0.000015259,  0.000015259,
    0.000015259,  0.000015259,  0.000015259,  0.000015259,
};

pub const Frame = struct {
    header: frameheader.FrameHeader,
    side_info: sideinfo.SideInfo,
    main_data: maindata.MainData,
    // Raw main data bits for reservoir; keep to feed next frame
    main_data_bits: bits.Bits,
    // Overlap-add storage and polyphase state
    store: [2][32][18]f32 = std.mem.zeroes([2][32][18]f32),
    v_vec: [2][1024]f32 = std.mem.zeroes([2][1024]f32),

    pub fn deinit(self: *Frame) void {
        self.main_data_bits.vec.deinit();
    }

    pub fn samplingFrequency(self: *Frame) !u32 {
        return self.header.samplingFrequencyValue() orelse return error.InvalidFormat;
    }

    // Fully synthesize this frame to interleaved stereo i16 PCM.
    pub fn decode(self: *Frame, allocator: std.mem.Allocator) ![]u8 {
        const nch = self.header.numberOfChannels();
        const out_len = 4 * mp3.samples_per_granule * @as(usize, self.header.granules());
        var out = try allocator.alloc(u8, out_len);

        var gr: usize = 0;
        while (gr < @as(usize, self.header.granules())) : (gr += 1) {
            var ch: usize = 0;
            while (ch < nch) : (ch += 1) {
                // Spectral domain processing
                requantize(self, gr, ch);
                reorder(self, gr, ch);
            }
            if (DEBUG_TRACE and gr == 0) {
                std.debug.print("trace: after reorder gr0 ch0 is[0..7]={any}\n", .{self.main_data.is[0][0][0..8]});
                if (nch == 2) std.debug.print("trace: after reorder gr0 ch1 is[0..7]={any}\n", .{self.main_data.is[0][1][0..8]});
            }
            // Stereo processing between channels
            stereo(self, gr);
            if (DEBUG_TRACE and gr == 0) {
                std.debug.print("trace: after stereo gr0 ch0 is[0..7]={any}\n", .{self.main_data.is[0][0][0..8]});
                if (nch == 2) std.debug.print("trace: after stereo gr0 ch1 is[0..7]={any}\n", .{self.main_data.is[0][1][0..8]});
            }
            ch = 0;
            while (ch < nch) : (ch += 1) {
                // Time domain processing and synthesis
                antialias(self, gr, ch);
                hybridSynthesis(self, gr, ch);
                if (DEBUG_TRACE and gr == 0 and ch == 0) {
                    // First subband time samples after hybrid
                    std.debug.print("trace: after hybrid gr0 ch0 sb0 is[0..7]={any}\n", .{self.main_data.is[0][0][0..8]});
                }
                frequencyInversion(self, gr, ch);
                subbandSynthesis(self, gr, ch, out[mp3.samples_per_granule * 4 * gr ..]);
            }
            if (DEBUG_TRACE and gr == 0) {
                // Print first 8 PCM samples (i16) of left and right
                var i: usize = 0;
                std.debug.print("trace: pcm L[0..7]=[", .{});
                while (i < 8) : (i += 1) {
                    const base = 4 * i;
                    const pL: *const [2]u8 = @ptrCast(&out[base]);
                    const sL = std.mem.readInt(i16, pL, .little);
                    std.debug.print("{d}{s}", .{ sL, if (i == 7) "]\n" else ", " });
                }
                i = 0;
                std.debug.print("trace: pcm R[0..7]=[", .{});
                while (i < 8) : (i += 1) {
                    const base = 4 * i;
                    const pR: *const [2]u8 = @ptrCast(&out[base + 2]);
                    const sR = std.mem.readInt(i16, pR, .little);
                    std.debug.print("{d}{s}", .{ sR, if (i == 7) "]\n" else ", " });
                }
            }
        }
        return out;
    }
};

pub fn decodeFrame(
    allocator: std.mem.Allocator,
    reader: *std.Io.Reader,
    prev_main: ?*bits.Bits,
) !Frame {
    // Parse header and advance
    const hdr_res = try frameheader.readFrameHeader(reader);
    var header = hdr_res.header;
    _ = try reader.take(4);

    if (header.version() == .v2_5) return error.InvalidFormat;
    if (header.layer() != .v3) return error.InvalidFormat;

    // CRC (2 bytes) if present
    if (header.protectionBit() == 0) {
        var crc_buf: [2]u8 = undefined;
        try reader.readSliceAll(&crc_buf);
    }

    // Read side information
    var si = try sideinfo.readAll(allocator, reader, header);

    // Decode main data (this assembles reservoir internally like Go)
    const res = try maindata.readFull(allocator, reader, prev_main, header, &si);

    return .{
        .header = header,
        .side_info = si,
        .main_data = res.main_data,
        .main_data_bits = res.bits,
    };
}
