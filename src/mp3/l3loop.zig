const std = @import("std");
const math = std.math;
const psycho = @import("psycho.zig");
const sideinfo = @import("sideinfo.zig");
const reservoir_mod = @import("reservoir.zig");
const huffman_encode = @import("huffman_encode.zig");
const mp3_tables = @import("tables.zig");
const EncoderGranuleInfo = sideinfo.EncoderGranuleInfo;

const GRANULE_SIZE: usize = 576;
const MAX_CHANNELS: usize = 2;
const MAX_GRANULES: usize = 2;
const SCALE_FACTOR_BAND_L_MAX: usize = 22;
const LN2: f64 = 0.69314718;
const EN_TOT_KRIT: i64 = 10;
const EN_DIF_KRIT: i64 = 100;
const EN_SCFI_BAND_KRIT: i64 = 10;
const XM_SCFI_BAND_KRIT: i64 = 10;
const SCFSI_BAND_LONG: [5]usize = .{ 0, 6, 11, 16, 21 };

pub const sLen1Table: [16]u64 = .{
    0, 0, 0, 0, 3, 1, 1, 1,
    2, 2, 2, 3, 3, 3, 4, 4,
};

pub const sLen2Table: [16]u64 = .{
    0, 1, 2, 3, 0, 1, 2, 3,
    1, 2, 3, 1, 2, 3, 2, 3,
};

pub const L3Loop = struct {
    xr: []const i32,
    xrsq: [GRANULE_SIZE]i32,
    xrabs: [GRANULE_SIZE]i32,
    xrmax: i32,
    en_tot: [MAX_GRANULES]i32,
    en: [MAX_GRANULES][SCALE_FACTOR_BAND_L_MAX]i32,
    xm: [MAX_GRANULES][SCALE_FACTOR_BAND_L_MAX]i32,
    xrmaxl: [MAX_GRANULES]i32,
    step_table: [128]f64,
    step_table_i: [128]i32,
    int2idx: [10000]i64,
};

pub fn initL3Loop(loop: *L3Loop) void {
    loopInitialize(loop);
}

pub fn loopInitialize(loop: *L3Loop) void {
    var i: u32 = 127;
    const max_int = @as(f64, std.math.maxInt(i32));
    while (true) {
        const index = @as(usize, i);
        const numerator = @as(f64, @floatFromInt(@as(i64, 127))) - @as(f64, @floatFromInt(@as(i64, i)));
        const exponent = numerator / 4.0;
        const power = math.pow(f64, 2.0, exponent);
        loop.step_table[index] = power;
        const scaled = power * 2.0;
        if (scaled > max_int) {
            loop.step_table_i[index] = std.math.maxInt(i32);
        } else {
            loop.step_table_i[index] = @intFromFloat(scaled + 0.5);
        }
        if (i == 0) break;
        i -= 1;
    }

    var j: u32 = 9999;
    while (true) {
        const idx = @as(usize, j);
        const jf = @as(f64, @floatFromInt(@as(i64, j)));
        const value = math.sqrt(math.sqrt(jf) * jf) - 0.0946 + 0.5;
        loop.int2idx[idx] = @intFromFloat(value);
        if (j == 0) break;
        j -= 1;
    }
}

const CalcRunLengthInfo = struct {
    big_values: *u64,
    count1: *u64,
};

