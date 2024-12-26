// https://github.com/npm/ini
// Ini don't have a standard parsing spec.
// But this is the most common implementation.

const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const unicode = std.unicode;

pub const CodePoint = struct {
    code_point: i32,
    width: usize,
};

pub const UTF8 = struct {
    pub fn char_at(index: usize, bytes: []const u8) !CodePoint {
        if (index >= bytes.len) {
            return error.Utf8InvalidStartByte;
        }
        const width = try unicode.utf8ByteSequenceLength(bytes[index]);
        const code_point = try unicode.utf8Decode(bytes[index .. index + width]);
        return CodePoint{
            .code_point = code_point,
            .width = @as(usize, @intCast(width)),
        };
    }
};

pub inline fn is_whitespace(c: i32) bool {
    return c == ' ' or c == '\t' or c == '\r' or c == '\n' or c == '\u{c}';
}

pub inline fn is_digit(c: i32) bool {
    return c >= '0' and c <= '9';
}

pub inline fn is_ident_start(c: i32) bool {
    return c >= 0 and c <= 127 or c >= 0x80 or c == 0x00;
}

inline fn skip_not_valid_sequence(c: i32) bool {
    switch (c) {
        -1 => return true,
        '[' => return true,
        ':', '=' => return true,
        '\r', '\n' => return true,
        else => return false,
    }
}

pub const Token = struct {
    const Self = @This();
    kind: Kind,
    start: usize,
    end: usize,
    line_number: usize,
    flag: Flag,
    pub const Flag = enum(u3) { none, hash, semi_colon, single_quote, double_quote, normal_equal, colon_equal };
    pub const Kind = enum(u8) {
        end_of_file,
        open_bracket,
        close_bracket,
        comment,
        equal,
        string,
        whitespace,
        pub fn to_str(tok: Token) []const u8 {
            switch (tok) {
                .end_of_file => "end_of_file",
                .open_bracket => "open_bracket",
                .close_bracket => "close_bracket",
                .comment => "comment",
                .colon => "colon",
                .equal => "equal",
                .string => "string",
                .whitespace => "whitespace",
            }
        }
    };
    pub fn init() Self {
        return Self{
            .kind = Kind.end_of_file,
            .start = 0,
            .end = undefined,
            .line_number = 0,
            .flag = undefined,
        };
    }
};

pub const Lex = struct {
    const Self = @This();
    buffer: []const u8,
    index: usize,
    token: Token,
    line_number: usize,
    code_point: i32,

    pub fn init(buffer: []const u8) Self {
        return Self{
            .buffer = buffer,
            .index = 0,
            .line_number = 1,
            .code_point = undefined,
            .token = undefined,
        };
    }

    inline fn step(self: *Self) void {
        const cp = UTF8.char_at(self.index, self.buffer) catch {
            self.code_point = -1;
            return;
        };
        self.index += cp.width;
        switch (cp.width) {
            0 => self.code_point = -1,
            else => self.code_point = cp.code_point,
        }
        if (cp.code_point == '\n') {
            self.line_number += 1;
        }
    }

    pub inline fn next(self: *Self) !void {
        while (true) {
            self.token = Token.init();
            self.token.start = self.index - 1;
            switch (self.code_point) {
                -1 => self.token.kind = Token.Kind.end_of_file,
                ' ', '\t', '\r', '\n', '\u{c}' => {
                    self.step();
                    while (is_whitespace(self.code_point)) {
                        self.step();
                    }
                    self.token.kind = Token.Kind.whitespace;
                },
                '[' => {
                    self.step();
                    self.token.kind = Token.Kind.open_bracket;
                },
                ']' => {
                    self.step();
                    self.token.kind = Token.Kind.close_bracket;
                },
                '#', ';' => {
                    self.step();
                    self.token.flag = if (self.code_point == '#') Token.Flag.hash else Token.Flag.semi_colon;
                    loop: while (true) {
                        switch (self.code_point) {
                            -1, '\r', '\n' => {
                                break :loop;
                            },
                            else => {
                                self.step();
                            },
                        }
                    }
                    self.token.kind = Token.Kind.comment;
                },
                '"', '\'' => {
                    const quote = self.code_point;
                    self.step();
                    loop: while (true) : (self.step()) {
                        switch (self.code_point) {
                            -1, '\r', '\n', '\u{c}' => {
                                break :loop;
                            },
                            else => {
                                if (self.code_point == quote) {
                                    self.step();
                                    self.token.kind = Token.Kind.string;
                                    self.token.flag = if (quote == '"') Token.Flag.double_quote else Token.Flag.single_quote;
                                    break :loop;
                                }
                            },
                        }
                    }
                },
                ':', '=' => {
                    self.token.kind = Token.Kind.equal;
                    self.token.flag = if (self.code_point == '=') Token.Flag.normal_equal else Token.Flag.colon_equal;
                    self.step();
                },
                else => {
                    self.token.kind = self.consume_str();
                },
            }
            self.token.end = if (self.index + 1 <= self.buffer.len) self.index - 1 else self.index;
            self.token.line_number = self.line_number;
            return;
        }
    }

    fn consume_str(self: *Self) Token.Kind {
        while (true) {
            if (skip_not_valid_sequence(self.code_point)) {
                break;
            }
            self.step();
        }
        return Token.Kind.string;
    }
};

pub fn Tokenizer(input: []const u8, allocator: Allocator) !ArrayList(Token) {
    var lex = Lex.init(input);
    var tokens = ArrayList(Token).init(allocator);
    lex.step();
    try lex.next();
    while (lex.token.kind != Token.Kind.end_of_file) {
        try tokens.append(lex.token);
        try lex.next();
    }

    return tokens;
}

test "UTF8 decode" {
    try std.testing.expectEqual(CodePoint{ .width = 3, .code_point = 20320 }, UTF8.char_at(0, "你"));
    try std.testing.expectEqual(CodePoint{ .width = 1, .code_point = 122 }, UTF8.char_at(3, "nonzzz"));
}
