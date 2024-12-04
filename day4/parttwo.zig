const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{});
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
    for (1..139) |r| {
        for (1..139) |c| {
            const currentChar = m[r][c];

            //if x look in all directions for MAS
            if (currentChar == 'A') {
                // print surrounding
                std.debug.print("Found new A at {}/{}\n", .{ r, c });
                for ((r - 1)..(r + 2)) |sr| {
                    for ((c - 1)..(c + 2)) |sc| {
                        const char = m[sr][sc];
                        std.debug.print("{}/{}:{c} ", .{ sr, sc, char });
                    }
                    std.debug.print("\n", .{});
                }

                var validDiagonals: u8 = 0;

                // exclude first and last row and column
                //bottom left to  top right
                if (m[r + 1][c - 1] == 'M' and m[r - 1][c + 1] == 'S') validDiagonals += 1;

                //bottom right to top left
                if (m[r + 1][c + 1] == 'M' and m[r - 1][c - 1] == 'S') validDiagonals += 1;

                //top right to bottom left
                if (m[r - 1][c - 1] == 'M' and m[r + 1][c + 1] == 'S') validDiagonals += 1;

                //top left to bottom right
                if (m[r - 1][c + 1] == 'M' and m[r + 1][c - 1] == 'S') validDiagonals += 1;

                //found two valid diagonals?
                if (validDiagonals == 2) sum += 1;
            }
        }
    }

    std.debug.print("Sum: {}\n", .{sum});
}
