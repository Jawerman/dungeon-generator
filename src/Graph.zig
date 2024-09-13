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
                        const left_min = left_node.area.y;
                        const left_max = left_node.area.y + left_node.area.height;
                        const right_min = right_node.area.y;
                        const right_max = right_node.area.y + right_node.area.height;

                        if ((left_max <= right_min) or (left_min >= right_max)) {
                            continue;
                        }
                        try self.edges.append(.{ left_node, right_node });
                    }
                }
            },
            .y => {
                for (root.first_child.?.down_nodes.items) |up_node| {
                    for (root.second_child.?.up_nodes.items) |down_node| {
                        const up_min = up_node.area.x;
                        const up_max = up_node.area.x + up_node.area.width;
                        const down_min = down_node.area.x;
                        const down_max = down_node.area.x + down_node.area.width;

                        if ((up_max <= down_min) or (up_min >= down_max)) {
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

pub fn draw(self: Self, scale_x: f32, scale_y: f32, color: rl.Color) void {
    for (self.edges.items) |edge| {
        drawEdge(edge, scale_x, scale_y, color);
    }
}

fn drawEdge(edge: Edge, scale_x: f32, scale_y: f32, color: rl.Color) void {
    const first_node_center = BspNode.getRectangeCenter(edge[0].area);
    const second_node_center = BspNode.getRectangeCenter(edge[1].area);

    rl.drawLine(@intFromFloat(first_node_center.x * scale_x), @intFromFloat(first_node_center.y * scale_y), @intFromFloat(second_node_center.x * scale_x), @intFromFloat(second_node_center.y * scale_y), color);
}
