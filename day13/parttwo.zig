const std = @import("std");
const input = @embedFile("./input.txt");

const Game = struct {
    a_x: isize,
    a_y: isize,
    b_x: isize,
    b_y: isize,
    p_x: isize,
    p_y: isize,
};

pub fn parseValues(values_str: []const u8, shift_one: bool) ![2]isize {
    var values_ite = std.mem.tokenizeScalar(u8, values_str, ',');

    const x_str = values_ite.next().?;
    const y_str = values_ite.next().?;

    var x_sub: []const u8 = undefined;
    var y_sub: []const u8 = undefined;

    if (shift_one) {
        x_sub = x_str[2..];
        y_sub = y_str[3..];
    } else {
        x_sub = x_str[1..];
        y_sub = y_str[2..];
    }

    var x: isize = try std.fmt.parseInt(isize, x_sub, 10);
    var y: isize = try std.fmt.parseInt(isize, y_sub, 10);

    if (shift_one) {
        // x = x;
        // y = y;
        x += 10_000_000_000_000;
        y += 10_000_000_000_000;
    }

    return .{ x, y };
}

pub fn printGame(g: Game) void {
    std.debug.print("Game: \n", .{});
    std.debug.print("Button A: x{} y{}\n", .{ g.a_x, g.a_y });
    std.debug.print("Button B: x{} y{}\n", .{ g.b_x, g.b_y });
    std.debug.print("Prize: x{} y{}\n\n", .{ g.p_x, g.p_y });
}

pub fn printMatrix(m: [2][3]f64) void {
    std.debug.print("Matrix: \n", .{});
    std.debug.print("{}\t\t {}\t\t | {}\n", .{ m[0][0], m[0][1], m[0][2] });
    std.debug.print("{}\t\t {}\t\t | {}\n", .{ m[1][0], m[1][1], m[1][2] });
}

pub fn solveGame(g: Game, allocator: std.mem.Allocator) ![]isize {
    var result = std.ArrayList(isize).init(allocator);

    //transform to math
    const a1: f64 = @floatFromInt(g.a_y);
    const b1: f64 = @floatFromInt(g.b_y);
    const z1: f64 = @floatFromInt(g.p_y);
    const a2: f64 = @floatFromInt(g.a_x);
    const b2: f64 = @floatFromInt(g.b_x);
    const z2: f64 = @floatFromInt(g.p_x);

    var A: [2][3]f64 = .{ .{ a1, b1, z1 }, .{ a2, b2, z2 } };
    //std.debug.print("Initial:\n", .{});
    //printMatrix(A);

    // echelonize
    var factor = A[1][0] / A[0][0];
    A[1][0] = A[1][0] - (A[0][0] * factor);
    A[1][1] = A[1][1] - (A[0][1] * factor);
    A[1][2] = A[1][2] - (A[0][2] * factor);

    //std.debug.print("In echolon form\n", .{});
    //printMatrix(A);

    factor = A[0][1] / A[1][1];
    A[0][1] = A[0][1] - (factor * A[1][1]);
    A[0][2] = A[0][2] - (factor * A[1][2]);

    A[0][2] = A[0][2] / A[0][0];
    A[0][0] = A[0][0] / A[0][0];

    A[1][2] = A[1][2] / A[1][1];
    A[1][1] = A[1][1] / A[1][1];

    //std.debug.print("Finished \n", .{});
    //printMatrix(A);

    const f_a: f64 = A[0][2];
    const f_b: f64 = A[1][2];
    std.debug.print("a: {d:.3} b: {d:.3}\n", .{ f_a, f_b });

    const round_a: f64 = @round(f_a);
    const round_b: f64 = @round(f_b);

    if (@abs(f_a - round_a) > 0.001 or @abs(f_b - round_b) > 0.001) {
        std.debug.print("NO MATCH\n", .{});
    } else {
        const res_a: isize = @intFromFloat(round_a);
        const res_b: isize = @intFromFloat(round_b);
        std.debug.print("Result #A: {} #B: {} \n", .{ res_a, res_b });

        try result.append(res_a * 3 + res_b);
    }

    return result.items;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var ite = std.mem.splitScalar(u8, input, '\n');

    var games = std.ArrayList(Game).init(allocator);

    var in_game = false;
    var current_game: Game = undefined;

    while (ite.next()) |line| {
        if (line.len == 0) {
            if (in_game) {
                try games.append(current_game);

                printGame(current_game);
                in_game = false;

                current_game.p_x = 0;
                current_game.p_y = 0;
                current_game.a_x = 0;
                current_game.a_y = 0;
                current_game.b_x = 0;
                current_game.b_y = 0;
            }
            continue;
        }

        const start_of_line = line[0..8];
        if (std.mem.eql(u8, start_of_line, "Button A")) {
            in_game = true;
            const values_part = line[10..];
            const coord = try parseValues(values_part, false);
            current_game.a_x = coord[0];
            current_game.a_y = coord[1];
        } else if (std.mem.eql(u8, start_of_line, "Button B")) {
            const values_part = line[10..];
            const coord = try parseValues(values_part, false);
            current_game.b_x = coord[0];
            current_game.b_y = coord[1];
        } else if (std.mem.eql(u8, start_of_line, "Prize: X")) {
            const values_part = line[7..];
            const coord = try parseValues(values_part, true);
            current_game.p_x = coord[0];
            current_game.p_y = coord[1];
        }
    }

    var result: isize = 0;
    for (games.items) |g| {
        const wins = try solveGame(g, allocator);
        if (wins.len == 1) {
            result += wins[0];
        } else if (wins.len > 1) {
            std.debug.print("Multiple wins, sorting initial first: {}", .{wins[0]});
            var own_wins = std.ArrayList(isize).init(allocator);
            try own_wins.appendSlice(wins);
            std.mem.sort(isize, own_wins.items, {}, comptime std.sort.desc(isize));
            result += wins[0];
        }
    }

    std.debug.print("Result: {}\n", .{result});
}
