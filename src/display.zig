const SPI = @import("spi.zig").SPI;
const peripheral = @import("peripheral.zig").peripheral;

pub fn set_window(spi: *const SPI, sio: *const peripheral, x: u16, xe: u16, y: u16, ye: u16) void {
    sio.set_bit(0x18, @intCast(1 << 21)); // Clear Data command
    _ = spi.write(&[_]u32{0x2A}); // CASET command
    sio.set_bit(0x10, @intCast(1 << 21)); // SET Data command

    _ = spi.write(&[_]u32{@intCast(x >> 8)});
    _ = spi.write(&[_]u32{@intCast(x & 0xFF)});
    _ = spi.write(&[_]u32{@intCast(xe >> 8)});
    _ = spi.write(&[_]u32{@intCast(xe & 0xFF)});

    sio.set_bit(0x18, @intCast(1 << 21)); // Clear Data command
    _ = spi.write(&[_]u32{0x2B}); // CASET command
    sio.set_bit(0x10, @intCast(1 << 21)); // Clear Data command
    _ = spi.write(&[_]u32{@intCast(y >> 8)});
    _ = spi.write(&[_]u32{@intCast(y & 0xFF)});
    _ = spi.write(&[_]u32{@intCast(ye >> 8)});
    _ = spi.write(&[_]u32{@intCast(ye & 0xFF)});
}

pub fn send_colour(spi: *const SPI, sio: *const peripheral, colour: u16, count: u32) void {
    sio.set_bit(0x18, @intCast(1 << 21)); // Clear Data command
    _ = spi.write(&[_]u32{0x2C}); // CASET command
    sio.set_bit(0x10, @intCast(1 << 21)); // Clear Data command

    var counter = count;
    while (counter != 0) : (counter -= 1) {
        _ = spi.write(&[_]u32{@intCast(colour >> 8)});
        _ = spi.write(&[_]u32{@intCast(colour & 0xFF)});
    }
}

pub fn draw_line(spi: *const SPI, sio: *const peripheral, x: u16, xe: u16, y: u16, colour: u16) void {
    //sio.set_bit(0x18, @intCast(1 << 20)); // Clear Reset (active low)
    set_window(spi, sio, x, xe, y, y);
    send_colour(spi, sio, colour, xe - x);
    //sio.set_bit(0x10, @intCast(1 << 20)); // Clear Reset (active low)

}

pub fn reset(sio: *const peripheral) void {
    sio.set_bit(0x10, @intCast(1 << 20)); // Set Reset (active low)
    var counter: u32 = 0;
    while (counter != 0xFFF) {
        counter += 1;
    }

    sio.set_bit(0x18, @intCast(1 << 20)); // Clear Reset (active low)

    counter = 0;
    while (counter != 0xFFFF) {
        counter += 1;
    }

    sio.set_bit(0x10, @intCast(1 << 20)); // Set Reset (active low)
    counter = 0;
    while (counter != 0xFFFF) {
        counter += 1;
    }
}

fn delay() void {
    var counter: u32 = 0;
    while (counter != 0xFFFF) {
        counter += 1;
    }
}

pub fn init(spi: *const SPI, sio: *const peripheral) void {
    sio.set_bit(0x18, @intCast(1 << 21)); // Clear Data command
    _ = spi.write(&[_]u32{0x01}); // RESET
    delay();
    _ = spi.write(&[_]u32{0x11}); // Wake up

    delay();
    _ = spi.write(&[_]u32{0x3A}); // colour mode
    sio.set_bit(0x10, @intCast(1 << 21)); // Set Data command

    delay();
    _ = spi.write(&[_]u32{0x55}); // RGB 565
    delay();
    sio.set_bit(0x18, @intCast(1 << 21)); // Clear Data command
    _ = spi.write(&[_]u32{0x21}); // colour inversion

    delay();
    _ = spi.write(&[_]u32{0x29}); // display on
    sio.set_bit(0x10, @intCast(1 << 21)); // set Data command
    delay();

    sio.set_bit(0x18, @intCast(1 << 21)); // Clear Data command
    _ = spi.write(&[_]u32{0x36}); // madctl
    sio.set_bit(0x10, @intCast(1 << 21)); // set Data command
    _ = spi.write(&[_]u32{0xA0}); // madctl data
}
