const std = @import("std");
const rl = @import("raylib");
const BspNode = @import("BspNode.zig");
const Graph = @import("Graph.zig");
const MspBuilder = @import("minimum_spanning_tree_builder.zig");
const Level = @import("Level.zig");
const LevelVisualization = @import("LevelVisualization.zig");
const LeveMesh = @import("LevelMesh.zig");
const Rectangle = @import("Rectangle.zig");

const split_colors = [_]rl.Color{
    rl.Color.red,
    rl.Color.green,
    // rl.Color.blue,
    // rl.Color.purple,
    // rl.Color.orange,
};

fn drawPositionAndTarget(position: rl.Vector3, target: rl.Vector3) !void {
    var buf: [100:0]u8 = .{0} ** 100;
    _ = try std.fmt.bufPrint(&buf, "position: {:.2} {:.2} {:.2}\ntarget: {:.2} {:.2} {:.2}", .{ position.x, position.y, position.z, target.x, target.y, target.z });
    const ptr_to_buf = @as([*:0]const u8, &buf);

    rl.drawText(ptr_to_buf, 10, 40, 20, rl.Color.white);
}

fn drawMousePosition(width: f32, height: f32) !void {
    const position = rl.getMousePosition();
    var buf: [100:0]u8 = .{0} ** 100;
    _ = try std.fmt.bufPrint(&buf, "position: {:.2} {:.2}", .{ position.x / width, position.y / height });
    const ptr_to_buf = @as([*:0]const u8, &buf);

    rl.drawText(ptr_to_buf, 10, 100, 20, rl.Color.white);
}

fn drawPlayerPosition(position: rl.Vector2) !void {
    var buf: [100:0]u8 = .{0} ** 100;
    _ = try std.fmt.bufPrint(&buf, "player: {:.2} {:.2}", .{ position.x, position.y });
    const ptr_to_buf = @as([*:0]const u8, &buf);

    rl.drawText(ptr_to_buf, 10, 120, 20, rl.Color.white);
}

fn drawPlayer(position: rl.Vector2, orientation: rl.Vector2, size: f32) void {
    const angle = 4.0 * (std.math.pi / 5.0);
    const front_point = position.add(orientation.scale(size));
    const back_left = position.add(orientation.rotate(-angle).scale(size));
    const back_right = position.add(orientation.rotate(angle).scale(size));

    rl.drawTriangle(front_point, back_left, back_right, rl.Color.dark_blue);
}

fn drawGrid(screen_width: comptime_int, screen_height: comptime_int, grid_size_x: comptime_float, grid_size_y: comptime_float, color: rl.Color) void {
    comptime var x_pos: f32 = 0;
    inline while (x_pos < screen_width) : (x_pos += grid_size_x) {
        const position: i32 = @intFromFloat(@round(x_pos));
        rl.drawLine(position, 0, position, screen_height, color);
    }

    comptime var y_pos: f32 = 0;
    inline while (y_pos < screen_width) : (y_pos += grid_size_y) {
        const position: i32 = @intFromFloat(@round(y_pos));
        rl.drawLine(0, position, screen_width, position, color);
    }
}

