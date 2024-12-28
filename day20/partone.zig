const std = @import("std");
const input = @embedFile("./input.txt");

const DIM = 141;
pub fn printMat(m: *[DIM][DIM]u8) void {
    for (0..DIM) |x| {
        for (0..DIM) |y| {
            std.debug.print("{c}", .{m[x][y]});
        }
        std.debug.print("\n", .{});
    }
}

pub fn printPath(p: *std.ArrayList(Node)) void {
    for (p.items, 0..) |node, counter| {
        std.debug.print("{} {any}\n", .{ counter, node });
    }
}

pub fn printCheats(p: *std.ArrayList(Cheat)) void {
    for (p.items, 0..) |node, counter| {
        std.debug.print("#{} From: {}@{}/{} To {}@{}/{}  Saving: {}\n", .{
            counter,

            node.from.dist,
            node.from.pos.r,
            node.from.pos.c,

            node.to.dist,
            node.to.pos.r,
            node.to.pos.c,

            node.saving,
        });
    }
}

const Cheat = struct {
    from: Node,
    to: Node,
    saving: usize,
};

const Pos = struct {
    r: usize,
    c: usize,
};

const Node = struct {
    pos: Pos,
    dist: usize,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    std.debug.print("Starting", .{});

    var mat: [DIM][DIM]u8 = undefined;
    var row: usize = 0;
    var col: usize = 0;

    var path = std.ArrayList(Node).init(allocator);
    defer path.deinit();

    var start = Pos{
        .r = 0,
        .c = 0,
    };
    for (input) |c| {
        if (c == '\n') {
            continue;
        }
        if (c == 'S') {
            start.r = row;
            start.c = col;
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

    //build path

    var dist: usize = 0;
    var current = start;
    while (true) {
        const currentNode = Node{
            .pos = current,
            .dist = dist,
        };
        try path.append(currentNode);

        mat[current.r][current.c] = 'O';
        const up = mat[current.r - 1][current.c];
        const down = mat[current.r + 1][current.c];
        const left = mat[current.r][current.c - 1];
        const right = mat[current.r][current.c + 1];
        if (up == '.' or up == 'E') {
            current = Pos{ .c = current.c, .r = current.r - 1 };
        } else if (down == '.' or down == 'E') {
            current = Pos{ .c = current.c, .r = current.r + 1 };
        } else if (left == '.' or left == 'E') {
            current = Pos{ .c = current.c - 1, .r = current.r };
        } else if (right == '.' or right == 'E') {
            current = Pos{ .c = current.c + 1, .r = current.r };
        } else {
            std.debug.print("Stopping at {}/{}\n", .{ current.r, current.c });
            break;
        }

        dist += 1;
    }

    printMat(&mat);
    printPath(&path);

    const cheat_dist: usize = 20;
    const min_cheat_dist: usize = 100;

    var cheats_found = std.ArrayList(Cheat).init(allocator);
    for (path.items, 0..) |node, idx| {
        const sub_list = path.items[(idx + 1)..];
        for (sub_list) |next_node| {
            const cnR: i128 = @intCast(node.pos.r);
            const cnC: i128 = @intCast(node.pos.c);
            const nnR: i128 = @intCast(next_node.pos.r);
            const nnC: i128 = @intCast(next_node.pos.c);

            const cart_dist: usize = @intCast(@abs(cnR - nnR) + @abs(cnC - nnC));
            const saving = next_node.dist - node.dist - cart_dist;
            if (cart_dist > 1 and cart_dist <= cheat_dist and saving >= min_cheat_dist) {
                try cheats_found.append(Cheat{
                    .from = node,
                    .to = next_node,
                    .saving = saving,
                });
            }
        }
    }

    printCheats(&cheats_found);
    std.debug.print("Result: {}\n", .{cheats_found.items.len});
}
