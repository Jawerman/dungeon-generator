const std = @import("std");
const BspNode = @import("BspNode.zig");
const Graph = @import("Graph.zig");

const NodeConnectionCost = struct {
    node: *const BspNode,
    cost: u32,
    edge: ?Graph.Edge,
};

fn cmpNodeConnectionCosts(context: void, a: NodeConnectionCost, b: NodeConnectionCost) std.math.Order {
    _ = context;
    return std.math.order(a.cost, b.cost);
}

pub fn buildMSTGraph(graph: Graph, allocator: std.mem.Allocator) !Graph {
    var pending_nodes_queue = std.PriorityQueue(NodeConnectionCost, void, cmpNodeConnectionCosts).init(allocator, undefined);
    var result = Graph.init(allocator);
    try result.nodes.appendSlice(graph.nodes.items);

    for (graph.nodes.items) |node| {
        try pending_nodes_queue.add(.{
            .node = node,
            .cost = std.math.maxInt(u32),
            .edge = null,
        });
    }

    while (pending_nodes_queue.items.len > 0) {
        const current = pending_nodes_queue.remove();
        if (current.edge) |edge| {
            try result.edges.append(edge);
        }

        for (graph.edges.items) |edge| {
            const joined_node = if (edge[0].id == current.node.id)
                edge[1]
            else if (edge[1].id == current.node.id)
                edge[0]
            else
                continue;

            const joined_node_connection = for (pending_nodes_queue.items) |*pending| {
                if (joined_node.id == pending.*.node.id) {
                    break pending;
                }
            } else {
                continue;
            };

            const edge_cost = calculateEdgeCost(edge);
            if (joined_node_connection.cost > edge_cost) {
                joined_node_connection.*.cost = edge_cost;
                joined_node_connection.*.edge = edge;
            }
        }
    }

    return result;
}

// PERF: Transform "Graph.Edge" into an struct to store the edge cost
// so it can be pre-calculated

fn calculateEdgeCost(edge: Graph.Edge) u32 {
    const first_node_center = edge[0].calculateCenterPoint();
    const second_node_center = edge[1].calculateCenterPoint();

    const x_distance = @as(i32, @intCast(first_node_center.x)) - @as(i32, @intCast(second_node_center.x));
    const y_distance = @as(i32, @intCast(first_node_center.y)) - @as(i32, @intCast(second_node_center.y));

    return @as(u32, @intCast((x_distance * x_distance) + (y_distance * y_distance)));
}
