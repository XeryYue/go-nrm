const std = @import("std");
const ast = @import("./ast.zig");

const AST = ast.AST;
const Allocator = std.mem.Allocator;

const Printer = struct {
    const Self = @This();
    allocator: Allocator,
    pub fn init(allocator: Allocator) Self {
        return Self{
            .allocator = allocator,
        };
    }
    pub fn stringify() anyerror!void {}
    inline fn print() void {}
};
