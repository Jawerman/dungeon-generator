const rl = @import("raylib");
const std = @import("std");

const Self = @This();

vertices: std.ArrayList(rl.Vector3),
normals: std.ArrayList(rl.Vector3),
texcoords: std.ArrayList(rl.Vector2),
indices: std.ArrayList(u16),

mesh: rl.Mesh,

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .vertices = std.ArrayList(rl.Vector3).init(allocator),
        .normals = std.ArrayList(rl.Vector3).init(allocator),
        .texcoords = std.ArrayList(rl.Vector2).init(allocator),
        .indices = std.ArrayList(u16).init(allocator),
        .mesh = undefined,
    };
}

pub fn add_submesh(self: *Self, vertices: []const rl.Vector3, indices: []const u16, texcoords: []const rl.Vector2, normals: []const rl.Vector3) !void {
    // It's important to add the indices before the vertex since hte indices uses the vertices array lenght
    // as offset
    try self.add_submesh_indices(indices);
    try self.add_submesh_vertices(vertices);
    try self.add_submesh_texcoords(texcoords);
    try self.add_submesh_normals(normals);
}

fn add_submesh_vertices(self: *Self, vertices: []const rl.Vector3) !void {
    for (vertices) |vertex| {
        try self.vertices.append(vertex);
    }
}

fn add_submesh_normals(self: *Self, normals: []const rl.Vector3) !void {
    for (normals) |normal| {
        try self.normals.append(normal);
    }
}

fn add_submesh_indices(self: *Self, indices: []const u16) !void {
    const offset = self.vertices.items.len;
    for (indices) |index| {
        try self.indices.append(@intCast(index + offset));
    }
}

fn add_submesh_texcoords(self: *Self, texcoords: []const rl.Vector2) !void {
    for (texcoords) |tex_coord| {
        try self.texcoords.append(tex_coord);
    }
}

pub fn buildMesh(self: *Self) rl.Mesh {
    self.allocatemesh();

    self.fillMeshVertices();
    self.fillMeshNormals();
    self.fillMeshTexCoords();
    self.fillMeshIndices();

    return self.mesh;
}

fn allocatemesh(self: *Self) void {
    const num_vertices: u32 = @intCast(self.vertices.items.len);
    const num_normals: u32 = @intCast(self.normals.items.len);
    const num_texcoords: u32 = @intCast(self.texcoords.items.len);
    const num_indices: u32 = @intCast(self.indices.items.len);
    const num_triangles: u32 = @intCast(num_indices / 3);

    const vertices: *[]f32 = @ptrCast(@alignCast(rl.memAlloc(num_vertices * 3 * @sizeOf(f32))));
    const normals: *[]f32 = @ptrCast(@alignCast(rl.memAlloc(num_normals * 3 * @sizeOf(f32))));
    const texcoords: *[]f32 = @ptrCast(@alignCast(rl.memAlloc(num_texcoords * 2 * @sizeOf(f32))));
    const indices: *[]u16 = @ptrCast(@alignCast(rl.memAlloc(num_indices * @sizeOf(u16))));

    self.mesh = rl.Mesh{
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

fn fillMeshVertices(self: *Self) void {
    for (self.vertices.items, 0..) |vertex, i| {
        const offset = i * 3;
        self.mesh.vertices[offset + 0] = vertex.x;
        // std.debug.print("\nvertices[{}]: {}", .{ offset + 0, vertex.x });

        self.mesh.vertices[offset + 1] = vertex.y;
        // std.debug.print("\nvertices[{}]: {}", .{ offset + 1, vertex.y });

        self.mesh.vertices[offset + 2] = vertex.z;
        // std.debug.print("\nvertices[{}]: {}", .{ offset + 2, vertex.z });
    }
}

fn fillMeshNormals(self: *Self) void {
    for (self.normals.items, 0..) |normal, i| {
        const offset = i * 3;
        self.mesh.normals[offset + 0] = normal.x;
        // std.debug.print("\nnormals[{}]: {}", .{ offset + 0, normal.x });

        self.mesh.normals[offset + 1] = normal.y;
        // std.debug.print("\nnormals[{}]: {}", .{ offset + 1, normal.y });

        self.mesh.normals[offset + 2] = normal.z;
        // std.debug.print("\nnormals[{}]: {}", .{ offset + 2, normal.z });
    }
}

fn fillMeshTexCoords(self: *Self) void {
    for (self.texcoords.items, 0..) |texcoord, i| {
        const offset = i * 2;
        self.mesh.texcoords[offset + 0] = texcoord.x;
        // std.debug.print("\ntexcoords[{}]: {}", .{ offset + 0, texcoord.x });

        self.mesh.texcoords[offset + 1] = texcoord.y;
        // std.debug.print("\ntexcoords[{}]: {}", .{ offset + 1, texcoord.y });
    }
}

fn fillMeshIndices(self: *Self) void {
    for (self.indices.items, 0..) |index, i| {
        self.mesh.indices[i] = index;
        // std.debug.print("\nindices[{}]: {}", .{ i, index });
    }
}
