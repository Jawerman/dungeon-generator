const rl = @import("raylib");
const LevelVisualization = @import("LevelVisualization.zig");
const std = @import("std");
const MeshBuilder = @import("Mesh.zig");
const Sector = @import("Sector.zig");
const Rectangle = @import("Rectangle.zig");

pub fn buildMesh(level: LevelVisualization, allocator: std.mem.Allocator) !rl.Mesh {
    var mesh_builder = MeshBuilder.init(allocator);

    for (level.sectors.items, 0..) |sector, i| {
        std.debug.print("\nRender sector {}: {any}", .{ i, sector.area });
        try addSector(&mesh_builder, sector);
    }

    return mesh_builder.buildMesh();
}

pub fn buildWallsMesh(level: LevelVisualization, allocator: std.mem.Allocator) !rl.Mesh {
    var mesh_builder = MeshBuilder.init(allocator);
    for (level.sectors.items, 0..) |sector, i| {
        std.debug.print("\nRender sector {}: {any}", .{ i, sector.area });
        try addSectorLines(&mesh_builder, sector);
    }
    for (level.sectors.items, 0..) |sector, i| {
        std.debug.print("\nRender sector {}: {any}", .{ i, sector.area });
        if (sector.sector_type == Sector.SectorType.door) {
            try addSectorCeil(&mesh_builder, sector.area, sector.ceil_height);
        }
    }
    return mesh_builder.buildMesh();
}

pub fn buildFloorsMesh(level: LevelVisualization, allocator: std.mem.Allocator) !rl.Mesh {
    var mesh_builder = MeshBuilder.init(allocator);
    for (level.sectors.items) |sector| {
        try addSectorFloor(&mesh_builder, sector.area, sector.floor_height);
    }
    return mesh_builder.buildMesh();
}

pub fn buildCeilMesh(level: LevelVisualization, allocator: std.mem.Allocator) !rl.Mesh {
    var mesh_builder = MeshBuilder.init(allocator);
    for (level.sectors.items) |sector| {
        if (sector.sector_type == Sector.SectorType.room) {
            try addSectorCeil(&mesh_builder, sector.area, sector.ceil_height);
        }
    }
    return mesh_builder.buildMesh();
}

fn addSector(mesh_builder: *MeshBuilder, sector: Sector) !void {
    try addSectorLines(mesh_builder, sector);
    try addSectorFloor(mesh_builder, sector.area, sector.floor_height);
    try addSectorCeil(mesh_builder, sector.area, sector.ceil_height);
}

fn addSectorLines(mesh_builder: *MeshBuilder, sector: Sector) !void {
    const sector_points = sector.points.items;
    var current_point = sector_points[0];
    for (sector_points[1..]) |point| {
        defer current_point = point;

        std.debug.print("\n\tPoint x: {}, y: {}, min: {}, max: {}", .{ current_point.x, current_point.y, current_point.min_height, current_point.max_height });
        std.debug.print("\n\tPoint x: {}, y: {}, min: {}, max: {}", .{ point.x, point.y, point.min_height, point.max_height });
        std.debug.print("\n", .{});

        try addLine(mesh_builder, current_point, point);
    }
    std.debug.print("\n\tPoint x: {}, y: {}, min: {}, max: {}", .{ current_point.x, current_point.y, current_point.min_height, current_point.max_height });
    std.debug.print("\n\tPoint x: {}, y: {}, min: {}, max: {}", .{ sector_points[0].x, sector_points[0].y, sector_points[0].min_height, sector_points[0].max_height });
    std.debug.print("\n", .{});
    try addLine(mesh_builder, current_point, sector_points[0]);
}

