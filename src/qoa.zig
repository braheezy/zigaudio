const std = @import("std");

const min_filesize = 16;
const max_channels = 8;
const slice_len = 20;
const slices_per_frame = 256;
const frame_len = slices_per_frame * slice_len;
const lms_len = 4;
const magic = 0x716f6166; // 'qoaf'

const quant_table = [17]i32{
    7, 7, 7, 5, 5, 3, 3, 1, // -8..-1
    0, // 0
    0, 2, 2, 4, 4, 6, 6, 6, // 1..8
};

const scalefactor_table = [16]i32{
    1,    7,    21,   45,   84,  138,
    211,  304,  421,  562,  731, 928,
    1157, 1419, 1715, 2048,
};

const reciprocal_table = [16]i32{
    65536, 9363, 3121, 1457, 781, 475,
    311,   216,  156,  117,  90,  71,
    57,    47,   39,   32,
};

const dequant_table = [16][8]i16{
    .{ 1, -1, 3, -3, 5, -5, 7, -7 },
    .{ 5, -5, 18, -18, 32, -32, 49, -49 },
    .{ 16, -16, 53, -53, 95, -95, 147, -147 },
    .{ 34, -34, 113, -113, 203, -203, 315, -315 },
    .{ 63, -63, 210, -210, 378, -378, 588, -588 },
    .{ 104, -104, 345, -345, 621, -621, 966, -966 },
    .{ 158, -158, 528, -528, 950, -950, 1477, -1477 },
    .{ 228, -228, 760, -760, 1368, -1368, 2128, -2128 },
    .{ 316, -316, 1053, -1053, 1895, -1895, 2947, -2947 },
    .{ 422, -422, 1405, -1405, 2529, -2529, 3934, -3934 },
    .{ 548, -548, 1828, -1828, 3290, -3290, 5117, -5117 },
    .{ 696, -696, 2320, -2320, 4176, -4176, 6496, -6496 },
    .{ 868, -868, 2893, -2893, 5207, -5207, 8099, -8099 },
    .{ 1064, -1064, 3548, -3548, 6386, -6386, 9933, -9933 },
    .{ 1286, -1286, 4288, -4288, 7718, -7718, 12005, -12005 },
    .{ 1536, -1536, 5120, -5120, 9216, -9216, 14336, -14336 },
};

pub const Lms = struct {
    history: [lms_len]i16,
    weights: [lms_len]i16,

    fn predict(self: *Lms) i32 {
        var prediction: i32 = 0;
        for (0..lms_len) |i| {
            prediction += @as(i32, @intCast(self.weights[i])) * @as(i32, @intCast(self.history[i]));
        }
        return prediction >> 13;
    }
    fn update(self: *Lms, sample: i16, residual: i16) void {
        const delta = residual >> 4;
        for (0..lms_len) |i| {
            self.weights[i] += if (self.history[i] < 0) -delta else delta;
        }
        for (0..lms_len - 1) |i| {
            self.history[i] = self.history[i + 1];
        }
        self.history[lms_len - 1] = sample;
    }
};

fn div(v: i32, scalefactor: i32) i32 {
    const reciprocal = reciprocal_table[scalefactor];
    const n = (v * reciprocal + (1 << 15)) >> 16;
    return n + ((v > 0) - (v < 0)) - ((n > 0) - (n < 0)); // round away from 0
}

fn clamp(v: i32, min: i32, max: i32) i32 {
    if (v < min) return min;
    if (v > max) return max;
    return v;
}
// This specialized clamp function for the signed 16 bit range improves decode
// performance quite a bit. The extra if() statement works nicely with the CPUs
// branch prediction as this branch is rarely taken.
fn clamp_s16(v: i32) i16 {
    if (v <= -32768) return -32768;
    if (v >= 32767) return 32767;
    return @truncate(v);
}

