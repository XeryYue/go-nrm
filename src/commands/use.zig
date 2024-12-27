const cli = @import("zig-cli");
const Command = @import("./command.zig").Command;

fn x() !void {}

pub const Use = struct {
    const Self = @This();

    fn use(ptr: *anyopaque) cli.Command {
        _ = ptr;
        return cli.Command{
            .name = "use",
            .description = cli.Description{
                .one_line = "use a specific registry.",
            },
            .target = cli.CommandTarget{
                .action = cli.CommandAction{
                    .exec = x,
                },
            },
        };
    }

    pub fn call(self: *Self) Command {
        return .{
            .ptr = self,
            .call = use,
        };
    }
};

pub fn new() Command {
    var instance = Use{};
    return instance.call();
}
