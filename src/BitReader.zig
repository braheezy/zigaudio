const std = @import("std");

pub const BitReader = @This();
// Public interface we expose
reader: std.Io.Reader,
// bit-level state
bit_index: usize = 0,
// memory management
allocator: std.mem.Allocator,
// append-only buffer (APPEND mode) when present
append_list: ?std.ArrayList(u8) = null,
append_ended: bool = false,
// cached total size when known (file or fixed memory)
total_size: ?usize = null,
// internal file handle (for file mode)
file: ?std.Io.File = null,
// Physical file cursor after the bytes currently buffered in reader.
file_pos: usize = 0,
// storage owned by this reader when streaming from a file
owned_buffer: ?[]u8 = null,

pub fn init(allocator: std.mem.Allocator, buffer: []u8) BitReader {
    return BitReader{
        .reader = .{
            .vtable = &vtable,
            .buffer = buffer,
            .seek = 0,
            .end = buffer.len,
        },
        .allocator = allocator,
        .total_size = null,
    };
}

pub fn initFromFile(allocator: std.mem.Allocator, filename: []const u8) !BitReader {
    const file = try std.fs.cwd().openFile(filename, .{});
    errdefer file.close(std.Options.debug_io);

    const initial_capacity: usize = 64 * 1024;
    const buffer = try allocator.alloc(u8, initial_capacity);
    errdefer allocator.free(buffer);

    var bit_reader = BitReader.init(allocator, buffer);
    bit_reader.reader.seek = 0;
    bit_reader.reader.end = 0;
    bit_reader.file = file;
    bit_reader.file_pos = 0;
    bit_reader.owned_buffer = buffer;
    bit_reader.total_size = @intCast(try file.length(std.Options.debug_io));
    return bit_reader;
}

pub fn initFromMemory(allocator: std.mem.Allocator, data: []const u8) BitReader {
    return BitReader{
        .reader = std.Io.Reader.fixed(data),
        .allocator = allocator,
        .total_size = data.len,
    };
}

pub fn initAppend(allocator: std.mem.Allocator, initial_capacity: usize) !BitReader {
    const list = std.ArrayList(u8).initCapacity(allocator, initial_capacity) catch return error.OutOfMemory;
    return BitReader{
        .reader = .{ .vtable = &vtable, .buffer = list.items, .seek = 0, .end = 0 },
        .allocator = allocator,
        .append_list = list,
        .append_ended = false,
        .total_size = null,
    };
}

pub fn append(self: *BitReader, data: []const u8) !void {
    if (self.append_list) |*list| {
        self.append_ended = false;
        try list.appendSlice(self.allocator, data);
        // Refresh reader slice to current storage (pointer may have moved)
        self.reader.buffer = list.items;
        self.reader.end = list.items.len;
        return;
    }
    return error.InvalidState;
}

pub fn deinit(self: *BitReader) void {
    if (self.file) |file| {
        file.close(std.Options.debug_io);
    }
    if (self.owned_buffer) |buffer| {
        self.allocator.free(buffer);
        self.owned_buffer = null;
    }
    // Deinit append list if present
    if (self.append_list) |*list| list.deinit(self.allocator);
}

// Bit-level operations
pub fn has(self: *BitReader, bit_count: usize) !bool {
    const available_bytes = if (self.reader.end >= self.reader.seek) self.reader.end - self.reader.seek else return false;
    const total_bits = @as(usize, available_bytes) << 3;

    // Guard against underflow if bit_index exceeds available bits
    if (self.bit_index > total_bits) return false;
    const available_bits = total_bits - self.bit_index;

    if (available_bits >= bit_count) return true;

    if (self.file == null) {
        return false;
    }

    // Try to fill more data via std.Io.Reader; treat EndOfStream as "no more bytes"
    self.reader.fillMore() catch |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    };

    const new_available_bytes = self.reader.end - self.reader.seek;
    const new_total_bits = new_available_bytes << 3;
    if (self.bit_index > new_total_bits) return false;
    const new_available_bits = new_total_bits - self.bit_index;
    if (new_available_bits >= bit_count) return true;

    if (self.file != null and new_available_bytes == available_bytes) {
        return false;
    }

    return false;
}

