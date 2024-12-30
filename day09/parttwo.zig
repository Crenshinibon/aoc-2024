const std = @import("std");

const fileName = "small.txt";

const Slot = struct {
    id: usize,
    type: u8,
    start_idx: usize,
    size: usize,
};

pub fn print(slots: *std.ArrayList(Slot)) void {
    var counter: usize = 0;
    const last_slot: Slot = slots.items[slots.items.len - 1];
    const last_idx: usize = last_slot.start_idx + last_slot.size;
    while (true) {
        std.debug.print("{}: ", .{counter});
        var found_one = false;
        for (slots.items) |slot| {
            const l_idx = slot.start_idx + slot.size - 1;
            const f_idx = slot.start_idx;
            const inside = counter >= f_idx and counter <= l_idx;
            if (inside) {
                found_one = true;
                if (slot.type == 'F') {
                    std.debug.print("{}", .{slot.id});
                }
                if (slot.type == 'E') {
                    std.debug.print(".", .{});
                }
            }
        }
        if (!found_one) {
            std.debug.print("-", .{});
        }

        if (counter == last_idx) {
            break;
        }
        counter += 1;

        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var files = std.ArrayList(Slot).init(allocator);
    var empty = std.ArrayList(Slot).init(allocator);

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
                try files.append(Slot{
                    .id = compressed_pos,
                    .type = 'F',
                    .start_idx = start_idx,
                    .size = size,
                });
            } else {
                try empty.append(Slot{
                    .id = compressed_pos,
                    .type = 'E',
                    .start_idx = start_idx,
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

    var filled = std.ArrayList(Slot).init(allocator);

    var forward_idx: usize = 0;
    try filled.append(files.items[forward_idx]);

    for (0..(empty.items.len - 1)) |free_idx| {
        var free = empty.items[free_idx];

        var file_idx = files.items.len - 1;
        while (true) {
            var cf = files.items[file_idx];
            if (cf.size < free.size) {
                cf.start_idx = free.start_idx;
                try filled.append(cf);

                free.size = free.size - cf.size;
                free.start_idx = free.start_idx + cf.size;

                continue;
            }

            if (free.size == 0) {
                break;
            }

            if (file_idx > 0) {
                file_idx -= 1;
            } else {
                break;
            }
        }
        forward_idx += 1;
        try filled.append(files.items[forward_idx]);
    }
    std.debug.print("filled:\n", .{});
    print(&filled);
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
