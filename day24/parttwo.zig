const std = @import("std");
const rules_file = @embedFile("./small_r.txt");
const input_file = @embedFile("./small_s.txt");

const Ops = enum {
    the_or,
    the_xor,
    the_and,

    pub fn doOp(self: Ops, in_1: u8, in_2: u8) !u8 {
        if (self == Ops.the_or) {
            return in_1 | in_2;
        } else if (self == Ops.the_xor) {
            return in_1 ^ in_2;
        } else if (self == Ops.the_and) {
            return in_1 & in_2;
        } else unreachable;
    }
};

const Rule = struct {
    in_1: []const u8,
    in_2: []const u8,
    op: Ops,
    next: []const u8,
};

const Value = struct {
    in: []const u8,
    val: u8,
};

const Node = struct {
    id: []const u8,
    val: u8,
    in_1: ?*Node = null,
    in_2: ?*Node = null,
    op: ?Ops = null,
    pub fn calcVal(self: *Node) !u8 {
        if (self.in_1 != null and self.in_2 != null and self.op != null) {
            const v_1 = try self.in_1.?.recalcVal();
            const v_2 = try self.in_2.?.recalcVal();
            self.val = try self.op.?.doCalc(v_1, v_2);
        }
        return self.val;
    }

    pub fn init(id: []const u8, val: u8, allocator: std.mem.Allocator) !*Node {
        var n = try allocator.create(Node);
        n.id = id;
        n.val = val;
        return n;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var rules = std.ArrayList(Rule).init(allocator);
    var r_ite = std.mem.tokenizeScalar(u8, rules_file, '\n');
    while (r_ite.next()) |r_string| {
        var p_ite = std.mem.tokenizeScalar(u8, r_string, ' ');
        const in_1 = p_ite.next().?;
        const ops_string = p_ite.next().?;
        const in_2 = p_ite.next().?;
        //discard arrow
        _ = p_ite.next().?;
        const next = p_ite.next().?;

        var op: Ops = undefined;
        if (std.mem.eql(u8, ops_string, "OR")) {
            op = Ops.the_or;
        } else if (std.mem.eql(u8, ops_string, "XOR")) {
            op = Ops.the_xor;
        } else if (std.mem.eql(u8, ops_string, "AND")) {
            op = Ops.the_and;
        } else unreachable;

        const r = Rule{
            .in_1 = in_1,
            .in_2 = in_2,
            .op = op,
            .next = next,
        };

        try rules.append(r);
    }

    std.debug.print("Read {}# of rules: \n\n", .{rules.items.len});
    for (rules.items) |rule| {
        std.debug.print("{s}-{s} => {s} (Op: {any})\n", .{ rule.in_1, rule.in_2, rule.next, rule.op });
    }

    var nodes = std.StringHashMap(Node).init(allocator);

    var i_ite = std.mem.tokenizeScalar(u8, input_file, '\n');
    var state = std.ArrayList(Value).init(allocator);
    while (i_ite.next()) |i_line| {
        const in = i_line[0..3];
        const value = i_line[5];

        try state.append(.{
            .in = in,
            .val = value - 48,
        });

        const initial_node = try Node.init(in, value - 48, allocator);
        try nodes.put(in, initial_node.*);
    }

    for (state.items) |v| {
        std.debug.print("S: {s} - {}\n", .{ v.in, v.val });
    }

    var ite: usize = 0;
    var found_one = true;
    while (found_one) {
        found_one = false;
        for (0..state.items.len) |idx_1| {
            for (idx_1..state.items.len) |idx_2| {
                const in_1 = state.items[idx_1];
                const in_2 = state.items[idx_2];

                for (rules.items, 0..) |r, idx| {
                    if ((std.mem.eql(u8, r.in_1, in_1.in) and std.mem.eql(u8, r.in_2, in_2.in)) or
                        (std.mem.eql(u8, r.in_2, in_1.in) and std.mem.eql(u8, r.in_1, in_2.in)))
                    {
                        found_one = true;
                        std.debug.print("Found rule: {s}-{s}->{s} \n", .{ r.in_1, r.in_2, r.next });

                        const res = try r.op.doOp(in_1.val, in_2.val);
                        try state.append(.{
                            .in = r.next,
                            .val = res,
                        });

                        var in_n_1 = nodes.get(r.in_1) orelse unreachable;
                        var in_n_2 = nodes.get(r.in_2) orelse unreachable;
                        var n_n = try Node.init(r.next, res, allocator);

                        n_n.in_1 = &in_n_1;
                        n_n.in_2 = &in_n_2;
                        n_n.op = r.op;

                        std.debug.print("NN: {s} i_1: {s} i_2: {s}\n", .{ n_n.id, n_n.in_1.?.id, n_n.in_2.?.id });
                        try nodes.put(r.next, n_n.*);

                        _ = rules.orderedRemove(idx);
                    }
                }
            }
        }
        //one complete iteration didn't find a matching rule
        //
        //std.debug.print("Ite: {} state: \n", .{ite});
        //for (state.items) |v| {
        //    std.debug.print("S: {s} - {}\n", .{ v.in, v.val //});
        //}

        //std.debug.print("Ite: {} rules: \n\n", .{ite});
        //for (rules.items) |rule| {
        //    std.debug.print("{s}-{s} => {s} (Op: {any})\n", .{ rule.in_1, rule.in_2, rule.next, rule.op });
        //}

        ite += 1;
    }

    const z_result = try calc(allocator, &nodes, 'z');
    const x_result = try calc(allocator, &nodes, 'x');
    const y_result = try calc(allocator, &nodes, 'y');

    std.debug.print("z binary: {b} {}\n", .{ z_result, z_result });
    std.debug.print("y binary: {b} {}\n", .{ y_result, y_result });
    std.debug.print("x binary: {b} {}\n", .{ x_result, x_result });
    std.debug.print("sum x y : {b} {}\n", .{ y_result + x_result, y_result + x_result });

    // find z-nodes and build dep-tree
    var nk_ite = nodes.keyIterator();
    var end_nodes = std.ArrayList(Node).init(allocator);
    while (nk_ite.next()) |k| {
        if (k.*[0] == 'z') {
            const node = nodes.get(k.*).?;
            try end_nodes.append(node);
        }
    }

    //std.debug.print("Endnodes: {any}\n", .{end_nodes.items});

    //for(end_nodes.items) | e_n | {
    var e_n = end_nodes.items[0];
    var depending_nodes = std.ArrayList(*Node).init(allocator);
    std.debug.print("e_n: {s}, in_1: {s}, in_2 {s}\n", .{ e_n.id, e_n.in_1.?.id, e_n.in_2.?.id });

    try traverse(&e_n, &depending_nodes);

    for (depending_nodes.items) |n| {
        std.debug.print("n: {s} - ", .{n.id});
    }
    //}
}

fn traverse(node: *Node, collector: *std.ArrayList(*Node)) !void {
    std.debug.print("c: {s} - ", .{node.id});
    if (collector.items.len > 2) {
        return;
    }

    if (node.in_1 != null and node.in_2 != null) {
        std.debug.print("branching 1: {s} - ", .{node.in_1.?.id});
        try collector.append(node.in_1.?);
        try traverse(node.in_1.?, collector);

        std.debug.print("branching 2: {s} - ", .{node.in_2.?.id});
        try collector.append(node.in_2.?);
        try traverse(node.in_2.?, collector);
    }
    return;
}

fn calc(allocator: std.mem.Allocator, nodes: *std.StringHashMap(Node), prefix: u8) !usize {
    var xe = std.ArrayList(Node).init(allocator);
    var ite = nodes.valueIterator();
    while (ite.next()) |v| {
        if (v.id[0] == prefix) {
            try xe.append(v.*);
        }
    }

    std.mem.sort(Node, xe.items, .{}, compareValue);
    var num: usize = 0;
    for (xe.items, 0..) |v, idx| {
        const nv = std.math.pow(usize, 2, idx) * v.val;
        num += nv;
    }

    return num;
}

fn compareValue(_: @TypeOf(.{}), lhs: Node, rhs: Node) bool {
    const lhi = std.fmt.parseInt(usize, lhs.id[1..], 10) catch {
        return true;
    };
    const rhi = std.fmt.parseInt(usize, rhs.id[1..], 10) catch {
        return true;
    };
    return lhi < rhi;
}
