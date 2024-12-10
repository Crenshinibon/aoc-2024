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

    var potDo: []const u8 = "";
    var potDont: []const u8 = "";
    var do: bool = true;

    while (true) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        if (do) {
            // loook for potential mul
            if (byte == 'm' and std.mem.eql(u8, potMul, "")) {
                potMul = "m";
                continue;
            } else if (byte == 'u' and std.mem.eql(u8, potMul, "m")) {
                potMul = "mu";
                continue;
            } else if (byte == 'l' and std.mem.eql(u8, potMul, "mu")) {
                potMul = "mul";
                continue;
            } else if (byte == '(' and std.mem.eql(u8, potMul, "mul")) {
                potMul = "mul(";
                continue;
            } else if (byte >= '0' and byte <= '9' and std.mem.eql(u8, potMul, "mul(") and num1StrLength <= 3) {
                num1Arr[num1StrLength] = byte;
                num1StrLength += 1;
                continue;
            } else if (byte == ',' and std.mem.eql(u8, potMul, "mul(") and num1Arr.len >= 1) {
                potMul = "mul(,";
                continue;
            } else if (byte >= '0' and byte <= '9' and std.mem.eql(u8, potMul, "mul(,") and num2StrLength <= 3) {
                num2Arr[num2StrLength] = byte;
                num2StrLength += 1;
                continue;
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
                continue;
            }

            // look for don't
            if (byte == 'd' and std.mem.eql(u8, potDont, "")) {
                potDont = "d";
                continue;
            } else if (byte == 'o' and std.mem.eql(u8, potDont, "d")) {
                potDont = "do";
                continue;
            } else if (byte == 'n' and std.mem.eql(u8, potDont, "do")) {
                potDont = "don";
                continue;
            } else if (byte == '\'' and std.mem.eql(u8, potDont, "don")) {
                potDont = "don'";
                continue;
            } else if (byte == 't' and std.mem.eql(u8, potDont, "don'")) {
                potDont = "don't";
                continue;
            } else if (byte == '(' and std.mem.eql(u8, potDont, "don't")) {
                potDont = "don't(";
                continue;
            } else if (byte == ')' and std.mem.eql(u8, potDont, "don't(")) {
                potDont = "";
                do = false;
                std.debug.print("Switching to dont\n", .{});
                continue;
            }

            potDont = "";
            potMul = "";
            num1Arr = [3]u8{ 0, 0, 0 };
            num1StrLength = 0;
            num2Arr = [3]u8{ 0, 0, 0 };
            num2StrLength = 0;
        } else {
            //look for do
            if (byte == 'd' and std.mem.eql(u8, potDo, "")) {
                potDo = "d";
            } else if (byte == 'o' and std.mem.eql(u8, potDo, "d")) {
                potDo = "do";
            } else if (byte == '(' and std.mem.eql(u8, potDo, "do")) {
                potDo = "do(";
            } else if (byte == ')' and std.mem.eql(u8, potDo, "do(")) {
                potDo = "";
                do = true;
                std.debug.print("Switching to do\n", .{});
            } else {
                potDo = "";
            }
        }
    }
    std.debug.print("Mul Result: {}\n", .{sum});
}
