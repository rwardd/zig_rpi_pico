//! Helper file to compute the RP2040 bootloader CRC and output a final binary

const std = @import("std");

/// Main function to take an input argument to a bootloader binary path, and output a CRC'd bootloader
/// binary
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 3) return error.InvalidArgs;
    const in_path = args.ptr[1];
    const out_path = args.ptr[2];

    // We can error out here if the bootloader size is greater than 252 bytes (to allow 4 bytes for
    // CRC checksum)
    const bootloader_file = try std.fs.cwd().readFileAlloc(allocator, in_path, 252);
    defer allocator.free(bootloader_file);

    var padded_bootloader = [_]u8{0} ** 252;
    for (0..bootloader_file.len) |i| {
        padded_bootloader[i] = bootloader_file[i];
    }

    // Compute CRC and transform into an 8 bit slice to load into the finalised bootloader binary
    const crc = std.hash.crc.Crc32Mpeg2;
    const crc_data = crc.hash(&padded_bootloader);
    var crc_data_slice = [_]u8{ 0, 0, 0, 0 };
    for (0..4) |i| {
        crc_data_slice[i] = @truncate((crc_data >> @intCast(i * 8)) & 0xFF);
    }

    // Generate a final bootloader file with the bootloader code + checksum
    const bootloader_checked = try std.fs.cwd().createFile(
        out_path,
        .{ .read = true },
    );
    defer bootloader_checked.close();

    const boot_header = ".cpu cortex-m0plus\n.thumb\n.section .boot2, \"ax\"\n.byte ";
    _ = try bootloader_checked.write(boot_header);

    var bytes_written: usize = 0;
    for (0..padded_bootloader.len) |i| {
        var b: [10]u8 = undefined;
        const byte = try std.fmt.bufPrint(&b, "0x{x}, ", .{padded_bootloader[i]});
        bytes_written += try bootloader_checked.write(byte);
    }

    // Write checksum
    for (0..crc_data_slice.len - 1) |i| {
        var b: [10]u8 = undefined;
        const byte = try std.fmt.bufPrint(&b, "0x{x}, ", .{crc_data_slice[i]});
        bytes_written += try bootloader_checked.write(byte);
    }

    var b: [10]u8 = undefined;
    const byte = try std.fmt.bufPrint(&b, "0x{x}", .{crc_data_slice[crc_data_slice.len - 1]});
    bytes_written += try bootloader_checked.write(byte);
}