pub const Decoder = struct {
    channels: u32,
    sample_rate: u32,
    sample_count: u32,
    lms: [max_channels]Lms = undefined,

    fn decodeFrame(self: *Decoder, bytes: []const u8, target_size: usize, samples: []i16) !struct { frame_size: usize, frame_length: usize } {
        if (target_size < 8 * lms_len * 4 * self.channels) {
            return error.FrameTooSmall;
        }

        var p: usize = 0;
        var frame_size: usize = 0;
        // read and verify header
        const frame_header = std.mem.readInt(u64, bytes[0..8], .big);
        p += 8;
        const channels: u32 = @intCast((frame_header >> 56) & 0x000000FF);
        const sample_rate: u32 = @intCast((frame_header >> 32) & 0x00FFFFFF);
        const sample_count: u32 = @intCast((frame_header >> 16) & 0x0000FFFF);
        frame_size = @intCast(frame_header & 0x0000FFFF);

        const data_size = frame_size - 8 - (lms_len * 4 * self.channels);
        const num_slices = data_size / 8;
        const max_total_samples = num_slices * slices_per_frame;

        if (channels != self.channels or
            sample_rate != self.sample_rate or
            frame_size > target_size or
            (sample_count * channels) > max_total_samples)
        {
            return error.InvalidFrameHeader;
        }

        // Read the LMS state: 4 x 2 bytes history and 4 x 2 bytes weights per channel
        for (0..self.channels) |c| {
            const history_ptr = @as(*const [8]u8, @ptrCast(&bytes[p]));
            const weights_ptr = @as(*const [8]u8, @ptrCast(&bytes[p + 8]));
            var history = std.mem.readInt(u64, history_ptr, .big);
            var weights = std.mem.readInt(u64, weights_ptr, .big);
            p += 16;

            for (0..lms_len) |i| {
                self.lms[c].history[i] = @truncate(@as(i32, @intCast((history >> 48))));
                history <<= 16;
                self.lms[c].weights[i] = @truncate(@as(i32, @intCast((weights >> 48))));
                weights <<= 16;
            }
        }

        // Decode all slices for all channels in this frame
        var sample_index: usize = 0;
        while (sample_index < sample_count) : (sample_index += slice_len) {
            for (0..channels) |c| {
                const slice_ptr = @as(*const [8]u8, @ptrCast(&bytes[p]));
                var slice = std.mem.readInt(u64, slice_ptr, .big);
                p += 8;

                const scalefactor = (slice >> 60) & 0xF;
                slice <<= 4;
                const slice_start = (sample_index * channels) + c;
                const slice_end = @as(u32, @intCast(clamp(@intCast(sample_index + slice_len), 0, @intCast(sample_count)))) * channels + c;

                var si: usize = slice_start;
                while (si < slice_end) : (si += channels) {
                    const predicted = self.lms[c].predict();
                    const quantized: usize = @intCast((slice >> 61) & 0x7);
                    const dequantized = dequant_table[scalefactor][quantized];
                    const reconstructed = clamp_s16(predicted + dequantized);

                    samples[si] = reconstructed;
                    slice <<= 3;

                    self.lms[c].update(reconstructed, dequantized);
                }
            }
        }

        return .{ .frame_size = p, .frame_length = sample_count };
    }
};

pub fn decode(allocator: std.mem.Allocator, bytes: []const u8) !struct { samples: []i16, decoder: Decoder } {
    var decoder = try decodeHeader(bytes);
    const size = bytes.len;
    var p: usize = 8;

    const total_samples = decoder.sample_count * decoder.channels;
    var sample_data = try allocator.alloc(i16, total_samples);
    errdefer allocator.free(sample_data);

    var sample_index: usize = 0;
    var frame_length: usize = 0;
    var frame_size: usize = 0;

    // decode all frames
    while (true) {
        const sample_ptr = sample_data[sample_index * decoder.channels ..];
        const result = try decoder.decodeFrame(bytes[p..], size - p, sample_ptr);
        frame_size = result.frame_size;
        frame_length = result.frame_length;

        p += frame_size;
        sample_index += frame_length;

        if (!(frame_size > 0 and sample_index < decoder.sample_count)) {
            break;
        }
    }
    decoder.sample_count = @intCast(sample_index);
    return .{ .samples = sample_data, .decoder = decoder };
}

pub fn decodeHeader(bytes: []const u8) !Decoder {
    if (bytes.len < min_filesize) {
        return error.InvalidFileSize;
    }

    const header = std.mem.readInt(u64, bytes[0..8], .big);
    if ((header >> 32) != magic) {
        return error.InvalidMagicNumber;
    }

    const samples: u32 = @intCast(header & 0xffffffff);
    if (samples == 0) {
        return error.InvalidSamples;
    }

    const frame_header = std.mem.readInt(u64, bytes[8..16], .big);
    const channels: u32 = @intCast((frame_header >> 56) & 0x0000ff);
    const sample_rate: u32 = @intCast((frame_header >> 32) & 0xffffff);

    if (channels == 0 or samples == 0) {
        return error.InvalidHeader;
    }

    return .{
        .channels = channels,
        .sample_rate = sample_rate,
        .sample_count = samples,
    };
}
