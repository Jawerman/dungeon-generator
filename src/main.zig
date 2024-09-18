const std = @import("std");
const rl = @import("raylib");
const BspNode = @import("BspNode.zig");
const Graph = @import("Graph.zig");
const MspBuilder = @import("minimum_spanning_tree_builder.zig");
const Level = @import("Level.zig");
const LevelVisualization = @import("LevelVisualization.zig");

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

// m: toggle minimum spanning tree
// g: toggle graph
// b: toggle bsp
// a: toggle map
// l: toggle lines
pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 1280;
    const screenHeight = 1280;

    // const depth_increase_interval = 0.5;

    var display_mst = false;
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
    try graph.buildFromBsp(node.?, 0.04, allocator);

    const minimum_graph = try MspBuilder.buildMSTGraph(graph, allocator);
    var level = Level.init(allocator);
    try level.build(minimum_graph, 0.0025, 0.02, allocator);

    var visualization = LevelVisualization.init(allocator);
    try visualization.buildFromLevel(level);

    rl.setTraceLogLevel(rl.TraceLogLevel.log_error);
    rl.setConfigFlags(rl.ConfigFlags{ .window_resizable = true, .vsync_hint = true });
    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var seconds_elapsed: f32 = 0;

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        defer seconds_elapsed += 1.0 / 60.0;
        // Update
        if (rl.isKeyPressed(rl.KeyboardKey.key_m)) {
            display_mst = !display_mst;
        }
        if (rl.isKeyPressed(rl.KeyboardKey.key_g)) {
            display_graph = !display_graph;
        }
        if (rl.isKeyPressed(rl.KeyboardKey.key_b)) {
            display_bsp = !display_bsp;
        }
        if (rl.isKeyPressed(rl.KeyboardKey.key_a)) {
            display_map = !display_map;
        }
        if (rl.isKeyPressed(rl.KeyboardKey.key_l)) {
            display_lines = !display_lines;
        }

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

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
