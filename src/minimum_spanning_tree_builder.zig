const std = @import("std");
const BspNode = @import("BspNode.zig");
const rl = @import("raylib");
const Graph = @import("Graph.zig");
const utils = @import("utils.zig");

const AreaConnectionCost = struct {
    area_index: usize,
    cost: f32,
    edge: ?Graph.Edge,
};

fn cmpAreaConnectionCosts(context: void, a: AreaConnectionCost, b: AreaConnectionCost) std.math.Order {
    _ = context;
    return std.math.order(a.cost, b.cost);
}

// NOTE: maybe I should use two separate allocators, one for permanent allocation and another for temporal allocation (node connections)
pub fn buildMSTGraph(graph: Graph, allocator: std.mem.Allocator) !Graph {
    var pending_areas_queue = std.PriorityQueue(AreaConnectionCost, void, cmpAreaConnectionCosts).init(allocator, undefined);
    var result = Graph.init(allocator);
    try result.areas.appendSlice(graph.areas.items);

    for (graph.areas.items, 0..) |*area, index| {
        _ = area;
        try pending_areas_queue.add(.{
            .area_index = index,
            .cost = std.math.maxInt(u32),
            .edge = null,
        });
    }

    while (pending_areas_queue.items.len > 0) {
        const current = pending_areas_queue.remove();

        if (current.edge) |edge| {
            try result.edges.append(edge);
        }

        for (graph.edges.items) |edge| {
            const joined_area_index = if (edge[0] == current.area_index)
                edge[1]
            else if (edge[1] == current.area_index)
                edge[0]
            else
                continue;

            var joined_area_connection: AreaConnectionCost = undefined;

            for (pending_areas_queue.items, 0..) |*pending, index| {
                if (joined_area_index == pending.area_index) {
                    joined_area_connection = pending_areas_queue.removeIndex(index);
                    break;
                }
            } else {
                continue;
            }

            const edge_cost = calculateEdgeCost(edge, result.areas);

            if (joined_area_connection.cost > edge_cost) {
                joined_area_connection.cost = edge_cost;
                joined_area_connection.edge = edge;
            }

            try pending_areas_queue.add(joined_area_connection);
        }
    }
    return result;
}

// PERF: Transform "Graph.Edge" into an struct to store the edge cost
// so it can be pre-calculated

fn calculateEdgeCost(edge: Graph.Edge, areas: std.ArrayList(rl.Rectangle)) f32 {
    const first_node_center = utils.getRectCenter(areas.items[edge[0]]);
    const second_node_center = utils.getRectCenter(areas.items[edge[1]]);

    const x_distance = first_node_center.x - second_node_center.x;
    const y_distance = first_node_center.y - second_node_center.y;

    return (x_distance * x_distance) + (y_distance * y_distance);
}
