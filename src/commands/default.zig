const cli = @import("zig-cli");
const Command = @import("./command.zig").Command;

pub const Default = struct {
    const Self = @This();

    fn default(ptr: *anyopaque) cli.Command {
        _ = ptr;
        return cli.Command{
            .name = "default",
            .description = cli.Description{
                .one_line = "set a registry as default.",
            },
            .target = cli.CommandTarget{},
        };
    }

    pub fn call(self: *Self) Command {
        return .{
            .ptr = self,
            .call = default,
        };
    }
};

pub fn new() Command {
    var instance = Default{};
    return instance.call();
}