pub fn readBits(self: *BitReader, bit_count: u5) !u32 {
    if (!try self.has(bit_count)) return error.EndOfStream;

    var value: u32 = 0;
    var remaining_bits = bit_count;

    while (remaining_bits > 0) {
        const current_byte: u8 = self.reader.buffer[self.reader.seek];

        const bit_offset: u4 = @intCast(self.bit_index & 7);
        const bits_in_byte: u4 = 8 - bit_offset;
        const bits_to_read_u4: u4 = @intCast(@min(bits_in_byte, remaining_bits));

        const mask_u16: u16 = if (bits_to_read_u4 == 8)
            0x00FF
        else
            (@as(u16, 0x00FF) >> (@as(u4, 8) - bits_to_read_u4));
        const mask: u8 = @intCast(mask_u16);
        const shift_amt_u3: u3 = @intCast(bits_in_byte - bits_to_read_u4);
        const part: u8 = (current_byte >> shift_amt_u3) & mask;

        value = (value << @as(u5, bits_to_read_u4)) | @as(u32, part);

        self.bit_index += @as(usize, bits_to_read_u4);
        remaining_bits -= @as(u5, bits_to_read_u4);

        // If we've consumed a full byte, advance
        if ((self.bit_index & 7) == 0) {
            self.reader.seek += 1;
            self.bit_index = 0;
        }
    }

    return value;
}

pub fn readBit(self: *BitReader) !bool {
    const v = try self.readBits(1);
    return v != 0;
}

pub fn alignToByte(self: *BitReader) void {
    if ((self.bit_index & 7) != 0) {
        self.reader.seek += 1;
        self.bit_index = 0;
    }
}

pub fn skip(self: *BitReader, bit_count: usize) void {
    if (self.has(bit_count) catch false) {
        const total_bits = self.bit_index + bit_count;
        self.reader.seek += total_bits >> 3;
        self.bit_index = total_bits & 7;
    }
}

pub fn tell(self: *BitReader) usize {
    if (self.file != null) {
        const pos = self.file_pos;
        const buffered = self.reader.end - self.reader.seek;
        return if (pos >= buffered) @intCast(pos - buffered) else self.reader.seek;
    }
    return self.reader.seek;
}

pub fn seekTo(self: *BitReader, pos: usize) void {
    self.bit_index = 0;
    if (self.file) |*file| {
        std.Options.debug_io.vtable.fileSeekTo(std.Options.debug_io.userdata, file.*, @intCast(pos)) catch {
            // leave position unchanged on error
            return;
        };
        self.file_pos = pos;
        self.reader.seek = 0;
        self.reader.end = 0;
        if (self.owned_buffer) |buffer| {
            const to_fill = @min(buffer.len, self.total_size orelse buffer.len);
            const filled = file.readStreaming(std.Options.debug_io, &.{buffer[0..to_fill]}) catch 0;
            self.file_pos += filled;
            self.reader.buffer = buffer;
            self.reader.end = filled;
        }
        self.bit_index = 0;
        return;
    }

    self.reader.seek = pos;
    self.bit_index = 0;
    if (self.append_list != null) {
        self.append_ended = false;
    }
}

pub fn readFile(self: *BitReader, buffer: []u8) !usize {
    const file = self.file orelse return error.InvalidState;
    const amt = try file.readStreaming(std.Options.debug_io, &.{buffer});
    self.file_pos += amt;
    return amt;
}

pub fn seekFileTo(self: *BitReader, pos: usize) !void {
    const file = self.file orelse return error.InvalidState;
    try std.Options.debug_io.vtable.fileSeekTo(std.Options.debug_io.userdata, file, @intCast(pos));
    self.file_pos = pos;
    self.reader.seek = 0;
    self.reader.end = 0;
    self.bit_index = 0;
}

pub fn seekFileBy(self: *BitReader, offset: usize) !void {
    const file = self.file orelse return error.InvalidState;
    try std.Options.debug_io.vtable.fileSeekBy(std.Options.debug_io.userdata, file, @intCast(offset));
    self.file_pos += offset;
    self.reader.seek = 0;
    self.reader.end = 0;
    self.bit_index = 0;
}

