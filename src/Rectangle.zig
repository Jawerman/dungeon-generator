const rl = @import("raylib");
const Axis = @import("utils.zig").Axis;

const Self = @This();

x: i32,
y: i32,
width: i32,
height: i32,

pub fn init(x: i32, y: i32, width: i32, height: i32) Self {
    return .{
        .x = x,
        .y = y,
        .width = width,
        .height = height,
    };
}

pub fn center(self: @This()) rl.Vector2 {
    const half_width: f32 = @as(f32, @floatFromInt(self.width)) / 2.0;
    const half_height: f32 = @as(f32, @floatFromInt(self.height)) / 2.0;

    const center_x: f32 = @as(f32, @floatFromInt(self.x)) + half_width;
    const center_y: f32 = @as(f32, @floatFromInt(self.y)) + half_height;

    return .{
        .x = center_x,
        .y = center_y,
    };
}
pub fn getRectAxisOverlap(self: Self, other: Self, axis: Axis) i32 {
    var min1: i32 = undefined;
    var max1: i32 = undefined;
    var min2: i32 = undefined;
    var max2: i32 = undefined;
    switch (axis) {
        .y => {
            min1 = self.y;
            max1 = self.y + self.height;
            min2 = other.y;
            max2 = other.y + other.height;
        },
        .x => {
            min1 = self.x;
            max1 = self.x + self.width;
            min2 = other.x;
            max2 = other.x + other.width;
        },
    }
    return @min(max2, max1) - @max(min1, min2);
}
