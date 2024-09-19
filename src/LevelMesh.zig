const rl = @import("raylib");
const LevelVisualization = @import("LevelVisualization.zig");
const std = @import("std");

const Self = @This();

mesh: rl.Mesh,
quad_count: usize = 0,
max_quads: usize,

pub fn init(level: LevelVisualization, height: f32) Self {
    const max_quads = level.lines.items.len;
    var result: Self = .{
        .mesh = allocateMesh(@intCast(max_quads * 2), @intCast(max_quads * 4), @intCast(max_quads * 6)),
        .max_quads = max_quads,
    };
    for (level.lines.items) |line| {
        result.add_line(line, height);
    }

    return result;
}

pub fn add_line(self: *Self, line: LevelVisualization.Line, height: f32) void {
    const vertices = [4]rl.Vector3{
        rl.Vector3.init(line.from.x, 0, line.from.y),
        rl.Vector3.init(line.to.x, 0, line.to.y),
        rl.Vector3.init(line.to.x, height, line.to.y),
        rl.Vector3.init(line.from.x, height, line.from.y),
    };
    const first_side = vertices[1].subtract(vertices[0]);
    const second_side = vertices[2].subtract(vertices[1]);

    const normal: rl.Vector3 = first_side.crossProduct(second_side).normalize();

    const indices: [6]u16 = .{ 0, 3, 2, 0, 2, 1 };

    const tex_coords: [4]rl.Vector2 = .{
        rl.Vector2.init(0, 0),
        rl.Vector2.init(0, 1),
        rl.Vector2.init(1, 1),
        rl.Vector2.init(1, 0),
    };

    self.add_quad(vertices, indices, tex_coords, normal);
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
        self.mesh.vertices[quad_offset + offset + 1] = vertices[i].y;
        self.mesh.vertices[quad_offset + offset + 2] = vertices[i].z;
    }
    return self;
}

fn add_quad_normals(self: *Self, index: usize, normal: rl.Vector3) *Self {
    const quad_offset = 12 * index;
    for (0..4) |i| {
        const offset = i * 3;
        self.mesh.normals[quad_offset + offset + 0] = normal.x;
        self.mesh.normals[quad_offset + offset + 1] = normal.y;
        self.mesh.normals[quad_offset + offset + 2] = normal.z;
    }
    return self;
}

fn add_quad_indices(self: *Self, index: usize, indices: [6]u16) *Self {
    const quad_index_offset = index * 4;
    const quad_offset = index * 6;

    for (0..6) |i| {
        self.mesh.indices[i + quad_offset] = @intCast(indices[i] + quad_index_offset);
    }
    return self;
}

fn add_tex_coords(self: *Self, index: usize, tex_coords: [4]rl.Vector2) *Self {
    const quad_offset = index * 8;
    for (0..4) |i| {
        const offset = i * 2;
        self.mesh.texcoords[quad_offset + offset + 0] = tex_coords[i].x;
        self.mesh.texcoords[quad_offset + offset + 1] = tex_coords[i].y;
    }
    return self;
}
