const std = @import("std");
const lex = @import("./lex.zig");

const Allocator = std.mem.Allocator;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

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
        name: Identifer = undefined,
        children: ArrayListUnmanaged(*Node) = .{},

        pub fn deinit(self: *Section, allocator: Allocator) void {
            for (self.children.items) |c| {
                c.deinit(allocator);
            }
            self.children.deinit(allocator);
        }
    };
    pub const Comment = struct {
        base: Node = .{
            .kind = NodeKind.comment,
            .loc = undefined,
        },
        flag: lex.Token.Flag = lex.Token.Flag.semi_colon,
        text: []const u8 = undefined,
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
            .comment => {
                const p: *Node.Comment = @fieldParentPtr("base", self);
                allocator.destroy(p);
            },
            .section => {
                const p: *Node.Section = @fieldParentPtr("base", self);
                p.deinit(allocator);
                allocator.destroy(p);
            },
            else => unreachable,
        }
    }
};

pub const AST = struct {
    nodes: ArrayListUnmanaged(*Node) = .{},
    comments: ArrayListUnmanaged(*Node) = .{},
};