fn addLine(mesh_builder: *MeshBuilder, start_point: Sector.Point, end_point: Sector.Point) !void {
    const start_x: f32 = @floatFromInt(start_point.x);
    const start_y: f32 = @floatFromInt(start_point.y);
    const end_x: f32 = @floatFromInt(end_point.x);
    const end_y: f32 = @floatFromInt(end_point.y);
    const min_height: f32 = @floatFromInt(start_point.min_height);
    const max_height: f32 = @floatFromInt(start_point.max_height);

    const vertices = [4]rl.Vector3{
        rl.Vector3.init(start_x, min_height, start_y),
        rl.Vector3.init(end_x, min_height, end_y),
        rl.Vector3.init(end_x, max_height, end_y),
        rl.Vector3.init(start_x, max_height, start_y),
    };

    const indices: [6]u16 = .{ 0, 1, 2, 0, 2, 3 };
    const first_side = vertices[1].subtract(vertices[0]);
    const second_side = vertices[2].subtract(vertices[1]);

    const normals = [_]rl.Vector3{first_side.crossProduct(second_side).normalize()} ** 4;

    const line_vector = rl.Vector2.init(end_x, end_y).subtract(rl.Vector2.init(start_x, start_y));
    const line_width = line_vector.length();
    const line_height = max_height - min_height;

    const texcoords: [4]rl.Vector2 = .{
        rl.Vector2.init(0, line_height),
        rl.Vector2.init(line_width, line_height),
        rl.Vector2.init(line_width, 0),
        rl.Vector2.init(0, 0),
    };

    try mesh_builder.add_submesh(&vertices, &indices, &texcoords, &normals);
}

fn addSectorFloor(mesh_builder: *MeshBuilder, area: Rectangle, floor_height: i32) !void {
    const start_x: f32 = @floatFromInt(area.x);
    const start_y: f32 = @floatFromInt(area.y);
    const end_x: f32 = @floatFromInt(area.x + area.width);
    const end_y: f32 = @floatFromInt(area.y + area.height);
    const width: f32 = @floatFromInt(area.width);
    const height: f32 = @floatFromInt(area.height);

    const floor_height_float: f32 = @floatFromInt(floor_height);

    const vertices = [4]rl.Vector3{
        rl.Vector3.init(start_x, floor_height_float, start_y),
        rl.Vector3.init(start_x, floor_height_float, end_y),
        rl.Vector3.init(end_x, floor_height_float, end_y),
        rl.Vector3.init(end_x, floor_height_float, start_y),
    };

    const indices: [6]u16 = .{ 0, 1, 2, 0, 2, 3 };
    const first_side = vertices[1].subtract(vertices[0]);
    const second_side = vertices[2].subtract(vertices[1]);
    const normals = [_]rl.Vector3{first_side.crossProduct(second_side).normalize()} ** 4;

    const texcoords: [4]rl.Vector2 = .{
        rl.Vector2.init(0, 0),
        rl.Vector2.init(0, height),
        rl.Vector2.init(width, height),
        rl.Vector2.init(width, 0),
    };

    try mesh_builder.add_submesh(&vertices, &indices, &texcoords, &normals);
}

fn addSectorCeil(mesh_builder: *MeshBuilder, area: Rectangle, ceil_height: i32) !void {
    const start_x: f32 = @floatFromInt(area.x);
    const start_y: f32 = @floatFromInt(area.y);
    const end_x: f32 = @floatFromInt(area.x + area.width);
    const end_y: f32 = @floatFromInt(area.y + area.height);
    const width: f32 = @floatFromInt(area.width);
    const height: f32 = @floatFromInt(area.height);

    const ceil_height_float: f32 = @floatFromInt(ceil_height);

    const vertices = [4]rl.Vector3{
        rl.Vector3.init(start_x, ceil_height_float, start_y),
        rl.Vector3.init(end_x, ceil_height_float, start_y),
        rl.Vector3.init(end_x, ceil_height_float, end_y),
        rl.Vector3.init(start_x, ceil_height_float, end_y),
    };

    const indices: [6]u16 = .{ 0, 1, 2, 0, 2, 3 };
    const first_side = vertices[1].subtract(vertices[0]);
    const second_side = vertices[2].subtract(vertices[1]);
    const normals = [_]rl.Vector3{first_side.crossProduct(second_side).normalize()} ** 4;

    const texcoords: [4]rl.Vector2 = .{
        rl.Vector2.init(0, 0),
        rl.Vector2.init(width, 0),
        rl.Vector2.init(width, height),
        rl.Vector2.init(0, height),
    };

    try mesh_builder.add_submesh(&vertices, &indices, &texcoords, &normals);
}
