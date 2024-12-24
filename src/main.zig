const std = @import("std");
const cli = @import("zig-cli");
const ini = @import("ini");

pub fn main() void {
    std.debug.print("{any}\n", .{cli.ColorUsage.always});
}
