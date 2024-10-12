const rl = @import("raylib");

pub const Axis = enum {
    x,
    y,
};

pub inline fn scaleByFloat(value: i32, scale: f32) i32 {
    return @intFromFloat(@as(f32, @floatFromInt(value)) * scale);
}