pub fn signalEnd(self: *BitReader) void {
    if (self.append_list != null) {
        self.append_ended = true;
    }
}

pub fn hasEnded(self: *BitReader) bool {
    const has_more = self.has(1) catch false;
    if (self.append_list != null) {
        return self.append_ended and !has_more;
    }
    return !has_more;
}

pub fn skipBytes(self: *BitReader, value: u8) !usize {
    self.alignToByte();
    var skipped: usize = 0;
    while (try self.has(8) and self.reader.buffer[self.reader.seek] == value) {
        self.reader.seek += 1;
        skipped += 1;
    }
    return skipped;
}

pub fn peekBits(self: *BitReader, bit_count: u5) !u32 {
    if (!try self.has(bit_count)) return error.EndOfStream;
    const saved_seek = self.reader.seek;
    const saved_bit_index = self.bit_index;
    const v = try self.readBits(bit_count);
    self.reader.seek = saved_seek;
    self.bit_index = saved_bit_index;
    return v;
}

pub fn peekNonZero(self: *BitReader, bit_count: u5) !bool {
    if (!try self.has(bit_count)) return false;
    const saved_seek = self.reader.seek;
    const saved_bit_index = self.bit_index;
    const v = try self.readBits(bit_count);
    self.reader.seek = saved_seek;
    self.bit_index = saved_bit_index;
    return v != 0;
}

pub fn nextStartCode(self: *BitReader) ?u8 {
    self.alignToByte();
    while (self.has(5 << 3) catch false) {
        const idx = self.reader.seek;
        const b = self.reader.buffer;
        if (b[idx] == 0x00 and b[idx + 1] == 0x00 and b[idx + 2] == 0x01) {
            const code = b[idx + 3];
            self.reader.seek = idx + 4;
            self.bit_index = 0;
            return code;
        }
        // advance by one byte
        self.reader.seek += 1;
    }
    return null;
}

pub fn findStartCode(self: *BitReader, code: u8) ?u8 {
    while (true) {
        const current = self.nextStartCode();
        if (current == null or current.? == code) return current;
        if (self.file != null and self.reader.seek == self.reader.end) {
            return null;
        }
    }
    return null;
}

pub fn hasStartCode(self: *BitReader, code: u8) bool {
    const saved_seek = self.reader.seek;
    const saved_bit_index = self.bit_index;
    const current = self.findStartCode(code);
    self.reader.seek = saved_seek;
    self.bit_index = saved_bit_index;
    return current != null and current.? == code;
}

pub fn discardReadBytes(self: *BitReader) void {
    if ((self.bit_index & 7) != 0) {
        self.reader.seek += 1;
        self.bit_index = 0;
    }

    if (self.reader.seek == 0) return;

    if (self.file != null) {
        self.reader.seek = 0;
        self.reader.end = 0;
        return;
    }

    if (self.append_list) |*list| {
        const consumed = self.reader.seek;
        if (consumed >= list.items.len) {
            list.shrinkRetainingCapacity(0);
        } else {
            const remaining_len = list.items.len - consumed;
            const src = list.items[consumed .. consumed + remaining_len];
            std.mem.copyForwards(u8, list.items[0..remaining_len], src);
            list.shrinkRetainingCapacity(remaining_len);
        }
        self.reader.buffer = list.items;
        self.reader.seek = 0;
        self.reader.end = list.items.len;
        self.bit_index = 0;
        return;
    }

    const consumed_bytes = self.reader.seek;
    const buffer = self.reader.buffer;
    if (consumed_bytes >= buffer.len) {
        self.reader.buffer = buffer[buffer.len..buffer.len];
        self.reader.seek = 0;
        self.reader.end = 0;
    } else {
        self.reader.buffer = buffer[consumed_bytes..];
        self.reader.seek = 0;
        self.reader.end = buffer.len - consumed_bytes;
    }
    self.bit_index = 0;
}

pub fn totalSize(self: *BitReader) ?usize {
    return self.total_size;
}

