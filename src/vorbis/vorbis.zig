const std = @import("std");

pub const stb_vorbis_alloc = extern struct {
    alloc_buffer: [*c]u8 = std.mem.zeroes([*c]u8),
    alloc_buffer_length_in_bytes: c_int = std.mem.zeroes(c_int),
};
pub const VORBIS__no_error: c_int = 0;
pub const VORBIS_need_more_data: c_int = 1;
pub const VORBIS_invalid_api_mixing: c_int = 2;
pub const VORBIS_outofmem: c_int = 3;
pub const VORBIS_feature_not_supported: c_int = 4;
pub const VORBIS_too_many_channels: c_int = 5;
pub const VORBIS_file_open_failure: c_int = 6;
pub const VORBIS_seek_without_length: c_int = 7;
pub const VORBIS_unexpected_eof: c_int = 10;
pub const VORBIS_seek_invalid: c_int = 11;
pub const VORBIS_invalid_setup: c_int = 20;
pub const VORBIS_invalid_stream: c_int = 21;
pub const VORBIS_missing_capture_pattern: c_int = 30;
pub const VORBIS_invalid_stream_structure_version: c_int = 31;
pub const VORBIS_continued_packet_flag_invalid: c_int = 32;
pub const VORBIS_incorrect_stream_serial_number: c_int = 33;
pub const VORBIS_invalid_first_page: c_int = 34;
pub const VORBIS_bad_packet_type: c_int = 35;
pub const VORBIS_cant_find_last_page: c_int = 36;
pub const VORBIS_seek_failed: c_int = 37;
pub const VORBIS_ogg_skeleton_not_supported: c_int = 38;
pub const enum_STBVorbisError = u32;
pub const uint16 = c_ushort;
pub const int16 = c_short;
pub const struct_stb_vorbis = extern struct {
    sample_rate: u32 = std.mem.zeroes(u32),
    channels: c_int = std.mem.zeroes(c_int),
    setup_memory_required: u32 = std.mem.zeroes(u32),
    temp_memory_required: u32 = std.mem.zeroes(u32),
    setup_temp_memory_required: u32 = std.mem.zeroes(u32),
    vendor: [*c]u8 = std.mem.zeroes([*c]u8),
    comment_list_length: c_int = std.mem.zeroes(c_int),
    comment_list: [*c][*c]u8 = std.mem.zeroes([*c][*c]u8),
    f_start: u32 = std.mem.zeroes(u32),
    close_on_free: c_int = std.mem.zeroes(c_int),
    stream: [*c]u8 = std.mem.zeroes([*c]u8),
    stream_start: [*c]u8 = std.mem.zeroes([*c]u8),
    stream_end: [*c]u8 = std.mem.zeroes([*c]u8),
    stream_len: u32 = std.mem.zeroes(u32),
    push_mode: u8 = std.mem.zeroes(u8),
    first_audio_page_offset: u32 = std.mem.zeroes(u32),
    p_first: ProbedPage = std.mem.zeroes(ProbedPage),
    p_last: ProbedPage = std.mem.zeroes(ProbedPage),
    alloc: stb_vorbis_alloc = std.mem.zeroes(stb_vorbis_alloc),
    setup_offset: c_int = std.mem.zeroes(c_int),
    temp_offset: c_int = std.mem.zeroes(c_int),
    eof: c_int = std.mem.zeroes(c_int),
    @"error": enum_STBVorbisError = std.mem.zeroes(enum_STBVorbisError),
    blocksize: [2]c_int = std.mem.zeroes([2]c_int),
    blocksize_0: c_int = std.mem.zeroes(c_int),
    blocksize_1: c_int = std.mem.zeroes(c_int),
    codebook_count: c_int = std.mem.zeroes(c_int),
    codebooks: [*c]Codebook = std.mem.zeroes([*c]Codebook),
    floor_count: c_int = std.mem.zeroes(c_int),
    floor_types: [64]uint16 = std.mem.zeroes([64]uint16),
    floor_config: [*c]Floor = std.mem.zeroes([*c]Floor),
    residue_count: c_int = std.mem.zeroes(c_int),
    residue_types: [64]uint16 = std.mem.zeroes([64]uint16),
    residue_config: [*c]Residue = std.mem.zeroes([*c]Residue),
    mapping_count: c_int = std.mem.zeroes(c_int),
    mapping: [*c]Mapping = std.mem.zeroes([*c]Mapping),
    mode_count: c_int = std.mem.zeroes(c_int),
    mode_config: [64]Mode = std.mem.zeroes([64]Mode),
    total_samples: u32 = std.mem.zeroes(u32),
    channel_buffers: [16][*c]f32 = std.mem.zeroes([16][*c]f32),
    outputs: [16][*c]f32 = std.mem.zeroes([16][*c]f32),
    previous_window: [16][*c]f32 = std.mem.zeroes([16][*c]f32),
    previous_length: c_int = std.mem.zeroes(c_int),
    finalY: [16][*c]int16 = std.mem.zeroes([16][*c]int16),
    current_loc: u32 = std.mem.zeroes(u32),
    current_loc_valid: c_int = std.mem.zeroes(c_int),
    A: [2][*c]f32 = std.mem.zeroes([2][*c]f32),
    B: [2][*c]f32 = std.mem.zeroes([2][*c]f32),
    C: [2][*c]f32 = std.mem.zeroes([2][*c]f32),
    window: [2][*c]f32 = std.mem.zeroes([2][*c]f32),
    bit_reverse: [2][*c]uint16 = std.mem.zeroes([2][*c]uint16),
    serial: u32 = std.mem.zeroes(u32),
    last_page: c_int = std.mem.zeroes(c_int),
    segment_count: c_int = std.mem.zeroes(c_int),
    segments: [255]u8 = std.mem.zeroes([255]u8),
    page_flag: u8 = std.mem.zeroes(u8),
    bytes_in_seg: u8 = std.mem.zeroes(u8),
    first_decode: u8 = std.mem.zeroes(u8),
    next_seg: c_int = std.mem.zeroes(c_int),
    last_seg: c_int = std.mem.zeroes(c_int),
    last_seg_which: c_int = std.mem.zeroes(c_int),
    acc: u32 = std.mem.zeroes(u32),
    valid_bits: c_int = std.mem.zeroes(c_int),
    packet_bytes: c_int = std.mem.zeroes(c_int),
    end_seg_with_known_loc: c_int = std.mem.zeroes(c_int),
    known_loc_for_packet: u32 = std.mem.zeroes(u32),
    discard_samples_deferred: c_int = std.mem.zeroes(c_int),
    samples_output: u32 = std.mem.zeroes(u32),
    page_crc_tests: c_int = std.mem.zeroes(c_int),
    scan: [4]CRCscan = std.mem.zeroes([4]CRCscan),
    channel_buffer_start: c_int = std.mem.zeroes(c_int),
    channel_buffer_end: c_int = std.mem.zeroes(c_int),
};
pub const stb_vorbis = struct_stb_vorbis;
pub const stb_vorbis_info = extern struct {
    sample_rate: u32 = std.mem.zeroes(u32),
    channels: c_int = std.mem.zeroes(c_int),
    setup_memory_required: u32 = std.mem.zeroes(u32),
    setup_temp_memory_required: u32 = std.mem.zeroes(u32),
    temp_memory_required: u32 = std.mem.zeroes(u32),
    max_frame_size: c_int = std.mem.zeroes(c_int),
};
pub const stb_vorbis_comment = extern struct {
    vendor: [*c]u8 = std.mem.zeroes([*c]u8),
    comment_list_length: c_int = std.mem.zeroes(c_int),
    comment_list: [*c][*c]u8 = std.mem.zeroes([*c][*c]u8),
};
pub export fn stb_vorbis_get_info(arg_f: [*c]stb_vorbis) stb_vorbis_info {
    var f = arg_f;
    _ = &f;
    var d: stb_vorbis_info = undefined;
    _ = &d;
    d.channels = f.*.channels;
    d.sample_rate = f.*.sample_rate;
    d.setup_memory_required = f.*.setup_memory_required;
    d.setup_temp_memory_required = f.*.setup_temp_memory_required;
    d.temp_memory_required = f.*.temp_memory_required;
    d.max_frame_size = f.*.blocksize_1 >> @intCast(1);
    return d;
}
pub export fn stb_vorbis_get_comment(arg_f: [*c]stb_vorbis) stb_vorbis_comment {
    var f = arg_f;
    _ = &f;
    var d: stb_vorbis_comment = undefined;
    _ = &d;
    d.vendor = f.*.vendor;
    d.comment_list_length = f.*.comment_list_length;
    d.comment_list = f.*.comment_list;
    return d;
}
pub export fn stb_vorbis_get_error(arg_f: [*c]stb_vorbis) c_int {
    var f = arg_f;
    _ = &f;
    var e: c_int = @as(c_int, @bitCast(f.*.@"error"));
    _ = &e;
    f.*.@"error" = @as(u32, @bitCast(VORBIS__no_error));
    return e;
}
pub export fn stb_vorbis_close(arg_p: [*c]stb_vorbis) void {
    var p = arg_p;
    _ = &p;
    if (p == @as([*c]stb_vorbis, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) return;
    vorbis_deinit(p);
    setup_free(p, @as(?*anyopaque, @ptrCast(p)));
}
pub export fn stb_vorbis_get_sample_offset(arg_f: [*c]stb_vorbis) c_int {
    var f = arg_f;
    _ = &f;
    if (f.*.current_loc_valid != 0) return @as(c_int, @bitCast(f.*.current_loc)) else return -@as(c_int, 1);
    return 0;
}
pub export fn stb_vorbis_get_file_offset(arg_f: [*c]stb_vorbis) u32 {
    var f = arg_f;
    _ = &f;
    if (f.*.push_mode != 0) return 0;
    return @as(u32, @bitCast(@as(c_int, @truncate(@divExact(@as(c_long, @bitCast(@intFromPtr(f.*.stream) -% @intFromPtr(f.*.stream_start))), @sizeOf(u8))))));
}
pub fn stb_vorbis_open_pushdata(arg_data: [*c]const u8, arg_data_len: c_int, arg_data_used: [*c]c_int, arg_error_1: [*c]c_int, arg_alloc: [*c]const stb_vorbis_alloc) ![*c]stb_vorbis {
    var data = arg_data;
    _ = &data;
    var data_len = arg_data_len;
    _ = &data_len;
    var data_used = arg_data_used;
    _ = &data_used;
    var error_1 = arg_error_1;
    _ = &error_1;
    var alloc = arg_alloc;
    _ = &alloc;
    var f: [*c]stb_vorbis = undefined;
    _ = &f;
    var p: stb_vorbis = undefined;
    _ = &p;
    vorbis_init(&p, alloc);
    p.stream = @as([*c]u8, @ptrCast(@constCast(@volatileCast(data))));
    p.stream_end = @as([*c]u8, @ptrCast(@constCast(@volatileCast(data)))) + @as(usize, @bitCast(@as(isize, @intCast(data_len))));
    p.push_mode = 1;
    if (!(try start_decoder(&p) != 0)) {
        if (p.eof != 0) {
            error_1.* = VORBIS_need_more_data;
        } else {
            error_1.* = @as(c_int, @bitCast(p.@"error"));
        }
        vorbis_deinit(&p);
        return null;
    }
    f = vorbis_alloc(&p);
    if (f != null) {
        f.* = p;
        data_used.* = @as(c_int, @bitCast(@as(c_int, @truncate(@divExact(@as(c_long, @bitCast(@intFromPtr(f.*.stream) -% @intFromPtr(data))), @sizeOf(u8))))));
        error_1.* = 0;
        return f;
    } else {
        vorbis_deinit(&p);
        return null;
    }
    return null;
}
pub export fn stb_vorbis_decode_frame_pushdata(arg_f: [*c]stb_vorbis, arg_data: [*c]const u8, arg_data_len: c_int, arg_channels: [*c]c_int, arg_output: [*c][*c][*c]f32, arg_samples: [*c]c_int) c_int {
    var f = arg_f;
    _ = &f;
    var data = arg_data;
    _ = &data;
    var data_len = arg_data_len;
    _ = &data_len;
    var channels = arg_channels;
    _ = &channels;
    var output = arg_output;
    _ = &output;
    var samples = arg_samples;
    _ = &samples;
    var i: c_int = undefined;
    _ = &i;
    var len: c_int = undefined;
    _ = &len;
    var right: c_int = undefined;
    _ = &right;
    var left: c_int = undefined;
    _ = &left;
    if (!(f.*.push_mode != 0)) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_api_mixing)));
    if (f.*.page_crc_tests >= @as(c_int, 0)) {
        samples.* = 0;
        return vorbis_search_for_page_pushdata(f, @as([*c]u8, @ptrCast(@constCast(@volatileCast(data)))), data_len);
    }
    f.*.stream = @as([*c]u8, @ptrCast(@constCast(@volatileCast(data))));
    f.*.stream_end = @as([*c]u8, @ptrCast(@constCast(@volatileCast(data)))) + @as(usize, @bitCast(@as(isize, @intCast(data_len))));
    f.*.@"error" = @as(u32, @bitCast(VORBIS__no_error));
    if (!(is_whole_packet_present(f) != 0)) {
        samples.* = 0;
        return 0;
    }
    if (!(vorbis_decode_packet(f, &len, &left, &right) != 0)) {
        var error_1: enum_STBVorbisError = f.*.@"error";
        _ = &error_1;
        if (error_1 == @as(u32, @bitCast(VORBIS_bad_packet_type))) {
            f.*.@"error" = @as(u32, @bitCast(VORBIS__no_error));
            while (get8_packet(f) != -@as(c_int, 1)) if (f.*.eof != 0) break;
            samples.* = 0;
            return @as(c_int, @bitCast(@as(c_int, @truncate(@divExact(@as(c_long, @bitCast(@intFromPtr(f.*.stream) -% @intFromPtr(data))), @sizeOf(u8))))));
        }
        if (error_1 == @as(u32, @bitCast(VORBIS_continued_packet_flag_invalid))) {
            if (f.*.previous_length == @as(c_int, 0)) {
                f.*.@"error" = @as(u32, @bitCast(VORBIS__no_error));
                while (get8_packet(f) != -@as(c_int, 1)) if (f.*.eof != 0) break;
                samples.* = 0;
                return @as(c_int, @bitCast(@as(c_int, @truncate(@divExact(@as(c_long, @bitCast(@intFromPtr(f.*.stream) -% @intFromPtr(data))), @sizeOf(u8))))));
            }
        }
        stb_vorbis_flush_pushdata(f);
        f.*.@"error" = error_1;
        samples.* = 0;
        return 1;
    }
    len = vorbis_finish_frame(f, len, left, right);
    {
        i = 0;
        while (i < f.*.channels) : (i += 1) {
            f.*.outputs[@as(u32, @intCast(i))] = f.*.channel_buffers[@as(u32, @intCast(i))] + @as(usize, @bitCast(@as(isize, @intCast(left))));
        }
    }
    if (channels != null) {
        channels.* = f.*.channels;
    }
    samples.* = len;
    output.* = @as([*c][*c]f32, @ptrCast(@alignCast(&f.*.outputs[@as(usize, @intCast(0))])));
    return @as(c_int, @bitCast(@as(c_int, @truncate(@divExact(@as(c_long, @bitCast(@intFromPtr(f.*.stream) -% @intFromPtr(data))), @sizeOf(u8))))));
}
pub export fn stb_vorbis_flush_pushdata(arg_f: [*c]stb_vorbis) void {
    var f = arg_f;
    _ = &f;
    f.*.previous_length = 0;
    f.*.page_crc_tests = 0;
    f.*.discard_samples_deferred = 0;
    f.*.current_loc_valid = 0;
    f.*.first_decode = 0;
    f.*.samples_output = 0;
    f.*.channel_buffer_start = 0;
    f.*.channel_buffer_end = 0;
}
pub fn stb_vorbis_decode_memory(arg_mem: [*c]const u8, arg_len: c_int, arg_channels: [*c]c_int, arg_sample_rate: [*c]c_int, arg_output: [*c][*c]c_short) !c_int {
    var mem = arg_mem;
    _ = &mem;
    var len = arg_len;
    _ = &len;
    var channels = arg_channels;
    _ = &channels;
    var sample_rate = arg_sample_rate;
    _ = &sample_rate;
    var output = arg_output;
    _ = &output;
    var data_len: c_int = undefined;
    _ = &data_len;
    var offset: c_int = undefined;
    _ = &offset;
    var total: c_int = undefined;
    _ = &total;
    var limit: c_int = undefined;
    _ = &limit;
    var error_1: c_int = undefined;
    _ = &error_1;
    var data: [*c]c_short = undefined;
    _ = &data;
    var v: [*c]stb_vorbis = try stb_vorbis_open_memory(mem, len, &error_1, null);
    _ = &v;
    if (v == @as([*c]stb_vorbis, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) return -@as(c_int, 1);
    limit = v.*.channels * @as(c_int, 4096);
    channels.* = v.*.channels;
    if (sample_rate != null) {
        sample_rate.* = @as(c_int, @bitCast(v.*.sample_rate));
    }
    offset = blk: {
        const tmp = @as(c_int, 0);
        data_len = tmp;
        break :blk tmp;
    };
    total = limit;
    data = @as([*c]c_short, @ptrCast(@alignCast(malloc(@as(c_ulong, @bitCast(@as(c_long, total))) *% @sizeOf(c_short)))));
    if (data == @as([*c]c_short, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
        stb_vorbis_close(v);
        return -@as(c_int, 2);
    }
    while (true) {
        var n: c_int = stb_vorbis_get_frame_short_interleaved(v, v.*.channels, data + @as(usize, @bitCast(@as(isize, @intCast(offset)))), total - offset);
        _ = &n;
        if (n == @as(c_int, 0)) break;
        data_len += n;
        offset += n * v.*.channels;
        if ((offset + limit) > total) {
            var data2: [*c]c_short = undefined;
            _ = &data2;
            total *= @as(c_int, 2);
            data2 = @as([*c]c_short, @ptrCast(@alignCast(realloc(@as(?*anyopaque, @ptrCast(data)), @as(c_ulong, @bitCast(@as(c_long, total))) *% @sizeOf(c_short)))));
            if (data2 == @as([*c]c_short, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) {
                free(@as(?*anyopaque, @ptrCast(data)));
                stb_vorbis_close(v);
                return -@as(c_int, 2);
            }
            data = data2;
        }
    }
    output.* = data;
    stb_vorbis_close(v);
    return data_len;
}
pub fn stb_vorbis_open_memory(arg_data: [*c]const u8, arg_len: c_int, arg_error_1: [*c]c_int, arg_alloc: [*c]const stb_vorbis_alloc) ![*c]stb_vorbis {
    var data = arg_data;
    _ = &data;
    var len = arg_len;
    _ = &len;
    var error_1 = arg_error_1;
    _ = &error_1;
    var alloc = arg_alloc;
    _ = &alloc;
    var f: [*c]stb_vorbis = undefined;
    _ = &f;
    var p: stb_vorbis = undefined;
    _ = &p;
    if (!(data != null)) {
        if (error_1 != null) {
            error_1.* = VORBIS_unexpected_eof;
        }
        return null;
    }
    if (len >= 4) {}
    vorbis_init(&p, alloc);
    p.stream = @as([*c]u8, @ptrCast(@constCast(@volatileCast(data))));
    p.stream_end = @as([*c]u8, @ptrCast(@constCast(@volatileCast(data)))) + @as(usize, @bitCast(@as(isize, @intCast(len))));
    p.stream_start = p.stream;
    p.stream_len = @as(u32, @bitCast(len));
    p.push_mode = 0;
    if (try start_decoder(&p) != 0) {
        f = vorbis_alloc(&p);
        if (f != null) {
            f.* = p;
            _ = vorbis_pump_first_frame(f);
            if (error_1 != null) {
                error_1.* = VORBIS__no_error;
            }
            return f;
        }
    }
    if (error_1 != null) {
        error_1.* = @as(c_int, @bitCast(p.@"error"));
    }
    vorbis_deinit(&p);
    return null;
}
pub export fn stb_vorbis_stream_length_in_samples(arg_f: [*c]stb_vorbis) u32 {
    var f = arg_f;
    _ = &f;
    if (IS_PUSH_MODE(f) != 0) {
        _ = @"error"(f, @as(u32, @bitCast(VORBIS_invalid_api_mixing)));
        return 0;
    }
    const sample_unknown: u32 = @as(u32, SAMPLE_unknown);
    if (f.*.total_samples == 0) {
        const restore_offset = stb_vorbis_get_file_offset(f);
        defer _ = set_file_offset(f, restore_offset);
        const previous_safe: u32 = if ((f.*.stream_len >= 65536) and ((f.*.stream_len - 65536) >= f.*.first_audio_page_offset))
            f.*.stream_len - 65536
        else
            f.*.first_audio_page_offset;
        _ = set_file_offset(f, previous_safe);
        var end: u32 = undefined;
        _ = &end;
        var last: u32 = undefined;
        _ = &last;
        if (vorbis_find_page(f, &end, &last) == 0) {
            f.*.@"error" = @as(u32, @bitCast(VORBIS_cant_find_last_page));
            f.*.total_samples = sample_unknown;
            _ = set_file_offset(f, restore_offset);
            return 0;
        }
        var last_page_loc = stb_vorbis_get_file_offset(f);
        while (last == 0) {
            _ = set_file_offset(f, end);
            if (vorbis_find_page(f, &end, &last) == 0) {
                break;
            }
            last_page_loc = stb_vorbis_get_file_offset(f);
        }
        _ = set_file_offset(f, last_page_loc);
        var header: [6]u8 = undefined;
        _ = getn(f, @as([*c]u8, @ptrCast(&header)), 6);
        var lo: u32 = get32(f);
        const hi: u32 = get32(f);
        if ((lo == sample_unknown) and (hi == sample_unknown)) {
            f.*.@"error" = @as(u32, @bitCast(VORBIS_cant_find_last_page));
            f.*.total_samples = sample_unknown;
            _ = set_file_offset(f, restore_offset);
            return 0;
        }
        if (hi != 0) {
            lo = @as(u32, 0xfffffffe);
        }
        f.*.total_samples = lo;
        f.*.p_last.page_start = last_page_loc;
        f.*.p_last.page_end = end;
        f.*.p_last.last_decoded_sample = lo;
    }
    if (f.*.total_samples == sample_unknown) return 0;
    return f.*.total_samples;
}
pub export fn stb_vorbis_get_frame_float(arg_f: [*c]stb_vorbis, arg_channels: [*c]c_int, arg_output: [*c][*c][*c]f32) c_int {
    var f = arg_f;
    _ = &f;
    var channels = arg_channels;
    _ = &channels;
    var output = arg_output;
    _ = &output;
    var len: c_int = undefined;
    _ = &len;
    var right: c_int = undefined;
    _ = &right;
    var left: c_int = undefined;
    _ = &left;
    var i: c_int = undefined;
    _ = &i;
    if (f.*.push_mode != 0) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_api_mixing)));
    if (!(vorbis_decode_packet(f, &len, &left, &right) != 0)) {
        f.*.channel_buffer_start = blk: {
            const tmp = @as(c_int, 0);
            f.*.channel_buffer_end = tmp;
            break :blk tmp;
        };
        return 0;
    }
    len = vorbis_finish_frame(f, len, left, right);
    {
        i = 0;
        while (i < f.*.channels) : (i += 1) {
            f.*.outputs[@as(u32, @intCast(i))] = f.*.channel_buffers[@as(u32, @intCast(i))] + @as(usize, @bitCast(@as(isize, @intCast(left))));
        }
    }
    f.*.channel_buffer_start = left;
    f.*.channel_buffer_end = left + len;
    if (channels != null) {
        channels.* = f.*.channels;
    }
    if (output != null) {
        output.* = @as([*c][*c]f32, @ptrCast(@alignCast(&f.*.outputs[@as(usize, @intCast(0))])));
    }
    return len;
}
pub export fn stb_vorbis_get_frame_short_interleaved(arg_f: [*c]stb_vorbis, arg_num_c: c_int, arg_buffer: [*c]c_short, arg_num_shorts: c_int) c_int {
    var f = arg_f;
    _ = &f;
    var num_c = arg_num_c;
    _ = &num_c;
    var buffer = arg_buffer;
    _ = &buffer;
    var num_shorts = arg_num_shorts;
    _ = &num_shorts;
    var output: [*c][*c]f32 = undefined;
    _ = &output;
    var len: c_int = undefined;
    _ = &len;
    if (num_c == @as(c_int, 1)) return stb_vorbis_get_frame_short(f, num_c, &buffer, num_shorts);
    len = stb_vorbis_get_frame_float(f, null, &output);
    if (len != 0) {
        if ((len * num_c) > num_shorts) {
            len = @divTrunc(num_shorts, num_c);
        }
        convert_channels_short_interleaved(num_c, buffer, f.*.channels, output, @as(c_int, 0), len);
    }
    return len;
}
pub export fn stb_vorbis_get_frame_short(arg_f: [*c]stb_vorbis, arg_num_c: c_int, arg_buffer: [*c][*c]c_short, arg_num_samples: c_int) c_int {
    var f = arg_f;
    _ = &f;
    var num_c = arg_num_c;
    _ = &num_c;
    var buffer = arg_buffer;
    _ = &buffer;
    var num_samples = arg_num_samples;
    _ = &num_samples;
    var output: [*c][*c]f32 = null;
    _ = &output;
    var len: c_int = stb_vorbis_get_frame_float(f, null, &output);
    _ = &len;
    if (len > num_samples) {
        len = num_samples;
    }
    if (len != 0) {
        convert_samples_short(num_c, buffer, @as(c_int, 0), f.*.channels, output, @as(c_int, 0), @intCast(len));
    }
    return len;
}
pub export fn stb_vorbis_get_samples_float_interleaved(arg_f: [*c]stb_vorbis, arg_channels: c_int, arg_buffer: [*c]f32, arg_num_floats: c_int) c_int {
    var f = arg_f;
    _ = &f;
    var channels = arg_channels;
    _ = &channels;
    var buffer = arg_buffer;
    _ = &buffer;
    var num_floats = arg_num_floats;
    _ = &num_floats;
    var outputs: [*c][*c]f32 = undefined;
    _ = &outputs;
    var len: c_int = @divTrunc(num_floats, channels);
    _ = &len;
    var n: c_int = 0;
    _ = &n;
    var z: c_int = f.*.channels;
    _ = &z;
    if (z > channels) {
        z = channels;
    }
    while (n < len) {
        var i: c_int = undefined;
        _ = &i;
        var j: c_int = undefined;
        _ = &j;
        var k: c_int = f.*.channel_buffer_end - f.*.channel_buffer_start;
        _ = &k;
        if ((n + k) >= len) {
            k = len - n;
        }
        {
            j = 0;
            while (j < k) : (j += 1) {
                {
                    i = 0;
                    while (i < z) : (i += 1) {
                        (blk: {
                            const ref = &buffer;
                            const tmp = ref.*;
                            ref.* += 1;
                            break :blk tmp;
                        }).* = (blk: {
                            const tmp = f.*.channel_buffer_start + j;
                            if (tmp >= 0) break :blk f.*.channel_buffers[@as(u32, @intCast(i))] + @as(usize, @intCast(tmp)) else break :blk f.*.channel_buffers[@as(u32, @intCast(i))] - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).*;
                    }
                }
                while (i < channels) : (i += 1) {
                    (blk: {
                        const ref = &buffer;
                        const tmp = ref.*;
                        ref.* += 1;
                        break :blk tmp;
                    }).* = 0;
                }
            }
        }
        n += k;
        f.*.channel_buffer_start += k;
        if (n == len) break;
        if (!(stb_vorbis_get_frame_float(f, null, &outputs) != 0)) break;
    }
    return n;
}
pub export fn stb_vorbis_get_samples_float(f: [*c]stb_vorbis, channels: usize, buffer: [*c][*c]f32, num_samples: usize) usize {
    var outputs: [*c][*c]f32 = undefined;
    var n: usize = 0;
    var z: usize = @intCast(f.*.channels);
    if (z > channels) {
        z = channels;
    }
    while (n < num_samples) {
        var k: usize = @intCast(f.*.channel_buffer_end - f.*.channel_buffer_start);
        if (n + k >= num_samples) {
            k = num_samples - n;
        }
        if (k != 0) {
            var i: usize = 0;
            while (i < z) : (i += 1) {
                @memcpy(
                    @as([*]u8, @ptrCast(buffer[i]))[0 .. @sizeOf(f32) * k],
                    @as([*]const u8, @ptrCast(f.*.channel_buffers[i] + @as(usize, @intCast(f.*.channel_buffer_start)))),
                );
            }
            while (i < channels) : (i += 1) {
                @memset(
                    @as([*]u8, @ptrCast(buffer[i]))[0 .. @sizeOf(f32) * k],
                    0,
                );
            }
        }
        n += k;
        f.*.channel_buffer_start += @intCast(k);
        if (n == num_samples) break;
        if (!(stb_vorbis_get_frame_float(f, null, &outputs) != 0)) break;
    }
    return n;
}
pub export fn stb_vorbis_get_samples_short_interleaved(arg_f: [*c]stb_vorbis, arg_channels: c_int, arg_buffer: [*c]c_short, arg_num_shorts: c_int) c_int {
    var f = arg_f;
    _ = &f;
    var channels = arg_channels;
    _ = &channels;
    var buffer = arg_buffer;
    _ = &buffer;
    var num_shorts = arg_num_shorts;
    _ = &num_shorts;
    var outputs: [*c][*c]f32 = undefined;
    _ = &outputs;
    var len: c_int = @divTrunc(num_shorts, channels);
    _ = &len;
    var n: c_int = 0;
    _ = &n;
    while (n < len) {
        var k: c_int = f.*.channel_buffer_end - f.*.channel_buffer_start;
        _ = &k;
        if ((n + k) >= len) {
            k = len - n;
        }
        if (k != 0) {
            convert_channels_short_interleaved(channels, buffer, f.*.channels, @as([*c][*c]f32, @ptrCast(@alignCast(&f.*.channel_buffers[@as(usize, @intCast(0))]))), f.*.channel_buffer_start, k);
        }
        buffer += @as(usize, @bitCast(@as(isize, @intCast(k * channels))));
        n += k;
        f.*.channel_buffer_start += k;
        if (n == len) break;
        if (!(stb_vorbis_get_frame_float(f, null, &outputs) != 0)) break;
    }
    return n;
}
pub export fn stb_vorbis_get_samples_short(arg_f: [*c]stb_vorbis, arg_channels: c_int, arg_buffer: [*c][*c]c_short, arg_len: c_int) c_int {
    var f = arg_f;
    _ = &f;
    var channels = arg_channels;
    _ = &channels;
    var buffer = arg_buffer;
    _ = &buffer;
    var len = arg_len;
    _ = &len;
    var outputs: [*c][*c]f32 = undefined;
    _ = &outputs;
    var n: c_int = 0;
    _ = &n;
    while (n < len) {
        var k: c_int = f.*.channel_buffer_end - f.*.channel_buffer_start;
        _ = &k;
        if ((n + k) >= len) {
            k = len - n;
        }
        if (k != 0) {
            convert_samples_short(
                channels,
                buffer,
                n,
                f.*.channels,
                @as([*c][*c]f32, @ptrCast(@alignCast(&f.*.channel_buffers[@as(usize, @intCast(0))]))),
                f.*.channel_buffer_start,
                @intCast(k),
            );
        }
        n += k;
        f.*.channel_buffer_start += k;
        if (n == len) break;
        if (!(stb_vorbis_get_frame_float(f, null, &outputs) != 0)) break;
    }
    return n;
}
pub extern fn malloc(__size: c_ulong) ?*anyopaque;
pub extern fn calloc(__count: c_ulong, __size: c_ulong) ?*anyopaque;
pub extern fn free(?*anyopaque) void;
pub extern fn realloc(__ptr: ?*anyopaque, __size: c_ulong) ?*anyopaque;
pub extern fn abs(c_int) c_int;
pub extern fn qsort(__base: ?*anyopaque, __nel: usize, __width: usize, __compar: ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.c) c_int) void;
pub extern var suboptarg: [*c]u8;
pub extern fn memcmp(__s1: ?*const anyopaque, __s2: ?*const anyopaque, __n: c_ulong) c_int;
pub extern fn memcpy(__dst: ?*anyopaque, __src: ?*const anyopaque, __n: c_ulong) ?*anyopaque;
pub extern fn memset(__b: ?*anyopaque, __c: c_int, __len: c_ulong) ?*anyopaque;
pub extern fn __assert_rtn([*c]const u8, [*c]const u8, c_int, [*c]const u8) noreturn;
pub const struct_exception = extern struct {
    type: c_int = std.mem.zeroes(c_int),
    name: [*c]u8 = std.mem.zeroes([*c]u8),
    arg1: f64 = std.mem.zeroes(f64),
    arg2: f64 = std.mem.zeroes(f64),
    retval: f64 = std.mem.zeroes(f64),
};
pub const int8 = i8;
pub const int32 = c_int;
pub const codetype = f32;
pub const Codebook = extern struct {
    dimensions: c_int = std.mem.zeroes(c_int),
    entries: c_int = std.mem.zeroes(c_int),
    codeword_lengths: [*c]u8 = std.mem.zeroes([*c]u8),
    minimum_value: f32 = std.mem.zeroes(f32),
    delta_value: f32 = std.mem.zeroes(f32),
    value_bits: u8 = std.mem.zeroes(u8),
    lookup_type: u8 = std.mem.zeroes(u8),
    sequence_p: u8 = std.mem.zeroes(u8),
    sparse: u8 = std.mem.zeroes(u8),
    lookup_values: u32 = std.mem.zeroes(u32),
    multiplicands: [*c]codetype = std.mem.zeroes([*c]codetype),
    codewords: [*c]u32 = std.mem.zeroes([*c]u32),
    fast_huffman: [1024]int16 = std.mem.zeroes([1024]int16),
    sorted_codewords: [*c]u32 = std.mem.zeroes([*c]u32),
    sorted_values: [*c]c_int = std.mem.zeroes([*c]c_int),
    sorted_entries: c_int = std.mem.zeroes(c_int),
};
pub const Floor0 = extern struct {
    order: u8 = std.mem.zeroes(u8),
    rate: uint16 = std.mem.zeroes(uint16),
    bark_map_size: uint16 = std.mem.zeroes(uint16),
    amplitude_bits: u8 = std.mem.zeroes(u8),
    amplitude_offset: u8 = std.mem.zeroes(u8),
    number_of_books: u8 = std.mem.zeroes(u8),
    book_list: [16]u8 = std.mem.zeroes([16]u8),
};
pub const Floor1 = extern struct {
    partitions: u8 = std.mem.zeroes(u8),
    partition_class_list: [32]u8 = std.mem.zeroes([32]u8),
    class_dimensions: [16]u8 = std.mem.zeroes([16]u8),
    class_subclasses: [16]u8 = std.mem.zeroes([16]u8),
    class_masterbooks: [16]u8 = std.mem.zeroes([16]u8),
    subclass_books: [16][8]int16 = std.mem.zeroes([16][8]int16),
    Xlist: [250]uint16 = std.mem.zeroes([250]uint16),
    sorted_order: [250]u8 = std.mem.zeroes([250]u8),
    neighbors: [250][2]u8 = std.mem.zeroes([250][2]u8),
    floor1_multiplier: u8 = std.mem.zeroes(u8),
    rangebits: u8 = std.mem.zeroes(u8),
    values: c_int = std.mem.zeroes(c_int),
};
pub const Floor = extern union {
    floor0: Floor0,
    floor1: Floor1,
};
pub const Residue = extern struct {
    begin: u32 = std.mem.zeroes(u32),
    end: u32 = std.mem.zeroes(u32),
    part_size: u32 = std.mem.zeroes(u32),
    classifications: u8 = std.mem.zeroes(u8),
    classbook: u8 = std.mem.zeroes(u8),
    classdata: [*c][*c]u8 = std.mem.zeroes([*c][*c]u8),
    residue_books: [*c][8]int16 = std.mem.zeroes([*c][8]int16),
};
pub const MappingChannel = extern struct {
    magnitude: u8 = std.mem.zeroes(u8),
    angle: u8 = std.mem.zeroes(u8),
    mux: u8 = std.mem.zeroes(u8),
};
pub const Mapping = extern struct {
    coupling_steps: uint16 = std.mem.zeroes(uint16),
    chan: [*c]MappingChannel = std.mem.zeroes([*c]MappingChannel),
    submaps: u8 = std.mem.zeroes(u8),
    submap_floor: [15]u8 = std.mem.zeroes([15]u8),
    submap_residue: [15]u8 = std.mem.zeroes([15]u8),
};
pub const Mode = extern struct {
    blockflag: u8 = std.mem.zeroes(u8),
    mapping: u8 = std.mem.zeroes(u8),
    windowtype: uint16 = std.mem.zeroes(uint16),
    transformtype: uint16 = std.mem.zeroes(uint16),
};
pub const CRCscan = extern struct {
    goal_crc: u32 = std.mem.zeroes(u32),
    bytes_left: c_int = std.mem.zeroes(c_int),
    crc_so_far: u32 = std.mem.zeroes(u32),
    bytes_done: c_int = std.mem.zeroes(c_int),
    sample_loc: u32 = std.mem.zeroes(u32),
};
pub const ProbedPage = extern struct {
    page_start: u32 = std.mem.zeroes(u32),
    page_end: u32 = std.mem.zeroes(u32),
    last_decoded_sample: u32 = std.mem.zeroes(u32),
};
pub const vorb = struct_stb_vorbis;
pub fn @"error"(arg_f: [*c]vorb, arg_e: enum_STBVorbisError) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var e = arg_e;
    _ = &e;
    f.*.@"error" = e;
    if (!(f.*.eof != 0) and (e != @as(u32, @bitCast(VORBIS_need_more_data)))) {
        f.*.@"error" = e;
    }
    return 0;
}
pub fn make_block_array(arg_mem: ?*anyopaque, arg_count: c_int, arg_size: c_int) callconv(.c) ?*anyopaque {
    var mem = arg_mem;
    _ = &mem;
    var count = arg_count;
    _ = &count;
    var size = arg_size;
    _ = &size;
    var i: c_int = undefined;
    _ = &i;
    var p: [*c]?*anyopaque = @as([*c]?*anyopaque, @ptrCast(@alignCast(mem)));
    _ = &p;
    var q: [*c]u8 = @as([*c]u8, @ptrCast(@alignCast(p + @as(usize, @bitCast(@as(isize, @intCast(count)))))));
    _ = &q;
    {
        i = 0;
        while (i < count) : (i += 1) {
            (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk p + @as(usize, @intCast(tmp)) else break :blk p - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = @as(?*anyopaque, @ptrCast(q));
            q += @as(usize, @bitCast(@as(isize, @intCast(size))));
        }
    }
    return @as(?*anyopaque, @ptrCast(p));
}
pub fn setup_malloc(arg_f: [*c]vorb, arg_sz: c_int) callconv(.c) ?*anyopaque {
    var f = arg_f;
    _ = &f;
    var sz = arg_sz;
    _ = &sz;
    sz = (sz + @as(c_int, 7)) & ~@as(c_int, 7);
    f.*.setup_memory_required +%= @as(u32, @bitCast(sz));
    if (f.*.alloc.alloc_buffer != null) {
        var p: ?*anyopaque = @as(?*anyopaque, @ptrCast(f.*.alloc.alloc_buffer + @as(usize, @bitCast(@as(isize, @intCast(f.*.setup_offset))))));
        _ = &p;
        if ((f.*.setup_offset + sz) > f.*.temp_offset) return @as(?*anyopaque, @ptrFromInt(@as(c_int, 0)));
        f.*.setup_offset += sz;
        return p;
    }
    // No buffer provided - use malloc
    return malloc(@as(c_ulong, @intCast(sz)));
}
pub fn setup_free(arg_f: [*c]vorb, arg_p: ?*anyopaque) callconv(.c) void {
    var f = arg_f;
    _ = &f;
    const p = arg_p;
    // If using buffer, nothing to free (arena handles it)
    // If not using buffer, free the malloc'd memory
    if (f.*.alloc.alloc_buffer == null) {
        free(p);
    }
}
pub fn setup_temp_malloc(arg_f: [*c]vorb, arg_sz: c_int) callconv(.c) ?*anyopaque {
    var f = arg_f;
    _ = &f;
    var sz = arg_sz;
    _ = &sz;
    sz = (sz + @as(c_int, 7)) & ~@as(c_int, 7);
    if (f.*.alloc.alloc_buffer != null) {
        if ((f.*.temp_offset - sz) < f.*.setup_offset) return @as(?*anyopaque, @ptrFromInt(@as(c_int, 0)));
        f.*.temp_offset -= sz;
        return @as(?*anyopaque, @ptrCast(f.*.alloc.alloc_buffer + @as(usize, @bitCast(@as(isize, @intCast(f.*.temp_offset))))));
    }
    // No buffer provided - use malloc
    return malloc(@as(c_ulong, @intCast(sz)));
}
pub fn setup_temp_free(arg_f: [*c]vorb, arg_p: ?*anyopaque, arg_sz: c_int) callconv(.c) void {
    var f = arg_f;
    _ = &f;
    const p = arg_p;
    var sz = arg_sz;
    _ = &sz;
    if (f.*.alloc.alloc_buffer != null) {
        f.*.temp_offset += (sz + @as(c_int, 7)) & ~@as(c_int, 7);
        return;
    }
    // No buffer - use free
    free(p);
}
pub var crc_table: [256]u32 = std.mem.zeroes([256]u32);
pub var integer_divide_table: [DIVTAB_NUMER][DIVTAB_DENOM]i8 = std.mem.zeroes([DIVTAB_NUMER][DIVTAB_DENOM]i8);
pub fn crc32_init() callconv(.c) void {
    var i: c_int = undefined;
    _ = &i;
    var j: c_int = undefined;
    _ = &j;
    var s: u32 = undefined;
    _ = &s;
    {
        i = 0;
        while (i < @as(c_int, 256)) : (i += 1) {
            {
                _ = blk: {
                    s = @as(u32, @bitCast(i)) << @intCast(24);
                    break :blk blk_1: {
                        const tmp = @as(c_int, 0);
                        j = tmp;
                        break :blk_1 tmp;
                    };
                };
                while (j < @as(c_int, 8)) : (j += 1) {
                    s = (s << @intCast(1)) ^ @as(u32, @bitCast(if (s >= (@as(u32, 1) << @intCast(31))) @as(c_int, 79764919) else @as(c_int, 0)));
                }
            }
            crc_table[@as(u32, @intCast(i))] = s;
        }
    }
}
pub fn crc32_update(arg_crc: u32, arg_byte: u8) callconv(.c) u32 {
    var crc = arg_crc;
    _ = &crc;
    var byte = arg_byte;
    _ = &byte;
    return (crc << @intCast(8)) ^ crc_table[@as(u32, @bitCast(@as(u32, byte))) ^ (crc >> @intCast(24))];
}
pub fn bit_reverse(arg_n: u32) callconv(.c) u32 {
    var n = arg_n;
    _ = &n;
    n = ((n & @as(u32, 2863311530)) >> @intCast(1)) | ((n & @as(u32, @bitCast(@as(c_int, 1431655765)))) << @intCast(1));
    n = ((n & @as(u32, 3435973836)) >> @intCast(2)) | ((n & @as(u32, @bitCast(@as(c_int, 858993459)))) << @intCast(2));
    n = ((n & @as(u32, 4042322160)) >> @intCast(4)) | ((n & @as(u32, @bitCast(@as(c_int, 252645135)))) << @intCast(4));
    n = ((n & @as(u32, 4278255360)) >> @intCast(8)) | ((n & @as(u32, @bitCast(@as(c_int, 16711935)))) << @intCast(8));
    return (n >> @intCast(16)) | (n << @intCast(16));
}
pub fn square(arg_x: f32) callconv(.c) f32 {
    var x = arg_x;
    _ = &x;
    return x * x;
}
pub fn ilog(arg_n: int32) callconv(.c) c_int {
    var n = arg_n;
    _ = &n;
    const log2_4 = struct {
        var static: [16]i8 = [16]i8{
            0,
            1,
            2,
            2,
            3,
            3,
            3,
            3,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
        };
    };
    _ = &log2_4;
    if (n < @as(c_int, 0)) return 0;
    if (n < (@as(c_int, 1) << @intCast(14))) if (n < (@as(c_int, 1) << @intCast(4))) return @as(c_int, 0) + @as(c_int, @bitCast(@as(c_int, log2_4.static[@as(u32, @intCast(n))]))) else if (n < (@as(c_int, 1) << @intCast(9))) return @as(c_int, 5) + @as(c_int, @bitCast(@as(c_int, log2_4.static[@as(u32, @intCast(n >> @intCast(5)))]))) else return @as(c_int, 10) + @as(c_int, @bitCast(@as(c_int, log2_4.static[@as(u32, @intCast(n >> @intCast(10)))]))) else if (n < (@as(c_int, 1) << @intCast(24))) if (n < (@as(c_int, 1) << @intCast(19))) return @as(c_int, 15) + @as(c_int, @bitCast(@as(c_int, log2_4.static[@as(u32, @intCast(n >> @intCast(15)))]))) else return @as(c_int, 20) + @as(c_int, @bitCast(@as(c_int, log2_4.static[@as(u32, @intCast(n >> @intCast(20)))]))) else if (n < (@as(c_int, 1) << @intCast(29))) return @as(c_int, 25) + @as(c_int, @bitCast(@as(c_int, log2_4.static[@as(u32, @intCast(n >> @intCast(25)))]))) else return @as(c_int, 30) + @as(c_int, @bitCast(@as(c_int, log2_4.static[@as(u32, @intCast(n >> @intCast(30)))])));
    return 0;
}
pub fn float32_unpack(arg_x: u32) callconv(.c) f32 {
    var x = arg_x;
    _ = &x;
    var mantissa: u32 = x & @as(u32, @bitCast(@as(c_int, 2097151)));
    _ = &mantissa;
    var sign: u32 = x & @as(u32, 2147483648);
    _ = &sign;
    var exp_1: u32 = (x & @as(u32, @bitCast(@as(c_int, 2145386496)))) >> @intCast(21);
    _ = &exp_1;
    var res: f64 = if (sign != 0) -@as(f64, @floatFromInt(mantissa)) else @as(f64, @floatFromInt(mantissa));
    _ = &res;
    return @as(f32, @floatCast(std.math.ldexp(@as(f64, @floatCast(@as(f32, @floatCast(res)))), @as(c_int, @bitCast(exp_1)) - @as(c_int, 788))));
}
pub fn add_entry(arg_c: [*c]Codebook, arg_huff_code: u32, arg_symbol: c_int, arg_count: c_int, arg_len: c_int, arg_values: [*c]u32) callconv(.c) void {
    var c = arg_c;
    _ = &c;
    var huff_code = arg_huff_code;
    _ = &huff_code;
    var symbol = arg_symbol;
    _ = &symbol;
    var count = arg_count;
    _ = &count;
    var len = arg_len;
    _ = &len;
    var values = arg_values;
    _ = &values;
    if (!(c.*.sparse != 0)) {
        (blk: {
            const tmp = symbol;
            if (tmp >= 0) break :blk c.*.codewords + @as(usize, @intCast(tmp)) else break :blk c.*.codewords - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = huff_code;
    } else {
        (blk: {
            const tmp = count;
            if (tmp >= 0) break :blk c.*.codewords + @as(usize, @intCast(tmp)) else break :blk c.*.codewords - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = huff_code;
        (blk: {
            const tmp = count;
            if (tmp >= 0) break :blk c.*.codeword_lengths + @as(usize, @intCast(tmp)) else break :blk c.*.codeword_lengths - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = @as(u8, @bitCast(@as(i8, @truncate(len))));
        (blk: {
            const tmp = count;
            if (tmp >= 0) break :blk values + @as(usize, @intCast(tmp)) else break :blk values - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = @as(u32, @bitCast(symbol));
    }
}
pub fn compute_codewords(c: [*c]Codebook, len: [*c]u8, n: c_int, values: [*c]u32) c_int {
    var i: c_int = undefined;
    var k: c_int = undefined;
    var m: c_int = 0;
    var available: [32]u32 = [_]u32{0} ** 32;
    {
        k = 0;
        while (k < n) : (k += 1) if (@as(c_int, @bitCast(@as(u32, (blk: {
            const tmp = k;
            if (tmp >= 0) break :blk len + @as(usize, @intCast(tmp)) else break :blk len - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*))) < @as(c_int, 255)) break;
    }
    if (k == n) {
        return 1;
    }
    add_entry(c, @as(u32, @bitCast(@as(c_int, 0))), k, blk: {
        const ref = &m;
        const tmp = ref.*;
        ref.* += 1;
        break :blk tmp;
    }, @as(c_int, @bitCast(@as(u32, (blk: {
        const tmp = k;
        if (tmp >= 0) break :blk len + @as(usize, @intCast(tmp)) else break :blk len - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*))), values);
    {
        i = 1;
        while (i <= @as(c_int, @bitCast(@as(u32, (blk: {
            const tmp = k;
            if (tmp >= 0) break :blk len + @as(usize, @intCast(tmp)) else break :blk len - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*)))) : (i += 1) {
            available[@as(u32, @intCast(i))] = @as(u32, 1) << @intCast(@as(c_int, 32) - i);
        }
    }
    {
        i = k + @as(c_int, 1);
        while (i < n) : (i += 1) {
            var res: u32 = undefined;
            _ = &res;
            var z: c_int = @as(c_int, @bitCast(@as(u32, (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk len + @as(usize, @intCast(tmp)) else break :blk len - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*)));
            _ = &z;
            var y: c_int = undefined;
            _ = &y;
            if (z == @as(c_int, 255)) continue;
            while ((z > @as(c_int, 0)) and !(available[@as(u32, @intCast(z))] != 0)) {
                z -= 1;
            }
            if (z == @as(c_int, 0)) {
                return 0;
            }
            res = available[@as(u32, @intCast(z))];
            available[@as(u32, @intCast(z))] = 0;
            add_entry(c, bit_reverse(res), i, blk: {
                const ref = &m;
                const tmp = ref.*;
                ref.* += 1;
                break :blk tmp;
            }, @as(c_int, @bitCast(@as(u32, (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk len + @as(usize, @intCast(tmp)) else break :blk len - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*))), values);
            if (z != @as(c_int, @bitCast(@as(u32, (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk len + @as(usize, @intCast(tmp)) else break :blk len - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*)))) {
                {
                    y = @as(c_int, @bitCast(@as(u32, (blk: {
                        const tmp = i;
                        if (tmp >= 0) break :blk len + @as(usize, @intCast(tmp)) else break :blk len - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                    }).*)));
                    while (y > z) : (y -= 1) {
                        available[@as(u32, @intCast(y))] = res +% @as(u32, @bitCast(@as(c_int, 1) << @intCast(@as(c_int, 32) - y)));
                    }
                }
            }
        }
    }
    return 1;
}
pub fn compute_accelerated_huffman(arg_c: [*c]Codebook) callconv(.c) void {
    var c = arg_c;
    _ = &c;
    var i: c_int = undefined;
    _ = &i;
    var len: c_int = undefined;
    _ = &len;
    {
        i = 0;
        while (i < (@as(c_int, 1) << @intCast(10))) : (i += 1) {
            c.*.fast_huffman[@as(u32, @intCast(i))] = @as(int16, @bitCast(@as(c_short, @truncate(-@as(c_int, 1)))));
        }
    }
    len = if (@as(c_int, @bitCast(@as(u32, c.*.sparse))) != 0) c.*.sorted_entries else c.*.entries;
    if (len > @as(c_int, 32767)) {
        len = 32767;
    }
    {
        i = 0;
        while (i < len) : (i += 1) {
            if (@as(c_int, @bitCast(@as(u32, (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk c.*.codeword_lengths + @as(usize, @intCast(tmp)) else break :blk c.*.codeword_lengths - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*))) <= @as(c_int, 10)) {
                var z: u32 = if (@as(c_int, @bitCast(@as(u32, c.*.sparse))) != 0) bit_reverse((blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk c.*.sorted_codewords + @as(usize, @intCast(tmp)) else break :blk c.*.sorted_codewords - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).*) else (blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk c.*.codewords + @as(usize, @intCast(tmp)) else break :blk c.*.codewords - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).*;
                _ = &z;
                while (z < @as(u32, @bitCast(@as(c_int, 1) << @intCast(10)))) {
                    c.*.fast_huffman[z] = @as(int16, @bitCast(@as(c_short, @truncate(i))));
                    z +%= @as(u32, @bitCast(@as(c_int, 1) << @intCast(@as(c_int, @bitCast(@as(u32, (blk: {
                        const tmp = i;
                        if (tmp >= 0) break :blk c.*.codeword_lengths + @as(usize, @intCast(tmp)) else break :blk c.*.codeword_lengths - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                    }).*))))));
                }
            }
        }
    }
}
pub fn uint32_compare(arg_p: ?*const anyopaque, arg_q: ?*const anyopaque) callconv(.c) c_int {
    var p = arg_p;
    _ = &p;
    var q = arg_q;
    _ = &q;
    var x: u32 = @as([*c]u32, @ptrCast(@alignCast(@constCast(@volatileCast(p))))).*;
    _ = &x;
    var y: u32 = @as([*c]u32, @ptrCast(@alignCast(@constCast(@volatileCast(q))))).*;
    _ = &y;
    return if (x < y) -@as(c_int, 1) else @intFromBool(x > y);
}
pub fn include_in_sort(arg_c: [*c]Codebook, arg_len: u8) callconv(.c) c_int {
    var c = arg_c;
    _ = &c;
    var len = arg_len;
    _ = &len;
    if (c.*.sparse != 0) {
        return 1;
    }
    if (@as(c_int, @bitCast(@as(u32, len))) == @as(c_int, 255)) return 0;
    if (@as(c_int, @bitCast(@as(u32, len))) > @as(c_int, 10)) return 1;
    return 0;
}
pub fn compute_sorted_huffman(arg_c: [*c]Codebook, arg_lengths: [*c]u8, arg_values: [*c]u32) callconv(.c) void {
    var c = arg_c;
    _ = &c;
    var lengths = arg_lengths;
    _ = &lengths;
    var values = arg_values;
    _ = &values;
    var i: c_int = undefined;
    _ = &i;
    var len: c_int = undefined;
    _ = &len;
    if (!(c.*.sparse != 0)) {
        var k: c_int = 0;
        _ = &k;
        {
            i = 0;
            while (i < c.*.entries) : (i += 1) if (include_in_sort(c, (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk lengths + @as(usize, @intCast(tmp)) else break :blk lengths - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*) != 0) {
                (blk: {
                    const tmp = blk_1: {
                        const ref = &k;
                        const tmp_2 = ref.*;
                        ref.* += 1;
                        break :blk_1 tmp_2;
                    };
                    if (tmp >= 0) break :blk c.*.sorted_codewords + @as(usize, @intCast(tmp)) else break :blk c.*.sorted_codewords - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).* = bit_reverse((blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk c.*.codewords + @as(usize, @intCast(tmp)) else break :blk c.*.codewords - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).*);
            };
        }
    } else {
        {
            i = 0;
            while (i < c.*.sorted_entries) : (i += 1) {
                (blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk c.*.sorted_codewords + @as(usize, @intCast(tmp)) else break :blk c.*.sorted_codewords - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).* = bit_reverse((blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk c.*.codewords + @as(usize, @intCast(tmp)) else break :blk c.*.codewords - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).*);
            }
        }
    }
    qsort(@as(?*anyopaque, @ptrCast(c.*.sorted_codewords)), @as(usize, @bitCast(@as(c_long, c.*.sorted_entries))), @sizeOf(u32), &uint32_compare);
    (blk: {
        const tmp = c.*.sorted_entries;
        if (tmp >= 0) break :blk c.*.sorted_codewords + @as(usize, @intCast(tmp)) else break :blk c.*.sorted_codewords - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).* = 4294967295;
    len = if (@as(c_int, @bitCast(@as(u32, c.*.sparse))) != 0) c.*.sorted_entries else c.*.entries;
    {
        i = 0;
        while (i < len) : (i += 1) {
            var huff_len: c_int = if (@as(c_int, @bitCast(@as(u32, c.*.sparse))) != 0) @as(c_int, @bitCast(@as(u32, lengths[
                (blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk values + @as(usize, @intCast(tmp)) else break :blk values - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).*
            ]))) else @as(c_int, @bitCast(@as(u32, (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk lengths + @as(usize, @intCast(tmp)) else break :blk lengths - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*)));
            _ = &huff_len;
            if (include_in_sort(c, @as(u8, @bitCast(@as(i8, @truncate(huff_len))))) != 0) {
                var code: u32 = bit_reverse((blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk c.*.codewords + @as(usize, @intCast(tmp)) else break :blk c.*.codewords - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).*);
                _ = &code;
                var x: c_int = 0;
                _ = &x;
                var n: c_int = c.*.sorted_entries;
                _ = &n;
                while (n > @as(c_int, 1)) {
                    var m: c_int = x + (n >> @intCast(1));
                    _ = &m;
                    if ((blk: {
                        const tmp = m;
                        if (tmp >= 0) break :blk c.*.sorted_codewords + @as(usize, @intCast(tmp)) else break :blk c.*.sorted_codewords - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                    }).* <= code) {
                        x = m;
                        n -= n >> @intCast(1);
                    } else {
                        n >>= @intCast(@as(c_int, 1));
                    }
                }
                if (c.*.sparse != 0) {
                    (blk: {
                        const tmp = x;
                        if (tmp >= 0) break :blk c.*.sorted_values + @as(usize, @intCast(tmp)) else break :blk c.*.sorted_values - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                    }).* = @as(c_int, @bitCast((blk: {
                        const tmp = i;
                        if (tmp >= 0) break :blk values + @as(usize, @intCast(tmp)) else break :blk values - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                    }).*));
                    (blk: {
                        const tmp = x;
                        if (tmp >= 0) break :blk c.*.codeword_lengths + @as(usize, @intCast(tmp)) else break :blk c.*.codeword_lengths - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                    }).* = @as(u8, @bitCast(@as(i8, @truncate(huff_len))));
                } else {
                    (blk: {
                        const tmp = x;
                        if (tmp >= 0) break :blk c.*.sorted_values + @as(usize, @intCast(tmp)) else break :blk c.*.sorted_values - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                    }).* = i;
                }
            }
        }
    }
}
pub fn vorbis_validate(arg_data: [*c]u8) callconv(.c) c_int {
    var data = arg_data;
    _ = &data;
    const vorbis = struct {
        var static: [6]u8 = [6]u8{
            'v',
            'o',
            'r',
            'b',
            'i',
            's',
        };
    };
    _ = &vorbis;
    return @intFromBool(memcmp(@as(?*const anyopaque, @ptrCast(data)), @as(?*const anyopaque, @ptrCast(@as([*c]u8, @ptrCast(@alignCast(&vorbis.static[@as(usize, @intCast(0))]))))), @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 6))))) == @as(c_int, 0));
}
pub fn lookup1_values(entries: i32, dim: i32) !u32 {
    const dim_f: f64 = @floatFromInt(dim);
    const entries_f: f64 = @floatFromInt(entries);
    var r: i32 = @intFromFloat(std.math.floor(@exp(@as(f32, @floatCast(@log(entries_f))) / dim_f)));
    if (@as(i32, @intFromFloat(std.math.floor(std.math.pow(f64, @as(f64, @floatFromInt(r)) + 1, dim_f)))) <= entries) {
        r += 1;
    }
    if (std.math.pow(f64, @as(f64, @floatCast(@as(f32, @floatFromInt(r)) + 1)), dim_f) <= entries_f) return error.InvalidSetup;
    if (@as(i32, @intFromFloat(std.math.floor(std.math.pow(f64, @as(f64, @floatFromInt(r)), dim_f)))) > entries) return error.InvalidSetup;

    return @intCast(r);
}
pub fn compute_twiddle_factors(arg_n: c_int, arg_A: [*c]f32, arg_B: [*c]f32, arg_C_1: [*c]f32) callconv(.c) void {
    var n = arg_n;
    _ = &n;
    var A = arg_A;
    _ = &A;
    var B = arg_B;
    _ = &B;
    var C_1 = arg_C_1;
    _ = &C_1;
    var n4: c_int = n >> @intCast(2);
    _ = &n4;
    var n8: c_int = n >> @intCast(3);
    _ = &n8;
    var k: c_int = undefined;
    _ = &k;
    var k2: c_int = undefined;
    _ = &k2;
    {
        k = blk: {
            const tmp = @as(c_int, 0);
            k2 = tmp;
            break :blk tmp;
        };
        while (k < n4) : (_ = blk: {
            k += 1;
            break :blk blk_1: {
                const ref = &k2;
                ref.* += @as(c_int, 2);
                break :blk_1 ref.*;
            };
        }) {
            (blk: {
                const tmp = k2;
                if (tmp >= 0) break :blk A + @as(usize, @intCast(tmp)) else break :blk A - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = @as(f32, @floatCast(@cos((@as(f64, @floatFromInt(@as(c_int, 4) * k)) * 3.141592653589793) / @as(f64, @floatFromInt(n)))));
            (blk: {
                const tmp = k2 + @as(c_int, 1);
                if (tmp >= 0) break :blk A + @as(usize, @intCast(tmp)) else break :blk A - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = @as(f32, @floatCast(-@sin((@as(f64, @floatFromInt(@as(c_int, 4) * k)) * 3.141592653589793) / @as(f64, @floatFromInt(n)))));
            (blk: {
                const tmp = k2;
                if (tmp >= 0) break :blk B + @as(usize, @intCast(tmp)) else break :blk B - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = @as(f32, @floatCast(@cos(((@as(f64, @floatFromInt(k2 + @as(c_int, 1))) * 3.141592653589793) / @as(f64, @floatFromInt(n))) / @as(f64, @floatFromInt(@as(c_int, 2)))))) * 0.5;
            (blk: {
                const tmp = k2 + @as(c_int, 1);
                if (tmp >= 0) break :blk B + @as(usize, @intCast(tmp)) else break :blk B - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = @as(f32, @floatCast(@sin(((@as(f64, @floatFromInt(k2 + @as(c_int, 1))) * 3.141592653589793) / @as(f64, @floatFromInt(n))) / @as(f64, @floatFromInt(@as(c_int, 2)))))) * 0.5;
        }
    }
    {
        k = blk: {
            const tmp = @as(c_int, 0);
            k2 = tmp;
            break :blk tmp;
        };
        while (k < n8) : (_ = blk: {
            k += 1;
            break :blk blk_1: {
                const ref = &k2;
                ref.* += @as(c_int, 2);
                break :blk_1 ref.*;
            };
        }) {
            (blk: {
                const tmp = k2;
                if (tmp >= 0) break :blk C_1 + @as(usize, @intCast(tmp)) else break :blk C_1 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = @as(f32, @floatCast(@cos((@as(f64, @floatFromInt(@as(c_int, 2) * (k2 + @as(c_int, 1)))) * 3.141592653589793) / @as(f64, @floatFromInt(n)))));
            (blk: {
                const tmp = k2 + @as(c_int, 1);
                if (tmp >= 0) break :blk C_1 + @as(usize, @intCast(tmp)) else break :blk C_1 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = @as(f32, @floatCast(-@sin((@as(f64, @floatFromInt(@as(c_int, 2) * (k2 + @as(c_int, 1)))) * 3.141592653589793) / @as(f64, @floatFromInt(n)))));
        }
    }
}
pub fn compute_window(arg_n: c_int, arg_window: [*c]f32) callconv(.c) void {
    var n = arg_n;
    _ = &n;
    var window = arg_window;
    _ = &window;
    var n2: c_int = n >> @intCast(1);
    _ = &n2;
    var i: c_int = undefined;
    _ = &i;
    {
        i = 0;
        while (i < n2) : (i += 1) {
            (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk window + @as(usize, @intCast(tmp)) else break :blk window - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = @as(f32, @floatCast(@sin((0.5 * 3.141592653589793) * @as(f64, @floatCast(square(@as(f32, @floatCast(@sin((((@as(f64, @floatFromInt(i - @as(c_int, 0))) + 0.5) / @as(f64, @floatFromInt(n2))) * 0.5) * 3.141592653589793)))))))));
        }
    }
}
pub fn compute_bitreverse(arg_n: c_int, arg_rev: [*c]uint16) callconv(.c) void {
    var n = arg_n;
    _ = &n;
    var rev = arg_rev;
    _ = &rev;
    var ld: c_int = ilog(n) - @as(c_int, 1);
    _ = &ld;
    var i: c_int = undefined;
    _ = &i;
    var n8: c_int = n >> @intCast(3);
    _ = &n8;
    {
        i = 0;
        while (i < n8) : (i += 1) {
            (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk rev + @as(usize, @intCast(tmp)) else break :blk rev - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = @as(uint16, @bitCast(@as(c_ushort, @truncate((bit_reverse(@as(u32, @bitCast(i))) >> @intCast((@as(c_int, 32) - ld) + @as(c_int, 3))) << @intCast(2)))));
        }
    }
}
pub fn init_blocksize(arg_f: [*c]vorb, arg_b: c_int, arg_n: c_int) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var b = arg_b;
    _ = &b;
    var n = arg_n;
    _ = &n;
    var n2: c_int = n >> @intCast(1);
    _ = &n2;
    var n4: c_int = n >> @intCast(2);
    _ = &n4;
    var n8: c_int = n >> @intCast(3);
    _ = &n8;
    f.*.A[@as(u32, @intCast(b))] = @as([*c]f32, @ptrCast(@alignCast(setup_malloc(f, @as(c_int, @bitCast(@as(u32, @truncate(@sizeOf(f32) *% @as(c_ulong, @bitCast(@as(c_long, n2)))))))))));
    f.*.B[@as(u32, @intCast(b))] = @as([*c]f32, @ptrCast(@alignCast(setup_malloc(f, @as(c_int, @bitCast(@as(u32, @truncate(@sizeOf(f32) *% @as(c_ulong, @bitCast(@as(c_long, n2)))))))))));
    f.*.C[@as(u32, @intCast(b))] = @as([*c]f32, @ptrCast(@alignCast(setup_malloc(f, @as(c_int, @bitCast(@as(u32, @truncate(@sizeOf(f32) *% @as(c_ulong, @bitCast(@as(c_long, n4)))))))))));
    if ((!(f.*.A[@as(u32, @intCast(b))] != null) or !(f.*.B[@as(u32, @intCast(b))] != null)) or !(f.*.C[@as(u32, @intCast(b))] != null)) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
    compute_twiddle_factors(n, f.*.A[@as(u32, @intCast(b))], f.*.B[@as(u32, @intCast(b))], f.*.C[@as(u32, @intCast(b))]);
    f.*.window[@as(u32, @intCast(b))] = @as([*c]f32, @ptrCast(@alignCast(setup_malloc(f, @as(c_int, @bitCast(@as(u32, @truncate(@sizeOf(f32) *% @as(c_ulong, @bitCast(@as(c_long, n2)))))))))));
    if (!(f.*.window[@as(u32, @intCast(b))] != null)) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
    compute_window(n, f.*.window[@as(u32, @intCast(b))]);
    f.*.bit_reverse[@as(u32, @intCast(b))] = @as([*c]uint16, @ptrCast(@alignCast(setup_malloc(f, @as(c_int, @bitCast(@as(u32, @truncate(@sizeOf(uint16) *% @as(c_ulong, @bitCast(@as(c_long, n8)))))))))));
    if (!(f.*.bit_reverse[@as(u32, @intCast(b))] != null)) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
    compute_bitreverse(n, f.*.bit_reverse[@as(u32, @intCast(b))]);
    return 1;
}
pub fn neighbors(arg_x: [*c]uint16, arg_n: c_int, arg_plow: [*c]c_int, arg_phigh: [*c]c_int) callconv(.c) void {
    var x = arg_x;
    _ = &x;
    var n = arg_n;
    _ = &n;
    var plow = arg_plow;
    _ = &plow;
    var phigh = arg_phigh;
    _ = &phigh;
    var low: c_int = -@as(c_int, 1);
    _ = &low;
    var high: c_int = 65536;
    _ = &high;
    var i: c_int = undefined;
    _ = &i;
    {
        i = 0;
        while (i < n) : (i += 1) {
            if ((@as(c_int, @bitCast(@as(u32, (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk x + @as(usize, @intCast(tmp)) else break :blk x - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*))) > low) and (@as(c_int, @bitCast(@as(u32, (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk x + @as(usize, @intCast(tmp)) else break :blk x - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*))) < @as(c_int, @bitCast(@as(u32, (blk: {
                const tmp = n;
                if (tmp >= 0) break :blk x + @as(usize, @intCast(tmp)) else break :blk x - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*))))) {
                plow.* = i;
                low = @as(c_int, @bitCast(@as(u32, (blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk x + @as(usize, @intCast(tmp)) else break :blk x - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).*)));
            }
            if ((@as(c_int, @bitCast(@as(u32, (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk x + @as(usize, @intCast(tmp)) else break :blk x - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*))) < high) and (@as(c_int, @bitCast(@as(u32, (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk x + @as(usize, @intCast(tmp)) else break :blk x - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*))) > @as(c_int, @bitCast(@as(u32, (blk: {
                const tmp = n;
                if (tmp >= 0) break :blk x + @as(usize, @intCast(tmp)) else break :blk x - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*))))) {
                phigh.* = i;
                high = @as(c_int, @bitCast(@as(u32, (blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk x + @as(usize, @intCast(tmp)) else break :blk x - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).*)));
            }
        }
    }
}
pub const stbv__floor_ordering = extern struct {
    x: uint16 = std.mem.zeroes(uint16),
    id: uint16 = std.mem.zeroes(uint16),
};
pub fn point_compare(arg_p: ?*const anyopaque, arg_q: ?*const anyopaque) callconv(.c) c_int {
    var p = arg_p;
    _ = &p;
    var q = arg_q;
    _ = &q;
    var a: [*c]stbv__floor_ordering = @as([*c]stbv__floor_ordering, @ptrCast(@alignCast(@constCast(@volatileCast(p)))));
    _ = &a;
    var b: [*c]stbv__floor_ordering = @as([*c]stbv__floor_ordering, @ptrCast(@alignCast(@constCast(@volatileCast(q)))));
    _ = &b;
    return if (@as(c_int, @bitCast(@as(u32, a.*.x))) < @as(c_int, @bitCast(@as(u32, b.*.x)))) -@as(c_int, 1) else @intFromBool(@as(c_int, @bitCast(@as(u32, a.*.x))) > @as(c_int, @bitCast(@as(u32, b.*.x))));
}
pub fn get8(z: [*c]vorb) callconv(.c) u8 {
    if (z.*.stream >= z.*.stream_end) {
        z.*.eof = 1;
        return 0;
    }
    return (blk: {
        const ref = &z.*.stream;
        const tmp = ref.*;
        ref.* += 1;
        break :blk tmp;
    }).*;
}
pub fn get32(arg_f: [*c]vorb) callconv(.c) u32 {
    var f = arg_f;
    _ = &f;
    var x: u32 = undefined;
    _ = &x;
    x = @as(u32, @bitCast(@as(u32, get8(f))));
    x +%= @as(u32, @bitCast(@as(c_int, @bitCast(@as(u32, get8(f)))) << @intCast(8)));
    x +%= @as(u32, @bitCast(@as(c_int, @bitCast(@as(u32, get8(f)))) << @intCast(16)));
    x +%= @as(u32, @bitCast(@as(u32, get8(f)))) << @intCast(24);
    return x;
}
pub fn getn(z: [*c]vorb, data: [*c]u8, n: usize) c_int {
    if (z.*.stream + n > z.*.stream_end) {
        z.*.eof = 1;
        return 0;
    }
    @memcpy(@as([*]u8, @ptrCast(data))[0..n], @as([*]const u8, @ptrCast(z.*.stream)));
    z.*.stream += n;
    return 1;
}
pub fn skip(z: [*c]vorb, n: c_int) callconv(.c) void {
    const available: usize = @intFromPtr(z.*.stream_end) - @intFromPtr(z.*.stream);
    var advance: usize = 0;
    if (n > 0) advance = @as(usize, @intCast(n));
    if (advance >= available) {
        z.*.stream = z.*.stream_end;
        z.*.eof = 1;
    } else {
        z.*.stream += advance;
    }
    return;
}
pub fn set_file_offset(arg_f: [*c]stb_vorbis, arg_loc: u32) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var loc = arg_loc;
    _ = &loc;
    if (f.*.push_mode != 0) return 0;
    f.*.eof = 0;
    if (((f.*.stream_start + loc) >= f.*.stream_end) or ((f.*.stream_start + loc) < f.*.stream_start)) {
        f.*.stream = f.*.stream_end;
        f.*.eof = 1;
        return 0;
    } else {
        f.*.stream = f.*.stream_start + loc;
        return 1;
    }
}
pub var ogg_page_header: [4]u8 = [4]u8{
    79,
    103,
    103,
    83,
};
pub fn capture_pattern(arg_f: [*c]vorb) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    if (get8(f) != 0x4f) return 0;
    if (get8(f) != 0x67) return 0;
    if (get8(f) != 0x67) return 0;
    if (get8(f) != 0x53) return 0;
    return 1;
}
pub fn start_page_no_capturepattern(arg_f: [*c]vorb) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var loc0: u32 = undefined;
    _ = &loc0;
    var loc1: u32 = undefined;
    _ = &loc1;
    var n: u32 = undefined;
    _ = &n;
    if ((@as(c_int, @bitCast(@as(u32, f.*.first_decode))) != 0) and !(f.*.push_mode != 0)) {
        f.*.p_first.page_start = stb_vorbis_get_file_offset(f) -% @as(u32, @bitCast(@as(c_int, 4)));
    }
    if (@as(c_int, 0) != @as(c_int, @bitCast(@as(u32, get8(f))))) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_stream_structure_version)));
    f.*.page_flag = get8(f);
    loc0 = get32(f);
    loc1 = get32(f);
    _ = get32(f);
    n = get32(f);
    f.*.last_page = @as(c_int, @bitCast(n));
    _ = get32(f);
    f.*.segment_count = @as(c_int, @bitCast(@as(u32, get8(f))));
    if (!(getn(f, @as([*c]u8, @ptrCast(@alignCast(&f.*.segments[0]))), @intCast(f.*.segment_count)) != 0)) return @"error"(f, @as(u32, @bitCast(VORBIS_unexpected_eof)));
    f.*.end_seg_with_known_loc = -@as(c_int, 2);
    if ((loc0 != ~@as(u32, 0)) or (loc1 != ~@as(u32, 0))) {
        var i: c_int = undefined;
        _ = &i;
        {
            i = f.*.segment_count - @as(c_int, 1);
            while (i >= @as(c_int, 0)) : (i -= 1) if (@as(c_int, @bitCast(@as(u32, f.*.segments[@as(u32, @intCast(i))]))) < @as(c_int, 255)) break;
        }
        if (i >= @as(c_int, 0)) {
            f.*.end_seg_with_known_loc = i;
            f.*.known_loc_for_packet = loc0;
        }
    }
    if (f.*.first_decode != 0) {
        var i: c_int = undefined;
        _ = &i;
        var len: c_int = undefined;
        _ = &len;
        len = 0;
        {
            i = 0;
            while (i < f.*.segment_count) : (i += 1) {
                len += @as(c_int, @bitCast(@as(u32, f.*.segments[@as(u32, @intCast(i))])));
            }
        }
        len += @as(c_int, 27) + f.*.segment_count;
        f.*.p_first.page_end = f.*.p_first.page_start +% @as(u32, @bitCast(len));
        f.*.p_first.last_decoded_sample = loc0;
    }
    f.*.next_seg = 0;
    return 1;
}
pub fn start_page(arg_f: [*c]vorb) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    if (!(capture_pattern(f) != 0)) return @"error"(f, @as(u32, @bitCast(VORBIS_missing_capture_pattern)));
    return start_page_no_capturepattern(f);
}
pub fn start_packet(arg_f: [*c]vorb) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    while (f.*.next_seg == -@as(c_int, 1)) {
        if (!(start_page(f) != 0)) return 0;
        if ((@as(c_int, @bitCast(@as(u32, f.*.page_flag))) & @as(c_int, 1)) != 0) return @"error"(f, @as(u32, @bitCast(VORBIS_continued_packet_flag_invalid)));
    }
    f.*.last_seg = 0;
    f.*.valid_bits = 0;
    f.*.packet_bytes = 0;
    f.*.bytes_in_seg = 0;
    return 1;
}
pub fn maybe_start_packet(arg_f: [*c]vorb) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    if (f.*.next_seg == -@as(c_int, 1)) {
        var x: c_int = @as(c_int, @bitCast(@as(u32, get8(f))));
        _ = &x;
        if (f.*.eof != 0) return 0;
        if (@as(c_int, 79) != x) return @"error"(f, @as(u32, @bitCast(VORBIS_missing_capture_pattern)));
        if (@as(c_int, 103) != @as(c_int, @bitCast(@as(u32, get8(f))))) return @"error"(f, @as(u32, @bitCast(VORBIS_missing_capture_pattern)));
        if (@as(c_int, 103) != @as(c_int, @bitCast(@as(u32, get8(f))))) return @"error"(f, @as(u32, @bitCast(VORBIS_missing_capture_pattern)));
        if (@as(c_int, 83) != @as(c_int, @bitCast(@as(u32, get8(f))))) return @"error"(f, @as(u32, @bitCast(VORBIS_missing_capture_pattern)));
        if (!(start_page_no_capturepattern(f) != 0)) return 0;
        if ((@as(c_int, @bitCast(@as(u32, f.*.page_flag))) & @as(c_int, 1)) != 0) {
            f.*.last_seg = 0;
            f.*.bytes_in_seg = 0;
            return @"error"(f, @as(u32, @bitCast(VORBIS_continued_packet_flag_invalid)));
        }
    }
    return start_packet(f);
}
pub fn next_segment(arg_f: [*c]vorb) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var len: c_int = undefined;
    _ = &len;
    if (f.*.last_seg != 0) return 0;
    if (f.*.next_seg == -@as(c_int, 1)) {
        f.*.last_seg_which = f.*.segment_count - @as(c_int, 1);
        if (!(start_page(f) != 0)) {
            f.*.last_seg = 1;
            return 0;
        }
        if (!((@as(c_int, @bitCast(@as(u32, f.*.page_flag))) & @as(c_int, 1)) != 0)) return @"error"(f, @as(u32, @bitCast(VORBIS_continued_packet_flag_invalid)));
    }
    len = @as(c_int, @bitCast(@as(u32, f.*.segments[
        @as(u32, @intCast(blk: {
            const ref = &f.*.next_seg;
            const tmp = ref.*;
            ref.* += 1;
            break :blk tmp;
        }))
    ])));
    if (len < @as(c_int, 255)) {
        f.*.last_seg = 1;
        f.*.last_seg_which = f.*.next_seg - @as(c_int, 1);
    }
    if (f.*.next_seg >= f.*.segment_count) {
        f.*.next_seg = -@as(c_int, 1);
    }
    f.*.bytes_in_seg = @as(u8, @bitCast(@as(i8, @truncate(len))));
    return len;
}
pub fn get8_packet_raw(arg_f: [*c]vorb) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    if (!(f.*.bytes_in_seg != 0)) {
        if (f.*.last_seg != 0) return -@as(c_int, 1) else if (!(next_segment(f) != 0)) return -@as(c_int, 1);
    }
    f.*.bytes_in_seg -%= 1;
    f.*.packet_bytes += 1;
    return @as(c_int, @bitCast(@as(u32, get8(f))));
}
pub fn get8_packet(arg_f: [*c]vorb) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var x: c_int = get8_packet_raw(f);
    _ = &x;
    f.*.valid_bits = 0;
    return x;
}
pub fn get32_packet(arg_f: [*c]vorb) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var x: u32 = undefined;
    _ = &x;
    x = @as(u32, @bitCast(get8_packet(f)));
    x +%= @as(u32, @bitCast(get8_packet(f) << @intCast(8)));
    x +%= @as(u32, @bitCast(get8_packet(f) << @intCast(16)));
    x +%= @as(u32, @bitCast(get8_packet(f))) << @intCast(24);
    return @as(c_int, @bitCast(x));
}
pub fn flush_packet(arg_f: [*c]vorb) callconv(.c) void {
    var f = arg_f;
    _ = &f;
    while (get8_packet_raw(f) != -@as(c_int, 1)) {}
}
pub fn get_bits(arg_f: [*c]vorb, arg_n: c_int) callconv(.c) u32 {
    var f = arg_f;
    _ = &f;
    var n = arg_n;
    _ = &n;
    var z: u32 = undefined;
    _ = &z;
    if (f.*.valid_bits < @as(c_int, 0)) return 0;
    if (f.*.valid_bits < n) {
        if (n > @as(c_int, 24)) {
            z = get_bits(f, @as(c_int, 24));
            z +%= get_bits(f, n - @as(c_int, 24)) << @intCast(24);
            return z;
        }
        if (f.*.valid_bits == @as(c_int, 0)) {
            f.*.acc = 0;
        }
        while (f.*.valid_bits < n) {
            var z_1: c_int = get8_packet_raw(f);
            _ = &z_1;
            if (z_1 == -@as(c_int, 1)) {
                f.*.valid_bits = -@as(c_int, 1);
                return 0;
            }
            f.*.acc +%= @as(u32, @bitCast(z_1 << @intCast(f.*.valid_bits)));
            f.*.valid_bits += @as(c_int, 8);
        }
    }
    z = f.*.acc & @as(u32, @bitCast((@as(c_int, 1) << @intCast(n)) - @as(c_int, 1)));
    f.*.acc >>= @intCast(n);
    f.*.valid_bits -= n;
    return z;
}
pub fn prep_huffman(arg_f: [*c]vorb) callconv(.c) void {
    var f = arg_f;
    _ = &f;
    if (f.*.valid_bits <= @as(c_int, 24)) {
        if (f.*.valid_bits == @as(c_int, 0)) {
            f.*.acc = 0;
        }
        while (true) {
            var z: c_int = undefined;
            _ = &z;
            if ((f.*.last_seg != 0) and !(f.*.bytes_in_seg != 0)) return;
            z = get8_packet_raw(f);
            if (z == -@as(c_int, 1)) return;
            f.*.acc +%= @as(u32, @bitCast(@as(u32, @bitCast(z)) << @intCast(f.*.valid_bits)));
            f.*.valid_bits += @as(c_int, 8);
            if (!(f.*.valid_bits <= @as(c_int, 24))) break;
        }
    }
}
pub const VORBIS_packet_id: c_int = 1;
pub const VORBIS_packet_comment: c_int = 3;
pub const VORBIS_packet_setup: c_int = 5;
const enum_unnamed_6 = u32;
pub fn codebook_decode_scalar_raw(arg_f: [*c]vorb, arg_c: [*c]Codebook) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var c = arg_c;
    _ = &c;
    var i: c_int = undefined;
    _ = &i;
    prep_huffman(f);
    if ((c.*.codewords == @as([*c]u32, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) and (c.*.sorted_codewords == @as([*c]u32, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0)))))))) return -@as(c_int, 1);
    if ((if (c.*.entries > @as(c_int, 8)) @intFromBool(c.*.sorted_codewords != @as([*c]u32, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) else @intFromBool(!(c.*.codewords != null))) != 0) {
        var code: u32 = bit_reverse(f.*.acc);
        _ = &code;
        var x: c_int = 0;
        _ = &x;
        var n: c_int = c.*.sorted_entries;
        _ = &n;
        var len: c_int = undefined;
        _ = &len;
        while (n > @as(c_int, 1)) {
            var m: c_int = x + (n >> @intCast(1));
            _ = &m;
            if ((blk: {
                const tmp = m;
                if (tmp >= 0) break :blk c.*.sorted_codewords + @as(usize, @intCast(tmp)) else break :blk c.*.sorted_codewords - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* <= code) {
                x = m;
                n -= n >> @intCast(1);
            } else {
                n >>= @intCast(@as(c_int, 1));
            }
        }
        if (!(c.*.sparse != 0)) {
            x = (blk: {
                const tmp = x;
                if (tmp >= 0) break :blk c.*.sorted_values + @as(usize, @intCast(tmp)) else break :blk c.*.sorted_values - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
        }
        len = @as(c_int, @bitCast(@as(u32, (blk: {
            const tmp = x;
            if (tmp >= 0) break :blk c.*.codeword_lengths + @as(usize, @intCast(tmp)) else break :blk c.*.codeword_lengths - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*)));
        if (f.*.valid_bits >= len) {
            f.*.acc >>= @intCast(len);
            f.*.valid_bits -= len;
            return x;
        }
        f.*.valid_bits = 0;
        return -@as(c_int, 1);
    }
    {
        i = 0;
        while (i < c.*.entries) : (i += 1) {
            if (@as(c_int, @bitCast(@as(u32, (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk c.*.codeword_lengths + @as(usize, @intCast(tmp)) else break :blk c.*.codeword_lengths - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*))) == @as(c_int, 255)) continue;
            if ((blk: {
                const tmp = i;
                if (tmp >= 0) break :blk c.*.codewords + @as(usize, @intCast(tmp)) else break :blk c.*.codewords - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* == (f.*.acc & @as(u32, @bitCast((@as(c_int, 1) << @intCast(@as(c_int, @bitCast(@as(u32, (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk c.*.codeword_lengths + @as(usize, @intCast(tmp)) else break :blk c.*.codeword_lengths - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*))))) - @as(c_int, 1))))) {
                if (f.*.valid_bits >= @as(c_int, @bitCast(@as(u32, (blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk c.*.codeword_lengths + @as(usize, @intCast(tmp)) else break :blk c.*.codeword_lengths - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).*)))) {
                    f.*.acc >>= @intCast(@as(c_int, @bitCast(@as(u32, (blk: {
                        const tmp = i;
                        if (tmp >= 0) break :blk c.*.codeword_lengths + @as(usize, @intCast(tmp)) else break :blk c.*.codeword_lengths - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                    }).*))));
                    f.*.valid_bits -= @as(c_int, @bitCast(@as(u32, (blk: {
                        const tmp = i;
                        if (tmp >= 0) break :blk c.*.codeword_lengths + @as(usize, @intCast(tmp)) else break :blk c.*.codeword_lengths - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                    }).*)));
                    return i;
                }
                f.*.valid_bits = 0;
                return -@as(c_int, 1);
            }
        }
    }
    _ = @"error"(f, @as(u32, @bitCast(VORBIS_invalid_stream)));
    f.*.valid_bits = 0;
    return -@as(c_int, 1);
}
pub fn codebook_decode_scalar(arg_f: [*c]vorb, arg_c: [*c]Codebook) callconv(.c) c_int {
    const f = arg_f;
    const c = arg_c;
    if (f.*.valid_bits < STB_VORBIS_FAST_HUFFMAN_LENGTH) {
        prep_huffman(f);
    }

    const idx = f.*.acc & @as(u32, FAST_HUFFMAN_TABLE_MASK);
    const code_index = @as(c_int, c.*.fast_huffman[@as(usize, idx)]);
    if (code_index >= 0) {
        const len = c.*.codeword_lengths[@as(usize, @intCast(code_index))];
        f.*.acc >>= @intCast(len);
        f.*.valid_bits -= len;
        if (f.*.valid_bits < 0) {
            f.*.valid_bits = 0;
            return -1;
        }
        return code_index;
    }

    return codebook_decode_scalar_raw(f, c);
}
pub fn codebook_decode_start(arg_f: [*c]vorb, arg_c: [*c]Codebook) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var c = arg_c;
    _ = &c;
    var z: c_int = -@as(c_int, 1);
    _ = &z;
    if (@as(c_int, @bitCast(@as(u32, c.*.lookup_type))) == @as(c_int, 0)) {
        _ = @"error"(f, @as(u32, @bitCast(VORBIS_invalid_stream)));
    } else {
        if (f.*.valid_bits < @as(c_int, 10)) {
            prep_huffman(f);
        }
        z = @as(c_int, @bitCast(f.*.acc & @as(u32, @bitCast((@as(c_int, 1) << @intCast(10)) - @as(c_int, 1)))));
        z = @as(c_int, @bitCast(@as(c_int, c.*.fast_huffman[@as(u32, @intCast(z))])));
        if (z >= @as(c_int, 0)) {
            var n: c_int = @as(c_int, @bitCast(@as(u32, (blk: {
                const tmp = z;
                if (tmp >= 0) break :blk c.*.codeword_lengths + @as(usize, @intCast(tmp)) else break :blk c.*.codeword_lengths - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*)));
            _ = &n;
            f.*.acc >>= @intCast(n);
            f.*.valid_bits -= n;
            if (f.*.valid_bits < @as(c_int, 0)) {
                f.*.valid_bits = 0;
                z = -@as(c_int, 1);
            }
        } else {
            z = codebook_decode_scalar_raw(f, c);
        }
        if (c.*.sparse != 0) {
            if (z < c.*.sorted_entries) @panic("z < c->sorted_entries");
        }
        if (z < @as(c_int, 0)) {
            if (!(f.*.bytes_in_seg != 0)) if (f.*.last_seg != 0) return z;
            _ = @"error"(f, @as(u32, @bitCast(VORBIS_invalid_stream)));
        }
    }
    return z;
}
pub fn codebook_decode(arg_f: [*c]vorb, arg_c: [*c]Codebook, arg_output: [*c]f32, arg_len: c_int) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var c = arg_c;
    _ = &c;
    var output = arg_output;
    _ = &output;
    var len = arg_len;
    _ = &len;
    var i: c_int = undefined;
    _ = &i;
    var z: c_int = codebook_decode_start(f, c);
    _ = &z;
    if (z < @as(c_int, 0)) return 0;
    if (len > c.*.dimensions) {
        len = c.*.dimensions;
    }
    z *= c.*.dimensions;
    if (c.*.sequence_p != 0) {
        var last: f32 = @as(f32, @floatFromInt(@as(c_int, 0)));
        _ = &last;
        {
            i = 0;
            while (i < len) : (i += 1) {
                var val: f32 = (blk: {
                    const tmp = z + i;
                    if (tmp >= 0) break :blk c.*.multiplicands + @as(usize, @intCast(tmp)) else break :blk c.*.multiplicands - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).* + last;
                _ = &val;
                (blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk output + @as(usize, @intCast(tmp)) else break :blk output - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).* += val;
                last = val + c.*.minimum_value;
            }
        }
    } else {
        var last: f32 = @as(f32, @floatFromInt(@as(c_int, 0)));
        _ = &last;
        {
            i = 0;
            while (i < len) : (i += 1) {
                (blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk output + @as(usize, @intCast(tmp)) else break :blk output - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).* += (blk: {
                    const tmp = z + i;
                    if (tmp >= 0) break :blk c.*.multiplicands + @as(usize, @intCast(tmp)) else break :blk c.*.multiplicands - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).* + last;
            }
        }
    }
    return 1;
}
pub fn codebook_decode_step(arg_f: [*c]vorb, arg_c: [*c]Codebook, arg_output: [*c]f32, arg_len: c_int, arg_step: c_int) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var c = arg_c;
    _ = &c;
    var output = arg_output;
    _ = &output;
    var len = arg_len;
    _ = &len;
    var step = arg_step;
    _ = &step;
    var i: c_int = undefined;
    _ = &i;
    var z: c_int = codebook_decode_start(f, c);
    _ = &z;
    var last: f32 = @as(f32, @floatFromInt(@as(c_int, 0)));
    _ = &last;
    if (z < @as(c_int, 0)) return 0;
    if (len > c.*.dimensions) {
        len = c.*.dimensions;
    }
    z *= c.*.dimensions;
    {
        i = 0;
        while (i < len) : (i += 1) {
            var val: f32 = (blk: {
                const tmp = z + i;
                if (tmp >= 0) break :blk c.*.multiplicands + @as(usize, @intCast(tmp)) else break :blk c.*.multiplicands - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* + last;
            _ = &val;
            (blk: {
                const tmp = i * step;
                if (tmp >= 0) break :blk output + @as(usize, @intCast(tmp)) else break :blk output - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* += val;
            if (c.*.sequence_p != 0) {
                last = val;
            }
        }
    }
    return 1;
}
pub fn codebook_decode_deinterleave_repeat(arg_f: [*c]vorb, arg_c: [*c]Codebook, arg_outputs: [*c][*c]f32, arg_ch: c_int, arg_c_inter_p: [*c]c_int, arg_p_inter_p: [*c]c_int, arg_len: c_int, arg_total_decode: c_int) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var c = arg_c;
    _ = &c;
    var outputs = arg_outputs;
    _ = &outputs;
    var ch = arg_ch;
    _ = &ch;
    var c_inter_p = arg_c_inter_p;
    _ = &c_inter_p;
    var p_inter_p = arg_p_inter_p;
    _ = &p_inter_p;
    var len = arg_len;
    _ = &len;
    var total_decode = arg_total_decode;
    _ = &total_decode;
    var c_inter: c_int = c_inter_p.*;
    _ = &c_inter;
    var p_inter: c_int = p_inter_p.*;
    _ = &p_inter;
    var i: c_int = undefined;
    _ = &i;
    var z: c_int = undefined;
    _ = &z;
    var effective: c_int = c.*.dimensions;
    _ = &effective;
    if (@as(c_int, @bitCast(@as(u32, c.*.lookup_type))) == @as(c_int, 0)) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_stream)));
    while (total_decode > @as(c_int, 0)) {
        var last: f32 = @as(f32, @floatFromInt(@as(c_int, 0)));
        _ = &last;
        if (f.*.valid_bits < @as(c_int, 10)) {
            prep_huffman(f);
        }
        z = @as(c_int, @bitCast(f.*.acc & @as(u32, @bitCast((@as(c_int, 1) << @intCast(10)) - @as(c_int, 1)))));
        z = @as(c_int, @bitCast(@as(c_int, c.*.fast_huffman[@as(u32, @intCast(z))])));
        if (z >= @as(c_int, 0)) {
            var n: c_int = @as(c_int, @bitCast(@as(u32, (blk: {
                const tmp = z;
                if (tmp >= 0) break :blk c.*.codeword_lengths + @as(usize, @intCast(tmp)) else break :blk c.*.codeword_lengths - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*)));
            _ = &n;
            f.*.acc >>= @intCast(n);
            f.*.valid_bits -= n;
            if (f.*.valid_bits < @as(c_int, 0)) {
                f.*.valid_bits = 0;
                z = -@as(c_int, 1);
            }
        } else {
            z = codebook_decode_scalar_raw(f, c);
        }
        if (z < 0) {
            if (!(f.*.bytes_in_seg != 0)) if (f.*.last_seg != 0) return 0;
            return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_stream)));
        }
        if (((c_inter + (p_inter * ch)) + effective) > (len * ch)) {
            effective = (len * ch) - ((p_inter * ch) - c_inter);
        }
        {
            z *= c.*.dimensions;
            if (c.*.sequence_p != 0) {
                {
                    i = 0;
                    while (i < effective) : (i += 1) {
                        var val: f32 = (blk: {
                            const tmp = z + i;
                            if (tmp >= 0) break :blk c.*.multiplicands + @as(usize, @intCast(tmp)) else break :blk c.*.multiplicands - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).* + last;
                        _ = &val;
                        if ((blk: {
                            const tmp = c_inter;
                            if (tmp >= 0) break :blk outputs + @as(usize, @intCast(tmp)) else break :blk outputs - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).* != null) {
                            (blk: {
                                const tmp = p_inter;
                                if (tmp >= 0) break :blk (blk_1: {
                                    const tmp_2 = c_inter;
                                    if (tmp_2 >= 0) break :blk_1 outputs + @as(usize, @intCast(tmp_2)) else break :blk_1 outputs - ~@as(usize, @bitCast(@as(isize, @intCast(tmp_2)) +% -1));
                                }).* + @as(usize, @intCast(tmp)) else break :blk (blk_1: {
                                    const tmp_2 = c_inter;
                                    if (tmp_2 >= 0) break :blk_1 outputs + @as(usize, @intCast(tmp_2)) else break :blk_1 outputs - ~@as(usize, @bitCast(@as(isize, @intCast(tmp_2)) +% -1));
                                }).* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                            }).* += val;
                        }
                        if ((blk: {
                            const ref = &c_inter;
                            ref.* += 1;
                            break :blk ref.*;
                        }) == ch) {
                            c_inter = 0;
                            p_inter += 1;
                        }
                        last = val;
                    }
                }
            } else {
                {
                    i = 0;
                    while (i < effective) : (i += 1) {
                        var val: f32 = (blk: {
                            const tmp = z + i;
                            if (tmp >= 0) break :blk c.*.multiplicands + @as(usize, @intCast(tmp)) else break :blk c.*.multiplicands - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).* + last;
                        _ = &val;
                        if ((blk: {
                            const tmp = c_inter;
                            if (tmp >= 0) break :blk outputs + @as(usize, @intCast(tmp)) else break :blk outputs - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).* != null) {
                            (blk: {
                                const tmp = p_inter;
                                if (tmp >= 0) break :blk (blk_1: {
                                    const tmp_2 = c_inter;
                                    if (tmp_2 >= 0) break :blk_1 outputs + @as(usize, @intCast(tmp_2)) else break :blk_1 outputs - ~@as(usize, @bitCast(@as(isize, @intCast(tmp_2)) +% -1));
                                }).* + @as(usize, @intCast(tmp)) else break :blk (blk_1: {
                                    const tmp_2 = c_inter;
                                    if (tmp_2 >= 0) break :blk_1 outputs + @as(usize, @intCast(tmp_2)) else break :blk_1 outputs - ~@as(usize, @bitCast(@as(isize, @intCast(tmp_2)) +% -1));
                                }).* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                            }).* += val;
                        }
                        if ((blk: {
                            const ref = &c_inter;
                            ref.* += 1;
                            break :blk ref.*;
                        }) == ch) {
                            c_inter = 0;
                            p_inter += 1;
                        }
                    }
                }
            }
        }
        total_decode -= effective;
    }
    c_inter_p.* = c_inter;
    p_inter_p.* = p_inter;
    return 1;
}
pub fn predict_point(arg_x: c_int, arg_x0: c_int, arg_x1: c_int, arg_y0_1: c_int, arg_y1_2: c_int) callconv(.c) c_int {
    var x = arg_x;
    _ = &x;
    var x0 = arg_x0;
    _ = &x0;
    var x1 = arg_x1;
    _ = &x1;
    var y0_1 = arg_y0_1;
    _ = &y0_1;
    var y1_2 = arg_y1_2;
    _ = &y1_2;
    var dy: c_int = y1_2 - y0_1;
    _ = &dy;
    var adx: c_int = x1 - x0;
    _ = &adx;
    var err: c_int = abs(dy) * (x - x0);
    _ = &err;
    var off: c_int = @divTrunc(err, adx);
    _ = &off;
    return if (dy < @as(c_int, 0)) y0_1 - off else y0_1 + off;
}
pub var inverse_db_table: [256]f32 = [256]f32{
    0.00000010649863213529898,
    0.00000011341951022814101,
    0.00000012079014766186447,
    0.00000012863978327004588,
    0.00000013699950329737476,
    0.0000001459025043004658,
    0.0000001553840860424316,
    0.0000001654818078122844,
    0.00000017623574422032107,
    0.00000018768855625239667,
    0.0000001998856049567621,
    0.0000002128753067154321,
    0.00000022670913324418507,
    0.00000024144196686393116,
    0.00000025713222839840455,
    0.0000002738421187586937,
    0.00000029163791737119027,
    0.0000003105902237621194,
    0.00000033077409966608684,
    0.00000035226966588197683,
    0.00000037516213069466176,
    0.00000039954230146577174,
    0.00000042550681200737017,
    0.0000004531586341727234,
    0.0000004826074473385233,
    0.0000005139700078871101,
    0.0000005473706323755323,
    0.0000005829418796565733,
    0.0000006208247214090079,
    0.0000006611693947888853,
    0.0000007041359140202985,
    0.0000007498946388295735,
    0.000000798627013409714,
    0.0000008505263053848466,
    0.0000009057982879312476,
    0.0000009646621492720442,
    0.0000010273513453284977,
    0.0000010941143955278676,
    0.0000011652160765152075,
    0.0000012409384453349048,
    0.0000013215816352385445,
    0.0000014074654473006376,
    0.000001498930487286998,
    0.0000015963394162099576,
    0.0000017000785419440945,
    0.0000018105591834682855,
    0.0000019282194898551097,
    0.0000020535260318865767,
    0.0000021869757347303675,
    0.0000023290976969292387,
    0.0000024804558051982895,
    0.0000026416496439196635,
    0.000002813319042616058,
    0.0000029961443033243995,
    0.000003190850520695676,
    0.0000033982100831053685,
    0.000003619044946390204,
    0.000003854230726574315,
    0.0000041047005652217194,
    0.000004371447175799403,
    0.000004655528300645528,
    0.000004958070803695591,
    0.000005280273853713879,
    0.000005623416200251086,
    0.00000598885708313901,
    0.0000063780466916796286,
    0.000006792528438381851,
    0.000007233945325424429,
    0.000007704047675360925,
    0.000008204699952329975,
    0.000008737887583265547,
    0.000009305725143349264,
    0.000009910463631968014,
    0.000010554501386650372,
    0.000011240392268518917,
    0.00001197085566673195,
    0.000012748789231409319,
    0.000013577277968579438,
    0.000014459606063610408,
    0.00001539927143312525,
    0.000016400004824390635,
    0.000017465768905822188,
    0.000018600792827783152,
    0.000019809576770057902,
    0.00002109691376972478,
    0.00002246791154902894,
    0.000023928001610329375,
    0.000025482977434876375,
    0.00002713900539674796,
    0.000028902650228701532,
    0.000030780909582972527,
    0.000032781226764200255,
    0.00003491153256618418,
    0.000037180281651671976,
    0.00003959646710427478,
    0.00004216966772219166,
    0.00004491009167395532,
    0.000047828601964283735,
    0.00005093677464174107,
    0.00005424693154054694,
    0.00005777220212621614,
    0.00006152656715130433,
    0.00006552490958711132,
    0.00006978308374527842,
    0.00007431798439938575,
    0.00007914758316474035,
    0.00008429103763774037,
    0.00008976874960353598,
    0.00009560242324369028,
    0.00010181521065533161,
    0.00010843174095498398,
    0.0001154782366938889,
    0.00012298267392907292,
    0.00013097477494738996,
    0.00013948624837212265,
    0.00014855085464660078,
    0.00015820453700143844,
    0.000168485552421771,
    0.00017943468992598355,
    0.00019109535787720233,
    0.00020351381681393832,
    0.00021673929586540908,
    0.0002308242255821824,
    0.00024582448531873524,
    0.0002617995487526059,
    0.0002788127458188683,
    0.0002969315683003515,
    0.00031622787355445325,
    0.00033677814644761384,
    0.0003586638777051121,
    0.0003819718840532005,
    0.0004067945701535791,
    0.00043323036516085267,
    0.0004613841010723263,
    0.000491367478389293,
    0.0005232992698438466,
    0.0005573062226176262,
    0.0005935230874456465,
    0.0006320935790427029,
    0.000673170608934015,
    0.0007169169839471579,
    0.0007635062793269753,
    0.0008131232461892068,
    0.0008659645682200789,
    0.0009222398512065411,
    0.0009821722051128745,
    0.001045999233610928,
    0.0011139742564409971,
    0.0011863665422424674,
    0.001263463287614286,
    0.0013455701991915703,
    0.0014330128906294703,
    0.0015261381631717086,
    0.00162531528621912,
    0.0017309373943135142,
    0.0018434234661981463,
    0.001963219605386257,
    0.002090800553560257,
    0.002226672600954771,
    0.002371374284848571,
    0.002525479532778263,
    0.0026895992923527956,
    0.0028643847908824682,
    0.0030505286995321512,
    0.0032487690914422274,
    0.0034598924685269594,
    0.003684735856950283,
    0.003924190532416105,
    0.0041792066767811775,
    0.004450794775038958,
    0.004740032833069563,
    0.005048066843301058,
    0.005376118700951338,
    0.005725488997995853,
    0.0060975635424256325,
    0.006493817549198866,
    0.006915822625160217,
    0.007365251425653696,
    0.00784388743340969,
    0.008353627286851406,
    0.008896492421627045,
    0.009474636986851692,
    0.010090352036058903,
    0.010746080428361893,
    0.01144442055374384,
    0.012188144028186798,
    0.012980197556316853,
    0.013823725283145905,
    0.0147220678627491,
    0.01567879132926464,
    0.016697686165571213,
    0.017782796174287796,
    0.018938422203063965,
    0.020169148221611977,
    0.021479854360222816,
    0.02287573553621769,
    0.02436232939362526,
    0.025945531204342842,
    0.027631618082523346,
    0.02942727692425251,
    0.031339626759290695,
    0.03337625041604042,
    0.0355452261865139,
    0.037855155766010284,
    0.04031519964337349,
    0.04293510690331459,
    0.045725274831056595,
    0.04869675636291504,
    0.05186134949326515,
    0.05523158982396126,
    0.058820851147174835,
    0.06264336407184601,
    0.06671427935361862,
    0.0710497498512268,
    0.07566696405410767,
    0.08058422803878784,
    0.08582104742527008,
    0.09139817953109741,
    0.0973377451300621,
    0.10366330295801163,
    0.11039993166923523,
    0.11757434159517288,
    0.12521497905254364,
    0.1333521455526352,
    0.142018124461174,
    0.15124726295471191,
    0.16107617318630219,
    0.17154380679130554,
    0.18269167840480804,
    0.19456401467323303,
    0.20720787346363068,
    0.22067342698574066,
    0.23501402139663696,
    0.2502865493297577,
    0.26655158400535583,
    0.28387361764907837,
    0.30232131481170654,
    0.32196786999702454,
    0.342891126871109,
    0.36517414450645447,
    0.38890519738197327,
    0.4141784608364105,
    0.44109413027763367,
    0.46975889801979065,
    0.5002864599227905,
    0.5327979326248169,
    0.567422091960907,
    0.6042963862419128,
    0.6435669660568237,
    0.6853895783424377,
    0.72993004322052,
    0.7773650288581848,
    0.8278825879096985,
    0.8816830515861511,
    0.9389798045158386,
    1.0,
};
pub fn draw_line(arg_output: [*c]f32, arg_x0: c_int, arg_y0_1: c_int, arg_x1: c_int, arg_y1_2: c_int, arg_n: c_int) callconv(.c) void {
    var output = arg_output;
    _ = &output;
    var x0 = arg_x0;
    _ = &x0;
    var y0_1 = arg_y0_1;
    _ = &y0_1;
    var x1 = arg_x1;
    _ = &x1;
    var y1_2 = arg_y1_2;
    _ = &y1_2;
    var n = arg_n;
    _ = &n;
    var dy: c_int = y1_2 - y0_1;
    _ = &dy;
    var adx: c_int = x1 - x0;
    _ = &adx;
    var ady: c_int = abs(dy);
    _ = &ady;
    var base: c_int = undefined;
    _ = &base;
    var x: c_int = x0;
    _ = &x;
    var y: c_int = y0_1;
    _ = &y;
    var err: c_int = 0;
    _ = &err;
    var sy: c_int = undefined;
    _ = &sy;
    if (adx < DIVTAB_DENOM and ady < DIVTAB_NUMER) {
        if (dy < 0) {
            base = -@as(c_int, @intCast(integer_divide_table[@as(usize, @intCast(ady))][@as(usize, @intCast(adx))]));
            sy = base - 1;
        } else {
            base = @as(c_int, @intCast(integer_divide_table[@as(usize, @intCast(ady))][@as(usize, @intCast(adx))]));
            sy = base + 1;
        }
    } else {
        base = @divTrunc(dy, adx);
        if (dy < @as(c_int, 0)) {
            sy = base - @as(c_int, 1);
        } else {
            sy = base + @as(c_int, 1);
        }
    }
    ady -= abs(base) * adx;
    if (x1 > n) {
        x1 = n;
    }
    if (x < x1) {
        (blk: {
            const tmp = x;
            if (tmp >= 0) break :blk output + @as(usize, @intCast(tmp)) else break :blk output - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* *= inverse_db_table[@as(u32, @intCast(y & @as(c_int, 255)))];
        {
            x += 1;
            while (x < x1) : (x += 1) {
                err += ady;
                if (err >= adx) {
                    err -= adx;
                    y += sy;
                } else {
                    y += base;
                }
                (blk: {
                    const tmp = x;
                    if (tmp >= 0) break :blk output + @as(usize, @intCast(tmp)) else break :blk output - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).* *= inverse_db_table[@as(u32, @intCast(y & @as(c_int, 255)))];
            }
        }
    }
}
pub fn residue_decode(arg_f: [*c]vorb, arg_book: [*c]Codebook, arg_target: [*c]f32, arg_offset: c_int, arg_n: c_int, arg_rtype: c_int) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var book = arg_book;
    _ = &book;
    var target = arg_target;
    _ = &target;
    var offset = arg_offset;
    _ = &offset;
    var n = arg_n;
    _ = &n;
    var rtype = arg_rtype;
    _ = &rtype;
    var k: c_int = undefined;
    _ = &k;
    if (rtype == @as(c_int, 0)) {
        var step: c_int = @divTrunc(n, book.*.dimensions);
        _ = &step;
        {
            k = 0;
            while (k < step) : (k += 1) if (!(codebook_decode_step(f, book, (target + @as(usize, @bitCast(@as(isize, @intCast(offset))))) + @as(usize, @bitCast(@as(isize, @intCast(k)))), (n - offset) - k, step) != 0)) return 0;
        }
    } else {
        {
            k = 0;
            while (k < n) {
                if (!(codebook_decode(f, book, target + @as(usize, @bitCast(@as(isize, @intCast(offset)))), n - k) != 0)) return 0;
                k += book.*.dimensions;
                offset += book.*.dimensions;
            }
        }
    }
    return 1;
}
pub export fn decode_residue(arg_f: [*c]vorb, arg_residue_buffers: [*c][*c]f32, arg_ch: c_int, arg_n: c_int, arg_rn: c_int, arg_do_not_decode: [*c]u8) callconv(.c) void {
    const f = arg_f;
    const residue_buffers = arg_residue_buffers;
    const ch = arg_ch;
    const n = arg_n;
    const rn = arg_rn;
    const do_not_decode = arg_do_not_decode;

    const r = f.*.residue_config + @as(usize, @intCast(rn));
    const rtype = f.*.residue_types[@as(usize, @intCast(rn))];
    const c = r.*.classbook;
    const classwords = f.*.codebooks[@as(usize, @intCast(c))].dimensions;
    const actual_size: u32 = if (rtype == 2) @as(u32, @intCast(n * 2)) else @as(u32, @intCast(n));
    const limit_r_begin: u32 = if (r.*.begin < actual_size) r.*.begin else actual_size;
    const limit_r_end: u32 = if (r.*.end < actual_size) r.*.end else actual_size;
    const n_read = @as(c_int, @intCast(limit_r_end - limit_r_begin));
    const part_read = @divTrunc(n_read, @as(c_int, @intCast(r.*.part_size)));
    const temp_alloc_point = temp_alloc_save(f);

    // Using part_classdata (STB_VORBIS_DIVIDES_IN_RESIDUE not defined)
    const part_classdata = @as([*c][*c][*c]u8, @ptrCast(@alignCast(temp_block_array(f, f.*.channels, part_read * @sizeOf([*c][*c]u8)))));

    CHECK(f);

    var i: c_int = 0;
    while (i < ch) : (i += 1) {
        if (do_not_decode[@as(usize, @intCast(i))] == 0) {
            @memset(residue_buffers[@as(usize, @intCast(i))][0..@as(usize, @intCast(n))], 0);
        }
    }

    done: {
        if (rtype == 2 and ch != 1) {
            var j: c_int = 0;
            while (j < ch) : (j += 1) {
                if (do_not_decode[@as(usize, @intCast(j))] == 0) break;
            }
            if (j == ch) break :done;

            var pass: c_int = 0;
            while (pass < 8) : (pass += 1) {
                var pcount: c_int = 0;
                var class_set: c_int = 0;

                if (ch == 2) {
                    while (pcount < part_read) {
                        var z = r.*.begin + @as(u32, @intCast(pcount)) * r.*.part_size;
                        var c_inter: c_int = @as(c_int, @intCast(z & 1));
                        var p_inter: c_int = @as(c_int, @intCast(z >> 1));

                        if (pass == 0) {
                            const codebook = f.*.codebooks + @as(usize, @intCast(r.*.classbook));
                            var q = codebook_decode_scalar(f, codebook);
                            if (codebook.*.sparse != 0) q = codebook.*.sorted_values[@as(usize, @intCast(q))];
                            if (q == EOP) break :done;
                            part_classdata[@as(usize, 0)][@as(usize, @intCast(class_set))] = r.*.classdata[@as(usize, @intCast(q))];
                        }

                        i = 0;
                        while (i < classwords and pcount < part_read) : ({
                            i += 1;
                            pcount += 1;
                        }) {
                            z = r.*.begin + @as(u32, @intCast(pcount)) * r.*.part_size;
                            const cls = part_classdata[@as(usize, 0)][@as(usize, @intCast(class_set))][@as(usize, @intCast(i))];
                            const b = r.*.residue_books[@as(usize, @intCast(cls))][@as(usize, @intCast(pass))];
                            if (b >= 0) {
                                const book = f.*.codebooks + @as(usize, @intCast(b));
                                if (codebook_decode_deinterleave_repeat(f, book, residue_buffers, ch, &c_inter, &p_inter, n, @as(c_int, @intCast(r.*.part_size))) == 0) {
                                    break :done;
                                }
                            } else {
                                z += r.*.part_size;
                                c_inter = @as(c_int, @intCast(z & 1));
                                p_inter = @as(c_int, @intCast(z >> 1));
                            }
                        }
                        class_set += 1;
                    }
                } else if (ch > 2) {
                    while (pcount < part_read) {
                        var z = r.*.begin + @as(u32, @intCast(pcount)) * r.*.part_size;
                        var c_inter: c_int = @as(c_int, @intCast(@mod(z, @as(u32, @intCast(ch)))));
                        var p_inter: c_int = @as(c_int, @intCast(@divTrunc(z, @as(u32, @intCast(ch)))));

                        if (pass == 0) {
                            const codebook = f.*.codebooks + @as(usize, @intCast(r.*.classbook));
                            var q = codebook_decode_scalar(f, codebook);
                            if (codebook.*.sparse != 0) q = codebook.*.sorted_values[@as(usize, @intCast(q))];
                            if (q == EOP) break :done;
                            part_classdata[@as(usize, 0)][@as(usize, @intCast(class_set))] = r.*.classdata[@as(usize, @intCast(q))];
                        }

                        i = 0;
                        while (i < classwords and pcount < part_read) : ({
                            i += 1;
                            pcount += 1;
                        }) {
                            z = r.*.begin + @as(u32, @intCast(pcount)) * r.*.part_size;
                            const cls = part_classdata[@as(usize, 0)][@as(usize, @intCast(class_set))][@as(usize, @intCast(i))];
                            const b = r.*.residue_books[@as(usize, @intCast(cls))][@as(usize, @intCast(pass))];
                            if (b >= 0) {
                                const book = f.*.codebooks + @as(usize, @intCast(b));
                                if (codebook_decode_deinterleave_repeat(f, book, residue_buffers, ch, &c_inter, &p_inter, n, @as(c_int, @intCast(r.*.part_size))) == 0) {
                                    break :done;
                                }
                            } else {
                                z += r.*.part_size;
                                c_inter = @as(c_int, @intCast(@mod(z, @as(u32, @intCast(ch)))));
                                p_inter = @as(c_int, @intCast(@divTrunc(z, @as(u32, @intCast(ch)))));
                            }
                        }
                        class_set += 1;
                    }
                }
            }
            break :done;
        }

        CHECK(f);

        var pass: c_int = 0;
        while (pass < 8) : (pass += 1) {
            var pcount: c_int = 0;
            var class_set: c_int = 0;

            while (pcount < part_read) {
                if (pass == 0) {
                    var j: c_int = 0;
                    while (j < ch) : (j += 1) {
                        if (do_not_decode[@as(usize, @intCast(j))] == 0) {
                            const codebook = f.*.codebooks + @as(usize, @intCast(r.*.classbook));
                            var temp = codebook_decode_scalar(f, codebook);
                            if (codebook.*.sparse != 0) temp = codebook.*.sorted_values[@as(usize, @intCast(temp))];
                            if (temp == EOP) break :done;
                            part_classdata[@as(usize, @intCast(j))][@as(usize, @intCast(class_set))] = r.*.classdata[@as(usize, @intCast(temp))];
                        }
                    }
                }

                i = 0;
                while (i < classwords and pcount < part_read) : ({
                    i += 1;
                    pcount += 1;
                }) {
                    var j: c_int = 0;
                    while (j < ch) : (j += 1) {
                        if (do_not_decode[@as(usize, @intCast(j))] == 0) {
                            const cls = part_classdata[@as(usize, @intCast(j))][@as(usize, @intCast(class_set))][@as(usize, @intCast(i))];
                            const b = r.*.residue_books[@as(usize, @intCast(cls))][@as(usize, @intCast(pass))];
                            if (b >= 0) {
                                const target = residue_buffers[@as(usize, @intCast(j))];
                                const offset = @as(c_int, @intCast(r.*.begin)) + pcount * @as(c_int, @intCast(r.*.part_size));
                                const part_size = @as(c_int, @intCast(r.*.part_size));
                                const book = f.*.codebooks + @as(usize, @intCast(b));
                                if (residue_decode(f, book, target, offset, part_size, rtype) == 0) {
                                    break :done;
                                }
                            }
                        }
                    }
                }
                class_set += 1;
            }
        }
    }

    CHECK(f);
    temp_free(f, part_classdata);
    temp_alloc_restore(f, temp_alloc_point);
}
pub fn imdct_step3_iter0_loop(arg_n: c_int, arg_e: [*c]f32, arg_i_off: c_int, arg_k_off: c_int, arg_A: [*c]f32) callconv(.c) void {
    var n = arg_n;
    _ = &n;
    var e = arg_e;
    _ = &e;
    var i_off = arg_i_off;
    _ = &i_off;
    var k_off = arg_k_off;
    _ = &k_off;
    var A = arg_A;
    _ = &A;
    var ee0: [*c]f32 = e + @as(usize, @bitCast(@as(isize, @intCast(i_off))));
    _ = &ee0;
    var ee2: [*c]f32 = ee0 + @as(usize, @bitCast(@as(isize, @intCast(k_off))));
    _ = &ee2;
    var i: c_int = undefined;
    _ = &i;
    {
        i = n >> @intCast(2);
        while (i > @as(c_int, 0)) : (i -= 1) {
            var k00_20: f32 = undefined;
            _ = &k00_20;
            var k01_21: f32 = undefined;
            _ = &k01_21;
            k00_20 = ee0[@as(u32, @intCast(@as(c_int, 0)))] - ee2[@as(u32, @intCast(@as(c_int, 0)))];
            k01_21 = (blk: {
                const tmp = -@as(c_int, 1);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 1);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            ee0[@as(u32, @intCast(@as(c_int, 0)))] += ee2[@as(u32, @intCast(@as(c_int, 0)))];
            (blk: {
                const tmp = -@as(c_int, 1);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* += (blk: {
                const tmp = -@as(c_int, 1);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            ee2[@as(u32, @intCast(@as(c_int, 0)))] = (k00_20 * A[@as(u32, @intCast(@as(c_int, 0)))]) - (k01_21 * A[@as(u32, @intCast(@as(c_int, 1)))]);
            (blk: {
                const tmp = -@as(c_int, 1);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k01_21 * A[@as(u32, @intCast(@as(c_int, 0)))]) + (k00_20 * A[@as(u32, @intCast(@as(c_int, 1)))]);
            A += @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 8)))));
            k00_20 = (blk: {
                const tmp = -@as(c_int, 2);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 2);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            k01_21 = (blk: {
                const tmp = -@as(c_int, 3);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 3);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 2);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* += (blk: {
                const tmp = -@as(c_int, 2);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 3);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* += (blk: {
                const tmp = -@as(c_int, 3);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 2);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k00_20 * A[@as(u32, @intCast(@as(c_int, 0)))]) - (k01_21 * A[@as(u32, @intCast(@as(c_int, 1)))]);
            (blk: {
                const tmp = -@as(c_int, 3);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k01_21 * A[@as(u32, @intCast(@as(c_int, 0)))]) + (k00_20 * A[@as(u32, @intCast(@as(c_int, 1)))]);
            A += @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 8)))));
            k00_20 = (blk: {
                const tmp = -@as(c_int, 4);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 4);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            k01_21 = (blk: {
                const tmp = -@as(c_int, 5);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 5);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 4);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* += (blk: {
                const tmp = -@as(c_int, 4);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 5);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* += (blk: {
                const tmp = -@as(c_int, 5);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 4);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k00_20 * A[@as(u32, @intCast(@as(c_int, 0)))]) - (k01_21 * A[@as(u32, @intCast(@as(c_int, 1)))]);
            (blk: {
                const tmp = -@as(c_int, 5);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k01_21 * A[@as(u32, @intCast(@as(c_int, 0)))]) + (k00_20 * A[@as(u32, @intCast(@as(c_int, 1)))]);
            A += @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 8)))));
            k00_20 = (blk: {
                const tmp = -@as(c_int, 6);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 6);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            k01_21 = (blk: {
                const tmp = -@as(c_int, 7);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 7);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 6);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* += (blk: {
                const tmp = -@as(c_int, 6);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 7);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* += (blk: {
                const tmp = -@as(c_int, 7);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 6);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k00_20 * A[@as(u32, @intCast(@as(c_int, 0)))]) - (k01_21 * A[@as(u32, @intCast(@as(c_int, 1)))]);
            (blk: {
                const tmp = -@as(c_int, 7);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k01_21 * A[@as(u32, @intCast(@as(c_int, 0)))]) + (k00_20 * A[@as(u32, @intCast(@as(c_int, 1)))]);
            A += @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 8)))));
            ee0 -= @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 8)))));
            ee2 -= @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 8)))));
        }
    }
}
pub fn imdct_step3_inner_r_loop(arg_lim: c_int, arg_e: [*c]f32, arg_d0: c_int, arg_k_off: c_int, arg_A: [*c]f32, arg_k1: c_int) callconv(.c) void {
    var lim = arg_lim;
    _ = &lim;
    var e = arg_e;
    _ = &e;
    var d0 = arg_d0;
    _ = &d0;
    var k_off = arg_k_off;
    _ = &k_off;
    var A = arg_A;
    _ = &A;
    var k1 = arg_k1;
    _ = &k1;
    var i: c_int = undefined;
    _ = &i;
    var k00_20: f32 = undefined;
    _ = &k00_20;
    var k01_21: f32 = undefined;
    _ = &k01_21;
    var e0: [*c]f32 = e + @as(usize, @bitCast(@as(isize, @intCast(d0))));
    _ = &e0;
    var e2: [*c]f32 = e0 + @as(usize, @bitCast(@as(isize, @intCast(k_off))));
    _ = &e2;
    {
        i = lim >> @intCast(2);
        while (i > @as(c_int, 0)) : (i -= 1) {
            k00_20 = (blk: {
                const tmp = -@as(c_int, 0);
                if (tmp >= 0) break :blk e0 + @as(usize, @intCast(tmp)) else break :blk e0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 0);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            k01_21 = (blk: {
                const tmp = -@as(c_int, 1);
                if (tmp >= 0) break :blk e0 + @as(usize, @intCast(tmp)) else break :blk e0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 1);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 0);
                if (tmp >= 0) break :blk e0 + @as(usize, @intCast(tmp)) else break :blk e0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* += (blk: {
                const tmp = -@as(c_int, 0);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 1);
                if (tmp >= 0) break :blk e0 + @as(usize, @intCast(tmp)) else break :blk e0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* += (blk: {
                const tmp = -@as(c_int, 1);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 0);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k00_20 * A[@as(u32, @intCast(@as(c_int, 0)))]) - (k01_21 * A[@as(u32, @intCast(@as(c_int, 1)))]);
            (blk: {
                const tmp = -@as(c_int, 1);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k01_21 * A[@as(u32, @intCast(@as(c_int, 0)))]) + (k00_20 * A[@as(u32, @intCast(@as(c_int, 1)))]);
            A += @as(usize, @bitCast(@as(isize, @intCast(k1))));
            k00_20 = (blk: {
                const tmp = -@as(c_int, 2);
                if (tmp >= 0) break :blk e0 + @as(usize, @intCast(tmp)) else break :blk e0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 2);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            k01_21 = (blk: {
                const tmp = -@as(c_int, 3);
                if (tmp >= 0) break :blk e0 + @as(usize, @intCast(tmp)) else break :blk e0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 3);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 2);
                if (tmp >= 0) break :blk e0 + @as(usize, @intCast(tmp)) else break :blk e0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* += (blk: {
                const tmp = -@as(c_int, 2);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 3);
                if (tmp >= 0) break :blk e0 + @as(usize, @intCast(tmp)) else break :blk e0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* += (blk: {
                const tmp = -@as(c_int, 3);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 2);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k00_20 * A[@as(u32, @intCast(@as(c_int, 0)))]) - (k01_21 * A[@as(u32, @intCast(@as(c_int, 1)))]);
            (blk: {
                const tmp = -@as(c_int, 3);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k01_21 * A[@as(u32, @intCast(@as(c_int, 0)))]) + (k00_20 * A[@as(u32, @intCast(@as(c_int, 1)))]);
            A += @as(usize, @bitCast(@as(isize, @intCast(k1))));
            k00_20 = (blk: {
                const tmp = -@as(c_int, 4);
                if (tmp >= 0) break :blk e0 + @as(usize, @intCast(tmp)) else break :blk e0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 4);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            k01_21 = (blk: {
                const tmp = -@as(c_int, 5);
                if (tmp >= 0) break :blk e0 + @as(usize, @intCast(tmp)) else break :blk e0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 5);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 4);
                if (tmp >= 0) break :blk e0 + @as(usize, @intCast(tmp)) else break :blk e0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* += (blk: {
                const tmp = -@as(c_int, 4);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 5);
                if (tmp >= 0) break :blk e0 + @as(usize, @intCast(tmp)) else break :blk e0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* += (blk: {
                const tmp = -@as(c_int, 5);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 4);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k00_20 * A[@as(u32, @intCast(@as(c_int, 0)))]) - (k01_21 * A[@as(u32, @intCast(@as(c_int, 1)))]);
            (blk: {
                const tmp = -@as(c_int, 5);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k01_21 * A[@as(u32, @intCast(@as(c_int, 0)))]) + (k00_20 * A[@as(u32, @intCast(@as(c_int, 1)))]);
            A += @as(usize, @bitCast(@as(isize, @intCast(k1))));
            k00_20 = (blk: {
                const tmp = -@as(c_int, 6);
                if (tmp >= 0) break :blk e0 + @as(usize, @intCast(tmp)) else break :blk e0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 6);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            k01_21 = (blk: {
                const tmp = -@as(c_int, 7);
                if (tmp >= 0) break :blk e0 + @as(usize, @intCast(tmp)) else break :blk e0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 7);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 6);
                if (tmp >= 0) break :blk e0 + @as(usize, @intCast(tmp)) else break :blk e0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* += (blk: {
                const tmp = -@as(c_int, 6);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 7);
                if (tmp >= 0) break :blk e0 + @as(usize, @intCast(tmp)) else break :blk e0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* += (blk: {
                const tmp = -@as(c_int, 7);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 6);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k00_20 * A[@as(u32, @intCast(@as(c_int, 0)))]) - (k01_21 * A[@as(u32, @intCast(@as(c_int, 1)))]);
            (blk: {
                const tmp = -@as(c_int, 7);
                if (tmp >= 0) break :blk e2 + @as(usize, @intCast(tmp)) else break :blk e2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k01_21 * A[@as(u32, @intCast(@as(c_int, 0)))]) + (k00_20 * A[@as(u32, @intCast(@as(c_int, 1)))]);
            e0 -= @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 8)))));
            e2 -= @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 8)))));
            A += @as(usize, @bitCast(@as(isize, @intCast(k1))));
        }
    }
}
pub fn imdct_step3_inner_s_loop(arg_n: c_int, arg_e: [*c]f32, arg_i_off: c_int, arg_k_off: c_int, arg_A: [*c]f32, arg_a_off: c_int, arg_k0: c_int) callconv(.c) void {
    var n = arg_n;
    _ = &n;
    var e = arg_e;
    _ = &e;
    var i_off = arg_i_off;
    _ = &i_off;
    var k_off = arg_k_off;
    _ = &k_off;
    var A = arg_A;
    _ = &A;
    var a_off = arg_a_off;
    _ = &a_off;
    var k0 = arg_k0;
    _ = &k0;
    var i: c_int = undefined;
    _ = &i;
    var A0: f32 = A[@as(u32, @intCast(@as(c_int, 0)))];
    _ = &A0;
    var A1: f32 = (blk: {
        const tmp = @as(c_int, 0) + @as(c_int, 1);
        if (tmp >= 0) break :blk A + @as(usize, @intCast(tmp)) else break :blk A - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*;
    _ = &A1;
    var A2: f32 = (blk: {
        const tmp = @as(c_int, 0) + a_off;
        if (tmp >= 0) break :blk A + @as(usize, @intCast(tmp)) else break :blk A - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*;
    _ = &A2;
    var A3: f32 = (blk: {
        const tmp = (@as(c_int, 0) + a_off) + @as(c_int, 1);
        if (tmp >= 0) break :blk A + @as(usize, @intCast(tmp)) else break :blk A - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*;
    _ = &A3;
    var A4: f32 = (blk: {
        const tmp = (@as(c_int, 0) + (a_off * @as(c_int, 2))) + @as(c_int, 0);
        if (tmp >= 0) break :blk A + @as(usize, @intCast(tmp)) else break :blk A - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*;
    _ = &A4;
    var A5: f32 = (blk: {
        const tmp = (@as(c_int, 0) + (a_off * @as(c_int, 2))) + @as(c_int, 1);
        if (tmp >= 0) break :blk A + @as(usize, @intCast(tmp)) else break :blk A - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*;
    _ = &A5;
    var A6: f32 = (blk: {
        const tmp = (@as(c_int, 0) + (a_off * @as(c_int, 3))) + @as(c_int, 0);
        if (tmp >= 0) break :blk A + @as(usize, @intCast(tmp)) else break :blk A - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*;
    _ = &A6;
    var A7: f32 = (blk: {
        const tmp = (@as(c_int, 0) + (a_off * @as(c_int, 3))) + @as(c_int, 1);
        if (tmp >= 0) break :blk A + @as(usize, @intCast(tmp)) else break :blk A - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*;
    _ = &A7;
    var k00: f32 = undefined;
    _ = &k00;
    var k11: f32 = undefined;
    _ = &k11;
    var ee0: [*c]f32 = e + @as(usize, @bitCast(@as(isize, @intCast(i_off))));
    _ = &ee0;
    var ee2: [*c]f32 = ee0 + @as(usize, @bitCast(@as(isize, @intCast(k_off))));
    _ = &ee2;
    {
        i = n;
        while (i > @as(c_int, 0)) : (i -= 1) {
            k00 = ee0[@as(u32, @intCast(@as(c_int, 0)))] - ee2[@as(u32, @intCast(@as(c_int, 0)))];
            k11 = (blk: {
                const tmp = -@as(c_int, 1);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 1);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            ee0[@as(u32, @intCast(@as(c_int, 0)))] = ee0[@as(u32, @intCast(@as(c_int, 0)))] + ee2[@as(u32, @intCast(@as(c_int, 0)))];
            (blk: {
                const tmp = -@as(c_int, 1);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (blk: {
                const tmp = -@as(c_int, 1);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* + (blk: {
                const tmp = -@as(c_int, 1);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            ee2[@as(u32, @intCast(@as(c_int, 0)))] = (k00 * A0) - (k11 * A1);
            (blk: {
                const tmp = -@as(c_int, 1);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k11 * A0) + (k00 * A1);
            k00 = (blk: {
                const tmp = -@as(c_int, 2);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 2);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            k11 = (blk: {
                const tmp = -@as(c_int, 3);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 3);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 2);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (blk: {
                const tmp = -@as(c_int, 2);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* + (blk: {
                const tmp = -@as(c_int, 2);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 3);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (blk: {
                const tmp = -@as(c_int, 3);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* + (blk: {
                const tmp = -@as(c_int, 3);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 2);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k00 * A2) - (k11 * A3);
            (blk: {
                const tmp = -@as(c_int, 3);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k11 * A2) + (k00 * A3);
            k00 = (blk: {
                const tmp = -@as(c_int, 4);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 4);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            k11 = (blk: {
                const tmp = -@as(c_int, 5);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 5);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 4);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (blk: {
                const tmp = -@as(c_int, 4);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* + (blk: {
                const tmp = -@as(c_int, 4);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 5);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (blk: {
                const tmp = -@as(c_int, 5);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* + (blk: {
                const tmp = -@as(c_int, 5);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 4);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k00 * A4) - (k11 * A5);
            (blk: {
                const tmp = -@as(c_int, 5);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k11 * A4) + (k00 * A5);
            k00 = (blk: {
                const tmp = -@as(c_int, 6);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 6);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            k11 = (blk: {
                const tmp = -@as(c_int, 7);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* - (blk: {
                const tmp = -@as(c_int, 7);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 6);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (blk: {
                const tmp = -@as(c_int, 6);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* + (blk: {
                const tmp = -@as(c_int, 6);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 7);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (blk: {
                const tmp = -@as(c_int, 7);
                if (tmp >= 0) break :blk ee0 + @as(usize, @intCast(tmp)) else break :blk ee0 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* + (blk: {
                const tmp = -@as(c_int, 7);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*;
            (blk: {
                const tmp = -@as(c_int, 6);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k00 * A6) - (k11 * A7);
            (blk: {
                const tmp = -@as(c_int, 7);
                if (tmp >= 0) break :blk ee2 + @as(usize, @intCast(tmp)) else break :blk ee2 - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = (k11 * A6) + (k00 * A7);
            ee0 -= @as(usize, @bitCast(@as(isize, @intCast(k0))));
            ee2 -= @as(usize, @bitCast(@as(isize, @intCast(k0))));
        }
    }
}
pub fn iter_54(arg_z: [*c]f32) callconv(.c) void {
    var z = arg_z;
    _ = &z;
    var k00: f32 = undefined;
    _ = &k00;
    var k11: f32 = undefined;
    _ = &k11;
    var k22: f32 = undefined;
    _ = &k22;
    var k33: f32 = undefined;
    _ = &k33;
    var y0_1: f32 = undefined;
    _ = &y0_1;
    var y1_2: f32 = undefined;
    _ = &y1_2;
    var y2: f32 = undefined;
    _ = &y2;
    var y3: f32 = undefined;
    _ = &y3;
    k00 = z[@as(u32, @intCast(@as(c_int, 0)))] - (blk: {
        const tmp = -@as(c_int, 4);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*;
    y0_1 = z[@as(u32, @intCast(@as(c_int, 0)))] + (blk: {
        const tmp = -@as(c_int, 4);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*;
    y2 = (blk: {
        const tmp = -@as(c_int, 2);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).* + (blk: {
        const tmp = -@as(c_int, 6);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*;
    k22 = (blk: {
        const tmp = -@as(c_int, 2);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).* - (blk: {
        const tmp = -@as(c_int, 6);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*;
    (blk: {
        const tmp = -@as(c_int, 0);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).* = y0_1 + y2;
    (blk: {
        const tmp = -@as(c_int, 2);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).* = y0_1 - y2;
    k33 = (blk: {
        const tmp = -@as(c_int, 3);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).* - (blk: {
        const tmp = -@as(c_int, 7);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*;
    (blk: {
        const tmp = -@as(c_int, 4);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).* = k00 + k33;
    (blk: {
        const tmp = -@as(c_int, 6);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).* = k00 - k33;
    k11 = (blk: {
        const tmp = -@as(c_int, 1);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).* - (blk: {
        const tmp = -@as(c_int, 5);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*;
    y1_2 = (blk: {
        const tmp = -@as(c_int, 1);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).* + (blk: {
        const tmp = -@as(c_int, 5);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*;
    y3 = (blk: {
        const tmp = -@as(c_int, 3);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).* + (blk: {
        const tmp = -@as(c_int, 7);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*;
    (blk: {
        const tmp = -@as(c_int, 1);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).* = y1_2 + y3;
    (blk: {
        const tmp = -@as(c_int, 3);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).* = y1_2 - y3;
    (blk: {
        const tmp = -@as(c_int, 5);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).* = k11 - k22;
    (blk: {
        const tmp = -@as(c_int, 7);
        if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).* = k11 + k22;
}
pub fn imdct_step3_inner_s_loop_ld654(arg_n: c_int, arg_e: [*c]f32, arg_i_off: c_int, arg_A: [*c]f32, arg_base_n: c_int) callconv(.c) void {
    var n = arg_n;
    _ = &n;
    var e = arg_e;
    _ = &e;
    var i_off = arg_i_off;
    _ = &i_off;
    var A = arg_A;
    _ = &A;
    var base_n = arg_base_n;
    _ = &base_n;
    var a_off: c_int = base_n >> @intCast(3);
    _ = &a_off;
    var A2: f32 = (blk: {
        const tmp = @as(c_int, 0) + a_off;
        if (tmp >= 0) break :blk A + @as(usize, @intCast(tmp)) else break :blk A - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*;
    _ = &A2;
    var z: [*c]f32 = e + @as(usize, @bitCast(@as(isize, @intCast(i_off))));
    _ = &z;
    var base: [*c]f32 = z - @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 16) * n))));
    _ = &base;
    while (z > base) {
        var k00: f32 = undefined;
        _ = &k00;
        var k11: f32 = undefined;
        _ = &k11;
        var l00: f32 = undefined;
        _ = &l00;
        var l11: f32 = undefined;
        _ = &l11;
        k00 = (blk: {
            const tmp = -@as(c_int, 0);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* - (blk: {
            const tmp = -@as(c_int, 8);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*;
        k11 = (blk: {
            const tmp = -@as(c_int, 1);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* - (blk: {
            const tmp = -@as(c_int, 9);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*;
        l00 = (blk: {
            const tmp = -@as(c_int, 2);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* - (blk: {
            const tmp = -@as(c_int, 10);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*;
        l11 = (blk: {
            const tmp = -@as(c_int, 3);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* - (blk: {
            const tmp = -@as(c_int, 11);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*;
        (blk: {
            const tmp = -@as(c_int, 0);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = (blk: {
            const tmp = -@as(c_int, 0);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* + (blk: {
            const tmp = -@as(c_int, 8);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*;
        (blk: {
            const tmp = -@as(c_int, 1);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = (blk: {
            const tmp = -@as(c_int, 1);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* + (blk: {
            const tmp = -@as(c_int, 9);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*;
        (blk: {
            const tmp = -@as(c_int, 2);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = (blk: {
            const tmp = -@as(c_int, 2);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* + (blk: {
            const tmp = -@as(c_int, 10);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*;
        (blk: {
            const tmp = -@as(c_int, 3);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = (blk: {
            const tmp = -@as(c_int, 3);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* + (blk: {
            const tmp = -@as(c_int, 11);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*;
        (blk: {
            const tmp = -@as(c_int, 8);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = k00;
        (blk: {
            const tmp = -@as(c_int, 9);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = k11;
        (blk: {
            const tmp = -@as(c_int, 10);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = (l00 + l11) * A2;
        (blk: {
            const tmp = -@as(c_int, 11);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = (l11 - l00) * A2;
        k00 = (blk: {
            const tmp = -@as(c_int, 4);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* - (blk: {
            const tmp = -@as(c_int, 12);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*;
        k11 = (blk: {
            const tmp = -@as(c_int, 5);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* - (blk: {
            const tmp = -@as(c_int, 13);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*;
        l00 = (blk: {
            const tmp = -@as(c_int, 6);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* - (blk: {
            const tmp = -@as(c_int, 14);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*;
        l11 = (blk: {
            const tmp = -@as(c_int, 7);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* - (blk: {
            const tmp = -@as(c_int, 15);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*;
        (blk: {
            const tmp = -@as(c_int, 4);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = (blk: {
            const tmp = -@as(c_int, 4);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* + (blk: {
            const tmp = -@as(c_int, 12);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*;
        (blk: {
            const tmp = -@as(c_int, 5);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = (blk: {
            const tmp = -@as(c_int, 5);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* + (blk: {
            const tmp = -@as(c_int, 13);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*;
        (blk: {
            const tmp = -@as(c_int, 6);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = (blk: {
            const tmp = -@as(c_int, 6);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* + (blk: {
            const tmp = -@as(c_int, 14);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*;
        (blk: {
            const tmp = -@as(c_int, 7);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = (blk: {
            const tmp = -@as(c_int, 7);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* + (blk: {
            const tmp = -@as(c_int, 15);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*;
        (blk: {
            const tmp = -@as(c_int, 12);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = k11;
        (blk: {
            const tmp = -@as(c_int, 13);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = -k00;
        (blk: {
            const tmp = -@as(c_int, 14);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = (l11 - l00) * A2;
        (blk: {
            const tmp = -@as(c_int, 15);
            if (tmp >= 0) break :blk z + @as(usize, @intCast(tmp)) else break :blk z - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).* = (l00 + l11) * -A2;
        iter_54(z);
        iter_54(z - @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 8))))));
        z -= @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 16)))));
    }
}
pub export fn inverse_mdct(arg_buffer: [*c]f32, arg_n: c_int, arg_f: [*c]vorb, arg_blocktype: c_int) callconv(.c) void {
    const buffer = arg_buffer;
    const n = arg_n;
    const f = arg_f;
    const blocktype = arg_blocktype;

    const n2 = n >> @intCast(1);
    const n4 = n >> @intCast(2);
    const n8 = n >> @intCast(3);

    const save_point = temp_alloc_save(f);
    const buf2 = @as([*c]f32, @ptrCast(@alignCast(temp_alloc(f, @as(usize, @intCast(n2)) * @sizeOf(f32)))));
    var u: [*c]f32 = null;
    var v: [*c]f32 = null;

    const A = f.*.A[@as(usize, @intCast(blocktype))];

    // Merged: copy and reflect spectral data + step 0
    {
        var d = buf2 + @as(usize, @intCast(n2 - 2));
        var AA = A;
        var e = buffer;
        const e_stop = buffer + @as(usize, @intCast(n2));

        while (@intFromPtr(e) != @intFromPtr(e_stop)) {
            d[1] = (e[0] * AA[0] - e[2] * AA[1]);
            d[0] = (e[0] * AA[1] + e[2] * AA[0]);
            d -= 2;
            AA += 2;
            e += 4;
        }

        e = buffer + @as(usize, @intCast(n2 - 3));
        while (@intFromPtr(d) >= @intFromPtr(buf2)) {
            d[1] = (-e[2] * AA[0] - -e[0] * AA[1]);
            d[0] = (-e[2] * AA[1] + -e[0] * AA[0]);
            d -= 2;
            AA += 2;
            e -= 4;
        }
    }

    u = buffer;
    v = buf2;

    // Step 2
    {
        var AA = A + @as(usize, @intCast(n2 - 8));
        var e0 = v + @as(usize, @intCast(n4));
        var e1 = v;
        var d0 = u + @as(usize, @intCast(n4));
        var d1 = u;

        while (@intFromPtr(AA) >= @intFromPtr(A)) {
            const v41_21 = e0[1] - e1[1];
            const v40_20 = e0[0] - e1[0];
            d0[1] = e0[1] + e1[1];
            d0[0] = e0[0] + e1[0];
            d1[1] = v41_21 * AA[4] - v40_20 * AA[5];
            d1[0] = v40_20 * AA[4] + v41_21 * AA[5];

            const v41_21_2 = e0[3] - e1[3];
            const v40_20_2 = e0[2] - e1[2];
            d0[3] = e0[3] + e1[3];
            d0[2] = e0[2] + e1[2];
            d1[3] = v41_21_2 * AA[0] - v40_20_2 * AA[1];
            d1[2] = v40_20_2 * AA[0] + v41_21_2 * AA[1];

            AA -= 8;
            d0 += 4;
            d1 += 4;
            e0 += 4;
            e1 += 4;
        }
    }

    // Step 3
    const ld = ilog(n) - 1;

    imdct_step3_iter0_loop(n >> @intCast(4), u, n2 - 1 - n4 * 0, -(n >> @intCast(3)), A);
    imdct_step3_iter0_loop(n >> @intCast(4), u, n2 - 1 - n4 * 1, -(n >> @intCast(3)), A);

    imdct_step3_inner_r_loop(n >> @intCast(5), u, n2 - 1 - n8 * 0, -(n >> @intCast(4)), A, 16);
    imdct_step3_inner_r_loop(n >> @intCast(5), u, n2 - 1 - n8 * 1, -(n >> @intCast(4)), A, 16);
    imdct_step3_inner_r_loop(n >> @intCast(5), u, n2 - 1 - n8 * 2, -(n >> @intCast(4)), A, 16);
    imdct_step3_inner_r_loop(n >> @intCast(5), u, n2 - 1 - n8 * 3, -(n >> @intCast(4)), A, 16);

    var l: c_int = 2;
    while (l < (ld - 3) >> @intCast(1)) : (l += 1) {
        const k0 = n >> @intCast(l + 2);
        const k0_2 = k0 >> @intCast(1);
        const lim = @as(c_int, 1) << @intCast(l + 1);
        var i: c_int = 0;
        while (i < lim) : (i += 1) {
            imdct_step3_inner_r_loop(n >> @intCast(l + 4), u, n2 - 1 - k0 * i, -k0_2, A, @as(c_int, 1) << @intCast(l + 3));
        }
    }

    while (l < ld - 6) : (l += 1) {
        const k0 = n >> @intCast(l + 2);
        const k1 = @as(c_int, 1) << @intCast(l + 3);
        const k0_2 = k0 >> @intCast(1);
        const rlim = n >> @intCast(l + 6);
        const lim = @as(c_int, 1) << @intCast(l + 1);
        var A0 = A;
        var i_off = n2 - 1;
        var r = rlim;
        while (r > 0) : (r -= 1) {
            imdct_step3_inner_s_loop(lim, u, i_off, -k0_2, A0, k1, k0);
            A0 += @as(usize, @intCast(k1 * 4));
            i_off -= 8;
        }
    }

    imdct_step3_inner_s_loop_ld654(n >> @intCast(5), u, n2 - 1, A, n);

    // Step 4, 5, and 6
    {
        const bitrev = f.*.bit_reverse[@as(usize, @intCast(blocktype))];
        var d0 = v + @as(usize, @intCast(n4 - 4));
        var d1 = v + @as(usize, @intCast(n2 - 4));
        var bitrev_ptr = bitrev;

        while (@intFromPtr(d0) >= @intFromPtr(v)) {
            const k4_0 = bitrev_ptr[0];
            d1[3] = u[@as(usize, @intCast(k4_0 + 0))];
            d1[2] = u[@as(usize, @intCast(k4_0 + 1))];
            d0[3] = u[@as(usize, @intCast(k4_0 + 2))];
            d0[2] = u[@as(usize, @intCast(k4_0 + 3))];

            const k4_1 = bitrev_ptr[1];
            d1[1] = u[@as(usize, @intCast(k4_1 + 0))];
            d1[0] = u[@as(usize, @intCast(k4_1 + 1))];
            d0[1] = u[@as(usize, @intCast(k4_1 + 2))];
            d0[0] = u[@as(usize, @intCast(k4_1 + 3))];

            d0 -= 4;
            d1 -= 4;
            bitrev_ptr += 2;
        }
    }

    // Assert v == buf2
    if (@intFromPtr(v) != @intFromPtr(buf2)) {
        @panic("inverse_mdct: v != buf2");
    }

    // Step 7
    {
        const cblock = f.*.C[@as(usize, @intCast(blocktype))];
        var d = v;
        var e = v + @as(usize, @intCast(n2 - 4));
        var C_ptr = cblock;

        while (@intFromPtr(d) < @intFromPtr(e)) {
            const a02 = d[0] - e[2];
            const a11 = d[1] + e[3];

            const b0 = C_ptr[1] * a02 + C_ptr[0] * a11;
            const b1 = C_ptr[1] * a11 - C_ptr[0] * a02;

            const b2 = d[0] + e[2];
            const b3 = d[1] - e[3];

            d[0] = b2 + b0;
            d[1] = b3 + b1;
            e[2] = b2 - b0;
            e[3] = b1 - b3;

            const a02_2 = d[2] - e[0];
            const a11_2 = d[3] + e[1];

            const b0_2 = C_ptr[3] * a02_2 + C_ptr[2] * a11_2;
            const b1_2 = C_ptr[3] * a11_2 - C_ptr[2] * a02_2;

            const b2_2 = d[2] + e[0];
            const b3_2 = d[3] - e[1];

            d[2] = b2_2 + b0_2;
            d[3] = b3_2 + b1_2;
            e[0] = b2_2 - b0_2;
            e[1] = b1_2 - b3_2;

            C_ptr += 4;
            d += 4;
            e -= 4;
        }
    }

    // Step 8 + decode
    {
        var B = f.*.B[@as(usize, @intCast(blocktype))] + @as(usize, @intCast(n2 - 8));
        var e = buf2 + @as(usize, @intCast(n2 - 8));
        var d0 = buffer;
        var d1 = buffer + @as(usize, @intCast(n2 - 4));
        var d2 = buffer + @as(usize, @intCast(n2));
        var d3 = buffer + @as(usize, @intCast(n - 4));

        while (@intFromPtr(e) >= @intFromPtr(v)) {
            const p3 = e[6] * B[7] - e[7] * B[6];
            const p2 = -e[6] * B[6] - e[7] * B[7];

            d0[0] = p3;
            d1[3] = -p3;
            d2[0] = p2;
            d3[3] = p2;

            const p1 = e[4] * B[5] - e[5] * B[4];
            const p0 = -e[4] * B[4] - e[5] * B[5];

            d0[1] = p1;
            d1[2] = -p1;
            d2[1] = p0;
            d3[2] = p0;

            const p3_2 = e[2] * B[3] - e[3] * B[2];
            const p2_2 = -e[2] * B[2] - e[3] * B[3];

            d0[2] = p3_2;
            d1[1] = -p3_2;
            d2[2] = p2_2;
            d3[1] = p2_2;

            const p1_2 = e[0] * B[1] - e[1] * B[0];
            const p0_2 = -e[0] * B[0] - e[1] * B[1];

            d0[3] = p1_2;
            d1[0] = -p1_2;
            d2[3] = p0_2;
            d3[0] = p0_2;

            B -= 8;
            e -= 8;
            d0 += 4;
            d2 += 4;
            d1 -= 4;
            d3 -= 4;
        }
    }

    temp_free(f, buf2);
    temp_alloc_restore(f, save_point);
}
pub fn get_window(arg_f: [*c]vorb, arg_len: c_int) callconv(.c) [*c]f32 {
    var f = arg_f;
    _ = &f;
    var len = arg_len;
    _ = &len;
    len <<= @intCast(@as(c_int, 1));
    if (len == f.*.blocksize_0) return f.*.window[@as(u32, @intCast(@as(c_int, 0)))];
    if (len == f.*.blocksize_1) return f.*.window[@as(u32, @intCast(@as(c_int, 1)))];
    return null;
}
pub const YTYPE = int16;
pub fn do_floor(arg_f: [*c]vorb, arg_map: [*c]Mapping, arg_i: c_int, arg_n: c_int, arg_target: [*c]f32, arg_finalY: [*c]YTYPE, arg_step2_flag: [*c]u8) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var map = arg_map;
    _ = &map;
    var i = arg_i;
    _ = &i;
    var n = arg_n;
    _ = &n;
    var target = arg_target;
    _ = &target;
    var finalY = arg_finalY;
    _ = &finalY;
    var step2_flag = arg_step2_flag;
    _ = &step2_flag;
    var n2: c_int = n >> @intCast(1);
    _ = &n2;
    var s: c_int = @as(c_int, @bitCast(@as(u32, (blk: {
        const tmp = i;
        if (tmp >= 0) break :blk map.*.chan + @as(usize, @intCast(tmp)) else break :blk map.*.chan - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
    }).*.mux)));
    _ = &s;
    var floor_1: c_int = undefined;
    _ = &floor_1;
    floor_1 = @as(c_int, @bitCast(@as(u32, map.*.submap_floor[@as(u32, @intCast(s))])));
    if (@as(c_int, @bitCast(@as(u32, f.*.floor_types[@as(u32, @intCast(floor_1))]))) == @as(c_int, 0)) {
        return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_stream)));
    } else {
        var g: [*c]Floor1 = &(blk: {
            const tmp = floor_1;
            if (tmp >= 0) break :blk f.*.floor_config + @as(usize, @intCast(tmp)) else break :blk f.*.floor_config - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
        }).*.floor1;
        _ = &g;
        var j: c_int = undefined;
        _ = &j;
        var q: c_int = undefined;
        _ = &q;
        var lx: c_int = 0;
        _ = &lx;
        var ly: c_int = @as(c_int, @bitCast(@as(c_int, finalY[@as(u32, @intCast(@as(c_int, 0)))]))) * @as(c_int, @bitCast(@as(u32, g.*.floor1_multiplier)));
        _ = &ly;
        {
            q = 1;
            while (q < g.*.values) : (q += 1) {
                j = @as(c_int, @bitCast(@as(u32, g.*.sorted_order[@as(u32, @intCast(q))])));
                _ = @sizeOf([*c]u8);
                if (@as(c_int, @bitCast(@as(c_int, (blk: {
                    const tmp = j;
                    if (tmp >= 0) break :blk finalY + @as(usize, @intCast(tmp)) else break :blk finalY - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).*))) >= @as(c_int, 0)) {
                    var hy: c_int = @as(c_int, @bitCast(@as(c_int, (blk: {
                        const tmp = j;
                        if (tmp >= 0) break :blk finalY + @as(usize, @intCast(tmp)) else break :blk finalY - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                    }).*))) * @as(c_int, @bitCast(@as(u32, g.*.floor1_multiplier)));
                    _ = &hy;
                    var hx: c_int = @as(c_int, @bitCast(@as(u32, g.*.Xlist[@as(u32, @intCast(j))])));
                    _ = &hx;
                    if (lx != hx) {
                        draw_line(target, lx, ly, hx, hy, n2);
                    }
                    _ = @as(c_int, 0);
                    _ = blk: {
                        lx = hx;
                        break :blk blk_1: {
                            const tmp = hy;
                            ly = tmp;
                            break :blk_1 tmp;
                        };
                    };
                }
            }
        }
        if (lx < n2) {
            {
                j = lx;
                while (j < n2) : (j += 1) {
                    (blk: {
                        const tmp = j;
                        if (tmp >= 0) break :blk target + @as(usize, @intCast(tmp)) else break :blk target - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                    }).* *= inverse_db_table[@as(u32, @intCast(ly))];
                }
            }
            _ = @as(c_int, 0);
        }
    }
    return 1;
}
pub export fn vorbis_decode_initial(arg_f: [*c]vorb, arg_p_left_start: [*c]c_int, arg_p_left_end: [*c]c_int, arg_p_right_start: [*c]c_int, arg_p_right_end: [*c]c_int, arg_mode: [*c]c_int) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var p_left_start = arg_p_left_start;
    _ = &p_left_start;
    var p_left_end = arg_p_left_end;
    _ = &p_left_end;
    var p_right_start = arg_p_right_start;
    _ = &p_right_start;
    var p_right_end = arg_p_right_end;
    _ = &p_right_end;
    var mode = arg_mode;
    _ = &mode;

    f.*.channel_buffer_start = 0;
    f.*.channel_buffer_end = 0;

    retry: while (true) {
        if (f.*.eof != 0) return FALSE;
        if (maybe_start_packet(f) == 0) return FALSE;

        if (get_bits(f, 1) != 0) {
            if (IS_PUSH_MODE(f) != 0) return @"error"(f, @as(u32, @bitCast(VORBIS_bad_packet_type)));
            while (get8_packet(f) != EOP) {}
            continue :retry;
        }

        if (f.*.alloc.alloc_buffer != null) {
            if (f.*.alloc.alloc_buffer_length_in_bytes != f.*.temp_offset) @panic("f->alloc.alloc_buffer_length_in_bytes == f->temp_offset");
        }

        const mode_index = get_bits(f, ilog(f.*.mode_count - 1));
        if (mode_index == @as(u32, @bitCast(EOP))) return FALSE;
        if (mode_index >= @as(u32, @bitCast(f.*.mode_count))) return FALSE;

        mode.* = @as(c_int, @bitCast(mode_index));
        const m_ptr = &f.*.mode_config[@as(usize, @intCast(mode.*))];

        var n: c_int = undefined;
        var prev: c_int = undefined;
        var next: c_int = undefined;
        const m = m_ptr.*;
        if (m.blockflag != 0) {
            n = f.*.blocksize_1;
            prev = @as(c_int, @bitCast(get_bits(f, 1)));
            next = @as(c_int, @bitCast(get_bits(f, 1)));
        } else {
            prev = 0;
            next = 0;
            n = f.*.blocksize_0;
        }

        const window_center = n >> @intCast(1);
        if ((m.blockflag != 0) and (prev == 0)) {
            p_left_start.* = (n - f.*.blocksize_0) >> @intCast(2);
            p_left_end.* = (n + f.*.blocksize_0) >> @intCast(2);
        } else {
            p_left_start.* = 0;
            p_left_end.* = window_center;
        }

        if ((m.blockflag != 0) and (next == 0)) {
            p_right_start.* = ((n * 3) - f.*.blocksize_0) >> @intCast(2);
            p_right_end.* = ((n * 3) + f.*.blocksize_0) >> @intCast(2);
        } else {
            p_right_start.* = window_center;
            p_right_end.* = n;
        }

        return TRUE;
    }
}
pub export fn vorbis_decode_packet_rest(arg_f: [*c]vorb, arg_len: [*c]c_int, arg_m: [*c]Mode, arg_left_start: c_int, _: c_int, arg_right_start: c_int, arg_right_end: c_int, arg_p_left: [*c]c_int) callconv(.c) c_int {
    const f = arg_f;
    const len_ptr = arg_len;
    const m = arg_m;
    var left_start = arg_left_start;
    const right_start = arg_right_start;
    const right_end = arg_right_end;
    const p_left = arg_p_left;

    const block_size_index = m.*.blockflag;
    const n = f.*.blocksize[@as(usize, block_size_index)];
    const n2 = n >> @intCast(1);
    const map = f.*.mapping + @as(usize, m.*.mapping);

    var zero_channel = [_]c_int{0} ** 256;
    var really_zero_channel = [_]c_int{0} ** 256;

    CHECK(f);

    var ch_index: c_int = 0;
    while (ch_index < f.*.channels) : (ch_index += 1) {
        const chan = map.*.chan + @as(usize, @intCast(ch_index));
        const mux = chan.*.mux;
        const floor_index = map.*.submap_floor[@as(usize, mux)];
        zero_channel[@as(usize, @intCast(ch_index))] = FALSE;

        if (f.*.floor_types[@as(usize, floor_index)] == 0) {
            return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_stream)));
        }

        const floor_conf = &f.*.floor_config[@as(usize, floor_index)].floor1;
        if (get_bits(f, 1) != 0) {
            var finalY = f.*.finalY[@as(usize, @intCast(ch_index))];
            var step2_flag = [_]u8{0} ** 256;
            const range_list = [_]c_int{ 256, 128, 86, 64 };
            const range = range_list[@as(usize, floor_conf.*.floor1_multiplier - 1)];
            var offset: c_int = 2;

            finalY[0] = @as(YTYPE, @intCast(get_bits(f, ilog(range) - 1)));
            finalY[1] = @as(YTYPE, @intCast(get_bits(f, ilog(range) - 1)));

            var part: c_int = 0;
            while (part < floor_conf.*.partitions) : (part += 1) {
                const pclass = floor_conf.*.partition_class_list[@as(usize, @intCast(part))];
                const cdim = floor_conf.*.class_dimensions[@as(usize, pclass)];
                const cbits = floor_conf.*.class_subclasses[@as(usize, pclass)];
                const csub = (@as(c_int, 1) << @intCast(cbits)) - 1;
                var cval: c_int = 0;

                if (cbits != 0) {
                    const master_idx = floor_conf.*.class_masterbooks[@as(usize, pclass)];
                    const codebook = f.*.codebooks + @as(usize, master_idx);
                    cval = codebook_decode_scalar(f, codebook);
                    if (cval == EOP) return FALSE;
                }

                var k: c_int = 0;
                while (k < cdim) : (k += 1) {
                    const book = floor_conf.*.subclass_books[@as(usize, pclass)][@as(usize, @intCast(cval & csub))];
                    cval >>= @intCast(cbits);
                    if (book >= 0) {
                        const codebook = f.*.codebooks + @as(usize, @intCast(book));
                        const temp = codebook_decode_scalar(f, codebook);
                        if (temp == EOP) return FALSE;
                        finalY[@as(usize, @intCast(offset))] = @as(YTYPE, @intCast(temp));
                    } else {
                        finalY[@as(usize, @intCast(offset))] = 0;
                    }
                    offset += 1;
                }
            }

            if (f.*.valid_bits == INVALID_BITS) {
                zero_channel[@as(usize, @intCast(ch_index))] = TRUE;
                continue;
            }

            step2_flag[0] = 1;
            step2_flag[1] = 1;

            var j: c_int = 2;
            while (j < floor_conf.*.values) : (j += 1) {
                const low = floor_conf.*.neighbors[@as(usize, @intCast(j))][0];
                const high = floor_conf.*.neighbors[@as(usize, @intCast(j))][1];
                const x = floor_conf.*.Xlist[@as(usize, @intCast(j))];
                const pred = predict_point(@as(c_int, x), @as(c_int, floor_conf.*.Xlist[@as(usize, low)]), @as(c_int, floor_conf.*.Xlist[@as(usize, high)]), finalY[@as(usize, low)], finalY[@as(usize, high)]);
                var val = @as(c_int, finalY[@as(usize, @intCast(j))]);
                const highroom = range - pred;
                const lowroom = pred;
                const room = if (highroom < lowroom) highroom * 2 else lowroom * 2;

                if (val != 0) {
                    step2_flag[@as(usize, low)] = 1;
                    step2_flag[@as(usize, high)] = 1;
                    step2_flag[@as(usize, @intCast(j))] = 1;
                    if (val >= room) {
                        if (highroom > lowroom) {
                            val = val - lowroom + pred;
                        } else {
                            val = pred - val + highroom - 1;
                        }
                    } else if ((val & 1) != 0) {
                        val = pred - ((val + 1) >> @intCast(1));
                    } else {
                        val = pred + (val >> @intCast(1));
                    }
                    finalY[@as(usize, @intCast(j))] = @as(YTYPE, @intCast(val));
                } else {
                    step2_flag[@as(usize, @intCast(j))] = 0;
                    finalY[@as(usize, @intCast(j))] = @as(YTYPE, @intCast(pred));
                }
            }

            var idx: c_int = 0;
            while (idx < floor_conf.*.values) : (idx += 1) {
                if (step2_flag[@as(usize, @intCast(idx))] == 0) {
                    finalY[@as(usize, @intCast(idx))] = -1;
                }
            }
        } else {
            zero_channel[@as(usize, @intCast(ch_index))] = TRUE;
        }
    }

    CHECK(f);

    if (f.*.alloc.alloc_buffer != null) {
        if (f.*.alloc.alloc_buffer_length_in_bytes != f.*.temp_offset) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_stream)));
    }

    @memcpy(@as([*c]c_int, @ptrCast(&really_zero_channel))[0..@as(usize, @intCast(f.*.channels))], @as([*c]const c_int, @ptrCast(&zero_channel))[0..@as(usize, @intCast(f.*.channels))]);

    var coupling_step: c_int = 0;
    while (coupling_step < map.*.coupling_steps) : (coupling_step += 1) {
        const magnitude = map.*.chan[@as(usize, @intCast(coupling_step))].magnitude;
        const angle = map.*.chan[@as(usize, @intCast(coupling_step))].angle;
        if ((zero_channel[@as(usize, magnitude)] == FALSE) or (zero_channel[@as(usize, angle)] == FALSE)) {
            zero_channel[@as(usize, magnitude)] = FALSE;
            zero_channel[@as(usize, angle)] = FALSE;
        }
    }

    CHECK(f);

    var residue_buffers: [STB_VORBIS_MAX_CHANNELS][*]f32 = undefined;
    var do_not_decode = [_]u8{0} ** 256;

    var submap: c_int = 0;
    while (submap < map.*.submaps) : (submap += 1) {
        var ch: c_int = 0;
        var ci: c_int = 0;
        while (ci < f.*.channels) : (ci += 1) {
            if (map.*.chan[@as(usize, @intCast(ci))].mux == submap) {
                if (zero_channel[@as(usize, @intCast(ci))] != 0) {
                    do_not_decode[@as(usize, @intCast(ch))] = TRUE;
                    residue_buffers[@as(usize, @intCast(ch))] = undefined;
                } else {
                    do_not_decode[@as(usize, @intCast(ch))] = FALSE;
                    residue_buffers[@as(usize, @intCast(ch))] = f.*.channel_buffers[@as(usize, @intCast(ci))];
                }
                ch += 1;
            }
        }

        const residue_index = map.*.submap_residue[@as(usize, @intCast(submap))];
        decode_residue(f, @as([*c][*c]f32, @ptrCast(&residue_buffers)), ch, n2, residue_index, @as([*c]u8, @ptrCast(&do_not_decode)));
    }

    if (f.*.alloc.alloc_buffer != null) {
        if (f.*.alloc.alloc_buffer_length_in_bytes != f.*.temp_offset) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_stream)));
    }

    CHECK(f);

    var cs = @as(c_int, map.*.coupling_steps) - 1;
    while (cs >= 0) : (cs -= 1) {
        const magnitude = map.*.chan[@as(usize, @intCast(cs))].magnitude;
        const angle = map.*.chan[@as(usize, @intCast(cs))].angle;
        var m_buf = f.*.channel_buffers[@as(usize, magnitude)];
        var a_buf = f.*.channel_buffers[@as(usize, angle)];
        var idx: c_int = 0;
        while (idx < n2) : (idx += 1) {
            const mag = m_buf[@as(usize, @intCast(idx))];
            const ang = a_buf[@as(usize, @intCast(idx))];
            if (mag > 0) {
                if (ang > 0) {
                    a_buf[@as(usize, @intCast(idx))] = mag - ang;
                } else {
                    a_buf[@as(usize, @intCast(idx))] = mag + ang;
                }
            } else {
                if (ang > 0) {
                    a_buf[@as(usize, @intCast(idx))] = mag + ang;
                } else {
                    a_buf[@as(usize, @intCast(idx))] = mag - ang;
                }
            }
            m_buf[@as(usize, @intCast(idx))] = mag;
        }
    }

    CHECK(f);

    var ch_idx: c_int = 0;
    while (ch_idx < f.*.channels) : (ch_idx += 1) {
        if (really_zero_channel[@as(usize, @intCast(ch_idx))] != 0) {
            @memset(f.*.channel_buffers[@as(usize, @intCast(ch_idx))][0..@as(usize, @intCast(n2))], 0);
        } else {
            _ = do_floor(f, map, ch_idx, n, f.*.channel_buffers[@as(usize, @intCast(ch_idx))], f.*.finalY[@as(usize, @intCast(ch_idx))], null);
        }
    }

    CHECK(f);

    ch_idx = 0;
    while (ch_idx < f.*.channels) : (ch_idx += 1) {
        inverse_mdct(f.*.channel_buffers[@as(usize, @intCast(ch_idx))], n, f, m.*.blockflag);
    }

    CHECK(f);

    flush_packet(f);

    if (f.*.first_decode != 0) {
        f.*.current_loc = @as(u32, 0) -% @as(u32, @intCast(n2));
        f.*.discard_samples_deferred = n - right_end;
        f.*.current_loc_valid = TRUE;
        f.*.first_decode = FALSE;
    } else if (f.*.discard_samples_deferred != 0) {
        if (f.*.discard_samples_deferred >= (right_start - left_start)) {
            f.*.discard_samples_deferred -= (right_start - left_start);
            left_start = right_start;
            p_left.* = left_start;
        } else {
            left_start += f.*.discard_samples_deferred;
            p_left.* = left_start;
            f.*.discard_samples_deferred = 0;
        }
    }

    if (f.*.last_seg_which == f.*.end_seg_with_known_loc) {
        if ((f.*.current_loc_valid != 0) and ((f.*.page_flag & PAGEFLAG_last_page) != 0)) {
            const current_end = f.*.known_loc_for_packet;
            if (current_end < f.*.current_loc + @as(u32, @intCast(right_end - left_start))) {
                if (current_end < f.*.current_loc) {
                    len_ptr.* = 0;
                } else {
                    len_ptr.* = @as(c_int, @intCast(current_end - f.*.current_loc));
                }
                len_ptr.* += left_start;
                if (len_ptr.* > right_end) len_ptr.* = right_end;
                f.*.current_loc += @as(u32, @intCast(len_ptr.*));
                return TRUE;
            }
        }

        f.*.current_loc = f.*.known_loc_for_packet - @as(u32, @intCast(n2 - left_start));
        f.*.current_loc_valid = TRUE;
    }

    if (f.*.current_loc_valid != 0) {
        const delta = right_start - left_start;
        f.*.current_loc +%= @as(u32, @bitCast(delta));
    }

    if (f.*.alloc.alloc_buffer != null) {
        if (f.*.alloc.alloc_buffer_length_in_bytes != f.*.temp_offset) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_stream)));
    }

    len_ptr.* = right_end;
    CHECK(f);
    return TRUE;
}
pub fn vorbis_decode_packet(arg_f: [*c]vorb, arg_len: [*c]c_int, arg_p_left: [*c]c_int, arg_p_right: [*c]c_int) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var len = arg_len;
    _ = &len;
    var p_left = arg_p_left;
    _ = &p_left;
    var p_right = arg_p_right;
    _ = &p_right;
    var mode: c_int = undefined;
    _ = &mode;
    var left_end: c_int = undefined;
    _ = &left_end;
    var right_end: c_int = undefined;
    _ = &right_end;
    if (!(vorbis_decode_initial(f, p_left, &left_end, p_right, &right_end, &mode) != 0)) return 0;
    return vorbis_decode_packet_rest(f, len, @as([*c]Mode, @ptrCast(@alignCast(&f.*.mode_config[@as(usize, @intCast(0))]))) + @as(usize, @bitCast(@as(isize, @intCast(mode)))), p_left.*, left_end, p_right.*, right_end, p_left);
}
pub fn vorbis_finish_frame(arg_f: [*c]stb_vorbis, arg_len: c_int, arg_left: c_int, arg_right: c_int) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var len = arg_len;
    _ = &len;
    var left = arg_left;
    _ = &left;
    var right = arg_right;
    _ = &right;
    var prev: c_int = undefined;
    _ = &prev;
    var i: c_int = undefined;
    _ = &i;
    var j: c_int = undefined;
    _ = &j;
    if (f.*.previous_length != 0) {
        var i_1: c_int = undefined;
        _ = &i_1;
        var j_2: c_int = undefined;
        _ = &j_2;
        var n: c_int = f.*.previous_length;
        _ = &n;
        var w: [*c]f32 = get_window(f, n);
        _ = &w;
        if (w == @as([*c]f32, @ptrCast(@alignCast(@as(?*anyopaque, @ptrFromInt(@as(c_int, 0))))))) return 0;
        {
            i_1 = 0;
            while (i_1 < f.*.channels) : (i_1 += 1) {
                {
                    j_2 = 0;
                    while (j_2 < n) : (j_2 += 1) {
                        (blk: {
                            const tmp = left + j_2;
                            if (tmp >= 0) break :blk f.*.channel_buffers[@as(u32, @intCast(i_1))] + @as(usize, @intCast(tmp)) else break :blk f.*.channel_buffers[@as(u32, @intCast(i_1))] - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).* = ((blk: {
                            const tmp = left + j_2;
                            if (tmp >= 0) break :blk f.*.channel_buffers[@as(u32, @intCast(i_1))] + @as(usize, @intCast(tmp)) else break :blk f.*.channel_buffers[@as(u32, @intCast(i_1))] - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).* * (blk: {
                            const tmp = j_2;
                            if (tmp >= 0) break :blk w + @as(usize, @intCast(tmp)) else break :blk w - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).*) + ((blk: {
                            const tmp = j_2;
                            if (tmp >= 0) break :blk f.*.previous_window[@as(u32, @intCast(i_1))] + @as(usize, @intCast(tmp)) else break :blk f.*.previous_window[@as(u32, @intCast(i_1))] - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).* * (blk: {
                            const tmp = (n - @as(c_int, 1)) - j_2;
                            if (tmp >= 0) break :blk w + @as(usize, @intCast(tmp)) else break :blk w - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).*);
                    }
                }
            }
        }
    }
    prev = f.*.previous_length;
    f.*.previous_length = len - right;
    {
        i = 0;
        while (i < f.*.channels) : (i += 1) {
            j = 0;
            while ((right + j) < len) : (j += 1) {
                (blk: {
                    const tmp = j;
                    if (tmp >= 0) break :blk f.*.previous_window[@as(u32, @intCast(i))] + @as(usize, @intCast(tmp)) else break :blk f.*.previous_window[@as(u32, @intCast(i))] - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).* = (blk: {
                    const tmp = right + j;
                    if (tmp >= 0) break :blk f.*.channel_buffers[@as(u32, @intCast(i))] + @as(usize, @intCast(tmp)) else break :blk f.*.channel_buffers[@as(u32, @intCast(i))] - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).*;
            }
        }
    }
    if (!(prev != 0)) return 0;
    if (len < right) {
        right = len;
    }
    f.*.samples_output +%= @as(u32, @bitCast(right - left));
    return right - left;
}
pub fn vorbis_pump_first_frame(f: [*c]stb_vorbis) callconv(.c) c_int {
    var len: c_int = undefined;
    var right: c_int = undefined;
    var left: c_int = undefined;
    var res: c_int = undefined;
    res = vorbis_decode_packet(f, &len, &left, &right);
    if (res != 0) {
        _ = vorbis_finish_frame(f, len, left, right);
    }
    return res;
}
pub fn is_whole_packet_present(arg_f: [*c]stb_vorbis) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var s: c_int = f.*.next_seg;
    _ = &s;
    var first: c_int = 1;
    _ = &first;
    var p: [*c]u8 = f.*.stream;
    _ = &p;
    if (s != -@as(c_int, 1)) {
        while (s < f.*.segment_count) : (s += 1) {
            p += @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, @bitCast(@as(u32, f.*.segments[@as(u32, @intCast(s))])))))));
            if (@as(c_int, @bitCast(@as(u32, f.*.segments[@as(u32, @intCast(s))]))) < @as(c_int, 255)) break;
        }
        if (s == f.*.segment_count) {
            s = -@as(c_int, 1);
        }
        if (p > f.*.stream_end) return @"error"(f, @as(u32, @bitCast(VORBIS_need_more_data)));
        first = 0;
    }
    while (s == -@as(c_int, 1)) {
        var q: [*c]u8 = undefined;
        _ = &q;
        var n: c_int = undefined;
        _ = &n;
        if ((p + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 26)))))) >= f.*.stream_end) return @"error"(f, @as(u32, @bitCast(VORBIS_need_more_data)));
        if (memcmp(@as(?*const anyopaque, @ptrCast(p)), @as(?*const anyopaque, @ptrCast(@as([*c]u8, @ptrCast(@alignCast(&ogg_page_header[@as(usize, @intCast(0))]))))), @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 4))))) != 0) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_stream)));
        if (@as(c_int, @bitCast(@as(u32, p[@as(u32, @intCast(@as(c_int, 4)))]))) != @as(c_int, 0)) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_stream)));
        if (first != 0) {
            if (f.*.previous_length != 0) if ((@as(c_int, @bitCast(@as(u32, p[@as(u32, @intCast(@as(c_int, 5)))]))) & @as(c_int, 1)) != 0) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_stream)));
        } else {
            if (!((@as(c_int, @bitCast(@as(u32, p[@as(u32, @intCast(@as(c_int, 5)))]))) & @as(c_int, 1)) != 0)) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_stream)));
        }
        n = @as(c_int, @bitCast(@as(u32, p[@as(u32, @intCast(@as(c_int, 26)))])));
        q = p + @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 27)))));
        p = q + @as(usize, @bitCast(@as(isize, @intCast(n))));
        if (p > f.*.stream_end) return @"error"(f, @as(u32, @bitCast(VORBIS_need_more_data)));
        {
            s = 0;
            while (s < n) : (s += 1) {
                p += @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, @bitCast(@as(u32, (blk: {
                    const tmp = s;
                    if (tmp >= 0) break :blk q + @as(usize, @intCast(tmp)) else break :blk q - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).*)))))));
                if (@as(c_int, @bitCast(@as(u32, (blk: {
                    const tmp = s;
                    if (tmp >= 0) break :blk q + @as(usize, @intCast(tmp)) else break :blk q - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).*))) < @as(c_int, 255)) break;
            }
        }
        if (s == n) {
            s = -@as(c_int, 1);
        }
        if (p > f.*.stream_end) return @"error"(f, @as(u32, @bitCast(VORBIS_need_more_data)));
        first = 0;
    }
    return 1;
}
pub fn start_decoder(arg_f: [*c]vorb) !c_int {
    const f = arg_f;
    var header: [6]u8 = undefined;
    var max_submaps: c_int = 0;
    var longest_floorlist: c_int = 0;

    f.*.first_decode = TRUE;

    if (start_page(f) == 0) {
        return FALSE;
    }
    if ((f.*.page_flag & @as(c_int, @bitCast(@as(u32, PAGEFLAG_first_page)))) == 0) {
        return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_first_page)));
    }
    if ((f.*.page_flag & @as(c_int, @bitCast(@as(u32, PAGEFLAG_last_page)))) != 0) {
        return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_first_page)));
    }
    if ((f.*.page_flag & @as(c_int, @bitCast(@as(u32, PAGEFLAG_continued_packet)))) != 0) {
        return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_first_page)));
    }
    if (f.*.segment_count != 1) {
        return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_first_page)));
    }

    if (f.*.segments[0] != 30) {
        if (f.*.segments[0] == 64 and getn(f, @as([*c]u8, @ptrCast(&header)), 6) != 0 and
            header[0] == 'f' and header[1] == 'i' and header[2] == 's' and
            header[3] == 'h' and header[4] == 'e' and header[5] == 'a' and
            get8(f) == 'd' and get8(f) == '\x00')
        {
            return @"error"(f, @as(u32, @bitCast(VORBIS_ogg_skeleton_not_supported)));
        } else {
            return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_first_page)));
        }
    }

    const packet_id = get8(f);
    if (packet_id != VORBIS_packet_id) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_first_page)));
    if (getn(f, @as([*c]u8, @ptrCast(&header)), 6) == 0) {
        return @"error"(f, @as(u32, @bitCast(VORBIS_unexpected_eof)));
    }
    if (vorbis_validate(@as([*c]u8, @ptrCast(&header))) == 0) {
        return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_first_page)));
    }
    const version = get32(f);
    if (version != 0) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_first_page)));
    f.*.channels = get8(f);
    if (f.*.channels == 0) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_first_page)));
    if (f.*.channels > STB_VORBIS_MAX_CHANNELS) return @"error"(f, @as(u32, @bitCast(VORBIS_too_many_channels)));
    f.*.sample_rate = get32(f);
    if (f.*.sample_rate == 0) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_first_page)));
    _ = get32(f);
    _ = get32(f);
    _ = get32(f);

    var x = get8(f);
    {
        const log0 = @as(c_int, @intCast(x & 15));
        const log1 = @as(c_int, @intCast(x >> 4));
        f.*.blocksize_0 = @as(c_int, 1) << @intCast(log0);
        f.*.blocksize_1 = @as(c_int, 1) << @intCast(log1);
        if (log0 < 6 or log0 > 13) {
            return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
        }
        if (log1 < 6 or log1 > 13) {
            return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
        }
        if (log0 > log1) {
            return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
        }
    }

    x = get8(f);
    if ((x & 1) == 0) {
        return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_first_page)));
    }

    if (start_page(f) == 0) {
        return FALSE;
    }
    if (start_packet(f) == 0) {
        return FALSE;
    }
    if (next_segment(f) == 0) {
        return FALSE;
    }

    const comment_type = get8_packet(f);
    if (comment_type != VORBIS_packet_comment) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
    var i: c_int = 0;
    while (i < 6) : (i += 1) header[@as(usize, @intCast(i))] = @intCast(get8_packet(f));
    if (vorbis_validate(@as([*c]u8, @ptrCast(&header))) == 0) {
        return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
    }

    var len = @as(c_int, @bitCast(get32_packet(f)));
    f.*.vendor = @as([*c]u8, @ptrCast(setup_malloc(f, @intCast(len + 1))));
    if (f.*.vendor == null) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
    i = 0;
    while (i < len) : (i += 1) f.*.vendor[@as(usize, @intCast(i))] = @intCast(get8_packet(f));
    f.*.vendor[@as(usize, @intCast(len))] = 0;

    f.*.comment_list_length = @as(c_int, @bitCast(get32_packet(f)));
    f.*.comment_list = null;
    if (f.*.comment_list_length > 0) {
        f.*.comment_list = @as([*c][*c]u8, @ptrCast(@alignCast(setup_malloc(f, @intCast(@sizeOf([*c]u8) * @as(usize, @intCast(f.*.comment_list_length)))))));
        if (f.*.comment_list == null) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
    }

    i = 0;
    while (i < f.*.comment_list_length) : (i += 1) {
        len = @as(c_int, @bitCast(get32_packet(f)));
        f.*.comment_list[@as(usize, @intCast(i))] = @as([*c]u8, @ptrCast(setup_malloc(f, @intCast(len + 1))));
        if (f.*.comment_list[@as(usize, @intCast(i))] == null) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
        var j: c_int = 0;
        while (j < len) : (j += 1) f.*.comment_list[@as(usize, @intCast(i))][@as(usize, @intCast(j))] = @intCast(get8_packet(f));
        f.*.comment_list[@as(usize, @intCast(i))][@as(usize, @intCast(len))] = 0;
    }

    x = @intCast(get8_packet(f));
    if ((x & 1) == 0) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));

    skip(f, f.*.bytes_in_seg);
    f.*.bytes_in_seg = 0;
    while (true) {
        len = next_segment(f);
        skip(f, len);
        f.*.bytes_in_seg = 0;
        if (len == 0) break;
    }

    if (start_packet(f) == 0) return FALSE;
    if (IS_PUSH_MODE(f) != 0) {
        if (is_whole_packet_present(f) == 0) {
            if (f.*.@"error" == @as(u32, @bitCast(VORBIS_invalid_stream))) f.*.@"error" = @as(u32, @bitCast(VORBIS_invalid_setup));
            return FALSE;
        }
    }

    crc32_init();

    if (get8_packet(f) != VORBIS_packet_setup) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
    i = 0;
    while (i < 6) : (i += 1) header[@as(usize, @intCast(i))] = @intCast(get8_packet(f));
    if (vorbis_validate(@as([*c]u8, @ptrCast(&header))) == 0) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));

    f.*.codebook_count = @as(c_int, @intCast(get_bits(f, 8) + 1));
    f.*.codebooks = @as([*c]Codebook, @ptrCast(@alignCast(setup_malloc(f, @intCast(@sizeOf(Codebook) * @as(usize, @intCast(f.*.codebook_count)))))));
    if (f.*.codebooks == null) {
        return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
    }
    @memset(f.*.codebooks[0..@as(usize, @intCast(f.*.codebook_count))], std.mem.zeroes(Codebook));

    // Parse codebooks
    i = 0;
    while (i < f.*.codebook_count) : (i += 1) {
        var values: [*c]u32 = null;
        var ordered: c_int = undefined;
        var sorted_count: c_int = undefined;
        var total: c_int = 0;
        var lengths: [*c]u8 = undefined;
        const c = f.*.codebooks + @as(usize, @intCast(i));

        CHECK(f);
        x = @intCast(get_bits(f, 8));
        if (x != 0x42) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
        x = @intCast(get_bits(f, 8));
        if (x != 0x43) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
        x = @intCast(get_bits(f, 8));
        if (x != 0x56) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
        x = @intCast(get_bits(f, 8));
        c.*.dimensions = @as(c_int, @intCast((get_bits(f, 8) << 8) + x));
        x = @intCast(get_bits(f, 8));
        const y = get_bits(f, 8);
        c.*.entries = @as(c_int, @intCast((get_bits(f, 8) << 16) + (y << 8) + x));
        ordered = @as(c_int, @intCast(get_bits(f, 1)));
        c.*.sparse = if (ordered != 0) @as(u8, 0) else @as(u8, @intCast(get_bits(f, 1)));

        if (c.*.dimensions == 0 and c.*.entries != 0) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));

        if (c.*.sparse != 0) {
            lengths = @as([*c]u8, @ptrCast(setup_temp_malloc(f, @intCast(c.*.entries))));
        } else {
            lengths = @as([*c]u8, @ptrCast(setup_malloc(f, @intCast(c.*.entries))));
            c.*.codeword_lengths = lengths;
        }

        if (lengths == null) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));

        if (ordered != 0) {
            var current_entry: c_int = 0;
            var current_length = @as(c_int, @intCast(get_bits(f, 5) + 1));
            while (current_entry < c.*.entries) {
                const limit = c.*.entries - current_entry;
                const n = @as(c_int, @intCast(get_bits(f, ilog(limit))));
                if (current_length >= 32) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
                if (current_entry + n > c.*.entries) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
                @memset(lengths[@as(usize, @intCast(current_entry))..@as(usize, @intCast(current_entry + n))], @as(u8, @intCast(current_length)));
                current_entry += n;
                current_length += 1;
            }
        } else {
            var j: c_int = 0;
            while (j < c.*.entries) : (j += 1) {
                const present = if (c.*.sparse != 0) @as(c_int, @intCast(get_bits(f, 1))) else 1;
                if (present != 0) {
                    lengths[@as(usize, @intCast(j))] = @as(u8, @intCast(get_bits(f, 5) + 1));
                    total += 1;
                    if (lengths[@as(usize, @intCast(j))] == 32) {
                        return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
                    }
                } else {
                    lengths[@as(usize, @intCast(j))] = NO_CODE;
                }
            }
        }

        if (c.*.sparse != 0 and total >= c.*.entries >> 2) {
            if (c.*.entries > @as(c_int, @bitCast(f.*.setup_temp_memory_required))) {
                f.*.setup_temp_memory_required = @as(u32, @intCast(c.*.entries));
            }

            c.*.codeword_lengths = @as([*c]u8, @ptrCast(setup_malloc(f, @intCast(c.*.entries))));
            if (c.*.codeword_lengths == null) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
            @memcpy(c.*.codeword_lengths[0..@as(usize, @intCast(c.*.entries))], lengths[0..@as(usize, @intCast(c.*.entries))]);
            setup_temp_free(f, lengths, @intCast(c.*.entries));
            lengths = c.*.codeword_lengths;
            c.*.sparse = 0;
        }

        if (c.*.sparse != 0) {
            sorted_count = total;
        } else {
            sorted_count = 0;
            var j: c_int = 0;
            while (j < c.*.entries) : (j += 1) {
                if (lengths[@as(usize, @intCast(j))] > STB_VORBIS_FAST_HUFFMAN_LENGTH and lengths[@as(usize, @intCast(j))] != NO_CODE) {
                    sorted_count += 1;
                }
            }
        }

        c.*.sorted_entries = sorted_count;
        values = null;

        CHECK(f);
        if (c.*.sparse == 0) {
            c.*.codewords = @as([*c]u32, @ptrCast(@alignCast(setup_malloc(f, @intCast(@sizeOf(u32) * @as(usize, @intCast(c.*.entries)))))));
            if (c.*.codewords == null) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
        } else {
            if (c.*.sorted_entries != 0) {
                c.*.codeword_lengths = @as([*c]u8, @ptrCast(setup_malloc(f, @intCast(c.*.sorted_entries))));
                if (c.*.codeword_lengths == null) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
                c.*.codewords = @as([*c]u32, @ptrCast(@alignCast(setup_temp_malloc(f, @sizeOf(u32) * c.*.sorted_entries))));
                if (c.*.codewords == null) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
                values = @as([*c]u32, @ptrCast(@alignCast(setup_temp_malloc(f, @sizeOf(u32) * c.*.sorted_entries))));
                if (values == null) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
            }
            const size = @as(u32, @intCast(c.*.entries)) + @as(u32, @intCast((@sizeOf(u32) + @sizeOf(u32)) * @as(usize, @intCast(c.*.sorted_entries))));
            if (size > f.*.setup_temp_memory_required) {
                f.*.setup_temp_memory_required = size;
            }
        }

        if (compute_codewords(c, lengths, c.*.entries, values) == 0) {
            if (c.*.sparse != 0) setup_temp_free(f, values, 0);
            return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
        }

        if (c.*.sorted_entries != 0) {
            c.*.sorted_codewords = @as([*c]u32, @ptrCast(@alignCast(setup_malloc(f, @sizeOf(u32) * c.*.sorted_entries + 1))));
            if (c.*.sorted_codewords == null) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
            c.*.sorted_values = @as([*c]c_int, @ptrCast(@alignCast(setup_malloc(f, @sizeOf(c_int) * c.*.sorted_entries + 1))));
            if (c.*.sorted_values == null) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
            c.*.sorted_values += 1;
            c.*.sorted_values[@as(usize, @bitCast(@as(isize, -1)))] = -1;
            compute_sorted_huffman(c, lengths, values);
        }

        if (c.*.sparse != 0) {
            setup_temp_free(f, values, @sizeOf(u32) * c.*.sorted_entries);
            setup_temp_free(f, c.*.codewords, @sizeOf(u32) * c.*.sorted_entries);
            setup_temp_free(f, lengths, c.*.entries);
            c.*.codewords = null;
        }

        compute_accelerated_huffman(c);

        CHECK(f);
        c.*.lookup_type = @intCast(get_bits(f, 4));
        if (c.*.lookup_type > 2) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));

        // Codebook lookup (with goto skip handling)
        lookup: {
            if (c.*.lookup_type > 0) {
                var mults: [*c]uint16 = undefined;
                c.*.minimum_value = float32_unpack(get_bits(f, 32));
                c.*.delta_value = float32_unpack(get_bits(f, 32));
                c.*.value_bits = @intCast(get_bits(f, 4) + 1);
                c.*.sequence_p = @intCast(get_bits(f, 1));
                if (c.*.lookup_type == 1) {
                    const val = try lookup1_values(c.*.entries, c.*.dimensions);
                    c.*.lookup_values = @intCast(val);
                } else {
                    c.*.lookup_values = @as(u32, @intCast(c.*.entries * c.*.dimensions));
                }
                if (c.*.lookup_values == 0) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
                mults = @as([*c]uint16, @ptrCast(@alignCast(setup_temp_malloc(f, @intCast(@sizeOf(uint16) * c.*.lookup_values)))));
                if (mults == null) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));

                var j: c_int = 0;
                while (j < @as(c_int, @intCast(c.*.lookup_values))) : (j += 1) {
                    const q = @as(c_int, @intCast(get_bits(f, c.*.value_bits)));
                    if (q == EOP) {
                        setup_temp_free(f, mults, @intCast(@sizeOf(uint16) * c.*.lookup_values));
                        return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
                    }
                    mults[@as(usize, @intCast(j))] = @as(uint16, @intCast(q));
                }

                // STB_VORBIS_DIVIDES_IN_CODEBOOK not defined
                if (c.*.lookup_type == 1) {
                    var codebook_len: c_int = undefined;
                    const sparse = c.*.sparse;
                    var last: f32 = 0;
                    if (sparse != 0) {
                        if (c.*.sorted_entries == 0) break :lookup;
                        c.*.multiplicands = @as([*c]codetype, @ptrCast(@alignCast(setup_malloc(f, @sizeOf(codetype) * c.*.sorted_entries * c.*.dimensions))));
                    } else {
                        c.*.multiplicands = @as([*c]codetype, @ptrCast(@alignCast(setup_malloc(f, @sizeOf(codetype) * c.*.entries * c.*.dimensions))));
                    }
                    if (c.*.multiplicands == null) {
                        setup_temp_free(f, mults, @intCast(@sizeOf(uint16) * c.*.lookup_values));
                        return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
                    }
                    codebook_len = if (sparse != 0) c.*.sorted_entries else c.*.entries;
                    j = 0;
                    while (j < codebook_len) : (j += 1) {
                        const z: u32 = if (sparse != 0) @as(u32, @intCast(c.*.sorted_values[@as(usize, @intCast(j))])) else @as(u32, @intCast(j));
                        var di: u32 = 1;
                        var k: c_int = 0;
                        while (k < c.*.dimensions) : (k += 1) {
                            const off = @as(c_int, @intCast((z / di) % c.*.lookup_values));
                            const val = @as(f32, @floatFromInt(mults[@as(usize, @intCast(off))])) * c.*.delta_value + c.*.minimum_value + last;
                            c.*.multiplicands[@as(usize, @intCast(j * c.*.dimensions + k))] = val;
                            if (c.*.sequence_p != 0) {
                                last = val;
                            }
                            if (k + 1 < c.*.dimensions) {
                                if (di > @as(u32, @bitCast(@as(c_int, -1))) / c.*.lookup_values) {
                                    setup_temp_free(f, mults, @intCast(@sizeOf(uint16) * c.*.lookup_values));
                                    return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
                                }
                                di *= c.*.lookup_values;
                            }
                        }
                    }
                    c.*.lookup_type = 2;
                } else {
                    var last: f32 = 0;
                    CHECK(f);
                    c.*.multiplicands = @as([*c]codetype, @ptrCast(@alignCast(setup_malloc(f, @intCast(@sizeOf(codetype) * c.*.lookup_values)))));
                    if (c.*.multiplicands == null) {
                        setup_temp_free(f, mults, @intCast(@sizeOf(uint16) * c.*.lookup_values));
                        return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
                    }
                    j = 0;
                    while (j < @as(c_int, @intCast(c.*.lookup_values))) : (j += 1) {
                        const val = @as(f32, @floatFromInt(mults[@as(usize, @intCast(j))])) * c.*.delta_value + c.*.minimum_value + last;
                        c.*.multiplicands[@as(usize, @intCast(j))] = val;
                        if (c.*.sequence_p != 0) {
                            last = val;
                        }
                    }
                }

                setup_temp_free(f, mults, @intCast(@sizeOf(uint16) * c.*.lookup_values));
                CHECK(f);
            }
        }
        CHECK(f);
    }

    // time domain transfers (notused)
    x = @intCast(get_bits(f, 6) + 1);
    i = 0;
    while (i < @as(c_int, @intCast(x))) : (i += 1) {
        const z = get_bits(f, 16);
        if (z != 0) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
    }

    // Floors
    f.*.floor_count = @as(c_int, @intCast(get_bits(f, 6) + 1));
    f.*.floor_config = @as([*c]Floor, @ptrCast(@alignCast(setup_malloc(f, @intCast(@as(usize, @intCast(f.*.floor_count)) * @sizeOf(Floor))))));
    if (f.*.floor_config == null) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));

    i = 0;
    while (i < f.*.floor_count) : (i += 1) {
        f.*.floor_types[@as(usize, @intCast(i))] = @as(uint16, @intCast(get_bits(f, 16)));
        if (f.*.floor_types[@as(usize, @intCast(i))] > 1) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
        if (f.*.floor_types[@as(usize, @intCast(i))] == 0) {
            const g = &f.*.floor_config[@as(usize, @intCast(i))].floor0;
            g.*.order = @intCast(get_bits(f, 8));
            g.*.rate = @as(uint16, @intCast(get_bits(f, 16)));
            g.*.bark_map_size = @as(uint16, @intCast(get_bits(f, 16)));
            g.*.amplitude_bits = @intCast(get_bits(f, 6));
            g.*.amplitude_offset = @intCast(get_bits(f, 8));
            g.*.number_of_books = @intCast(get_bits(f, 4) + 1);
            var j: c_int = 0;
            while (j < @as(c_int, @intCast(g.*.number_of_books))) : (j += 1) {
                g.*.book_list[@as(usize, @intCast(j))] = @intCast(get_bits(f, 8));
            }
            return @"error"(f, @as(u32, @bitCast(VORBIS_feature_not_supported)));
        } else {
            var p: [31 * 8 + 2]stbv__floor_ordering = undefined;
            const g = &f.*.floor_config[@as(usize, @intCast(i))].floor1;
            var max_class: c_int = -1;
            g.*.partitions = @intCast(get_bits(f, 5));
            var j: c_int = 0;
            while (j < @as(c_int, @intCast(g.*.partitions))) : (j += 1) {
                g.*.partition_class_list[@as(usize, @intCast(j))] = @intCast(get_bits(f, 4));
                if (@as(c_int, @intCast(g.*.partition_class_list[@as(usize, @intCast(j))])) > max_class) {
                    max_class = @as(c_int, @intCast(g.*.partition_class_list[@as(usize, @intCast(j))]));
                }
            }
            j = 0;
            while (j <= max_class) : (j += 1) {
                g.*.class_dimensions[@as(usize, @intCast(j))] = @intCast(get_bits(f, 3) + 1);
                g.*.class_subclasses[@as(usize, @intCast(j))] = @intCast(get_bits(f, 2));
                if (g.*.class_subclasses[@as(usize, @intCast(j))] != 0) {
                    g.*.class_masterbooks[@as(usize, @intCast(j))] = @intCast(get_bits(f, 8));
                    if (@as(c_int, @intCast(g.*.class_masterbooks[@as(usize, @intCast(j))])) >= f.*.codebook_count) {
                        return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
                    }
                }
                var k: c_int = 0;
                while (k < (@as(c_int, 1) << @intCast(g.*.class_subclasses[@as(usize, @intCast(j))]))) : (k += 1) {
                    g.*.subclass_books[@as(usize, @intCast(j))][@as(usize, @intCast(k))] = @as(int16, @intCast(@as(c_int, @intCast(get_bits(f, 8))) - 1));
                    if (g.*.subclass_books[@as(usize, @intCast(j))][@as(usize, @intCast(k))] >= @as(int16, @intCast(f.*.codebook_count))) {
                        return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
                    }
                }
            }
            g.*.floor1_multiplier = @intCast(get_bits(f, 2) + 1);
            g.*.rangebits = @intCast(get_bits(f, 4));
            g.*.Xlist[0] = 0;
            g.*.Xlist[1] = @as(uint16, @intCast(@as(c_int, 1) << @intCast(g.*.rangebits)));
            g.*.values = 2;
            j = 0;
            while (j < @as(c_int, @intCast(g.*.partitions))) : (j += 1) {
                const cls = @as(c_int, @intCast(g.*.partition_class_list[@as(usize, @intCast(j))]));
                var k: c_int = 0;
                while (k < @as(c_int, @intCast(g.*.class_dimensions[@as(usize, @intCast(cls))]))) : (k += 1) {
                    g.*.Xlist[@as(usize, @intCast(g.*.values))] = @as(uint16, @intCast(get_bits(f, g.*.rangebits)));
                    g.*.values += 1;
                }
            }
            j = 0;
            while (j < @as(c_int, @intCast(g.*.values))) : (j += 1) {
                p[@as(usize, @intCast(j))].x = g.*.Xlist[@as(usize, @intCast(j))];
                p[@as(usize, @intCast(j))].id = @as(uint16, @intCast(j));
            }
            qsort(@as(?*anyopaque, @ptrCast(&p)), @as(usize, @intCast(g.*.values)), @sizeOf(stbv__floor_ordering), point_compare);
            j = 0;
            while (j < @as(c_int, @intCast(g.*.values)) - 1) : (j += 1) {
                if (p[@as(usize, @intCast(j))].x == p[@as(usize, @intCast(j + 1))].x) {
                    return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
                }
            }
            j = 0;
            while (j < @as(c_int, @intCast(g.*.values))) : (j += 1) {
                g.*.sorted_order[@as(usize, @intCast(j))] = @as(u8, @intCast(p[@as(usize, @intCast(j))].id));
            }
            j = 2;
            while (j < @as(c_int, @intCast(g.*.values))) : (j += 1) {
                var low: c_int = 0;
                var hi: c_int = 0;
                neighbors(@ptrCast(@alignCast(&g.*.Xlist)), j, &low, &hi);
                g.*.neighbors[@as(usize, @intCast(j))][@as(usize, 0)] = @as(u8, @intCast(low));
                g.*.neighbors[@as(usize, @intCast(j))][@as(usize, 1)] = @as(u8, @intCast(hi));
            }

            if (@as(c_int, @intCast(g.*.values)) > longest_floorlist) {
                longest_floorlist = @as(c_int, @intCast(g.*.values));
            }
        }
    }

    // Residue
    f.*.residue_count = @as(c_int, @intCast(get_bits(f, 6) + 1));
    f.*.residue_config = @as([*c]Residue, @ptrCast(@alignCast(setup_malloc(f, f.*.residue_count * @sizeOf(Residue)))));
    if (f.*.residue_config == null) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
    @memset(f.*.residue_config[0..@as(usize, @intCast(f.*.residue_count))], std.mem.zeroes(Residue));

    i = 0;
    while (i < f.*.residue_count) : (i += 1) {
        var residue_cascade: [64]u8 = undefined;
        const r = f.*.residue_config + @as(usize, @intCast(i));
        f.*.residue_types[@as(usize, @intCast(i))] = @as(uint16, @intCast(get_bits(f, 16)));
        if (f.*.residue_types[@as(usize, @intCast(i))] > 2) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
        r.*.begin = get_bits(f, 24);
        r.*.end = get_bits(f, 24);
        if (r.*.end < r.*.begin) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
        r.*.part_size = get_bits(f, 24) + 1;
        r.*.classifications = @intCast(get_bits(f, 6) + 1);
        r.*.classbook = @intCast(get_bits(f, 8));
        if (@as(c_int, @intCast(r.*.classbook)) >= f.*.codebook_count) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));

        var j: c_int = 0;
        while (j < @as(c_int, @intCast(r.*.classifications))) : (j += 1) {
            var high_bits: u8 = 0;
            const low_bits = @as(u8, @intCast(get_bits(f, 3)));
            if (get_bits(f, 1) != 0) {
                high_bits = @as(u8, @intCast(get_bits(f, 5)));
            }
            residue_cascade[@as(usize, @intCast(j))] = high_bits * 8 + low_bits;
        }
        r.*.residue_books = @as([*c][8]int16, @ptrCast(@alignCast(setup_malloc(f, @sizeOf([8]int16) * r.*.classifications))));
        if (r.*.residue_books == null) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
        j = 0;
        while (j < @as(c_int, @intCast(r.*.classifications))) : (j += 1) {
            var k: c_int = 0;
            while (k < 8) : (k += 1) {
                if ((residue_cascade[@as(usize, @intCast(j))] & (@as(u8, 1) << @intCast(k))) != 0) {
                    r.*.residue_books[@as(usize, @intCast(j))][@as(usize, @intCast(k))] = @as(int16, @intCast(get_bits(f, 8)));
                    if (r.*.residue_books[@as(usize, @intCast(j))][@as(usize, @intCast(k))] >= @as(int16, @intCast(f.*.codebook_count))) {
                        return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
                    }
                } else {
                    r.*.residue_books[@as(usize, @intCast(j))][@as(usize, @intCast(k))] = -1;
                }
            }
        }
        r.*.classdata = @as([*c][*c]u8, @ptrCast(@alignCast(setup_malloc(f, @sizeOf([*c]u8) * f.*.codebooks[@as(usize, @intCast(r.*.classbook))].entries))));
        if (r.*.classdata == null) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
        @memset(r.*.classdata[0..@as(usize, @intCast(f.*.codebooks[@as(usize, @intCast(r.*.classbook))].entries))], null);
        j = 0;
        while (j < f.*.codebooks[@as(usize, @intCast(r.*.classbook))].entries) : (j += 1) {
            const classwords = f.*.codebooks[@as(usize, @intCast(r.*.classbook))].dimensions;
            var temp = j;
            r.*.classdata[@as(usize, @intCast(j))] = @as([*c]u8, @ptrCast(setup_malloc(f, @sizeOf(u8) * classwords)));
            if (r.*.classdata[@as(usize, @intCast(j))] == null) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
            var k: c_int = classwords - 1;
            while (k >= 0) : (k -= 1) {
                r.*.classdata[@as(usize, @intCast(j))][@as(usize, @intCast(k))] = @as(u8, @intCast(@mod(temp, @as(c_int, @intCast(r.*.classifications)))));
                temp = @divTrunc(temp, @as(c_int, @intCast(r.*.classifications)));
            }
        }
    }

    // Mappings
    f.*.mapping_count = @as(c_int, @intCast(get_bits(f, 6) + 1));
    f.*.mapping = @as([*c]Mapping, @ptrCast(@alignCast(setup_malloc(f, @as(c_int, @intCast(f.*.mapping_count)) * @sizeOf(Mapping)))));
    if (f.*.mapping == null) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
    @memset(f.*.mapping[0..@as(usize, @intCast(f.*.mapping_count))], std.mem.zeroes(Mapping));

    i = 0;
    while (i < f.*.mapping_count) : (i += 1) {
        const m = f.*.mapping + @as(usize, @intCast(i));
        const mapping_type = @as(c_int, @intCast(get_bits(f, 16)));
        if (mapping_type != 0) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
        m.*.chan = @as([*c]MappingChannel, @ptrCast(@alignCast(setup_malloc(f, @as(c_int, @intCast(f.*.channels)) * @sizeOf(MappingChannel)))));
        if (m.*.chan == null) return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
        if (get_bits(f, 1) != 0) {
            m.*.submaps = @as(u8, @intCast(get_bits(f, 4) + 1));
        } else {
            m.*.submaps = 1;
        }
        if (@as(c_int, @intCast(m.*.submaps)) > max_submaps) {
            max_submaps = @as(c_int, @intCast(m.*.submaps));
        }
        if (get_bits(f, 1) != 0) {
            m.*.coupling_steps = @as(uint16, @intCast(get_bits(f, 8) + 1));
            if (m.*.coupling_steps > @as(uint16, @intCast(f.*.channels))) {
                return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
            }
            var k: c_int = 0;
            while (k < @as(c_int, @intCast(m.*.coupling_steps))) : (k += 1) {
                m.*.chan[@as(usize, @intCast(k))].magnitude = @as(u8, @intCast(get_bits(f, ilog(f.*.channels - 1))));
                m.*.chan[@as(usize, @intCast(k))].angle = @as(u8, @intCast(get_bits(f, ilog(f.*.channels - 1))));
                if (m.*.chan[@as(usize, @intCast(k))].magnitude >= @as(u8, @intCast(f.*.channels))) {
                    return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
                }
                if (m.*.chan[@as(usize, @intCast(k))].angle >= @as(u8, @intCast(f.*.channels))) {
                    return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
                }
                if (m.*.chan[@as(usize, @intCast(k))].magnitude == m.*.chan[@as(usize, @intCast(k))].angle) {
                    return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
                }
            }
        } else {
            m.*.coupling_steps = 0;
        }

        if (get_bits(f, 2) != 0) return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));

        if (@as(c_int, @intCast(m.*.submaps)) > 1) {
            var j: c_int = 0;
            while (j < f.*.channels) : (j += 1) {
                m.*.chan[@as(usize, @intCast(j))].mux = @as(u8, @intCast(get_bits(f, 4)));
                if (@as(c_int, @intCast(m.*.chan[@as(usize, @intCast(j))].mux)) >= @as(c_int, @intCast(m.*.submaps))) {
                    return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
                }
            }
        } else {
            var j: c_int = 0;
            while (j < f.*.channels) : (j += 1) {
                m.*.chan[@as(usize, @intCast(j))].mux = 0;
            }
        }
        var j: c_int = 0;
        while (j < @as(c_int, @intCast(m.*.submaps))) : (j += 1) {
            _ = get_bits(f, 8);
            m.*.submap_floor[@as(usize, @intCast(j))] = @intCast(get_bits(f, 8));
            m.*.submap_residue[@as(usize, @intCast(j))] = @intCast(get_bits(f, 8));
            if (@as(c_int, @intCast(m.*.submap_floor[@as(usize, @intCast(j))])) >= f.*.floor_count) {
                return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
            }
            if (@as(c_int, @intCast(m.*.submap_residue[@as(usize, @intCast(j))])) >= f.*.residue_count) {
                return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
            }
        }
    }

    // Modes
    f.*.mode_count = @as(c_int, @intCast(get_bits(f, 6) + 1));
    i = 0;
    while (i < f.*.mode_count) : (i += 1) {
        f.*.mode_config[@as(usize, @intCast(i))].blockflag = @intCast(get_bits(f, 1));
        f.*.mode_config[@as(usize, @intCast(i))].windowtype = @as(uint16, @intCast(get_bits(f, 16)));
        f.*.mode_config[@as(usize, @intCast(i))].transformtype = @as(uint16, @intCast(get_bits(f, 16)));
        f.*.mode_config[@as(usize, @intCast(i))].mapping = @intCast(get_bits(f, 8));
        if (f.*.mode_config[@as(usize, @intCast(i))].windowtype != 0) {
            return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
        }
        if (f.*.mode_config[@as(usize, @intCast(i))].transformtype != 0) {
            return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
        }
        if (@as(c_int, @intCast(f.*.mode_config[@as(usize, @intCast(i))].mapping)) >= f.*.mapping_count) {
            return @"error"(f, @as(u32, @bitCast(VORBIS_invalid_setup)));
        }
    }

    flush_packet(f);

    f.*.previous_length = 0;

    var j: c_int = 0;
    while (j < f.*.channels) : (j += 1) {
        f.*.channel_buffers[@as(usize, @intCast(j))] = @as([*c]f32, @ptrCast(@alignCast(setup_malloc(f, @intCast(@sizeOf(f32) * f.*.blocksize_1)))));
        f.*.previous_window[@as(usize, @intCast(j))] = @as([*c]f32, @ptrCast(@alignCast(setup_malloc(f, @intCast(@sizeOf(f32) * (f.*.blocksize_1 >> @intCast(1)))))));
        f.*.finalY[@as(usize, @intCast(j))] = @as([*c]int16, @ptrCast(@alignCast(setup_malloc(f, @intCast(@sizeOf(int16) * @as(usize, @intCast(longest_floorlist)))))));
        if (f.*.channel_buffers[@as(usize, @intCast(j))] == null or f.*.previous_window[@as(usize, @intCast(j))] == null or f.*.finalY[@as(usize, @intCast(j))] == null) {
            return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
        }
        @memset(f.*.channel_buffers[@as(usize, @intCast(j))][0..@as(usize, @intCast(f.*.blocksize_1))], 0);
    }
    if (f.*.channels < STB_VORBIS_MAX_CHANNELS) {
        var k: c_int = f.*.channels;
        while (k < @as(c_int, @intCast(STB_VORBIS_MAX_CHANNELS))) : (k += 1) {
            f.*.channel_buffers[@as(usize, @intCast(k))] = null;
            f.*.previous_window[@as(usize, @intCast(k))] = null;
            f.*.finalY[@as(usize, @intCast(k))] = null;
        }
    }

    if (init_blocksize(f, 0, f.*.blocksize_0) == 0) return FALSE;
    if (init_blocksize(f, 1, f.*.blocksize_1) == 0) return FALSE;
    f.*.blocksize[@as(usize, 0)] = f.*.blocksize_0;
    f.*.blocksize[@as(usize, 1)] = f.*.blocksize_1;

    if (integer_divide_table[1][@as(usize, 1)] == 0) {
        i = 0;
        while (i < DIVTAB_NUMER) : (i += 1) {
            j = 1;
            while (j < DIVTAB_DENOM) : (j += 1) {
                integer_divide_table[@as(usize, @intCast(i))][@as(usize, @intCast(j))] = @intCast(@divTrunc(i, j));
            }
        }
    }

    // Compute how much temporary memory is needed
    var max_part_read: c_int = 0;
    {
        const imdct_mem = @as(u32, @intCast((f.*.blocksize_1 * @as(c_int, @intCast(@sizeOf(f32)))) >> 1));
        var classify_mem: u32 = undefined;
        i = 0;
        while (i < f.*.residue_count) : (i += 1) {
            const r = f.*.residue_config + @as(usize, @intCast(i));
            const actual_size = @as(u32, @intCast(@divTrunc(f.*.blocksize_1, @as(c_int, 2))));
            const limit_r_begin = if (r.*.begin < actual_size) r.*.begin else actual_size;
            const limit_r_end = if (r.*.end < actual_size) r.*.end else actual_size;
            const n_read = @as(c_int, @intCast(limit_r_end - limit_r_begin));
            const part_read = @divTrunc(n_read, @as(c_int, @intCast(r.*.part_size)));
            if (part_read > max_part_read) {
                max_part_read = part_read;
            }
        }
        // STB_VORBIS_DIVIDES_IN_RESIDUE not defined
        classify_mem = @as(u32, @intCast(f.*.channels)) * (@sizeOf(?*anyopaque) + @as(u32, @intCast(max_part_read)) * @sizeOf([*c]u8));

        f.*.temp_memory_required = classify_mem;
        if (imdct_mem > f.*.temp_memory_required) {
            f.*.temp_memory_required = imdct_mem;
        }
    }

    if (f.*.alloc.alloc_buffer != null) {
        // Note: The original C code asserts that alloc_buffer follows the struct in memory.
        // We're not using that memory layout, so we skip the assertion.
        // Check if there's enough temp memory so we don't error later
        if (f.*.setup_offset + @as(c_int, @intCast(@sizeOf(vorb) + f.*.temp_memory_required)) > @as(u32, @intCast(f.*.temp_offset))) {
            return @"error"(f, @as(u32, @bitCast(VORBIS_outofmem)));
        }
    }

    f.*.temp_memory_required = if (f.*.temp_memory_required > f.*.setup_temp_memory_required) f.*.temp_memory_required else f.*.setup_temp_memory_required;

    if (IS_PUSH_MODE(f) == 0) {
        f.*.temp_offset = @intCast(f.*.alloc.alloc_buffer_length_in_bytes);
    } else {
        f.*.temp_offset = @intCast(f.*.temp_memory_required);
    }

    if (longest_floorlist <= @as(c_int, @intCast(max_part_read))) {
        max_part_read = longest_floorlist;
    }
    if (@as(c_int, @intCast(max_part_read)) > @as(c_int, @intCast(STB_VORBIS_MAX_CHANNELS))) {
        max_part_read = STB_VORBIS_MAX_CHANNELS;
    }
    if (max_submaps == 0) {
        max_submaps = 1;
    }
    f.*.temp_memory_required += @as(u32, @intCast((max_submaps - 1) * @sizeOf([*c]u8)));

    if (f.*.next_seg == -1) {
        f.*.first_audio_page_offset = @as(u32, @bitCast(stb_vorbis_get_file_offset(f)));
    } else {
        f.*.first_audio_page_offset = 0;
    }

    return TRUE;
}
pub fn vorbis_deinit(arg_p: [*c]stb_vorbis) callconv(.c) void {
    var p = arg_p;
    _ = &p;
    var i: c_int = undefined;
    _ = &i;
    var j: c_int = undefined;
    _ = &j;
    setup_free(p, @as(?*anyopaque, @ptrCast(p.*.vendor)));
    {
        i = 0;
        while (i < p.*.comment_list_length) : (i += 1) {
            setup_free(p, @as(?*anyopaque, @ptrCast((blk: {
                const tmp = i;
                if (tmp >= 0) break :blk p.*.comment_list + @as(usize, @intCast(tmp)) else break :blk p.*.comment_list - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).*)));
        }
    }
    setup_free(p, @as(?*anyopaque, @ptrCast(p.*.comment_list)));
    if (p.*.residue_config != null) {
        {
            i = 0;
            while (i < p.*.residue_count) : (i += 1) {
                var r: [*c]Residue = p.*.residue_config + @as(usize, @bitCast(@as(isize, @intCast(i))));
                _ = &r;
                if (r.*.classdata != null) {
                    {
                        j = 0;
                        while (j < p.*.codebooks[r.*.classbook].entries) : (j += 1) {
                            setup_free(p, @as(?*anyopaque, @ptrCast((blk: {
                                const tmp = j;
                                if (tmp >= 0) break :blk r.*.classdata + @as(usize, @intCast(tmp)) else break :blk r.*.classdata - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                            }).*)));
                        }
                    }
                    setup_free(p, @as(?*anyopaque, @ptrCast(r.*.classdata)));
                }
                setup_free(p, @as(?*anyopaque, @ptrCast(r.*.residue_books)));
            }
        }
    }
    if (p.*.codebooks != null) {
        _ = @as(c_int, 0);
        {
            i = 0;
            while (i < p.*.codebook_count) : (i += 1) {
                var c: [*c]Codebook = p.*.codebooks + @as(usize, @bitCast(@as(isize, @intCast(i))));
                _ = &c;
                setup_free(p, @as(?*anyopaque, @ptrCast(c.*.codeword_lengths)));
                setup_free(p, @as(?*anyopaque, @ptrCast(c.*.multiplicands)));
                setup_free(p, @as(?*anyopaque, @ptrCast(c.*.codewords)));
                setup_free(p, @as(?*anyopaque, @ptrCast(c.*.sorted_codewords)));
                setup_free(p, @as(?*anyopaque, @ptrCast(if (c.*.sorted_values != null) c.*.sorted_values - @as(usize, @bitCast(@as(isize, @intCast(@as(c_int, 1))))) else null)));
            }
        }
        setup_free(p, @as(?*anyopaque, @ptrCast(p.*.codebooks)));
    }
    setup_free(p, @as(?*anyopaque, @ptrCast(p.*.floor_config)));
    setup_free(p, @as(?*anyopaque, @ptrCast(p.*.residue_config)));
    if (p.*.mapping != null) {
        {
            i = 0;
            while (i < p.*.mapping_count) : (i += 1) {
                setup_free(p, @as(?*anyopaque, @ptrCast((blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk p.*.mapping + @as(usize, @intCast(tmp)) else break :blk p.*.mapping - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).*.chan)));
            }
        }
        setup_free(p, @as(?*anyopaque, @ptrCast(p.*.mapping)));
    }
    _ = @as(c_int, 0);
    {
        i = 0;
        while ((i < p.*.channels) and (i < @as(c_int, 16))) : (i += 1) {
            setup_free(p, @as(?*anyopaque, @ptrCast(p.*.channel_buffers[@as(u32, @intCast(i))])));
            setup_free(p, @as(?*anyopaque, @ptrCast(p.*.previous_window[@as(u32, @intCast(i))])));
            setup_free(p, @as(?*anyopaque, @ptrCast(p.*.finalY[@as(u32, @intCast(i))])));
        }
    }
    {
        i = 0;
        while (i < @as(c_int, 2)) : (i += 1) {
            setup_free(p, @as(?*anyopaque, @ptrCast(p.*.A[@as(u32, @intCast(i))])));
            setup_free(p, @as(?*anyopaque, @ptrCast(p.*.B[@as(u32, @intCast(i))])));
            setup_free(p, @as(?*anyopaque, @ptrCast(p.*.C[@as(u32, @intCast(i))])));
            setup_free(p, @as(?*anyopaque, @ptrCast(p.*.window[@as(u32, @intCast(i))])));
            setup_free(p, @as(?*anyopaque, @ptrCast(p.*.bit_reverse[@as(u32, @intCast(i))])));
        }
    }
}
pub fn vorbis_init(p: [*c]stb_vorbis, z: [*c]const stb_vorbis_alloc) void {
    p.* = std.mem.zeroes(stb_vorbis);
    if (z != null) {
        p.*.alloc = z.*;
        p.*.alloc.alloc_buffer_length_in_bytes &= ~@as(c_int, 7);
        p.*.temp_offset = p.*.alloc.alloc_buffer_length_in_bytes;
    }
    p.*.eof = 0;
    p.*.@"error" = @as(u32, @bitCast(VORBIS__no_error));
    p.*.stream = null;
    p.*.codebooks = null;
    p.*.page_crc_tests = -@as(c_int, 1);
    p.*.close_on_free = 0;
}
pub fn vorbis_alloc(arg_f: [*c]stb_vorbis) callconv(.c) [*c]stb_vorbis {
    var f = arg_f;
    _ = &f;
    var p: [*c]stb_vorbis = @as([*c]stb_vorbis, @ptrCast(@alignCast(setup_malloc(f, @as(c_int, @bitCast(@as(u32, @truncate(@sizeOf(stb_vorbis)))))))));
    _ = &p;
    return p;
}
pub fn vorbis_search_for_page_pushdata(arg_f: [*c]vorb, arg_data: [*c]u8, arg_data_len: c_int) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var data = arg_data;
    _ = &data;
    var data_len = arg_data_len;
    _ = &data_len;
    var i: c_int = undefined;
    _ = &i;
    var n: c_int = undefined;
    _ = &n;
    {
        i = 0;
        while (i < f.*.page_crc_tests) : (i += 1) {
            f.*.scan[@as(u32, @intCast(i))].bytes_done = 0;
        }
    }
    if (f.*.page_crc_tests < @as(c_int, 4)) {
        if (data_len < @as(c_int, 4)) return 0;
        data_len -= @as(c_int, 3);
        {
            i = 0;
            while (i < data_len) : (i += 1) {
                if (@as(c_int, @bitCast(@as(u32, (blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk data + @as(usize, @intCast(tmp)) else break :blk data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).*))) == @as(c_int, 79)) {
                    if (@as(c_int, 0) == memcmp(@as(?*const anyopaque, @ptrCast(data + @as(usize, @bitCast(@as(isize, @intCast(i)))))), @as(?*const anyopaque, @ptrCast(@as([*c]u8, @ptrCast(@alignCast(&ogg_page_header[@as(usize, @intCast(0))]))))), @as(c_ulong, @bitCast(@as(c_long, @as(c_int, 4)))))) {
                        var j: c_int = undefined;
                        _ = &j;
                        var len: c_int = undefined;
                        _ = &len;
                        var crc: u32 = undefined;
                        _ = &crc;
                        if (((i + @as(c_int, 26)) >= data_len) or (((i + @as(c_int, 27)) + @as(c_int, @bitCast(@as(u32, (blk: {
                            const tmp = i + @as(c_int, 26);
                            if (tmp >= 0) break :blk data + @as(usize, @intCast(tmp)) else break :blk data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).*)))) >= data_len)) {
                            data_len = i;
                            break;
                        }
                        len = @as(c_int, 27) + @as(c_int, @bitCast(@as(u32, (blk: {
                            const tmp = i + @as(c_int, 26);
                            if (tmp >= 0) break :blk data + @as(usize, @intCast(tmp)) else break :blk data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).*)));
                        {
                            j = 0;
                            while (j < @as(c_int, @bitCast(@as(u32, (blk: {
                                const tmp = i + @as(c_int, 26);
                                if (tmp >= 0) break :blk data + @as(usize, @intCast(tmp)) else break :blk data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                            }).*)))) : (j += 1) {
                                len += @as(c_int, @bitCast(@as(u32, (blk: {
                                    const tmp = (i + @as(c_int, 27)) + j;
                                    if (tmp >= 0) break :blk data + @as(usize, @intCast(tmp)) else break :blk data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                }).*)));
                            }
                        }
                        crc = 0;
                        {
                            j = 0;
                            while (j < @as(c_int, 22)) : (j += 1) {
                                crc = crc32_update(crc, (blk: {
                                    const tmp = i + j;
                                    if (tmp >= 0) break :blk data + @as(usize, @intCast(tmp)) else break :blk data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                                }).*);
                            }
                        }
                        while (j < @as(c_int, 26)) : (j += 1) {
                            crc = crc32_update(crc, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))));
                        }
                        n = blk: {
                            const ref = &f.*.page_crc_tests;
                            const tmp = ref.*;
                            ref.* += 1;
                            break :blk tmp;
                        };
                        f.*.scan[@as(u32, @intCast(n))].bytes_left = len - j;
                        f.*.scan[@as(u32, @intCast(n))].crc_so_far = crc;
                        f.*.scan[@as(u32, @intCast(n))].goal_crc = @as(u32, @bitCast(((@as(c_int, @bitCast(@as(u32, (blk: {
                            const tmp = i + @as(c_int, 22);
                            if (tmp >= 0) break :blk data + @as(usize, @intCast(tmp)) else break :blk data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).*))) + (@as(c_int, @bitCast(@as(u32, (blk: {
                            const tmp = i + @as(c_int, 23);
                            if (tmp >= 0) break :blk data + @as(usize, @intCast(tmp)) else break :blk data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).*))) << @intCast(8))) + (@as(c_int, @bitCast(@as(u32, (blk: {
                            const tmp = i + @as(c_int, 24);
                            if (tmp >= 0) break :blk data + @as(usize, @intCast(tmp)) else break :blk data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).*))) << @intCast(16))) + (@as(c_int, @bitCast(@as(u32, (blk: {
                            const tmp = i + @as(c_int, 25);
                            if (tmp >= 0) break :blk data + @as(usize, @intCast(tmp)) else break :blk data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).*))) << @intCast(24))));
                        if (@as(c_int, @bitCast(@as(u32, (blk: {
                            const tmp = ((i + @as(c_int, 27)) + @as(c_int, @bitCast(@as(u32, (blk_1: {
                                const tmp_2 = i + @as(c_int, 26);
                                if (tmp_2 >= 0) break :blk_1 data + @as(usize, @intCast(tmp_2)) else break :blk_1 data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp_2)) +% -1));
                            }).*)))) - @as(c_int, 1);
                            if (tmp >= 0) break :blk data + @as(usize, @intCast(tmp)) else break :blk data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).*))) == @as(c_int, 255)) {
                            f.*.scan[@as(u32, @intCast(n))].sample_loc = @as(u32, @bitCast(~@as(c_int, 0)));
                        } else {
                            f.*.scan[@as(u32, @intCast(n))].sample_loc = @as(u32, @bitCast(((@as(c_int, @bitCast(@as(u32, (blk: {
                                const tmp = i + @as(c_int, 6);
                                if (tmp >= 0) break :blk data + @as(usize, @intCast(tmp)) else break :blk data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                            }).*))) + (@as(c_int, @bitCast(@as(u32, (blk: {
                                const tmp = i + @as(c_int, 7);
                                if (tmp >= 0) break :blk data + @as(usize, @intCast(tmp)) else break :blk data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                            }).*))) << @intCast(8))) + (@as(c_int, @bitCast(@as(u32, (blk: {
                                const tmp = i + @as(c_int, 8);
                                if (tmp >= 0) break :blk data + @as(usize, @intCast(tmp)) else break :blk data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                            }).*))) << @intCast(16))) + (@as(c_int, @bitCast(@as(u32, (blk: {
                                const tmp = i + @as(c_int, 9);
                                if (tmp >= 0) break :blk data + @as(usize, @intCast(tmp)) else break :blk data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                            }).*))) << @intCast(24))));
                        }
                        f.*.scan[@as(u32, @intCast(n))].bytes_done = i + j;
                        if (f.*.page_crc_tests == @as(c_int, 4)) break;
                    }
                }
            }
        }
    }
    {
        i = 0;
        while (i < f.*.page_crc_tests) {
            var crc: u32 = undefined;
            _ = &crc;
            var j: c_int = undefined;
            _ = &j;
            var n_1: c_int = f.*.scan[@as(u32, @intCast(i))].bytes_done;
            _ = &n_1;
            var m: c_int = f.*.scan[@as(u32, @intCast(i))].bytes_left;
            _ = &m;
            if (m > (data_len - n_1)) {
                m = data_len - n_1;
            }
            crc = f.*.scan[@as(u32, @intCast(i))].crc_so_far;
            {
                j = 0;
                while (j < m) : (j += 1) {
                    crc = crc32_update(crc, (blk: {
                        const tmp = n_1 + j;
                        if (tmp >= 0) break :blk data + @as(usize, @intCast(tmp)) else break :blk data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                    }).*);
                }
            }
            f.*.scan[@as(u32, @intCast(i))].bytes_left -= m;
            f.*.scan[@as(u32, @intCast(i))].crc_so_far = crc;
            if (f.*.scan[@as(u32, @intCast(i))].bytes_left == @as(c_int, 0)) {
                if (f.*.scan[@as(u32, @intCast(i))].crc_so_far == f.*.scan[@as(u32, @intCast(i))].goal_crc) {
                    data_len = n_1 + m;
                    f.*.page_crc_tests = -@as(c_int, 1);
                    f.*.previous_length = 0;
                    f.*.next_seg = -@as(c_int, 1);
                    f.*.current_loc = f.*.scan[@as(u32, @intCast(i))].sample_loc;
                    f.*.current_loc_valid = @intFromBool(f.*.current_loc != ~@as(u32, 0));
                    return data_len;
                }
                f.*.scan[@as(u32, @intCast(i))] = f.*.scan[
                    @as(u32, @intCast(blk: {
                        const ref = &f.*.page_crc_tests;
                        ref.* -= 1;
                        break :blk ref.*;
                    }))
                ];
            } else {
                i += 1;
            }
        }
    }
    return data_len;
}
pub export fn vorbis_find_page(arg_f: [*c]stb_vorbis, arg_end: [*c]u32, arg_last: [*c]u32) callconv(.c) u32 {
    const f = arg_f;
    const end = arg_end;
    const last = arg_last;

    while (true) {
        if (f.*.eof != 0) return 0;
        const n = get8(f);

        if (n == 0x4f) { // page header candidate
            const retry_loc = stb_vorbis_get_file_offset(f);

            // Use labeled block to handle goto invalid
            validation: {
                // check if we're off the end of a file_section stream
                if (retry_loc - 25 > f.*.stream_len) return 0;

                // check the rest of the header
                var i: c_int = 1;
                while (i < 4) : (i += 1) {
                    if (get8(f) != ogg_page_header[@as(usize, @intCast(i))]) {
                        break :validation;
                    }
                }
                if (f.*.eof != 0) return 0;

                // i == 4, header matches
                var header: [27]u8 = undefined;
                var idx: u32 = 0;
                while (idx < 4) : (idx += 1) {
                    header[@as(usize, idx)] = ogg_page_header[@as(usize, idx)];
                }
                while (idx < 27) : (idx += 1) {
                    header[@as(usize, idx)] = get8(f);
                }
                if (f.*.eof != 0) return 0;
                if (header[4] != 0) break :validation; // goto invalid

                const goal = @as(u32, header[22]) +
                    (@as(u32, header[23]) << 8) +
                    (@as(u32, header[24]) << 16) +
                    (@as(u32, header[25]) << 24);

                idx = 22;
                while (idx < 26) : (idx += 1) {
                    header[@as(usize, idx)] = 0;
                }

                var crc: u32 = 0;
                idx = 0;
                while (idx < 27) : (idx += 1) {
                    crc = crc32_update(crc, header[@as(usize, idx)]);
                }

                var len: u32 = 0;
                idx = 0;
                while (idx < header[26]) : (idx += 1) {
                    const s = get8(f);
                    crc = crc32_update(crc, s);
                    len += s;
                }
                if ((len != 0) and (f.*.eof != 0)) return 0;

                idx = 0;
                while (idx < len) : (idx += 1) {
                    crc = crc32_update(crc, get8(f));
                }

                // finished parsing probable page
                if (crc == goal) {
                    if (end != null) {
                        end.* = stb_vorbis_get_file_offset(f);
                    }
                    if (last != null) {
                        if ((header[5] & 0x04) != 0) {
                            last.* = 1;
                        } else {
                            last.* = 0;
                        }
                    }
                    _ = set_file_offset(f, retry_loc - 1);
                    return 1;
                }
                // CRC didn't match, fall through to invalid
            }

            // invalid: not a valid page, so rewind and look for next one
            _ = set_file_offset(f, retry_loc);
        }
    }
}
pub fn get_seek_page_info(arg_f: [*c]stb_vorbis, arg_z: [*c]ProbedPage) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var z = arg_z;
    _ = &z;
    var header: [27]u8 = undefined;
    _ = &header;
    var lacing: [255]u8 = undefined;
    _ = &lacing;
    var i: c_int = undefined;
    _ = &i;
    var len: c_int = undefined;
    _ = &len;
    z.*.page_start = stb_vorbis_get_file_offset(f);
    _ = getn(f, @as([*c]u8, @ptrCast(@alignCast(&header[@as(usize, @intCast(0))]))), @as(c_int, 27));
    if ((((@as(c_int, @bitCast(@as(u32, header[@as(u32, @intCast(@as(c_int, 0)))]))) != @as(c_int, 'O')) or (@as(c_int, @bitCast(@as(u32, header[@as(u32, @intCast(@as(c_int, 1)))]))) != @as(c_int, 'g'))) or (@as(c_int, @bitCast(@as(u32, header[@as(u32, @intCast(@as(c_int, 2)))]))) != @as(c_int, 'g'))) or (@as(c_int, @bitCast(@as(u32, header[@as(u32, @intCast(@as(c_int, 3)))]))) != @as(c_int, 'S'))) return 0;
    _ = getn(f, @as([*c]u8, @ptrCast(@alignCast(&lacing[@as(usize, @intCast(0))]))), @as(c_int, @bitCast(@as(u32, header[@as(u32, @intCast(@as(c_int, 26)))]))));
    len = 0;
    {
        i = 0;
        while (i < @as(c_int, @bitCast(@as(u32, header[@as(u32, @intCast(@as(c_int, 26)))])))) : (i += 1) {
            len += @as(c_int, @bitCast(@as(u32, lacing[@as(u32, @intCast(i))])));
        }
    }
    z.*.page_end = ((z.*.page_start +% @as(u32, @bitCast(@as(c_int, 27)))) +% @as(u32, @bitCast(@as(u32, header[@as(u32, @intCast(@as(c_int, 26)))])))) +% @as(u32, @bitCast(len));
    z.*.last_decoded_sample = @as(u32, @bitCast(((@as(c_int, @bitCast(@as(u32, header[@as(u32, @intCast(@as(c_int, 6)))]))) + (@as(c_int, @bitCast(@as(u32, header[@as(u32, @intCast(@as(c_int, 7)))]))) << @intCast(8))) + (@as(c_int, @bitCast(@as(u32, header[@as(u32, @intCast(@as(c_int, 8)))]))) << @intCast(16))) + (@as(c_int, @bitCast(@as(u32, header[@as(u32, @intCast(@as(c_int, 9)))]))) << @intCast(24))));
    _ = set_file_offset(f, z.*.page_start);
    return 1;
}
pub fn go_to_page_before(arg_f: [*c]stb_vorbis, arg_limit_offset: u32) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var limit_offset = arg_limit_offset;
    _ = &limit_offset;
    var previous_safe: u32 = undefined;
    _ = &previous_safe;
    var end: u32 = undefined;
    _ = &end;
    if ((limit_offset >= @as(u32, @bitCast(@as(c_int, 65536)))) and ((limit_offset -% @as(u32, @bitCast(@as(c_int, 65536)))) >= f.*.first_audio_page_offset)) {
        previous_safe = limit_offset -% @as(u32, @bitCast(@as(c_int, 65536)));
    } else {
        previous_safe = f.*.first_audio_page_offset;
    }
    _ = set_file_offset(f, previous_safe);
    while (vorbis_find_page(f, &end, null) != 0) {
        if ((end >= limit_offset) and (stb_vorbis_get_file_offset(f) < limit_offset)) return 1;
        _ = set_file_offset(f, end);
    }
    return 0;
}
pub fn peek_decode_initial(arg_f: [*c]vorb, arg_p_left_start: [*c]c_int, arg_p_left_end: [*c]c_int, arg_p_right_start: [*c]c_int, arg_p_right_end: [*c]c_int, arg_mode: [*c]c_int) callconv(.c) c_int {
    var f = arg_f;
    _ = &f;
    var p_left_start = arg_p_left_start;
    _ = &p_left_start;
    var p_left_end = arg_p_left_end;
    _ = &p_left_end;
    var p_right_start = arg_p_right_start;
    _ = &p_right_start;
    var p_right_end = arg_p_right_end;
    _ = &p_right_end;
    var mode = arg_mode;
    _ = &mode;
    var bits_read: c_int = undefined;
    _ = &bits_read;
    var bytes_read: c_int = undefined;
    _ = &bytes_read;
    if (!(vorbis_decode_initial(f, p_left_start, p_left_end, p_right_start, p_right_end, mode) != 0)) return 0;
    bits_read = @as(c_int, 1) + ilog(f.*.mode_count - @as(c_int, 1));
    if (f.*.mode_config[@as(u32, @intCast(mode.*))].blockflag != 0) {
        bits_read += @as(c_int, 2);
    }
    bytes_read = @divTrunc(bits_read + @as(c_int, 7), @as(c_int, 8));
    f.*.bytes_in_seg +%= @as(u8, @bitCast(@as(i8, @truncate(bytes_read))));
    f.*.packet_bytes -= bytes_read;
    skip(f, -bytes_read);
    if (f.*.next_seg == -@as(c_int, 1)) {
        f.*.next_seg = f.*.segment_count - @as(c_int, 1);
    } else {
        f.*.next_seg -= 1;
    }
    f.*.valid_bits = 0;
    return 1;
}
pub var channel_position: [7][6]int8 = [7][6]int8{
    [1]int8{
        0,
    } ++ [1]int8{std.mem.zeroes(int8)} ** 5,
    [1]int8{
        @as(int8, @bitCast(@as(i8, @truncate((@as(c_int, 2) | @as(c_int, 4)) | @as(c_int, 1))))),
    } ++ [1]int8{std.mem.zeroes(int8)} ** 5,
    [2]int8{
        @as(int8, @bitCast(@as(i8, @truncate(@as(c_int, 2) | @as(c_int, 1))))),
        @as(int8, @bitCast(@as(i8, @truncate(@as(c_int, 4) | @as(c_int, 1))))),
    } ++ [1]int8{std.mem.zeroes(int8)} ** 4,
    [3]int8{
        @as(int8, @bitCast(@as(i8, @truncate(@as(c_int, 2) | @as(c_int, 1))))),
        @as(int8, @bitCast(@as(i8, @truncate((@as(c_int, 2) | @as(c_int, 4)) | @as(c_int, 1))))),
        @as(int8, @bitCast(@as(i8, @truncate(@as(c_int, 4) | @as(c_int, 1))))),
    } ++ [1]int8{std.mem.zeroes(int8)} ** 3,
    [4]int8{
        @as(int8, @bitCast(@as(i8, @truncate(@as(c_int, 2) | @as(c_int, 1))))),
        @as(int8, @bitCast(@as(i8, @truncate(@as(c_int, 4) | @as(c_int, 1))))),
        @as(int8, @bitCast(@as(i8, @truncate(@as(c_int, 2) | @as(c_int, 1))))),
        @as(int8, @bitCast(@as(i8, @truncate(@as(c_int, 4) | @as(c_int, 1))))),
    } ++ [1]int8{std.mem.zeroes(int8)} ** 2,
    [5]int8{
        @as(int8, @bitCast(@as(i8, @truncate(@as(c_int, 2) | @as(c_int, 1))))),
        @as(int8, @bitCast(@as(i8, @truncate((@as(c_int, 2) | @as(c_int, 4)) | @as(c_int, 1))))),
        @as(int8, @bitCast(@as(i8, @truncate(@as(c_int, 4) | @as(c_int, 1))))),
        @as(int8, @bitCast(@as(i8, @truncate(@as(c_int, 2) | @as(c_int, 1))))),
        @as(int8, @bitCast(@as(i8, @truncate(@as(c_int, 4) | @as(c_int, 1))))),
    } ++ [1]int8{std.mem.zeroes(int8)} ** 1,
    [6]int8{
        @as(int8, @bitCast(@as(i8, @truncate(@as(c_int, 2) | @as(c_int, 1))))),
        @as(int8, @bitCast(@as(i8, @truncate((@as(c_int, 2) | @as(c_int, 4)) | @as(c_int, 1))))),
        @as(int8, @bitCast(@as(i8, @truncate(@as(c_int, 4) | @as(c_int, 1))))),
        @as(int8, @bitCast(@as(i8, @truncate(@as(c_int, 2) | @as(c_int, 1))))),
        @as(int8, @bitCast(@as(i8, @truncate(@as(c_int, 4) | @as(c_int, 1))))),
        @as(int8, @bitCast(@as(i8, @truncate((@as(c_int, 2) | @as(c_int, 4)) | @as(c_int, 1))))),
    },
};
pub const float_conv = extern union {
    f: f32,
    i: c_int,
};
pub const stb_vorbis_float_size_test = [1]u8;
pub fn copy_samples(arg_dest: [*c]c_short, arg_src: [*c]f32, arg_len: c_int) callconv(.c) void {
    var dest = arg_dest;
    _ = &dest;
    var src = arg_src;
    _ = &src;
    var len = arg_len;
    _ = &len;
    var i: c_int = undefined;
    _ = &i;
    {
        i = 0;
        while (i < len) : (i += 1) {
            var temp: float_conv = undefined;
            _ = &temp;
            var v: c_int = blk: {
                temp.f = (blk_1: {
                    const tmp = i;
                    if (tmp >= 0) break :blk_1 src + @as(usize, @intCast(tmp)) else break :blk_1 src - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).* + ((1.5 * @as(f32, @floatFromInt(@as(c_int, 1) << @intCast(@as(c_int, 23) - @as(c_int, 15))))) + (0.5 / @as(f32, @floatFromInt(@as(c_int, 1) << @intCast(15)))));
                break :blk temp.i - (((@as(c_int, 150) - @as(c_int, 15)) << @intCast(23)) + (@as(c_int, 1) << @intCast(22)));
            };
            _ = &v;
            if (@as(u32, @bitCast(v + @as(c_int, 32768))) > @as(u32, @bitCast(@as(c_int, 65535)))) {
                v = if (v < @as(c_int, 0)) -@as(c_int, 32768) else @as(c_int, 32767);
            }
            (blk: {
                const tmp = i;
                if (tmp >= 0) break :blk dest + @as(usize, @intCast(tmp)) else break :blk dest - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = @as(c_short, @bitCast(@as(c_short, @truncate(v))));
        }
    }
}
pub fn compute_samples(mask: c_int, output: [*c]c_short, num_c: c_int, data: [*c][*c]f32, d_offset: c_int, len: c_int) void {
    var buffer: [32]f32 = undefined;
    var i: c_int = undefined;
    var j: c_int = undefined;
    var o: c_int = 0;
    var n: c_int = 32;

    while (o < len) : (o += @as(c_int, 32)) {
        @memset(&buffer, 0);
        if ((o + n) > len) {
            n = len - o;
        }
        {
            j = 0;
            while (j < num_c) : (j += 1) {
                if ((@as(c_int, @bitCast(@as(c_int, channel_position[@as(u32, @intCast(num_c))][@as(u32, @intCast(j))]))) & mask) != 0) {
                    {
                        i = 0;
                        while (i < n) : (i += 1) {
                            buffer[@as(u32, @intCast(i))] += (blk: {
                                const tmp = (d_offset + o) + i;
                                if (tmp >= 0) break :blk (blk_1: {
                                    const tmp_2 = j;
                                    if (tmp_2 >= 0) break :blk_1 data + @as(usize, @intCast(tmp_2)) else break :blk_1 data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp_2)) +% -1));
                                }).* + @as(usize, @intCast(tmp)) else break :blk (blk_1: {
                                    const tmp_2 = j;
                                    if (tmp_2 >= 0) break :blk_1 data + @as(usize, @intCast(tmp_2)) else break :blk_1 data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp_2)) +% -1));
                                }).* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                            }).*;
                        }
                    }
                }
            }
        }
        {
            i = 0;
            while (i < n) : (i += 1) {
                var temp: float_conv = undefined;
                _ = &temp;
                var v: c_int = blk: {
                    temp.f = buffer[@as(u32, @intCast(i))] + ((1.5 * @as(f32, @floatFromInt(@as(c_int, 1) << @intCast(@as(c_int, 23) - @as(c_int, 15))))) + (0.5 / @as(f32, @floatFromInt(@as(c_int, 1) << @intCast(15)))));
                    break :blk temp.i - (((@as(c_int, 150) - @as(c_int, 15)) << @intCast(23)) + (@as(c_int, 1) << @intCast(22)));
                };
                _ = &v;
                if (@as(u32, @bitCast(v + @as(c_int, 32768))) > @as(u32, @bitCast(@as(c_int, 65535)))) {
                    v = if (v < @as(c_int, 0)) -@as(c_int, 32768) else @as(c_int, 32767);
                }
                (blk: {
                    const tmp = o + i;
                    if (tmp >= 0) break :blk output + @as(usize, @intCast(tmp)) else break :blk output - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).* = @as(c_short, @bitCast(@as(c_short, @truncate(v))));
            }
        }
    }
}
pub fn compute_stereo_samples(output: [*c]c_short, num_c: c_int, data: [*c][*c]f32, d_offset: c_int, len: c_int) void {
    var buffer: [32]f32 = undefined;
    var i: c_int = undefined;
    var j: c_int = undefined;
    var o: c_int = 0;
    var n: c_int = @as(c_int, 32) >> @intCast(1);
    while (o < len) : (o += 32 >> 1) {
        const o2: c_int = o << @intCast(1);
        @memset(&buffer, 0);
        if ((o + n) > len) {
            n = len - o;
        }

        j = 0;
        while (j < num_c) : (j += 1) {
            var m: c_int = @as(c_int, @bitCast(@as(c_int, channel_position[@as(u32, @intCast(num_c))][@as(u32, @intCast(j))]))) & (@as(c_int, 2) | @as(c_int, 4));
            _ = &m;
            if (m == (@as(c_int, 2) | @as(c_int, 4))) {
                {
                    i = 0;
                    while (i < n) : (i += 1) {
                        buffer[@as(u32, @intCast((i * @as(c_int, 2)) + @as(c_int, 0)))] += (blk: {
                            const tmp = (d_offset + o) + i;
                            if (tmp >= 0) break :blk (blk_1: {
                                const tmp_2 = j;
                                if (tmp_2 >= 0) break :blk_1 data + @as(usize, @intCast(tmp_2)) else break :blk_1 data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp_2)) +% -1));
                            }).* + @as(usize, @intCast(tmp)) else break :blk (blk_1: {
                                const tmp_2 = j;
                                if (tmp_2 >= 0) break :blk_1 data + @as(usize, @intCast(tmp_2)) else break :blk_1 data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp_2)) +% -1));
                            }).* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).*;
                        buffer[@as(u32, @intCast((i * @as(c_int, 2)) + @as(c_int, 1)))] += (blk: {
                            const tmp = (d_offset + o) + i;
                            if (tmp >= 0) break :blk (blk_1: {
                                const tmp_2 = j;
                                if (tmp_2 >= 0) break :blk_1 data + @as(usize, @intCast(tmp_2)) else break :blk_1 data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp_2)) +% -1));
                            }).* + @as(usize, @intCast(tmp)) else break :blk (blk_1: {
                                const tmp_2 = j;
                                if (tmp_2 >= 0) break :blk_1 data + @as(usize, @intCast(tmp_2)) else break :blk_1 data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp_2)) +% -1));
                            }).* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).*;
                    }
                }
            } else if (m == @as(c_int, 2)) {
                {
                    i = 0;
                    while (i < n) : (i += 1) {
                        buffer[@as(u32, @intCast((i * @as(c_int, 2)) + @as(c_int, 0)))] += (blk: {
                            const tmp = (d_offset + o) + i;
                            if (tmp >= 0) break :blk (blk_1: {
                                const tmp_2 = j;
                                if (tmp_2 >= 0) break :blk_1 data + @as(usize, @intCast(tmp_2)) else break :blk_1 data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp_2)) +% -1));
                            }).* + @as(usize, @intCast(tmp)) else break :blk (blk_1: {
                                const tmp_2 = j;
                                if (tmp_2 >= 0) break :blk_1 data + @as(usize, @intCast(tmp_2)) else break :blk_1 data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp_2)) +% -1));
                            }).* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).*;
                    }
                }
            } else if (m == @as(c_int, 4)) {
                {
                    i = 0;
                    while (i < n) : (i += 1) {
                        buffer[@as(u32, @intCast((i * @as(c_int, 2)) + @as(c_int, 1)))] += (blk: {
                            const tmp = (d_offset + o) + i;
                            if (tmp >= 0) break :blk (blk_1: {
                                const tmp_2 = j;
                                if (tmp_2 >= 0) break :blk_1 data + @as(usize, @intCast(tmp_2)) else break :blk_1 data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp_2)) +% -1));
                            }).* + @as(usize, @intCast(tmp)) else break :blk (blk_1: {
                                const tmp_2 = j;
                                if (tmp_2 >= 0) break :blk_1 data + @as(usize, @intCast(tmp_2)) else break :blk_1 data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp_2)) +% -1));
                            }).* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).*;
                    }
                }
            }
        }
        i = 0;
        while (i < (n << @intCast(1))) : (i += 1) {
            var temp: float_conv = undefined;
            _ = &temp;
            var v: c_int = blk: {
                temp.f = buffer[@as(u32, @intCast(i))] + ((1.5 * @as(f32, @floatFromInt(@as(c_int, 1) << @intCast(@as(c_int, 23) - @as(c_int, 15))))) + (0.5 / @as(f32, @floatFromInt(@as(c_int, 1) << @intCast(15)))));
                break :blk temp.i - (((@as(c_int, 150) - @as(c_int, 15)) << @intCast(23)) + (@as(c_int, 1) << @intCast(22)));
            };
            _ = &v;
            if (@as(u32, @bitCast(v + @as(c_int, 32768))) > @as(u32, @bitCast(@as(c_int, 65535)))) {
                v = if (v < @as(c_int, 0)) -@as(c_int, 32768) else @as(c_int, 32767);
            }
            (blk: {
                const tmp = o2 + i;
                if (tmp >= 0) break :blk output + @as(usize, @intCast(tmp)) else break :blk output - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
            }).* = @as(c_short, @bitCast(@as(c_short, @truncate(v))));
        }
    }
}
pub fn convert_samples_short(buf_c: c_int, buffer: [*c][*c]c_short, b_offset: c_int, data_c: c_int, data: [*c][*c]f32, d_offset: c_int, samples: usize) void {
    var i: usize = undefined;
    if (((buf_c != data_c) and (buf_c <= 2)) and (data_c <= 6)) {
        const channel_selector = struct {
            var static: [3][2]c_int = [3][2]c_int{
                [1]c_int{
                    0,
                } ++ [1]c_int{0} ** 1,
                [1]c_int{
                    1,
                } ++ [1]c_int{0} ** 1,
                [2]c_int{
                    2,
                    4,
                },
            };
        };
        {
            i = 0;
            while (i < buf_c) : (i += 1) {
                compute_samples(channel_selector.static[@as(u32, @intCast(buf_c))][@as(u32, @intCast(i))], (blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk buffer + @as(usize, @intCast(tmp)) else break :blk buffer - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).* + @as(usize, @bitCast(@as(isize, @intCast(b_offset)))), data_c, data, d_offset, @intCast(samples));
            }
        }
    } else {
        var limit: c_int = if (buf_c < data_c) buf_c else data_c;
        _ = &limit;
        {
            i = 0;
            while (i < limit) : (i += 1) {
                copy_samples((blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk buffer + @as(usize, @intCast(tmp)) else break :blk buffer - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).* + @as(usize, @bitCast(@as(isize, @intCast(b_offset)))), (blk: {
                    const tmp = i;
                    if (tmp >= 0) break :blk data + @as(usize, @intCast(tmp)) else break :blk data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                }).* + @as(usize, @bitCast(@as(isize, @intCast(d_offset)))), @intCast(samples));
            }
        }
        while (i < buf_c) : (i += 1) {
            @memset(
                @as([*]u8, @ptrCast(buffer[i]))[0 .. @sizeOf(c_short) * samples],
                0,
            );
        }
    }
}
pub fn convert_channels_short_interleaved(arg_buf_c: c_int, arg_buffer: [*c]c_short, arg_data_c: c_int, arg_data: [*c][*c]f32, arg_d_offset: c_int, arg_len: c_int) callconv(.c) void {
    var buf_c = arg_buf_c;
    _ = &buf_c;
    var buffer = arg_buffer;
    _ = &buffer;
    var data_c = arg_data_c;
    _ = &data_c;
    var data = arg_data;
    _ = &data;
    var d_offset = arg_d_offset;
    _ = &d_offset;
    var len = arg_len;
    _ = &len;
    var i: c_int = undefined;
    _ = &i;
    if (((buf_c != data_c) and (buf_c <= 2)) and (data_c <= 6)) {
        i = 0;
        while (i < buf_c) : (i += 1) {
            compute_stereo_samples(buffer, data_c, data, d_offset, len);
        }
    } else {
        var limit: c_int = if (buf_c < data_c) buf_c else data_c;
        _ = &limit;
        var j: c_int = undefined;
        _ = &j;
        {
            j = 0;
            while (j < len) : (j += 1) {
                {
                    i = 0;
                    while (i < limit) : (i += 1) {
                        var temp: float_conv = undefined;
                        _ = &temp;
                        var f: f32 = (blk: {
                            const tmp = d_offset + j;
                            if (tmp >= 0) break :blk (blk_1: {
                                const tmp_2 = i;
                                if (tmp_2 >= 0) break :blk_1 data + @as(usize, @intCast(tmp_2)) else break :blk_1 data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp_2)) +% -1));
                            }).* + @as(usize, @intCast(tmp)) else break :blk (blk_1: {
                                const tmp_2 = i;
                                if (tmp_2 >= 0) break :blk_1 data + @as(usize, @intCast(tmp_2)) else break :blk_1 data - ~@as(usize, @bitCast(@as(isize, @intCast(tmp_2)) +% -1));
                            }).* - ~@as(usize, @bitCast(@as(isize, @intCast(tmp)) +% -1));
                        }).*;
                        _ = &f;
                        var v: c_int = blk: {
                            temp.f = f + ((1.5 * @as(f32, @floatFromInt(@as(c_int, 1) << @intCast(@as(c_int, 23) - @as(c_int, 15))))) + (0.5 / @as(f32, @floatFromInt(@as(c_int, 1) << @intCast(15)))));
                            break :blk temp.i - (((@as(c_int, 150) - @as(c_int, 15)) << @intCast(23)) + (@as(c_int, 1) << @intCast(22)));
                        };
                        _ = &v;
                        if (@as(u32, @bitCast(v + @as(c_int, 32768))) > @as(u32, @bitCast(@as(c_int, 65535)))) {
                            v = if (v < @as(c_int, 0)) -@as(c_int, 32768) else @as(c_int, 32767);
                        }
                        (blk: {
                            const ref = &buffer;
                            const tmp = ref.*;
                            ref.* += 1;
                            break :blk tmp;
                        }).* = @as(c_short, @bitCast(@as(c_short, @truncate(v))));
                    }
                }
                while (i < buf_c) : (i += 1) {
                    (blk: {
                        const ref = &buffer;
                        const tmp = ref.*;
                        ref.* += 1;
                        break :blk tmp;
                    }).* = 0;
                }
            }
        }
    }
}
pub const STB_VORBIS_MAX_CHANNELS = @as(c_int, 16);
pub const STB_VORBIS_PUSHDATA_CRC_COUNT = @as(c_int, 4);
pub const STB_VORBIS_FAST_HUFFMAN_LENGTH = @as(c_int, 10);
pub const STB_VORBIS_FAST_HUFFMAN_SHORT = "";
pub const STB_VORBIS_ENDIAN = @as(c_int, 0);
pub const DIVTAB_NUMER = @as(c_int, 32);
pub const DIVTAB_DENOM = @as(c_int, 64);
pub inline fn CHECK(f: anytype) void {
    _ = &f;
}
pub const MAX_BLOCKSIZE_LOG = @as(c_int, 13);
pub const MAX_BLOCKSIZE = @as(c_int, 1) << MAX_BLOCKSIZE_LOG;
pub const TRUE = @as(c_int, 1);
pub const FALSE = @as(c_int, 0);
pub inline fn STBV_NOTUSED(v: anytype) anyopaque {
    _ = &v;
    return std.zig.c_translation.cast(anyopaque, std.zig.c_translation.sizeof(v));
}
pub const FAST_HUFFMAN_TABLE_SIZE = @as(c_int, 1) << STB_VORBIS_FAST_HUFFMAN_LENGTH;
pub const FAST_HUFFMAN_TABLE_MASK = FAST_HUFFMAN_TABLE_SIZE - @as(c_int, 1);
pub inline fn IS_PUSH_MODE(f: anytype) @TypeOf(f.*.push_mode) {
    _ = &f;
    return f.*.push_mode;
}
pub inline fn array_size_required(count: anytype, size: anytype) usize {
    return @as(usize, @intCast(count)) * (@sizeOf(?*anyopaque) + @as(usize, @intCast(size)));
}
pub inline fn temp_alloc(f: anytype, size: anytype) ?*anyopaque {
    return setup_temp_malloc(f, @intCast(size));
}
pub inline fn temp_free(f: anytype, p: anytype) void {
    _ = &f;
    _ = &p;
}
pub inline fn temp_alloc_save(f: anytype) @TypeOf(f.*.temp_offset) {
    _ = &f;
    return f.*.temp_offset;
}
pub inline fn temp_alloc_restore(f: anytype, p: anytype) void {
    f.*.temp_offset = p;
}
pub inline fn temp_block_array(f: anytype, count: anytype, size: anytype) @TypeOf(make_block_array(temp_alloc(f, array_size_required(count, size)), count, size)) {
    _ = &f;
    _ = &count;
    _ = &size;
    return make_block_array(temp_alloc(f, array_size_required(count, size)), count, size);
}
const CRC32_POLY = std.zig.c_translation.promoteIntLiteral(c_int, 0x04c11db7, .hex);
const NO_CODE = @as(c_int, 255);
const STBV_CDECL = "";
const PAGEFLAG_continued_packet = 1;
const PAGEFLAG_first_page = 2;
const PAGEFLAG_last_page = 4;
const EOP: i32 = -1;
const INVALID_BITS = -1;
inline fn CODEBOOK_ELEMENT(c: anytype, off: anytype) @TypeOf(c.*.multiplicands[@as(usize, @intCast(off))]) {
    _ = &c;
    _ = &off;
    return c.*.multiplicands[@as(usize, @intCast(off))];
}
inline fn CODEBOOK_ELEMENT_FAST(c: anytype, off: anytype) @TypeOf(c.*.multiplicands[@as(usize, @intCast(off))]) {
    _ = &c;
    _ = &off;
    return c.*.multiplicands[@as(usize, @intCast(off))];
}
inline fn CODEBOOK_ELEMENT_BASE(c: anytype) @TypeOf(@as(c_int, 0)) {
    _ = &c;
    return @as(c_int, 0);
}
const LIBVORBIS_MDCT = 0;
const SAMPLE_unknown = 0xffffffff;
const PLAYBACK_MONO = 1;
const PLAYBACK_LEFT = 2;
const PLAYBACK_RIGHT = 4;
const L = PLAYBACK_LEFT | PLAYBACK_MONO;
const C = (PLAYBACK_LEFT | PLAYBACK_RIGHT) | PLAYBACK_MONO;
const R = PLAYBACK_RIGHT | PLAYBACK_MONO;