pub fn quantize(ix: *[GRANULE_SIZE]i64, step_size: i64, loop: *const L3Loop) i64 {
    var ix_max: i64 = 0;
    const max_int8 = @as(i64, std.math.maxInt(i8));
    const desired_index = step_size + max_int8;
    var clamped_index = desired_index;
    if (clamped_index < 0) {
        clamped_index = 0;
    } else if (clamped_index > 127) {
        clamped_index = 127;
    }
    const index: usize = @intCast(clamped_index);
    const scale_i = loop.step_table_i[index];

    if (mulR(loop.xrmax, scale_i) > 165140) {
        return 16384;
    }

    const scale_f = loop.step_table[index];
    var i: usize = 0;
    while (i < GRANULE_SIZE) : (i += 1) {
        const xr_val = loop.xr[i];
        const abs_val = if (xr_val < 0) -xr_val else xr_val;
        const ln = mulR(@as(i32, abs_val), scale_i);

        if (ln < 10000) {
            const ln_idx: usize = @intCast(ln);
            ix[i] = loop.int2idx[ln_idx];
        } else {
            const dbl_value: f64 = @floatFromInt(loop.xrabs[i]);
            const dbl = dbl_value * scale_f * 4.656612875e-10;
            const scaled = math.sqrt(math.sqrt(dbl) * dbl);
            const scaled_i64: i64 = @intFromFloat(scaled);
            ix[i] = scaled_i64;
        }

        if (ix_max < ix[i]) {
            ix_max = ix[i];
        }
    }

    return ix_max;
}

fn mulR(a: i32, b: i32) i32 {
    const a_i64: i64 = @intCast(a);
    const b_i64: i64 = @intCast(b);
    const product = a_i64 * b_i64 + 0x80000000;
    return @intCast(product >> 32);
}

fn mulSR(a: i32, b: i32) i32 {
    const product = @as(i64, a) * @as(i64, b) + 0x40000000;
    return @intCast(product >> 31);
}

pub fn calcRunLength(ix: *[GRANULE_SIZE]i64, gran_info: *CalcRunLengthInfo) void {
    var i: usize = GRANULE_SIZE;
    while (i > 1) {
        const idx0 = i - 1;
        const idx1 = i - 2;
        if (ix[idx0] == 0 and ix[idx1] == 0) {
            i -= 2;
            continue;
        }
        break;
    }

    var count1_count: u64 = 0;
    while (i > 3) {
        const idx_v = i - 1;
        const idx_w = i - 2;
        const idx_x = i - 3;
        const idx_y = i - 4;
        const v = ix[idx_v];
        const w = ix[idx_w];
        const x = ix[idx_x];
        const y = ix[idx_y];
        if (v >= -1 and v <= 1 and w >= -1 and w <= 1 and x >= -1 and x <= 1 and y >= -1 and y <= 1) {
            count1_count += 1;
            i -= 4;
        } else {
            break;
        }
    }

    gran_info.big_values.* = @as(u64, i >> 1);
    gran_info.count1.* = count1_count;
}

const SubdivideEntry = struct {
    region0_count: u64,
    region1_count: u64,
};

const subdivideTable: [23]SubdivideEntry = .{
    .{ .region0_count = 0, .region1_count = 0 },
    .{ .region0_count = 0, .region1_count = 0 },
    .{ .region0_count = 0, .region1_count = 0 },
    .{ .region0_count = 0, .region1_count = 0 },
    .{ .region0_count = 0, .region1_count = 0 },
    .{ .region0_count = 0, .region1_count = 1 },
    .{ .region0_count = 1, .region1_count = 1 },
    .{ .region0_count = 1, .region1_count = 1 },
    .{ .region0_count = 1, .region1_count = 2 },
    .{ .region0_count = 2, .region1_count = 2 },
    .{ .region0_count = 2, .region1_count = 3 },
    .{ .region0_count = 2, .region1_count = 3 },
    .{ .region0_count = 3, .region1_count = 4 },
    .{ .region0_count = 3, .region1_count = 4 },
    .{ .region0_count = 3, .region1_count = 4 },
    .{ .region0_count = 4, .region1_count = 5 },
    .{ .region0_count = 4, .region1_count = 5 },
    .{ .region0_count = 4, .region1_count = 6 },
    .{ .region0_count = 5, .region1_count = 6 },
    .{ .region0_count = 5, .region1_count = 6 },
    .{ .region0_count = 5, .region1_count = 7 },
    .{ .region0_count = 6, .region1_count = 7 },
    .{ .region0_count = 6, .region1_count = 7 },
};