pub fn clone(self: *const BitReader, allocator: std.mem.Allocator) !BitReader {
    var cloned = self.*;
    cloned.allocator = allocator;
    cloned.append_list = null;
    cloned.append_ended = self.append_ended;
    cloned.reader.vtable = &vtable;
    cloned.owned_buffer = null;

    if (self.owned_buffer) |buffer| {
        const copy = try allocator.alloc(u8, buffer.len);
        @memcpy(copy, buffer);
        cloned.reader.buffer = copy;
        cloned.reader.seek = self.reader.seek;
        cloned.reader.end = self.reader.end;
        cloned.owned_buffer = copy;
    } else if (self.file == null) {
        const slice = self.reader.buffer[self.reader.seek..self.reader.end];
        if (slice.len > 0) {
            const copy = try allocator.alloc(u8, slice.len);
            @memcpy(copy, slice);
            cloned.reader.buffer = copy;
            cloned.reader.seek = 0;
            cloned.reader.end = slice.len;
            cloned.owned_buffer = copy;
        } else {
            cloned.reader.buffer = &[0]u8{};
            cloned.reader.seek = 0;
            cloned.reader.end = 0;
        }
    }

    cloned.file = null;
    return cloned;
}

pub fn deinitClone(self: *BitReader) void {
    if (self.owned_buffer) |buffer| {
        self.allocator.free(buffer);
        self.owned_buffer = null;
    }
    if (self.append_list) |*list| {
        list.deinit(self.allocator);
        self.append_list = null;
    }
}

// std.Io.Reader VTable implementation
const vtable = std.Io.Reader.VTable{
    .stream = stream,
    .discard = discard,
    .readVec = readVec,
    .rebase = rebase,
};

fn stream(r: *std.Io.Reader, w: *std.Io.Writer, limit: std.Io.Limit) std.Io.Reader.StreamError!usize {
    const self: *BitReader = @fieldParentPtr("reader", r);
    if (self.file) |file| {
        // File mode - read from file and write to writer
        var buffer: [4096]u8 = undefined;
        var total_written: usize = 0;
        while (total_written < @intFromEnum(limit)) {
            const bytes_read = file.readStreaming(std.Options.debug_io, &.{buffer[0..]}) catch |err| switch (err) {
                error.EndOfStream => break,
                else => return error.ReadFailed,
            };
            if (bytes_read == 0) break;
            self.file_pos += bytes_read;
            const to_write = @min(bytes_read, @intFromEnum(limit) - total_written);
            _ = w.write(buffer[0..to_write]) catch |err| switch (err) {
                else => return error.WriteFailed,
            };
            total_written += to_write;
        }
        return total_written;
    } else {
        // Memory mode - use r.buffer directly
        const available = r.end - r.seek;
        const to_stream = @min(available, @intFromEnum(limit));
        if (to_stream > 0) {
            _ = w.write(r.buffer[r.seek .. r.seek + to_stream]) catch |err| switch (err) {
                else => return error.WriteFailed,
            };
            r.seek += to_stream;
        }
        return to_stream;
    }
}

fn discard(r: *std.Io.Reader, limit: std.Io.Limit) std.Io.Reader.Error!usize {
    const self: *BitReader = @fieldParentPtr("reader", r);
    if (self.file) |file| {
        // File mode - seek forward
        const offset = @intFromEnum(limit);
        std.Options.debug_io.vtable.fileSeekBy(std.Options.debug_io.userdata, file, @intCast(offset)) catch |err| switch (err) {
            else => return error.ReadFailed,
        };
        self.file_pos += offset;
        return offset;
    } else {
        // Memory mode - advance seek position in r
        const available = r.end - r.seek;
        const to_discard = @min(available, @intFromEnum(limit));
        r.seek += to_discard;
        return to_discard;
    }
}

