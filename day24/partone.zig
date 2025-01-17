const std = @import("std");
const rules_file = @embedFile("./input_r.txt");
const input_file = @embedFile("./input_s.txt");

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

    var i_ite = std.mem.tokenizeScalar(u8, input_file, '\n');
    var state = std.ArrayList(Value).init(allocator);
    while (i_ite.next()) |i_line| {
        const in = i_line[0..3];
        const value = i_line[5];

        try state.append(.{
            .in = in,
            .val = value - 48,
        });
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

                        _ = rules.orderedRemove(idx);
                    }
                }
            }
        }
        //one complete iteration didn't find a matching rule
        //
        std.debug.print("Ite: {} state: \n", .{ite});
        for (state.items) |v| {
            std.debug.print("S: {s} - {}\n", .{ v.in, v.val });
        }

        std.debug.print("Ite: {} rules: \n\n", .{ite});
        for (rules.items) |rule| {
            std.debug.print("{s}-{s} => {s} (Op: {any})\n", .{ rule.in_1, rule.in_2, rule.next, rule.op });
        }

        ite += 1;
    }

    var result = std.ArrayList(Value).init(allocator);
    std.debug.print("Final complete state\n", .{});
    for (state.items) |v| {
        std.debug.print("S: {s} - {}\n", .{ v.in, v.val });
        if (v.in[0] == 'z') {
            try result.append(v);
        }
    }

    std.debug.print("Final Rules:\n", .{});
    for (rules.items) |rule| {
        std.debug.print("{s}-{s} => {s} (Op: {any})\n", .{ rule.in_1, rule.in_2, rule.next, rule.op });
    }

    std.debug.print("Found Zs\n", .{});
    for (result.items) |v| {
        std.debug.print("R: {s} - {}\n", .{ v.in, v.val });
    }

    std.mem.sort(Value, result.items, .{}, compareValue);

    std.debug.print("Sorted Zs\n", .{});
    for (result.items) |v| {
        std.debug.print("R: {s} - {}\n", .{ v.in, v.val });
    }

    var num: usize = 0;
    for (result.items, 0..) |v, idx| {
        const nv = std.math.pow(usize, 2, idx) * v.val;
        num += nv;
    }

    std.debug.print("binarynumber: {b} {}\n", .{ num, num });
}

fn compareValue(_: @TypeOf(.{}), lhs: Value, rhs: Value) bool {
    const lhi = std.fmt.parseInt(usize, lhs.in[1..], 10) catch {
        return true;
    };
    const rhi = std.fmt.parseInt(usize, rhs.in[1..], 10) catch {
        return true;
    };
    return lhi < rhi;
}
