const rl = @import("raylib");
const std = @import("std");
const Level = @import("Level.zig");

const Self = @This();

const LineType = enum {
    room,
    door_outside,
    door_inside,
};

const SectorType = enum {
    room,
    door,
};

pub const Line = struct {
    from: rl.Vector2,
    to: rl.Vector2,
    type: LineType,
    min_height: f32,
    max_height: f32,

    fn create(x1: f32, y1: f32, x2: f32, y2: f32, min_height: f32, max_height: f32, lineType: LineType, reversed: bool) @This() {
        const result: @This() = if (!reversed)
            .{
                .from = rl.Vector2.init(x1, y1),
                .to = rl.Vector2.init(x2, y2),
                .type = lineType,
                .min_height = min_height,
                .max_height = max_height,
            }
        else
            .{
                .from = rl.Vector2.init(x2, y2),
                .to = rl.Vector2.init(x1, y1),
                .type = lineType,
                .min_height = min_height,
                .max_height = max_height,
            };

        std.debug.print("\n\tLine (x:{} y:{}) - (x:{} y:{})", .{ result.from.x, result.from.y, result.to.x, result.to.y });
        return result;
    }
};

pub const Sector = struct {
    area: rl.Rectangle,
    floor_height: f32,
    ceil_height: f32,
    type: SectorType,
};

lines: std.ArrayList(Line),

sectors: std.ArrayList(Sector),

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .lines = std.ArrayList(Line).init(allocator),
        .sectors = std.ArrayList(Sector).init(allocator),
    };
}

pub fn buildFromLevel(self: *Self, level: Level, height: f32) !void {
    try self.addRoomsLines(level, height);
    try self.addDoorsLines(level, height);
    try self.addSectors(level, height);
}

fn addSectors(self: *Self, level: Level, height: f32) !void {
    try self.sectors.resize(level.rooms.items.len + level.doors.items.len);

    for (level.rooms.items) |room| {
        try self.sectors.append(.{
            .area = room.area,
            .floor_height = 0,
            .ceil_height = height,
            .type = .room,
        });
    }
    for (level.doors.items) |door| {
        try self.sectors.append(.{
            .area = door,
            .floor_height = 0,
            .ceil_height = height / 2.0,
            .type = .door,
        });
    }
}

fn addRoomsLines(self: *Self, level: Level, height: f32) !void {
    for (level.rooms.items, 0..) |room, i| {
        std.debug.print("\nLines for Room: {} UP", .{i});
        try self.addRoomHorizontalLine(room.area.y, room.area.x, room.area.x + room.area.width, height, room.up_doors.items, level.doors.items, false);
        std.debug.print("\nLines for Room: {} DOWN", .{i});
        try self.addRoomHorizontalLine(room.area.y + room.area.height, room.area.x, room.area.x + room.area.width, height, room.down_doors.items, level.doors.items, true);
        std.debug.print("\nLines for Room: {} LEFT", .{i});
        try self.addRoomVerticalLine(room.area.x, room.area.y, room.area.y + room.area.height, height, room.left_doors.items, level.doors.items, true);
        std.debug.print("\nLines for Room: {} RIGHT", .{i});
        try self.addRoomVerticalLine(room.area.x + room.area.width, room.area.y, room.area.y + room.area.height, height, room.right_doors.items, level.doors.items, false);
    }
}

pub fn addDoorsLines(self: *Self, level: Level, height: f32) !void {
    for (level.doors.items) |door| {
        try self.addDoorLines(door, height);
    }
}

fn addRoomHorizontalLine(self: *Self, y: f32, x_min: f32, x_max: f32, height: f32, door_ids: []usize, doors: []rl.Rectangle, reversed: bool) !void {
    var current_position = x_min;
    for (door_ids) |door_id| {
        const door = doors[door_id];
        if (door.x > current_position) {
            try self.lines.append(Line.create(current_position, y, door.x, y, 0, height, .room, reversed));
            current_position = door.x;
        }
        try self.lines.append(Line.create(current_position, y, current_position + door.width, y, height / 2.0, height, .door_outside, reversed));
        current_position += door.width;
    }

    if (current_position < x_max) {
        try self.lines.append(Line.create(current_position, y, x_max, y, 0, height, .room, reversed));
    }
}

fn addRoomVerticalLine(self: *Self, x: f32, y_min: f32, y_max: f32, height: f32, door_ids: []usize, doors: []rl.Rectangle, reversed: bool) !void {
    var current_position = y_min;
    for (door_ids) |door_id| {
        const door = doors[door_id];
        if (door.y > current_position) {
            try self.lines.append(Line.create(x, current_position, x, door.y, 0, height, .room, reversed));
            current_position = door.y;
        }
        try self.lines.append(Line.create(x, current_position, x, current_position + door.height, height / 2.0, height, .door_outside, reversed));
        current_position += door.height;
    }

    if (current_position < y_max) {
        try self.lines.append(Line.create(x, current_position, x, y_max, 0, height, .room, reversed));
    }
}

fn addDoorLines(self: *Self, door: rl.Rectangle, height: f32) !void {
    if (door.width > door.height) {
        try self.lines.append(Line.create(door.x, door.y, door.x, door.y + door.height, 0, height / 2.0, .door_inside, true));
        try self.lines.append(Line.create(door.x + door.width, door.y, door.x + door.width, door.y + door.height, 0, height / 2.0, .door_inside, false));
    } else {
        try self.lines.append(Line.create(door.x, door.y, door.x + door.width, door.y, 0, height / 2.0, .door_inside, false));
        try self.lines.append(Line.create(door.x, door.y + door.height, door.x + door.width, door.y + door.height, 0, height / 2.0, .door_inside, true));
    }
}

pub fn draw(self: Self, scale_x: f32, scale_y: f32, room_color: rl.Color, door_color: rl.Color) void {
    for (self.lines.items) |line| {
        const color = switch (line.type) {
            .door_outside => door_color,
            .door_inside => door_color,
            .room => room_color,
        };
        rl.drawLine(@intFromFloat(line.from.x * scale_x), @intFromFloat(line.from.y * scale_y), @intFromFloat(line.to.x * scale_x), @intFromFloat(line.to.y * scale_y), color);

        const middle_point = rl.Vector2.init((line.from.x + line.to.x) / 2.0, (line.from.y + line.to.y) / 2.0);
        const orientation = line.to.subtract(line.from).rotate(std.math.pi / 2.0).normalize().scale(0.005);
        rl.drawLine(@intFromFloat(middle_point.x * scale_x), @intFromFloat(middle_point.y * scale_y), @intFromFloat((middle_point.x + orientation.x) * scale_x), @intFromFloat((middle_point.y + orientation.y) * scale_y), color);
    }
}
