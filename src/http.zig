const std = @import("std");
const net = std.net;

pub const Client = struct {
    limit: u8,
    const Self = @This();
    pub fn init() Self {}
    pub fn deinit() void {}
    pub fn send_req_sequence() void {}
};

test "client test" {
    try std.testing.expect(true);
}
