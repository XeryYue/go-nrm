const std = @import("std");
const cli = @import("zig-cli");
const Commands = @import("commands");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const command = enum {
    add,
    current,
    default,
    delete,
    fetch,
    use,
    list,
    inline fn parse(c: command) cli.Command {
        return switch (c) {
            .add => Commands.Add().apply(),
            .current => Commands.Current().apply(),
            .default => Commands.Default().apply(),
            .delete => Commands.Delete().apply(),
            .fetch => Commands.Fetch().apply(),
            .use => Commands.Use().apply(),
            .list => Commands.List().apply(),
        };
    }
};

pub fn parseArgs() cli.AppRunner.Error!cli.ExecFn {
    var r = try cli.AppRunner.init(allocator);

    const app = cli.App{
        .command = cli.Command{
            .name = "grm",
            .target = cli.CommandTarget{
                .subcommands = &.{
                    command.add.parse(),
                    command.current.parse(),
                    command.default.parse(),
                    command.delete.parse(),
                    command.fetch.parse(),
                    command.use.parse(),
                    command.list.parse(),
                },
            },
        },
    };

    return r.getAction(&app);
}
