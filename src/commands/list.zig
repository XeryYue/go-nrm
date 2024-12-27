const cli = @import("zig-cli");
const Command = @import("./command.zig").Command;

pub const List = struct {
    const Self = @This();

    fn list(ptr: *anyopaque) cli.Command {
        _ = ptr;
        return cli.Command{
            .name = "list",
            .description = cli.Description{
                .one_line = "list all available registry.",
            },
            .target = cli.CommandTarget{},
        };
    }

    pub fn call(self: *Self) Command {
        return .{
            .ptr = self,
            .call = list,
        };
    }
};

pub fn new() Command {
    var instance = List{};
    return instance.call();
}
