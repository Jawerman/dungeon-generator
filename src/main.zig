const std = @import("std");
const rl = @import("raylib");
const LeveMesh = @import("LevelMesh.zig");
const LevelRenderer = @import("LevelRenderer.zig");
const Rectangle = @import("Rectangle.zig");
const FlashLight = @import("FlashLight.zig");
const Player = @import("Player.zig");

const LevelGenerator = @import("./level/Level.zig");

const split_colors = [_]rl.Color{
    rl.Color.red,
    rl.Color.green,
    rl.Color.blue,
    rl.Color.purple,
    rl.Color.orange,
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
    const map_size = 128;
    const screenWidth = 1920;
    const screenHeight = 1080;

    const screen_width_map_ratio: f32 = @as(f32, @floatFromInt(screenWidth)) / @as(f32, @floatFromInt(map_size));
    const screen_height_map_ratio: f32 = @as(f32, @floatFromInt(screenHeight)) / @as(f32, @floatFromInt(map_size));

    const draw_region = rl.Rectangle.init(0.0, 0.0, screen_width_map_ratio, screen_height_map_ratio);

    const door_size = 4;
    const padding = 1;
    const minimum_overlap_for_connecting_rooms = 6;

    const level_height = 8;

    rl.setTraceLogLevel(rl.TraceLogLevel.log_error);
    rl.setConfigFlags(rl.ConfigFlags{ .window_resizable = true, .vsync_hint = true });
    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    var display_mst = false;
    var display_graph = false;
    var display_bsp = false;
    var display_map = false;
    var display_lines = false;
    var display_3d_view = true;
    var enable_camera_update = true;
    var display_3d_wires = false;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    const new_level = try LevelGenerator.init(.{
        .size = Rectangle.init(0, 0, map_size, map_size),
        .min_room_width = map_size / 8,
        .min_room_height = map_size / 8,
        .max_recursion_level = split_colors.len,
        .minimum_overlap_for_room_connection = minimum_overlap_for_connecting_rooms,
        .room_padding = padding,
        .doors_width = door_size,
        .level_height = level_height,
        .doors_height = @divTrunc(level_height, 2),
    }, allocator);

    // ATLAS
    const atlas_image = rl.loadImage("./assets/MOutside_A4.png");
    defer rl.unloadImage(atlas_image);

    const atlas_tile_size = rl.Vector2.init(48.0, 48.0);

    const wall_image = rl.imageFromImage(atlas_image, rl.Rectangle.init(0.0 * atlas_tile_size.x, 0.0 * atlas_tile_size.y, atlas_tile_size.x, atlas_tile_size.y));
    var wall_texture = rl.loadTextureFromImage(wall_image);
    defer rl.unloadTexture(wall_texture);
    rl.genTextureMipmaps(&wall_texture);
    rl.setTextureFilter(wall_texture, rl.TextureFilter.texture_filter_point);

    const floor_image = rl.imageFromImage(atlas_image, rl.Rectangle.init(0 * atlas_tile_size.x, 14.0 * atlas_tile_size.y, atlas_tile_size.x, atlas_tile_size.y));
    var floor_texture = rl.loadTextureFromImage(floor_image);
    defer rl.unloadTexture(floor_texture);
    rl.genTextureMipmaps(&floor_texture);
    rl.setTextureFilter(floor_texture, rl.TextureFilter.texture_filter_point);

    const ceil_image = rl.imageFromImage(atlas_image, rl.Rectangle.init(13.0 * atlas_tile_size.x, 5.0 * atlas_tile_size.y, atlas_tile_size.x, atlas_tile_size.y));
    var ceil_texture = rl.loadTextureFromImage(ceil_image);
    defer rl.unloadTexture(ceil_texture);
    rl.genTextureMipmaps(&ceil_texture);
    rl.setTextureFilter(ceil_texture, rl.TextureFilter.texture_filter_point);

    var camera = rl.Camera{
        .position = rl.Vector3.init(map_size / 2, 3.0, map_size / 2.0),
        .target = rl.Vector3.init(map_size / 2.0, 3.0, 0.0),
        .up = rl.Vector3.init(0.0, 1.0, 0.0),
        .fovy = 60.0,
        .projection = rl.CameraProjection.camera_perspective,
    };

    // SHADER

    const shader = rl.loadShader("./assets/shaders/light.vs.glsl", "./assets/shaders/light.fs.glsl");
    defer rl.unloadShader(shader);
    shader.locs[@intFromEnum(rl.ShaderLocationIndex.shader_loc_vector_view)] = rl.getShaderLocation(shader, "viewPos");

    const ambientLoc = rl.getShaderLocation(shader, "ambient");
    const ambientLight = rl.Vector4.init(1.0, 1.0, 1.0, 0.1);
    rl.setShaderValue(shader, ambientLoc, &ambientLight, rl.ShaderUniformDataType.shader_uniform_vec4);

    var cameraPos = [_]f32{ camera.position.x, camera.position.y, camera.position.z };
    rl.setShaderValue(shader, shader.locs[@intFromEnum(rl.ShaderLocationIndex.shader_loc_vector_view)], &cameraPos, rl.ShaderUniformDataType.shader_uniform_vec4);

    var flash_light = FlashLight.init(camera.position, camera.target.subtract(camera.position).normalize(), rl.Color.init(255, 255, 255, 100), shader);
    var level_renderer = try LevelRenderer.init(new_level.level_visualization, wall_texture, floor_texture, ceil_texture, shader, allocator);

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    var seconds_elapsed: f32 = 0;

    var player = Player.init(1.0, 0.09, rl.Vector2.init(0.003, 0.003), rl.Vector2.init(0.03, -0.03), camera.position, camera.target);

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

        if (enable_camera_update) {
            player.update(new_level);
            // camera.update(rl.CameraMode.camera_first_person);

            camera.target = player.target;
            camera.position = player.position;

            flash_light.position = camera.position;
            flash_light.direction = camera.target.subtract(camera.position).normalize();
            flash_light.update(shader);

            cameraPos = [_]f32{ camera.position.x, camera.position.y, camera.position.z };

            rl.setShaderValue(shader, shader.locs[@intFromEnum(rl.ShaderLocationIndex.shader_loc_vector_view)], &cameraPos, rl.ShaderUniformDataType.shader_uniform_vec4);
        }
        // Draw
        //----------------------------------------------------------------------------------

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.black);
        // drawGrid(screenWidth, screenHeight, screen_width_map_ratio, screen_height_map_ratio, rl.Color.init(255, 255, 255, 20));

        {
            camera.begin();
            defer camera.end();
            if (display_3d_view) {
                // DRAW THE MESH
                level_renderer.draw(rl.Vector3.init(0, 0, 0), 1.0, rl.Color.white);
            }
            if (display_3d_wires) {
                // DRAW THE MESH
                level_renderer.drawWires(rl.Vector3.init(0, 0, 0), 1.0, rl.Color.white);
            }
        }
        //
        // // const depth: u32 = @intFromFloat(@round(seconds_elapsed / depth_increase_interval));
        //
        if (display_bsp) {
            try new_level.drawBsp(draw_region, &split_colors);
        }

        if (display_graph) {
            new_level.drawGraph(draw_region, rl.Color.init(255, 255, 255, 40));
        }

        if (display_mst) {
            new_level.drawMinimumSpanningTree(draw_region, rl.Color.init(255, 255, 255, 150));
        }

        if (display_map) {
            new_level.drawLevelDefinition(draw_region, rl.Color.init(255, 0, 0, 100), rl.Color.init(0, 255, 0, 255));
        }

        if (display_lines) {
            // visualization.draw(screen_width_map_ratio, screen_height_map_ratio, rl.Color.init(0, 0, 255, 100), rl.Color.init(255, 0, 0, 255));
            new_level.drawLevelVisualization(draw_region, rl.Color.init(255, 0, 0, 100), rl.Color.init(0, 255, 0, 255));
            const player_pos = rl.Vector2.init(camera.position.x * screen_width_map_ratio, camera.position.z * screen_height_map_ratio);
            const camera_orientation = camera.target.subtract(camera.position);
            const player_orientation = rl.Vector2.init(camera_orientation.x, camera_orientation.z).normalize();

            drawPlayer(player_pos, player_orientation, 10.0);
            try drawPlayerPosition(player_pos);
        }
        //
        // try drawPositionAndTarget(camera.position, camera.target);
        try drawMousePosition(screenWidth, screenHeight);
        rl.drawFPS(10, 10);
        //----------------------------------------------------------------------------------
    }
}
