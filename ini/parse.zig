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
    pub fn init(allocator: Allocator) void {
        return Self{
            .allocator = allocator,
        };
    }

    pub fn parse(self: *Self, buffer: []const u8) !void {
        const result = try lex.Tokenizer(buffer, Self.allocator);
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
