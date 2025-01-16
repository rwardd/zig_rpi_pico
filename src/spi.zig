const peripheral = @import("peripheral.zig").peripheral;

// reset base = 0x4000c000

///
/// Inspired by
/// https://github.com/raspberrypi/pico-sdk/blob/master/src/rp2_common/hardware_spi/spi.c
/// https://github.com/ZigEmbeddedGroup/microzig/blob/main/port/raspberrypi/rp2xxx/src/hal/spi.zig
///
pub const SPI = struct {
    const Self = @This();
    base_address: usize,

    pub fn set(self: Self, offset: usize, value: u32) void {
        const address: *volatile u32 = @ptrFromInt(self.base_address + offset);
        address.* = value;
    }

    pub fn get(self: Self, offset: usize) u32 {
        const address: *volatile u32 = @ptrFromInt(self.base_address + offset);
        return address.*;
    }

    fn reset(self: Self) void {
        _ = self;
    }

    fn start(self: Self, baudrate: u32) void {
        self.set_baudrate(baudrate);
    }

    inline fn is_writable(self: Self) bool {
        return (self.get(0x0C) & 0x02) == 1;
    }

    inline fn is_readable(self: Self) bool {
        return (self.get(0x0C) & 0x04) == 1;
    }

    pub fn write(self: Self, data: []const u32) usize {
        for (data) |byte| {
            while (!self.is_writable()) {}
            self.set(0x08, byte);
        }

        // Drain RX FIFO
        while (self.is_readable()) {
            _ = self.get(0x08);
        }
        while ((self.get(0x0C) & 0x10) == 1) {}
        while (self.is_readable()) {
            _ = self.get(0x08);
        }

        self.set(0x20, 0x01);
        return data.len;
    }

    fn set_baudrate(self: Self, baudrate: u32) void {
        const freq_in = 12_000_000; // Our peripheral clock is running at 12 MHz

        var prescale: u64 = 2;
        while (prescale <= 254) : (prescale += 2) {
            if (freq_in < prescale * 256 * baudrate) break;
        }

        var postdiv: u64 = 256;
        while (postdiv > 1) : (postdiv -= 1) {
            if (freq_in / (prescale * (postdiv - 1)) > baudrate) break;
        }

        self.set(0x10, @as(u32, @intCast(prescale))); // Set CPSR
        self.set(0x00, @as(u32, @intCast(postdiv - 1)) << 8); // Set SCR in CR0
    }

    pub fn init(self: Self, baudrate: u32, data_bits: u32, cpha: u32, cpol: u32) void {
        self.set(0x04, 0x00); // Disable SPI
        self.start(baudrate);
        const properties: u32 = (data_bits - 1) << 0 | cpol << 6 | cpha << 7;

        self.set(0x00, self.get(0x00) | properties);
        self.set(0x04, 0x02); // Enable SPI in master mode

    }
};
