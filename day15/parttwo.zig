const std = @import("std");
const input = @embedFile("./input.txt");
const path = @embedFile("./path.txt");

const DIM = 50;
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

pub fn collectBoxesToMove(m: *[DIM][DIM * 2]u8, box: Box, dir: u8, collected: *std.ArrayList(Box)) !bool {
    try collected.append(box);

    var new_row: usize = 0;
    if (dir == '^') {
        new_row = box.r - 1;
    } else {
        new_row = box.r + 1;
    }
    //std.debug.print("Moving Box r{}/{}-{} to row {}\n", .{ box.r, box.left, box.right, new_row });

    const c_left = m[new_row][box.left];
    const c_right = m[new_row][box.right];

    if (c_left == '#' or c_right == '#') return false;

    //empty above box
    if (c_left == '.' and c_right == '.') {
        return true;
        //new box straight in the middle
    } else if (c_left == '[') {
        const new_box = Box{
            .r = new_row,
            .left = box.left,
            .right = box.right,
        };
        return collectBoxesToMove(m, new_box, dir, collected);
    }
    //new box on the left side
    if (c_left == ']') {
        const new_box = Box{
            .r = new_row,
            .left = box.left - 1,
            .right = box.right - 1,
        };
        const empty = try collectBoxesToMove(m, new_box, dir, collected);
        if (!empty) return false;
    }
    //new box no the right side
    if (c_right == '[') {
        const new_box = Box{
            .r = new_row,
            .left = box.left + 1,
            .right = box.right + 1,
        };
        const empty = try collectBoxesToMove(m, new_box, dir, collected);
        if (!empty) return false;
    }

    return true;
}

const Pos = struct {
    r: usize,
    c: usize,
};

const Box = struct {
    r: usize,
    left: usize,
    right: usize,
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
        //printWMat(&w_mat);
        //std.debug.print("Bot @{}/{} => dir: {c}\n", .{ bot.r, bot.c, dir });

        const bot_next = moveTarget(bot, dir);
        //std.debug.print("Bot Next @{}/{} => dir: {c}\n", .{ bot_next.r, bot_next.c, dir });
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
            var box_2 = Pos{
                .r = box.r,
                .c = box.c + 1,
            };

            try to_move_pot.append(box);
            try to_move_pot.append(box_2);

            while (true) {
                const n_box = Pos{
                    .r = box_2.r,
                    .c = box_2.c + 1,
                };

                const c = w_mat[n_box.r][n_box.c];
                //next is free
                if (c == '.') {
                    can_move = true;
                    break;
                }
                // next is another box
                else if (c == '[') {
                    box = n_box;
                    box_2 = Pos{
                        .c = box.c + 1,
                        .r = box.r,
                    };
                    try to_move_pot.append(box);
                    try to_move_pot.append(box_2);
                    continue;
                }
                // next is a wall
                else if (c == '#') {
                    break;
                }
            }
            if (can_move) {
                const b_size = to_move_pot.items.len;
                for (0..b_size) |m_idx| {
                    const t_m_b = to_move_pot.items[b_size - 1 - m_idx];
                    w_mat[t_m_b.r][t_m_b.c + 1] = w_mat[t_m_b.r][t_m_b.c];
                }
                w_mat[bot_next.r][bot_next.c] = '@';
                w_mat[bot.r][bot.c] = '.';
                bot = bot_next;
            }
        } else if (char_next == ']' and dir == '<') {
            var can_move = false;
            var to_move_pot = std.ArrayList(Pos).init(allocator);
            defer to_move_pot.deinit();

            var box = bot_next;
            var box_2 = Pos{
                .r = box.r,
                .c = box.c - 1,
            };

            try to_move_pot.append(box);
            try to_move_pot.append(box_2);

            while (true) {
                const n_box = Pos{
                    .r = box_2.r,
                    .c = box_2.c - 1,
                };

                const c = w_mat[n_box.r][n_box.c];
                //next is free
                if (c == '.') {
                    can_move = true;
                    break;
                }
                // next is another box
                else if (c == ']') {
                    box = n_box;
                    box_2 = Pos{
                        .c = box.c - 1,
                        .r = box.r,
                    };
                    try to_move_pot.append(box);
                    try to_move_pot.append(box_2);
                    continue;
                }
                // next is a wall
                else if (c == '#') {
                    break;
                }
            }
            if (can_move) {
                const b_size = to_move_pot.items.len;
                for (0..b_size) |m_idx| {
                    const t_m_b = to_move_pot.items[b_size - 1 - m_idx];
                    w_mat[t_m_b.r][t_m_b.c - 1] = w_mat[t_m_b.r][t_m_b.c];
                }

                w_mat[bot_next.r][bot_next.c] = '@';
                w_mat[bot.r][bot.c] = '.';
                bot = bot_next;
            }
        } else if ((char_next == ']' or char_next == '[') and (dir == '^' or dir == 'v')) {
            var box: Box = undefined;
            var bot_2: Pos = undefined;

            if (char_next == ']') {
                box = Box{
                    .left = bot_next.c - 1,
                    .right = bot_next.c,
                    .r = bot_next.r,
                };
                bot_2 = Pos{
                    .c = bot_next.c - 1,
                    .r = bot_next.r,
                };
            } else {
                box = Box{
                    .left = bot_next.c,
                    .right = bot_next.c + 1,
                    .r = bot_next.r,
                };
                bot_2 = Pos{
                    .c = bot_next.c + 1,
                    .r = bot_next.r,
                };
            }

            var to_move_pot = std.ArrayList(Box).init(allocator);
            defer to_move_pot.deinit();
            const can_move = try collectBoxesToMove(&w_mat, box, dir, &to_move_pot);

            if (can_move) {
                for (to_move_pot.items) |o_box| {
                    //remove old box
                    w_mat[o_box.r][o_box.left] = '.';
                    w_mat[o_box.r][o_box.right] = '.';
                }
                for (to_move_pot.items) |o_box| {
                    var new_row: usize = 0;
                    if (dir == '^') {
                        new_row = o_box.r - 1;
                    } else {
                        new_row = o_box.r + 1;
                    }
                    const n_box = Box{
                        .r = new_row,
                        .left = o_box.left,
                        .right = o_box.right,
                    };
                    //draw new box
                    w_mat[n_box.r][n_box.left] = '[';
                    w_mat[n_box.r][n_box.right] = ']';
                }
                w_mat[bot.r][bot.c] = '.';

                w_mat[bot_2.r][bot_2.c] = '.';
                w_mat[bot_next.r][bot_next.c] = '@';

                bot = bot_next;
            } else {
                continue;
            }
        }
    }

    printWMat(&w_mat);

    var counter: usize = 0;
    var result: usize = 0;
    for (0..DIM) |r| {
        for (0..(DIM * 2)) |c| {
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