// t: toggle minimum spanning tree
// g: toggle graph
// b: toggle bsp
// m: toggle map
// l: toggle level
// v: toggle 3d
// c: toggle camera update
// r: toggle draw wire
pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    // const map_scale = 100.0;
    const map_size = 128;
    const screenWidth = 1280;
    const screenHeight = 1280;

    const screen_width_map_ratio: f32 = @as(f32, @floatFromInt(screenWidth)) / @as(f32, @floatFromInt(map_size));
    const screen_height_map_ratio: f32 = @as(f32, @floatFromInt(screenHeight)) / @as(f32, @floatFromInt(map_size));

    // const door_size = 0.04;
    // const padding = 0.005;
    const minimum_overlap_for_connecting_rooms = map_size / 16;
    //
    // const level_height = 0.1;
    // const tiling_ratio = map_scale / 10.0;

    rl.setTraceLogLevel(rl.TraceLogLevel.log_error);
    rl.setConfigFlags(rl.ConfigFlags{ .window_resizable = true, .vsync_hint = true });
    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    var display_mst = false;
    var display_graph = true;
    var display_bsp = true;
    var display_map = false;
    var display_lines = true;
    var display_3d_view = true;
    var enable_camera_update = true;
    var display_3d_wires = false;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    // const min_split_width_ratio = 1.0 / 5.0;
    // const min_split_height_ratio = 1.0 / 5.0;

    const node = try BspNode.init(Rectangle.init(0, 0, map_size, map_size), map_size / 4, map_size / 4, allocator, split_colors.len);
    var graph = Graph.init(allocator);
    try graph.buildFromBsp(node.?, minimum_overlap_for_connecting_rooms, allocator);
    //
    // const minimum_graph = try MspBuilder.buildMSTGraph(graph, allocator);
    // var level = Level.init(allocator);
    // try level.build(minimum_graph, padding, door_size, allocator);
    //
    // var visualization = LevelVisualization.init(allocator);
    // try visualization.buildFromLevel(level, level_height);
    //
    // // Checked texture
    // const checked_image = rl.genImageChecked(2, 2, 1, 1, rl.Color.dark_gray, rl.Color.dark_brown);
    // const checked_texture = rl.loadTextureFromImage(checked_image);
    // rl.unloadImage(checked_image);
    // defer rl.unloadTexture(checked_texture);
    //
    // const texture = rl.loadTexture("./assets/cubicmap_atlas.png");
    // defer rl.unloadTexture(texture);
    //
    // // Generate MESH
    // var level_mesh = try LeveMesh.init(visualization, tiling_ratio, allocator);
    // rl.uploadMesh(&(level_mesh.mesh), false);
    // // unloadModel takes care of unloading its mesh
    // // defer rl.unloadMesh(level_mesh.mesh);
    //
    // var level_model = rl.loadModelFromMesh(level_mesh.mesh);
    // defer rl.unloadModel(level_model);
    //
    // level_model.materials[0].maps[@intFromEnum(rl.MATERIAL_MAP_DIFFUSE)].texture = texture;
    //
    // var camera = rl.Camera{
    //     .position = rl.Vector3.init(map_scale / 2.0, 3.0, map_scale / 2.0),
    //     .target = rl.Vector3.init(map_scale / 2.0, 3.0, 0.0),
    //     .up = rl.Vector3.init(0.0, 1.0, 0.0),
    //     .fovy = 60.0,
    //     .projection = rl.CameraProjection.camera_perspective,
    // };

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
        if (rl.isKeyPressed(rl.KeyboardKey.key_v)) {
            display_3d_view = !display_3d_view;
        }
        if (rl.isKeyPressed(rl.KeyboardKey.key_c)) {
            enable_camera_update = !enable_camera_update;
        }
        if (rl.isKeyPressed(rl.KeyboardKey.key_r)) {
            display_3d_wires = !display_3d_wires;
        }

        // if (enable_camera_update) {
        //     camera.update(rl.CameraMode.camera_first_person);
        // }
        // Draw
        //----------------------------------------------------------------------------------

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.black);
        drawGrid(screenWidth, screenHeight, screen_width_map_ratio, screen_height_map_ratio, rl.Color.dark_gray);

        // {
        //     camera.begin();
        //     defer camera.end();
        //     if (display_3d_view) {
        //         // DRAW THE MESH
        //         rl.drawModel(level_model, rl.Vector3.init(0, 0, 0), map_scale, rl.Color.white);
        //     }
        //     if (display_3d_wires) {
        //         // DRAW THE MESH
        //         rl.drawModelWires(level_model, rl.Vector3.init(0, 0, 0), map_scale, rl.Color.blue);
        //     }
        // }
        //
        // // const depth: u32 = @intFromFloat(@round(seconds_elapsed / depth_increase_interval));
        //
        if (display_bsp) {
            try node.?.draw(&split_colors, screen_width_map_ratio, screen_height_map_ratio, split_colors.len);
        }
        //
        if (display_graph) {
            graph.draw(screen_width_map_ratio, screen_height_map_ratio, rl.Color.init(255, 255, 255, 40));
        }
        //
        // if (display_mst) {
        //     minimum_graph.draw(screenWidth, screenHeight, rl.Color.init(255, 255, 255, 150));
        // }
        //
        // if (display_map) {
        //     level.draw(screenWidth, screenHeight, rl.Color.init(255, 0, 0, 100), rl.Color.init(0, 255, 0, 255));
        // }
        //
        // if (display_lines) {
        //     visualization.draw(screenWidth, screenHeight, rl.Color.init(0, 0, 255, 100), rl.Color.init(255, 0, 0, 255));
        //     const player_pos = rl.Vector2.init((camera.position.x / map_scale) * screenWidth, (camera.position.z / map_scale) * screenHeight);
        //     const camera_orientation = camera.target.subtract(camera.position);
        //     const player_orientation = rl.Vector2.init(camera_orientation.x, camera_orientation.z).normalize();
        //
        //     drawPlayer(player_pos, player_orientation, 10.0);
        //     try drawPlayerPosition(player_pos);
        // }
        //
        // try drawPositionAndTarget(camera.position, camera.target);
        try drawMousePosition(screenWidth, screenHeight);
        // rl.drawText("Welcome to the third dimension!", 10, 40, 20, rl.Color.dark_gray);
        rl.drawFPS(10, 10);
        //----------------------------------------------------------------------------------
    }
}
