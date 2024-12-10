const std = @import("std");

const Ops = enum {
    plus,
    mult,

    pub fn doOp(self: Ops, o1: usize, o2: usize) usize {
        if (self == Ops.plus) {
            return o1 + o2;
        } else if (self == Ops.mult) {
            return o1 * o2;
        }
    }
};

const Equation = struct {
    result: usize,
    operands: std.ArrayList(usize),
    ops: std.ArrayList(Ops),
    mutateState: usize,

    fn calc(self: Equation) usize {
        var result: usize = 0;
        for (0..(self.operands.items.len - 1)) |idx| {
            const value1 = self.operands[idx];
            const value2 = self.operands[idx + 1];
            const op = self.ops[idx];
            result += op.doOp(value1, value2);
        }
        return result;
    }

    fn permutateOps(self: Equation) bool {
        if (self.mutateState == self.ops.len) {
            return false;
        }
        return true;
    }

    pub fn solve(self: Equation) EquationError!usize {
        for (1..(self.operands.items.len)) |i| {
            std.debug.print("Adding initial op #{}", .{i});
            self.ops.append(Ops.plus{});
        }
        var res = self.calc();
        if (res == self.result) {
            return self.result;
        }
        while (self.permutateOps()) {
            res = self.calc();
            if (res == self.result) {
                return self.result;
            }
        }
        if (res != self.result) return EquationError.NoResultError;
    }
};

const EquationError = error{
    NoResultError,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var equations = std.ArrayList(Equation).init(allocator);

    var arr = std.ArrayList(u8).init(allocator);
    while (true) {
        reader.streamUntilDelimiter(arr.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        var equation: Equation = .{
            .result = 0,
            .operands = std.ArrayList(usize).init(allocator),
            .ops = std.ArrayList(Ops).init(allocator),
            .mutateState = 0,
        };

        var currentValue = std.ArrayList(u8).init(allocator);
        for (arr.items) |x| {
            if (x == ':') {
                const intValue: usize = try std.fmt.parseInt(usize, currentValue.items, 10);
                equation.result = intValue;
                currentValue.clearRetainingCapacity();
                continue;
            } else if (x == ' ') {
                if (currentValue.items.len > 0) {
                    const intValue: usize = try std.fmt.parseInt(usize, currentValue.items, 10);
                    try equation.operands.append(intValue);
                    currentValue.clearRetainingCapacity();
                }
                continue;
            } else if (x == '\n') {
                continue;
            }
            try currentValue.append(x);
        }

        try equations.append(equation);
        arr.clearRetainingCapacity();
    }

    var sum: usize = 0;
    for (equations.items) |eq| {
        const result: usize = eq.solve() catch |err| {
            if (err == EquationError.NoResultError) {
                sum += 0;
            }
        };
        sum += result;
    }

    std.debug.print("Equations read: {any}", .{sum});
}
