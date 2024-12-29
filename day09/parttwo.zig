const std = @import("std");

const fileName = "small.txt";

const File = struct {
    start_idx: usize,
    size: usize,
};

const Free = struct {
    start_idx: usize,
    size: usize,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var files = std.ArrayList(File).init(allocator);
    var empty = std.ArrayList(Free).init(allocator);

    var compressed_pos: usize = 0;

    var start_idx: usize = 0;
    while (true) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        if (byte >= 48) {
            const size: u8 = byte - 48;
            if (compressed_pos % 2 == 0) {
                try files.append(File{
                    .start_idx = start_idx,
                    .size = size,
                });
            } else {
                try empty.append(Free{
                    .start_idx = start_idx + 1,
                    .size = size,
                });
            }

            start_idx += size;
            compressed_pos += 1;
        }
    }

    std.debug.print("max file idx: {}\n", .{start_idx - 1});
    std.debug.print("files: {any}\n", .{files.items});
    std.debug.print("empty: {any}\n", .{empty.items});

    var filled = std.ArrayList(File).init(allocator);

    var forward_idx: usize = 0;
    try filled.append(files.items[forward_idx]);

    for (0..(empty.items.len - 1)) |free_idx| {
        var free = empty.items[free_idx];

        for ((files.items.len - 1)..0) |file_idx| {
            var cf = files.items[file_idx];
            if (cf.size < free.size) {
                cf.start_idx = free.start_idx;
                try filled.append(cf);

                free.size = free.size - cf.size;
                free.start_idx = free.start_idx + cf.size;
            }
            if (free.size == 0) {
                break;
            }
        }
        forward_idx += 1;
        try filled.append(file.items[forward_idx]);
    }
    std.debug.print("filled: {any}\n", .{filled.items});
    const result: usize = 0;

    //for (locations.items, 0..) |loc, idx| {
    //    switch (loc) {
    //        PosTag.file => {
    //            result += loc.file.id * idx;
    //            //std.debug.print("mult id:{} * index:{} = {} => total result: {}\n", .{ loc.file.id, idx, loc.file.id * idx, result });
    //        },
    //        PosTag.free => {
    //            std.debug.print("{any} at {}\n", .{ loc, idx });
    //            std.debug.print("{any} at {}\n", .{ locations.items[idx + 1], idx + 1 });
    //            break;
    //        },
    //    }
    //}

    std.debug.print("Result: {}\n", .{result});
}
