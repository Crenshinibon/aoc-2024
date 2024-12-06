const std = @import("std");

// what may not be before the current page, traversing the rule backwards
const Rule = struct {
    c: usize,
    n: usize,
};

pub fn read_rules() ![]Rule {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var result = std.ArrayList(Rule).init(allocator);

    var file = try std.fs.cwd().openFile("rules.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var arr = std.ArrayList(u8).init(allocator);
    var counter: usize = 0;
    while (true) {
        reader.streamUntilDelimiter(arr.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        var firstValueDone = false;
        var firstValue = std.ArrayList(u8).init(allocator);
        defer firstValue.deinit();
        var secondValue = std.ArrayList(u8).init(allocator);
        defer secondValue.deinit();

        //std.debug.print("{}: {s}\n", .{ counter, arr.items });

        for (arr.items) |x| {
            if (x == '|') {
                firstValueDone = true;
                continue;
            }

            if (firstValueDone) {
                try secondValue.append(x);
            } else {
                try firstValue.append(x);
            }
        }
        //std.debug.print("FirstValue: {any}, SecondValue: {any}\n", .{ firstValue.items, secondValue.items });

        const intValueFirst: usize = try std.fmt.parseInt(usize, firstValue.items, 10);
        const intValueSecond: usize = try std.fmt.parseInt(usize, secondValue.items, 10);

        try result.append(Rule{ .c = intValueFirst, .n = intValueSecond });

        counter += 1;
        arr.clearRetainingCapacity();
    }
    return result.items;
}

pub fn read_updates() !std.ArrayList(std.ArrayList(usize)) {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var result = std.ArrayList(std.ArrayList(usize)).init(allocator);

    var file = try std.fs.cwd().openFile("updates.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var arr = std.ArrayList(u8).init(allocator);
    while (true) {
        reader.streamUntilDelimiter(arr.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        var update = std.ArrayList(usize).init(allocator);
        var value = std.ArrayList(u8).init(allocator);
        defer value.deinit();

        for (arr.items) |x| {
            if (x == ',') {
                const intValue: usize = try std.fmt.parseInt(usize, value.items, 10);
                try update.append(intValue);

                value.clearAndFree();
                continue;
            }
            try value.append(x);
        }
        const intValue: usize = try std.fmt.parseInt(usize, value.items, 10);
        try update.append(intValue);

        value.clearAndFree();

        try result.append(update);
        arr.clearRetainingCapacity();
    }
    return result;
}

pub fn fixFailing(failingUpdate: []usize, rules: *const []Rule, allocator: std.mem.Allocator) !std.ArrayList(usize) {
    var result = std.ArrayList(usize).init(allocator);
    for (failingUpdate) |it| {
        try result.append(it);
    }
    //var result = try failingUpdate.clone();
    //std.ArrayList(usize).init(allocator);
    //defer result.deinit();

    var fixed = false;
    for (0..(result.items.len - 1)) |idx| {
        const c = result.items[idx];
        const n = result.items[idx + 1];

        for (rules.*) |rule| {
            if (rule.c == n and rule.n == c) {
                fixed = true;
                result.items[idx] = n;
                result.items[idx + 1] = c;
            }
        }
    }

    if (fixed) {
        std.debug.print("redoing it\n", .{});
        result = try fixFailing(result.items, rules, allocator);
    } else {
        //defer result.deinit();
    }

    return result;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var sum: usize = 0;
    const rules = try read_rules();
    const updates = try read_updates();
    defer updates.deinit();

    var failingUpdates = std.ArrayList(std.ArrayList(usize)).init(allocator);
    defer failingUpdates.deinit();

    for (updates.items) |upd| {
        var updValid = true;

        for (0..(upd.items.len - 1)) |idx| {
            var ruleFound = false;
            for (rules) |rule| {
                if (rule.c == upd.items[idx] and rule.n == upd.items[idx + 1]) ruleFound = true;

                if (ruleFound) {
                    break;
                }
            }
            if (!ruleFound) {
                updValid = false;
            }
        }
        if (updValid) {
            const middleIndex = (upd.items.len - 1) / 2;
            //std.debug.print("Middle Index {} - {}\n", .{ middleIndex, upd.items.len });
            const middleValue = upd.items[middleIndex];
            sum += middleValue;
        } else {
            try failingUpdates.append(upd);
        }
    }
    std.debug.print("Sum: {}\n", .{sum});

    var fixed = std.ArrayList(std.ArrayList(usize)).init(allocator);
    defer fixed.deinit();
    //for (failingUpdates.items) |upd| {
    //    try fixed.append(try fixFailing(upd, &rules));
    //}
    try fixed.append(try fixFailing(failingUpdates.items[0].items, &rules, allocator));

    std.debug.print("Fixed {any}\n", .{fixed.items.len});
}
