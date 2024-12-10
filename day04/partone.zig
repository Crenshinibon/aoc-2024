const std = @import("std");

pub fn walk() void {}

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
        if (colNum == 139) {
            rowNum += 1;
            colNum = 0;
        } else {
            colNum += 1;
        }
    }

    const sum: usize = 0;
    for (0..130) |r| {
        for (0..130) |c| {
            const currentChar = m[r][c];

            if (currentChar == '#') {
                std.debug.print("Found obstacle at {r}-{c}", .{ r, c });
            } else if (currentChar != '.') {
                std.debug.print("something else at {r}-{c}", .{ r, c });
            }
        }
    }

    std.debug.print("Sum: {}\n", .{sum});
}
