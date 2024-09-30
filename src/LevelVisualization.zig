const rl = @import("raylib");
const std = @import("std");
const util = @import("utils.zig");
const Level = @import("Level.zig");
const Sector = @import("Sector.zig");
const Rectangle = @import("Rectangle.zig");

const Self = @This();

sectors: std.ArrayList(Sector),

pub fn init(level: Level, level_height: i32, door_height: i32, allocator: std.mem.Allocator) !Self {
    var result = Self{
        .sectors = std.ArrayList(Sector).init(allocator),
    };
    try result.buildFromLevel(level, level_height, door_height, allocator);
    return result;
}

fn buildFromLevel(self: *Self, level: Level, level_height: i32, door_height: i32, allocator: std.mem.Allocator) !void {
    try self.addSectors(level, level_height, door_height, allocator);
}

fn addSectors(self: *Self, level: Level, level_height: i32, door_height: i32, allocator: std.mem.Allocator) !void {
    try self.sectors.ensureTotalCapacity(level.rooms.items.len);

    for (level.rooms.items) |room| {
        std.debug.print("\nRoom {}", .{room.area});
        try self.createSectorFromRoom(room, level.doors.items, level_height, door_height, allocator);
    }
    for (level.doors.items) |door| {
        std.debug.print("\nDoor {}", .{door.area});
        try self.createSectorFromDoor(door, door_height, allocator);
    }
}

fn createSectorFromDoor(self: *Self, door: Level.Door, door_height: i32, allocator: std.mem.Allocator) !void {
    var new_sector = Sector.init(door.area, Sector.SectorType.door, 0, door_height, allocator);

    try new_sector.points.append(.{
        .x = door.area.x,
        .y = door.area.y,
        .min_height = 0,
        .max_height = switch (door.orientation) {
            .horizontal => door_height,
            .vertical => 0,
        },
    });
    std.debug.print("\n\tAdded point {}", .{new_sector.points.getLast()});

    try new_sector.points.append(.{
        .x = door.area.x + door.area.width,
        .y = door.area.y,
        .min_height = 0,
        .max_height = switch (door.orientation) {
            .horizontal => 0,
            .vertical => door_height,
        },
    });
    std.debug.print("\n\tAdded point {}", .{new_sector.points.getLast()});

    try new_sector.points.append(.{
        .x = door.area.x + door.area.width,
        .y = door.area.y + door.area.height,
        .min_height = 0,
        .max_height = switch (door.orientation) {
            .horizontal => door_height,
            .vertical => 0,
        },
    });
    std.debug.print("\n\tAdded point {}", .{new_sector.points.getLast()});

    try new_sector.points.append(.{
        .x = door.area.x,
        .y = door.area.y + door.area.height,
        .min_height = 0,
        .max_height = switch (door.orientation) {
            .horizontal => 0,
            .vertical => door_height,
        },
    });
    std.debug.print("\n\tAdded point {}", .{new_sector.points.getLast()});

    try self.sectors.append(new_sector);
}

fn createSectorFromRoom(self: *Self, room: Level.Room, level_doors: []Level.Door, level_height: i32, door_height: i32, allocator: std.mem.Allocator) !void {
    var new_sector = Sector.init(room.area, Sector.SectorType.room, 0, level_height, allocator);

    try new_sector.points.append(.{
        .x = room.area.x,
        .y = room.area.y,
        .min_height = 0,
        .max_height = level_height,
    });
    std.debug.print("\n\tAdded point {}", .{new_sector.points.getLast()});

    try addUpLinesPoints(&new_sector.points, room.up_doors.items, level_doors, level_height, door_height);

    try new_sector.points.append(.{
        .x = room.area.x + room.area.width,
        .y = room.area.y,
        .min_height = 0,
        .max_height = level_height,
    });
    std.debug.print("\n\tAdded point {}", .{new_sector.points.getLast()});

    try addRightLinesPoints(&new_sector.points, room.right_doors.items, level_doors, level_height, door_height);

    try new_sector.points.append(.{
        .x = room.area.x + room.area.width,
        .y = room.area.y + room.area.height,
        .min_height = 0,
        .max_height = level_height,
    });

    std.debug.print("\n\tAdded point {}", .{new_sector.points.getLast()});
    try addDownLinesPoints(&new_sector.points, room.down_doors.items, level_doors, level_height, door_height);

    try new_sector.points.append(.{
        .x = room.area.x,
        .y = room.area.y + room.area.height,
        .min_height = 0,
        .max_height = level_height,
    });
    std.debug.print("\n\tAdded point {}", .{new_sector.points.getLast()});

    try addLeftLinesPoints(&new_sector.points, room.left_doors.items, level_doors, level_height, door_height);

    try self.sectors.append(new_sector);
}

