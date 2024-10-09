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

pub fn center(self: Self) rl.Vector2 {
    const half_width: f32 = @as(f32, @floatFromInt(self.width)) / 2.0;
    const half_height: f32 = @as(f32, @floatFromInt(self.height)) / 2.0;

    const center_x: f32 = @as(f32, @floatFromInt(self.x)) + half_width;
    const center_y: f32 = @as(f32, @floatFromInt(self.y)) + half_height;

    return .{
        .x = center_x,
        .y = center_y,
    };
}

pub fn contains(self: Self, point: rl.Vector2) bool {
    const self_x: f32 = @floatFromInt(self.x);
    const self_y: f32 = @floatFromInt(self.y);
    const self_width: f32 = @floatFromInt(self.width);
    const self_height: f32 = @floatFromInt(self.height);

    return point.x > self_x and
        point.x < self_x + self_width and
        point.y > self_y and
        point.y < self_y + self_height;
}

pub fn isEqual(self: Self, other: Self) bool {
    return self.x == other.x and
        self.y == other.y and
        self.width == other.width and
        self.height == other.height;
}

pub fn getOverlap(self: Self, other: Self) Self {
    const max_min_x = @max(self.x, other.x);
    const max_min_y = @max(self.y, other.y);
    const min_max_x = @min(self.x + self.width, other.x + other.width);
    const min_max_y = @min(self.y + self.height, other.y + other.height);

    return Self{
        .x = max_min_x,
        .y = max_min_y,
        .width = max_min_x - min_max_x,
        .height = max_min_y - min_max_y,
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
