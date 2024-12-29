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
    pub inline fn create(line: usize, start: usize, end: usize) Loc {
        return Loc{
            .line = line,
            .start = start,
            .end = end,
        };
    }
};

const NodeLoc = struct {
    start: Loc,
    end: Loc,
};

pub const Node = struct {
    kind: NodeKind,
    loc: NodeLoc = NodeLoc{
        .start = undefined,
        .end = undefined,
    },
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
        decl: Identifer = undefined,
        init: Identifer = undefined,
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
        pub inline fn create_loc(self: *Identifer, line: usize, start: usize, end: usize) void {
            self.base.loc.start = Loc.create(line, start, end);
            self.base.loc.end = Loc.create(line, start, end);
        }
    };

    pub fn deinit(self: *Node, allocator: Allocator) void {
        switch (self.kind) {
            .pairs => {
                const p: *Node.Pairs = @fieldParentPtr("base", self);
                allocator.destroy(p);
            },
            else => unreachable,
        }
    }
};

pub const AST = struct {
    nodes: ArrayListUnmanaged(*Node) = .{},
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
    pos: usize,
    const Self = @This();
    pub fn init(allocator: Allocator) Self {
        return Self{
            .allocator = allocator,
            .tokens = undefined,
            .ast = .{},
            .source = undefined,
            .pos = 0,
        };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.tokens);
        for (self.ast.nodes.items) |node| {
            node.deinit(self.allocator);
        }
        self.ast.nodes.deinit(self.allocator);
    }

    pub fn parse(self: *Self, buffer: []const u8) !void {
        var tokens = try lex.Tokenizer(buffer, self.allocator);
        defer tokens.deinit();
        self.tokens = try tokens.toOwnedSlice();
        self.source = buffer;
        // std.debug.print("{any}\n", .{self.tokens});
        for (self.tokens) |token| {
            if (self.pos >= self.tokens.len) break;
            switch (token.kind) {
                Token.Kind.end_of_file => {
                    break;
                },
                Token.Kind.string => {
                    const pairs = try self.consume_key_value_pairs();
                    try self.ast.nodes.append(self.allocator, pairs);
                },
                // Token.Kind.open_bracket => {},
                else => {
                    self.advance();
                },
            }
        }
    }

    fn consume_key_value_pairs(self: *Self) ParseError!*Node {
        const node = try self.allocator.create(Node.Pairs);
        errdefer self.allocator.destroy(node);
        node.* = .{};
        const key_token = self.current();
        const key_raw = self.decode_text();
        node.base.loc.start = Loc.create(key_token.line_number, key_token.start, key_token.start + key_raw.len);
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
                        const value_token = self.current();
                        const value_raw = self.decode_text();
                        node.base.loc.end = Loc.create(value_token.line_number, value_token.end, value_token.end + value_raw.len);
                        node.decl = Node.Identifer{
                            .value = key_raw,
                        };
                        const start = node.base.loc.start;
                        const end = node.base.loc.end;
                        node.decl.create_loc(start.line, start.start, start.end);
                        node.init = Node.Identifer{
                            .value = value_raw,
                        };
                        node.init.create_loc(end.line, end.start, end.end);
                    }
                    self.advance();
                    break :loop;
                },
                Token.Kind.whitespace => {
                    // self.advance();
                    break :loop;
                },
                else => {
                    return error.UnexpectedToken;
                },
            }
        }
        return &node.base;
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
            return Token.init();
        }
        return self.tokens[self.pos + 1];
    }
    inline fn expect(self: *Self, kind: Token.Kind) bool {
        if (self.peek().kind == kind) {
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
    defer parse.deinit();
    try parse.parse(content);
    std.debug.print("{any}\n", .{parse.ast.nodes.items.len});
}

test "Parse" {
    try TestParse("base.ini", std.testing.allocator);
}
