const std = @import("std");
const Rectangle = @import("Rectangle.zig");

const Self = @This();

pub const SectorType = enum {
    room,
    door,
};

pub const Point = struct {
    x: i32,
    y: i32,
    min_height: i32,
    max_height: i32,
};

area: Rectangle,
points: std.ArrayList(Point),
sector_type: SectorType,

floor_height: i32,
ceil_height: i32,

pub fn init(area: Rectangle, sector_type: SectorType, floor_height: i32, ceil_height: i32, allocator: std.mem.Allocator) Self {
    return .{
        .area = area,
        .floor_height = floor_height,
        .ceil_height = ceil_height,
        .sector_type = sector_type,
        .points = std.ArrayList(Point).init(allocator),
    };
}
