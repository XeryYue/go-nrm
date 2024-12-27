const std = @import("std");
const cli = @import("./cli.zig");

pub fn main() anyerror!void {
    const action = try cli.parseArgs();
    const r = action();
    return r;
}
