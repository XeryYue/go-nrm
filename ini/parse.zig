const std = @import("std");
const lex = @import("./lex.zig");

const Token = lex.Token;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const Node = struct {
    kind: NodeKind,
    pub const NodeKind = enum(u3) {
        paris,
        section,
        comment,
    };
    pub const Paris = struct {
        base: Node = .{ .kind = NodeKind.paris },
    };
    pub const Section = struct {
        base: Node = .{ .kind = NodeKind.section },
    };
    pub const Comment = struct {
        base: Node = .{ .kind = NodeKind.comment },
    };
};

pub const AST = struct {
    nodes: []Node,
};

pub const Parse = struct {
    allocator: Allocator,
    ast: AST,
    tokens: []Token,
    const Self = @This();
    pub fn init(allocator: Allocator) Self {
        return Self{
            .allocator = allocator,
            .tokens = undefined,
            .ast = undefined,
        };
    }

    pub fn parse(self: *Self, buffer: []const u8) !void {
        const result = try lex.Tokenizer(buffer, self.allocator);
        const nodes = ArrayList(Node).init(self.allocator);
        defer {
            result.deinit();
            nodes.deinit();
        }
        self.tokens = result.items;
        // std.debug.print("{any}\n", .{self.tokens});
        for (self.tokens) |token| {
            switch (token.kind) {
                Token.Kind.end_of_file => {
                    break;
                },
                Token.Kind.string => {
                    try nodes.append(self.consume_key_value_pairs());
                },
                // Token.Kind.open_bracket => {},
                else => {},
            }
        }
    }

    fn consume_key_value_pairs(self: *Self) void {
        _ = self.current();
    }

    fn consume_comment() void {}

    fn consume_section() void {}

    inline fn advance(self: *Self) void {
        if (self.pos >= self.tokens.len) {
            return;
        }
        self.pos += 1;
    }
    inline fn current(self: *Self) Token {
        return self.tokens[self.pos];
    }
    inline fn peek(self: *Self) Token {
        if (self.pos >= self.tokens.len) {
            return Token{ .kind = Token.Kind.end_of_file };
        }
        return self.tokens[self.pos + 1];
    }
};

fn TestParse(fixture_name: []const u8, allocator: Allocator) !void {
    const cwd = try std.process.getCwdAlloc(allocator);
    const path = try std.fs.path.join(allocator, &[_][]const u8{ cwd, "/ini/__fixtures__/", fixture_name });
    const content = try std.fs.cwd().readFileAlloc(allocator, path, std.math.maxInt(usize));
    defer {
        allocator.free(cwd);
        allocator.free(path);
        allocator.free(content);
    }
    var parse = Parse.init(allocator);
    try parse.parse(content);
}

test "Parse" {
    try TestParse("base.ini", std.testing.allocator);
}
