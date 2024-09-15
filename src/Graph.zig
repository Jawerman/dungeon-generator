const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");
const BspNode = @import("BspNode.zig");

const Self = @This();

pub const Edge = [2]usize;

edges: std.ArrayList(Edge),
areas: std.ArrayList(rl.Rectangle),

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .edges = std.ArrayList(Edge).init(allocator),
        .areas = std.ArrayList(rl.Rectangle).init(allocator),
    };
}

// NOTE: maybe buildFromBsp should handle its own allocator for temporal allocation, in this case the lookup hashmap
pub fn buildFromBsp(self: *Self, root: *BspNode, minimum_overlap: f32, allocator: std.mem.Allocator) !void {
    var area_index_lookup_map = std.AutoHashMap(u32, usize).init(allocator);
    try self.collect_leaf_nodes(root, &area_index_lookup_map);
    try self.generate_edges(root, area_index_lookup_map, minimum_overlap);
}

pub fn generate_edges(self: *Self, root: *BspNode, area_index_lookup_map: std.AutoHashMap(u32, usize), minimum_overlap: f32) !void {
    if (root.splitted_axis) |axis| {
        if (root.first_child) |child| {
            try self.generate_edges(child, area_index_lookup_map, minimum_overlap);
        }
        if (root.second_child) |child| {
            try self.generate_edges(child, area_index_lookup_map, minimum_overlap);
        }
        switch (axis) {
            .x => {
                for (root.first_child.?.right_nodes.items) |left_node| {
                    for (root.second_child.?.left_nodes.items) |right_node| {
                        const overlapping = utils.getRectAxisOverlap(left_node.area, right_node.area, utils.Axis.y);
                        if (overlapping >= minimum_overlap) {
                            try self.edges.append(.{ area_index_lookup_map.get(left_node.id).?, area_index_lookup_map.get(right_node.id).? });
                        }
                    }
                }
            },
            .y => {
                for (root.first_child.?.down_nodes.items) |up_node| {
                    for (root.second_child.?.up_nodes.items) |down_node| {
                        const overlapping = utils.getRectAxisOverlap(up_node.area, down_node.area, utils.Axis.x);
                        if (overlapping >= minimum_overlap) {
                            try self.edges.append(.{ area_index_lookup_map.get(up_node.id).?, area_index_lookup_map.get(down_node.id).? });
                        }
                    }
                }
            },
        }
    }
}

fn collect_leaf_nodes(self: *Self, root: *BspNode, index_lookup_hash_map: *std.AutoHashMap(u32, usize)) !void {
    if (root.splitted_axis != null) {
        if (root.first_child) |child| {
            try self.collect_leaf_nodes(child, index_lookup_hash_map);
        }
        if (root.second_child) |child| {
            try self.collect_leaf_nodes(child, index_lookup_hash_map);
        }
    } else {
        const index = self.areas.items.len;
        try self.areas.append(root.area);
        try index_lookup_hash_map.put(root.id, index);
    }
}

pub fn draw(self: Self, scale_x: f32, scale_y: f32, color: rl.Color) void {
    for (self.edges.items) |edge| {
        self.drawEdge(edge, scale_x, scale_y, color);
    }
}

fn drawEdge(self: Self, edge: Edge, scale_x: f32, scale_y: f32, color: rl.Color) void {
    const first_node_center = utils.getRectCenter(self.areas.items[edge[0]]);
    const second_node_center = utils.getRectCenter(self.areas.items[edge[1]]);

    rl.drawLine(@intFromFloat(first_node_center.x * scale_x), @intFromFloat(first_node_center.y * scale_y), @intFromFloat(second_node_center.x * scale_x), @intFromFloat(second_node_center.y * scale_y), color);
}
