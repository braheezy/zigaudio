const std = @import("std");
const build_options = @import("build_options");
const simd = @import("../simd.zig");

const trace_enabled = false;

inline fn trace(comptime fmt: []const u8, args: anytype) void {
    if (trace_enabled) std.debug.print(fmt, args);
}

pub const fx_bitstream_t = struct {
    buf: u64 = @import("std").mem.zeroes(u64),
    src: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    src_end: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    pos: u8 = @import("std").mem.zeroes(u8),
};
const BUF_SIZE: usize = @sizeOf(u64) * 8;
const FX_ALIGN: usize = 16;

/// Aligns a pointer to FX_ALIGN byte boundary
fn fx_align_addr(ptr: anytype) @TypeOf(ptr) {
    const addr = @intFromPtr(ptr);
    const aligned = (addr + (FX_ALIGN - 1)) & ~(FX_ALIGN - 1);
    return @ptrFromInt(aligned);
}

pub const struct_fx_flac = struct {
    bitstream: fx_bitstream_t = @import("std").mem.zeroes(fx_bitstream_t),
    state: fx_flac_state_t = @import("std").mem.zeroes(fx_flac_state_t),
    priv_state: fx_flac_private_state_t = @import("std").mem.zeroes(fx_flac_private_state_t),
    n_bytes_rem: u32 = @import("std").mem.zeroes(u32),
    max_block_size: u16 = @import("std").mem.zeroes(u16),
    max_channels: u8 = @import("std").mem.zeroes(u8),
    coef_cur: u8 = @import("std").mem.zeroes(u8),
    partition_cur: u16 = @import("std").mem.zeroes(u16),
    partition_sample: u16 = @import("std").mem.zeroes(u16),
    rice_unary_counter: u16 = @import("std").mem.zeroes(u16),
    chan_cur: u8 = @import("std").mem.zeroes(u8),
    blk_cur: u16 = @import("std").mem.zeroes(u16),
    crc8: u8 = @import("std").mem.zeroes(u8),
    crc16: u16 = @import("std").mem.zeroes(u16),
    metadata: [*c]fx_flac_metadata_t = @import("std").mem.zeroes([*c]fx_flac_metadata_t),
    streaminfo: [*c]fx_flac_streaminfo_t = @import("std").mem.zeroes([*c]fx_flac_streaminfo_t),
    frame_header: [*c]fx_flac_frame_header_t = @import("std").mem.zeroes([*c]fx_flac_frame_header_t),
    subframe_header: [*c]fx_flac_subframe_header_t = @import("std").mem.zeroes([*c]fx_flac_subframe_header_t),
    qbuf: [*c]i32 = @import("std").mem.zeroes([*c]i32),
    blkbuf: [8][*c]i32 = @import("std").mem.zeroes([8][*c]i32),
};
pub const fx_flac_t = struct_fx_flac;
pub const FLAC_ERR: c_int = -1;
pub const FLAC_INIT: c_int = 0;
pub const FLAC_IN_METADATA: c_int = 1;
pub const FLAC_END_OF_METADATA: c_int = 2;
pub const FLAC_SEARCH_FRAME: c_int = 3;
pub const FLAC_IN_FRAME: c_int = 4;
pub const FLAC_DECODED_FRAME: c_int = 5;
pub const FLAC_END_OF_FRAME: c_int = 6;
pub const fx_flac_state_t = c_int;
pub const FLAC_KEY_MIN_BLOCK_SIZE: c_int = 0;
pub const FLAC_KEY_MAX_BLOCK_SIZE: c_int = 1;
pub const FLAC_KEY_MIN_FRAME_SIZE: c_int = 2;
pub const FLAC_KEY_MAX_FRAME_SIZE: c_int = 3;
pub const FLAC_KEY_SAMPLE_RATE: c_int = 4;
pub const FLAC_KEY_N_CHANNELS: c_int = 5;
pub const FLAC_KEY_SAMPLE_SIZE: c_int = 6;
pub const FLAC_KEY_N_SAMPLES: c_int = 7;
pub const FLAC_KEY_MD5_SUM_0: c_int = 128;
pub const FLAC_KEY_MD5_SUM_1: c_int = 129;
pub const FLAC_KEY_MD5_SUM_2: c_int = 130;
pub const FLAC_KEY_MD5_SUM_3: c_int = 131;
pub const FLAC_KEY_MD5_SUM_4: c_int = 132;
pub const FLAC_KEY_MD5_SUM_5: c_int = 133;
pub const FLAC_KEY_MD5_SUM_6: c_int = 134;
pub const FLAC_KEY_MD5_SUM_7: c_int = 135;
pub const FLAC_KEY_MD5_SUM_8: c_int = 136;
pub const FLAC_KEY_MD5_SUM_9: c_int = 137;
pub const FLAC_KEY_MD5_SUM_A: c_int = 138;
pub const FLAC_KEY_MD5_SUM_B: c_int = 139;
pub const FLAC_KEY_MD5_SUM_C: c_int = 140;
pub const FLAC_KEY_MD5_SUM_D: c_int = 141;
pub const FLAC_KEY_MD5_SUM_E: c_int = 142;
pub const FLAC_KEY_MD5_SUM_F: c_int = 143;
pub const fx_flac_streaminfo_key_t = c_uint;
pub export fn fx_flac_size(arg_max_block_size: u32, arg_max_channels: u8) u32 {
    var max_block_size = arg_max_block_size;
    _ = &max_block_size;
    var max_channels = arg_max_channels;
    _ = &max_channels;
    var size: u32 = undefined;
    _ = &size;
    var ok: bool = (((((((@as(c_int, @intFromBool(_fx_flac_check_params(@as(u16, @bitCast(@as(c_ushort, @truncate(max_block_size)))), max_channels))) != 0) and (@as(c_int, @intFromBool(fx_mem_init_size(&size))) != 0)) and (@as(c_int, @intFromBool(fx_mem_update_size(&size, @as(u32, @bitCast(@as(c_uint, @truncate(@sizeOf(fx_flac_t)))))))) != 0)) and (@as(c_int, @intFromBool(fx_mem_update_size(&size, @as(u32, @bitCast(@as(c_uint, @truncate(@sizeOf(fx_flac_metadata_t)))))))) != 0)) and (@as(c_int, @intFromBool(fx_mem_update_size(&size, @as(u32, @bitCast(@as(c_uint, @truncate(@sizeOf(fx_flac_streaminfo_t)))))))) != 0)) and (@as(c_int, @intFromBool(fx_mem_update_size(&size, @as(u32, @bitCast(@as(c_uint, @truncate(@sizeOf(fx_flac_frame_header_t)))))))) != 0)) and (@as(c_int, @intFromBool(fx_mem_update_size(&size, @as(u32, @bitCast(@as(c_uint, @truncate(@sizeOf(fx_flac_subframe_header_t)))))))) != 0)) and (@as(c_int, @intFromBool(fx_mem_update_size(&size, @as(u32, @bitCast(@as(c_uint, @truncate(@sizeOf(i32) *% @as(c_ulong, @bitCast(@as(c_ulong, @as(c_uint, 32))))))))))) != 0);
    _ = &ok;
    {
        var i: u8 = 0;
        _ = &i;
        while (@as(c_int, @bitCast(@as(c_uint, i))) < @as(c_int, @bitCast(@as(c_uint, max_channels)))) : (i +%= 1) {
            ok = (@as(c_int, @intFromBool(ok)) != 0) and (@as(c_int, @intFromBool(fx_mem_update_size(&size, @as(u32, @bitCast(@as(c_uint, @truncate(@sizeOf(i32) *% @as(c_ulong, @bitCast(@as(c_ulong, max_block_size)))))))))) != 0);
        }
    }
    return if (@as(c_int, @intFromBool(ok)) != 0) size else @as(u32, @bitCast(@as(c_int, 0)));
}
pub fn fx_flac_init(arg_mem: ?*anyopaque, max_block_size: u16, max_channels: u8) ?*fx_flac_t {
    var mem = arg_mem;
    _ = &mem;
    if (!_fx_flac_check_params(max_block_size, max_channels)) {
        return null;
    }
    const inst_unaligned: *fx_flac_t = @as(*fx_flac_t, @ptrCast(@alignCast(arg_mem)));
    if (arg_mem != null) {
        var inst: *fx_flac_t = @as(*fx_flac_t, @ptrCast(@alignCast(fx_mem_align(@ptrCast(&mem), @as(u32, @bitCast(@as(c_uint, @truncate(@sizeOf(fx_flac_t)))))))));
        _ = &inst;
        inst.*.max_block_size = max_block_size;
        inst.*.max_channels = max_channels;
        inst.*.metadata = @as([*c]fx_flac_metadata_t, @ptrCast(@alignCast(fx_mem_align(@ptrCast(&mem), @as(u32, @bitCast(@as(c_uint, @truncate(@sizeOf(fx_flac_metadata_t)))))))));
        inst.*.streaminfo = @as([*c]fx_flac_streaminfo_t, @ptrCast(@alignCast(fx_mem_align(@ptrCast(&mem), @as(u32, @bitCast(@as(c_uint, @truncate(@sizeOf(fx_flac_streaminfo_t)))))))));
        inst.*.frame_header = @as([*c]fx_flac_frame_header_t, @ptrCast(@alignCast(fx_mem_align(@ptrCast(&mem), @as(u32, @bitCast(@as(c_uint, @truncate(@sizeOf(fx_flac_frame_header_t)))))))));
        inst.*.subframe_header = @as([*c]fx_flac_subframe_header_t, @ptrCast(@alignCast(fx_mem_align(@ptrCast(&mem), @as(u32, @bitCast(@as(c_uint, @truncate(@sizeOf(fx_flac_subframe_header_t)))))))));
        inst.*.qbuf = @as([*c]i32, @ptrCast(@alignCast(fx_mem_align(@ptrCast(&mem), @as(u32, @bitCast(@as(c_uint, @truncate(@sizeOf(i32) *% @as(c_ulong, @bitCast(@as(c_ulong, @as(c_uint, 32))))))))))));
        {
            var i: u8 = 0;
            _ = &i;
            while (@as(c_uint, @bitCast(@as(c_uint, i))) < @as(c_uint, 8)) : (i +%= 1) {
                inst.*.blkbuf[i] = null;
            }
        }
        {
            var i: u8 = 0;
            _ = &i;
            while (@as(c_int, @bitCast(@as(c_uint, i))) < @as(c_int, @bitCast(@as(c_uint, max_channels)))) : (i +%= 1) {
                inst.*.blkbuf[i] = @as([*c]i32, @ptrCast(@alignCast(fx_mem_align(@ptrCast(&mem), @as(u32, @bitCast(@as(c_uint, @truncate(@sizeOf(i32) *% @as(c_ulong, @bitCast(@as(c_ulong, max_block_size)))))))))));
            }
        }
        fx_flac_reset(inst);
    }
    return inst_unaligned;
}
pub fn fx_flac_reset(arg_inst: *fx_flac_t) void {
    const inst = fx_align_addr(arg_inst);
    fx_bitstream_init(&inst.*.bitstream);
    while (true) {
        fx_mem_zero_aligned(@as(?*anyopaque, @ptrCast(inst.*.metadata)), @as(u32, @bitCast(@as(c_uint, @truncate(@sizeOf(fx_flac_metadata_t))))));
        if (!false) break;
    }
    inst.*.metadata.*.type = @as(c_uint, @bitCast(META_TYPE_INVALID));
    while (true) {
        fx_mem_zero_aligned(@as(?*anyopaque, @ptrCast(inst.*.streaminfo)), @as(u32, @bitCast(@as(c_uint, @truncate(@sizeOf(fx_flac_streaminfo_t))))));
        if (!false) break;
    }
    while (true) {
        fx_mem_zero_aligned(@as(?*anyopaque, @ptrCast(inst.*.frame_header)), @as(u32, @bitCast(@as(c_uint, @truncate(@sizeOf(fx_flac_frame_header_t))))));
        if (!false) break;
    }
    while (true) {
        fx_mem_zero_aligned(@as(?*anyopaque, @ptrCast(inst.*.subframe_header)), @as(u32, @bitCast(@as(c_uint, @truncate(@sizeOf(fx_flac_subframe_header_t))))));
        if (!false) break;
    }
    inst.*.state = FLAC_INIT;
    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SYNC_INIT));
    inst.*.n_bytes_rem = 0;
    inst.*.crc8 = 0;
    inst.*.coef_cur = 0;
    inst.*.partition_cur = 0;
    inst.*.partition_sample = 0;
    inst.*.rice_unary_counter = 0;
    inst.*.chan_cur = 0;
    inst.*.blk_cur = 0;
}
pub fn fx_flac_get_state(arg_inst: [*c]const fx_flac_t) fx_flac_state_t {
    const inst = fx_align_addr(arg_inst);
    return inst.*.state;
}
pub fn fx_flac_get_streaminfo(inst_arg: *fx_flac_t, key: fx_flac_streaminfo_key_t) i64 {
    const inst = fx_align_addr(inst_arg);
    while (true) {
        switch (key) {
            @as(c_uint, @bitCast(@as(c_int, 0))) => return @as(i64, @bitCast(@as(c_ulonglong, inst.*.streaminfo.*.min_block_size))),
            @as(c_uint, @bitCast(@as(c_int, 1))) => return @as(i64, @bitCast(@as(c_ulonglong, inst.*.streaminfo.*.max_block_size))),
            @as(c_uint, @bitCast(@as(c_int, 2))) => return @as(i64, @bitCast(@as(c_ulonglong, inst.*.streaminfo.*.min_frame_size))),
            @as(c_uint, @bitCast(@as(c_int, 3))) => return @as(i64, @bitCast(@as(c_ulonglong, inst.*.streaminfo.*.max_frame_size))),
            @as(c_uint, @bitCast(@as(c_int, 4))) => return @as(i64, @bitCast(@as(c_ulonglong, inst.*.streaminfo.*.sample_rate))),
            @as(c_uint, @bitCast(@as(c_int, 5))) => return @as(i64, @bitCast(@as(c_ulonglong, inst.*.streaminfo.*.n_channels))),
            @as(c_uint, @bitCast(@as(c_int, 6))) => return @as(i64, @bitCast(@as(c_ulonglong, inst.*.streaminfo.*.sample_size))),
            @as(c_uint, @bitCast(@as(c_int, 7))) => return @as(i64, @bitCast(inst.*.streaminfo.*.n_samples)),
            @as(c_uint, @bitCast(@as(c_int, 128))), @as(c_uint, @bitCast(@as(c_int, 129))), @as(c_uint, @bitCast(@as(c_int, 130))), @as(c_uint, @bitCast(@as(c_int, 131))), @as(c_uint, @bitCast(@as(c_int, 132))), @as(c_uint, @bitCast(@as(c_int, 133))), @as(c_uint, @bitCast(@as(c_int, 134))), @as(c_uint, @bitCast(@as(c_int, 135))), @as(c_uint, @bitCast(@as(c_int, 136))), @as(c_uint, @bitCast(@as(c_int, 137))), @as(c_uint, @bitCast(@as(c_int, 138))), @as(c_uint, @bitCast(@as(c_int, 139))), @as(c_uint, @bitCast(@as(c_int, 140))), @as(c_uint, @bitCast(@as(c_int, 141))), @as(c_uint, @bitCast(@as(c_int, 142))), @as(c_uint, @bitCast(@as(c_int, 143))) => return @as(i64, @bitCast(@as(c_ulonglong, inst.*.streaminfo.*.md5_sum[key -% @as(c_uint, @bitCast(FLAC_KEY_MD5_SUM_0))]))),
            else => return @as(i64, @bitCast(@as(c_ulonglong, 9223372036854775807))),
        }
        break;
    }
    return @import("std").mem.zeroes(i64);
}
pub fn fx_flac_process(arg_inst: *fx_flac_t, in: [*c]const u8, in_len: [*c]u32, out: [*c]i32, out_len: [*c]u32) fx_flac_state_t {
    const inst = fx_align_addr(arg_inst);
    const bs = &inst.*.bitstream;

    trace("fx_flac_process: in_len={}, out={}, out_len={}, initial_state={}\n", .{ in_len.*, out != null, if (out_len != null) out_len.* else 0, inst.*.state });

    fx_bitstream_set_source(bs, in, in_len.*);
    var done: bool = false;
    var out_len_: u32 = 0;
    var old_state: fx_flac_state_t = inst.*.state;
    var iter: usize = 0;

    while (!done) {
        trace("  Loop iter={}, state={}, done={}\n", .{ iter, inst.*.state, done });

        if (inst.*.state == FLAC_ERR) {
            done = true;
            trace("  FLAC_ERR detected!\n", .{});
            continue;
        }
        if (old_state != inst.*.state) {
            trace("  State changed: {} -> {}\n", .{ old_state, inst.*.state });
            old_state = inst.*.state;
            switch (inst.*.state) {
                FLAC_END_OF_METADATA, FLAC_END_OF_FRAME => {
                    trace("  Early exit on END state\n", .{});
                    done = true;
                    continue;
                },
                else => {},
            }
        }
        switch (inst.*.state) {
            FLAC_INIT => {
                trace("  Processing FLAC_INIT\n", .{});
                done = !_fx_flac_process_init(inst);
            },
            FLAC_IN_METADATA => {
                trace("  Processing FLAC_IN_METADATA\n", .{});
                done = !_fx_flac_process_in_metadata(inst);
            },
            FLAC_END_OF_METADATA, FLAC_END_OF_FRAME => {
                trace("  Transitioning to SEARCH_FRAME\n", .{});
                inst.*.state = FLAC_SEARCH_FRAME;
                inst.*.priv_state = @as(c_uint, @bitCast(FLAC_FRAME_SYNC));
            },
            FLAC_SEARCH_FRAME => {
                trace("  Processing FLAC_SEARCH_FRAME\n", .{});
                done = !_fx_flac_process_search_frame(inst);
            },
            FLAC_IN_FRAME => {
                trace("  Processing FLAC_IN_FRAME\n", .{});
                done = !_fx_flac_process_in_frame(inst);
            },
            FLAC_DECODED_FRAME => {
                trace("  Processing FLAC_DECODED_FRAME, out={}, out_len={}\n", .{ out != null, out_len != null });
                if (!(out != null) or !(out_len != null)) {
                    trace("  No output buffer, transitioning to END_OF_FRAME\n", .{});
                    inst.*.state = FLAC_END_OF_FRAME;
                } else {
                    out_len_ = out_len.*;
                    trace("  Decoding frame, out_len_={}\n", .{out_len_});
                    done = !_fx_flac_process_decoded_frame(inst, out, &out_len_);
                    trace("  After decode: done={}, out_len_={}\n", .{ done, out_len_ });
                }
            },
            else => {
                trace("  Unknown state {}! Setting FLAC_ERR\n", .{inst.*.state});
                inst.*.state = FLAC_ERR;
            },
        }

        iter += 1;
        if (iter > 100000) {
            trace("  Too many iterations! Breaking\n", .{});
            inst.*.state = FLAC_ERR;
            done = true;
        }
    }
    if (out_len != null) {
        out_len.* = out_len_;
    }
    in_len.* = @as(u32, @bitCast(@as(c_int, @truncate(@divExact(@as(c_long, @bitCast(@intFromPtr(bs.*.src) -% @intFromPtr(in))), @sizeOf(u8))))));

    trace("fx_flac_process EXIT: state={}, consumed={}, out_len={}\n", .{ inst.*.state, in_len.*, out_len_ });
    return inst.*.state;
}
pub const fx_bitstream_byte_callback_t = ?*const fn (u8, ?*anyopaque) callconv(.c) void;
pub fn fx_bitstream_init(arg_reader: *fx_bitstream_t) callconv(.c) void {
    var reader = arg_reader;
    _ = &reader;
    reader.*.buf = 0;
    reader.*.pos = @as(u8, @bitCast(@as(u8, @truncate(@sizeOf(u64) *% @as(c_ulong, @bitCast(@as(c_ulong, @as(c_uint, 8))))))));
    reader.*.src = null;
    reader.*.src_end = null;
}
pub fn fx_bitstream_set_source(arg_reader: *fx_bitstream_t, arg_src: [*c]const u8, arg_src_len: u32) callconv(.c) void {
    var reader = arg_reader;
    _ = &reader;
    var src = arg_src;
    _ = &src;
    var src_len = arg_src_len;
    _ = &src_len;
    reader.*.src = src;
    reader.*.src_end = src + src_len;
    _fx_bitstream_fill_buf(reader);
}
pub fn fx_bitstream_can_read(arg_reader: *fx_bitstream_t, arg_n_bits: u8) callconv(.c) bool {
    var reader = arg_reader;
    _ = &reader;
    var n_bits = arg_n_bits;
    _ = &n_bits;
    return (@sizeOf(u64) *% @as(c_ulong, @bitCast(@as(c_ulong, @as(c_uint, 8))))) >= @as(c_ulong, @bitCast(@as(c_long, @as(c_int, @bitCast(@as(c_uint, n_bits))) + @as(c_int, @bitCast(@as(c_uint, reader.*.pos))))));
}
pub fn fx_bitstream_read_msb(arg_reader: *fx_bitstream_t, arg_n_bits: u8) callconv(.c) u64 {
    var reader = arg_reader;
    _ = &reader;
    var n_bits = arg_n_bits;
    _ = &n_bits;
    return _fx_bitstream_read_msb(reader, n_bits, null, @as(?*anyopaque, @ptrFromInt(@as(c_int, 0))));
}
pub fn fx_bitstream_read_msb_ex(arg_reader: *fx_bitstream_t, arg_n_bits: u8, arg_callback: fx_bitstream_byte_callback_t, arg_callback_data: ?*anyopaque) callconv(.c) u64 {
    var reader = arg_reader;
    _ = &reader;
    var n_bits = arg_n_bits;
    _ = &n_bits;
    var callback = arg_callback;
    _ = &callback;
    var callback_data = arg_callback_data;
    _ = &callback_data;
    return _fx_bitstream_read_msb(reader, n_bits, callback, callback_data);
}
pub fn fx_bitstream_peek_msb(arg_reader: *fx_bitstream_t, arg_n_bits: u8) callconv(.c) u64 {
    var reader = arg_reader;
    _ = &reader;
    var n_bits = arg_n_bits;
    _ = &n_bits;

    return (reader.*.buf << @intCast(@as(c_int, @bitCast(@as(c_uint, reader.*.pos))))) >> @intCast((@sizeOf(u64) *% @as(c_ulong, @bitCast(@as(c_ulong, @as(c_uint, 8))))) -% @as(c_ulong, @bitCast(@as(c_ulong, n_bits))));
}
pub fn fx_bitstream_try_read_msb(arg_reader: *fx_bitstream_t, arg_n_bits: u8) callconv(.c) i64 {
    var reader = arg_reader;
    _ = &reader;
    var n_bits = arg_n_bits;
    _ = &n_bits;
    return if (@as(c_int, @intFromBool(fx_bitstream_can_read(reader, n_bits))) != 0) @as(i64, @bitCast(fx_bitstream_read_msb(reader, n_bits))) else @as(i64, @bitCast(@as(c_longlong, -@as(c_int, 1))));
}
pub fn fx_bitstream_try_read_msb_ex(arg_reader: *fx_bitstream_t, arg_n_bits: u8, arg_callback: fx_bitstream_byte_callback_t, arg_callback_data: ?*anyopaque) callconv(.c) i64 {
    var reader = arg_reader;
    _ = &reader;
    var n_bits = arg_n_bits;
    _ = &n_bits;
    var callback = arg_callback;
    _ = &callback;
    var callback_data = arg_callback_data;
    _ = &callback_data;
    return if (@as(c_int, @intFromBool(fx_bitstream_can_read(reader, n_bits))) != 0) @as(i64, @bitCast(fx_bitstream_read_msb_ex(reader, n_bits, callback, callback_data))) else @as(i64, @bitCast(@as(c_longlong, -@as(c_int, 1))));
}
pub fn fx_bitstream_try_peek_msb(arg_reader: *fx_bitstream_t, arg_n_bits: u8) callconv(.c) i64 {
    var reader = arg_reader;
    _ = &reader;
    var n_bits = arg_n_bits;
    _ = &n_bits;
    return if (@as(c_int, @intFromBool(fx_bitstream_can_read(reader, n_bits))) != 0) @as(i64, @bitCast(fx_bitstream_peek_msb(reader, n_bits))) else @as(i64, @bitCast(@as(c_longlong, -@as(c_int, 1))));
}
pub fn _fx_bitstream_fill_buf(arg_reader: *fx_bitstream_t) callconv(.c) void {
    var reader = arg_reader;
    _ = &reader;
    while ((@as(c_uint, @bitCast(@as(c_uint, reader.*.pos))) >= @as(c_uint, 8)) and (reader.*.src != reader.*.src_end)) {
        reader.*.buf = (reader.*.buf << @intCast(8)) | @as(u64, @bitCast(@as(c_ulonglong, (blk: {
            const ref = &reader.*.src;
            const tmp = ref.*;
            ref.* += 1;
            break :blk tmp;
        }).*)));
        reader.*.pos -%= @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 8)))));
    }
}
pub fn _fx_bitstream_read_msb(reader: *fx_bitstream_t, n_bits: u8, callback: fx_bitstream_byte_callback_t, callback_data: ?*anyopaque) u64 {
    const bits: u64 = reader.*.buf << @intCast(reader.*.pos);
    const pos_new: u8 = reader.*.pos + n_bits;
    if (callback != null) {
        const @"i0": u8 = @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, @bitCast(@as(c_uint, reader.*.pos))) / @as(c_uint, 8)))));
        _ = &@"i0";
        const @"i1": u8 = @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, @bitCast(@as(c_uint, pos_new))) / @as(c_uint, 8)))));
        _ = &@"i1";
        var buf: u64 = reader.*.buf << @intCast(@as(c_uint, @bitCast(@as(c_uint, @"i0"))) *% @as(c_uint, 8));
        _ = &buf;
        {
            var i: u8 = @"i0";
            _ = &i;
            while (@as(c_int, @bitCast(@as(c_uint, i))) < @as(c_int, @bitCast(@as(c_uint, @"i1")))) : (i +%= 1) {
                var byte: u8 = @as(u8, @bitCast(@as(u8, @truncate(buf >> @intCast((@sizeOf(u64) *% @as(c_ulong, @bitCast(@as(c_ulong, @as(c_uint, 8))))) -% @as(c_ulong, @bitCast(@as(c_ulong, @as(c_uint, 8)))))))));
                _ = &byte;
                callback.?(byte, callback_data);
                buf = buf << @intCast(8);
            }
        }
    }
    reader.*.pos = pos_new;
    _fx_bitstream_fill_buf(reader);
    return bits >> @truncate(BUF_SIZE - n_bits);
}
pub fn fx_mem_init_size(arg_size: [*c]u32) callconv(.c) bool {
    var size = arg_size;
    _ = &size;
    size.* = 16;
    return @as(c_int, 1) != 0;
}
pub fn fx_mem_update_size_ex(arg_size: [*c]u32, arg_n_bytes: u32, arg_align: u32) callconv(.c) bool {
    var size = arg_size;
    _ = &size;
    var n_bytes = arg_n_bytes;
    _ = &n_bytes;
    var @"align" = arg_align;
    _ = &@"align";
    const new_size: u32 = (((size.* +% n_bytes) +% @"align") -% @as(u32, @bitCast(@as(c_int, 1)))) & ~(@"align" -% @as(u32, @bitCast(@as(c_int, 1))));
    _ = &new_size;
    if (new_size < size.*) {
        return @as(c_int, 0) != 0;
    }
    size.* = new_size;
    return @as(c_int, 1) != 0;
}
pub fn fx_mem_update_size(arg_size: [*c]u32, arg_n_bytes: u32) callconv(.c) bool {
    var size = arg_size;
    _ = &size;
    var n_bytes = arg_n_bytes;
    _ = &n_bytes;
    return fx_mem_update_size_ex(size, n_bytes, @as(u32, @bitCast(@as(c_int, 16))));
}
pub fn fx_mem_align_ex(arg_mem: [*c]?*anyopaque, arg_size: u32, arg_align: u32) callconv(.c) ?*anyopaque {
    var mem = arg_mem;
    _ = &mem;
    var size = arg_size;
    _ = &size;
    var @"align" = arg_align;
    _ = &@"align";
    var res: ?*anyopaque = @as(?*anyopaque, @ptrFromInt(((@as(usize, @intCast(@intFromPtr(mem.*))) +% @as(usize, @bitCast(@as(c_ulong, @"align")))) -% @as(usize, @bitCast(@as(c_long, @as(c_int, 1))))) & ~@as(usize, @bitCast(@as(c_ulong, @"align" -% @as(u32, @bitCast(@as(c_int, 1))))))));
    _ = &res;
    mem.* = @as(?*anyopaque, @ptrFromInt(@as(usize, @intCast(@intFromPtr(res))) +% @as(usize, @bitCast(@as(c_ulong, size)))));
    return res;
}
pub fn fx_mem_align(arg_mem: [*]?*anyopaque, arg_size: u32) ?*anyopaque {
    var mem = arg_mem;
    _ = &mem;
    var size = arg_size;
    _ = &size;
    return fx_mem_align_ex(mem, size, @as(u32, @bitCast(@as(c_int, 16))));
}
pub fn fx_mem_zero_aligned(arg_mem: ?*anyopaque, arg_size: u32) callconv(.c) void {
    var mem = arg_mem;
    _ = &mem;
    var size = arg_size;
    _ = &size;
    mem = mem;
    {
        var i: u32 = 0;
        _ = &i;
        while (i < (((size +% @as(u32, @bitCast(@as(c_int, 16)))) -% @as(u32, @bitCast(@as(c_int, 1)))) / @as(u32, @bitCast(@as(c_int, 16))))) : (i +%= 1) {
            @as([*c]u64, @ptrCast(@alignCast(mem)))[(@as(u32, @bitCast(@as(c_int, 2))) *% i) +% @as(u32, @bitCast(@as(c_int, 0)))] = 0;
            @as([*c]u64, @ptrCast(@alignCast(mem)))[(@as(u32, @bitCast(@as(c_int, 2))) *% i) +% @as(u32, @bitCast(@as(c_int, 1)))] = 0;
        }
    }
}
pub const FLAC_SUBSET_MAX_BLOCK_SIZE = 16384;
pub const FLAC_MAX_CHANNEL_COUNT = 8;
pub const FLAC_INVALID_METADATA_KEY = 0x7FFFFFFFFFFFFFFF;
pub const META_TYPE_STREAMINFO: c_int = 0;
pub const META_TYPE_PADDING: c_int = 1;
pub const META_TYPE_APPLICATION: c_int = 2;
pub const META_TYPE_SEEKTABLE: c_int = 3;
pub const META_TYPE_VORBIS_COMMENT: c_int = 4;
pub const META_TYPE_CUESHEET: c_int = 5;
pub const META_TYPE_PICTURE: c_int = 6;
pub const META_TYPE_INVALID: c_int = 127;
pub const fx_flac_metadata_type_t = c_uint;
pub const BLK_FIXED: c_int = 0;
pub const BLK_VARIABLE: c_int = 1;
pub const fx_flac_blocking_strategy_t = c_uint;
pub const INDEPENDENT_MONO: c_int = 0;
pub const INDEPENDENT_STEREO: c_int = 1;
pub const INDEPENDENT_3C: c_int = 2;
pub const INDEPENDENT_4C: c_int = 3;
pub const INDEPENDENT_5C: c_int = 4;
pub const INDEPENDENT_6C: c_int = 5;
pub const INDEPENDENT_7C: c_int = 6;
pub const INDEPENDENT_8C: c_int = 7;
pub const LEFT_SIDE_STEREO: c_int = 8;
pub const RIGHT_SIDE_STEREO: c_int = 9;
pub const MID_SIDE_STEREO: c_int = 10;
pub const fx_flac_channel_assignment_t = c_uint;
pub const BLK_SIZE_RESERVED: c_int = 0;
pub const BLK_SIZE_192: c_int = 1;
pub const BLK_SIZE_576: c_int = 2;
pub const BLK_SIZE_1152: c_int = 3;
pub const BLK_SIZE_2304: c_int = 4;
pub const BLK_SIZE_4608: c_int = 5;
pub const BLK_SIZE_READ_8BIT: c_int = 6;
pub const BLK_SIZE_READ_16BIT: c_int = 7;
pub const BLK_SIZE_256: c_int = 8;
pub const BLK_SIZE_512: c_int = 9;
pub const BLK_SIZE_1024: c_int = 10;
pub const BLK_SIZE_2048: c_int = 11;
pub const BLK_SIZE_4096: c_int = 12;
pub const BLK_SIZE_8192: c_int = 13;
pub const BLK_SIZE_16384: c_int = 14;
pub const BLK_SIZE_32768: c_int = 15;
pub const fx_flac_block_size_t = c_uint;
pub const fx_flac_block_sizes_: [16]i32 = [16]i32{
    -@as(c_int, 1),
    192,
    576,
    1152,
    2304,
    4608,
    0,
    0,
    256,
    512,
    1024,
    2048,
    4096,
    8192,
    16384,
    32768,
};
pub const FS_STREAMINFO: c_int = 0;
pub const FS_88_2KHZ: c_int = 1;
pub const FS_176_4KHZ: c_int = 2;
pub const FS_192KHZ: c_int = 3;
pub const FS_8KHZ: c_int = 4;
pub const FS_16KHZ: c_int = 5;
pub const FS_22_05KHZ: c_int = 6;
pub const FS_24KHZ: c_int = 7;
pub const FS_32KHZ: c_int = 8;
pub const FS_44_1KHZ: c_int = 9;
pub const FS_48KHZ: c_int = 10;
pub const FS_96KHZ: c_int = 11;
pub const FS_READ_8BIT_KHZ: c_int = 12;
pub const FS_READ_16BIT_HZ: c_int = 13;
pub const FS_READ_16BIT_DHZ: c_int = 14;
pub const FS_INVALID: c_int = 15;
pub const fx_flac_sample_rate_t = c_uint;
pub const fx_flac_sample_rates_: [16]i32 = [16]i32{
    0,
    88200,
    176400,
    192000,
    8000,
    16000,
    22050,
    24000,
    32000,
    44100,
    48000,
    96000,
    0,
    0,
    0,
    -@as(c_int, 1),
};
pub const SS_STREAMINFO: c_int = 0;
pub const SS_8BIT: c_int = 1;
pub const SS_12BIT: c_int = 2;
pub const SS_RESERVED_1: c_int = 3;
pub const SS_16BIT: c_int = 4;
pub const SS_20BIT: c_int = 5;
pub const SS_24BIT: c_int = 6;
pub const SS_RESERVED_2: c_int = 7;
pub const fx_flac_sample_size_t = c_uint;
pub const fx_flac_sample_sizes_: [8]i8 = [8]i8{
    0,
    8,
    12,
    @as(i8, @bitCast(@as(i8, @truncate(-@as(c_int, 1))))),
    16,
    20,
    24,
    @as(i8, @bitCast(@as(i8, @truncate(-@as(c_int, 1))))),
};
pub const SFT_CONSTANT: c_int = 0;
pub const SFT_VERBATIM: c_int = 1;
pub const SFT_FIXED: c_int = 2;
pub const SFT_LPC: c_int = 3;
pub const fx_flac_subframe_type_t = c_uint;
pub const RES_RICE: c_int = 0;
pub const RES_RICE2: c_int = 1;
pub const RES_RESERVED_1: c_int = 2;
pub const RES_RESERVED_2: c_int = 3;
pub const fx_flac_residual_method_t = c_uint;
pub const fx_flac_metadata_t = extern struct {
    is_last: bool = @import("std").mem.zeroes(bool),
    type: fx_flac_metadata_type_t = @import("std").mem.zeroes(fx_flac_metadata_type_t),
    length: u32 = @import("std").mem.zeroes(u32),
};
pub const fx_flac_streaminfo_t = extern struct {
    min_block_size: u16 = @import("std").mem.zeroes(u16),
    max_block_size: u16 = @import("std").mem.zeroes(u16),
    min_frame_size: u32 = @import("std").mem.zeroes(u32),
    max_frame_size: u32 = @import("std").mem.zeroes(u32),
    sample_rate: u32 = @import("std").mem.zeroes(u32),
    n_channels: u8 = @import("std").mem.zeroes(u8),
    sample_size: u8 = @import("std").mem.zeroes(u8),
    n_samples: u64 = @import("std").mem.zeroes(u64),
    md5_sum: [16]u8 = @import("std").mem.zeroes([16]u8),
};
pub const fx_flac_frame_header_t = extern struct {
    blocking_strategy: fx_flac_blocking_strategy_t = @import("std").mem.zeroes(fx_flac_blocking_strategy_t),
    block_size_enum: fx_flac_block_size_t = @import("std").mem.zeroes(fx_flac_block_size_t),
    sample_rate_enum: fx_flac_sample_rate_t = @import("std").mem.zeroes(fx_flac_sample_rate_t),
    channel_assignment: fx_flac_channel_assignment_t = @import("std").mem.zeroes(fx_flac_channel_assignment_t),
    sample_size_enum: fx_flac_sample_size_t = @import("std").mem.zeroes(fx_flac_sample_size_t),
    block_size: u32 = @import("std").mem.zeroes(u32),
    sample_rate: u32 = @import("std").mem.zeroes(u32),
    channel_count: u8 = @import("std").mem.zeroes(u8),
    sample_size: u8 = @import("std").mem.zeroes(u8),
    sync_info: u64 = @import("std").mem.zeroes(u64),
    crc8: u8 = @import("std").mem.zeroes(u8),
};
pub const fx_flac_subframe_header_t = extern struct {
    type: fx_flac_subframe_type_t = @import("std").mem.zeroes(fx_flac_subframe_type_t),
    order: u8 = @import("std").mem.zeroes(u8),
    wasted_bits: u8 = @import("std").mem.zeroes(u8),
    lpc_prec: u8 = @import("std").mem.zeroes(u8),
    lpc_shift: i8 = @import("std").mem.zeroes(i8),
    lpc_coeffs: [*c]i32 = @import("std").mem.zeroes([*c]i32),
    residual_method: fx_flac_residual_method_t = @import("std").mem.zeroes(fx_flac_residual_method_t),
    rice_partition_order: u8 = @import("std").mem.zeroes(u8),
    rice_parameter: u8 = @import("std").mem.zeroes(u8),
};
pub const _fx_flac_fixed_coeffs: [5][4]i32 = [5][4]i32{
    [4]i32{
        0,
        0,
        0,
        0,
    },
    [4]i32{
        1,
        0,
        0,
        0,
    },
    [4]i32{
        2,
        -@as(c_int, 1),
        0,
        0,
    },
    [4]i32{
        3,
        -@as(c_int, 3),
        1,
        0,
    },
    [4]i32{
        4,
        -@as(c_int, 6),
        4,
        -@as(c_int, 1),
    },
};
pub const FLAC_SYNC_INIT: c_int = 0;
pub const FLAC_SYNC_F: c_int = 100;
pub const FLAC_SYNC_L: c_int = 101;
pub const FLAC_SYNC_A: c_int = 102;
pub const FLAC_METADATA_HEADER: c_int = 200;
pub const FLAC_METADATA_SKIP: c_int = 201;
pub const FLAC_METADATA_SINFO: c_int = 202;
pub const FLAC_FRAME_SYNC: c_int = 300;
pub const FLAC_FRAME_HEADER: c_int = 400;
pub const FLAC_FRAME_HEADER_SYNC_INFO: c_int = 401;
pub const FLAC_FRAME_HEADER_AUX: c_int = 402;
pub const FLAC_FRAME_HEADER_CRC: c_int = 403;
pub const FLAC_SUBFRAME_HEADER: c_int = 500;
pub const FLAC_SUBFRAME_CONSTANT: c_int = 502;
pub const FLAC_SUBFRAME_FIXED: c_int = 503;
pub const FLAC_SUBFRAME_FIXED_RESIDUAL: c_int = 504;
pub const FLAC_SUBFRAME_LPC: c_int = 505;
pub const FLAC_SUBFRAME_LPC_HEADER: c_int = 506;
pub const FLAC_SUBFRAME_LPC_COEFFS: c_int = 507;
pub const FLAC_SUBFRAME_LPC_RESIDUAL: c_int = 508;
pub const FLAC_SUBFRAME_RICE_INIT: c_int = 509;
pub const FLAC_SUBFRAME_RICE: c_int = 510;
pub const FLAC_SUBFRAME_RICE_UNARY: c_int = 511;
pub const FLAC_SUBFRAME_RICE_VERBATIM: c_int = 512;
pub const FLAC_SUBFRAME_RICE_FINALIZE: c_int = 513;
pub const FLAC_SUBFRAME_VERBATIM: c_int = 514;
pub const FLAC_SUBFRAME_FINALIZE: c_int = 515;
pub const fx_flac_private_state_t = c_uint;
pub fn _fx_flac_check_params(arg_max_block_size: u16, arg_max_channels: u8) callconv(.c) bool {
    var max_block_size = arg_max_block_size;
    _ = &max_block_size;
    var max_channels = arg_max_channels;
    _ = &max_channels;
    return ((@as(c_uint, @bitCast(@as(c_uint, max_block_size))) > @as(c_uint, 0)) and (@as(c_uint, @bitCast(@as(c_uint, max_channels))) > @as(c_uint, 0))) and (@as(c_uint, @bitCast(@as(c_uint, max_channels))) <= @as(c_uint, 8));
}
pub fn _fx_flac_decode_block_size(arg_block_size_enum: fx_flac_block_size_t, arg_block_size: [*c]u32) callconv(.c) bool {
    var block_size_enum = arg_block_size_enum;
    _ = &block_size_enum;
    var block_size = arg_block_size;
    _ = &block_size;
    const bs: i32 = fx_flac_block_sizes_[@as(c_uint, @intCast(@as(c_int, @bitCast(block_size_enum))))];
    _ = &bs;
    if (bs < @as(c_int, 0)) {
        return @as(c_int, 0) != 0;
    } else if (bs > @as(c_int, 0)) {
        block_size.* = @as(u32, @bitCast(bs));
    }
    return @as(c_int, 1) != 0;
}
pub fn _fx_flac_decode_sample_rate(arg_sample_rate_enum: fx_flac_sample_rate_t, arg_sample_rate: [*c]u32) callconv(.c) bool {
    var sample_rate_enum = arg_sample_rate_enum;
    _ = &sample_rate_enum;
    var sample_rate = arg_sample_rate;
    _ = &sample_rate;
    const fs: i32 = fx_flac_sample_rates_[@as(c_uint, @intCast(@as(c_int, @bitCast(sample_rate_enum))))];
    _ = &fs;
    if (fs < @as(c_int, 0)) {
        return @as(c_int, 0) != 0;
    } else if (fs > @as(c_int, 0)) {
        sample_rate.* = @as(u32, @bitCast(fs));
    }
    return @as(c_int, 1) != 0;
}
pub fn _fx_flac_decode_sample_size(arg_sample_size_enum: fx_flac_sample_size_t, arg_sample_size: [*c]u8) callconv(.c) bool {
    var sample_size_enum = arg_sample_size_enum;
    _ = &sample_size_enum;
    var sample_size = arg_sample_size;
    _ = &sample_size;
    const ss: i8 = fx_flac_sample_sizes_[@as(c_uint, @intCast(@as(c_int, @bitCast(sample_size_enum))))];
    _ = &ss;
    if (@as(c_int, @bitCast(@as(c_int, ss))) < @as(c_int, 0)) {
        return @as(c_int, 0) != 0;
    } else if (@as(c_int, @bitCast(@as(c_int, ss))) > @as(c_int, 0)) {
        sample_size.* = @as(u8, @bitCast(ss));
    }
    return @as(c_int, 1) != 0;
}
pub fn _fx_flac_decode_channel_count(arg_channel_assignment: fx_flac_channel_assignment_t, arg_channel_count: [*c]u8) callconv(.c) bool {
    var channel_assignment = arg_channel_assignment;
    _ = &channel_assignment;
    var channel_count = arg_channel_count;
    _ = &channel_count;
    channel_count.* = @as(u8, @bitCast(@as(u8, @truncate(if (channel_assignment >= @as(c_uint, @bitCast(LEFT_SIDE_STEREO))) @as(c_uint, 2) else @as(c_uint, @bitCast(@as(c_uint, @as(u8, @bitCast(@as(u8, @truncate(channel_assignment))))))) +% @as(c_uint, 1)))));
    return @as(c_int, 1) != 0;
}
pub fn _fx_flac_post_process_left_side(arg_blk1: [*c]i32, arg_blk2: [*c]i32, arg_blk_size: u32) callconv(.c) void {
    if (build_options.simd and simd.is_neon) {
        simd.postProcessLeftSideNeon(arg_blk1, arg_blk2, arg_blk_size);
        return;
    }
    var blk1 = arg_blk1;
    _ = &blk1;
    var blk2 = arg_blk2;
    _ = &blk2;
    var blk_size = arg_blk_size;
    _ = &blk_size;
    blk1 = blk1;
    blk2 = blk2;
    {
        var i: u32 = 0;
        _ = &i;
        while (i < blk_size) : (i +%= 1) {
            blk2[i] = blk1[i] - blk2[i];
        }
    }
}
pub fn _fx_flac_post_process_right_side(arg_blk1: [*c]i32, arg_blk2: [*c]i32, arg_blk_size: u32) callconv(.c) void {
    var blk1 = arg_blk1;
    _ = &blk1;
    var blk2 = arg_blk2;
    _ = &blk2;
    var blk_size = arg_blk_size;
    _ = &blk_size;
    blk1 = blk1;
    blk2 = blk2;
    {
        var i: u32 = 0;
        _ = &i;
        while (i < blk_size) : (i +%= 1) {
            blk1[i] = blk1[i] + blk2[i];
        }
    }
}
pub fn _fx_flac_post_process_mid_side(arg_blk1: [*c]i32, arg_blk2: [*c]i32, arg_blk_size: u32) callconv(.c) void {
    if (build_options.simd and simd.is_neon) {
        simd.postProcessMidSideNeon(arg_blk1, arg_blk2, arg_blk_size);
        return;
    }
    var blk1 = arg_blk1;
    _ = &blk1;
    var blk2 = arg_blk2;
    _ = &blk2;
    var blk_size = arg_blk_size;
    _ = &blk_size;
    blk1 = blk1;
    blk2 = blk2;
    {
        var i: u32 = 0;
        _ = &i;
        while (i < blk_size) : (i +%= 1) {
            var mid: i32 = blk1[i];
            _ = &mid;
            var side: i32 = blk2[i];
            _ = &side;
            mid = @as(i32, @bitCast(@as(u32, @bitCast(mid)) << @intCast(1)));
            mid |= @as(i32, @bitCast(side & @as(c_int, 1)));
            blk1[i] = (mid + side) >> @intCast(1);
            blk2[i] = (mid - side) >> @intCast(1);
        }
    }
}
pub fn _fx_flac_restore_lpc_signal(arg_blk: [*c]i32, arg_blk_size: u32, arg_lpc_coeffs: [*c]i32, arg_lpc_order: u8, arg_lpc_shift: i8) callconv(.c) void {
    if (build_options.simd and simd.is_neon) {
        simd.restoreLpcSignalNeon(arg_blk, arg_blk_size, arg_lpc_coeffs, arg_lpc_order, arg_lpc_shift);
        return;
    }
    var blk = arg_blk;
    _ = &blk;
    var blk_size = arg_blk_size;
    _ = &blk_size;
    var lpc_coeffs = arg_lpc_coeffs;
    _ = &lpc_coeffs;
    var lpc_order = arg_lpc_order;
    _ = &lpc_order;
    var lpc_shift = arg_lpc_shift;
    _ = &lpc_shift;
    blk = blk;
    lpc_coeffs = lpc_coeffs;
    {
        var i: u32 = @as(u32, @bitCast(@as(c_uint, lpc_order)));
        _ = &i;
        while (i < blk_size) : (i +%= 1) {
            var accu: i64 = 0;
            _ = &accu;
            {
                var j: u8 = 0;
                _ = &j;
                while (@as(c_int, @bitCast(@as(c_uint, j))) < @as(c_int, @bitCast(@as(c_uint, lpc_order)))) : (j +%= 1) {
                    accu += @as(i64, @bitCast(@as(c_longlong, lpc_coeffs[j]))) * @as(i64, @bitCast(@as(c_longlong, blk[(i -% @as(u32, @bitCast(@as(c_uint, j)))) -% @as(u32, @bitCast(@as(c_int, 1)))])));
                }
            }
            blk[i] = @as(i32, @bitCast(@as(c_int, @truncate(@as(i64, @bitCast(@as(c_longlong, blk[i]))) + (accu >> @intCast(@as(c_int, @bitCast(@as(c_int, lpc_shift)))))))));
        }
    }
}
pub const fx_flac_crc8_table_: [256]u8 = [256]u8{
    0,
    7,
    14,
    9,
    28,
    27,
    18,
    21,
    56,
    63,
    54,
    49,
    36,
    35,
    42,
    45,
    112,
    119,
    126,
    121,
    108,
    107,
    98,
    101,
    72,
    79,
    70,
    65,
    84,
    83,
    90,
    93,
    224,
    231,
    238,
    233,
    252,
    251,
    242,
    245,
    216,
    223,
    214,
    209,
    196,
    195,
    202,
    205,
    144,
    151,
    158,
    153,
    140,
    139,
    130,
    133,
    168,
    175,
    166,
    161,
    180,
    179,
    186,
    189,
    199,
    192,
    201,
    206,
    219,
    220,
    213,
    210,
    255,
    248,
    241,
    246,
    227,
    228,
    237,
    234,
    183,
    176,
    185,
    190,
    171,
    172,
    165,
    162,
    143,
    136,
    129,
    134,
    147,
    148,
    157,
    154,
    39,
    32,
    41,
    46,
    59,
    60,
    53,
    50,
    31,
    24,
    17,
    22,
    3,
    4,
    13,
    10,
    87,
    80,
    89,
    94,
    75,
    76,
    69,
    66,
    111,
    104,
    97,
    102,
    115,
    116,
    125,
    122,
    137,
    142,
    135,
    128,
    149,
    146,
    155,
    156,
    177,
    182,
    191,
    184,
    173,
    170,
    163,
    164,
    249,
    254,
    247,
    240,
    229,
    226,
    235,
    236,
    193,
    198,
    207,
    200,
    221,
    218,
    211,
    212,
    105,
    110,
    103,
    96,
    117,
    114,
    123,
    124,
    81,
    86,
    95,
    88,
    77,
    74,
    67,
    68,
    25,
    30,
    23,
    16,
    5,
    2,
    11,
    12,
    33,
    38,
    47,
    40,
    61,
    58,
    51,
    52,
    78,
    73,
    64,
    71,
    82,
    85,
    92,
    91,
    118,
    113,
    120,
    127,
    106,
    109,
    100,
    99,
    62,
    57,
    48,
    55,
    34,
    37,
    44,
    43,
    6,
    1,
    8,
    15,
    26,
    29,
    20,
    19,
    174,
    169,
    160,
    167,
    178,
    181,
    188,
    187,
    150,
    145,
    152,
    159,
    138,
    141,
    132,
    131,
    222,
    217,
    208,
    215,
    194,
    197,
    204,
    203,
    230,
    225,
    232,
    239,
    250,
    253,
    244,
    243,
};
pub const fx_flac_crc16_table_: [256]u16 = [256]u16{
    0,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32773))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32783))))),
    10,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32795))))),
    30,
    20,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32785))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32819))))),
    54,
    60,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32825))))),
    40,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32813))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32807))))),
    34,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32867))))),
    102,
    108,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32873))))),
    120,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32893))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32887))))),
    114,
    80,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32853))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32863))))),
    90,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32843))))),
    78,
    68,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32833))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32963))))),
    198,
    204,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32969))))),
    216,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32989))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32983))))),
    210,
    240,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33013))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33023))))),
    250,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33003))))),
    238,
    228,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32993))))),
    160,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32933))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32943))))),
    170,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32955))))),
    190,
    180,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32945))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32915))))),
    150,
    156,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32921))))),
    136,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32909))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 32903))))),
    130,
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33155))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 390))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 396))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33161))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 408))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33181))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33175))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 402))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 432))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33205))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33215))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 442))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33195))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 430))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 420))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33185))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 480))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33253))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33263))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 490))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33275))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 510))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 500))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33265))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33235))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 470))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 476))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33241))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 456))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33229))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33223))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 450))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 320))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33093))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33103))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 330))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33115))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 350))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 340))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33105))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33139))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 374))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 380))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33145))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 360))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33133))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33127))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 354))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33059))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 294))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 300))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33065))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 312))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33085))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33079))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 306))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 272))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33045))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33055))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 282))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33035))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 270))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 260))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33025))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33539))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 774))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 780))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33545))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 792))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33565))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33559))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 786))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 816))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33589))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33599))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 826))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33579))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 814))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 804))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33569))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 864))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33637))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33647))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 874))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33659))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 894))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 884))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33649))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33619))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 854))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 860))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33625))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 840))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33613))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33607))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 834))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 960))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33733))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33743))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 970))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33755))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 990))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 980))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33745))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33779))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 1014))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 1020))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33785))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 1000))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33773))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33767))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 994))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33699))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 934))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 940))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33705))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 952))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33725))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33719))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 946))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 912))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33685))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33695))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 922))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33675))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 910))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 900))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33665))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 640))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33413))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33423))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 650))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33435))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 670))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 660))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33425))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33459))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 694))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 700))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33465))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 680))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33453))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33447))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 674))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33507))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 742))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 748))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33513))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 760))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33533))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33527))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 754))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 720))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33493))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33503))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 730))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33483))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 718))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 708))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33473))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33347))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 582))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 588))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33353))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 600))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33373))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33367))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 594))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 624))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33397))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33407))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 634))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33387))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 622))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 612))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33377))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 544))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33317))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33327))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 554))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33339))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 574))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 564))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33329))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33299))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 534))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 540))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33305))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 520))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33293))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 33287))))),
    @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 514))))),
};
pub fn _fx_flac_crc8_(arg_byte: u8, arg_data: ?*anyopaque) void {
    var byte = arg_byte;
    _ = &byte;
    var data = arg_data;
    _ = &data;
    var inst: *fx_flac_t = @ptrCast(@alignCast(data));
    _ = &inst;
    inst.*.crc8 = fx_flac_crc8_table_[@as(c_uint, @intCast(@as(c_int, @bitCast(@as(c_uint, inst.*.crc8))) ^ @as(c_int, @bitCast(@as(c_uint, byte)))))];
}
pub fn _fx_flac_crc16_(arg_byte: u8, arg_data: ?*anyopaque) callconv(.c) void {
    var byte = arg_byte;
    _ = &byte;
    var data = arg_data;
    _ = &data;
    var inst: *fx_flac_t = @ptrCast(@alignCast(data));
    _ = &inst;
    const i: u8 = @as(u8, @bitCast(@as(i8, @truncate(((@as(c_int, @bitCast(@as(c_uint, inst.*.crc16))) >> @intCast(8)) ^ @as(c_int, @bitCast(@as(c_uint, byte)))) & @as(c_int, 255)))));
    _ = &i;
    inst.*.crc16 = @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, fx_flac_crc16_table_[i]))) ^ (@as(c_int, @bitCast(@as(c_uint, inst.*.crc16))) << @intCast(8))))));
}
pub fn _fx_flac_double_crc_(arg_byte: u8, arg_data: ?*anyopaque) callconv(.c) void {
    var byte = arg_byte;
    _ = &byte;
    var data = arg_data;
    _ = &data;
    _fx_flac_crc8_(byte, data);
    _fx_flac_crc16_(byte, data);
}
pub fn _fx_flac_reader_utf8_coded_int(arg_inst: *fx_flac_t, arg_max_n: u8, arg_tar: [*c]u64) callconv(.c) bool {
    var inst = arg_inst;
    _ = &inst;
    var max_n = arg_max_n;
    _ = &max_n;
    var tar = arg_tar;
    _ = &tar;
    var tmp_: i64 = undefined;
    _ = &tmp_;
    if (!fx_bitstream_can_read(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, @bitCast(@as(c_uint, max_n))) *% @as(c_uint, 8))))))) {
        return @as(c_int, 0) != 0;
    }
    var v: u8 = @as(u8, @bitCast(@as(i8, @truncate(blk: {
        const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 8))))), &_fx_flac_double_crc_, @as(?*anyopaque, @ptrCast(inst)))));
        tmp_ = tmp;
        break :blk tmp;
    }))));
    _ = &v;
    var n_ones: u8 = 0;
    _ = &n_ones;
    while ((@as(c_uint, @bitCast(@as(c_uint, v))) & @as(c_uint, 128)) != 0) {
        v = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, v))) << @intCast(1)))));
        n_ones +%= 1;
    }
    if (@as(c_int, @bitCast(@as(c_uint, n_ones))) > @as(c_int, @bitCast(@as(c_uint, max_n)))) {
        inst.*.priv_state = @as(c_uint, @bitCast(FLAC_FRAME_SYNC));
        return @as(c_int, 1) != 0;
    }
    tar.* = @as(u64, @bitCast(@as(c_longlong, @as(c_int, @bitCast(@as(c_uint, v))) >> @intCast(@as(c_int, @bitCast(@as(c_uint, n_ones)))))));
    {
        var i: u8 = 1;
        _ = &i;
        while (@as(c_int, @bitCast(@as(c_uint, i))) < @as(c_int, @bitCast(@as(c_uint, n_ones)))) : (i +%= 1) {
            v = @as(u8, @bitCast(@as(i8, @truncate(blk: {
                const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 8))))), &_fx_flac_double_crc_, @as(?*anyopaque, @ptrCast(inst)))));
                tmp_ = tmp;
                break :blk tmp;
            }))));
            if ((@as(c_uint, @bitCast(@as(c_uint, v))) & @as(c_uint, 192)) != @as(c_uint, @bitCast(@as(c_int, 128)))) {
                inst.*.priv_state = @as(c_uint, @bitCast(FLAC_FRAME_SYNC));
                return @as(c_int, 1) != 0;
            }
            tar.* = (tar.* << @intCast(6)) | @as(u64, @bitCast(@as(c_longlong, @as(c_int, @bitCast(@as(c_uint, v))) & @as(c_int, 63))));
        }
    }
    return @as(c_int, 1) != 0;
}
pub fn _fx_flac_handle_err(arg_inst: *fx_flac_t) callconv(.c) bool {
    var inst = arg_inst;
    _ = &inst;
    if (inst.*.state < FLAC_END_OF_METADATA) {
        inst.*.state = FLAC_ERR;
        return @as(c_int, 0) != 0;
    }
    inst.*.state = FLAC_SEARCH_FRAME;
    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_FRAME_SYNC));
    return @as(c_int, 1) != 0;
}
pub fn _fx_flac_process_init(arg_inst: *fx_flac_t) callconv(.c) bool {
    var inst = arg_inst;
    _ = &inst;
    var tmp_: i64 = undefined;
    _ = &tmp_;

    const bs = &inst.*.bitstream;
    trace("    _fx_flac_process_init: priv_state={}, src={}, src_end={}, pos={}\n", .{ inst.*.priv_state, bs.*.src != null, bs.*.src_end != null, bs.*.pos });

    var byte: u8 = @as(u8, @bitCast(@as(i8, @truncate(blk: {
        const tmp = fx_bitstream_try_read_msb(&inst.*.bitstream, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 8))))));
        tmp_ = tmp;
        break :blk tmp;
    }))));
    _ = &byte;

    trace("    _fx_flac_process_init: try_read returned={}, byte=0x{x}\n", .{ tmp_, byte });

    if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
        trace("    _fx_flac_process_init: NO DATA, returning false\n", .{});
        return @as(c_int, 0) != 0;
    }
    while (true) {
        switch (inst.*.priv_state) {
            @as(c_uint, @bitCast(@as(c_int, 0))) => {
                if (@as(c_int, @bitCast(@as(c_uint, byte))) == @as(c_int, 'f')) {
                    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SYNC_F));
                }
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 100))) => {
                if (@as(c_int, @bitCast(@as(c_uint, byte))) == @as(c_int, 'L')) {
                    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SYNC_L));
                } else {
                    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SYNC_INIT));
                }
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 101))) => {
                if (@as(c_int, @bitCast(@as(c_uint, byte))) == @as(c_int, 'a')) {
                    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SYNC_A));
                } else {
                    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SYNC_INIT));
                }
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 102))) => {
                if (@as(c_int, @bitCast(@as(c_uint, byte))) == @as(c_int, 'C')) {
                    inst.*.state = FLAC_IN_METADATA;
                    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_METADATA_HEADER));
                } else {
                    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SYNC_INIT));
                }
                break;
            },
            else => return _fx_flac_handle_err(inst),
        }
        break;
    }
    return @as(c_int, 1) != 0;
}
pub fn _fx_flac_process_in_metadata(inst: *fx_flac_t) bool {
    var tmp_: i64 = undefined;

    trace("    _fx_flac_process_in_metadata: priv_state={}\n", .{inst.*.priv_state});

    switch (inst.*.priv_state) {
        FLAC_METADATA_HEADER => {
            const can_read = fx_bitstream_can_read(&inst.*.bitstream, 32);
            trace("      METADATA_HEADER: can_read_32bits={}\n", .{can_read});
            if (!can_read) {
                trace("      returning false (need more data)\n", .{});
                return false;
            }
            inst.*.metadata.*.is_last = (blk: {
                const tmp = @as(i64, @bitCast(fx_bitstream_read_msb(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 1))))))));
                tmp_ = tmp;
                break :blk tmp;
            }) != 0;
            inst.*.metadata.*.type = @as(c_uint, @bitCast(@as(c_int, @truncate(blk: {
                const tmp = @as(i64, @bitCast(fx_bitstream_read_msb(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 7))))))));
                tmp_ = tmp;
                break :blk tmp;
            }))));
            if (inst.*.metadata.*.type == @as(c_uint, @bitCast(META_TYPE_INVALID))) {
                return _fx_flac_handle_err(inst);
            }
            inst.*.metadata.*.length = blk: {
                const tmp = @as(u32, @bitCast(@as(c_int, @truncate(blk_1: {
                    const tmp_2 = @as(i64, @bitCast(fx_bitstream_read_msb(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 24))))))));
                    tmp_ = tmp_2;
                    break :blk_1 tmp_2;
                }))));
                inst.*.n_bytes_rem = tmp;
                break :blk tmp;
            };
            if (inst.*.metadata.*.type == @as(c_uint, @bitCast(META_TYPE_STREAMINFO))) {
                inst.*.priv_state = @as(c_uint, @bitCast(FLAC_METADATA_SINFO));
                if (inst.*.metadata.*.length != @as(c_uint, 34)) {
                    return _fx_flac_handle_err(inst);
                }
            } else {
                inst.*.priv_state = @as(c_uint, @bitCast(FLAC_METADATA_SKIP));
            }
        },
        @as(c_uint, @bitCast(@as(c_int, 202))) => {
            trace("      METADATA_SINFO: n_bytes_rem={}\n", .{inst.*.n_bytes_rem});
            while (true) {
                switch (inst.*.n_bytes_rem) {
                    @as(c_uint, 34) => {
                        trace("        Reading min_block_size (16 bits)\n", .{});
                        inst.*.streaminfo.*.min_block_size = @as(u16, @bitCast(@as(c_short, @truncate(blk: {
                            const tmp = fx_bitstream_try_read_msb(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 16))))));
                            tmp_ = tmp;
                            break :blk tmp;
                        }))));
                        if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
                            trace("        Failed to read! Returning false\n", .{});
                            return @as(c_int, 0) != 0;
                        }
                        trace("        Read min_block_size={}\n", .{inst.*.streaminfo.*.min_block_size});
                        inst.*.n_bytes_rem -%= @as(u32, @bitCast(@as(c_uint, 2)));
                        break;
                    },
                    @as(c_uint, 32) => {
                        inst.*.streaminfo.*.max_block_size = @as(u16, @bitCast(@as(c_short, @truncate(blk: {
                            const tmp = fx_bitstream_try_read_msb(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 16))))));
                            tmp_ = tmp;
                            break :blk tmp;
                        }))));
                        if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
                            return @as(c_int, 0) != 0;
                        }
                        inst.*.n_bytes_rem -%= @as(u32, @bitCast(@as(c_uint, 2)));
                        break;
                    },
                    @as(c_uint, 30) => {
                        inst.*.streaminfo.*.min_frame_size = @as(u32, @bitCast(@as(c_int, @truncate(blk: {
                            const tmp = fx_bitstream_try_read_msb(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 24))))));
                            tmp_ = tmp;
                            break :blk tmp;
                        }))));
                        if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
                            return @as(c_int, 0) != 0;
                        }
                        inst.*.n_bytes_rem -%= @as(u32, @bitCast(@as(c_uint, 3)));
                        break;
                    },
                    @as(c_uint, 27) => {
                        inst.*.streaminfo.*.max_frame_size = @as(u32, @bitCast(@as(c_int, @truncate(blk: {
                            const tmp = fx_bitstream_try_read_msb(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 24))))));
                            tmp_ = tmp;
                            break :blk tmp;
                        }))));
                        if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
                            return @as(c_int, 0) != 0;
                        }
                        inst.*.n_bytes_rem -%= @as(u32, @bitCast(@as(c_uint, 3)));
                        break;
                    },
                    @as(c_uint, 24) => {
                        if (!fx_bitstream_can_read(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 28))))))) {
                            return @as(c_int, 0) != 0;
                        }
                        inst.*.streaminfo.*.sample_rate = @as(u32, @bitCast(@as(c_int, @truncate(blk: {
                            const tmp = @as(i64, @bitCast(fx_bitstream_read_msb(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 20))))))));
                            tmp_ = tmp;
                            break :blk tmp;
                        }))));
                        inst.*.streaminfo.*.n_channels = @as(u8, @bitCast(@as(i8, @truncate(@as(i64, @bitCast(@as(c_ulonglong, @as(c_uint, 1)))) + (blk: {
                            const tmp = @as(i64, @bitCast(fx_bitstream_read_msb(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 3))))))));
                            tmp_ = tmp;
                            break :blk tmp;
                        })))));
                        inst.*.streaminfo.*.sample_size = @as(u8, @bitCast(@as(i8, @truncate(@as(i64, @bitCast(@as(c_ulonglong, @as(c_uint, 1)))) + (blk: {
                            const tmp = @as(i64, @bitCast(fx_bitstream_read_msb(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 5))))))));
                            tmp_ = tmp;
                            break :blk tmp;
                        })))));
                        inst.*.n_bytes_rem -%= @as(u32, @bitCast(@as(c_uint, 4)));
                        break;
                    },
                    @as(c_uint, 20) => {
                        inst.*.streaminfo.*.n_samples = @as(u64, @bitCast(blk: {
                            const tmp = fx_bitstream_try_read_msb(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 36))))));
                            tmp_ = tmp;
                            break :blk tmp;
                        }));
                        if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
                            return @as(c_int, 0) != 0;
                        }
                        inst.*.n_bytes_rem -%= @as(u32, @bitCast(@as(c_uint, 4)));
                        break;
                    },
                    @as(c_uint, 1), @as(c_uint, 2), @as(c_uint, 3), @as(c_uint, 4), @as(c_uint, 5), @as(c_uint, 6), @as(c_uint, 7), @as(c_uint, 8), @as(c_uint, 9), @as(c_uint, 10), @as(c_uint, 11), @as(c_uint, 12), @as(c_uint, 13), @as(c_uint, 14), @as(c_uint, 15), @as(c_uint, 16) => {
                        inst.*.streaminfo.*.md5_sum[@as(c_uint, 16) -% inst.*.n_bytes_rem] = @as(u8, @bitCast(@as(i8, @truncate(blk: {
                            const tmp = fx_bitstream_try_read_msb(&inst.*.bitstream, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 8))))));
                            tmp_ = tmp;
                            break :blk tmp;
                        }))));
                        if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
                            return @as(c_int, 0) != 0;
                        }
                        inst.*.n_bytes_rem -%= @as(u32, @bitCast(@as(c_uint, 1)));
                        break;
                    },
                    @as(c_uint, 0) => {
                        inst.*.priv_state = @as(c_uint, @bitCast(FLAC_METADATA_SKIP));
                        break;
                    },
                    else => return _fx_flac_handle_err(inst),
                }
                break;
            }
        },
        @as(c_uint, @bitCast(@as(c_int, 201))) => {
            trace("      METADATA_SKIP: n_bytes_rem={}\n", .{inst.*.n_bytes_rem});
            const n_read: u8 = @as(u8, @bitCast(@as(u8, @truncate(if (inst.*.n_bytes_rem >= @as(c_uint, 7)) @as(c_uint, 7) else inst.*.n_bytes_rem))));
            _ = &n_read;
            trace("        n_read={}, is_last={}\n", .{ n_read, inst.*.metadata.*.is_last });
            if (@as(c_uint, @bitCast(@as(c_uint, n_read))) == @as(c_uint, 0)) {
                if (inst.*.metadata.*.is_last) {
                    trace("        Transitioning to END_OF_METADATA\n", .{});
                    inst.*.state = FLAC_END_OF_METADATA;
                } else {
                    trace("        Transitioning to METADATA_HEADER (more metadata)\n", .{});
                    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_METADATA_HEADER));
                }
            }
            _ = blk: {
                const tmp = fx_bitstream_try_read_msb(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, @bitCast(@as(c_uint, n_read))) *% @as(c_uint, 8))))));
                tmp_ = tmp;
                break :blk tmp;
            };
            if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
                return @as(c_int, 0) != 0;
            }
            inst.*.n_bytes_rem -%= @as(u32, @bitCast(@as(c_uint, n_read)));
        },
        else => return _fx_flac_handle_err(inst),
    }
    return true;
}
pub fn _fx_flac_process_search_frame(arg_inst: *fx_flac_t) callconv(.c) bool {
    var inst = arg_inst;
    _ = &inst;
    var tmp_: i64 = undefined;
    _ = &tmp_;
    var fh: [*c]fx_flac_frame_header_t = inst.*.frame_header;
    _ = &fh;
    var si: [*c]fx_flac_streaminfo_t = inst.*.streaminfo;
    _ = &si;
    while (true) {
        switch (inst.*.priv_state) {
            @as(c_uint, @bitCast(@as(c_int, 300))) => {
                {
                    var n_: u8 = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, inst.*.bitstream.pos))) & @as(c_int, 7)))));
                    _ = &n_;
                    if (n_ != 0) {
                        _ = blk: {
                            const tmp = fx_bitstream_try_read_msb(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 8) -% @as(c_uint, @bitCast(@as(c_uint, n_))))))));
                            tmp_ = tmp;
                            break :blk tmp;
                        };
                        if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
                            return @as(c_int, 0) != 0;
                        }
                    }
                }
                if (!fx_bitstream_can_read(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 15))))))) {
                    return @as(c_int, 0) != 0;
                }
                var sync_code: u16 = @as(u16, @bitCast(@as(c_short, @truncate(blk: {
                    const tmp = fx_bitstream_try_peek_msb(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 15))))));
                    tmp_ = tmp;
                    break :blk tmp;
                }))));
                _ = &sync_code;
                if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
                    return @as(c_int, 0) != 0;
                }
                if (@as(c_uint, @bitCast(@as(c_uint, sync_code))) != @as(c_uint, 32764)) {
                    _ = blk: {
                        const tmp = fx_bitstream_try_read_msb(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 8))))));
                        tmp_ = tmp;
                        break :blk tmp;
                    };
                    if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
                        return @as(c_int, 0) != 0;
                    }
                    return @as(c_int, 1) != 0;
                } else {
                    inst.*.crc8 = 0;
                    inst.*.crc16 = 0;
                    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_FRAME_HEADER));
                    _ = blk: {
                        const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 15))))), &_fx_flac_double_crc_, @as(?*anyopaque, @ptrCast(inst)))));
                        tmp_ = tmp;
                        break :blk tmp;
                    };
                }
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 400))) => {
                if (!fx_bitstream_can_read(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 17))))))) {
                    return @as(c_int, 0) != 0;
                }
                fh.*.blocking_strategy = @as(c_uint, @bitCast(@as(c_int, @truncate(blk: {
                    const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 1))))), &_fx_flac_double_crc_, @as(?*anyopaque, @ptrCast(inst)))));
                    tmp_ = tmp;
                    break :blk tmp;
                }))));
                fh.*.block_size_enum = @as(c_uint, @bitCast(@as(c_int, @truncate(blk: {
                    const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 4))))), &_fx_flac_double_crc_, @as(?*anyopaque, @ptrCast(inst)))));
                    tmp_ = tmp;
                    break :blk tmp;
                }))));
                fh.*.sample_rate_enum = @as(c_uint, @bitCast(@as(c_int, @truncate(blk: {
                    const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 4))))), &_fx_flac_double_crc_, @as(?*anyopaque, @ptrCast(inst)))));
                    tmp_ = tmp;
                    break :blk tmp;
                }))));
                fh.*.channel_assignment = @as(c_uint, @bitCast(@as(c_int, @truncate(blk: {
                    const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 4))))), &_fx_flac_double_crc_, @as(?*anyopaque, @ptrCast(inst)))));
                    tmp_ = tmp;
                    break :blk tmp;
                }))));
                fh.*.sample_size_enum = @as(c_uint, @bitCast(@as(c_int, @truncate(blk: {
                    const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 3))))), &_fx_flac_double_crc_, @as(?*anyopaque, @ptrCast(inst)))));
                    tmp_ = tmp;
                    break :blk tmp;
                }))));
                _ = blk: {
                    const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 1))))), &_fx_flac_double_crc_, @as(?*anyopaque, @ptrCast(inst)))));
                    tmp_ = tmp;
                    break :blk tmp;
                };
                if ((tmp_ != @as(i64, @bitCast(@as(c_ulonglong, @as(c_uint, 0))))) or (fh.*.channel_assignment > @as(c_uint, @bitCast(MID_SIDE_STEREO)))) {
                    return _fx_flac_handle_err(inst);
                }
                fh.*.sample_rate = si.*.sample_rate;
                fh.*.sample_size = si.*.sample_size;
                if (((!_fx_flac_decode_block_size(fh.*.block_size_enum, &fh.*.block_size) or !_fx_flac_decode_sample_rate(fh.*.sample_rate_enum, &fh.*.sample_rate)) or !_fx_flac_decode_sample_size(fh.*.sample_size_enum, &fh.*.sample_size)) or !_fx_flac_decode_channel_count(fh.*.channel_assignment, &fh.*.channel_count)) {
                    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_FRAME_SYNC));
                    break;
                }
                inst.*.priv_state = @as(c_uint, @bitCast(FLAC_FRAME_HEADER_SYNC_INFO));
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 401))) => {
                if (!_fx_flac_reader_utf8_coded_int(inst, @as(u8, @bitCast(@as(u8, @truncate(if (fh.*.blocking_strategy == @as(c_uint, @bitCast(BLK_VARIABLE))) @as(c_uint, 7) else @as(c_uint, 6))))), &fh.*.sync_info)) {
                    return @as(c_int, 0) != 0;
                }
                inst.*.priv_state = @as(c_uint, @bitCast(FLAC_FRAME_HEADER_AUX));
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 402))) => {
                if (!fx_bitstream_can_read(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 32))))))) {
                    return @as(c_int, 0) != 0;
                }
                while (true) {
                    switch (fh.*.block_size_enum) {
                        @as(c_uint, @bitCast(@as(c_int, 6))) => {
                            fh.*.block_size = @as(u32, @bitCast(@as(c_int, @truncate(@as(i64, @bitCast(@as(c_ulonglong, @as(c_uint, 1)))) + (blk: {
                                const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 8))))), &_fx_flac_double_crc_, @as(?*anyopaque, @ptrCast(inst)))));
                                tmp_ = tmp;
                                break :blk tmp;
                            })))));
                            break;
                        },
                        @as(c_uint, @bitCast(@as(c_int, 7))) => {
                            fh.*.block_size = @as(u32, @bitCast(@as(c_int, @truncate(@as(i64, @bitCast(@as(c_ulonglong, @as(c_uint, 1)))) + (blk: {
                                const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 16))))), &_fx_flac_double_crc_, @as(?*anyopaque, @ptrCast(inst)))));
                                tmp_ = tmp;
                                break :blk tmp;
                            })))));
                            break;
                        },
                        else => break,
                    }
                    break;
                }
                while (true) {
                    switch (fh.*.sample_rate_enum) {
                        @as(c_uint, @bitCast(@as(c_int, 12))) => {
                            fh.*.sample_rate = @as(u32, @bitCast(@as(c_uint, @truncate(@as(c_ulonglong, @bitCast(@as(c_ulonglong, @as(c_ulong, 1000)))) *% @as(c_ulonglong, @bitCast(blk: {
                                const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 8))))), &_fx_flac_double_crc_, @as(?*anyopaque, @ptrCast(inst)))));
                                tmp_ = tmp;
                                break :blk tmp;
                            }))))));
                            break;
                        },
                        @as(c_uint, @bitCast(@as(c_int, 13))) => {
                            fh.*.sample_rate = @as(u32, @bitCast(@as(c_int, @truncate(blk: {
                                const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 16))))), &_fx_flac_double_crc_, @as(?*anyopaque, @ptrCast(inst)))));
                                tmp_ = tmp;
                                break :blk tmp;
                            }))));
                            break;
                        },
                        @as(c_uint, @bitCast(@as(c_int, 14))) => {
                            fh.*.sample_rate = @as(u32, @bitCast(@as(c_uint, @truncate(@as(c_ulonglong, @bitCast(@as(c_ulonglong, @as(c_ulong, 10)))) *% @as(c_ulonglong, @bitCast(blk: {
                                const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 16))))), &_fx_flac_double_crc_, @as(?*anyopaque, @ptrCast(inst)))));
                                tmp_ = tmp;
                                break :blk tmp;
                            }))))));
                            break;
                        },
                        else => break,
                    }
                    break;
                }
                inst.*.priv_state = @as(c_uint, @bitCast(FLAC_FRAME_HEADER_CRC));
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 403))) => {
                fh.*.crc8 = @as(u8, @bitCast(@as(i8, @truncate(blk: {
                    const tmp = fx_bitstream_try_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 8))))), &_fx_flac_crc16_, @as(?*anyopaque, @ptrCast(inst)));
                    tmp_ = tmp;
                    break :blk tmp;
                }))));
                if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
                    return @as(c_int, 0) != 0;
                }
                if (@as(c_int, @bitCast(@as(c_uint, fh.*.crc8))) != @as(c_int, @bitCast(@as(c_uint, inst.*.crc8)))) {
                    return _fx_flac_handle_err(inst);
                }
                if ((fh.*.block_size > @as(u32, @bitCast(@as(c_uint, inst.*.max_block_size)))) or (@as(c_int, @bitCast(@as(c_uint, fh.*.channel_count))) > @as(c_int, @bitCast(@as(c_uint, inst.*.max_channels))))) {
                    return _fx_flac_handle_err(inst);
                }
                inst.*.state = FLAC_IN_FRAME;
                inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SUBFRAME_HEADER));
                inst.*.chan_cur = 0;
                break;
            },
            else => return _fx_flac_handle_err(inst),
        }
        break;
    }
    return @as(c_int, 1) != 0;
}
pub fn _fx_flac_process_in_frame(arg_inst: *fx_flac_t) callconv(.c) bool {
    var inst = arg_inst;
    _ = &inst;
    var tmp_: i64 = undefined;
    _ = &tmp_;
    var fh: [*c]fx_flac_frame_header_t = inst.*.frame_header;
    _ = &fh;
    var sfh: [*c]fx_flac_subframe_header_t = inst.*.subframe_header;
    _ = &sfh;
    var blk: [*c]i32 = inst.*.blkbuf[@as(c_uint, @bitCast(@as(c_uint, inst.*.chan_cur))) % @as(c_uint, 8)];
    _ = &blk;
    const blk_n: u32 = fh.*.block_size;
    _ = &blk_n;
    var bps: u8 = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, fh.*.sample_size))) - @as(c_int, @bitCast(@as(c_uint, sfh.*.wasted_bits)))))));
    _ = &bps;
    if ((((fh.*.channel_assignment == @as(c_uint, @bitCast(LEFT_SIDE_STEREO))) and (@as(c_int, @bitCast(@as(c_uint, inst.*.chan_cur))) == @as(c_int, 1))) or ((fh.*.channel_assignment == @as(c_uint, @bitCast(RIGHT_SIDE_STEREO))) and (@as(c_int, @bitCast(@as(c_uint, inst.*.chan_cur))) == @as(c_int, 0)))) or ((fh.*.channel_assignment == @as(c_uint, @bitCast(MID_SIDE_STEREO))) and (@as(c_int, @bitCast(@as(c_uint, inst.*.chan_cur))) == @as(c_int, 1)))) {
        bps +%= 1;
    }
    if ((@as(c_uint, @bitCast(@as(c_uint, bps))) == @as(c_uint, 0)) or (@as(c_uint, @bitCast(@as(c_uint, bps))) > @as(c_uint, 32))) {
        return _fx_flac_handle_err(inst);
    }
    while (true) {
        switch (inst.*.priv_state) {
            @as(c_uint, @bitCast(@as(c_int, 500))) => {
                {
                    if (!fx_bitstream_can_read(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 40))))))) {
                        return @as(c_int, 0) != 0;
                    }
                    inst.*.blk_cur = 0;
                    blk[@as(c_uint, 0)] = 0;
                    var padding: u8 = @as(u8, @bitCast(@as(i8, @truncate(blk_1: {
                        const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 1))))), &_fx_flac_crc16_, @as(?*anyopaque, @ptrCast(inst)))));
                        tmp_ = tmp;
                        break :blk_1 tmp;
                    }))));
                    _ = &padding;
                    var valid: bool = @as(c_uint, @bitCast(@as(c_uint, padding))) == @as(c_uint, 0);
                    _ = &valid;
                    var @"type": u8 = @as(u8, @bitCast(@as(i8, @truncate(blk_1: {
                        const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 6))))), &_fx_flac_crc16_, @as(?*anyopaque, @ptrCast(inst)))));
                        tmp_ = tmp;
                        break :blk_1 tmp;
                    }))));
                    _ = &@"type";
                    if ((@as(c_uint, @bitCast(@as(c_uint, @"type"))) & @as(c_uint, 32)) != 0) {
                        sfh.*.order = @as(u8, @bitCast(@as(u8, @truncate((@as(c_uint, @bitCast(@as(c_uint, @"type"))) & @as(c_uint, 31)) +% @as(c_uint, 1)))));
                        sfh.*.type = @as(c_uint, @bitCast(SFT_LPC));
                        sfh.*.lpc_coeffs = inst.*.qbuf;
                        inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SUBFRAME_LPC));
                    } else if ((@as(c_uint, @bitCast(@as(c_uint, @"type"))) & @as(c_uint, 16)) != 0) {
                        return _fx_flac_handle_err(inst);
                    } else if ((@as(c_uint, @bitCast(@as(c_uint, @"type"))) & @as(c_uint, 8)) != 0) {
                        sfh.*.order = @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, @bitCast(@as(c_uint, @"type"))) & @as(c_uint, 7)))));
                        sfh.*.type = @as(c_uint, @bitCast(SFT_FIXED));
                        sfh.*.lpc_shift = 0;
                        inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SUBFRAME_FIXED));
                        valid = (@as(c_int, @intFromBool(valid)) != 0) and (@as(c_uint, @bitCast(@as(c_uint, sfh.*.order))) <= @as(c_uint, 4));
                        if (valid) {
                            sfh.*.lpc_coeffs = @as([*c]i32, @ptrCast(@constCast(@volatileCast(@as([*c]const i32, @ptrCast(@alignCast(&_fx_flac_fixed_coeffs[sfh.*.order][@as(usize, @intCast(0))])))))));
                        }
                    } else if (((@as(c_uint, @bitCast(@as(c_uint, @"type"))) & @as(c_uint, 4)) != 0) or ((@as(c_uint, @bitCast(@as(c_uint, @"type"))) & @as(c_uint, 2)) != 0)) {
                        return _fx_flac_handle_err(inst);
                    } else if ((@as(c_uint, @bitCast(@as(c_uint, @"type"))) & @as(c_uint, 1)) != 0) {
                        sfh.*.type = @as(c_uint, @bitCast(SFT_VERBATIM));
                        inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SUBFRAME_VERBATIM));
                    } else {
                        sfh.*.type = @as(c_uint, @bitCast(SFT_CONSTANT));
                        inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SUBFRAME_CONSTANT));
                    }
                    sfh.*.wasted_bits = @as(u8, @bitCast(@as(i8, @truncate(blk_1: {
                        const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 1))))), &_fx_flac_crc16_, @as(?*anyopaque, @ptrCast(inst)))));
                        tmp_ = tmp;
                        break :blk_1 tmp;
                    }))));
                    if (sfh.*.wasted_bits != 0) {
                        {
                            var i: u8 = 1;
                            _ = &i;
                            while (@as(c_uint, @bitCast(@as(c_uint, i))) <= @as(c_uint, 30)) : (i +%= 1) {
                                const bit: u8 = @as(u8, @bitCast(@as(i8, @truncate(blk_1: {
                                    const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 1))))), &_fx_flac_crc16_, @as(?*anyopaque, @ptrCast(inst)))));
                                    tmp_ = tmp;
                                    break :blk_1 tmp;
                                }))));
                                _ = &bit;
                                if (@as(c_uint, @bitCast(@as(c_uint, bit))) == @as(c_uint, 1)) {
                                    sfh.*.wasted_bits = i;
                                    break;
                                }
                            }
                        }
                        valid = ((@as(c_int, @intFromBool(valid)) != 0) and (@as(c_uint, @bitCast(@as(c_uint, sfh.*.wasted_bits))) > @as(c_uint, 0))) and (@as(c_int, @bitCast(@as(c_uint, sfh.*.wasted_bits))) < @as(c_int, @bitCast(@as(c_uint, fh.*.sample_size))));
                    }
                    valid = (@as(c_int, @intFromBool(valid)) != 0) and (blk_n >= @as(u32, @bitCast(@as(c_uint, sfh.*.order))));
                    if (!valid) {
                        _ = _fx_flac_handle_err(inst);
                    }
                    break;
                }
            },
            @as(c_uint, @bitCast(@as(c_int, 502))) => {
                {
                    blk[@as(c_uint, 0)] = @as(i32, @bitCast(@as(c_int, @truncate(blk_1: {
                        const tmp = fx_bitstream_try_read_msb_ex(&inst.*.bitstream, bps, &_fx_flac_crc16_, @as(?*anyopaque, @ptrCast(inst)));
                        tmp_ = tmp;
                        break :blk_1 tmp;
                    }))));
                    if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
                        return @as(c_int, 0) != 0;
                    }
                    blk[@as(c_uint, 0)] = @as(i32, @bitCast(@as(c_int, @truncate(@as(i64, @bitCast(@as(c_ulonglong, @as(c_ulong, @bitCast(@as(c_long, blk[@as(c_uint, 0)]))) ^ (@as(c_ulong, 1) << @intCast(@as(c_uint, @bitCast(@as(c_uint, bps))) -% @as(c_uint, 1)))))) - @as(i64, @bitCast(@as(c_ulonglong, @as(c_ulong, 1) << @intCast(@as(c_uint, @bitCast(@as(c_uint, bps))) -% @as(c_uint, 1)))))))));
                    {
                        var i: u16 = 1;
                        _ = &i;
                        while (@as(u32, @bitCast(@as(c_uint, i))) < blk_n) : (i +%= 1) {
                            blk[i] = blk[@as(c_uint, 0)];
                        }
                    }
                    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SUBFRAME_FINALIZE));
                    break;
                }
            },
            @as(c_uint, @bitCast(@as(c_int, 514))), @as(c_uint, @bitCast(@as(c_int, 503))), @as(c_uint, @bitCast(@as(c_int, 505))) => {
                {
                    const n: u32 = if (sfh.*.type == @as(c_uint, @bitCast(SFT_VERBATIM))) blk_n else @as(u32, @bitCast(@as(c_uint, sfh.*.order)));
                    _ = &n;
                    while (@as(u32, @bitCast(@as(c_uint, inst.*.blk_cur))) < n) {
                        blk[inst.*.blk_cur] = @as(i32, @bitCast(@as(c_int, @truncate(blk_1: {
                            const tmp = fx_bitstream_try_read_msb_ex(&inst.*.bitstream, bps, &_fx_flac_crc16_, @as(?*anyopaque, @ptrCast(inst)));
                            tmp_ = tmp;
                            break :blk_1 tmp;
                        }))));
                        if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
                            return @as(c_int, 0) != 0;
                        }
                        blk[inst.*.blk_cur] = @as(i32, @bitCast(@as(c_int, @truncate(@as(i64, @bitCast(@as(c_ulonglong, @as(c_ulong, @bitCast(@as(c_long, blk[inst.*.blk_cur]))) ^ (@as(c_ulong, 1) << @intCast(@as(c_uint, @bitCast(@as(c_uint, bps))) -% @as(c_uint, 1)))))) - @as(i64, @bitCast(@as(c_ulonglong, @as(c_ulong, 1) << @intCast(@as(c_uint, @bitCast(@as(c_uint, bps))) -% @as(c_uint, 1)))))))));
                        inst.*.blk_cur +%= 1;
                    }
                    inst.*.priv_state = @as(c_uint, @bitCast(@as(c_int, @bitCast(inst.*.priv_state)))) +% @as(c_uint, 1);
                    break;
                }
            },
            @as(c_uint, @bitCast(@as(c_int, 506))) => {
                {
                    if (!fx_bitstream_can_read(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 9))))))) {
                        return @as(c_int, 0) != 0;
                    }
                    const prec: u8 = @as(u8, @bitCast(@as(i8, @truncate(blk_1: {
                        const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 4))))), &_fx_flac_crc16_, @as(?*anyopaque, @ptrCast(inst)))));
                        tmp_ = tmp;
                        break :blk_1 tmp;
                    }))));
                    _ = &prec;
                    const shift: u8 = @as(u8, @bitCast(@as(i8, @truncate(blk_1: {
                        const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 5))))), &_fx_flac_crc16_, @as(?*anyopaque, @ptrCast(inst)))));
                        tmp_ = tmp;
                        break :blk_1 tmp;
                    }))));
                    _ = &shift;
                    if (@as(c_uint, @bitCast(@as(c_uint, prec))) == @as(c_uint, 15)) {
                        return _fx_flac_handle_err(inst);
                    }
                    sfh.*.lpc_prec = @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, @bitCast(@as(c_uint, prec))) +% @as(c_uint, 1)))));
                    sfh.*.lpc_shift = @as(i8, @bitCast(@as(i8, @truncate(@as(i64, @bitCast(@as(c_ulonglong, @as(c_ulong, @bitCast(@as(c_ulong, shift))) ^ (@as(c_ulong, 1) << @intCast(@as(c_uint, 5) -% @as(c_uint, 1)))))) - @as(i64, @bitCast(@as(c_ulonglong, @as(c_ulong, 1) << @intCast(@as(c_uint, 5) -% @as(c_uint, 1)))))))));
                    if (@as(c_int, @bitCast(@as(c_int, sfh.*.lpc_shift))) < @as(c_int, 0)) {
                        return _fx_flac_handle_err(inst);
                    }
                    inst.*.coef_cur = 0;
                    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SUBFRAME_LPC_COEFFS));
                    break;
                }
            },
            @as(c_uint, @bitCast(@as(c_int, 507))) => {
                while (@as(c_int, @bitCast(@as(c_uint, inst.*.coef_cur))) < @as(c_int, @bitCast(@as(c_uint, sfh.*.order)))) {
                    var coef: u32 = @as(u32, @bitCast(@as(c_int, @truncate(blk_1: {
                        const tmp = fx_bitstream_try_read_msb_ex(&inst.*.bitstream, sfh.*.lpc_prec, &_fx_flac_crc16_, @as(?*anyopaque, @ptrCast(inst)));
                        tmp_ = tmp;
                        break :blk_1 tmp;
                    }))));
                    _ = &coef;
                    if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
                        return @as(c_int, 0) != 0;
                    }
                    sfh.*.lpc_coeffs[inst.*.coef_cur] = @as(i32, @bitCast(@as(c_int, @truncate(@as(i64, @bitCast(@as(c_ulonglong, @as(c_ulong, @bitCast(@as(c_ulong, coef))) ^ (@as(c_ulong, 1) << @intCast(@as(c_uint, @bitCast(@as(c_uint, sfh.*.lpc_prec))) -% @as(c_uint, 1)))))) - @as(i64, @bitCast(@as(c_ulonglong, @as(c_ulong, 1) << @intCast(@as(c_uint, @bitCast(@as(c_uint, sfh.*.lpc_prec))) -% @as(c_uint, 1)))))))));
                    inst.*.coef_cur +%= 1;
                }
                inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SUBFRAME_LPC_RESIDUAL));
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 504))), @as(c_uint, @bitCast(@as(c_int, 508))) => {
                {
                    if (!fx_bitstream_can_read(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 6))))))) {
                        return @as(c_int, 0) != 0;
                    }
                    sfh.*.residual_method = @as(c_uint, @bitCast(@as(c_int, @truncate(blk_1: {
                        const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 2))))), &_fx_flac_crc16_, @as(?*anyopaque, @ptrCast(inst)))));
                        tmp_ = tmp;
                        break :blk_1 tmp;
                    }))));
                    if (sfh.*.residual_method > @as(c_uint, @bitCast(RES_RICE2))) {
                        return _fx_flac_handle_err(inst);
                    }
                    sfh.*.rice_partition_order = @as(u8, @bitCast(@as(i8, @truncate(blk_1: {
                        const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 4))))), &_fx_flac_crc16_, @as(?*anyopaque, @ptrCast(inst)))));
                        tmp_ = tmp;
                        break :blk_1 tmp;
                    }))));
                    inst.*.partition_cur = 0;
                    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SUBFRAME_RICE_INIT));
                    break;
                }
            },
            @as(c_uint, @bitCast(@as(c_int, 509))) => {
                {
                    if (!fx_bitstream_can_read(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 10))))))) {
                        return @as(c_int, 0) != 0;
                    }
                    var n_bits: u8 = @as(u8, @bitCast(@as(u8, @truncate(if (sfh.*.residual_method == @as(c_uint, @bitCast(RES_RICE))) @as(c_uint, 4) else @as(c_uint, 5)))));
                    _ = &n_bits;
                    sfh.*.rice_parameter = @as(u8, @bitCast(@as(i8, @truncate(blk_1: {
                        const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, n_bits, &_fx_flac_crc16_, @as(?*anyopaque, @ptrCast(inst)))));
                        tmp_ = tmp;
                        break :blk_1 tmp;
                    }))));
                    if (@as(c_uint, @bitCast(@as(c_uint, sfh.*.rice_parameter))) == ((@as(c_uint, 1) << @intCast(@as(c_int, @bitCast(@as(c_uint, n_bits))))) -% @as(c_uint, 1))) {
                        sfh.*.rice_parameter = @as(u8, @bitCast(@as(i8, @truncate(blk_1: {
                            const tmp = @as(i64, @bitCast(fx_bitstream_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 5))))), &_fx_flac_crc16_, @as(?*anyopaque, @ptrCast(inst)))));
                            tmp_ = tmp;
                            break :blk_1 tmp;
                        }))));
                        inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SUBFRAME_RICE_VERBATIM));
                    } else {
                        inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SUBFRAME_RICE_UNARY));
                        inst.*.rice_unary_counter = 0;
                    }
                    inst.*.partition_sample = @as(u16, @bitCast(@as(c_ushort, @truncate(blk_n >> @intCast(@as(c_int, @bitCast(@as(c_uint, sfh.*.rice_partition_order))))))));
                    if (@as(c_uint, @bitCast(@as(c_uint, inst.*.partition_cur))) == @as(c_uint, 0)) {
                        if (@as(c_int, @bitCast(@as(c_uint, inst.*.partition_sample))) < @as(c_int, @bitCast(@as(c_uint, sfh.*.order)))) {
                            return _fx_flac_handle_err(inst);
                        }
                        inst.*.partition_sample -%= @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, sfh.*.order)))))));
                    }
                    if (@as(u32, @bitCast(@as(c_int, @bitCast(@as(c_uint, inst.*.partition_sample))) + @as(c_int, @bitCast(@as(c_uint, inst.*.blk_cur))))) > blk_n) {
                        return _fx_flac_handle_err(inst);
                    }
                    break;
                }
            },
            @as(c_uint, @bitCast(@as(c_int, 510))), @as(c_uint, @bitCast(@as(c_int, 511))) => {
                while (@as(c_uint, @bitCast(@as(c_uint, inst.*.partition_sample))) > @as(c_uint, 0)) {
                    if (inst.*.priv_state == @as(c_uint, @bitCast(FLAC_SUBFRAME_RICE_UNARY))) {
                        while (true) {
                            const bit: u8 = @as(u8, @bitCast(@as(i8, @truncate(blk_1: {
                                const tmp = fx_bitstream_try_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 1))))), &_fx_flac_crc16_, @as(?*anyopaque, @ptrCast(inst)));
                                tmp_ = tmp;
                                break :blk_1 tmp;
                            }))));
                            _ = &bit;
                            if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
                                return @as(c_int, 0) != 0;
                            }
                            if (bit != 0) {
                                break;
                            }
                            inst.*.rice_unary_counter +%= 1;
                        }
                    }
                    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SUBFRAME_RICE));
                    var r: u32 = 0;
                    _ = &r;
                    if (@as(c_uint, @bitCast(@as(c_uint, sfh.*.rice_parameter))) > @as(c_uint, 0)) {
                        r = @as(u32, @bitCast(@as(c_int, @truncate(blk_1: {
                            const tmp = fx_bitstream_try_read_msb_ex(&inst.*.bitstream, sfh.*.rice_parameter, &_fx_flac_crc16_, @as(?*anyopaque, @ptrCast(inst)));
                            tmp_ = tmp;
                            break :blk_1 tmp;
                        }))));
                        if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
                            return @as(c_int, 0) != 0;
                        }
                    }
                    const q: u16 = inst.*.rice_unary_counter;
                    _ = &q;
                    const val: u32 = @as(u32, @bitCast(@as(c_int, @bitCast(@as(c_uint, q))) << @intCast(@as(c_int, @bitCast(@as(c_uint, sfh.*.rice_parameter)))))) | r;
                    _ = &val;
                    if ((val & @as(u32, @bitCast(@as(c_int, 1)))) != 0) {
                        blk[inst.*.blk_cur] = -@as(i32, @bitCast(val >> @intCast(1))) - @as(c_int, 1);
                    } else {
                        blk[inst.*.blk_cur] = @as(i32, @bitCast(val >> @intCast(1)));
                    }
                    inst.*.rice_unary_counter = 0;
                    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SUBFRAME_RICE_UNARY));
                    inst.*.blk_cur +%= 1;
                    inst.*.partition_sample -%= 1;
                }
                inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SUBFRAME_RICE_FINALIZE));
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 512))) => {
                {
                    const bps_1: u8 = sfh.*.rice_parameter;
                    _ = &bps_1;
                    while (@as(c_uint, @bitCast(@as(c_uint, inst.*.partition_sample))) > @as(c_uint, 0)) {
                        blk[inst.*.blk_cur] = @as(i32, @bitCast(@as(c_int, @truncate(if (@as(c_int, @bitCast(@as(c_uint, bps_1))) == @as(c_int, 0)) @as(i64, @bitCast(@as(c_ulonglong, @as(c_uint, 0)))) else blk_1: {
                            const tmp = fx_bitstream_try_read_msb_ex(&inst.*.bitstream, bps_1, &_fx_flac_crc16_, @as(?*anyopaque, @ptrCast(inst)));
                            tmp_ = tmp;
                            break :blk_1 tmp;
                        }))));
                        if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
                            return @as(c_int, 0) != 0;
                        }
                        blk[inst.*.blk_cur] = @as(i32, @bitCast(@as(c_int, @truncate(@as(i64, @bitCast(@as(c_ulonglong, @as(c_ulong, @bitCast(@as(c_long, blk[inst.*.blk_cur]))) ^ (@as(c_ulong, 1) << @intCast(@as(c_uint, @bitCast(@as(c_uint, bps_1))) -% @as(c_uint, 1)))))) - @as(i64, @bitCast(@as(c_ulonglong, @as(c_ulong, 1) << @intCast(@as(c_uint, @bitCast(@as(c_uint, bps_1))) -% @as(c_uint, 1)))))))));
                        inst.*.blk_cur +%= 1;
                        inst.*.partition_sample -%= 1;
                    }
                    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SUBFRAME_RICE_FINALIZE));
                    break;
                }
            },
            @as(c_uint, @bitCast(@as(c_int, 513))) => {
                inst.*.partition_cur +%= 1;
                if (@as(c_uint, @bitCast(@as(c_uint, inst.*.partition_cur))) == (@as(c_uint, 1) << @intCast(@as(c_int, @bitCast(@as(c_uint, sfh.*.rice_partition_order)))))) {
                    _fx_flac_restore_lpc_signal(blk, blk_n, sfh.*.lpc_coeffs, sfh.*.order, sfh.*.lpc_shift);
                    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SUBFRAME_FINALIZE));
                } else {
                    inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SUBFRAME_RICE_INIT));
                }
                break;
            },
            @as(c_uint, @bitCast(@as(c_int, 515))) => {
                {
                    if (sfh.*.wasted_bits != 0) {
                        var shift: u8 = sfh.*.wasted_bits;
                        _ = &shift;
                        {
                            var i: u16 = 0;
                            _ = &i;
                            while (@as(u32, @bitCast(@as(c_uint, i))) < blk_n) : (i +%= 1) {
                                blk[i] = blk[i] * (@as(c_int, 1) << @intCast(@as(c_int, @bitCast(@as(c_uint, shift)))));
                            }
                        }
                    }
                    inst.*.chan_cur +%= 1;
                    if (@as(c_int, @bitCast(@as(c_uint, inst.*.chan_cur))) < @as(c_int, @bitCast(@as(c_uint, fh.*.channel_count)))) {
                        inst.*.priv_state = @as(c_uint, @bitCast(FLAC_SUBFRAME_HEADER));
                        break;
                    }
                    {
                        var n_: u8 = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, inst.*.bitstream.pos))) & @as(c_int, 7)))));
                        _ = &n_;
                        if (n_ != 0) {
                            _ = blk_1: {
                                const tmp = fx_bitstream_try_read_msb_ex(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 8) -% @as(c_uint, @bitCast(@as(c_uint, n_))))))), &_fx_flac_crc16_, @as(?*anyopaque, @ptrCast(inst)));
                                tmp_ = tmp;
                                break :blk_1 tmp;
                            };
                            if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
                                return @as(c_int, 0) != 0;
                            }
                        }
                    }
                    var crc16: u16 = @as(u16, @bitCast(@as(c_short, @truncate(blk_1: {
                        const tmp = fx_bitstream_try_read_msb(&inst.*.bitstream, @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 16))))));
                        tmp_ = tmp;
                        break :blk_1 tmp;
                    }))));
                    _ = &crc16;
                    if (tmp_ < @as(i64, @bitCast(@as(c_longlong, @as(c_int, 0))))) {
                        return @as(c_int, 0) != 0;
                    }
                    if (@as(c_int, @bitCast(@as(c_uint, crc16))) != @as(c_int, @bitCast(@as(c_uint, inst.*.crc16)))) {
                        return _fx_flac_handle_err(inst);
                    }
                    var c1: [*c]i32 = inst.*.blkbuf[@as(c_uint, @intCast(@as(c_int, 0)))];
                    _ = &c1;
                    var c2: [*c]i32 = inst.*.blkbuf[@as(c_uint, @intCast(@as(c_int, 1)))];
                    _ = &c2;
                    while (true) {
                        switch (fh.*.channel_assignment) {
                            @as(c_uint, @bitCast(@as(c_int, 8))) => {
                                _fx_flac_post_process_left_side(c1, c2, blk_n);
                                break;
                            },
                            @as(c_uint, @bitCast(@as(c_int, 9))) => {
                                _fx_flac_post_process_right_side(c1, c2, blk_n);
                                break;
                            },
                            @as(c_uint, @bitCast(@as(c_int, 10))) => {
                                _fx_flac_post_process_mid_side(c1, c2, blk_n);
                                break;
                            },
                            else => break,
                        }
                        break;
                    }
                    var shift: u8 = @as(u8, @bitCast(@as(u8, @truncate(@as(c_uint, 32) -% @as(c_uint, @bitCast(@as(c_uint, fh.*.sample_size)))))));
                    _ = &shift;
                    if (shift != 0) {
                        {
                            var c: u8 = 0;
                            _ = &c;
                            while (@as(c_int, @bitCast(@as(c_uint, c))) < @as(c_int, @bitCast(@as(c_uint, fh.*.channel_count)))) : (c +%= 1) {
                                var blk_1: [*c]i32 = inst.*.blkbuf[c];
                                _ = &blk_1;
                                {
                                    var i: u16 = 0;
                                    _ = &i;
                                    while (@as(u32, @bitCast(@as(c_uint, i))) < blk_n) : (i +%= 1) {
                                        blk_1[i] = blk_1[i] * (@as(c_int, 1) << @intCast(@as(c_int, @bitCast(@as(c_uint, shift)))));
                                    }
                                }
                            }
                        }
                    }
                    inst.*.blk_cur = 0;
                    inst.*.chan_cur = 0;
                    inst.*.state = FLAC_DECODED_FRAME;
                    break;
                }
            },
            else => {
                inst.*.state = FLAC_ERR;
                break;
            },
        }
        break;
    }
    return @as(c_int, 1) != 0;
}
pub fn _fx_flac_process_decoded_frame(arg_inst: *fx_flac_t, arg_out: [*c]i32, arg_out_len: [*c]u32) callconv(.c) bool {
    var inst = arg_inst;
    _ = &inst;
    var out = arg_out;
    _ = &out;
    var out_len = arg_out_len;
    _ = &out_len;
    var fh: [*c]const fx_flac_frame_header_t = inst.*.frame_header;
    _ = &fh;
    const cc: u8 = fh.*.channel_count;
    _ = &cc;
    var n_smpls_rem: u32 = (((fh.*.block_size -% @as(u32, @bitCast(@as(c_uint, inst.*.blk_cur)))) -% @as(c_uint, 1)) *% @as(c_uint, @bitCast(@as(c_uint, cc)))) +% @as(c_uint, @bitCast(@as(c_int, @bitCast(@as(c_uint, cc))) - @as(c_int, @bitCast(@as(c_uint, inst.*.chan_cur)))));
    _ = &n_smpls_rem;
    if (n_smpls_rem > out_len.*) {
        n_smpls_rem = out_len.*;
    }
    var tar: u32 = 0;
    _ = &tar;
    while (tar < n_smpls_rem) {
        out[tar] = inst.*.blkbuf[inst.*.chan_cur][inst.*.blk_cur];
        inst.*.chan_cur +%= 1;
        if (@as(c_int, @bitCast(@as(c_uint, inst.*.chan_cur))) == @as(c_int, @bitCast(@as(c_uint, cc)))) {
            inst.*.chan_cur = 0;
            inst.*.blk_cur +%= 1;
        }
        tar +%= 1;
    }
    out_len.* = tar;
    if (@as(u32, @bitCast(@as(c_uint, inst.*.blk_cur))) == fh.*.block_size) {
        inst.*.state = FLAC_END_OF_FRAME;
        return @as(c_int, 1) != 0;
    }
    return @as(c_int, 0) != 0;
}
