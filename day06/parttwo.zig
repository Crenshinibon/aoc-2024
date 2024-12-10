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

pub fn tryMap(initialGuard: *Guard, initialMap: *[130][130]u8) bool {
    var m: [130][130]u8 = undefined;
    for (0..130) |r| {
        for (0..130) |c| {
            m[r][c] = initialMap[r][c];
        }
    }

    var guard: Guard = .{
        .r = initialGuard.r,
        .c = initialGuard.c,
        .dir = initialGuard.dir,
    };

    //var counter: u32 = 0;
    var looped = false;
    while (true) {
        guard = walk(guard, &m) catch {
            //std.debug.print("Not Looped\n", .{});
            break;
        };

        //detect loop
        if (m[guard.r][guard.c] == '^' and guard.dir == Direction.up) {
            looped = true;
        } else if (m[guard.r][guard.c] == '>' and guard.dir == Direction.right) {
            looped = true;
        } else if (m[guard.r][guard.c] == 'v' and guard.dir == Direction.down) {
            looped = true;
        } else if (m[guard.r][guard.c] == '<' and guard.dir == Direction.left) {
            looped = true;
        }
        if (looped) {
            //std.debug.print("Looped\n", .{});
            break;
        }

        //mark position only if it's not yet visited
        if (m[guard.r][guard.c] == '.') {
            const marker: u8 = if (guard.dir == Direction.up) '^' else if (guard.dir == Direction.right) '>' else if (guard.dir == Direction.down) 'v' else if (guard.dir == Direction.left) '<' else unreachable;
            m[guard.r][guard.c] = marker;
        }

        // not needed anymore
        //counter += 1;
        //if (counter > 100000) {
        //    std.debug.print("Breaking, 100.000 reached assuming loop\n", .{});

        //    //............#..............#..^........#............#................#..#.v.....................#.#...v.#.............##..........
        //    //..........#..................#^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<v<<<<<<<<<<<<<<<<<<<<<<<<<<<<.........................#.
        //    //.....................................#..............##....................v.............#.............#........#..................
        //    //..............................#..................#...............#......#.v##....................#................................
        //    //..#............#....................................#.....................v.................................#...#.................
        //    //..................###..........................#.......#..................v..............#........................................
        //    //.....#.#..........................................................#.......v...##...#.....#.................................#......
        //    //.............................................#...................#>>>>>><<<#......................#.............#.......#.....#... //here we have the problem ... this sucks badly
        //    //...#......................#............#..................................#........................#....................#.......#.
        //    //....##..........#..........#...#.............#............#....#......#....................#...........#..#..........#............
        //    //..#......................#............#..#..#.......................#.........#......#...............#............#..#............
        //    //..#.............#.#.............................#......#......#.........................#......#.#...............#...............#
        //    //...#...........#...............#.....................................#.................#....#....#...................#.#...#......
        //    //.......#........#....................#.............................................#..............................................
        //    //........#............................#....#....#........#...................#.#...............#...#.....................#.........
        //    //.##........#.................#...........#...............................##.#.....................................................
        //    //.###...........................#........#..#................................................#...........................#.........

        //    for (0..130) |r| {
        //        for (0..130) |c| {
        //            std.debug.print("{c}", .{m[r][c]});
        //        }
        //        std.debug.print("\n", .{});
        //    }

        //    looped = true;
        //    break;
        //}
    }
    return looped;
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

    var looped: usize = 0;
    var notLooped: usize = 0;
    //modify each (valid) position and test
    for (0..130) |r| {
        for (0..130) |c| {
            const currentChar = m[r][c];
            //only obs on empty spaces
            if (currentChar == '.') {
                var mapCopy: [130][130]u8 = undefined;
                for (0..130) |ir| {
                    for (0..130) |ic| {
                        mapCopy[ir][ic] = m[ir][ic];
                    }
                }
                mapCopy[r][c] = '#';
                //std.debug.print("Trying obs at {} - {}\n", .{ r, c });

                if (tryMap(&guard, &mapCopy)) {
                    looped += 1;
                    //std.debug.print("Looped", .{});
                } else {
                    notLooped += 1;
                    //std.debug.print("NOT Looped", .{});
                }
            }
        }
    }

    std.debug.print("Looped: {}, Not Looped: {}\n", .{ looped, notLooped });
}
