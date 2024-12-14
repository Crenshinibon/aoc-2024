const std = @import("std");

const rowsNum = 4;
const colsNum = 4;
const fileName = "tiny2.txt";

pub fn print(m: *[rowsNum][colsNum]u8) void {
    for (0..rowsNum) |x| {
        for (0..colsNum) |y| {
            std.debug.print("{c}", .{m[x][y]});
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}

const Lot = struct {
    plant: ?u8,
    fence: std.ArrayList(Fence),
    area: usize,
};

const Fence = struct {
    loc: Location,
    dir: u8, // up == 0, right == 1, down == 2, left == 3
    fn SortColumns(_: void, l1: Fence, l2: Fence) bool {
        return l1.loc.c < l2.loc.c or (l1.loc.c == l2.loc.c and l1.loc.r < l2.loc.r);
    }
    fn SortRows(_: void, l1: Fence, l2: Fence) bool {
        return l1.loc.r < l2.loc.r or (l1.loc.r == l2.loc.r and l1.loc.c < l2.loc.c);
    }
};

const Location = struct {
    r: usize,
    c: usize,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var org: [colsNum][rowsNum]u8 = undefined;
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
        org[rowNum][colNum] = byte;

        if (colNum == (colsNum - 1)) {
            rowNum += 1;
            colNum = 0;
        } else {
            colNum += 1;
        }
    }
    print(&m);

    var lots: std.ArrayList(*Lot) = std.ArrayList(*Lot).init(allocator);
    defer lots.deinit();

    var currentLot: *Lot = try allocator.create(Lot);
    currentLot.* = .{
        .area = 0,
        .fence = std.ArrayList(Fence).init(allocator),
        .plant = null,
    };

    var next_locations = std.ArrayList(Location).init(allocator);
    try next_locations.append(.{ .c = 0, .r = 0 });
    defer next_locations.deinit();

    while (true) {
        while (next_locations.items.len > 0) {
            const l1 = next_locations.pop();
            const p = m[l1.r][l1.c];

            if (p == '%') continue;

            currentLot.plant = currentLot.plant orelse p;
            currentLot.area += 1;

            var is_fence_loc = false;
            if (l1.c == 0) {
                const f = try allocator.create(Fence);
                f.* = .{ .loc = l1, .dir = 3 };
                try currentLot.fence.append(f.*);
            } else if (l1.c == (colsNum - 1)) {
                is_fence_loc = true;
                const f = try allocator.create(Fence);
                f.* = .{ .loc = l1, .dir = 1 };
                try currentLot.fence.append(f.*);
            }
            if (l1.r == 0) {
                const f = try allocator.create(Fence);
                f.* = .{ .loc = l1, .dir = 0 };
                try currentLot.fence.append(f.*);
            } else if (l1.r == (rowsNum - 1)) {
                const f = try allocator.create(Fence);
                f.* = .{ .loc = l1, .dir = 2 };
                try currentLot.fence.append(f.*);
            }

            //look up
            if (l1.r > 0) {
                const u_loc: Location = .{ .c = l1.c, .r = l1.r - 1 };

                const u_p = m[u_loc.r][u_loc.c];
                const u_p_org = org[u_loc.r][u_loc.c];

                if (u_p == currentLot.plant) {
                    try next_locations.append(u_loc);
                }
                if (u_p_org != currentLot.plant) {
                    const f = try allocator.create(Fence);
                    f.* = .{ .loc = l1, .dir = 0 };
                    try currentLot.fence.append(f.*);
                    //std.debug.print("Adding fence up to {?c} {} looking {any}\n", .{ currentLot.plant, currentLot.fence, u_loc });
                }
            }

            //look down
            if (l1.r < (rowsNum - 1)) {
                const d_loc: Location = .{ .c = l1.c, .r = l1.r + 1 };

                const d_p = m[d_loc.r][d_loc.c];
                const d_p_org = org[d_loc.r][d_loc.c];

                if (d_p == currentLot.plant) {
                    try next_locations.append(d_loc);
                }
                if (d_p_org != currentLot.plant) {
                    const f = try allocator.create(Fence);
                    f.* = .{ .loc = l1, .dir = 2 };
                    try currentLot.fence.append(f.*);
                    //std.debug.print("Adding fence down to {?c} {} looking {any}\n", .{ currentLot.plant, currentLot.fence, d_loc });
                }
            }

            //look right
            if (l1.c < (colsNum - 1)) {
                const r_loc: Location = .{ .c = l1.c + 1, .r = l1.r };

                const r_p = m[r_loc.r][r_loc.c];
                const r_p_org = org[r_loc.r][r_loc.c];

                if (r_p == currentLot.plant) {
                    try next_locations.append(r_loc);
                }

                if (r_p_org != currentLot.plant) {
                    const f = try allocator.create(Fence);
                    f.* = .{ .loc = l1, .dir = 1 };
                    try currentLot.fence.append(f.*);
                    //std.debug.print("Adding fence righte to {?c} {} looking {any}\n", .{ currentLot.plant, currentLot.fence, r_loc });
                }
            }

            //look left
            if (l1.c > 0) {
                const l_loc: Location = .{ .c = l1.c - 1, .r = l1.r };

                const l_p = m[l_loc.r][l_loc.c];
                const l_p_org = org[l_loc.r][l_loc.c];

                if (l_p == currentLot.plant) {
                    try next_locations.append(l_loc);
                }

                if (l_p_org != currentLot.plant) {
                    const f = try allocator.create(Fence);
                    f.* = .{ .loc = l1, .dir = 3 };
                    try currentLot.fence.append(f.*);
                    //std.debug.print("Adding fence left to {?c} {} looking {any}\n", .{ currentLot.plant, currentLot.fence, l_loc });
                }
            }

            m[l1.r][l1.c] = '*';
            print(&m);
            m[l1.r][l1.c] = '%';
        }

        try lots.append(currentLot);

        var nsl: ?Location = null;
        outer: for (0..rowsNum) |r| {
            for (0..colsNum) |c| {
                if (m[r][c] != '%') {
                    nsl = .{
                        .r = r,
                        .c = c,
                    };
                    break :outer;
                }
            }
        }

        if (nsl == null) {
            break;
        } else {
            const p2 = m[nsl.?.r][nsl.?.c];
            currentLot = try allocator.create(Lot);
            currentLot.* = .{ .plant = p2, .area = 0, .fence = std.ArrayList(Fence).init(allocator) };
            next_locations.clearRetainingCapacity();
            try next_locations.append(.{ .c = nsl.?.c, .r = nsl.?.r });
        }
    }

    std.debug.print("DONE\n", .{});
    const total: usize = 0;

    for (lots.items) |l| {
        var sides: usize = 0;
        std.debug.print("Lot {?c}, Area: {} \nFence elements:\n", .{ l.plant, l.area });

        for (l.fence.items) |f| {
            std.debug.print("\t r{} c{}\n", .{ f.loc.r, f.loc.c, f.dir });
        }

        //perimeter walk count dir changes

        //sort by row
        std.mem.sort(Fence, l.fence.items, {}, Fence.SortRows);
        //std.debug.print("Row sorted:\n", .{});
        //for (l.fence.items) |f| {
        //    std.debug.print("\t r{} c{}\n", .{ f.r, f.c });
        //}

        //then count consecutive columns per row
        var c_row: usize = 9999;
        var c_col: usize = 9999;
        var initial: bool = true;

        for (l.fence.items) |f| {
            if (initial) {
                sides += 2;
                initial = false;
            }

            if (f.r > (c_row + 1)) {
                sides += 2;
            }

            c_row = f.r;

            //    if (initial) {
            //        c_row = f.r;
            //        c_col = f.c;
            //        initial = false;
            //        sides += 2;
            //        std.debug.print("Initial row {} /w col {}, sides-total {}\n", .{ c_row, c_col, sides });
            //    }

            //    if (c_row != f.r and c_col != f.c) {
            //        c_row = f.r;
            //        sides += 1;
            //        std.debug.print("New row {} /w col {} adding, sides-total: {}\n", .{ c_row, c_col, sides });
            //    } else {
            //        std.debug.print("testing {} {} {}\n", .{ f.c, c_col + 1, f.c > (c_col + 1) });
            //        if (f.c > (c_col + 1)) {
            //            sides += 1;
            //            std.debug.print("New col {} in same row {} adding, side-total: {}\n", .{ c_col, c_row, sides });
            //        }
            //    }
            //    c_col = f.c;
        }

        //sort by column
        std.mem.sort(Fence, l.fence.items, {}, Fence.SortColumns);
        //std.debug.print("Column sorted:\n", .{});
        //for (l.fence.items) |f| {
        //    std.debug.print("\t r{} c{}\n", .{ f.r, f.c });
        //}

        //then count consecutive rows per column
        c_row = 9999;
        c_col = 9999;
        initial = true;
        for (l.fence.items) |f| {
            if (initial) {
                sides += 2;
                initial = false;
            }

            if (f.c > (c_col + 1)) {
                sides += 2;
            }
            c_col = f.c;

            //if (initial) {
            //    c_col = f.c;
            //    c_row = f.r;
            //    initial = false;
            //    sides += 2;
            //    std.debug.print("Initial col {} /w row {}, sides-total {}\n", .{ c_col, c_row, sides });
            //}

            //if (c_col != f.c and c_row != f.r) {
            //    c_col = f.c;
            //    sides += 1;
            //    std.debug.print("New col {} /w row {} adding, sides-total: {}\n", .{ c_col, c_row, sides });
            //} else {
            //    std.debug.print("testing {} {} {}\n", .{ f.r, c_row + 1, f.r > (c_row + 1) });
            //    if (f.r > (c_row + 1)) {
            //        sides += 1;
            //        std.debug.print("New row {} in same col {} adding, sides-total: {}\n", .{ c_row, c_col, sides });
            //    }
            //}

            //c_row = f.r;
        }

        std.debug.print("Lot {?c}: Sides {}\n", .{ l.plant, sides });
    }
    std.debug.print("Total: {}\n", .{total});

    //std.debug.print("Result: {} for {} trails.\n", .{ result, trails.items.len });

}
