//! GPIO module for the RPI PICO
const peripheral = @import("peripheral.zig").peripheral;

const GPIO_BASE: u32 = 0x40014000;

const gpio = peripheral{ .base_address = GPIO_BASE };

pub fn gpio_init() void {}
