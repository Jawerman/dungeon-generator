const std = @import("std");
const rl = @import("raylib");
const BspNode = @import("BspNode.zig");
const Graph = @import("Graph.zig");
const MspBuilder = @import("minimum_spanning_tree_builder.zig");

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

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 1920;
    const screenHeight = 1080;

    // const depth_increase_interval = 0.5;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    const node = try BspNode.init(screenWidth / 10, screenHeight / 10, 10, 10, allocator, split_colors.len);
    var graph = Graph.init(allocator);
    try graph.buildFromBsp(node.?);

    var minimum_graph = try MspBuilder.buildMSTGraph(graph, allocator);

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
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        // drawGrid(screenWidth, screenHeight, grid_size, rl.Color.dark_gray);

        // const depth: u32 = @intFromFloat(@round(seconds_elapsed / depth_increase_interval));
        try node.?.draw(&split_colors, 10, split_colors.len);
        // graph.draw(10, rl.Color.dark_purple);
        minimum_graph.draw(10, rl.Color.white);

        //----------------------------------------------------------------------------------
    }
}
