const std = @import("std");

// what may not be before the current page, traversing the rule backwards
const NegRule = struct {
    c: usize,
    notAllowed: std.ArrayList(u16),

    pub fn breaking(update: []u16) !bool {
        for ((update.len - 1)..0) |idx| {
            return std.mem.containsAtLeast(u16, .notAllowed, 1, update[idx]);
        }
        return false;
    }
};

pub fn read_rules() !std.AutoHashMap(u16, NegRule) {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var result = std.AutoHashMap(u16, NegRule).init(allocator);

    var file = try std.fs.cwd().openFile("rules.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var arr = std.ArrayList(u8).init(allocator);
    while (true) {
        reader.streamUntilDelimiter(arr.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        var firstValueDone = false;
        var firstValue = std.ArrayList(u8).init(allocator);
        defer firstValue.deinit();
        var secondValue = std.ArrayList(u8).init(allocator);
        defer secondValue.deinit();

        for (arr.items) |x| {
            if (x == '|') {
                firstValueDone = true;
            }
            if (firstValueDone) {
                try secondValue.append(x);
            } else {
                try firstValue.append(x);
            }
        }
        const intValueFirst: u16 = try std.fmt.parseInt(u16, firstValue.items, 10);
        const intValueSecond: u16 = try std.fmt.parseInt(u16, secondValue.items, 10);

        const currentRule: NegRule = result.get(intValueSecond) orelse .{
            .c = intValueSecond,
            .notAllowed = std.ArrayList(u16).init(allocator),
        };

        try currentRule.notAllowed.append(intValueFirst);
    }
    return result;
}

pub fn main() !void {
    var negRules = try read_rules();
    defer negRules.clearAndFree();

    std.debug.print("Read rules {any}", .{negRules});

    //var file = try std.fs.cwd().openFile("input_raph.txt", .{});
    //defer file.close();

    //var buffered = std.io.bufferedReader(file.reader());
    //var reader = buffered.reader();

    //var m: [140][140]u8 = undefined;
    //var rowNum: usize = 0;
    //var colNum: usize = 0;

    //while (true) {
    //    const byte = reader.readByte() catch |err| switch (err) {
    //        error.EndOfStream => break,
    //        else => return err,
    //    };

    //    if (byte == '\n') continue;

    //    m[rowNum][colNum] = byte;
    //    if (colNum == 139) {
    //        rowNum += 1;
    //        colNum = 0;
    //    } else {
    //        colNum += 1;
    //    }
    //}

    //var sum: usize = 0;
    //for (1..139) |r| {
    //    for (1..139) |c| {
    //        const currentChar = m[r][c];

    //        //if x look in all directions for MAS
    //        if (currentChar == 'A') {
    //            // print surrounding
    //            std.debug.print("Found new A at {}/{}\n", .{ r, c });
    //            for ((r - 1)..(r + 2)) |sr| {
    //                for ((c - 1)..(c + 2)) |sc| {
    //                    const char = m[sr][sc];
    //                    std.debug.print("{}/{}:{c} ", .{ sr, sc, char });
    //                }
    //                std.debug.print("\n", .{});
    //            }

    //            var validDiagonals: u8 = 0;

    //            // exclude first and last row and column
    //            //bottom left to  top right
    //            if (m[r + 1][c - 1] == 'M' and m[r - 1][c + 1] == 'S') validDiagonals += 1;

    //            //bottom right to top left
    //            if (m[r + 1][c + 1] == 'M' and m[r - 1][c - 1] == 'S') validDiagonals += 1;

    //            //top right to bottom left
    //            if (m[r - 1][c - 1] == 'M' and m[r + 1][c + 1] == 'S') validDiagonals += 1;

    //            //top left to bottom right
    //            if (m[r - 1][c + 1] == 'M' and m[r + 1][c - 1] == 'S') validDiagonals += 1;

    //            //found two valid diagonals?
    //            if (validDiagonals == 2) sum += 1;
    //        }
    //    }
    //}

    //std.debug.print("Sum: {}\n", .{sum});
}
