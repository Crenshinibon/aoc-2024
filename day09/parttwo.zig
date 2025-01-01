const std = @import("std");

const fileName = "small.txt";

const Slot = struct {
    id: usize,
    type: u8,
    size: usize,
};

pub fn print(slots: *std.ArrayList(Slot)) void {
    for (slots.items, 0..) |slot, idx| {
        if (slot.type == 'F') {
            std.debug.print("{}: {c} => id: {} size: {}\n", .{ idx, slot.type, slot.id, slot.size });
        } else {
            std.debug.print("{}: {c} => emtpy size: {}\n", .{ idx, slot.type, slot.size });
        }
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
            if (rev_slot.size <= target_len) {
                return rev_index;
            }
            rev_index -= 1;
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
    while (true) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        if (byte >= 48 and byte <= 58) {
            const size: u8 = byte - 48;
            if (compressed_pos % 2 == 0) {
                try slots.append(Slot{
                    .id = compressed_pos,
                    .type = 'F',
                    .size = size,
                });
            } else {
                try slots.append(Slot{
                    .id = compressed_pos,
                    .type = 'E',
                    .size = size,
                });
            }

            compressed_pos += 1;
        } else {
            std.debug.print("Found other char: {}\n", .{byte});
        }
    }

    print(&slots);

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
                if (rev_index == null or rev_index.? < c_index) {
                    break;
                }

                const rev_slot = slots.items[rev_index.?];
                to_fill -= rev_slot.size;
                const moved_file = Slot{
                    .id = rev_slot.id,
                    .type = rev_slot.type,
                    .size = rev_slot.size,
                };

                //check if rev_index + 1 == empty and rev_index - 1 == empty, if so merge
                // don't do it for the last index
                if (rev_index.? < (slots.items.len - 1)) {
                    const rev_slot_minus_1 = slots.items[rev_index.? - 1];
                    const rev_slot_plus_1 = slots.items[rev_index.? + 1];
                    if (rev_slot_minus_1.type == 'E' and rev_slot_plus_1.type == 'E') {
                        const merged_empty = Slot{
                            .id = rev_slot_minus_1.id,
                            .type = 'E',
                            .size = rev_slot_minus_1.size + rev_slot_plus_1.size,
                        };

                        _ = slots.orderedRemove(rev_index.? + 1);
                        _ = slots.orderedRemove(rev_index.? - 1);
                        try slots.insert(rev_index.? - 1, merged_empty);
                    }
                }
                //remove found file in the back
                _ = slots.orderedRemove(rev_index.?);

                //remove empty slot in the front
                _ = slots.orderedRemove(c_index);

                //if still room left
                if (to_fill > 0) {
                    std.debug.print("not filled up, left {}\n", .{to_fill});
                    //insert new empty slot at old_index
                    const new_empty = Slot{
                        .id = c_slot.id,
                        .type = c_slot.type,
                        .size = to_fill,
                    };
                    try slots.insert(c_index, new_empty);
                }

                //insert the file in the front
                try slots.insert(c_index, moved_file);
                print(&slots);

                if (to_fill > 0) {
                    c_index += 1;
                }
            }
        }

        c_index += 1;
    }

    //printAll(&empty, &copied, &filled, &files);
    var result: usize = 0;
    for (slots.items, 0..) |slot, start_idx| {
        if (slot.type == 'F') {
            for (0..(slot.size - 1)) |idx| {
                result += idx + start_idx * slot.id;
            }
        }
    }

    std.debug.print("Result: {}\n", .{result});
}
