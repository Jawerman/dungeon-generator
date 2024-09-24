const rl = @import("raylib");
const LevelVisualization = @import("LevelVisualization.zig");
const std = @import("std");
const MeshBuilder = @import("Mesh.zig");

const Self = @This();

mesh: rl.Mesh,
mesh_builder: MeshBuilder,
quad_count: usize = 0,
max_quads: usize,

pub fn init(level: LevelVisualization, tiling_ratio: f32, allocator: std.mem.Allocator) !Self {
    const max_quads = level.lines.items.len + (level.sectors.items.len * 2);
    var result: Self = .{
        .mesh = undefined,
        .mesh_builder = MeshBuilder.init(allocator),
        .max_quads = max_quads,
    };
    for (level.lines.items) |line| {
        try result.add_line(line, tiling_ratio);
    }
    for (level.sectors.items) |sector| {
        try result.add_sector_floor(sector);
        try result.add_sector_ceil(sector);
    }

    result.mesh = result.mesh_builder.buildMesh();
    return result;
}

fn add_line(self: *Self, line: LevelVisualization.Line, tiling_ratio: f32) !void {
    const vertices = [4]rl.Vector3{
        rl.Vector3.init(line.from.x, line.min_height, line.from.y),
        rl.Vector3.init(line.to.x, line.min_height, line.to.y),
        rl.Vector3.init(line.to.x, line.max_height, line.to.y),
        rl.Vector3.init(line.from.x, line.max_height, line.from.y),
    };
    const first_side = vertices[1].subtract(vertices[0]);
    const second_side = vertices[2].subtract(vertices[1]);

    // const normal: rl.Vector3 = first_side.crossProduct(second_side).normalize();
    const normals = [_]rl.Vector3{first_side.crossProduct(second_side).normalize()} ** 3;

    const vector = line.to.subtract(line.from);
    var lenght = vector.length();
    if (vector.x < 0 or vector.y < 0) {
        lenght = -lenght;
    }

    const indices: [6]u16 = .{ 0, 1, 2, 0, 2, 3 };

    const origin = line.from.x + line.from.y;
    const min_x = origin * tiling_ratio;
    const max_x = (origin + lenght) * tiling_ratio;

    const max_y = -line.max_height * tiling_ratio;
    const min_y = -line.min_height * tiling_ratio;

    const texcoords: [4]rl.Vector2 = .{
        rl.Vector2.init(min_x, min_y),
        rl.Vector2.init(max_x, min_y),
        rl.Vector2.init(max_x, max_y),
        rl.Vector2.init(min_x, max_y),
    };
    try self.mesh_builder.add_submesh(&vertices, &indices, &texcoords, &normals);
}

fn add_sector_floor(self: *Self, sector: LevelVisualization.Sector) !void {
    const area = sector.area;
    const vertices = [4]rl.Vector3{
        rl.Vector3.init(area.x, sector.floor_height, area.y),
        rl.Vector3.init(area.x + area.width, sector.floor_height, area.y),
        rl.Vector3.init(area.x + area.width, sector.floor_height, area.y + area.height),
        rl.Vector3.init(area.x, sector.floor_height, area.y + area.height),
    };
    const first_side = vertices[1].subtract(vertices[0]);
    const second_side = vertices[2].subtract(vertices[1]);

    // const normal: rl.Vector3 = first_side.crossProduct(second_side).normalize();
    const normals = [_]rl.Vector3{first_side.crossProduct(second_side).normalize()} ** 3;

    const indices: [6]u16 = .{ 0, 3, 2, 0, 2, 1 };

    const texcoords: [4]rl.Vector2 = .{
        rl.Vector2.init(0, 0),
        rl.Vector2.init(0, 1),
        rl.Vector2.init(1, 1),
        rl.Vector2.init(1, 0),
    };

    try self.mesh_builder.add_submesh(&vertices, &indices, &texcoords, &normals);
}

fn add_sector_ceil(self: *Self, sector: LevelVisualization.Sector) !void {
    const area = sector.area;
    const vertices = [4]rl.Vector3{
        rl.Vector3.init(area.x, sector.ceil_height, area.y),
        rl.Vector3.init(area.x, sector.ceil_height, area.y + area.height),
        rl.Vector3.init(area.x + area.width, sector.ceil_height, area.y + area.height),
        rl.Vector3.init(area.x + area.width, sector.ceil_height, area.y),
    };
    const first_side = vertices[1].subtract(vertices[0]);
    const second_side = vertices[2].subtract(vertices[1]);

    // const normal: rl.Vector3 = first_side.crossProduct(second_side).normalize();
    const normals = [_]rl.Vector3{first_side.crossProduct(second_side).normalize()} ** 3;

    const indices: [6]u16 = .{ 0, 3, 2, 0, 2, 1 };

    const texcoords: [4]rl.Vector2 = .{
        rl.Vector2.init(0, 0),
        rl.Vector2.init(0, 1),
        rl.Vector2.init(1, 1),
        rl.Vector2.init(1, 0),
    };

    try self.mesh_builder.add_submesh(&vertices, &indices, &texcoords, &normals);
}

