//! GPIO module for the RPI PICO
const peripheral = @import("peripheral.zig").peripheral;

const GPIO_BASE: u32 = 0x40014000;

pub const GPIO = struct {
    const Self = @This();
    base_address: u32,

    pub fn set(self: Self, offset: usize, value: u32) void {
        const address: *volatile u32 = @ptrFromInt(self.base_address + offset);
        address.* = value;
    }

    pub fn get(self: Self, offset: usize) u32 {
        const address: *volatile u32 = @ptrFromInt(self.base_address + offset);
        return address.*;
    }

    pub fn init() void {}
    pub fn set_function(self: Self, pin: u32, function: u32) void {
        self.set(pin, function);
    }
};
