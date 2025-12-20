const std = @import("std");

/// BitWriter provides bit-level writing capabilities, similar to BitReader but for encoding.
/// It maintains a bit cache and writes bytes to a buffer. Matches the Go bitstream implementation.
pub const BitWriter = struct {
    allocator: std.mem.Allocator,
    // Buffer for accumulating bytes
    data: std.ArrayList(u8),
    // Current write position in buffer
    data_position: usize = 0,
    // Bit cache for accumulating bits before writing bytes
    cache: u32 = 0,
    // Bits remaining in cache (0..32, 32 means empty)
    cache_bits: u6 = 32,

    const Self = @This();
    const BUFFER_SIZE: usize = 4096;

    /// Initialize a BitWriter with initial buffer capacity
    pub fn init(allocator: std.mem.Allocator) Self {
        var data = std.ArrayList(u8).empty;
        data.ensureTotalCapacity(allocator, BUFFER_SIZE) catch {};
        return Self{
            .allocator = allocator,
            .data = data,
        };
    }

    /// Write N bits from val into the bitstream (MSB-first), matching MP3 bitstream semantics.
    /// `n` must be 0..32.
    pub fn putBits(self: *Self, val: u32, n: u6) !void {
        std.debug.assert(n <= 32);

        if (self.cache_bits > n) {
            self.cache_bits -= n;
            if (self.cache_bits < 32) {
                self.cache |= val << @as(u5, @intCast(self.cache_bits));
            }
            return;
        }

        const remaining_in_cache: u6 = self.cache_bits;
        const bits_after: u6 = n - remaining_in_cache;

        if (remaining_in_cache > 0) {
            self.cache |= val >> @as(u5, @intCast(bits_after));
        }

        // Ensure we have space for 4 more bytes
        if (self.data_position + 4 > self.data.items.len) {
            const target_len = self.data_position + 4;
            try self.data.ensureTotalCapacity(self.allocator, target_len);
            self.data.items.len = target_len;
        }

        // Flush cache as 4 bytes (big-endian)
        self.data.items[self.data_position] = @truncate(self.cache >> 24);
        self.data.items[self.data_position + 1] = @truncate(self.cache >> 16);
        self.data.items[self.data_position + 2] = @truncate(self.cache >> 8);
        self.data.items[self.data_position + 3] = @truncate(self.cache);
        self.data_position += 4;

        // Refill cache with leftover bits
        self.cache = 0;
        self.cache_bits = 32 - bits_after;
        if (bits_after > 0) {
            self.cache |= val << @as(u5, @intCast(self.cache_bits));
        }
    }

    /// Get the total number of bits written
    pub fn getBitsCount(self: *const Self) usize {
        return self.data_position * 8 + (@as(usize, 32 - self.cache_bits));
    }

    /// Get the current data buffer (up to data_position)
    pub fn getData(self: *const Self) []const u8 {
        return self.data.items[0..self.data_position];
    }

    /// Flush any remaining cached bits (to the next byte boundary) into the buffer
    /// and return the full written byte slice.
    ///
    /// MP3 framing expects byte-aligned output; call this after you've written/padded
    /// all bits for a frame.
    pub fn finish(self: *Self) ![]const u8 {
        if (self.cache_bits == 32) return self.getData();

        const bits_used: u6 = 32 - self.cache_bits;
        const bytes_needed: usize = (@as(usize, bits_used) + 7) / 8;
        if (bytes_needed == 0) return self.getData();

        const target_len = self.data_position + bytes_needed;
        if (target_len > self.data.items.len) {
            try self.data.ensureTotalCapacity(self.allocator, target_len);
            self.data.items.len = target_len;
        } else if (self.data.items.len < target_len) {
            self.data.items.len = target_len;
        }

        var i: usize = 0;
        while (i < bytes_needed) : (i += 1) {
            const shift: u5 = @intCast(24 - @as(u32, @intCast(i)) * 8);
            self.data.items[self.data_position + i] = @truncate(self.cache >> shift);
        }

        self.data_position = target_len;
        self.cache = 0;
        self.cache_bits = 32;
        return self.getData();
    }

    /// Reset the writer state (clears buffer and cache, resets position)
    pub fn reset(self: *Self) void {
        self.data.clearRetainingCapacity();
        self.data_position = 0;
        self.cache = 0;
        self.cache_bits = 32;
    }

    /// Clean up resources
    pub fn deinit(self: *Self) void {
        self.data.deinit(self.allocator);
    }
};


const testing = std.testing;

test "BitWriter basic putBits" {
    var bw = BitWriter.init(testing.allocator);
    defer bw.deinit();

    // Write 11 bits: 0x7FF (all ones)
    try bw.putBits(0x7FF, 11);
    // Write 2 bits: 0x3
    try bw.putBits(0x3, 2);
    // Write 2 bits: 0x1
    try bw.putBits(0x1, 2);
    // Write 1 bit: 0x1
    try bw.putBits(0x1, 1);

    const data = try bw.finish();
    // Should have written at least 2 bytes: 0xFF, 0xF8 (16 bits total)
    try testing.expect(data.len >= 2);
    try testing.expectEqual(@as(usize, 16), bw.getBitsCount());
}

test "BitWriter cache overflow" {
    var bw = BitWriter.init(testing.allocator);
    defer bw.deinit();

    // Fill cache with 31 bits
    try bw.putBits(0x7FFFFFFF, 31);
    // Add 2 more bits - should trigger flush
    try bw.putBits(0x3, 2);

    const data = bw.getData();
    // Should have written at least 4 bytes
    try testing.expect(data.len >= 4);
    try testing.expectEqual(@as(usize, 33), bw.getBitsCount());
}

test "BitWriter multiple writes" {
    var bw = BitWriter.init(testing.allocator);
    defer bw.deinit();

    try bw.putBits(0xFF, 8);
    try bw.putBits(0xAA, 8);

    const data = try bw.finish();
    // Should have written at least 2 bytes
    try testing.expect(data.len >= 2);
    try testing.expectEqual(@as(usize, 16), bw.getBitsCount());
}
