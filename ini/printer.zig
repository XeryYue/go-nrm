const std = @import("std");
const ast = @import("./ast.zig");
const Parse = @import("./parse.zig").Parse;

const AST = ast.AST;
const Node = ast.Node;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

// Note: I have no time to implement a pretty printer. so this impl is opinionated.
pub const Printer = struct {
    const Self = @This();
    allocator: Allocator,
    ast: AST,
    sb: StringBuilder,
    pub fn init(allocator: Allocator) Self {
        return Self{
            .allocator = allocator,
            .ast = undefined,
            .sb = StringBuilder.init(allocator),
        };
    }
    pub fn deinit(self: *Self) void {
        self.sb.deinit();
    }
    pub fn stringify(self: *Self, input: AST) anyerror!void {
        self.ast = input;
        for (self.ast.nodes.items) |node| {
            switch (node.kind) {
                .pairs => try self.print_paris(node),
                .section => {
                    const p: *Node.Section = @fieldParentPtr("base", node);
                    try self.print('[');
                    try self.print(p.name.value);
                    try self.print(']');
                    try self.print('\n');
                    for (p.children.items) |child| {
                        try self.print_paris(child);
                    }
                },
                else => unreachable,
            }
        }
    }
    fn print_paris(self: *Self, node: *Node) !void {
        const p: *Node.Pairs = @fieldParentPtr("base", node);
        try self.print(p.decl.value);
        try self.print(' ');
        try self.print('=');
        try self.print(' ');
        try self.print(p.init.value);
        try self.print('\n');
    }
    inline fn print(self: *Self, data: anytype) !void {
        try self.sb.write(data);
    }
};

const StringBuilder = struct {
    const Self = @This();
    s: ArrayList(u8),
    allocator: Allocator,
    pub fn init(allocator: Allocator) Self {
        return Self{
            .allocator = allocator,
            .s = ArrayList(u8).init(allocator),
        };
    }
    pub fn deinit(self: *Self) void {
        self.s.deinit();
    }

    pub fn write_str(self: *Self, str: []const u8) !void {
        for (str) |b| {
            try self.s.append(b);
        }
    }
    pub fn write_byte(self: *Self, byte: comptime_int) !void {
        try self.s.append(byte);
    }
    pub fn write(self: *Self, data: anytype) !void {
        const T = @TypeOf(data);
        switch (@typeInfo(T)) {
            .Int, .ComptimeInt => try self.write_byte(data),
            .Pointer => |ptr| switch (ptr.size) {
                .One, .Slice => try self.write_str(data),
                else => @compileError("Unsupported pointer type"),
            },
            else => @compileError("Unsupported type"),
        }
    }
};

test "StringBuilder" {
    var sb = StringBuilder.init(std.testing.allocator);
    defer sb.deinit();
    try sb.write(48);
    try sb.write(48);
    try sb.write("000");
    try std.testing.expect(std.mem.eql(u8, sb.s.items, "00000"));
}

fn TestPrinter(fixture_name: []const u8, allocator: Allocator) !void {
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
    var printer = Printer.init(allocator);
    defer printer.deinit();
    try printer.stringify(parse.ast);
}

test "Printer" {
    try TestPrinter("base.ini", std.testing.allocator);
    try TestPrinter("section.ini", std.testing.allocator);
}
