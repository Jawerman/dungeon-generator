const rl = @import("raylib");
const std = @import("std");
const util = @import("../utils.zig");
const LevelDefinition = @import("LevelDefinition.zig");
const Sector = @import("Sector.zig");
const Rectangle = @import("../Rectangle.zig");

const Self = @This();

sectors: std.ArrayList(Sector),

pub fn init(level: LevelDefinition, level_height: i32, door_height: i32, allocator: std.mem.Allocator) !Self {
    var result = Self{
        .sectors = std.ArrayList(Sector).init(allocator),
    };
    try result.buildFromLevel(level, level_height, door_height, allocator);
    return result;
}

fn buildFromLevel(self: *Self, level: LevelDefinition, level_height: i32, door_height: i32, allocator: std.mem.Allocator) !void {
    try self.addSectors(level, level_height, door_height, allocator);
}

fn addSectors(self: *Self, level: LevelDefinition, level_height: i32, door_height: i32, allocator: std.mem.Allocator) !void {
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

fn createSectorFromDoor(self: *Self, door: LevelDefinition.Door, door_height: i32, allocator: std.mem.Allocator) !void {
    var new_sector = Sector.init(door.area, Sector.SectorType.door, 0, door_height, allocator);
    const first_point_index = new_sector.points.items.len;

    const horizontal_heigth = switch (door.orientation) {
        .horizontal => 0,
        .vertical => door_height,
    };
    const vertical_height = switch (door.orientation) {
        .horizontal => door_height,
        .vertical => 0,
    };

    try addPointToSector(&new_sector, .{
        .x = door.area.x,
        .y = door.area.y,
    }, 0, 0);

    std.debug.print("\n\tAdded point {}", .{new_sector.points.getLast()});

    try addPointToSector(&new_sector, .{
        .x = door.area.x + door.area.width,
        .y = door.area.y,
    }, 0, horizontal_heigth);

    std.debug.print("\n\tAdded point {}", .{new_sector.points.getLast()});

    try addPointToSector(&new_sector, .{
        .x = door.area.x + door.area.width,
        .y = door.area.y + door.area.height,
    }, 0, vertical_height);

    std.debug.print("\n\tAdded point {}", .{new_sector.points.getLast()});

    try addPointToSector(&new_sector, .{
        .x = door.area.x,
        .y = door.area.y + door.area.height,
    }, 0, horizontal_heigth);

    std.debug.print("\n\tAdded point {}", .{new_sector.points.getLast()});

    const last_point_index = new_sector.points.items.len - 1;
    try new_sector.lines.append(.{
        .min_height = 0,
        .max_height = vertical_height,
        .points = .{ last_point_index, first_point_index },
    });

    try self.sectors.append(new_sector);
}

fn createSectorFromRoom(self: *Self, room: LevelDefinition.Room, level_doors: []LevelDefinition.Door, level_height: i32, door_height: i32, allocator: std.mem.Allocator) !void {
    var new_sector = Sector.init(room.area, Sector.SectorType.room, 0, level_height, allocator);

    const first_point_index = new_sector.points.items.len;

    try addPointToSector(&new_sector, .{
        .x = room.area.x,
        .y = room.area.y,
    }, 0, level_height);

    std.debug.print("\n\tAdded point {}", .{new_sector.points.getLast()});

    try addUpLinesPoints(&new_sector, room.up_doors.items, level_doors, level_height, door_height);

    try addPointToSector(&new_sector, .{
        .x = room.area.x + room.area.width,
        .y = room.area.y,
    }, 0, level_height);
    std.debug.print("\n\tAdded point {}", .{new_sector.points.getLast()});

    try addRightLinesPoints(&new_sector, room.right_doors.items, level_doors, level_height, door_height);

    try addPointToSector(&new_sector, .{
        .x = room.area.x + room.area.width,
        .y = room.area.y + room.area.height,
    }, 0, level_height);

    std.debug.print("\n\tAdded point {}", .{new_sector.points.getLast()});
    try addDownLinesPoints(&new_sector, room.down_doors.items, level_doors, level_height, door_height);

    try addPointToSector(&new_sector, .{
        .x = room.area.x,
        .y = room.area.y + room.area.height,
    }, 0, level_height);
    std.debug.print("\n\tAdded point {}", .{new_sector.points.getLast()});

    try addLeftLinesPoints(&new_sector, room.left_doors.items, level_doors, level_height, door_height);

    const last_point_index = new_sector.points.items.len - 1;
    try new_sector.lines.append(.{
        .min_height = 0,
        .max_height = level_height,
        .points = .{ last_point_index, first_point_index },
    });

    try self.sectors.append(new_sector);
}

fn addPointToSector(sector: *Sector, point: Sector.Point, min_height: i32, max_height: i32) !void {
    const new_point_index = sector.points.items.len;

    try sector.points.append(point);
    if (new_point_index > 0) {
        try sector.lines.append(.{
            .min_height = min_height,
            .max_height = max_height,
            .points = .{ new_point_index - 1, new_point_index },
        });
    }
}

fn addUpLinesPoints(sector: *Sector, door_indexes: []usize, level_doors: []LevelDefinition.Door, level_height: i32, door_height: i32) !void {
    const position_y = sector.points.getLast().y;
    for (door_indexes) |door_index| {
        const current_door_area = level_doors[door_index].area;
        try addPointToSector(sector, .{
            .x = current_door_area.x,
            .y = position_y,
        }, 0, level_height);

        std.debug.print("\n\tAdded point {}", .{sector.points.getLast()});

        try addPointToSector(sector, .{
            .x = current_door_area.x + current_door_area.width,
            .y = position_y,
        }, door_height, level_height);

        std.debug.print("\n\tAdded point {}", .{sector.points.getLast()});
    }
}

fn addRightLinesPoints(sector: *Sector, door_indexes: []usize, level_doors: []LevelDefinition.Door, level_height: i32, door_height: i32) !void {
    const position_x = sector.points.getLast().x;

    for (door_indexes) |door_index| {
        const current_door_area = level_doors[door_index].area;
        try addPointToSector(sector, .{
            .x = position_x,
            .y = current_door_area.y,
        }, 0, level_height);
        std.debug.print("\n\tAdded point {}", .{sector.points.getLast()});

        try addPointToSector(sector, .{
            .x = position_x,
            .y = current_door_area.y + current_door_area.height,
        }, door_height, level_height);
        std.debug.print("\n\tAdded point {}", .{sector.points.getLast()});
    }
}

fn addDownLinesPoints(sector: *Sector, door_indexes: []usize, level_doors: []LevelDefinition.Door, level_height: i32, door_height: i32) !void {
    const position_y = sector.points.getLast().y;
    for (door_indexes) |door_index| {
        const current_door_area = level_doors[door_index].area;
        try addPointToSector(sector, .{
            .x = current_door_area.x + current_door_area.width,
            .y = position_y,
        }, 0, level_height);
        std.debug.print("\n\tAdded point {}", .{sector.points.getLast()});

        try addPointToSector(sector, .{
            .x = current_door_area.x,
            .y = position_y,
        }, door_height, level_height);
        std.debug.print("\n\tAdded point {}", .{sector.points.getLast()});
    }
}

fn addLeftLinesPoints(sector: *Sector, door_indexes: []usize, level_doors: []LevelDefinition.Door, level_height: i32, door_height: i32) !void {
    const position_x = sector.points.getLast().x;

    for (door_indexes) |door_index| {
        const current_door_area = level_doors[door_index].area;
        try addPointToSector(sector, .{
            .x = position_x,
            .y = current_door_area.y + current_door_area.height,
        }, 0, level_height);
        std.debug.print("\n\tAdded point {}", .{sector.points.getLast()});

        try addPointToSector(sector, .{
            .x = position_x,
            .y = current_door_area.y,
        }, door_height, level_height);
        std.debug.print("\n\tAdded point {}", .{sector.points.getLast()});
    }
}

pub fn draw(self: Self, scale_x: f32, scale_y: f32, room_color: rl.Color, door_color: rl.Color) void {
    for (self.sectors.items) |sector| {
        const color = switch (sector.sector_type) {
            .door => door_color,
            .room => room_color,
        };

        const sector_points = sector.points.items;
        const sector_lines = sector.lines.items;

        for (sector_lines) |line| {
            const first_point = sector_points[line.points[0]];
            const second_point = sector_points[line.points[1]];
            rl.drawLine(util.scaleByFloat(first_point.x, scale_x), util.scaleByFloat(first_point.y, scale_y), util.scaleByFloat(second_point.x, scale_x), util.scaleByFloat(second_point.y, scale_y), color);
        }
    }
}
