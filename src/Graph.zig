const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");
const BspNode = @import("BspNode.zig");

const Self = @This();

pub const Edge = [2]*BspNode;

edges: std.ArrayList(Edge),

// NOTE: maybe I can add a getLeafNodes method into the BspNode to retrieve all leafs so the nodes doesn't
// need to be stored here
nodes: std.ArrayList(*const BspNode),

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .edges = std.ArrayList(Edge).init(allocator),
        .nodes = std.ArrayList(*const BspNode).init(allocator),
    };
}

pub fn buildFromBsp(self: *Self, root: *BspNode, minimum_overlap: f32) !void {
    if (root.splitted_axis) |axis| {
        if (root.first_child) |child| {
            try self.buildFromBsp(child, minimum_overlap);
        }
        if (root.second_child) |child| {
            try self.buildFromBsp(child, minimum_overlap);
        }
        switch (axis) {
            .x => {
                for (root.first_child.?.right_nodes.items) |left_node| {
                    for (root.second_child.?.left_nodes.items) |right_node| {
                        const overlapping = utils.getRectAxisOverlap(left_node.area, right_node.area, utils.Axis.y);
                        if (overlapping >= minimum_overlap) {
                            try self.edges.append(.{ left_node, right_node });
                        }
                    }
                }
            },
            .y => {
                for (root.first_child.?.down_nodes.items) |up_node| {
                    for (root.second_child.?.up_nodes.items) |down_node| {
                        const overlapping = utils.getRectAxisOverlap(up_node.area, down_node.area, utils.Axis.x);
                        if (overlapping >= minimum_overlap) {
                            try self.edges.append(.{ up_node, down_node });
                        }
                    }
                }
            },
        }
    } else {
        try self.nodes.append(root);
    }
}

pub fn draw(self: Self, scale_x: f32, scale_y: f32, color: rl.Color) void {
    for (self.edges.items) |edge| {
        drawEdge(edge, scale_x, scale_y, color);
    }
}

fn drawEdge(edge: Edge, scale_x: f32, scale_y: f32, color: rl.Color) void {
    const first_node_center = utils.getRectCenter(edge[0].area);
    const second_node_center = utils.getRectCenter(edge[1].area);

    rl.drawLine(@intFromFloat(first_node_center.x * scale_x), @intFromFloat(first_node_center.y * scale_y), @intFromFloat(second_node_center.x * scale_x), @intFromFloat(second_node_center.y * scale_y), color);
}
