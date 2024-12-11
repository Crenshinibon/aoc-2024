const std = @import("std");

const fileName = "input.txt";

const StoneReader = struct {
    reader: std.io.GenericReader,
    allocator: std.mem.Allocator,
    file: std.fs.File,

    const Self = @This();
    pub fn init(file_name: []const u8, allocator: std.mem.Allocator) !Self {
        var file = try std.fs.cwd().openFile(file_name, .{});
        var buffered = std.io.bufferedReader(file.reader());
        const reader = buffered.reader();
        @compileLog(@TypeOf(reader));

        return .{ .allocator = allocator, .reader = reader, .file = file };
    }

    pub fn nextStone(self: *Self) ?[]u8 {
        var buf: [128]u8 = self.allocator.create(u8, 128);
        defer self.allocator.free(buf);

        const stone_str = try self.reader.readUntiDelimiterOrEof(&buf, ' ');
        var clean = try self.allocator.alloc(u8, stone_str.len);

        var stone_length: usize = 0;
        for (stone_str, 0..) |c, idx| {
            if (c >= 48 and c <= 57) {
                clean[idx] = c;
                stone_length += 1;
            }
        }

        return clean.*;
    }

    pub fn deinit(self: *Self) !void {
        defer self.file.close();
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const stone_reader: StoneReader = try StoneReader.init("input.txt", allocator);
    defer stone_reader.deinit();

    var stones: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
    defer stones.deinit();

    while (true) {
        const clean = stone_reader.nextStone();
        if (clean == null) {
            break;
        }
        //const stone = try std.fmt.parseInt(usize, clean.items, 10);
        try stones.append(clean);
        //std.debug.print("parsed {any}\n", .{stones.items});
    }
    std.debug.print("Initial\n", .{});
    for (stones.items, 0..) |stone, idx| {
        std.debug.print("  {}: {s}", .{ idx + 1, stone });
    }
    std.debug.print("\n", .{});

    const iterations: usize = 25;
    var current_iteraton: usize = 0;

    while (current_iteraton < iterations) : (current_iteraton += 1) {
        var new_stones: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(allocator);
        defer new_stones.deinit();

        for (stones.items) |stone| {
            //std.debug.print("CURRENT_STONE: {s}, {any}\n", .{ stone, stone });
            //rule 1
            if (stone.len == 1 and stone[0] == '0') {
                try new_stones.append("1");
                //for (new_stones.items) |ns| {
                //    std.debug.print("NEW STONES 0=>1: {s} == {any} \n", .{ ns, ns });
                //}
            } else if (stone.len % 2 == 0) {
                const half = stone.len / 2;
                var first_half = try allocator.alloc(u8, half);
                errdefer allocator.free(first_half);
                var second_half = try allocator.alloc(u8, half);
                errdefer allocator.free(second_half);

                for (stone, 0..) |s, idx| {
                    if (idx < half) {
                        first_half[idx] = s;
                    } else {
                        second_half[idx - half] = s;
                    }
                }
                try new_stones.append(first_half);

                //std.debug.print("stone: {s} - half: {} fhalf: {s} - shalf: {s}\n", .{ stone, half, first_half, second_half });

                const int_value = try std.fmt.parseInt(usize, second_half, 10);

                const sec_buf: []u8 = try allocator.alloc(u8, 16);
                errdefer allocator.free(sec_buf);

                const sec_str = try std.fmt.bufPrint(sec_buf, "{}", .{int_value});
                try new_stones.append(sec_str);

                //for (new_stones.items) |ns| {
                //    std.debug.print("NEW STONES SPLIT:  {s} == {any} \n", .{ ns, ns });
                //}
            } else {
                const int_value = try std.fmt.parseInt(usize, stone, 10);
                const new_value = int_value * 2024;

                const vbuf: []u8 = try allocator.alloc(u8, 32);
                errdefer allocator.free(vbuf);

                const str = try std.fmt.bufPrint(vbuf, "{}", .{new_value});
                //std.debug.print("{} => {s}, {s} == {any}  (len: {})\n", .{ new_value, vbuf, str, str, str.len });

                try new_stones.append(str);
                //for (new_stones.items) |ns| {
                //    std.debug.print("NEW STONES MULT: {} => {s} == {any} \n", .{ int_value, ns, ns });
                //}
            }
        }

        stones.clearRetainingCapacity();
        //std.debug.print("\n", .{});

        try stones.appendSlice(new_stones.items);

        //std.debug.print("Iteraton {}\n", .{current_iteraton});
        //for (stones.items, 0..) |stone, idx| {
        //    std.debug.print("  {}: {s}", .{ idx + 1, stone });
        //}
        //std.debug.print("\n", .{});
    }

    std.debug.print("Result: {}\n", .{stones.items.len});
}
