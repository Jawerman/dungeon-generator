const std = @import("std");
const utils = @import("utils.zig");
const rl = @import("raylib");
const Graph = @import("Graph.zig");
const Rectangle = @import("Rectangle.zig");

const Self = @This();

const Orientation = enum {
    horizontal,
    vertical,
};

pub const Room = struct {
    area: Rectangle,

    up_doors: std.ArrayList(usize),
    down_doors: std.ArrayList(usize),
    left_doors: std.ArrayList(usize),
    right_doors: std.ArrayList(usize),
};

pub const Door = struct {
    area: Rectangle,
    orientation: Orientation,
};

rooms: std.ArrayList(Room),
doors: std.ArrayList(Door),

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .rooms = std.ArrayList(Room).init(allocator),
        .doors = std.ArrayList(Door).init(allocator),
    };
}

pub fn build(self: *Self, graph: Graph, padding: i32, door_size: i32, allocator: std.mem.Allocator) !void {
    for (graph.areas.items) |area| {
        try self.rooms.append(.{
            .area = Rectangle.init(area.x + padding, area.y + padding, area.width - padding, area.height - padding),
            .up_doors = std.ArrayList(usize).init(allocator),
            .down_doors = std.ArrayList(usize).init(allocator),
            .left_doors = std.ArrayList(usize).init(allocator),
            .right_doors = std.ArrayList(usize).init(allocator),
        });
    }

    for (graph.edges.items) |edge| {
        try self.addDoor(edge, door_size);
    }

    for (self.rooms.items) |*room| {
        sortRoomDoors(room, self.doors.items);
    }
    self.print_debug_info();
}

fn print_debug_info(self: Self) void {
    for (self.doors.items, 0..) |door, i| {
        std.debug.print("\nDOOR {}: x:{}, y:{}, width: {}, height: {}", .{ i, door.area.x, door.area.y, door.area.width, door.area.height });
    }
    for (self.rooms.items, 0..) |room, i| {
        std.debug.print("\nROOM {}: x:{}, y:{}, width: {}, height: {}", .{ i, room.area.x, room.area.y, room.area.width, room.area.height });
        std.debug.print("\n\tUp: ", .{});
        for (room.up_doors.items) |door| {
            std.debug.print("{}, ", .{door});
        }
        std.debug.print("\n\tDown: ", .{});
        for (room.down_doors.items) |door| {
            std.debug.print("{}, ", .{door});
        }
        std.debug.print("\n\tLeft: ", .{});
        for (room.left_doors.items) |door| {
            std.debug.print("{}, ", .{door});
        }
        std.debug.print("\n\tRight: ", .{});
        for (room.right_doors.items) |door| {
            std.debug.print("{}, ", .{door});
        }
    }
}

fn addDoor(self: *Self, edge: Graph.Edge, door_size: i32) !void {
    var room1 = &self.rooms.items[edge[0]];
    var room2 = &self.rooms.items[edge[1]];

    const min_x_1 = room1.area.x;
    const max_x_1 = room1.area.x + room1.area.width;
    const min_y_1 = room1.area.y;
    const max_y_1 = room1.area.y + room1.area.height;

    const min_x_2 = room2.area.x;
    const max_x_2 = room2.area.x + room2.area.width;
    const min_y_2 = room2.area.y;
    const max_y_2 = room2.area.y + room2.area.height;

    const min_max_x = @min(max_x_1, max_x_2);
    const max_min_x = @max(min_x_1, min_x_2);

    const min_max_y = @min(max_y_1, max_y_2);
    const max_min_y = @max(min_y_1, min_y_2);

    const x_gap = max_min_x - min_max_x;
    const y_gap = max_min_y - min_max_y;

    const door_index = self.doors.items.len;

    if (x_gap > 0) {
        const x = min_max_x;
        const y = @divTrunc((max_min_y + min_max_y), 2) - @divTrunc(door_size, 2);
        const width = x_gap;
        const height = door_size;
        const area = Rectangle.init(x, y, width, height);

        if (min_x_1 < x) {
            try room1.right_doors.append(door_index);
            try room2.left_doors.append(door_index);
        } else {
            try room1.left_doors.append(door_index);
            try room2.right_doors.append(door_index);
        }
        try self.doors.append(Door{
            .area = area,
            .orientation = Orientation.vertical,
        });
    } else {
        const y = min_max_y;
        const x = @divTrunc((max_min_x + min_max_x), 2) - @divTrunc(door_size, 2);
        const width = door_size;
        const height = y_gap;
        const area = Rectangle.init(x, y, width, height);

        if (min_y_1 < y) {
            try room1.down_doors.append(door_index);
            try room2.up_doors.append(door_index);
        } else {
            try room1.up_doors.append(door_index);
            try room2.down_doors.append(door_index);
        }
        try self.doors.append(Door{
            .area = area,
            .orientation = Orientation.horizontal,
        });
    }
}

fn sortRoomDoors(room: *Room, doors: []Door) void {
    std.mem.sort(usize, room.up_doors.items, doors, cmpDoorsAsc);
    std.mem.sort(usize, room.right_doors.items, doors, cmpDoorsAsc);
    std.mem.sort(usize, room.down_doors.items, doors, cmpDoorsDesc);
    std.mem.sort(usize, room.left_doors.items, doors, cmpDoorsDesc);
}

pub fn draw(self: Self, scale_x: f32, scale_y: f32, room_color: rl.Color, door_color: rl.Color) void {
    for (self.rooms.items) |room| {
        const area = room.area;

        rl.drawRectangle(utils.scaleByFloat(area.x, scale_x), utils.scaleByFloat(area.y, scale_y), utils.scaleByFloat(area.width, scale_x), utils.scaleByFloat(area.height, scale_y), room_color);
    }
    for (self.doors.items) |door| {
        const area = door.area;
        rl.drawRectangle(utils.scaleByFloat(area.x, scale_x), utils.scaleByFloat(area.y, scale_y), utils.scaleByFloat(area.width, scale_x), utils.scaleByFloat(area.height, scale_y), door_color);
    }
}

fn cmpDoorsAsc(context: []Door, a: usize, b: usize) bool {
    const doorA = context[a];
    const doorB = context[b];

    return switch (doorA.orientation) {
        .horizontal => doorA.area.x < doorB.area.x,
        .vertical => doorA.area.y < doorB.area.y,
    };
}

fn cmpDoorsDesc(context: []Door, a: usize, b: usize) bool {
    const doorA = context[a];
    const doorB = context[b];

    return switch (doorA.orientation) {
        .horizontal => doorA.area.x > doorB.area.x,
        .vertical => doorA.area.y > doorB.area.y,
    };
}
