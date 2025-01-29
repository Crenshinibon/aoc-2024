const std = @import("std");
const input_r = @embedFile("./input_r.txt");
const input_s = @embedFile("./input_s.txt");

fn readInputState(allocator: std.mem.Allocator) ![]Node {
    var state = std.ArrayList(Node).init(allocator);

    var i_ite = std.mem.tokenizeScalar(u8, input_s, '\n');
    while (i_ite.next()) |i_line| {
        const id = i_line[0..3];
        const value = i_line[5];

        try state.append(.{
            .id = id,
            .value = if (value - 48 == 0) 0 else 1,
        });
    }
    return state.items;
}

fn readNodes(allocator: std.mem.Allocator) !std.StringHashMap(*Node) {
    var map = std.StringHashMap(*Node).init(allocator);
    var r_ite = std.mem.tokenizeScalar(u8, input_r, '\n');

    while (r_ite.next()) |r_string| {
        var p_ite = std.mem.tokenizeScalar(u8, r_string, ' ');
        const in_1 = p_ite.next().?;
        //discard ops
        _ = p_ite.next().?;
        const in_2 = p_ite.next().?;
        //discard arrow
        _ = p_ite.next().?;
        const next = p_ite.next().?;

        if (!map.contains(in_1)) {
            var from_1 = try allocator.create(Node);
            from_1.id = in_1;
            try map.put(in_1, from_1);
        }
        if (!map.contains(in_2)) {
            var from_2 = try allocator.create(Node);
            from_2.id = in_2;
            try map.put(in_2, from_2);
        }
        if (!map.contains(next)) {
            var to = try allocator.create(Node);
            to.id = next;
            try map.put(next, to);
        }
    }

    return map;
}

fn readTransitions(allocator: std.mem.Allocator, nodes: std.StringHashMap(*Node)) ![]Transition {
    var trans = std.ArrayList(Transition).init(allocator);

    var r_ite = std.mem.tokenizeScalar(u8, input_r, '\n');
    while (r_ite.next()) |r_string| {
        var p_ite = std.mem.tokenizeScalar(u8, r_string, ' ');
        const in_1 = p_ite.next().?;
        const ops_string = p_ite.next().?;
        const in_2 = p_ite.next().?;
        //discard arrow
        _ = p_ite.next().?;
        const next = p_ite.next().?;

        var op: Op = undefined;
        if (std.mem.eql(u8, ops_string, "OR")) {
            op = Op.the_or;
        } else if (std.mem.eql(u8, ops_string, "XOR")) {
            op = Op.the_xor;
        } else if (std.mem.eql(u8, ops_string, "AND")) {
            op = Op.the_and;
        } else unreachable;

        const from_1 = nodes.get(in_1);
        const from_2 = nodes.get(in_2);
        const to = nodes.get(next);

        const r = Transition{
            .from_1 = from_1.?,
            .from_2 = from_2.?,
            .op = op,
            .to = to.?,
        };

        try trans.append(r);
    }

    return trans.items;
}

const Op = enum {
    the_or,
    the_xor,
    the_and,

    pub fn doOp(self: Op, in_1: u8, in_2: u8) !u8 {
        return switch (self) {
            Op.the_or => in_1 | in_2,
            Op.the_xor => in_1 ^ in_2,
            Op.the_and => in_1 & in_2,
        };
    }
    pub fn print(self: Op) void {
        switch (self) {
            Op.the_or => std.debug.print("OR", .{}),
            Op.the_xor => std.debug.print("XOR", .{}),
            Op.the_and => std.debug.print("AND", .{}),
        }
    }
};

const Node = struct {
    id: []const u8,
    value: ?u1 = null,
};

const Transition = struct {
    from_1: *Node,
    from_2: *Node,
    op: Op,
    to: *Node,
};

pub fn printNode(n: *Node) void {
    std.debug.print("{s}({?})", .{ n.id, n.value });
}

pub fn printTransition(t: *const Transition) void {
    std.debug.print("Transition: \n", .{});
    printNode(t.from_1);
    printNode(t.from_2);
    std.debug.print("\n", .{});
    std.debug.print("Op: ", .{});
    t.op.print();
    std.debug.print("\n", .{});
    printNode(t.to);
    std.debug.print("\n", .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const state = try readInputState(allocator);
    std.debug.print("{any}", .{state});

    const nodes = try readNodes(allocator);
    const transitions = try readTransitions(allocator, nodes);

    var inTransitions = std.StringHashMap(*const Transition).init(allocator);
    var targets = std.ArrayList(*const Transition).init(allocator);
    for (transitions) |t| {
        try inTransitions.put(t.to.id, &t);
        if (t.to.id[0] == 'z') {
            try targets.append(&t);
        }
        std.debug.print("Transitions Loop: ", .{});
        printTransition(&t);
    }

    var valIte = inTransitions.valueIterator();
    while (valIte.next()) |t| {
        std.debug.print("TMap Loop: ", .{});
        printTransition(t.*);
    }

    for (targets.items) |t| {
        std.debug.print("Targets loop: ", .{});
        printTransition(t);
    }
}
