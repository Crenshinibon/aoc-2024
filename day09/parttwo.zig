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

pub fn findReverseFileIdx(slots: *std.ArrayList(Slot), target_len: usize) ?usize {
    var rev_index: usize = slots.items.len - 1;
    while (rev_index >= 0) {
        const rev_slot = slots.items[rev_index];
        if (rev_slot.type == 'E') {
            rev_index -= 1;
            continue;
        } else {
            rev_index -= 1;
            if (rev_slot.size <= target_len) {
                return rev_index;
            }
        }
    }
    return null;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var slots = std.ArrayList(Slot).init(allocator);

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
                try slots.append(Slot{
                    .id = compressed_pos,
                    .type = 'F',
                    .start_idx = start_idx,
                    .size = size,
                });
            } else {
                try slots.append(Slot{
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

    var c_index: usize = 0;
    while (c_index < slots.items.len) {
        std.debug.print("{}\n", .{c_index});
        const c_slot = slots.items[c_index];
        if (c_slot.type == 'F') {
            c_index += 1;
            continue;
        } else {
            var to_fill = c_slot.size;

            while (to_fill > 0) {
                std.debug.print("to_fill: {}\n", .{to_fill});

                const rev_index = findReverseFileIdx(&slots, to_fill);
                std.debug.print("rev_index: {?}\n", .{rev_index});

                // nothing found, continue
                if (rev_index == null) {
                    break;
                }

                const rev_slot = slots.items[rev_index.?];
                std.debug.print("rev_slot: {any}", .{rev_slot});
                to_fill -= rev_slot.size;

                const moved_file = Slot{
                    .id = rev_slot.id,
                    .type = rev_slot.type,
                    .start_idx = c_index,
                    .size = rev_slot.size,
                };

                //remove found file in the back
                _ = slots.orderedRemove(rev_index.?);

                //remove empty slot in the front
                _ = slots.orderedRemove(c_index);

                //if still room left
                if (to_fill > 0) {
                    //insert new empty slot at old_index
                    const new_empty_idx = c_slot.start_idx + rev_slot.size;
                    const new_empty = Slot{
                        .id = c_slot.id,
                        .start_idx = new_empty_idx,
                        .type = c_slot.type,
                        .size = to_fill,
                    };
                    try slots.insert(c_index, new_empty);
                }

                //insert the file in the front
                try slots.insert(c_index, moved_file);
                std.debug.print("{any}\n", .{moved_file});
            }
        }

        c_index += 1;
    }

    //printAll(&empty, &copied, &filled, &files);
    const result: usize = 0;

    std.debug.print("Result: {}\n", .{result});
}
