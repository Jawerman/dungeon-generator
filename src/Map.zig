const std = @import("std");
const utils = @import("utils.zig");
const rl = @import("raylib");
const Graph = @import("Graph.zig");

const Self = @This();

pub const Sector = struct {
    area: rl.Rectangle,
};

rooms: std.ArrayList(rl.Rectangle),
doors: std.ArrayList(rl.Rectangle),

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .rooms = std.ArrayList(rl.Rectangle).init(allocator),
        .doors = std.ArrayList(rl.Rectangle).init(allocator),
    };
}

pub fn build(self: *Self, graph: Graph, padding: f32, door_size: f32) !void {
    for (graph.areas.items) |area| {
        try self.rooms.append(rl.Rectangle.init(area.x + padding, area.y + padding, area.width - (2 * padding), area.height - (2 * padding)));
    }

    for (graph.edges.items) |edge| {
        const first_area = self.rooms.items[edge[0]];
        const second_area = self.rooms.items[edge[1]];
        try self.doors.append(get_door_between(first_area, second_area, door_size));
    }
}

pub fn get_door_between(area1: rl.Rectangle, area2: rl.Rectangle, door_size: f32) rl.Rectangle {
    const min_x_1 = area1.x;
    const max_x_1 = area1.x + area1.width;
    const min_y_1 = area1.y;
    const max_y_1 = area1.y + area1.height;

    const min_x_2 = area2.x;
    const max_x_2 = area2.x + area2.width;
    const min_y_2 = area2.y;
    const max_y_2 = area2.y + area2.height;

    const min_max_x = @min(max_x_1, max_x_2);
    const max_min_x = @max(min_x_1, min_x_2);

    const min_max_y = @min(max_y_1, max_y_2);
    const max_min_y = @max(min_y_1, min_y_2);

    const x_gap = max_min_x - min_max_x;
    const y_gap = max_min_y - min_max_y;

    if (x_gap > 0) {
        const x = min_max_x;
        const y = ((max_min_y + min_max_y) / 2) - door_size;
        const width = x_gap;
        const height = door_size;
        return rl.Rectangle.init(x, y, width, height);
    } else {
        const y = min_max_y;
        const x = ((max_min_x + min_max_x) / 2) - door_size;
        const width = door_size;
        const height = y_gap;
        return rl.Rectangle.init(x, y, width, height);
    }
}

pub fn draw(self: Self, scale_x: f32, scale_y: f32, room_color: rl.Color, door_color: rl.Color) void {
    for (self.rooms.items) |room| {
        rl.drawRectangle(@intFromFloat(room.x * scale_x), @intFromFloat(room.y * scale_y), @intFromFloat(room.width * scale_x), @intFromFloat(room.height * scale_y), room_color);
    }
    for (self.doors.items) |door| {
        rl.drawRectangle(@intFromFloat(door.x * scale_x), @intFromFloat(door.y * scale_y), @intFromFloat(door.width * scale_x), @intFromFloat(door.height * scale_y), door_color);
    }
}
