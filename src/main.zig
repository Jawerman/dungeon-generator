// raylib-zig (c) Nikolas Wipper 2023

const std = @import("std");
const rl = @import("raylib");
const BspNode = @import("BspNode.zig");

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
    // const grid_size = 10;

    const depth_increase_interval = 0.1;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    const node = try BspNode.New(screenWidth / 10, screenHeight / 10, 10, 10, allocator);
    defer arena.deinit();

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

        rl.clearBackground(rl.Color.light_gray);

        // drawGrid(screenWidth, screenHeight, grid_size, rl.Color.light_gray);

        const depth: u32 = @intFromFloat(@round(seconds_elapsed / depth_increase_interval));
        node.?.draw(rl.Color.red, 10, depth);

        //----------------------------------------------------------------------------------
    }
}