fn addUpLinesPoints(points: *std.ArrayList(Sector.Point), door_indexes: []usize, level_doors: []Level.Door, level_height: i32, door_height: i32) !void {
    const position_y = points.getLast().y;

    for (door_indexes) |door_index| {
        const current_door_area = level_doors[door_index].area;
        try points.append(.{
            .x = current_door_area.x,
            .y = position_y,
            .min_height = door_height,
            .max_height = level_height,
        });
        std.debug.print("\n\tAdded point {}", .{points.getLast()});

        try points.append(.{
            .x = current_door_area.x + current_door_area.width,
            .y = position_y,
            .min_height = 0,
            .max_height = level_height,
        });
        std.debug.print("\n\tAdded point {}", .{points.getLast()});
    }
}

fn addRightLinesPoints(points: *std.ArrayList(Sector.Point), door_indexes: []usize, level_doors: []Level.Door, level_height: i32, door_height: i32) !void {
    const position_x = points.getLast().x;

    for (door_indexes) |door_index| {
        const current_door_area = level_doors[door_index].area;
        try points.append(.{
            .x = position_x,
            .y = current_door_area.y,
            .min_height = door_height,
            .max_height = level_height,
        });
        std.debug.print("\n\tAdded point {}", .{points.getLast()});

        try points.append(.{
            .x = position_x,
            .y = current_door_area.y + current_door_area.height,
            .min_height = 0,
            .max_height = level_height,
        });
        std.debug.print("\n\tAdded point {}", .{points.getLast()});
    }
}

fn addDownLinesPoints(points: *std.ArrayList(Sector.Point), door_indexes: []usize, level_doors: []Level.Door, level_height: i32, door_height: i32) !void {
    const position_y = points.getLast().y;
    for (door_indexes) |door_index| {
        const current_door_area = level_doors[door_index].area;
        try points.append(.{
            .x = current_door_area.x + current_door_area.width,
            .y = position_y,
            .min_height = door_height,
            .max_height = level_height,
        });
        std.debug.print("\n\tAdded point {}", .{points.getLast()});

        try points.append(.{
            .x = current_door_area.x,
            .y = position_y,
            .min_height = 0,
            .max_height = level_height,
        });
        std.debug.print("\n\tAdded point {}", .{points.getLast()});
    }
}

fn addLeftLinesPoints(points: *std.ArrayList(Sector.Point), door_indexes: []usize, level_doors: []Level.Door, level_height: i32, door_height: i32) !void {
    const position_x = points.getLast().x;

    for (door_indexes) |door_index| {
        const current_door_area = level_doors[door_index].area;
        try points.append(.{
            .x = position_x,
            .y = current_door_area.y + current_door_area.height,
            .min_height = door_height,
            .max_height = level_height,
        });
        std.debug.print("\n\tAdded point {}", .{points.getLast()});

        try points.append(.{
            .x = position_x,
            .y = current_door_area.y,
            .min_height = 0,
            .max_height = level_height,
        });
        std.debug.print("\n\tAdded point {}", .{points.getLast()});
    }
}

pub fn draw(self: Self, scale_x: f32, scale_y: f32, room_color: rl.Color, door_color: rl.Color) void {
    for (self.sectors.items) |sector| {
        const color = switch (sector.sector_type) {
            .door => door_color,
            .room => room_color,
        };

        const sector_points = sector.points.items;
        var current_point = sector_points[0];

        for (sector_points[1..]) |point| {
            defer current_point = point;
            if (current_point.min_height == current_point.max_height) {
                continue;
            }
            rl.drawLine(util.scaleByFloat(current_point.x, scale_x), util.scaleByFloat(current_point.y, scale_y), util.scaleByFloat(point.x, scale_x), util.scaleByFloat(point.y, scale_y), color);
        }

        if (current_point.min_height != current_point.max_height) {
            const first_point = sector_points[0];
            rl.drawLine(util.scaleByFloat(current_point.x, scale_x), util.scaleByFloat(current_point.y, scale_y), util.scaleByFloat(first_point.x, scale_x), util.scaleByFloat(first_point.y, scale_y), color);
        }
    }
}