// TODO: Return an error when the quad limit is reached
fn add_quad(self: *Self, vertices: [4]rl.Vector3, indices: [6]u16, tex_coords: [4]rl.Vector2, normal: rl.Vector3) void {
    _ = self.add_quad_vertices(self.quad_count, vertices)
        .add_quad_normals(self.quad_count, normal)
        .add_quad_indices(self.quad_count, indices)
        .add_tex_coords(self.quad_count, tex_coords);
    self.quad_count += 1;
}

fn allocateMesh(num_triangles: u32, num_vertices: u32, num_indices: u32) rl.Mesh {
    const vertices: *[]f32 = @ptrCast(@alignCast(rl.memAlloc(num_vertices * 3 * @sizeOf(f32))));
    const normals: *[]f32 = @ptrCast(@alignCast(rl.memAlloc(num_vertices * 3 * @sizeOf(f32))));
    const texcoords: *[]f32 = @ptrCast(@alignCast(rl.memAlloc(num_vertices * 2 * @sizeOf(f32))));
    const indices: *[]u16 = @ptrCast(@alignCast(rl.memAlloc(num_indices * @sizeOf(u16))));

    return rl.Mesh{
        .vertexCount = @intCast(num_vertices),
        .triangleCount = @intCast(num_triangles),
        .vertices = @ptrCast(vertices),
        .texcoords = @ptrCast(texcoords),
        .texcoords2 = null,
        .normals = @ptrCast(normals),
        .tangents = null,
        .colors = null,
        .indices = @ptrCast(indices),
        .animVertices = null,
        .animNormals = null,
        .boneIds = null,
        .boneWeights = null,
        .vaoId = 0,
        .vboId = null,
    };
}

fn add_quad_vertices(self: *Self, index: usize, vertices: [4]rl.Vector3) *Self {
    const quad_offset = 12 * index;
    for (0..4) |i| {
        const offset = i * 3;
        self.mesh.vertices[quad_offset + offset + 0] = vertices[i].x;
        std.debug.print("\nvertices[{}]: {}", .{ quad_offset + offset + 0, vertices[i].x });

        self.mesh.vertices[quad_offset + offset + 1] = vertices[i].y;
        std.debug.print("\nvertices[{}]: {}", .{ quad_offset + offset + 1, vertices[i].y });

        self.mesh.vertices[quad_offset + offset + 2] = vertices[i].z;
        std.debug.print("\nvertices[{}]: {}", .{ quad_offset + offset + 2, vertices[i].z });
    }
    return self;
}

fn add_quad_normals(self: *Self, index: usize, normal: rl.Vector3) *Self {
    const quad_offset = 12 * index;
    for (0..4) |i| {
        const offset = i * 3;
        self.mesh.normals[quad_offset + offset + 0] = normal.x;
        std.debug.print("\nnormals[{}]: {}", .{ quad_offset + offset + 0, normal.x });

        self.mesh.normals[quad_offset + offset + 1] = normal.y;
        std.debug.print("\nnormals[{}]: {}", .{ quad_offset + offset + 1, normal.y });

        self.mesh.normals[quad_offset + offset + 2] = normal.z;
        std.debug.print("\nnormals[{}]: {}", .{ quad_offset + offset + 2, normal.z });
    }
    return self;
}

fn add_quad_indices(self: *Self, index: usize, indices: [6]u16) *Self {
    const quad_index_offset = index * 4;
    const quad_offset = index * 6;

    for (0..6) |i| {
        self.mesh.indices[i + quad_offset] = @intCast(indices[i] + quad_index_offset);
        std.debug.print("\nindices[{}]: {}", .{ i + quad_offset, @as(u16, @intCast(indices[i] + quad_index_offset)) });
    }
    return self;
}

fn add_tex_coords(self: *Self, index: usize, tex_coords: [4]rl.Vector2) *Self {
    const quad_offset = index * 8;
    for (0..4) |i| {
        const offset = i * 2;
        self.mesh.texcoords[quad_offset + offset + 0] = tex_coords[i].x;
        std.debug.print("\ntexcoords[{}]: {}", .{ quad_offset + offset + 0, tex_coords[i].x });

        self.mesh.texcoords[quad_offset + offset + 1] = tex_coords[i].y;
        std.debug.print("\ntexcoords[{}]: {}", .{ quad_offset + offset + 1, tex_coords[i].y });
    }
    return self;
}
