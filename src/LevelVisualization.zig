const rl = @import("raylib");
const std = @import("std");
const Level = @import("Level.zig");

const Self = @This();

const LineType = enum {
    room,
    door,
};

const Line = struct {
    from: rl.Vector2,
    to: rl.Vector2,
    type: LineType,
};

lines: std.ArrayList(Line),

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .lines = std.ArrayList(Line).init(allocator),
    };
}

pub fn addRoomsLines(self: *Self, level: Level) !void {
    for (level.rooms.items) |room| {
        try self.addHorizontalWall(room.area.y, room.area.x, room.area.x + room.area.width, room.up_doors.items, level.doors.items);
        try self.addHorizontalWall(room.area.y + room.area.height, room.area.x, room.area.x + room.area.width, room.down_doors.items, level.doors.items);
        try self.addVerticalWall(room.area.x, room.area.y, room.area.y + room.area.height, room.left_doors.items, level.doors.items);
        try self.addVerticalWall(room.area.x + room.area.width, room.area.y, room.area.y + room.area.height, room.right_doors.items, level.doors.items);
    }
}

fn addHorizontalWall(self: *Self, y: f32, x_min: f32, x_max: f32, door_ids: []usize, doors: []rl.Rectangle) !void {
    var current_position = x_min;
    for (door_ids) |door_id| {
        const door = doors[door_id];
        if (door.x > current_position) {
            try self.lines.append(.{
                .from = rl.Vector2.init(current_position, y),
                .to = rl.Vector2.init(door.x, y),
                .type = .room,
            });
            current_position = door.x;
        }
        try self.lines.append(.{
            .from = rl.Vector2.init(current_position, y),
            .to = rl.Vector2.init(current_position + door.width, y),
            .type = .door,
        });
    }

    if (current_position < x_max) {
        try self.lines.append(.{
            .from = rl.Vector2.init(current_position, y),
            .to = rl.Vector2.init(x_max, y),
            .type = .room,
        });
    }
}

fn addVerticalWall(self: *Self, x: f32, y_min: f32, y_max: f32, door_ids: []usize, doors: []rl.Rectangle) !void {
    var current_position = y_min;
    for (door_ids) |door_id| {
        const door = doors[door_id];
        if (door.y > current_position) {
            try self.lines.append(.{
                .from = rl.Vector2.init(x, current_position),
                .to = rl.Vector2.init(x, door.y),
                .type = .room,
            });
            current_position = door.y;
        }
        try self.lines.append(.{
            .from = rl.Vector2.init(x, current_position),
            .to = rl.Vector2.init(x, current_position + door.height),
            .type = .door,
        });
    }

    if (current_position < y_max) {
        try self.lines.append(.{
            .from = rl.Vector2.init(x, current_position),
            .to = rl.Vector2.init(x, y_max),
            .type = .room,
        });
    }
}

pub fn draw(self: Self, scale_x: f32, scale_y: f32, room_color: rl.Color, door_color: rl.Color) void {
    for (self.lines.items) |line| {
        const color = switch (line.type) {
            .door => door_color,
            .room => room_color,
        };
        rl.drawLine(@intFromFloat(line.from.x * scale_x), @intFromFloat(line.from.y * scale_y), @intFromFloat(line.to.x * scale_x), @intFromFloat(line.to.y * scale_y), color);
    }
}
