const cli = @import("zig-cli");
const Command = @import("./command.zig").Command;
const std = @import("std");

fn h() !void {}

pub const Add = struct {
    const Self = @This();
    fn add(ptr: *anyopaque) cli.Command {
        _ = ptr;
        return cli.Command{
            .name = "add",
            .description = cli.Description{
                .one_line = "add a new registry.",
            },
            .target = cli.CommandTarget{ .action = cli.CommandAction{
                .exec = h,
            } },
        };
    }

    pub fn call(self: *Self) Command {
        return .{
            .ptr = self,
            .call = add,
        };
    }
};

pub fn new() Command {
    var instance = Add{};
    return instance.call();
}
