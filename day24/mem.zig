const std = @import("std");

const Op = enum {
    the_or,
    the_xor,
    the_and,

    pub fn doOp(self: Op, in_1: u8, in_2: u8) !u8 {
        if (self == Op.the_or) {
            return in_1 | in_2;
        } else if (self == Op.the_xor) {
            return in_1 ^ in_2;
        } else if (self == Op.the_and) {
            return in_1 & in_2;
        } else unreachable;
    }
};

const Node = struct {
    id: []const u8,
};

const Transition = struct {
    from_1: *Node,
    from_2: *Node,
    op: Op,
    to_1: *Node,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
}
