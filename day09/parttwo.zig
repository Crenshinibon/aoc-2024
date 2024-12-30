const std = @import("std");

const fileName = "small.txt";

const Slot = struct {
    id: usize,
    type: u8,
    start_idx: usize,
    size: usize,
};

pub fn printAll(slots1: *std.ArrayList(Slot), slots2: *std.ArrayList(Slot), slots3: *std.ArrayList(Slot), slots4: *std.ArrayList(Slot)) void {
    var counter: usize = 0;
    const last_slot: Slot = slots1.items[slots1.items.len - 1];
    const last_idx: usize = last_slot.start_idx + last_slot.size;
    while (true) {
        std.debug.print("{}: |", .{counter});
        var found_1 = false;
        for (slots1.items) |slot| {
            const l_idx = slot.start_idx + slot.size - 1;
            const f_idx = slot.start_idx;
            const inside = counter >= f_idx and counter <= l_idx;
            if (inside) {
                found_1 = true;
                std.debug.print("0", .{});
            }
        }
        if (!found_1) {
            std.debug.print("_", .{});
        }
        std.debug.print("|", .{});

        var found_2 = false;
        for (slots2.items) |slot| {
            const l_idx = slot.start_idx + slot.size - 1;
            const f_idx = slot.start_idx;
            const inside = counter >= f_idx and counter <= l_idx;
            if (inside) {
                found_2 = true;
                std.debug.print("F", .{});
            }
        }
        if (!found_2) {
            std.debug.print("_", .{});
        }
        std.debug.print("|", .{});

        var found_3 = false;
        for (slots3.items) |slot| {
            const l_idx = slot.start_idx + slot.size - 1;
            const f_idx = slot.start_idx;
            const inside = counter >= f_idx and counter <= l_idx;
            if (inside) {
                found_3 = true;
                std.debug.print("{}", .{slot.id});
            }
        }
        if (!found_3) {
            std.debug.print("_", .{});
        }
        std.debug.print("|", .{});

        var found_4 = false;
        for (slots4.items) |slot| {
            const l_idx = slot.start_idx + slot.size - 1;
            const f_idx = slot.start_idx;
            const inside = counter >= f_idx and counter <= l_idx;
            if (inside) {
                found_4 = true;
                std.debug.print("{}", .{slot.id});
            }
        }
        if (!found_4) {
            std.debug.print("_", .{});
        }

        std.debug.print("|\n", .{});

        if (counter == last_idx) {
            break;
        }
        counter += 1;
    }
    std.debug.print("\n", .{});
}

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

    var filled = std.ArrayList(Slot).init(allocator);
    var copied = try files.clone();

    var free_idx: usize = 0;
    var cont = true;
    
    try filled.append(files.items[free_idx]);
    //restart on every move ...
    while(cont) {
        var free = empty.items[free_idx];
        var file_idx = files.items.len - 1;

        while (true) {
            var cf = files.items[file_idx];
            if (cf.size <= free.size) {
                cf.start_idx = free.start_idx;
                try filled.append(cf);

                free.size = free.size - cf.size;
                free.start_idx = free.start_idx + cf.size;

                _ = files.orderedRemove(file_idx);
                file_idx = files.items.len - 1;
                continue;
            }

            if (free.size == 0) {
                file_idx = files.items.len - 1;
                break;
            }

            if (file_idx > 0) {
                file_idx -= 1;
            } else {
                file_idx = files.items.len - 1;
                break;
            }
        }

        free_idx += 1;
    }

    printAll(&empty, &copied, &filled, &files);
    const result: usize = 0;

    std.debug.print("Result: {}\n", .{result});
}
