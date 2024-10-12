const rl = @import("raylib");
const std = @import("std");
// const BspNode = @import("./BspNode.zig");
const BspTree = @import("./BspTree.zig");
const Graph = @import("./Graph.zig");
const MspBuilder = @import("./minimum_spanning_tree_builder.zig");
const Rectangle = @import("../Rectangle.zig");
const LevelDefinition = @import("./LevelDefinition.zig");
const LevelVisualization = @import("./LevelVisualization.zig");

const GraphFromBsp = @import("./build_graph_from_bsp.zig");

const Self = @This();

const LevelGenerationConfig = struct {
    // BSP
    size: Rectangle,
    min_room_width: i32,
    min_room_height: i32,
    max_recursion_level: u32,

    // GRAPH
    minimum_overlap_for_room_connection: i32,

    // MINIMUM GRAPH
    //

    // LEVEL
    room_padding: i32,
    doors_width: i32,

    // VISUALIZATION
    level_height: i32,
    doors_height: i32,
};

// bsp: ?*BspNode,
bspTree: BspTree,
graph: Graph,
minimum_spanning_tree: Graph,
level_definition: LevelDefinition,
level_visualization: LevelVisualization,

pub fn init(config: LevelGenerationConfig, allocator: std.mem.Allocator) !Self {
    // const node = try BspNode.init(config.size, config.min_room_width, config.min_room_height, allocator, config.max_recursion_level);
    // const node = try BspNode.init(config.size, config.min_room_width, config.min_room_height, allocator, config.max_recursion_level);
    const tree = try BspTree.init(config.size, config.min_room_width, config.min_room_height, allocator, config.max_recursion_level);
    var graph = Graph.init(allocator);
    try GraphFromBsp.buildGraphFromBSP(&graph, tree, config.minimum_overlap_for_room_connection, allocator);
    // try graph.buildFromBsp(node.?, config.minimum_overlap_for_room_connection, allocator);

    const minimum_graph = try MspBuilder.buildMSTGraph(graph, allocator);

    const level = try LevelDefinition.init(minimum_graph, config.room_padding, config.doors_width, allocator);
    const visualization = try LevelVisualization.init(level, config.level_height, config.doors_height, allocator);

    return .{
        .bspTree = tree,
        .graph = graph,
        .minimum_spanning_tree = minimum_graph,
        .level_definition = level,
        .level_visualization = visualization,
    };
}

pub fn drawBsp(self: Self, draw_region: rl.Rectangle, colors: []const rl.Color) !void {
    try self.bspTree.draw(colors, draw_region.width, draw_region.height);
}

pub fn drawGraph(self: Self, draw_region: rl.Rectangle, color: rl.Color) void {
    self.graph.draw(draw_region.width, draw_region.height, color);
}

pub fn drawMinimumSpanningTree(self: Self, draw_region: rl.Rectangle, color: rl.Color) void {
    self.minimum_spanning_tree.draw(draw_region.width, draw_region.height, color);
}

pub fn drawLevelDefinition(self: Self, draw_region: rl.Rectangle, room_color: rl.Color, door_color: rl.Color) void {
    self.level_definition.draw(draw_region.width, draw_region.height, room_color, door_color);
}

pub fn drawLevelVisualization(self: Self, draw_region: rl.Rectangle, room_color: rl.Color, door_color: rl.Color) void {
    self.level_visualization.draw(draw_region.width, draw_region.height, room_color, door_color);
}
