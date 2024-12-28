const std = @import("std");

const fileName = "input.txt";

const File = struct {
    id: usize,
};

const PosTag = enum {
    file,
    free,
};

const Pos = union(PosTag) {
    file: File,
    free: void,
};

fn print(locations: []Pos, out: bool, outFile: []const u8) !void {
    if (!out) {
        for (locations) |loc| {
            switch (loc) {
                PosTag.file => std.debug.print("{} ", .{loc.file.id}),
                PosTag.free => std.debug.print(". ", .{}),
            }
        }
        std.debug.print("\n", .{});
    } else {
        var file = try std.fs.cwd().createFile(outFile, .{});
        defer file.close();

        var buffered = std.io.bufferedWriter(file.writer());
        var writer = buffered.writer();

        for (locations) |loc| {
            switch (loc) {
                PosTag.file => try writer.print("{} ", .{loc.file.id}),
                PosTag.free => try writer.print(". ", .{}),
            }
        }

        try buffered.flush();
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var locations: std.ArrayList(Pos) = std.ArrayList(Pos).init(allocator);
    var compressed_pos: usize = 0;

    var blocks_total: usize = 0;

    var file_id: usize = 0;
    while (true) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        if (byte >= 48) {
            const int_value: u8 = byte - 48;
            //std.debug.print("{} => {}\n", .{ compressed_pos, int_value });
            //every even position is a file, every odd a free blocks number
            if (compressed_pos % 2 == 0) {
                var x: usize = 0;
                while (x < int_value) : (x += 1) {
                    try locations.append(Pos{ .file = File{ .id = file_id } });
                }
                file_id += 1;
            } else {
                var x: usize = 0;
                while (x < int_value) : (x += 1) {
                    try locations.append(Pos{ .free = {} });
                }
            }

            compressed_pos += 1;
            blocks_total += int_value;
        }
    }
    std.debug.print("max file id: {}, total block count: {}\n", .{ file_id - 1, blocks_total - 1 });

    try print(locations.items, true, "unordered.txt");

    var reverse_index: usize = locations.items.len - 1;
    for (locations.items, 0..) |loc, idx| {
        //print(locations.items);
        //std.debug.print("{} -> {} {any}\n", .{ idx, reverse_index, loc });
        if (idx > reverse_index) {
            std.debug.print("Breaking: idx: {} - rev_idx: {} - {any}\n", .{ idx, reverse_index, loc });
            break;
        }

        switch (loc) {
            PosTag.file => continue,
            PosTag.free => {
                while (true) {
                    const rloc = locations.items[reverse_index];
                    switch (rloc) {
                        PosTag.free => {
                            //std.debug.print("found empty reverse {}\n", .{reverse_index});
                            reverse_index = reverse_index - 1;
                            continue;
                        },
                        PosTag.file => {
                            //std.debug.print("found file reverse {}\n", .{reverse_index});
                            //std.debug.print("Filling from {}\n", .{reverse_index});
                            locations.items[idx] = rloc;
                            if (reverse_index >= idx) {
                                locations.items[reverse_index] = Pos{ .free = {} };
                            }
                            reverse_index = reverse_index - 1;
                            break;
                        },
                    }
                }
            },
        }
    }
    try print(locations.items, true, "ordered.txt");

    var result: usize = 0;
    for (locations.items, 0..) |loc, idx| {
        switch (loc) {
            PosTag.file => {
                result += loc.file.id * idx;
                //std.debug.print("mult id:{} * index:{} = {} => total result: {}\n", .{ loc.file.id, idx, loc.file.id * idx, result });
            },
            PosTag.free => {
                std.debug.print("{any} at {}\n", .{ loc, idx });
                std.debug.print("{any} at {}\n", .{ locations.items[idx + 1], idx + 1 });
                break;
            },
        }
    }

    std.debug.print("Result: {}\n", .{result});
}
