const std = @import("std");

const Pos = struct {
    r: u32,
    c: u32,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var m: [50][50]u8 = undefined;
    var rowNum: usize = 0;
    var colNum: usize = 0;

    while (true) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        if (byte == '\n') continue;

        m[rowNum][colNum] = byte;
        if (colNum == 49) {
            rowNum += 1;
            colNum = 0;
        } else {
            colNum += 1;
        }
    }

    var antennas: std.AutoHashMap(u8, []const Pos) = std.AutoHashMap(u8, []const Pos).init(allocator);

    defer antennas.deinit();
    var r: u32 = 0;
    while (r < 50) : (r += 1) {
        var c: u32 = 0;
        while (c < 50) : (c += 1) {
            const currentChar = m[r][c];

            if (currentChar != '.') {
                if (!antennas.contains(currentChar)) {
                    try antennas.put(currentChar, &[_]Pos{.{
                        .r = r,
                        .c = c,
                    }});
                } else {
                    const positions: []const Pos = antennas.get(currentChar) orelse unreachable;
                    var newPositions: []Pos = try allocator.alloc(Pos, positions.len + 1);
                    for (positions, 0..) |pos, idx| {
                        newPositions[idx] = pos;
                    }
                    newPositions[positions.len] = .{
                        .r = r,
                        .c = c,
                    };
                    try antennas.put(currentChar, newPositions);
                }
            }
        }
    }

    var iter2 = antennas.iterator();
    while (iter2.next()) |entry| {
        const antenna = entry.key_ptr.*;
        const positions = entry.value_ptr.*;
        std.debug.print("Antenna: {c} positions: {any}\n", .{ antenna, positions });

        for (positions) |ref| {
            for (positions) |other| {
                if (ref.c != other.c and ref.r != other.r) {
                    const distR: isize = @as(i64, ref.c) - @as(i64, other.c);
                    const distC: isize = @as(i64, ref.r) - @as(i64, other.r);
                    std.debug.print("Distances {c}: r{} c{}\n", .{ antenna, distR, distC });

                    const n1c = @as(i64, ref.c) + distC;
                    const n1r = @as(i64, ref.r) + distR;

                    if (n1c >= 0 and n1c < 50 and n1r >= 0 and n1r < 50) {
                        m[n1c][n1r] = '#';
                    }

                    const n2c = @as(i64, other.c) + distC;
                    const n2r = @as(i64, other.r) + distR;

                    if (n2c >= 0 and n2c < 50 and n2r >= 0 and n2r < 50) {
                        m[n1c][n1r] = '#';
                    }
                } else {
                    std.debug.print("Ignoring self\n", .{});
                }
            }
        }
    }

    //std.debug.print("Antennas: {any}\n", .{antennas});
}
