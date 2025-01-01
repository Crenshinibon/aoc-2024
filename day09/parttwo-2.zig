const std = @import("std");

const fileName = "input.txt";

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
                    .id = compressed_pos / 2,
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

    var c_index: usize = slots.items.len - 1;
    outer: while (c_index > 0) {
        std.debug.print("{}\n", .{c_index});
        //print(&slots);

        const c_slot = slots.items[c_index];
        if (c_slot.type == 'E') {
            c_index -= 1;
            continue;
        } else {

            //find fitting slot
            for (slots.items, 0..) |e_slot, f_idx| {
                if (f_idx == c_index) {
                    if (c_index > 0) {
                        c_index -= 1;
                    }
                    continue :outer;
                }

                if (e_slot.type == 'E' and e_slot.size >= c_slot.size) {
                    const room_left = e_slot.size - c_slot.size;
                    //std.debug.print("Moving {} to {}\n", .{ c_index, f_idx });
                    _ = slots.orderedRemove(c_index);
                    const new_empty = Slot{
                        .id = 10000,
                        .type = 'E',
                        .size = c_slot.size,
                    };
                    try slots.insert(c_index, new_empty);

                    _ = slots.orderedRemove(f_idx);
                    try slots.insert(f_idx, c_slot);

                    if (room_left > 0) {
                        const new_empty_f = Slot{
                            .id = e_slot.id,
                            .type = e_slot.type,
                            .size = room_left,
                        };
                        try slots.insert(f_idx + 1, new_empty_f);
                    }
                    break;
                }
            }
        }

        //print(&slots);
        c_index -= 1;
    }

    //printAll(&empty, &copied, &filled, &files);
    var result: usize = 0;
    var start: usize = 0;
    for (slots.items) |slot| {
        if (slot.type == 'F') {
            for (0..(slot.size)) |idx| {
                const block_pos = start + idx;
                result += block_pos * slot.id;
                //std.debug.print("Adding: {} {}*{} = {}\n", .{ start, block_pos, slot.id, result });
            }
        }

        start += slot.size;
    }

    std.debug.print("Result: {}\n", .{result});
}