fn subDivide(
    gran_info: *EncoderGranuleInfo,
    scale_factor_band_index: []const u16,
) void {
    const big_values = gran_info.big_values;
    if (big_values == 0) {
        gran_info.region0_count = 0;
        gran_info.region1_count = 0;
        return;
    }

    const bigvalues_region = big_values << 1;
    const bigvalues_region_u16: u16 = @truncate(bigvalues_region);

    var scalefac_band_index = scale_factor_band_index;
    var scfb_anz: usize = 0;
    while (scfb_anz < scalefac_band_index.len and scalefac_band_index[scfb_anz] < bigvalues_region_u16) : (scfb_anz += 1) {}
    const table_entry = subdivideTable[scfb_anz];

    var thiscount: i64 = @intCast(table_entry.region0_count);
    while (thiscount != 0) {
        if (scalefac_band_index[@as(usize, @intCast(thiscount + 1))] <= bigvalues_region_u16) {
            break;
        }
        thiscount -= 1;
    }

    gran_info.region0_count = @intCast(thiscount);
    gran_info.address1 = @intCast(scalefac_band_index[@as(usize, @intCast(thiscount + 1))]);

    scalefac_band_index = scalefac_band_index[@as(usize, @intCast(gran_info.region0_count + 1))..];

    var thiscount1: i64 = @intCast(table_entry.region1_count);
    while (thiscount1 != 0) {
        if (scalefac_band_index[@as(usize, @intCast(thiscount1 + 1))] <= bigvalues_region_u16) {
            break;
        }
        thiscount1 -= 1;
    }

    gran_info.region1_count = @intCast(thiscount1);
    gran_info.address2 = @intCast(scalefac_band_index[@as(usize, @intCast(thiscount1 + 1))]);
    gran_info.address3 = bigvalues_region;
}

fn countBit(ix: *[GRANULE_SIZE]i64, start: u64, end: u64, table: u64) i64 {
    if (table == 0) return 0;
    const table_idx: usize = @intCast(table);
    const h = huffman_encode.huffmanCodeTable[table_idx];
    const hLen = h.hLen orelse return 0;
    const hLenArr = @as([*]const u8, @ptrCast(hLen));

    var sum: i64 = 0;
    const y_len_val = @as(usize, h.y_len);
    const lin_bits: i64 = @intCast(h.lin_bits);

    if (table > 15) {
        var i: u64 = start;
        while (i < end) : (i += 2) {
            const idx_x: usize = @intCast(i);
            var x = ix[idx_x];
            const idx_y: usize = @intCast(i + 1);
            var y = ix[idx_y];
            if (x > 14) {
                x = 15;
                sum += lin_bits;
            }
            if (y > 14) {
                y = 15;
                sum += lin_bits;
            }
            const pos = @as(usize, @intCast(x)) * y_len_val + @as(usize, @intCast(y));
            sum += @intCast(hLenArr[pos]);
            if (x != 0) sum += 1;
            if (y != 0) sum += 1;
        }
    } else {
        var i: u64 = start;
        while (i < end) : (i += 2) {
            const idx_x: usize = @intCast(i);
            const x = ix[idx_x];
            const idx_y: usize = @intCast(i + 1);
            const y = ix[idx_y];
            const pos = @as(usize, @intCast(x)) * y_len_val + @as(usize, @intCast(y));
            sum += @as(i64, hLenArr[pos]);
            if (x != 0) sum += 1;
            if (y != 0) sum += 1;
        }
    }
    return sum;
}

