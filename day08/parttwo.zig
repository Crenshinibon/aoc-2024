const std = @import("std");

const Pos = struct {
    r: u32,
    c: u32,
};

const rowsNum = 50;
const colsNum = 50;
const fileName = "input.txt";

pub fn print(m: *[rowsNum][colsNum]u8) void {
    for (0..rowsNum) |x| {
        for (0..colsNum) |y| {
            std.debug.print("{c}", .{m[x][y]});
        }
        std.debug.print("\n", .{});
    }
}

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
        //std.debug.print("r{},c{}={c} ", .{ rowNum, colNum, byte });

        m[rowNum][colNum] = byte;
        if (colNum == (colsNum - 1)) {
            rowNum += 1;
            colNum = 0;
        } else {
            colNum += 1;
        }
    }

    print(&m);

    var antennas: std.AutoHashMap(u8, []const Pos) = std.AutoHashMap(u8, []const Pos).init(allocator);
    defer antennas.deinit();

    var r: u32 = 0;
    while (r < rowsNum) : (r += 1) {
        var c: u32 = 0;
        while (c < colsNum) : (c += 1) {
            const currentChar = m[r][c];

            if (currentChar != '.') {
                if (!antennas.contains(currentChar)) {
                    var fPos = try allocator.alloc(Pos, 1);
                    fPos[0].r = r;
                    fPos[0].c = c;
                    try antennas.put(currentChar, fPos);
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
                    const distR: isize = @as(i64, other.r) - @as(i64, ref.r);
                    const distC: isize = @as(i64, other.c) - @as(i64, ref.c);
                    //std.debug.print("From {}|{} to {}|{} Distances {c}: {}|{}\n", .{ ref.r, ref.c, other.r, other.c, antenna, distR, distC });

                    var n1r = @as(i64, ref.r) - distR;
                    var n1c = @as(i64, ref.c) - distC;

                    var n2r = @as(i64, other.r) + distR;
                    var n2c = @as(i64, other.c) + distC;

                    while (true) {
                        var keep_going = false;

                        //std.debug.print("Potential Node 1: {}|{}\n", .{ n1r, n1c });
                        if (n1c >= 0 and n1c < colsNum and n1r >= 0 and n1r < rowsNum) {
                            //std.debug.print("Node 1 added: {}|{}\n", .{ n1r, n1c });
                            m[@intCast(n1r)][@intCast(n1c)] = '#';
                            keep_going = true;

                            n1r = n1r - distR;
                            n1c = n1c - distC;
                        }

                        //std.debug.print("Potential Node 2: {}|{}\n", .{ n2r, n2c });
                        if (n2c >= 0 and n2c < colsNum and n2r >= 0 and n2r < rowsNum) {
                            //std.debug.print("Node 2 added: {}|{}\n", .{ n2r, n2c });
                            m[@intCast(n2r)][@intCast(n2c)] = '#';
                            keep_going = true;

                            n2r = n2r + distR;
                            n2c = n2c + distC;
                        }

                        print(&m);
                        std.debug.print("\n", .{});
                        if (!keep_going) {
                            break;
                        }
                    }
                } else {
                    //std.debug.print("Ignoring self\n", .{});
                }
            }
        }
    }

    print(&m);

    var result: usize = 0;
    for (0..rowsNum) |x| {
        for (0..colsNum) |y| {
            const currentChar = m[x][y];
            if (currentChar != '.') {
                result += 1;
            }
        }
    }

    std.debug.print("Result: {}\n", .{result});
}
