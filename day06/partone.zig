const std = @import("std");

const GuardLeftMap = error{LeftMap};

const Direction = enum { up, right, down, left };

const Guard = struct {
    r: usize,
    c: usize,
    dir: Direction,
};

pub fn walk(g: Guard, m: *[130][130]u8) GuardLeftMap!Guard {
    var newGuard: Guard = undefined;
    if (g.dir == Direction.up) {
        if (g.r == 0) return GuardLeftMap.LeftMap;
        const newR = g.r - 1;
        const obs = m[newR][g.c] == '#';
        if (obs) {
            newGuard = .{ .r = g.r, .c = g.c, .dir = Direction.right };
        } else {
            newGuard = .{ .r = newR, .c = g.c, .dir = g.dir };
        }
    } else if (g.dir == Direction.right) {
        if (g.c == 129) return GuardLeftMap.LeftMap;
        const newC = g.c + 1;
        const obs = m[g.r][newC] == '#';
        if (obs) {
            newGuard = .{ .r = g.r, .c = g.c, .dir = Direction.down };
        } else {
            newGuard = .{ .r = g.r, .c = newC, .dir = g.dir };
        }
    } else if (g.dir == Direction.down) {
        if (g.r == 129) return GuardLeftMap.LeftMap;
        const newR = g.r + 1;
        const obs = m[newR][g.c] == '#';
        if (obs) {
            newGuard = .{ .r = g.r, .c = g.c, .dir = Direction.left };
        } else {
            newGuard = .{ .r = newR, .c = g.c, .dir = g.dir };
        }
    } else if (g.dir == Direction.left) {
        if (g.c == 0) return GuardLeftMap.LeftMap;
        const newC = g.c - 1;
        const obs = m[g.r][newC] == '#';
        if (obs) {
            newGuard = .{ .r = g.r, .c = g.c, .dir = Direction.up };
        } else {
            newGuard = .{ .r = g.r, .c = newC, .dir = g.dir };
        }
    }
    return newGuard;
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var m: [130][130]u8 = undefined;
    var rowNum: usize = 0;
    var colNum: usize = 0;

    while (true) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        if (byte == '\n') continue;

        m[rowNum][colNum] = byte;
        if (colNum == 129) {
            rowNum += 1;
            colNum = 0;
        } else {
            colNum += 1;
        }
    }

    //find initial positon of guard;
    var guard: Guard = undefined;
    for (0..130) |r| {
        for (0..130) |c| {
            const currentChar = m[r][c];

            if (currentChar != '.' and currentChar != '#') {
                var guardDir: Direction = undefined;
                if (currentChar == '^') {
                    guardDir = Direction.up;
                } else if (currentChar == '>') {
                    guardDir = Direction.right;
                } else if (currentChar == 'v') {
                    guardDir = Direction.down;
                } else if (currentChar == '<') {
                    guardDir = Direction.left;
                }
                guard = .{ .r = r, .c = c, .dir = guardDir };
            }
        }
    }

    std.debug.print("Inital Guard Pos: {any}\n", .{guard});
    var sum: usize = 1;
    while (true) {
        guard = walk(guard, &m) catch |err| {
            std.debug.print("Done: {}\n", .{err});
            break;
        };

        if (m[guard.r][guard.c] == '.') {
            sum += 1;
            m[guard.r][guard.c] = 'X';
        }

        //for (0..130) |r| {
        //    for (0..130) |c| {
        //        std.debug.print("{c}", .{m[r][c]});
        //    }
        //    std.debug.print("\n", .{});
        //}
    }

    std.debug.print("Sum: {}\n", .{sum});
}
