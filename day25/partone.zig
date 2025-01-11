const std = @import("std");
const input = @embedFile("./input.txt");

pub fn printPattern(pattern: [7][5]u8) void {
    for (0..7) |r| {
        std.debug.print("\n", .{});
        for (0..5) |l| {
            std.debug.print("{c}", .{pattern[r][l]});
        }
    }
    std.debug.print("\n", .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var keys = std.ArrayList([5]usize).init(allocator);
    var locks = std.ArrayList([5]usize).init(allocator);

    var current = [5]usize{ 0, 0, 0, 0, 0 };

    var in_key = false;
    var in_lock = false;

    var ite = std.mem.splitScalar(u8, input, '\n');

    var pattern: [7][5]u8 = .{
        .{ '0', '0', '0', '0', '0' },
        .{ '0', '0', '0', '0', '0' },
        .{ '0', '0', '0', '0', '0' },
        .{ '0', '0', '0', '0', '0' },
        .{ '0', '0', '0', '0', '0' },
        .{ '0', '0', '0', '0', '0' },
        .{ '0', '0', '0', '0', '0' },
    };

    var pattern_idx: usize = 0;
    while (ite.next()) |line| {
        //if empty line, store key or lock
        if (line.len == 0) {
            std.debug.print("Key? {} Lock? {}\n", .{ in_key, in_lock });
            printPattern(pattern);
            std.debug.print("\nCurrent: {any}\n", .{current});

            pattern_idx = 0;
            pattern = .{
                .{ '0', '0', '0', '0', '0' },
                .{ '0', '0', '0', '0', '0' },
                .{ '0', '0', '0', '0', '0' },
                .{ '0', '0', '0', '0', '0' },
                .{ '0', '0', '0', '0', '0' },
                .{ '0', '0', '0', '0', '0' },
                .{ '0', '0', '0', '0', '0' },
            };

            if (in_key and in_lock) unreachable;

            std.debug.print("\n", .{});
            if (in_key) {
                //remove last line from keys
                current[0] -= 1;
                current[1] -= 1;
                current[2] -= 1;
                current[3] -= 1;
                current[4] -= 1;

                try keys.append(current);
            }
            if (in_lock) {
                try locks.append(current);
            }

            current = [5]usize{ 0, 0, 0, 0, 0 };

            //empty line continue;
            in_key = false;
            in_lock = false;
            continue;
        } else {
            pattern[pattern_idx] = [5]u8{ line[0], line[1], line[2], line[3], line[4] };
            pattern_idx += 1;
        }

        //decide wether it's a key or lock
        if (!in_key and !in_lock and std.mem.eql(u8, line, "#####")) {
            in_lock = true;
            continue;
        } else if (!in_key and !in_lock) {
            in_key = true;
        }

        for (0..5) |idx| {
            if (line[idx] == '#') {
                current[idx] += 1;
            }
        }
    }

    //std.debug.print("Keys: {}\n Locks: {}\n", .{ locks.items.len, keys.items.len });

    var result: usize = 0;
    for (locks.items) |k| {
        for (keys.items) |l| {
            var fine = true;
            for (0..5) |idx| {
                const m = l[idx] + k[idx];
                if (m >= 6) {
                    fine = false;
                    break;
                }
            }

            if (fine) {
                std.debug.print("No overlap: #{}:\n", .{result});

                std.debug.print("K\t", .{});
                for (0..5) |idx| {
                    std.debug.print("{}", .{k[idx]});
                }
                std.debug.print("\nL\t", .{});
                for (0..5) |idx| {
                    std.debug.print("{}", .{l[idx]});
                }
                std.debug.print("\nS\t", .{});
                for (0..5) |idx| {
                    std.debug.print("{}", .{k[idx] + l[idx]});
                }

                std.debug.print("\n\n\n", .{});

                result += 1;
            }
        }
    }

    std.debug.print("Result: {}\n", .{result});
}
