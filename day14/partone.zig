const std = @import("std");
const input = @embedFile("./input.txt");
const DIM_X = 101;
const DIM_Y = 103;

const Bot = struct {
    x: isize,
    y: isize,
    v_x: isize,
    v_y: isize,
};

const Errors = error{Unparsable};

pub fn parseValues(values_str: ?[]const u8) ![2]isize {
    if (values_str == null) return Errors.Unparsable;
    var values_ite = std.mem.tokenizeScalar(u8, values_str.?, ',');

    const x_str = values_ite.next().?;
    const y_str = values_ite.next().?;

    const x_sub: []const u8 = x_str[2..];
    const y_sub: []const u8 = y_str;

    const x: isize = try std.fmt.parseInt(isize, x_sub, 10);
    const y: isize = try std.fmt.parseInt(isize, y_sub, 10);

    //std.debug.print("{s} - {s} => {} {}\n", .{ x_str[1..], y_str[2..], x, y });

    return .{ x, y };
}

pub fn printMatrix(bots: []Bot, hide_lines: bool) void {
    std.debug.print("M: \n", .{});
    for (0..DIM_Y) |y| {
        std.debug.print("|", .{});
        for (0..DIM_X) |x| {
            var count: usize = 0;
            for (bots) |b| {
                if (b.x == x and b.y == y) {
                    count += 1;
                }
            }
            if (hide_lines and (y == DIM_Y / 2 or x == DIM_X / 2)) {
                std.debug.print(" |", .{});
            } else {
                std.debug.print("{}|", .{count});
            }
        }
        std.debug.print("\n", .{});
    }
}

pub fn countBots(bots: []Bot) [4]usize {
    var count_1: usize = 0;
    var count_2: usize = 0;
    var count_3: usize = 0;
    var count_4: usize = 0;

    for (0..DIM_Y) |y| {
        for (0..DIM_X) |x| {
            var count: usize = 0;
            for (bots) |b| {
                if (b.x == x and b.y == y) {
                    count += 1;
                }
            }
            if (x < DIM_X / 2) {
                if (y < DIM_Y / 2) {
                    count_1 += count;
                } else if (y > DIM_Y / 2) {
                    count_2 += count;
                }
            } else if (x > DIM_X / 2) {
                if (y < DIM_Y / 2) {
                    count_3 += count;
                } else if (y > DIM_Y / 2) {
                    count_4 += count;
                }
            }
        }
    }
    return .{ count_1, count_2, count_3, count_4 };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var ite = std.mem.tokenizeScalar(u8, input, '\n');
    var bots = std.ArrayList(Bot).init(allocator);
    while (ite.next()) |line| {
        var botIte = std.mem.tokenizeScalar(u8, line, ' ');

        const position: [2]isize = try parseValues(botIte.next());
        const velocity: [2]isize = try parseValues(botIte.next());

        try bots.append(.{
            .x = position[0],
            .y = position[1],
            .v_x = velocity[0],
            .v_y = velocity[1],
        });
    }
    printMatrix(bots.items, false);

    for (0..100) |iteration| {
        std.debug.print("Ite: {}\n", .{iteration});
        //reposition bots
        for (bots.items, 0..) |b, idx| {
            var n_x = b.x + b.v_x;
            while (n_x >= DIM_X) {
                n_x -= DIM_X;
            }
            while (n_x < 0) {
                n_x += DIM_X;
            }

            var n_y = b.y + b.v_y;
            while (n_y >= DIM_Y) {
                n_y -= DIM_Y;
            }
            while (n_y < 0) {
                n_y += DIM_Y;
            }

            const n_b = Bot{
                .x = n_x,
                .y = n_y,
                .v_x = b.v_x,
                .v_y = b.v_y,
            };

            try bots.replaceRange(idx, 1, &.{n_b});
        }
        //std.debug.print("Bots {any}\n", .{bots.items});
        //printMatrix(bots.items, false);
    }

    //std.debug.print("BOT: {any}", .{b});
    printMatrix(bots.items, false);
    const bots_c = countBots(bots.items);
    std.debug.print("Q counts: {any}\n", .{bots_c});
    const result = bots_c[0] * bots_c[1] * bots_c[2] * bots_c[3];
    //for (games.items) |g| {
    //    const wins = try solveGame(g, allocator);
    //    if (wins.len == 1) {
    //        result += wins[0];
    //    } else if (wins.len > 1) {
    //        std.debug.print("Multiple wins, sorting initial first: {}", .{wins[0]});
    //        var own_wins = std.ArrayList(isize).init(allocator);
    //        try own_wins.appendSlice(wins);
    //        std.mem.sort(isize, own_wins.items, {}, comptime std.sort.desc(isize));
    //        result += wins[0];
    //    }
    //}

    std.debug.print("Result: {}\n", .{result});
}
