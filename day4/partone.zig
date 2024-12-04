const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input4.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var m: [140][140]u8 = undefined;
    var rowNum: usize = 0;
    var colNum: usize = 0;

    while (true) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        if (byte == '\n') continue;

        m[rowNum][colNum] = byte;
        if (colNum == 139) {
            rowNum += 1;
            colNum = 0;
        } else {
            colNum += 1;
        }
    }

    var sum: usize = 0;
    for (0..140) |r| {
        for (0..140) |c| {
            const currentChar = m[c][r];

            //if x look in all directions for MAS
            if (currentChar == 'X') {
                // print surrounding

                const minC = if (@as(i128, c) - 3 < 0) 0 else c - 3;
                const maxC = if (c + 3 > 140) 140 else c + 3;
                const minR = if (@as(i128, r) - 3 < 0) 0 else r - 3;
                const maxR = if (r + 3 > 140) 140 else r + 3;
                std.debug.print("Surrounding X at c{} r{} -dimensions: row:{}-{} column:{}-{}\n", .{ c, r, minR, maxR, minC, maxC });
                for (minR..maxR) |sr| {
                    for (minC..maxC) |sc| {
                        const char = m[sr][sc];
                        std.debug.print("{}/{}:{c} ", .{ sr, sc, char });
                    }
                    std.debug.print("\n", .{});
                }

                //right
                if (c + 3 < 140 and m[c + 1][r] == 'M' and m[c + 2][r] == 'A' and m[c + 3][r] == 'S') {
                    sum += 1;
                }
                //left
                if (c >= 3 and m[c - 1][r] == 'M' and m[c - 2][r] == 'A' and m[c - 3][r] == 'S') {
                    sum += 1;
                }
                //up
                if (r >= 3 and m[c][r - 1] == 'M' and m[c][r - 2] == 'A' and m[c][r - 3] == 'S') {
                    sum += 1;
                }
                //down
                if (r + 3 < 140 and m[c][r + 1] == 'M' and m[c][r + 2] == 'A' and m[c][r + 3] == 'S') {
                    sum += 1;
                }
                //up-right
                if (r >= 3 and c + 3 < 140 and m[c + 1][r - 1] == 'M' and m[c + 2][r - 2] == 'A' and m[c + 3][r - 3] == 'S') {
                    sum += 1;
                }
                //down-right
                if (r + 3 < 140 and c + 3 < 140 and m[c + 1][r + 1] == 'M' and m[c + 2][r + 2] == 'A' and m[c + 3][r + 3] == 'S') {
                    sum += 1;
                }
                //up-left
                if (r >= 3 and c >= 3 and m[c - 1][r - 1] == 'M' and m[c - 2][r - 2] == 'A' and m[c - 3][r - 3] == 'S') {
                    sum += 1;
                }
                //down-left
                if (r + 3 < 140 and c >= 3 and m[c - 1][r + 1] == 'M' and m[c - 2][r + 2] == 'A' and m[c - 3][r + 3] == 'S') {
                    sum += 1;
                }
            }
        }
    }

    std.debug.print("Sum: {}\n", .{sum});
}