fn count1BitCount(
    ix: *[GRANULE_SIZE]i64,
    big_values: u64,
    count1: u64,
    count1_table_select: ?*u64,
) i64 {
    var sum0: i64 = 0;
    var sum1: i64 = 0;
    var idx: u64 = big_values << 1;

    const h32 = huffman_encode.huffmanCodeTable[32];
    const h33 = huffman_encode.huffmanCodeTable[33];
    const h32Len = h32.hLen orelse return 0;
    const h33Len = h33.hLen orelse return 0;
    const h32LenArr = @as([*]const u8, @ptrCast(h32Len));
    const h33LenArr = @as([*]const u8, @ptrCast(h33Len));

    var k: u64 = 0;
    while (k < count1) : (k += 1) {
        const base = @as(usize, idx);
        const v = ix[base];
        const w = ix[base + 1];
        const x = ix[base + 2];
        const y = ix[base + 3];
        idx += 4;

        var sign_bits: i64 = 0;
        if (v != 0) sign_bits += 1;
        if (w != 0) sign_bits += 1;
        if (x != 0) sign_bits += 1;
        if (y != 0) sign_bits += 1;

        const sum = v + (w << 1) + (x << 2) + (y << 3);
        const p = if (sum >= 0) @as(usize, @intCast(sum)) else 0;
        sum0 += sign_bits + @as(i64, h32LenArr[p]);
        sum1 += sign_bits + @as(i64, h33LenArr[p]);
    }

    const use_sum0 = sum0 < sum1;
    if (count1_table_select) |ptr| ptr.* = if (use_sum0) 0 else 1;
    return if (use_sum0) sum0 else sum1;
}

fn bigValuesBitCount(
    ix: *[GRANULE_SIZE]i64,
    gran_info: *EncoderGranuleInfo,
) i64 {
    var bits: i64 = 0;
    const tables = gran_info.table_select;

    const t0 = tables[0];
    if (t0 != 0) {
        bits += countBit(ix, 0, gran_info.address1, t0);
    }
    const t1 = tables[1];
    if (t1 != 0) {
        bits += countBit(ix, gran_info.address1, gran_info.address2, t1);
    }
    const t2 = tables[2];
    if (t2 != 0) {
        bits += countBit(ix, gran_info.address2, gran_info.address3, t2);
    }
    return bits;
}

fn ixMax(ix: *[GRANULE_SIZE]i64, begin: u64, end: u64) i64 {
    var max: i64 = 0;
    var i: u64 = begin;
    while (i < end) : (i += 1) {
        const idx: usize = @intCast(i);
        const value = ix[idx];
        if (value > max) {
            max = value;
        }
    }
    return max;
}

fn newChooseTable(ix: *[GRANULE_SIZE]i64, begin: u64, end: u64) i64 {
    var choice: [2]i64 = .{ 0, 0 };
    var sum: [2]i64 = .{ 0, 0 };
    const max = ixMax(ix, begin, end);
    const max_u64: u64 = if (max >= 0) @intCast(max) else 0;
    if (max == 0) {
        return 0;
    }

    if (max < 15) {
        var i: i64 = 13;
        while (i >= 0) : (i -= 1) {
            if (huffman_encode.huffmanCodeTable[@as(usize, @intCast(i))].x_len > max_u64) {
                choice[0] = i;
                break;
            }
        }
        sum[0] = countBit(ix, begin, end, @intCast(choice[0]));
        switch (choice[0]) {
            2 => {
                sum[1] = countBit(ix, begin, end, 3);
                if (sum[1] <= sum[0]) {
                    choice[0] = 3;
                }
            },
            5 => {
                sum[1] = countBit(ix, begin, end, 6);
                if (sum[1] <= sum[0]) {
                    choice[0] = 6;
                }
            },
            7 => {
                sum[1] = countBit(ix, begin, end, 8);
                if (sum[1] <= sum[0]) {
                    choice[0] = 8;
                    sum[0] = sum[1];
                }
                sum[1] = countBit(ix, begin, end, 9);
                if (sum[1] <= sum[0]) {
                    choice[0] = 9;
                }
            },
            10 => {
                sum[1] = countBit(ix, begin, end, 11);
                if (sum[1] <= sum[0]) {
                    choice[0] = 11;
                    sum[0] = sum[1];
                }
                sum[1] = countBit(ix, begin, end, 12);
                if (sum[1] <= sum[0]) {
                    choice[0] = 12;
                }
            },
            13 => {
                sum[1] = countBit(ix, begin, end, 15);
                if (sum[1] <= sum[0]) {
                    choice[0] = 15;
                }
            },
            else => {},
        }
    } else {
        const max_lin = max - 15;
        var i: usize = 15;
        while (i < 24) : (i += 1) {
            if (huffman_encode.huffmanCodeTable[i].lin_max >= @as(u64, @intCast(max_lin))) {
                choice[0] = @intCast(i);
                break;
            }
        }
        i = 24;
        while (i < 32) : (i += 1) {
            if (huffman_encode.huffmanCodeTable[i].lin_max >= @as(u64, @intCast(max_lin))) {
                choice[1] = @intCast(i);
                break;
            }
        }
        sum[0] = countBit(ix, begin, end, @intCast(choice[0]));
        sum[1] = countBit(ix, begin, end, @intCast(choice[1]));
        if (sum[1] < sum[0]) {
            choice[0] = choice[1];
        }
    }

    return choice[0];
}

