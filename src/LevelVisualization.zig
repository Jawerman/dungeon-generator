const rl = @import("raylib");
const std = @import("std");
const Level = @import("Level.zig");

const Self = @This();

const LineType = enum {
    room,
    door,
};

pub const Line = struct {
    from: rl.Vector2,
    to: rl.Vector2,
    type: LineType,

    fn create(x1: f32, y1: f32, x2: f32, y2: f32, lineType: LineType, reversed: bool) @This() {
        return if (reversed)
            .{
                .from = rl.Vector2.init(x1, y1),
                .to = rl.Vector2.init(x2, y2),
                .type = lineType,
            }
        else
            .{
                .from = rl.Vector2.init(x2, y2),
                .to = rl.Vector2.init(x1, y1),
                .type = lineType,
            };
    }
};

lines: std.ArrayList(Line),

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .lines = std.ArrayList(Line).init(allocator),
    };
}

pub fn buildFromLevel(self: *Self, level: Level) !void {
    try self.addRoomsLines(level);
    try self.addDoorsLines(level);
}

fn addRoomsLines(self: *Self, level: Level) !void {
    for (level.rooms.items) |room| {
        try self.addRoomHorizontalLine(room.area.y, room.area.x, room.area.x + room.area.width, room.up_doors.items, level.doors.items, false);
        try self.addRoomHorizontalLine(room.area.y + room.area.height, room.area.x, room.area.x + room.area.width, room.down_doors.items, level.doors.items, true);
        try self.addRoomVerticalLine(room.area.x, room.area.y, room.area.y + room.area.height, room.left_doors.items, level.doors.items, true);
        try self.addRoomVerticalLine(room.area.x + room.area.width, room.area.y, room.area.y + room.area.height, room.right_doors.items, level.doors.items, false);
    }
}

pub fn addDoorsLines(self: *Self, level: Level) !void {
    for (level.doors.items) |door| {
        try self.addDoorLines(door);
    }
}

fn addRoomHorizontalLine(self: *Self, y: f32, x_min: f32, x_max: f32, door_ids: []usize, doors: []rl.Rectangle, reversed: bool) !void {
    var current_position = x_min;
    for (door_ids) |door_id| {
        const door = doors[door_id];
        if (door.x > current_position) {
            try self.lines.append(Line.create(current_position, y, door.x, y, .room, reversed));
            current_position = door.x;
        }
        try self.lines.append(Line.create(current_position, y, current_position + door.width, y, .door, reversed));
        current_position += door.width;
    }

    if (current_position < x_max) {
        try self.lines.append(Line.create(current_position, y, x_max, y, .room, reversed));
    }
}

fn addRoomVerticalLine(self: *Self, x: f32, y_min: f32, y_max: f32, door_ids: []usize, doors: []rl.Rectangle, reversed: bool) !void {
    var current_position = y_min;
    for (door_ids) |door_id| {
        const door = doors[door_id];
        if (door.y > current_position) {
            try self.lines.append(Line.create(x, current_position, x, door.y, .room, reversed));
            current_position = door.y;
        }
        try self.lines.append(Line.create(x, current_position, x, current_position + door.height, .door, reversed));
        current_position += door.height;
    }

    if (current_position < y_max) {
        try self.lines.append(Line.create(x, current_position, x, y_max, .room, reversed));
    }
}

fn addDoorLines(self: *Self, door: rl.Rectangle) !void {
    if (door.width > door.height) {
        try self.lines.append(Line.create(door.x, door.y, door.x, door.y + door.height, .door, true));
        try self.lines.append(Line.create(door.x + door.width, door.y, door.x + door.width, door.y + door.height, .door, false));
    } else {
        try self.lines.append(Line.create(door.x, door.y, door.x + door.width, door.y, .door, false));
        try self.lines.append(Line.create(door.x, door.y + door.height, door.x + door.width, door.y + door.height, .door, true));
    }
}

pub fn draw(self: Self, scale_x: f32, scale_y: f32, room_color: rl.Color, door_color: rl.Color) void {
    for (self.lines.items) |line| {
        const color = switch (line.type) {
            .door => door_color,
            .room => room_color,
        };
        rl.drawLine(@intFromFloat(line.from.x * scale_x), @intFromFloat(line.from.y * scale_y), @intFromFloat(line.to.x * scale_x), @intFromFloat(line.to.y * scale_y), color);

        const middle_point = rl.Vector2.init((line.from.x + line.to.x) / 2.0, (line.from.y + line.to.y) / 2.0);
        const orientation = line.to.subtract(line.from).rotate(-std.math.pi / 2.0).normalize().scale(0.005);
        rl.drawLine(@intFromFloat(middle_point.x * scale_x), @intFromFloat(middle_point.y * scale_y), @intFromFloat((middle_point.x + orientation.x) * scale_x), @intFromFloat((middle_point.y + orientation.y) * scale_y), color);
    }
}
