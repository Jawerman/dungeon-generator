const rl = @import("raylib");
const LevelVisualization = @import("LevelVisualization.zig");

const Self = @This();

mesh: rl.Mesh,

pub fn init() Self {
    var result: Self = .{
        .mesh = undefined,
    };

    result.add_line();
    return result;
}

fn add_line(self: *Self) void {
    self.mesh = allocateMesh(2, 4, 6);
    const vertices = [4]rl.Vector3{
        rl.Vector3.init(0, 0, 0),
        rl.Vector3.init(0, 0, 1),
        rl.Vector3.init(1, 0, 1),
        rl.Vector3.init(1, 0, 0),
    };
    const normal: rl.Vector3 = rl.Vector3.init(0, 1, 0);
    const indices: [6]u16 = .{ 0, 1, 2, 0, 2, 3 };

    const text_coords: [4]rl.Vector2 = .{
        rl.Vector2.init(0, 0),
        rl.Vector2.init(0, 0),
        rl.Vector2.init(1, 0),
        rl.Vector2.init(1, 0),
    };

    _ = self.add_quad_vertices(0, vertices)
        .add_quad_normals(0, normal)
        .add_quad_indices(0, indices)
        .add_tex_coords(0, text_coords);
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

fn add_quad_vertices(self: *Self, index: u32, vertices: [4]rl.Vector3) *Self {
    const quad_offset = 12 * index;
    for (0..4) |i| {
        const offset = i * 3;
        self.mesh.vertices[quad_offset + offset + 0] = vertices[i].x;
        self.mesh.vertices[quad_offset + offset + 1] = vertices[i].y;
        self.mesh.vertices[quad_offset + offset + 2] = vertices[i].z;
    }
    return self;
}

fn add_quad_normals(self: *Self, index: u32, normal: rl.Vector3) *Self {
    const quad_offset = 12 * index;
    for (0..4) |i| {
        const offset = i * 3;
        self.mesh.normals[quad_offset + offset + 0] = normal.x;
        self.mesh.normals[quad_offset + offset + 1] = normal.y;
        self.mesh.normals[quad_offset + offset + 2] = normal.z;
    }
    return self;
}

fn add_quad_indices(self: *Self, index: u32, indices: [6]u16) *Self {
    const quad_index_offset = index * 4;
    const quad_offset = index * 6;

    for (0..6) |i| {
        self.mesh.indices[i + quad_offset] = @intCast(indices[i] + quad_index_offset);
    }
    return self;
}

fn add_tex_coords(self: *Self, index: u32, tex_coords: [4]rl.Vector2) *Self {
    const quad_offset = index * 8;
    for (0..4) |i| {
        const offset = i * 2;
        self.mesh.texcoords[quad_offset + offset + 0] = tex_coords[i].x;
        self.mesh.texcoords[quad_offset + offset + 1] = tex_coords[i].y;
    }
    return self;
}
