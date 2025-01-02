const std = @import("std");
const input = @embedFile("./input.txt");
const path = @embedFile("./path.txt");

const DIM = 50;
pub fn printMat(m: *[DIM][DIM]u8) void {
    for (0..DIM) |x| {
        for (0..DIM) |y| {
            std.debug.print("{c}", .{m[x][y]});
        }
        std.debug.print("\n", .{});
    }
}

const Pos = struct {
    r: usize,
    c: usize,
};

pub fn move_target(cur: Pos, dir: u8) Pos {
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
        if (cur.c + 1 == DIM) {
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

    var bot: Pos = undefined;
    for (input) |c| {
        if (c == '\n') {
            continue;
        }
        if (c == '@') {
            bot.r = row;
            bot.c = col;
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

    var directions = std.ArrayList(u8).init(allocator);
    for (path) |c| {
        if (c == '\n') {
            continue;
        } else {
            try directions.append(c);
        }
    }

    for (directions.items) |dir| {
        //printMat(&mat);
        //std.debug.print("Bot @{}/{} => dir: {c}\n", .{ bot.r, bot.c, dir });

        const bot_next = move_target(bot, dir);
        const char_next = mat[bot_next.r][bot_next.c];

        //it's empty
        if (char_next == '.') {
            //draw it
            mat[bot.r][bot.c] = '.';
            mat[bot_next.r][bot_next.c] = '@';
            bot = bot_next;
            continue;
            //hit a wall, do nothing
        } else if (char_next == '#') {
            continue;
            //it's a box
        } else if (char_next == 'O') {
            //look ahead if moving or not
            var box = bot_next;
            var can_move = false;
            var to_move_pot = std.ArrayList(Pos).init(allocator);
            try to_move_pot.append(box);
            defer to_move_pot.deinit();

            while (true) {
                const box_next = move_target(box, dir);
                if (mat[box_next.r][box_next.c] == '#') {
                    break;
                } else if (mat[box_next.r][box_next.c] == '.') {
                    can_move = true;
                    break;
                } else if (mat[box_next.r][box_next.c] == 'O') {
                    try to_move_pot.append(box_next);
                    box = box_next;
                } else unreachable;
            }

            if (can_move) {
                for (to_move_pot.items) |m_box| {
                    const n_b = move_target(m_box, dir);
                    mat[n_b.r][n_b.c] = 'O';
                }
                mat[bot.r][bot.c] = '.';
                mat[bot_next.r][bot_next.c] = '@';
                bot = bot_next;
            } else {
                continue;
            }
        }
    }
    printMat(&mat);

    var counter: usize = 0;
    var result: usize = 0;
    for (0..DIM) |r| {
        for (0..DIM) |c| {
            if (mat[r][c] == 'O') {
                counter += 1;
                const gps = 100 * r + c;
                result += gps;
                std.debug.print("Box #{} @ {}/{} => {} total: {}\n", .{ counter, r, c, gps, result });
            }
        }
    }

    std.debug.print("Result: {}\n", .{result});
}