pub fn bigValuesTableSelect(
    ix: *[GRANULE_SIZE]i64,
    gran_info: *EncoderGranuleInfo,
) void {
    gran_info.table_select[0] = 0;
    gran_info.table_select[1] = 0;
    gran_info.table_select[2] = 0;

    if (gran_info.address1 > 0) {
        const table_value = newChooseTable(ix, 0, gran_info.address1);
        gran_info.table_select[0] = @intCast(if (table_value >= 0) table_value else 0);
    }
    if (gran_info.address2 > gran_info.address1) {
        const table_value = newChooseTable(ix, gran_info.address1, gran_info.address2);
        gran_info.table_select[1] = @intCast(if (table_value >= 0) table_value else 0);
    }
    const big_values_region = gran_info.big_values << 1;
    if (big_values_region > gran_info.address2) {
        const table_value = newChooseTable(ix, gran_info.address2, big_values_region);
        gran_info.table_select[2] = @intCast(if (table_value >= 0) table_value else 0);
    }
}

pub fn innerLoop(
    ix: *[GRANULE_SIZE]i64,
    max_bits: i64,
    gran_info: *EncoderGranuleInfo,
    loop: *const L3Loop,
    scale_factor_band_index: []const u16,
) i64 {
    var bits: i64 = 0;

    if (max_bits < 0) {
        gran_info.quantizer_step_size -= 1;
    }

    while (true) {
        gran_info.quantizer_step_size += 1;

        const max_val = quantize(ix, gran_info.quantizer_step_size, loop);
        if (max_val > 8192) {
            continue;
        }

        var run_length_info = CalcRunLengthInfo{
            .big_values = &gran_info.big_values,
            .count1 = &gran_info.count1,
        };
        calcRunLength(ix, &run_length_info);

        bits = count1BitCount(
            ix,
            gran_info.big_values,
            gran_info.count1,
            &gran_info.count1_table_select,
        );

        subDivide(gran_info, scale_factor_band_index);
        bigValuesTableSelect(ix, gran_info);
        bits += bigValuesBitCount(ix, gran_info);

        if (bits <= max_bits) {
            break;
        }
    }

    return bits;
}

pub fn outerLoop(
    max_bits: i64,
    _: *const psycho.PsyXMin,
    ix: *[GRANULE_SIZE]i64,
    gr: usize,
    ch: usize,
    gran_info: *EncoderGranuleInfo,
    loop: *const L3Loop,
    scale_factor_band_index: []const u16,
    scale_factor_compress: u64,
    scale_factor_select_info: [4]u64,
) void {
    std.debug.assert(ch < MAX_CHANNELS);
    gran_info.quantizer_step_size = binSearchStepSize(
        ix,
        max_bits,
        gran_info,
        loop,
        scale_factor_band_index,
    );

    gran_info.part2_length = @as(u64, calcPart2Length(
        scale_factor_compress,
        gr,
        scale_factor_select_info,
    ));

    const part2_length_i64: i64 = @intCast(gran_info.part2_length);
    const huff_bits = max_bits - part2_length_i64;
    const bits = innerLoop(ix, huff_bits, gran_info, loop, scale_factor_band_index);
    gran_info.part2_3_length = gran_info.part2_length + @as(u64, @intCast(bits));
}

