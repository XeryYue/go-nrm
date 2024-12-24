const builtin = @import("builtin");
const cli = @import("zig-cli");
const ini = @import("ini");

pub const Command = struct {
    pub const Type = enum(u8) {
        list,
        current,
        use,
        add,
        default,
        delete,
        fetch, // test is keyword
    };

    pub fn execute(command: Command) type {
        switch (command) {
            .list => List,
            .current => Current,
            .use => Use,
            .add => Add,
            .default => Default,
            .delete => Delete,
            .fetch => Fetch,
        }
    }
    pub const List = cli.Command{
        .name = "list",
        .description = cli.Description{
            .one_line = "List all available registry.",
            .detailed =
            \\Aliased as ls.
            ,
        },
    };

    pub const Current = cli.Command{
        .name = "current",
        .description = cli.Description{
            .one_line = "Show the currently used registry.",
        },
    };

    pub const Use = cli.Command{
        .name = "use",
        .description = cli.Description{
            .one_line = "Use a specific registry.",
        },
    };

    pub const Add = cli.Command{
        .name = "add",
        .description = cli.Description{
            .one_line = "Add a new registry.",
        },
    };

    pub const Default = cli.Command{
        .name = "default",
        .description = cli.Description{
            .one_line = "Set a registry as default.",
        },
    };

    pub const Delete = cli.Command{
        .name = "delete",
        .description = cli.Description{
            .one_line = "Delete a registry.",
        },
    };

    pub const Fetch = cli.Command{
        .name = "fetch",
        .description = cli.Description{
            .one_line = "Test response time for a registry or all registries.",
        },
    };
};
