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

fn main() void {
    // Initialise system clocks
    const crystal_oscillator = peripheral{ .base_address = 0x40024000 };
    crystal_oscillator.set(0x00, 0xAA0);
}

/// We get here from startup.s
export fn start() noreturn {
    main();
    while (true) {}
}
