const std = @import("std");
const rl = @import("raylib");

const BspNode = @import("BspNode.zig");

const Self = @This();
const NodeExposedNodes = struct {
    up: std.ArrayList(*BspNode),
    down: std.ArrayList(*BspNode),
    left: std.ArrayList(*BspNode),
    right: std.ArrayList(*BspNode),
};

edges: std.ArrayList([2]*BspNode),

pub fn init(allocator: std.mem.Allocator) Self {
    return .{ .edges = std.ArrayList([2]*BspNode).init(allocator) };
}

pub fn buildFromBsp(self: *Self, root: BspNode) !void {
    if (root.splitted_axis) |axis| {
        try self.buildFromBsp(root.first_child.?.*);
        try self.buildFromBsp(root.second_child.?.*);
        switch (axis) {
            .x => {
                for (root.first_child.?.right_nodes.items) |right_node| {
                    for (root.second_child.?.left_nodes.items) |left_node| {
                        if (right_node.max_y <= left_node.min_y or right_node.min_y >= right_node.max_y) {
                            continue;
                        }
                        try self.edges.append(.{ right_node, left_node });
                    }
                }
            },
            .y => {
                for (root.first_child.?.down_nodes.items) |down_node| {
                    for (root.second_child.?.up_nodes.items) |up_node| {
                        if (down_node.max_x <= up_node.min_x or down_node.min_x >= up_node.max_x) {
                            continue;
                        }
                        try self.edges.append(.{ down_node, up_node });
                    }
                }
            },
        }
    }
}

pub fn draw(self: Self, scaling: u32, color: rl.Color) void {
    for (self.edges.items) |edge| {
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
}
