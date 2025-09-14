const api = @import("root.zig");
const qoa = @import("qoa.zig");

pub fn defaultFormats() []const api.FormatVTable {
    return &[_]api.FormatVTable{
        qoa.vtable(),
    };
}
