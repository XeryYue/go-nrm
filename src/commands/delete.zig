const cli = @import("zig-cli");
const Command = @import("./command.zig").Command;

pub const Delete = struct {
    const Self = @This();

    fn delete(ptr: *anyopaque) cli.Command {
        _ = ptr;
        return cli.Command{
            .name = "delete",
            .description = cli.Description{
                .one_line = "delete a registry.",
            },
            .target = cli.CommandTarget{},
        };
    }

    pub fn call(self: *Self) Command {
        return .{
            .ptr = self,
            .call = delete,
        };
    }
};

pub fn new() Command {
    var instance = Delete{};
    return instance.call();
}
