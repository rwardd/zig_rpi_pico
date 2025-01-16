pub const peripheral = struct {
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
};