fn readVec(r: *std.Io.Reader, data: [][]u8) std.Io.Reader.Error!usize {
    const self: *BitReader = @fieldParentPtr("reader", r);
    if (self.file) |file| {
        var vec_storage: [8][]u8 = undefined;
        const dest_count, const data_size = try r.writableVector(&vec_storage, data);
        const dest = vec_storage[0..dest_count];

        var total_read: usize = 0;
        for (dest) |slice| {
            if (slice.len == 0) continue;
            const bytes_read = file.readStreaming(std.Options.debug_io, &.{slice}) catch |err| switch (err) {
                error.EndOfStream => 0,
                else => return error.ReadFailed,
            };
            self.file_pos += bytes_read;
            total_read += bytes_read;
            if (bytes_read < slice.len) {
                if (total_read > data_size) {
                    r.end += total_read - data_size;
                }
                if (total_read == 0) return error.EndOfStream;
                return total_read;
            }
        }

        if (total_read == 0) return error.EndOfStream;
        if (total_read > data_size) {
            r.end += total_read - data_size;
        }
        return total_read;
    } else {
        // Memory mode - read from r.buffer
        var total_read: usize = 0;
        for (data) |slice| {
            const available = r.end - r.seek;
            if (available == 0) break;
            const to_read = @min(available, slice.len);
            @memcpy(slice[0..to_read], r.buffer[r.seek .. r.seek + to_read]);
            r.seek += to_read;
            total_read += to_read;
            if (to_read < slice.len) break;
        }
        return total_read;
    }
}

fn rebase(r: *std.Io.Reader, capacity: usize) std.Io.Reader.RebaseError!void {
    const self: *BitReader = @fieldParentPtr("reader", r);
    if (self.file) |_| {
        const tail_len = r.end - r.seek;
        const required = tail_len + capacity;

        if (self.owned_buffer) |buffer| {
            var current = buffer;
            if (required > current.len) {
                var new_capacity = current.len;
                if (new_capacity == 0) new_capacity = capacity;
                while (new_capacity < required) {
                    new_capacity *= 2;
                }
                current = try reallocOwnedBuffer(self, current, new_capacity);
                self.owned_buffer = current;
                self.reader.buffer = current;
            }
        } else if (required > self.reader.buffer.len) {
            return error.EndOfStream;
        }

        if (tail_len > 0 and r.seek != 0) {
            const src = self.reader.buffer[r.seek .. r.seek + tail_len];
            std.mem.copyForwards(u8, self.reader.buffer[0..tail_len], src);
        }
        r.seek = 0;
        r.end = tail_len;
        return;
    }

    return std.Io.Reader.defaultRebase(r, capacity);
}

fn reallocOwnedBuffer(self: *BitReader, buf: []u8, new_capacity: usize) std.Io.Reader.RebaseError![]u8 {
    const new_buf = self.allocator.realloc(buf, new_capacity) catch {
        return error.EndOfStream;
    };
    return new_buf;
}

test "BitReader append: incremental bit reads across boundary" {
    const allocator = std.testing.allocator;
    var br = try BitReader.initAppend(allocator, 1);
    defer br.deinit();

    // Append first byte 0xAA = 1010_1010
    try br.append(&.{0xAA});
    try std.testing.expect(try br.has(4));
    const first4 = try br.readBits(4);
    try std.testing.expectEqual(@as(u32, 0xA), first4);

    // Not enough for 8 bits yet
    try std.testing.expect(!(try br.has(8)));

    // Append second byte 0xBC = 1011_1100
    try br.append(&.{0xBC});
    // Now we have enough bits for the next 8: remaining 4 of 0xAA + first 4 of 0xBC = 0xAB
    try std.testing.expect(try br.has(8));
    const cross8 = try br.readBits(8);
    try std.testing.expectEqual(@as(u32, 0xAB), cross8);

    // Remaining 4 bits of 0xBC -> 0xC
    const last4 = try br.readBits(4);
    try std.testing.expectEqual(@as(u32, 0xC), last4);

    // No more bits
    try std.testing.expect(!(try br.has(1)));
}

test "BitReader append: readVec after appends" {
    const allocator = std.testing.allocator;
    var br = try BitReader.initAppend(allocator, 2);
    defer br.deinit();

    try br.append(&.{0xDE});
    try br.append(&.{ 0xAD, 0xBE, 0xEF });

    var a: [2]u8 = undefined;
    var b: [3]u8 = undefined;
    var vec = [_][]u8{ a[0..], b[0..] };
    const n = try br.reader.readVec(vec[0..]);
    try std.testing.expectEqual(@as(usize, 4), n);
    try std.testing.expect(std.mem.eql(u8, a[0..], &.{ 0xDE, 0xAD }));
    const expect_tail = [_]u8{ 0xBE, 0xEF };
    try std.testing.expect(std.mem.eql(u8, b[0..2], expect_tail[0..]));
}

