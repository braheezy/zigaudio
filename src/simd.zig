const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");

pub const enabled = build_options.simd;
pub const is_neon = builtin.cpu.arch == .aarch64 or builtin.cpu.arch == .arm;

pub fn convertFlacSamplesNeon(dst: []f32, src: []const i32, bits_per_sample: u8) usize {
    const count = @min(dst.len, src.len);
    if (count < 4) return 0;

    const effective_bps: u8 = if (bits_per_sample == 0) 16 else bits_per_sample;
    const clamped_bps = std.math.clamp(effective_bps, 1, 32);
    const back_shift: u5 = @intCast(32 - clamped_bps);
    const scale: f32 = 1.0 / @as(f32, @floatFromInt(@as(i32, 1) << @intCast(clamped_bps - 1)));

    const vec_len = 4;
    const VecI32 = @Vector(vec_len, i32);
    const VecF32 = @Vector(vec_len, f32);
    const scale_vec: VecF32 = @splat(scale);
    const shift_vec: @Vector(vec_len, u5) = @splat(back_shift);

    var i: usize = 0;
    const limit = count - (count % vec_len);
    while (i < limit) : (i += vec_len) {
        const src_ptr = @as(*align(1) const [vec_len]i32, @ptrCast(src.ptr + i));
        var v: VecI32 = src_ptr.*;
        if (back_shift != 0) {
            v = v >> shift_vec;
        }
        const vf: VecF32 = @floatFromInt(v);
        const out: VecF32 = vf * scale_vec;
        const dst_ptr = @as(*align(1) [vec_len]f32, @ptrCast(dst.ptr + i));
        dst_ptr.* = out;
    }

    return limit;
}

pub fn restoreLpcSignalNeon(
    blk: [*c]i32,
    blk_size: u32,
    lpc_coeffs: [*c]i32,
    lpc_order: u8,
    lpc_shift: i8,
) void {
    const vec_len = 4;
    const VecI32 = @Vector(vec_len, i32);
    const VecI64 = @Vector(vec_len, i64);

    var i: u32 = @as(u32, @bitCast(@as(c_uint, lpc_order)));
    while (i < blk_size) : (i +%= 1) {
        var accu: i64 = 0;
        var j: u8 = 0;

        while ((j + vec_len) <= lpc_order) : (j += vec_len) {
            const coeffs_ptr = lpc_coeffs + j;
            const coeffs_vec: VecI32 = @as(*const [vec_len]i32, @ptrCast(coeffs_ptr)).*;

            const base_idx = i -% @as(u32, @bitCast(@as(c_uint, j))) -% @as(u32, @bitCast(@as(c_int, vec_len)));
            const samples_ptr = blk + base_idx;
            const samples_raw: VecI32 = @as(*const [vec_len]i32, @ptrCast(samples_ptr)).*;
            const mask: @Vector(vec_len, i32) = .{ 3, 2, 1, 0 };
            const samples_vec: VecI32 = @shuffle(i32, samples_raw, samples_raw, mask);

            const coeffs_i64: VecI64 = @intCast(coeffs_vec);
            const samples_i64: VecI64 = @intCast(samples_vec);
            accu += @reduce(.Add, coeffs_i64 * samples_i64);
        }

        while (@as(c_int, @bitCast(@as(c_uint, j))) < @as(c_int, @bitCast(@as(c_uint, lpc_order)))) : (j +%= 1) {
            accu += @as(i64, @bitCast(@as(c_longlong, lpc_coeffs[j]))) *
                @as(i64, @bitCast(@as(c_longlong, blk[(i -% @as(u32, @bitCast(@as(c_uint, j)))) -% @as(u32, @bitCast(@as(c_int, 1)))])));
        }

        blk[i] = @as(i32, @bitCast(@as(c_int, @truncate(@as(i64, @bitCast(@as(c_longlong, blk[i]))) + (accu >> @intCast(@as(c_int, @bitCast(@as(c_int, lpc_shift)))))))));
    }
}

pub fn postProcessLeftSideNeon(
    blk1: [*c]i32,
    blk2: [*c]i32,
    blk_size: u32,
) void {
    const vec_len = 4;
    const VecI32 = @Vector(vec_len, i32);
    var i: u32 = 0;

    while (i + vec_len <= blk_size) : (i += vec_len) {
        const blk1_ptr = @as(*align(1) const [vec_len]i32, @ptrCast(blk1 + i));
        const blk2_ptr = @as(*align(1) const [vec_len]i32, @ptrCast(blk2 + i));
        const v1: VecI32 = blk1_ptr.*;
        const v2: VecI32 = blk2_ptr.*;
        const out: VecI32 = v1 - v2;
        const out_ptr = @as(*align(1) [vec_len]i32, @ptrCast(blk2 + i));
        out_ptr.* = out;
    }

    while (i < blk_size) : (i +%= 1) {
        blk2[i] = blk1[i] - blk2[i];
    }
}

pub fn postProcessMidSideNeon(
    blk1: [*c]i32,
    blk2: [*c]i32,
    blk_size: u32,
) void {
    const vec_len = 4;
    const VecI32 = @Vector(vec_len, i32);
    const ones: VecI32 = @splat(1);
    var i: u32 = 0;

    while (i + vec_len <= blk_size) : (i += vec_len) {
        const blk1_ptr = @as(*align(1) const [vec_len]i32, @ptrCast(blk1 + i));
        const blk2_ptr = @as(*align(1) const [vec_len]i32, @ptrCast(blk2 + i));
        const v1: VecI32 = blk1_ptr.*;
        const v2: VecI32 = blk2_ptr.*;

        var mid: VecI32 = v1 << ones;
        mid |= v2 & ones;
        const left: VecI32 = (mid + v2) >> ones;
        const right: VecI32 = (mid - v2) >> ones;

        const out1_ptr = @as(*align(1) [vec_len]i32, @ptrCast(blk1 + i));
        const out2_ptr = @as(*align(1) [vec_len]i32, @ptrCast(blk2 + i));
        out1_ptr.* = left;
        out2_ptr.* = right;
    }

    while (i < blk_size) : (i +%= 1) {
        var mid: i32 = blk1[i];
        const side: i32 = blk2[i];
        mid = @as(i32, @bitCast(@as(u32, @bitCast(mid)) << 1));
        mid |= @as(i32, @bitCast(side & 1));
        blk1[i] = (mid + side) >> 1;
        blk2[i] = (mid - side) >> 1;
    }
}
