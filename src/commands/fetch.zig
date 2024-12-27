const cli = @import("zig-cli");
const Command = @import("./command.zig").Command;

fn fetch_impl() !void {}

pub const Fetch = struct {
    const Self = @This();

    fn fetch(ptr: *anyopaque) cli.Command {
        _ = ptr;
        return cli.Command{
            .name = "fetch",
            .description = cli.Description{
                .one_line = "test response time for a registry or all registries.",
            },
            .target = cli.CommandTarget{
                .action = cli.CommandAction{
                    .exec = fetch_impl,
                },
            },
        };
    }

    pub fn call(self: *Self) Command {
        return .{
            .ptr = self,
            .call = fetch,
        };
    }
};

pub fn new() Command {
    var instance = Fetch{};
    return instance.call();
}