test "BitReader memory: readBits basic" {
    const allocator = std.testing.allocator;
    const data = [_]u8{ 0xB3, 0x5C }; // 1011_0011, 0101_1100
    var br = BitReader.initFromMemory(allocator, data[0..]);

    // 3 bits: 101 = 5
    const a = try br.readBits(3);
    try std.testing.expectEqual(@as(u32, 5), a);

    // next 5 bits from first byte: 10011 = 19
    const b = try br.readBits(5);
    try std.testing.expectEqual(@as(u32, 19), b);

    // now exactly at byte boundary, next 8 bits should be second byte 0x5C
    const c = try br.readBits(8);
    try std.testing.expectEqual(@as(u32, 0x5C), c);
}

test "BitReader memory: has() near EOF" {
    const allocator = std.testing.allocator;
    const data = [_]u8{ 0xFF, 0x00 };
    var br = BitReader.initFromMemory(allocator, data[0..]);

    try std.testing.expect(try br.has(16));
    try std.testing.expect(!(try br.has(17)));
}

test "BitReader memory: std.Io.Reader.readVec" {
    const allocator = std.testing.allocator;
    const data = [_]u8{ 0xDE, 0xAD, 0xBE };
    var br = BitReader.initFromMemory(allocator, data[0..]);

    var out1: [2]u8 = undefined;
    var out2: [2]u8 = undefined;
    var vec = [_][]u8{ out1[0..], out2[0..] };
    const n = try br.reader.readVec(vec[0..]);
    try std.testing.expectEqual(@as(usize, 3), n);
    try std.testing.expect(std.mem.eql(u8, out1[0..], &.{ 0xDE, 0xAD }));
    try std.testing.expectEqual(@as(u8, 0xBE), out2[0]);
}

test "BitReader memory: peekBits and peekNonZero" {
    const allocator = std.testing.allocator;
    const data = [_]u8{ 0b1010_1100, 0b1111_0000 };
    var br = BitReader.initFromMemory(allocator, data[0..]);

    // Peek first 4 bits = 0b1010 = 10, reader state unchanged
    const p = try br.peekBits(4);
    try std.testing.expectEqual(@as(u32, 10), p);

    // Now actually read 4 bits; should match
    const r = try br.readBits(4);
    try std.testing.expectEqual(@as(u32, 10), r);

    // Next 4 bits of first byte: 1100 = 12, and it's non-zero
    try std.testing.expect(try br.peekNonZero(4));
    const r2 = try br.readBits(4);
    try std.testing.expectEqual(@as(u32, 12), r2);

    // Next 4 bits from second byte: 1111 = 15, non-zero
    try std.testing.expect(try br.peekNonZero(4));
    const r3 = try br.readBits(4);
    try std.testing.expectEqual(@as(u32, 15), r3);

    // Remaining 4 bits: 0000 = 0, peekNonZero should be false
    try std.testing.expect(!(try br.peekNonZero(4)));
    const r4 = try br.readBits(4);
    try std.testing.expectEqual(@as(u32, 0), r4);
}

test "BitReader memory: nextStartCode and findStartCode" {
    const allocator = std.testing.allocator;
    // bytes: 00 00 01 B3 12 34 00 00 01 E0 FF
    const data = [_]u8{ 0x00, 0x00, 0x01, 0xB3, 0x12, 0x34, 0x00, 0x00, 0x01, 0xE0, 0xFF };
    var br = BitReader.initFromMemory(allocator, data[0..]);

    const code1 = br.nextStartCode();
    try std.testing.expect(code1 != null);
    try std.testing.expectEqual(@as(u8, 0xB3), code1.?);

    const code2 = br.findStartCode(0xE0);
    try std.testing.expect(code2 != null);
    try std.testing.expectEqual(@as(u8, 0xE0), code2.?);

    const none = br.nextStartCode();
    try std.testing.expect(none == null);
}

