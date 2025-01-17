const peripheral = @import("peripheral.zig").peripheral;
const SPI = @import("spi.zig").SPI;
const GPIO = @import("gpio.zig").GPIO;
const display = @import("display.zig");

fn initialise_clocks() void {
    // Initialise system clocks
    const crystal_oscillator = peripheral{ .base_address = 0x40024000 };

    crystal_oscillator.set(0x00, 0xAA0); // Set to 1 - 15 MHz
    crystal_oscillator.set(0x0C, 0x2F); // Startup delay (datasheet value)
    crystal_oscillator.set(0x2000, 0xFAB000); // Magic word to enable

    // Wait for oscillator to stabilise
    while ((crystal_oscillator.get(0x04) & 0x80000000) == 0) {}

    const clock = peripheral{ .base_address = 0x40008000 };
    clock.set(0x30, 0x02); // REFCLK source is external oscillator
    clock.set(0x3C, 0x00);
    clock.set(0x34, 0x100);
    clock.set(0x48, 0x880);
}
fn initialise_hardware() void {
    const reset_bank = peripheral{ .base_address = 0x4000C000 };

    // IO bank reset
    reset_bank.set(0x3000, 0x20);
    while ((reset_bank.get(0x08) & 0x20) == 0) {}

    // PAD bank reset
    reset_bank.set(0x3000, 0x100);
    while ((reset_bank.get(0x08) & 0x100) == 0) {}

    // UART 0 reset
    reset_bank.set(0x3000, 0x400000);
    while ((reset_bank.get(0x08) & 0x400000) == 0) {}

    reset_bank.set(0x3000, 0x10000);
    while ((reset_bank.get(0x08) & 0x10000) == 0) {}
}

fn initialise_uart(uart: *const peripheral, sio: *const peripheral) void {
    uart.set(0x24, 0x4e); // 9600 baud rate (integer register)
    uart.set(0x28, 0x08); // 9600 baud rate (fractional register)

    uart.set(0x2C, 0x70); // Char length + FIFO
    uart.set(0x30, 0x301); // UART TX + RX enable

    // Configure UART hardware
    const io_bank0 = peripheral{ .base_address = 0x40014000 };
    io_bank0.set(0x04, 0x02);
    io_bank0.set(0x0C, 0x02);
    io_bank0.set(0xCC, 0x02);

    sio.set(0x24, 0x2000000);
}

fn uart_putchar(uart: *const peripheral, char: u32) void {
    while ((uart.get(0x18) & 0x20) != 0) {}
    uart.set(0x00, char);
}

fn uart_puts(uart: *const peripheral, msg: []const u8) void {
    for (msg) |b| {
        uart_putchar(uart, b);
    }
}

fn main() void {
    initialise_clocks();
    initialise_hardware();
    const uart = peripheral{ .base_address = 0x40034000 };
    const spi = SPI{ .base_address = 0x4003c000 };
    const gpio = GPIO{ .base_address = 0x40014000 };
    const sio = peripheral{ .base_address = 0xd0000000 };

    gpio.set_function(0x9c, 0x01); // SPI0 TX @ GPIO Pin 19
    gpio.set_function(0x94, 0x01); // SPI0 SCK @ GPIO Pin 18
    gpio.set_function(0xa4, 0x05); // Display reset @ GPIO Pin 20
    gpio.set_function(0xac, 0x05); // Display Data Command @ GPIO Pin 21
    sio.set(0x20, @intCast((1 << 20) | (1 << 21))); // Set OE for reset & data command

    spi.init(1_000_000, 8, 1, 1); // 8 data bits, clock phase and polarity inverted
    initialise_uart(&uart, &sio);

    display.reset(&sio);
    display.init(&spi, &sio);
    display.clear_screen(&spi, &sio, 0x0000);
    display.set_position(50, 20);
    display.draw_string(&spi, &sio, "Hello, Zig.", 0xFFFF);
    while (true) {
        uart_puts(&uart, "Hello, World\r\n");
        var counter: u32 = 0;
        while (counter != 0xFFFFFF) {
            counter += 1;
        }
    }
}

/// We get here from startup.s
export fn start() noreturn {
    main();
    while (true) {}
}
