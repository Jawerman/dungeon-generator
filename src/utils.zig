const rl = @import("raylib");

pub const Axis = enum {
    x,
    y,
};

pub fn getRectCenter(rect: rl.Rectangle) rl.Vector2 {
    return rl.Vector2.init(rect.x + (rect.width / 2), rect.y + (rect.height / 2));
}

pub fn getRectAxisOverlap(rect1: rl.Rectangle, rect2: rl.Rectangle, axis: Axis) f32 {
    var min1: f32 = undefined;
    var max1: f32 = undefined;
    var min2: f32 = undefined;
    var max2: f32 = undefined;
    switch (axis) {
        .y => {
            min1 = rect1.y;
            max1 = rect1.y + rect1.height;
            min2 = rect2.y;
            max2 = rect2.y + rect2.height;
        },
        .x => {
            min1 = rect1.x;
            max1 = rect1.x + rect1.width;
            min2 = rect2.x;
            max2 = rect2.x + rect2.width;
        },
    }
    return @min(max2, max1) - @max(min1, min2);
}

pub inline fn scaleByFloat(value: i32, scale: f32) i32 {
    return @intFromFloat(@as(f32, @floatFromInt(value)) * scale);
}
