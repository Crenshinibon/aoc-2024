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

    const x: isize = try std.fmt.parseInt(isize, x_sub, 10);
    const y: isize = try std.fmt.parseInt(isize, y_sub, 10);

    //std.debug.print("{s} - {s} => {} {}\n", .{ x_str[1..], y_str[2..], x, y });

    return .{ x, y };
}

pub fn printGame(g: Game) void {
    std.debug.print("Game: \n", .{});
    std.debug.print("Button A: x{} y{}\n", .{ g.a_x, g.a_y });
    std.debug.print("Button B: x{} y{}\n", .{ g.b_x, g.b_y });
    std.debug.print("Prize: x{} y{}\n\n", .{ g.p_x, g.p_y });
}

pub fn solveGame(g: Game, allocator: std.mem.Allocator) ![]isize {
    var result = std.ArrayList(isize).init(allocator);

    var count_a: isize = 0;
    var count_b: isize = 0;
    while (count_a < 201) {
        while (count_b < 201) {
            const pos_x = (g.b_x * count_b) + (g.a_x * count_a);
            const pos_y = (g.b_y * count_b) + (g.a_y * count_a);
            //std.debug.print("a{} b{} => {}/{} => {}/{}\n", .{ count_a, count_b, pos_x, pos_y, g.p_x, g.p_y });

            if (pos_x == g.p_x and pos_y == g.p_y) {
                std.debug.print("Found result: @x{}/y{} with {} A and {} B\n", .{ pos_x, pos_y, count_a, count_b });
                try result.append(count_a * 3 + count_b);
            }

            count_b += 1;
        }
        count_a += 1;
        count_b = 0;
    }

    //count_a = 0;
    //count_b = 0;
    //while (count_b < 201) {
    //    while (count_a < 201) {
    //        const pos_x = (g.b_x * count_b) + (g.a_x * count_a);
    //        const pos_y = (g.b_y * count_b) + (g.a_y * count_a);
    //        std.debug.print("a{} b{} => {}/{} => {}/{}\n", .{ count_a, count_b, pos_x, pos_y, g.p_x, g.p_y });

    //        if (pos_x == g.p_x and pos_y == g.p_y) {
    //            std.debug.print("Found result: @x{}/y{} with {} A and {} B", .{ pos_x, pos_y, count_a, count_b });
    //            try result.append(count_a * 3 + count_b);
    //        }

    //        count_a += 1;
    //    }
    //    count_b += 1;
    //}

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
