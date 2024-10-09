const std = @import("std");
const utils = @import("../utils.zig");
const BspTree = @import("BspTree.zig");
const Rectangle = @import("../Rectangle.zig");
const Graph = @import("Graph.zig");

pub fn buildGraphFromBSP(graph: *Graph, bsp: BspTree, minimum_overlap: i32, allocator: std.mem.Allocator) !void {
    var area_index_lookup_map = std.AutoHashMap(usize, usize).init(allocator);
    try collectLeafNodesAreas(graph, bsp, &area_index_lookup_map, 0);
    try generateEdges(graph, bsp, area_index_lookup_map, minimum_overlap, 0);
}

fn generateEdges(graph: *Graph, bsp: BspTree, area_index_lookup_map: std.AutoHashMap(usize, usize), minimum_overlap: i32, root_index: usize) !void {
    const node = bsp.getNode(root_index);

    if (node.splitted_axis) |axis| {
        if (node.first_child) |child_index| {
            try generateEdges(graph, bsp, area_index_lookup_map, minimum_overlap, child_index);
        }
        if (node.second_child) |child_index| {
            try generateEdges(graph, bsp, area_index_lookup_map, minimum_overlap, child_index);
        }
        switch (axis) {
            .x => {
                const left_nodes_indices = bsp.getNode(node.first_child.?).right_nodes.items;
                const right_nodes_indices = bsp.getNode(node.second_child.?).left_nodes.items;
                try addHorizontalSplitEdges(graph, bsp, left_nodes_indices, right_nodes_indices, minimum_overlap, area_index_lookup_map);
            },
            .y => {
                const up_nodes_indices = bsp.getNode(node.first_child.?).down_nodes.items;
                const down_nodes_indices = bsp.getNode(node.second_child.?).up_nodes.items;
                try addVerticalSplitEdges(graph, bsp, up_nodes_indices, down_nodes_indices, minimum_overlap, area_index_lookup_map);
            },
        }
    }
}

fn addHorizontalSplitEdges(graph: *Graph, bsp: BspTree, left_nodes_indices: []usize, right_nodes_indices: []usize, minimum_overlap: i32, area_index_lookup_map: std.AutoHashMap(usize, usize)) !void {
    for (left_nodes_indices) |left_node| {
        for (right_nodes_indices) |right_node| {
            const left_area = bsp.getArea(left_node);
            const right_area = bsp.getArea(right_node);

            const overlapping = left_area.getRectAxisOverlap(right_area, utils.Axis.y);
            if (overlapping >= minimum_overlap) {
                try graph.edges.append(.{ area_index_lookup_map.get(left_node).?, area_index_lookup_map.get(right_node).? });
            }
        }
    }
}

fn addVerticalSplitEdges(graph: *Graph, bsp: BspTree, up_nodes_indices: []usize, down_nodes_indices: []usize, minimum_overlap: i32, area_index_lookup_map: std.AutoHashMap(usize, usize)) !void {
    for (up_nodes_indices) |up_node| {
        for (down_nodes_indices) |down_node| {
            const up_area = bsp.getArea(up_node);
            const down_area = bsp.getArea(down_node);

            const overlapping = up_area.getRectAxisOverlap(down_area, utils.Axis.x);
            if (overlapping >= minimum_overlap) {
                try graph.edges.append(.{ area_index_lookup_map.get(up_node).?, area_index_lookup_map.get(down_node).? });
            }
        }
    }
}

fn collectLeafNodesAreas(graph: *Graph, bsp: BspTree, area_index_lookup_map: *std.AutoHashMap(usize, usize), root_index: usize) !void {
    const node = bsp.getNode(root_index);

    if (node.splitted_axis != null) {
        if (node.first_child) |child_index| {
            try collectLeafNodesAreas(graph, bsp, area_index_lookup_map, child_index);
        }
        if (node.second_child) |child_index| {
            try collectLeafNodesAreas(graph, bsp, area_index_lookup_map, child_index);
        }
    } else {
        const graph_areas_index = graph.areas.items.len;
        try graph.areas.append(bsp.getArea(root_index));
        try area_index_lookup_map.put(root_index, graph_areas_index);
    }
}
