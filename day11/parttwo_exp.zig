const std = @import("std");

const fileName = "input.txt";

pub fn nextStone(reader: anytype, allocator: std.mem.Allocator) !?[]u8 {
    var buf: [32]u8 = undefined; //try allocator.alloc(u8, 128);
    //defer allocator.free(buf);

    if (try reader.readUntilDelimiterOrEof(&buf, ' ')) |stone_str| {
        var clean = try allocator.alloc(u8, stone_str.len);

        var stone_length: usize = 0;
        for (stone_str, 0..) |c, idx| {
            if (c >= 48 and c <= 57) {
                clean[idx] = c;
                stone_length += 1;
            }
        }
        return clean[0..stone_length];
    }
    return null;
}

pub fn createTempFile(iteration: usize, allocator: std.mem.Allocator) !std.fs.File {
    const cwd: std.fs.Dir = std.fs.cwd();
    cwd.makeDir("output") catch |e| switch (e) {
        error.PathAlreadyExists => {},
        else => return e,
    };
    var output_dir: std.fs.Dir = try cwd.openDir("output", .{});

    const buf: []u8 = try allocator.alloc(u8, 16);
    errdefer allocator.free(buf);
    const file_name = try std.fmt.bufPrint(buf, "iteration_{}.txt", .{iteration});

    const file: std.fs.File = try output_dir.createFile(file_name, .{ .read = true });
    return file;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    const buffered_reader = buffered.reader();

    var stones: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    defer stones.deinit();

    while (true) {
        const clean = try nextStone(buffered_reader, allocator);
        if (clean == null) {
            break;
        } else {
            //const stone = try std.fmt.parseInt(usize, clean.items, 10);
            try stones.append(clean.?);
        }
        //std.debug.print("parsed {any}\n", .{stones.items});
    }
    std.debug.print("Initial\n", .{});
    for (stones.items, 0..) |stone, idx| {
        std.debug.print("  {}: {s}", .{ idx + 1, stone });
    }
    std.debug.print("\n", .{});

    const iterations: usize = 75;
    var current_iteration: usize = 0;

    var files_map: std.AutoHashMap(usize, std.fs.File) = std.AutoHashMap(usize, std.fs.File).init(allocator);
    defer files_map.deinit();

    for (0..(iterations + 1)) |it| {
        const temp_file = try createTempFile(it, allocator);
        try files_map.put(it, temp_file);
    }
    std.debug.print("Created temp_files: {}\n", .{files_map.count()});

    //std.debug.print("\n Writing to temp input file\n", .{});
    const first_file = files_map.get(0).?;
    for (stones.items) |s| {
        _ = try first_file.write(s);
        _ = try first_file.write(" ");
    }
    try first_file.seekTo(0);

    while (current_iteration < iterations) : (current_iteration += 1) {
        const in_file = files_map.get(current_iteration).?;
        var if_buffered = std.io.bufferedReader(in_file.reader());

        const of = files_map.get(current_iteration + 1).?;
        var out_file = std.io.bufferedWriter(of.writer());

        while (true) {
            var stone_a = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            defer stone_a.deinit();
            const s_allocator = stone_a.allocator();

            const opt_stone = try nextStone(if_buffered.reader(), s_allocator);
            if (opt_stone == null) {
                break;
            } else {
                const stone = opt_stone.?;
                if (stone.len == 1 and stone[0] == '0') {
                    _ = try out_file.write("1 ");
                } else if (stone.len % 2 == 0) {
                    const half = stone.len / 2;
                    var first_half = try s_allocator.alloc(u8, half);
                    var second_half = try s_allocator.alloc(u8, half);

                    for (stone, 0..) |s, idx| {
                        if (idx < half) {
                            first_half[idx] = s;
                        } else {
                            second_half[idx - half] = s;
                        }
                    }
                    _ = try out_file.write(first_half);
                    _ = try out_file.write(" ");

                    const int_value = try std.fmt.parseInt(usize, second_half, 10);

                    const sec_buf: []u8 = try s_allocator.alloc(u8, 16);

                    const sec_str = try std.fmt.bufPrint(sec_buf, "{} ", .{int_value});
                    _ = try out_file.write(sec_str);
                } else {
                    const int_value = try std.fmt.parseInt(usize, stone, 10);
                    const new_value = int_value * 2024;

                    const vbuf: []u8 = try s_allocator.alloc(u8, 32);

                    const str = try std.fmt.bufPrint(vbuf, "{} ", .{new_value});
                    _ = try out_file.write(str);
                }
            }
        }
        std.debug.print("Iteration {} finished\n", .{current_iteration});
        try out_file.flush();
        try of.seekTo(0);

        in_file.close();
    }

    //open final file and count stones
    const final_file = files_map.get(iterations).?;
    var result: usize = 0;
    while (true) {
        const opt_stone = try nextStone(final_file.reader(), allocator);
        if (opt_stone == null) {
            break;
        } else {
            result += 1;
        }
    }

    std.debug.print("Result: {}\n", .{result});
}
