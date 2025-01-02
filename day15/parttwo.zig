const std = @import("std");
const input = @embedFile("./small.txt");
const path = @embedFile("./small_p.txt");

const DIM = 10;
pub fn printMat(m: *[DIM][DIM]u8) void {
    for (0..DIM) |r| {
        for (0..DIM) |c| {
            std.debug.print("{c}", .{m[r][c]});
        }
        std.debug.print("\n", .{});
    }
}

pub fn widenMat(m: *[DIM][DIM]u8) [DIM][DIM * 2]u8 {
    var out: [DIM][DIM * 2]u8 = undefined;

    for (0..DIM) |r| {
        for (0..DIM) |c| {
            if (m[r][c] == 'O') {
                out[r][c * 2] = '[';
                out[r][c * 2 + 1] = ']';
            } else if (m[r][c] == '@') {
                out[r][c * 2] = '@';
                out[r][c * 2 + 1] = '.';
            } else {
                out[r][c * 2] = m[r][c];
                out[r][c * 2 + 1] = m[r][c];
            }
        }
    }
    return out;
}

pub fn printWMat(m: *[DIM][DIM * 2]u8) void {
    for (0..DIM) |r| {
        for (0..(DIM * 2)) |c| {
            std.debug.print("{c}", .{m[r][c]});
        }
        std.debug.print("\n", .{});
    }
}

const Pos = struct {
    r: usize,
    c: usize,
};

pub fn moveTarget(cur: Pos, dir: u8) Pos {
    if (dir == '^') {
        if (cur.r == 0) {
            return cur;
        }
        return Pos{
            .r = cur.r - 1,
            .c = cur.c,
        };
    } else if (dir == 'v') {
        if (cur.r + 1 == DIM) {
            return cur;
        }
        return Pos{
            .r = cur.r + 1,
            .c = cur.c,
        };
    } else if (dir == '>') {
        if (cur.c + 1 == (DIM * 2)) {
            return cur;
        }
        return Pos{
            .r = cur.r,
            .c = cur.c + 1,
        };
    } else if (dir == '<') {
        if (cur.c == 0) {
            return cur;
        }
        return Pos{
            .r = cur.r,
            .c = cur.c - 1,
        };
    } else unreachable;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    std.debug.print("Starting", .{});

    var mat: [DIM][DIM]u8 = undefined;
    var row: usize = 0;
    var col: usize = 0;

    for (input) |c| {
        if (c == '\n') {
            continue;
        }
        mat[row][col] = c;
        if (col == (DIM - 1)) {
            row += 1;
            col = 0;
        } else {
            col += 1;
        }
    }
    printMat(&mat);

    var w_mat: [DIM][DIM * 2]u8 = widenMat(&mat);
    printWMat(&w_mat);

    var bot: Pos = undefined;
    outer: for (0..DIM) |r| {
        for (0..(DIM * 2)) |c| {
            if (w_mat[r][c] == '@') {
                std.debug.print("Found bot @ {}/{}\n", .{ r, c });
                bot.r = r;
                bot.c = c;
                break :outer;
            }
        }
    }
    var directions = std.ArrayList(u8).init(allocator);
    for (path) |c| {
        if (c == '\n') {
            continue;
        } else {
            try directions.append(c);
        }
    }

    for (directions.items) |dir| {
        printWMat(&w_mat);
        std.debug.print("Bot @{}/{} => dir: {c}\n", .{ bot.r, bot.c, dir });

        const bot_next = moveTarget(bot, dir);
        std.debug.print("Bot Next @{}/{} => dir: {c}\n", .{ bot_next.r, bot_next.c, dir });
        const char_next = w_mat[bot_next.r][bot_next.c];

        //    //it's empty
        if (char_next == '.') {
            //draw it
            w_mat[bot.r][bot.c] = '.';
            w_mat[bot_next.r][bot_next.c] = '@';
            bot = bot_next;
            continue;
            //hit a wall, do nothing
        } else if (char_next == '#') {
            continue;
            //it's a box
        } else if (char_next == '[' and dir == '>') {
            var can_move = false;
            var to_move_pot = std.ArrayList(Pos).init(allocator);
            defer to_move_pot.deinit();

            var box = bot_next;
            try to_move_pot.append(box);

            while (true) {}
            if (can_move) {}
        } else if (char_next == ']' and dir == '<') {

            // generalize maybe
        } else if (char_next == ']' and dir == '^') {} else if (char_next == ']' and dir == 'v') {} else if (char_next == '[' and dir == '^') {} else if (char_next == '[' and dir == 'v') {}

        //look ahead if moving or not
        var box = bot_next;
        var box_2: Pos = undefined;
        if (char_next == ']') {
            box_2 = Pos{
                .c = box.c - 1,
                .r = box.r,
            };
        } else {
            box_2 = Pos{
                .c = box.c + 1,
                .r = box.r,
            };
        }

        var can_move = false;
        var to_move_pot = std.ArrayList(Pos).init(allocator);
        try to_move_pot.append(box);
        try to_move_pot.append(box_2);

        defer to_move_pot.deinit();

        while (true) {
            if (dir == '<' or dir == '>') {
                var box_next: Pos = undefined;
                if (char_next == ']') {
                    box_next = moveTarget(box_2, dir);
                } else {
                    box_next = moveTarget(box, dir);
                }
            } else {
                const box_next = moveTarget(box, dir);
                const box_next_2 = moveTarget(box_2, dir);
                if (w_mat[box_next.r][box_next.c] == '#' or w_mat[box_next_2.r][box_next_2.c] == '#') {
                    break;
                } else if (w_mat[box_next.r][box_next.c] == '.' and w_mat[box_next_2.r][box_next_2.c] == '.') {
                    can_move = true;
                    break;
                } else if (w_mat[box_next.r][box_next.c] == ']' or
                    w_mat[box_next.r][box_next.c] == '[' or
                    w_mat[box_next_2.r][box_next_2.c] == ']' or
                    w_mat[box_next_2.r][box_next_2.c] == '[')
                {
                    try to_move_pot.append(box_next);
                    try to_move_pot.append(box_next_2);

                    box = box_next;
                    box_2 = box_next_2;
                } else {
                    printWMat(&w_mat);
                    std.debug.print("Unreachable {any} {any} => {c} / {c}\n", .{ box_next, box_next_2, w_mat[box_next.r][box_next.c], w_mat[box_next_2.r][box_next_2.c] });
                    unreachable;
                }
            }
        }

        if (can_move) {
            for (to_move_pot.items) |m_box| {
                const c = w_mat[m_box.r][m_box.c];
                const n_b = moveTarget(m_box, dir);
                w_mat[n_b.r][n_b.c] = c;
            }
            w_mat[bot.r][bot.c] = '.';
            w_mat[bot_next.r][bot_next.c] = '@';
            bot = bot_next;
        } else {
            continue;
        }
    }
    printWMat(&w_mat);

    var counter: usize = 0;
    var result: usize = 0;
    for (0..DIM) |r| {
        for (0..DIM) |c| {
            if (w_mat[r][c] == '[') {
                counter += 1;
                const gps = 100 * r + c;
                result += gps;
                std.debug.print("Box #{} @ {}/{} => {} total: {}\n", .{ counter, r, c, gps, result });
            }
        }
    }

    std.debug.print("Result: {}\n", .{result});
}
