const std = @import("std");
const rl = @import("raylib");
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

pub fn buildFromBsp(self: *Self, root: *BspNode) !void {
    if (root.splitted_axis) |axis| {
        if (root.first_child) |child| {
            try self.buildFromBsp(child);
        }
        if (root.second_child) |child| {
            try self.buildFromBsp(child);
        }
        switch (axis) {
            .x => {
                for (root.first_child.?.right_nodes.items) |left_node| {
                    for (root.second_child.?.left_nodes.items) |right_node| {
                        if (left_node.max_y <= right_node.min_y or left_node.min_y >= right_node.max_y) {
                            continue;
                        }
                        try self.edges.append(.{ left_node, right_node });
                    }
                }
            },
            .y => {
                for (root.first_child.?.down_nodes.items) |up_node| {
                    for (root.second_child.?.up_nodes.items) |down_node| {
                        if (up_node.max_x <= down_node.min_x or up_node.min_x >= down_node.max_x) {
                            continue;
                        }
                        try self.edges.append(.{ up_node, down_node });
                    }
                }
            },
        }
    } else {
        try self.nodes.append(root);
    }
}

pub fn draw(self: Self, scaling: u32, color: rl.Color) void {
    for (self.edges.items) |edge| {
        drawEdge(edge, scaling, color);
    }
}

fn drawEdge(edge: Edge, scaling: u32, color: rl.Color) void {
    const first_node_min_x = edge[0].*.min_x * scaling;
    const first_node_max_x = edge[0].*.max_x * scaling;
    const first_node_min_y = edge[0].*.min_y * scaling;
    const first_node_max_y = edge[0].*.max_y * scaling;

    const second_node_min_x = edge[1].*.min_x * scaling;
    const second_node_max_x = edge[1].*.max_x * scaling;
    const second_node_min_y = edge[1].*.min_y * scaling;
    const second_node_max_y = edge[1].*.max_y * scaling;

    const first_node_center_x = first_node_min_x + ((first_node_max_x - first_node_min_x) / 2);
    const first_node_center_y = first_node_min_y + ((first_node_max_y - first_node_min_y) / 2);

    const second_node_center_x = second_node_min_x + (((second_node_max_x - second_node_min_x) / 2));
    const second_node_center_y = second_node_min_y + ((second_node_max_y - second_node_min_y) / 2);

    rl.drawLine(@intCast(first_node_center_x), @intCast(first_node_center_y), @intCast(second_node_center_x), @intCast(second_node_center_y), color);
}
