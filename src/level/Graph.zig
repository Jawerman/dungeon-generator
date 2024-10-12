const std = @import("std");
const rl = @import("raylib");
const utils = @import("../utils.zig");
const BspNode = @import("BspNode.zig");
const Rectangle = @import("../Rectangle.zig");

const Self = @This();

pub const Edge = [2]usize;

edges: std.ArrayList(Edge),
areas: std.ArrayList(Rectangle),

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .edges = std.ArrayList(Edge).init(allocator),
        .areas = std.ArrayList(Rectangle).init(allocator),
    };
}

pub fn draw(self: Self, scale_x: f32, scale_y: f32, color: rl.Color) void {
    for (self.edges.items) |edge| {
        self.drawEdge(edge, scale_x, scale_y, color);
    }
}

fn drawEdge(self: Self, edge: Edge, scale_x: f32, scale_y: f32, color: rl.Color) void {
    const first_node_center = self.areas.items[edge[0]].center();
    const second_node_center = self.areas.items[edge[1]].center();

    rl.drawLine(@intFromFloat(first_node_center.x * scale_x), @intFromFloat(first_node_center.y * scale_y), @intFromFloat(second_node_center.x * scale_x), @intFromFloat(second_node_center.y * scale_y), color);
}
