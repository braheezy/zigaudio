const std = @import("std");

// Comptime function to generate IMDCT window data
fn generateImdctWinData() [4][36]f32 {
    var data: [4][36]f32 = undefined;

    // Window 0: sin(π/36 * (i + 0.5)) for all 36 elements
    for (0..36) |i| {
        data[0][i] = @sin(std.math.pi / 36.0 * (@as(f32, @floatFromInt(i)) + 0.5));
    }

    // Window 1: Complex pattern
    for (0..18) |i| {
        data[1][i] = @sin(std.math.pi / 36.0 * (@as(f32, @floatFromInt(i)) + 0.5));
    }
    for (18..24) |i| {
        data[1][i] = 1.0;
    }
    for (24..30) |i| {
        data[1][i] = @sin(std.math.pi / 12.0 * (@as(f32, @floatFromInt(i)) + 0.5 - 18.0));
    }
    for (30..36) |i| {
        data[1][i] = 0.0;
    }

    // Window 2: sin(π/12 * (i + 0.5)) for first 12, then zeros
    for (0..12) |i| {
        data[2][i] = @sin(std.math.pi / 12.0 * (@as(f32, @floatFromInt(i)) + 0.5));
    }
    for (12..36) |i| {
        data[2][i] = 0.0;
    }

    // Window 3: Complex pattern
    for (0..6) |i| {
        data[3][i] = 0.0;
    }
    for (6..12) |i| {
        data[3][i] = @sin(std.math.pi / 12.0 * (@as(f32, @floatFromInt(i)) + 0.5 - 6.0));
    }
    for (12..18) |i| {
        data[3][i] = 1.0;
    }
    for (18..36) |i| {
        data[3][i] = @sin(std.math.pi / 36.0 * (@as(f32, @floatFromInt(i)) + 0.5));
    }

    return data;
}

// Comptime function to generate cosine lookup tables
fn generateCosN12() [6][12]f32 {
    var data: [6][12]f32 = undefined;
    const N: f32 = 12.0;

    for (0..6) |i| {
        for (0..12) |j| {
            const i_f = @as(f32, @floatFromInt(i));
            const j_f = @as(f32, @floatFromInt(j));
            data[i][j] = @cos(std.math.pi / (2.0 * N) * (2.0 * j_f + 1.0 + N / 2.0) * (2.0 * i_f + 1.0));
        }
    }

    return data;
}

fn generateCosN36() [18][36]f32 {
    var data: [18][36]f32 = undefined;
    const N: f32 = 36.0;

    for (0..18) |i| {
        for (0..36) |j| {
            const i_f = @as(f32, @floatFromInt(i));
            const j_f = @as(f32, @floatFromInt(j));
            data[i][j] = @cos(std.math.pi / (2.0 * N) * (2.0 * j_f + 1.0 + N / 2.0) * (2.0 * i_f + 1.0));
        }
    }

    return data;
}

// Comptime-generated lookup tables
pub const win_data = generateImdctWinData();
pub const cos_n12 = generateCosN12();
pub const cos_n36 = generateCosN36();

const testing = std.testing;

test "imdct lookup tables generated correctly" {
    // Test that win_data has correct dimensions
    try testing.expectEqual(@as(usize, 4), win_data.len);
    try testing.expectEqual(@as(usize, 36), win_data[0].len);

    // Test that cos_n12 has correct dimensions
    try testing.expectEqual(@as(usize, 6), cos_n12.len);
    try testing.expectEqual(@as(usize, 12), cos_n12[0].len);

    // Test that cos_n36 has correct dimensions
    try testing.expectEqual(@as(usize, 18), cos_n36.len);
    try testing.expectEqual(@as(usize, 36), cos_n36[0].len);

    // Test some known values from win_data
    // Window 0: first element should be sin(π/36 * 0.5)
    const expected_first = @sin(std.math.pi / 36.0 * 0.5);
    try testing.expectApproxEqAbs(expected_first, win_data[0][0], 1e-6);

    // Window 1: elements 18-23 should be 1.0
    for (18..24) |i| {
        try testing.expectEqual(@as(f32, 1.0), win_data[1][i]);
    }

    // Window 2: elements 12-35 should be 0.0
    for (12..36) |i| {
        try testing.expectEqual(@as(f32, 0.0), win_data[2][i]);
    }

    // Window 3: elements 0-5 should be 0.0
    for (0..6) |i| {
        try testing.expectEqual(@as(f32, 0.0), win_data[3][i]);
    }

    // Test that cosine tables are properly generated
    // cos_n12[0][0] should be cos(π/24 * (0 + 1 + 6) * (0 + 1)) = cos(π/24 * 7)
    const expected_cos = @cos(std.math.pi / 24.0 * 7.0);
    try testing.expectApproxEqAbs(expected_cos, cos_n12[0][0], 1e-6);

    // Test that all cosine values are finite (no NaN or Inf)
    for (0..6) |i| {
        for (0..12) |j| {
            try testing.expect(std.math.isFinite(cos_n12[i][j]));
        }
    }

    for (0..18) |i| {
        for (0..36) |j| {
            try testing.expect(std.math.isFinite(cos_n36[i][j]));
        }
    }
}
