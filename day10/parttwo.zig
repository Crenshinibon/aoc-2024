const std = @import("std");

const rowsNum = 54;
const colsNum = 54;
const fileName = "input.txt";

pub fn print(m: *[rowsNum][colsNum]u8) void {
    for (0..rowsNum) |x| {
        for (0..colsNum) |y| {
            std.debug.print("{c}", .{m[x][y]});
        }
        std.debug.print("\n", .{});
    }
}

const Point = struct {
    r: usize,
    c: usize,
    h: u8,
};

const Trail = struct { p: []Point, ended: bool, initial: Point };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var m: [colsNum][rowsNum]u8 = undefined;
    var rowNum: usize = 0;
    var colNum: usize = 0;

    while (true) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        if (byte == '\n') continue;

        m[rowNum][colNum] = byte;
        if (colNum == (colsNum - 1)) {
            rowNum += 1;
            colNum = 0;
        } else {
            colNum += 1;
        }
    }
    print(&m);

    var trails: std.ArrayList(*Trail) = std.ArrayList(*Trail).init(allocator);
    defer trails.deinit();

    //find trail heads
    var r: usize = 0;
    while (r < rowsNum) : (r += 1) {
        var c: u32 = 0;
        while (c < colsNum) : (c += 1) {
            const h = m[r][c];

            if (h == '0') {
                var start = try allocator.alloc(Point, 1);
                start[0].c = c;
                start[0].r = r;
                start[0].h = h - 48;

                var t = try allocator.create(Trail);
                t.p = start;
                t.ended = false;
                t.initial = start[0];

                try trails.append(t);
                std.debug.print("Appending {any}\n", .{t.p});
            }
        }
    }
    std.debug.print("Trails Heads found: {}\n", .{trails.items.len});

    //iterate trails
    while (true) {
        var contGlobal = false;
        for (trails.items) |t| {
            if (!t.ended) {
                contGlobal = true;

                var newPoints = std.ArrayList(Point).init(allocator);

                var contTrail = false;

                for (t.p) |p| {
                    std.debug.print("Current Point {any}\n", .{p});

                    var newPathFound = false;
                    //find next possible locations from p
                    //look up
                    if (p.r > 0) {
                        //48 is ASCII 0
                        const n = m[p.r - 1][p.c] - 48;
                        if (n == p.h + 1) {
                            std.debug.print("Found up\n", .{});
                            newPathFound = true;

                            var point = try allocator.create(Point);
                            point.c = p.c;
                            point.r = p.r - 1;
                            point.h = n;
                            //errdefer allocator.free(point);
                            try newPoints.append(point.*);
                        }
                    }

                    //look down
                    if (p.r < (rowsNum - 1)) {
                        const n = m[p.r + 1][p.c] - 48;
                        if (n == p.h + 1) {
                            std.debug.print("Found down\n", .{});
                            newPathFound = true;

                            var point = try allocator.create(Point);
                            point.c = p.c;
                            point.r = p.r + 1;
                            point.h = n;
                            //errdefer allocator.free(point);
                            try newPoints.append(point.*);
                        }
                    }

                    //look right
                    if (p.c < (colsNum - 1)) {
                        const n = m[p.r][p.c + 1] - 48;
                        if (n == p.h + 1) {
                            std.debug.print("Found right\n", .{});
                            newPathFound = true;

                            var point = try allocator.create(Point);
                            point.c = p.c + 1;
                            point.r = p.r;
                            point.h = n;
                            //errdefer allocator.free(point);
                            try newPoints.append(point.*);
                        }
                    }

                    //look left
                    if (p.c > 0) {
                        const n = m[p.r][p.c - 1] - 48;
                        if (n == p.h + 1) {
                            std.debug.print("Found left\n", .{});
                            newPathFound = true;

                            var point = try allocator.create(Point);
                            point.c = p.c - 1;
                            point.r = p.r;
                            point.h = n;
                            //errdefer allocator.free(point);
                            try newPoints.append(point.*);
                        }
                    }

                    if (newPathFound) {
                        contTrail = true;
                    }
                }

                if (newPoints.items.len > 0) {
                    std.debug.print("Next points {any}\n", .{newPoints.items});
                    t.p = newPoints.items;
                }

                if (!contTrail) {
                    t.ended = true;
                }
            }
        }

        if (!contGlobal) {
            break;
        }
    }

    var result: usize = 0;
    for (trails.items) |t| {
        std.debug.print("trail: {} - {}\n", .{ t.initial.r, t.initial.c });
        var trailScore: usize = 0;

        //        var seen = std.StringHashMap(void).init(allocator);
        for (t.p) |p| {
            if (p.h == 9) {
                //            var keyBuf: [16]u8 = undefined;
                //              const key = try std.fmt.bufPrint(&keyBuf, "{}-{}", .{ p.r, p.c });

                //          const c = seen.contains(key);
                //        if (!c) {
                trailScore += 1;
                //          std.debug.print("Counting {s} {}\n", .{ key, trailScore });
                //        try seen.put(key, {});
                //   }
            }
        }
        //seen.clearRetainingCapacity();
        std.debug.print("Score: {}\n", .{trailScore});
        result += trailScore;
    }

    std.debug.print("Result: {} for {} trails.\n", .{ result, trails.items.len });
}
