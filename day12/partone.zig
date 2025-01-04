const std = @import("std");

const rowsNum = 140;
const colsNum = 140;
const fileName = "input.txt";

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
    fence: usize,
    area: usize,
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
        .fence = 0,
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

            if (l1.c == 0 or l1.c == (colsNum - 1)) {
                currentLot.fence += 1;
                //std.debug.print("Adding fence columns to {?c} {} at {any}\n", .{ currentLot.plant, currentLot.fence, l1 });
            }
            if (l1.r == 0 or l1.r == (rowsNum - 1)) {
                currentLot.fence += 1;
                //std.debug.print("Adding fence rows to {?c} {} at {any}\n", .{ currentLot.plant, currentLot.fence, l1 });
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
                    currentLot.fence += 1;
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
                    currentLot.fence += 1;
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
                    currentLot.fence += 1;
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
                    currentLot.fence += 1;
                    //std.debug.print("Adding fence left to {?c} {} looking {any}\n", .{ currentLot.plant, currentLot.fence, l_loc });
                }
            }

            m[l1.r][l1.c] = '*';
            //print(&m);
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
            currentLot.* = .{
                .plant = p2,
                .area = 0,
                .fence = 0,
            };
            next_locations.clearRetainingCapacity();
            try next_locations.append(.{ .c = nsl.?.c, .r = nsl.?.r });
        }
    }

    std.debug.print("DONE\n", .{});

    var total: usize = 0;
    for (lots.items) |l| {
        std.debug.print("Lot {?c}, {} * {} = {}\n", .{ l.plant, l.area, l.fence, l.area * l.fence });
        total += l.area * l.fence;
    }
    std.debug.print("Total: {}\n", .{total});

    //std.debug.print("Result: {} for {} trails.\n", .{ result, trails.items.len });

}
