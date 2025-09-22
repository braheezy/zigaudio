test {
    @import("std").testing.refAllDecls(@This());
    _ = @import("frameheader.zig");
    _ = @import("bits.zig");
    _ = @import("imdct.zig");
    _ = @import("sideinfo.zig");
    _ = @import("maindata.zig");
}
