const std = @import("std");

fn reportValid(report: *std.ArrayList(u16)) bool {
    var firstValue: bool = true;
    var secondValue: bool = false;

    var prevValue: u16 = 0;
    var increasingGlobal: bool = false;
    for (report.items) |lvl| {

        //skip first value
        if (firstValue) {
            prevValue = lvl;
            secondValue = true;
            firstValue = false;
            continue;
        }
        //set global direction from first pair
        if (secondValue) {
            increasingGlobal = lvl > prevValue;
            secondValue = false;
        }

        const increasingLocal = lvl > prevValue;
        //determine if increasing or decreasing
        if (increasingGlobal != increasingLocal) {
            //std.debug.print("SWITCH dir: {any}\n", .{report.items});
            return false;
        }

        var diff: u16 = undefined;
        if (increasingGlobal) {
            diff = lvl - prevValue;
        } else {
            diff = prevValue - lvl;
        }

        if (diff < 1 or diff > 3) {
            //std.debug.print("Too big difference: {} in: {any}\n", .{ diff, report.items });
            return false;
        }

        prevValue = lvl;
    }
    return true;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var arr = std.ArrayList(u8).init(allocator);
    var counterValid: usize = 0;
    var counterInvalid: usize = 0;

    while (true) {
        var report = std.ArrayList(u16).init(allocator);
        defer report.deinit();

        reader.streamUntilDelimiter(arr.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        var lvl = std.ArrayList(u8).init(allocator);
        defer lvl.deinit();

        for (arr.items) |x| {
            if (x == ' ') {
                //blank encountered ... current lvl finished
                //std.debug.print("first slice: {s}\n", .{firstSlice});
                const intValue = try std.fmt.parseInt(u16, lvl.items, 10);
                //std.debug.print("Lvl parsed value {any}\n", .{intValue});

                try report.append(intValue);
                lvl.clearAndFree();
                continue;
            }
            try lvl.append(x);
        }
        //don't forget the last value
        const intValue = try std.fmt.parseInt(u16, lvl.items, 10);
        try report.append(intValue);

        arr.clearRetainingCapacity();

        const v = reportValid(&report);
        if (v) {
            counterValid += 1;
            std.debug.print("Valid Report #{}, latest: {any}.\n", .{ counterValid, report.items });
        } else {
            //remove element after element, to see if we can find a valid report.
            var errorDamperFine = false;
            for (0..report.items.len) |idx| {
                var reportCopy = try report.clone();
                _ = reportCopy.orderedRemove(idx);
                const modifiedValid = reportValid(&reportCopy);
                if (modifiedValid) {
                    errorDamperFine = true;
                    break;
                }
            }
            if (errorDamperFine) {
                counterValid += 1;
            } else {
                counterInvalid += 1;
            }
            //std.debug.print("INVALID Report #{}, latest: {any}.\n", .{ counterInvalid, report.items });
        }
    }
    std.debug.print("Number of valid reports: {}\n", .{counterValid});
}