pub fn calcPart2Length(
    scale_factor_compress: u64,
    gr: usize,
    scale_factor_select_info: [4]u64,
) u64 {
    const compress_idx: usize = if (scale_factor_compress < @as(u64, sLen1Table.len)) @as(usize, scale_factor_compress) else sLen1Table.len - 1;
    const s_len1 = sLen1Table[compress_idx];
    const s_len2 = sLen2Table[compress_idx];

    var bits: u64 = 0;
    if (gr == 0 or scale_factor_select_info[0] == 0) {
        var band: usize = 0;
        while (band < 6) : (band += 1) {
            bits += s_len1;
        }
    }
    if (gr == 0 or scale_factor_select_info[1] == 0) {
        var band: usize = 6;
        while (band < 11) : (band += 1) {
            bits += s_len1;
        }
    }
    if (gr == 0 or scale_factor_select_info[2] == 0) {
        var band: usize = 11;
        while (band < 16) : (band += 1) {
            bits += s_len2;
        }
    }
    if (gr == 0 or scale_factor_select_info[3] == 0) {
        var band: usize = 16;
        while (band < 21) : (band += 1) {
            bits += s_len2;
        }
    }

    return bits;
}

pub fn calcXMin(
    _: *psycho.PsyRatio,
    code_info: *sideinfo.EncoderGranuleInfo,
    l3_xmin: *psycho.PsyXMin,
    gr: usize,
    ch: usize,
) void {
    var band_limit: usize = @as(usize, code_info.scale_factor_band_max_len);
    if (band_limit > SCALE_FACTOR_BAND_L_MAX) {
        band_limit = SCALE_FACTOR_BAND_L_MAX;
    }
    if (band_limit == 0) {
        return;
    }

    var band = band_limit;
    while (band > 0) : (band -= 1) {
        const idx: usize = band - 1;
        // Match Go behavior: no psychoacoustic model, xmin is zero.
        l3_xmin.l[gr][ch][idx] = 0;
    }
}

