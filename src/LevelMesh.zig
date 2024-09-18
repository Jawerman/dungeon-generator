const rl = @import("raylib");

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
