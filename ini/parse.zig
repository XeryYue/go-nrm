const std = @import("std");
const lex = @import("./lex.zig");

const Token = lex.Token;
const Allocator = std.mem.Allocator;

pub const Node = struct {};

pub const AST = struct {};

pub const Parse = struct {
    allocator: Allocator,
    tokens: []Token,
    const Self = @This();
    pub fn init(allocator: Allocator) Self {
        return Self{
            .allocator = allocator,
            .tokens = undefined,
        };
    }

    pub fn parse(self: *Self, buffer: []const u8) !void {
        const result = try lex.Tokenizer(buffer, self.allocator);
        defer {
            result.deinit();
        }
        self.tokens = result.items;

        for (self.tokens) |token| {
            switch (token.kind) {
                Token.Kind.end_of_file => {
                    break;
                },
                Token.Kind.string => {
                    //
                },
                else => {},
            }
        }
    }

    fn consume_key_value_pairs() void {}

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
