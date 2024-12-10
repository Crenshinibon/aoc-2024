const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var first = std.ArrayList(u17).init(allocator);
    defer first.deinit();
    var second = std.ArrayList(u17).init(allocator);
    defer second.deinit();

    var arr = std.ArrayList(u8).init(allocator);
    var counter: usize = 0;
    while (true) {
        reader.streamUntilDelimiter(arr.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        var firstValue = std.ArrayList(u8).init(allocator);
        defer firstValue.deinit();

        var secondValue = std.ArrayList(u8).init(allocator);
        defer secondValue.deinit();

        var firstValueDone: bool = false;
        for (arr.items) |x| {
            //std.debug.print("Current char {}\n", .{x});
            //std.debug.print("First Value Done {}\n", .{firstValueDone});

            if (x == ' ' and !firstValueDone) {
                //blank encountered ... first value finished
                firstValueDone = true;

                const firstSlice = firstValue.items;
                //std.debug.print("first slice: {s}\n", .{firstSlice});
                const firstIntValue = try std.fmt.parseInt(u17, firstSlice, 10);
                std.debug.print("First parsed value {}\n", .{firstIntValue});

                try first.append(firstIntValue);
                continue;
            }

            if (!firstValueDone) {
                try firstValue.append(x);
                //                std.debug.print("First value {any}\n", .{firstValue});
            } else if (x != ' ') {
                try secondValue.append(x);
                // std.debug.print("Second value {any}\n", .{secondValue});
            }
        }

        const secondSlice = secondValue.items;
        const secondIntValue = try std.fmt.parseInt(u17, secondSlice, 10);
        std.debug.print("Second parsed value {}\n", .{secondIntValue});
        //std.debug.print("First: {any} Second: {any}", .{ firstValue.items, secondValue.items });

        try second.append(secondIntValue);
        firstValueDone = false;
        counter += 1;
        arr.clearRetainingCapacity();
    }
    std.debug.print("Length first {}. Length second {}\n", .{ first.items.len, second.items.len });

    std.mem.sort(u17, first.items, {}, comptime std.sort.asc(u17));
    std.mem.sort(u17, second.items, {}, comptime std.sort.asc(u17));

    var sum: u32 = 0;
    for (0..first.items.len) |idx| {
        var diff: u32 = 0;

        const firstItem = first.items[idx];
        const secondItem = second.items[idx];
        if (firstItem < secondItem) {
            diff = secondItem - firstItem;
        } else {
            diff = firstItem - secondItem;
        }
        sum = sum + diff;
    }

    std.debug.print("Sum: {}\n", .{sum});
}
