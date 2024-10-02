const rl = @import("raylib");
const std = @import("std");
const LevelVisualization = @import("LevelVisualization.zig");
const LevelMeshBuilder = @import("LevelMesh.zig");

const Self = @This();

floorsModel: rl.Model,
wallsModel: rl.Model,
ceilsModel: rl.Model,

pub fn init(level: LevelVisualization, wall_texture: rl.Texture, floor_texture: rl.Texture, ceil_texture: rl.Texture, shader: rl.Shader, allocator: std.mem.Allocator) !Self {
    var floorsMesh = try LevelMeshBuilder.buildFloorsMesh(level, allocator);
    var ceilMesh = try LevelMeshBuilder.buildCeilMesh(level, allocator);
    var wallsMesh = try LevelMeshBuilder.buildWallsMesh(level, allocator);

    rl.uploadMesh(&floorsMesh, false);
    rl.uploadMesh(&ceilMesh, false);
    rl.uploadMesh(&wallsMesh, false);

    var result = Self{
        .floorsModel = rl.loadModelFromMesh(floorsMesh),
        .wallsModel = rl.loadModelFromMesh(wallsMesh),
        .ceilsModel = rl.loadModelFromMesh(ceilMesh),
    };

    result.floorsModel.materials[0].maps[@intFromEnum(rl.MATERIAL_MAP_DIFFUSE)].texture = floor_texture;
    result.wallsModel.materials[0].maps[@intFromEnum(rl.MATERIAL_MAP_DIFFUSE)].texture = wall_texture;
    result.ceilsModel.materials[0].maps[@intFromEnum(rl.MATERIAL_MAP_DIFFUSE)].texture = ceil_texture;

    result.floorsModel.materials[0].shader = shader;
    result.wallsModel.materials[0].shader = shader;
    result.ceilsModel.materials[0].shader = shader;

    return result;
}

pub fn draw(self: Self, position: rl.Vector3, scale: f32, tint: rl.Color) void {
    rl.drawModel(self.wallsModel, position, scale, tint);
    rl.drawModel(self.ceilsModel, position, scale, tint);
    rl.drawModel(self.floorsModel, position, scale, tint);
}

pub fn drawWires(self: Self, position: rl.Vector3, scale: f32, tint: rl.Color) void {
    rl.drawModelWires(self.wallsModel, position, scale, tint);
    rl.drawModelWires(self.ceilsModel, position, scale, tint);
    rl.drawModelWires(self.floorsModel, position, scale, tint);
}

pub fn unload(self: Self) void {
    rl.unloadModel(self.floorsModel);
    rl.unloadModel(self.ceilsModel);
    rl.unloadModel(self.wallsModel);
}
