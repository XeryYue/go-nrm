pub const lex = @import("./lex.zig");
pub const parse = @import("./parse.zig");

comptime {
    if (@import("builtin").is_test) {
        @import("std").testing.refAllDecls(@This());
    }
}
