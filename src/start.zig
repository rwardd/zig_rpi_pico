const peripheral = struct {
    const Self = @This();
    base_address: usize,

    pub fn set(self: Self, offset: usize, value: u32) void {
        const address: *volatile u32 = @ptrFromInt(self.base_address + offset);
        address.* = value;
    }

    fn get(self: Self, offset: usize) u32 {
        const address: *volatile u32 = @ptrFromInt(self.base_address + offset);
        return address.*;
    }
};

fn initialise_clocks() void {
    // Initialise system clocks
    const crystal_oscillator = peripheral{ .base_address = 0x40024000 };

    crystal_oscillator.set(0x00, 0xAA0); // Set to 1 - 15 MHz
    crystal_oscillator.set(0x0C, 0x2F); // Startup delay (datasheet value)
    crystal_oscillator.set(0x2000, 0xFAB000); // Magic word to enable

    // Wait for oscillator to stabilise
    while ((crystal_oscillator.get(0x04) & 0x80000000) == 0) {}

    const clock = peripheral{ .base_address = 0x40008000 };
    clock.set(0x30, 0x02);
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
}

fn initialise_uart(uart: *const peripheral) void {
    uart.set(0x24, 0x4e); // 9600 baud rate (integer register)
    uart.set(0x28, 0x08); // 9600 baud rate (fractional register)

    uart.set(0x2C, 0x70); // Char length + FIFO
    uart.set(0x30, 0x301); // UART TX + RX enable

    // Configure UART hardware
    const io_bank0 = peripheral{ .base_address = 0x40014000 };
    io_bank0.set(0x04, 0x02);
    io_bank0.set(0x0C, 0x02);
    io_bank0.set(0xCC, 0x02);

    const sio = peripheral{ .base_address = 0xD0000000 };
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
    const uart = peripheral{ .base_address = 0x40034000 };
    initialise_clocks();
    initialise_hardware();
    initialise_uart(&uart);
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
