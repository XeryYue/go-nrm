const cli = @import("zig-cli");
const Command = @import("./command.zig").Command;

pub const Current = struct {
    const Self = @This();

    fn current_version(ptr: *anyopaque) cli.Command {
        _ = ptr;
        return cli.Command{
            .name = "current",
            .description = cli.Description{
                .one_line = "show the currently used registry.",
            },
            .target = cli.CommandAction{},
        };
    }

    pub fn call(self: *Self) Command {
        return .{
            .ptr = self,
            .call = current_version,
        };
    }
};

pub fn new() Command {
    var instance = Current{};
    return instance.call();
}
