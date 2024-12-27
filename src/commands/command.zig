const cli = @import("zig-cli");
const std = @import("std");

pub const Command = struct {
    ptr: *anyopaque,
    call: *const fn (ptr: *anyopaque) cli.Command,
    pub fn apply(self: Command) cli.Command {
        return self.call(self.ptr);
    }
};
