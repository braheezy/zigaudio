const api = @import("root.zig");
const qoa = @import("qoa.zig");

pub const supported_formats: []const api.FormatVTable = &[_]api.FormatVTable{
    qoa.vtable,
};
