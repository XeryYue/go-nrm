pub const lex = @import("./lex.zig");
pub const parse = @import("./parse.zig");
pub const printer = @import("./printer.zig");

comptime {
    if (@import("builtin").is_test) {
        @import("std").testing.refAllDecls(@This());
    }
}
