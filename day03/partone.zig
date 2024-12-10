const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var sum: u64 = 0;

    var potMul: []const u8 = "";
    var num1Arr = [3]u8{ 0, 0, 0 };
    var num1StrLength: u8 = 0;
    var num2Arr = [3]u8{ 0, 0, 0 };
    var num2StrLength: u8 = 0;

    while (true) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        if (byte == 'm' and std.mem.eql(u8, potMul, "")) {
            potMul = "m";
        } else if (byte == 'u' and std.mem.eql(u8, potMul, "m")) {
            potMul = "mu";
        } else if (byte == 'l' and std.mem.eql(u8, potMul, "mu")) {
            potMul = "mul";
        } else if (byte == '(' and std.mem.eql(u8, potMul, "mul")) {
            potMul = "mul(";
        } else if (byte >= '0' and byte <= '9' and std.mem.eql(u8, potMul, "mul(") and num1StrLength <= 3) {
            num1Arr[num1StrLength] = byte;
            num1StrLength += 1;
        } else if (byte == ',' and std.mem.eql(u8, potMul, "mul(") and num1Arr.len >= 1) {
            potMul = "mul(,";
        } else if (byte >= '0' and byte <= '9' and std.mem.eql(u8, potMul, "mul(,") and num2StrLength <= 3) {
            num2Arr[num2StrLength] = byte;
            num2StrLength += 1;
        } else if (byte == ')' and std.mem.eql(u8, potMul, "mul(,") and num1StrLength >= 1 and num2StrLength >= 1) {
            std.debug.print("Found complete mul operation\n", .{});
            const intVal1 = try std.fmt.parseInt(u32, num1Arr[0..num1StrLength], 10);
            const intVal2 = try std.fmt.parseInt(u32, num2Arr[0..num2StrLength], 10);
            const fact = intVal1 * intVal2;
            std.debug.print("Multiplied {} with {} and got {} adding up to {}\n", .{ intVal1, intVal2, fact, sum });
            sum = sum + fact;

            potMul = "";
            num1Arr = [3]u8{ 0, 0, 0 };
            num1StrLength = 0;
            num2Arr = [3]u8{ 0, 0, 0 };
            num2StrLength = 0;
        } else {
            potMul = "";
            num1Arr = [3]u8{ 0, 0, 0 };
            num1StrLength = 0;
            num2Arr = [3]u8{ 0, 0, 0 };
            num2StrLength = 0;
        }
    }
    std.debug.print("Mul Result: {}\n", .{sum});
}
