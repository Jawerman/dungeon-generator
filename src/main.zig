const std = @import("std");
const rl = @import("raylib");
const BspNode = @import("BspNode.zig");
const Graph = @import("Graph.zig");
const MspBuilder = @import("minimum_spanning_tree_builder.zig");
const Level = @import("Level.zig");
const LevelVisualization = @import("LevelVisualization.zig");
const LeveMesh = @import("LevelMesh.zig");

const split_colors = [_]rl.Color{
    rl.Color.red,
    rl.Color.green,
    rl.Color.blue,
    rl.Color.purple,
    rl.Color.orange,
};

fn drawGrid(screen_width: comptime_int, screen_height: comptime_int, grid_size: comptime_int, color: rl.Color) void {
    for (0..screen_width / grid_size) |i| {
        const position: i32 = @intCast(i * grid_size);
        rl.drawLine(position, 0, position, screen_height, color);
    }
    for (0..screen_height / grid_size) |i| {
        const position: i32 = @intCast(i * grid_size);
        rl.drawLine(0, position, screen_width, position, color);
    }
}

// t: toggle minimum spanning tree
// g: toggle graph
// b: toggle bsp
// m: toggle map
// l: toggle level
pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 1280;
    const screenHeight = 1280;

    const door_size = 0.04;
    const padding = 0.005;
    const minimum_overlap_for_connecting_rooms = door_size * 1.5;

    const level_height = 0.1;

    rl.setTraceLogLevel(rl.TraceLogLevel.log_error);
    rl.setConfigFlags(rl.ConfigFlags{ .window_resizable = true, .vsync_hint = true });
    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    // const depth_increase_interval = 0.5;

    var display_mst = true;
    var display_graph = false;
    var display_bsp = false;
    var display_map = false;
    var display_lines = true;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    const rand = try BspNode.getPrng();
    const min_split_width_ratio = 1.0 / 5.0;
    const min_split_height_ratio = 1.0 / 5.0;

    const node = try BspNode.init(rl.Rectangle.init(0, 0, 1, 1), min_split_height_ratio, min_split_width_ratio, allocator, rand, split_colors.len);
    var graph = Graph.init(allocator);
    try graph.buildFromBsp(node.?, minimum_overlap_for_connecting_rooms, allocator);

    const minimum_graph = try MspBuilder.buildMSTGraph(graph, allocator);
    var level = Level.init(allocator);
    try level.build(minimum_graph, padding, door_size, allocator);

    var visualization = LevelVisualization.init(allocator);
    try visualization.buildFromLevel(level, level_height);

    // Generate MESH
    // -- checked image
    const checked_image = rl.genImageChecked(2, 2, 1, 1, rl.Color.red, rl.Color.green);
    const checked_texture = rl.loadTextureFromImage(checked_image);
    rl.unloadImage(checked_image);
    defer rl.unloadTexture(checked_texture);

    // -- mesh
    var level_mesh = LeveMesh.init(visualization);

    rl.uploadMesh(&(level_mesh.mesh), false);
    // unloadModel takes care of unloading its mesh
    // defer rl.unloadMesh(level_mesh.mesh);

    var level_model = rl.loadModelFromMesh(level_mesh.mesh);
    defer rl.unloadModel(level_model);

    level_model.materials[0].maps[@intFromEnum(rl.MATERIAL_MAP_DIFFUSE)].texture = checked_texture;

    var camera = rl.Camera{
        .position = rl.Vector3.init(0.0, 20.0, 0.0),
        .target = rl.Vector3.init(100.0 / 2.0, 0.0, 100.0 / 2.0),
        .up = rl.Vector3.init(0.0, 1.0, 0.0),
        .fovy = 60.0,
        .projection = rl.CameraProjection.camera_perspective,
    };

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var seconds_elapsed: f32 = 0;

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        defer seconds_elapsed += 1.0 / 60.0;
        // Update
        if (rl.isKeyPressed(rl.KeyboardKey.key_t)) {
            display_mst = !display_mst;
        }
        if (rl.isKeyPressed(rl.KeyboardKey.key_g)) {
            display_graph = !display_graph;
        }
        if (rl.isKeyPressed(rl.KeyboardKey.key_b)) {
            display_bsp = !display_bsp;
        }
        if (rl.isKeyPressed(rl.KeyboardKey.key_m)) {
            display_map = !display_map;
        }
        if (rl.isKeyPressed(rl.KeyboardKey.key_l)) {
            display_lines = !display_lines;
        }

        camera.update(rl.CameraMode.camera_free);

        // Draw
        //----------------------------------------------------------------------------------

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.black);

        {
            camera.begin();
            defer camera.end();

            // DRAW THE MESH
            rl.drawModel(level_model, rl.Vector3.init(0, 0, 0), 100.0, rl.Color.white);
        }

        // const depth: u32 = @intFromFloat(@round(seconds_elapsed / depth_increase_interval));

        if (display_bsp) {
            try node.?.draw(&split_colors, screenWidth, screenHeight, split_colors.len);
        }

        if (display_graph) {
            graph.draw(screenWidth, screenHeight, rl.Color.init(255, 255, 255, 40));
        }

        if (display_mst) {
            minimum_graph.draw(screenWidth, screenHeight, rl.Color.init(255, 255, 255, 150));
        }

        if (display_map) {
            level.draw(screenWidth, screenHeight, rl.Color.init(255, 0, 0, 100), rl.Color.init(0, 255, 0, 255));
        }

        if (display_lines) {
            visualization.draw(screenWidth, screenHeight, rl.Color.init(0, 0, 255, 100), rl.Color.init(255, 0, 0, 255));
        }

        //----------------------------------------------------------------------------------
    }
}