test "BitReader memory: hasStartCode mirrors findStartCode without consuming" {
    const allocator = std.testing.allocator;
    const data = [_]u8{ 0x00, 0x00, 0x01, 0xB3, 0x7F, 0x00, 0x00, 0x01, 0xE0 };
    var br = BitReader.initFromMemory(allocator, data[0..]);

    // Should detect 0xB3 without consuming
    try std.testing.expect(br.hasStartCode(0xB3));
    // Now nextStartCode should still return 0xB3
    const code = br.nextStartCode();
    try std.testing.expect(code != null and code.? == 0xB3);
}

test "BitReader memory: skipBytes aligns and skips target byte" {
    const allocator = std.testing.allocator;
    const data = [_]u8{ 0xFF, 0x00, 0x00, 0x00, 0x12, 0x00 };
    var br = BitReader.initFromMemory(allocator, data[0..]);

    // Consume 4 bits to force misalignment, then skipBytes should align
    _ = try br.readBits(4);
    const skipped = try br.skipBytes(0x00);
    try std.testing.expectEqual(@as(usize, 3), skipped);
    // Next byte should be 0x12
    const next = try br.readBits(8);
    try std.testing.expectEqual(@as(u32, 0x12), next);
}

test "BitReader memory: tell reflects byte position across bit reads" {
    const allocator = std.testing.allocator;
    const data = [_]u8{ 0xAA, 0xBB, 0xCC };
    var br = BitReader.initFromMemory(allocator, data[0..]);

    try std.testing.expectEqual(@as(usize, 0), br.tell());
    _ = try br.readBits(3); // not crossing byte
    try std.testing.expectEqual(@as(usize, 0), br.tell());
    _ = try br.readBits(5); // completes first byte
    try std.testing.expectEqual(@as(usize, 1), br.tell());
    _ = try br.readBits(8);
    try std.testing.expectEqual(@as(usize, 2), br.tell());
}

test "BitReader memory: hasEnded after consuming all bits" {
    const allocator = std.testing.allocator;
    const data = [_]u8{0x01};
    var br = BitReader.initFromMemory(allocator, data[0..]);

    try std.testing.expect(!br.hasEnded());
    _ = try br.readBits(8);
    try std.testing.expect(br.hasEnded());
}

test "BitReader append: signalEnd controls hasEnded" {
    const allocator = std.testing.allocator;
    var br = try BitReader.initAppend(allocator, 4);
    defer br.deinit();

    try br.append(&.{0xAA});
    try std.testing.expect(!br.hasEnded());
    br.signalEnd();
    _ = try br.readBits(8);
    try std.testing.expect(br.hasEnded());
}

test "BitReader memory: discardReadBytes compacts consumed data" {
    const allocator = std.testing.allocator;
    const data = [_]u8{ 0x11, 0x22, 0x33 };
    var br = BitReader.initFromMemory(allocator, data[0..]);

    _ = try br.readBits(8);
    _ = try br.readBits(8);
    try std.testing.expectEqual(@as(usize, 2), br.reader.seek);

    br.discardReadBytes();

    try std.testing.expectEqual(@as(usize, 0), br.reader.seek);
    try std.testing.expectEqual(@as(usize, 1), br.reader.end);
    const remaining = try br.readBits(8);
    try std.testing.expectEqual(@as(u32, 0x33), remaining);
    try std.testing.expect(br.hasEnded());
}

test "BitReader append: discardReadBytes shrinks buffer" {
    const allocator = std.testing.allocator;
    var br = try BitReader.initAppend(allocator, 4);
    defer br.deinit();

    try br.append(&.{ 0xAA, 0xBB, 0xCC });
    _ = try br.readBits(8);
    _ = try br.readBits(8);
    try std.testing.expectEqual(@as(usize, 2), br.reader.seek);

    br.discardReadBytes();

    try std.testing.expectEqual(@as(usize, 0), br.reader.seek);
    try std.testing.expectEqual(@as(usize, 1), br.reader.end);
    try std.testing.expectEqual(@as(usize, 1), br.append_list.?.items.len);
    const tail = try br.readBits(8);
    try std.testing.expectEqual(@as(u32, 0xCC), tail);
    try std.testing.expect(!br.hasEnded());
    br.signalEnd();
    try std.testing.expect(br.hasEnded());
}