pub fn calcSCFSI(
    l3loop: *L3Loop,
    side_info: *sideinfo.EncoderSideInfo,
    l3_xmin: *psycho.PsyXMin,
    sample_rate_index: usize,
    ch: usize,
    gr: usize,
) void {
    const scale_factor_band_long = mp3_tables.scale_factor_band_index[sample_rate_index];
    l3loop.xrmaxl[gr] = l3loop.xrmax;

    var temp: i64 = 0;
    var idx_total: usize = GRANULE_SIZE;
    while (idx_total > 0) : (idx_total -= 1) {
        temp += (@as(i64, l3loop.xrsq[idx_total - 1]) >> 10);
    }
    if (temp != 0) {
        const temp_f: f64 = @floatFromInt(temp);
        const en_tot_val = math.log(f64, math.e, temp_f * 4.768371584e-07) / LN2;
        const en_tot_i32: i32 = @intFromFloat(en_tot_val);
        l3loop.en_tot[gr] = en_tot_i32;
    } else {
        l3loop.en_tot[gr] = 0;
    }

    var sfb_count: usize = 21;
    while (sfb_count > 0) : (sfb_count -= 1) {
        const band_idx = sfb_count - 1;
        const start = @as(usize, scale_factor_band_long[band_idx]);
        const end = @as(usize, scale_factor_band_long[band_idx + 1]);
        var bucket_sum: i64 = 0;
        var sample = start;
        while (sample < end) : (sample += 1) {
            bucket_sum += @as(i64, l3loop.xrsq[sample]) >> 10;
        }
        if (bucket_sum != 0) {
            const en_val = math.log(f64, math.e, @as(f64, @floatFromInt(bucket_sum)) * 4.768371584e-07) / LN2;
            const en_val_i32: i32 = @intFromFloat(en_val);
            l3loop.en[gr][band_idx] = en_val_i32;
        } else {
            l3loop.en[gr][band_idx] = 0;
        }
        const xmin_value = l3_xmin.l[gr][ch][band_idx];
        if (xmin_value != 0) {
            const xm_val = math.log(f64, math.e, xmin_value) / LN2;
            const xm_val_i32: i32 = @intFromFloat(xm_val);
            l3loop.xm[gr][band_idx] = xm_val_i32;
        } else {
            l3loop.xm[gr][band_idx] = 0;
        }
    }

    if (gr == 1) {
        var condition: i64 = 0;
        var gr2: i64 = 1;
        while (gr2 >= 0) : (gr2 -= 1) {
            if (l3loop.xrmaxl[@as(usize, @intCast(gr2))] != 0) {
                condition += 1;
            }
            condition += 1;
        }
        const en_tot_diff = @abs(@as(f64, @floatFromInt(l3loop.en_tot[0])) - @as(f64, @floatFromInt(l3loop.en_tot[1])));
        if (en_tot_diff < @as(f64, EN_TOT_KRIT)) {
            condition += 1;
        }
        var tp: i64 = 0;
        var sfb2_count: usize = 21;
        while (sfb2_count > 0) : (sfb2_count -= 1) {
            const sfb2_idx = sfb2_count - 1;
            const diff = @abs(@as(f64, @floatFromInt(l3loop.en[0][sfb2_idx])) - @as(f64, @floatFromInt(l3loop.en[1][sfb2_idx])));
            tp += @as(i64, @intFromFloat(diff));
        }
        if (tp < EN_DIF_KRIT) {
            condition += 1;
        }

        if (condition == 6) {
            var scfsi_band: usize = 0;
            while (scfsi_band < 4) : (scfsi_band += 1) {
                var sum0: i64 = 0;
                var sum1: i64 = 0;
                const start = SCFSI_BAND_LONG[scfsi_band];
                const end = SCFSI_BAND_LONG[scfsi_band + 1];
                var band_idx = start;
                while (band_idx < end) : (band_idx += 1) {
                    sum0 += @as(i64, @intFromFloat(@abs(@as(f64, @floatFromInt(l3loop.en[0][band_idx])) - @as(f64, @floatFromInt(l3loop.en[1][band_idx])))));
                    sum1 += @as(i64, @intFromFloat(@abs(@as(f64, @floatFromInt(l3loop.xm[0][band_idx])) - @as(f64, @floatFromInt(l3loop.xm[1][band_idx])))));
                }
                side_info.scale_factor_select_info[ch][scfsi_band] =
                    if (sum0 < EN_SCFI_BAND_KRIT and sum1 < XM_SCFI_BAND_KRIT) @as(u64, 1) else 0;
            }
        } else {
            var scfsi_band: usize = 0;
            while (scfsi_band < 4) : (scfsi_band += 1) {
                side_info.scale_factor_select_info[ch][scfsi_band] = 0;
            }
        }
    }
}

pub fn binSearchStepSize(
    ix: *[GRANULE_SIZE]i64,
    desired_rate: i64,
    gran_info: *EncoderGranuleInfo,
    loop: *const L3Loop,
    scale_factor_band_index: []const u16,
) i64 {
    var next: i64 = -120;
    var count: i64 = 120;

    while (true) {
        const half = @divTrunc(count, 2);
        var bit: i64 = 0;
        const candidate = next + half;

        if (quantize(ix, candidate, loop) > 8192) {
            bit = 100_000;
        } else {
            var run_length_info = CalcRunLengthInfo{
                .big_values = &gran_info.big_values,
                .count1 = &gran_info.count1,
            };
            calcRunLength(ix, &run_length_info);
            bit = count1BitCount(
                ix,
                gran_info.big_values,
                gran_info.count1,
                &gran_info.count1_table_select,
            );
            subDivide(gran_info, scale_factor_band_index);
            bigValuesTableSelect(ix, gran_info);
            bit += bigValuesBitCount(ix, gran_info);
        }

        if (bit < desired_rate) {
            count = half;
        } else {
            next += half;
            count -= half;
        }

        if (count <= 1) break;
    }

    return next;
}

