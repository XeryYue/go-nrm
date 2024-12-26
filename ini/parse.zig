const std = @import("std");
const lex = @import("./lex.zig");

const Token = lex.Token;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

// We should also provide detail loc info.
pub const Loc = struct {
    line: usize,
    start: usize,
    end: usize,
};

const NodeLoc = struct {
    start: Loc,
    end: Loc,
};

pub const Node = struct {
    kind: NodeKind,
    loc: NodeLoc,
    pub const NodeKind = enum(u3) {
        pairs,
        section,
        comment,
        identifer,
    };
    pub const Pairs = struct {
        base: Node = .{
            .kind = NodeKind.pairs,
            .loc = undefined,
        },
        decl: Identifer,
        init: Identifer,
    };
    pub const Section = struct {
        base: Node = .{
            .kind = NodeKind.section,
            .loc = undefined,
        },
        children: []Node,
    };
    pub const Comment = struct {
        base: Node = .{
            .kind = NodeKind.comment,
            .loc = undefined,
        },
        text: []const u8,
    };

    pub const Identifer = struct {
        base: Node = .{
            .kind = NodeKind.identifer,
            .loc = undefined,
        },
        value: []const u8,
    };
};

pub const AST = struct {
    // nodes: []Node,
    nodes: ArrayListUnmanaged(*Node),
};

pub const ParseError = error{
    InvalidPairs, // like missing init
    InvalidSection,
    UnexpectedToken,
} || Allocator.Error;

pub const Parse = struct {
    allocator: Allocator,
    ast: AST,
    tokens: []Token,
    source: []const u8,
    const Self = @This();
    pub fn init(allocator: Allocator) Self {
        return Self{
            .allocator = allocator,
            .tokens = undefined,
            .ast = undefined,
            .source = undefined,
        };
    }

    pub fn parse(self: *Self, buffer: []const u8) !void {
        const tokens = try lex.Tokenizer(buffer, self.allocator);
        const nodes = ArrayList(Node).init(self.allocator);
        defer {
            tokens.deinit();
            nodes.deinit();
        }
        self.tokens = tokens.toOwnedSlice();
        self.source = buffer;
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

    fn consume_key_value_pairs(self: *Self) Node {
        const key = self.decode_text();
        self.advance();
        loop: while (true) {
            switch (self.current().kind) {
                Token.Kind.end_of_file => {
                    break :loop;
                },
                Token.Kind.comment => {
                    break :loop;
                },
                Token.Kind.open_bracket => {
                    break :loop;
                },
                Token.Kind.equal => {
                    if (self.expect(Token.Kind.string)) {
                        // return Node.Paris{
                        //     .key = key,
                        //     .value = self.decode_text(),
                        // };
                    }
                },
                Token.Kind.whitespace => self.advance(),
            }
        }
    }

    // fn consume_comment(self: *Self) void {

    // }

    // fn consume_section(self: *Self) void {}

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
    inline fn expect(self: *Self, kind: Token.Kind) bool {
        if (self.peek() == kind) {
            self.advance();
            return true;
        }
        return false;
    }
    inline fn decode_text(self: *Self) []const u8 {
        const token = self.current();
        return self.source[token.start..token.end];
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
