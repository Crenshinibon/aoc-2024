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

pub fn printPath(p: *std.StringHashMap(Node)) void {
    var ite = p.iterator();
    var counter: usize = 0;
    while (ite.next()) |pair| {
        std.debug.print("{} {s} {any}\n", .{ counter, pair.key_ptr.*, pair.value_ptr.* });
        counter += 1;
    }
}

const Cheat = struct {
    target: []const u8,
};

const Pos = struct {
    r: usize,
    c: usize,
};

const Node = struct {
    pos: Pos,
    dist: usize,
    cheats: ?[]Cheat,
};

pub fn key(pos: Pos, allocator: std.mem.Allocator) ![]const u8 {
    const buf: []u8 = try allocator.alloc(u8, 7);
    return try std.fmt.bufPrint(buf, "{}-{}", .{ pos.r, pos.c });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    std.debug.print("Starting", .{});

    var mat: [DIM][DIM]u8 = undefined;
    var row: usize = 0;
    var col: usize = 0;

    var path = std.StringHashMap(Node).init(allocator);
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

        mat[col][row] = c;
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
    // 1 - up; 2 - down; 3 - left; 4 - right;
    var prevDir: usize = 0;
    while (true) {
        const k = try key(current, allocator);
        var currentNode = Node{
            .pos = current,
            .dist = dist,
            .cheats = null,
        };

        mat[current.r][current.c] = 'O';
        // go all the way up up
        if (mat[current.r][current.c - 1] == '.') {
            prevDir = 1;
            current = Pos{ .c = current.c - 1, .r = current.r };
        } else if (mat[current.r][current.c + 1] == '.') {
            //std.debug.print("Going down\n", .{});
            prevDir = 2;
            current = Pos{ .c = current.c + 1, .r = current.r };
        } else if (mat[current.r - 1][current.c] == '.') {
            //std.debug.print("Going left\n", .{});
            prevDir = 3;
            current = Pos{ .c = current.c, .r = current.r - 1 };
        } else if (mat[current.r + 1][current.c] == '.') {
            //std.debug.print("Going right\n", .{});
            prevDir = 4;
            current = Pos{ .c = current.c, .r = current.r + 1 };
        } else {
            std.debug.print("End reached {} {}\n", .{ current.r, current.c });
            break;
            // must be the end
        }

        if (mat[current.r][current.c - 1] == '#' and prevDir == 1) {
            var cheatDist: usize = 2;
            var cheatList = std.ArrayList(Cheat).init(allocator);
            while (cheatDist < current.c) {
                const cCol = current.c - cheatDist;
                const cRow = current.r;
                if (mat[cRow][cCol] == '.') {
                    //cheat found
                    const cheatTarget = try key(Pos{ .c = cCol, .r = cRow }, allocator);
                    try cheatList.append(Cheat{ .target = cheatTarget });
                }
                cheatDist += 1;
            }
            currentNode.cheats = try cheatList.toOwnedSlice();
        } else if (mat[current.r][current.c + 1] == '#' and prevDir == 2) {
            var cheatDist: usize = 2;
            var cheatList = std.ArrayList(Cheat).init(allocator);
            while (cheatDist < DIM) {
                const cCol = current.c + cheatDist;
                const cRow = current.r;
                if (mat[cRow][cCol] == '.') {
                    //cheat found
                    const cheatTarget = try key(Pos{ .c = cCol, .r = cRow }, allocator);
                    try cheatList.append(Cheat{ .target = cheatTarget });
                }
                cheatDist += 1;
            }
            currentNode.cheats = try cheatList.toOwnedSlice();
        } else if (mat[current.r - 1][current.c] == '#' and prevDir == 3) {
            var cheatDist: usize = 2;
            var cheatList = std.ArrayList(Cheat).init(allocator);
            while (cheatDist < current.r) {
                const cRow = current.r - cheatDist;
                const cCol = current.c;
                if (mat[cRow][cCol] == '.') {
                    //cheat found
                    const cheatTarget = try key(Pos{ .c = cCol, .r = cRow }, allocator);
                    try cheatList.append(Cheat{ .target = cheatTarget });
                }
                cheatDist += 1;
            }
            currentNode.cheats = try cheatList.toOwnedSlice();
        } else if (mat[current.r + 1][current.c] == '#' and prevDir == 4) {
            var cheatDist: usize = 2;
            var cheatList = std.ArrayList(Cheat).init(allocator);
            while (cheatDist < DIM) {
                const cRow = current.r + cheatDist;
                const cCol = current.c;
                if (mat[cRow][cCol] == '.') {
                    //cheat found
                    const cheatTarget = try key(Pos{ .c = cCol, .r = cRow }, allocator);
                    try cheatList.append(Cheat{ .target = cheatTarget });
                }
                cheatDist += 1;
            }
            currentNode.cheats = try cheatList.toOwnedSlice();
        }

        try path.put(k, currentNode);
        dist += 1;
    }

    printMat(&mat);
    printPath(&path);
    //
    //const buf: []u8 = try allocator.alloc(u8, 7);
    //        errdefer allocator.free(buf);
    //        const key = try std.fmt.bufPrint(buf, "{}-{}", .{col, row});
    //        path.put(key, Node{
    //            .c = col,
    //            .r = row,
    //            .
    //        });
    //
    //
}