pub fn iterationLoop(
    ratio: *psycho.PsyRatio,
    perceptual_energy: *[MAX_CHANNELS][MAX_GRANULES]f64,
    mdct_frequency: [MAX_CHANNELS][MAX_GRANULES][GRANULE_SIZE]i32,
    l3_encoding: *[MAX_CHANNELS][MAX_GRANULES][GRANULE_SIZE]i64,
    l3loop: *L3Loop,
    side_info: *sideinfo.EncoderSideInfo,
    reservoir: *reservoir_mod.Reservoir,
    sample_rate_index: usize,
    granules_per_frame: usize,
    channels: usize,
    is_mpeg1: bool,
) void {
    var l3_xmin: psycho.PsyXMin = std.mem.zeroes(psycho.PsyXMin);
    const scale_factor_band_table = mp3_tables.scale_factor_band_index[@as(usize, sample_rate_index)][0..];

    var ch_idx: usize = channels;
    while (ch_idx > 0) : (ch_idx -= 1) {
        const ch = ch_idx - 1;
        var gr: usize = 0;
        while (gr < granules_per_frame) : (gr += 1) {
            const ix = &l3_encoding[ch][gr];
            l3loop.xr = mdct_frequency[ch][gr][0..];
            var i: usize = 0;
            l3loop.xrmax = 0;
            while (i < GRANULE_SIZE) : (i += 1) {
                const val = l3loop.xr[i];
                l3loop.xrsq[i] = mulSR(val, val);
                const abs_val = if (val < 0) -val else val;
                l3loop.xrabs[i] = abs_val;
                if (abs_val > l3loop.xrmax) {
                    l3loop.xrmax = abs_val;
                }
            }

            var code_info = &side_info.granules[gr].channels[ch].tt;
            code_info.scale_factor_band_max_len = @as(u64, SCALE_FACTOR_BAND_L_MAX - 1);
            calcXMin(ratio, code_info, &l3_xmin, gr, ch);
            if (is_mpeg1) {
                calcSCFSI(l3loop, side_info, &l3_xmin, sample_rate_index, ch, gr);
            }

            const max_bits = reservoir.maxReservoirBits(&perceptual_energy[ch][gr]);
            var idx: usize = 0;
            while (idx < 4) : (idx += 1) {
                code_info.scale_factor_len[idx] = 0;
            }
            code_info.part2_3_length = 0;
            code_info.big_values = 0;
            code_info.count1 = 0;
            code_info.scale_factor_compress = 0;
            code_info.table_select = .{ 0, 0, 0 };
            code_info.region0_count = 0;
            code_info.region1_count = 0;
            code_info.part2_length = 0;
            code_info.preflag = 0;
            code_info.scale_factor_scale = 0;
            code_info.count1_table_select = 0;

            if (l3loop.xrmax != 0) {
                outerLoop(
                    max_bits,
                    &l3_xmin,
                    ix,
                    gr,
                    ch,
                    code_info,
                    l3loop,
                    scale_factor_band_table,
                    code_info.scale_factor_compress,
                    side_info.scale_factor_select_info[ch],
                );
            }

            reservoir.reservoirAdjust(code_info);
            const gain = code_info.quantizer_step_size + 210;
            code_info.global_gain = @bitCast(gain);
        }
    }

    reservoir.reservoirFrameEnd(side_info, @intCast(granules_per_frame));
}

const testing = std.testing;

// Tests (simplified) to exercise the helpers

test "quantize" {
    var xr_buffer: [GRANULE_SIZE]i32 = undefined;
    xr_buffer[0] = 1000;
    xr_buffer[1] = -500;
    xr_buffer[2] = 2000;

    var loop = L3Loop{
        .xr = xr_buffer[0..],
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
    initL3Loop(&loop);

    var ix: [GRANULE_SIZE]i64 = undefined;
    const max_val = quantize(&ix, 10, &loop);
    try testing.expect(max_val >= 0);
}

test "calc run length" {
    var ix: [GRANULE_SIZE]i64 = undefined;
    @memset(&ix, 0);
    ix[0] = 1;
    ix[1] = -1;
    ix[2] = 2;

    var big_vals: u64 = 0;
    var count1: u64 = 0;
    var gran_info_test = CalcRunLengthInfo{ .big_values = &big_vals, .count1 = &count1 };
    calcRunLength(&ix, &gran_info_test);

    try testing.expect(big_vals > 0);
}
