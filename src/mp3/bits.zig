const std = @import("std");

pub const Bits = struct {
    vec: std.array_list.Managed(u8),
    bit_pos: usize = 0,
    byte_pos: usize = 0,

    pub fn init(allocator: std.mem.Allocator, vec: []const u8) Bits {
        var list = std.array_list.Managed(u8).init(allocator);
        list.appendSlice(vec) catch unreachable;
        return .{ .vec = list };
    }

    pub fn bit(self: *Bits) u8 {
        if (self.vec.items.len <= self.byte_pos) {
            return 0;
        }

        var tmp = @as(usize, self.vec.items[self.byte_pos]) >> @as(u6, @intCast(7 - self.bit_pos));
        tmp &= 0x01;
        self.byte_pos += (self.bit_pos + 1) >> 3;
        self.bit_pos = (self.bit_pos + 1) & 0x07;
        return @intCast(tmp);
    }

    pub fn bits(self: *Bits, num: usize) usize {
        if (num == 0) {
            return 0;
        }
        if (self.vec.items.len <= self.byte_pos) {
            return 0;
        }

        var buf: [4]u8 = .{ 0, 0, 0, 0 };
        const slice_len = @min(4, self.vec.items.len - self.byte_pos);
        @memcpy(buf[0..slice_len], self.vec.items[self.byte_pos .. self.byte_pos + slice_len]);

        // Convert to big-endian u32 (like the Go version)
        var tmp: u32 = (@as(u32, buf[0]) << 24) |
            (@as(u32, buf[1]) << 16) |
            (@as(u32, buf[2]) << 8) |
            @as(u32, buf[3]);

        tmp <<= @as(u5, @intCast(self.bit_pos));
        tmp >>= @as(u5, @intCast(32 - num));
        self.byte_pos += (self.bit_pos + num) >> 3;
        self.bit_pos = (self.bit_pos + num) & 0x07;
        return @intCast(tmp);
    }

    pub fn bitPosition(self: *Bits) usize {
        return (self.byte_pos << 3) + self.bit_pos;
    }

    pub fn setPosition(self: *Bits, pos: usize) void {
        self.byte_pos = pos >> 3;
        self.bit_pos = pos & 0x07;
    }

    pub fn lenInBytes(self: *Bits) usize {
        return self.vec.items.len;
    }

    pub fn tail(self: *Bits, offset: usize) []u8 {
        if (offset >= self.vec.items.len) {
            return &[_]u8{};
        }
        return self.vec.items[self.vec.items.len - offset ..];
    }
};

const testing = std.testing;

test "bits reading" {
    const allocator = testing.allocator;

    // Test data from Go test:
    // b1 := byte(85)  // 01010101
    // b2 := byte(170) // 10101010
    // b3 := byte(204) // 11001100
    // b4 := byte(51)  // 00110011
    var test_data = [_]u8{ 85, 170, 204, 51 };
    var bits = Bits.init(allocator, &test_data);
    defer bits.vec.deinit();

    // Test single bit reads
    try testing.expectEqual(@as(u8, 0), bits.bit()); // First bit: 0
    try testing.expectEqual(@as(u8, 1), bits.bit()); // Second bit: 1
    try testing.expectEqual(@as(u8, 0), bits.bit()); // Third bit: 0
    try testing.expectEqual(@as(u8, 1), bits.bit()); // Fourth bit: 1

    // Test 8-bit read: should get 01011010 (90 in decimal)
    // From the remaining bits: 010110101010101100110011
    // First 8 bits: 01011010 = 90
    try testing.expectEqual(@as(usize, 90), bits.bits(8));

    // Test 12-bit read: should get 101011001100 (2764 in decimal)
    // From remaining bits: 1010101100110011
    // First 12 bits: 101011001100 = 2764
    try testing.expectEqual(@as(usize, 2764), bits.bits(12));
}
