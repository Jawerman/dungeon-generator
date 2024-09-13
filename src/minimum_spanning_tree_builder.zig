const std = @import("std");
const BspNode = @import("BspNode.zig");
const Graph = @import("Graph.zig");

const NodeConnectionCost = struct {
    node: *const BspNode,
    cost: f32,
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

        // std.debug.print("\nTesting node: {} with current cost: {}", .{ current.node.id, current.cost });

        if (current.edge) |edge| {
            try result.edges.append(edge);
            // std.debug.print("\n\tAdding to result node: {} with cost: {}, with edge {} - {}", .{ current.node.id, current.cost, edge[0].id, edge[1].id });
        }

        for (graph.edges.items) |edge| {
            // std.debug.print("\n\tTesting edge {} - {}", .{ edge[0].id, edge[1].id });
            const joined_node = if (edge[0].id == current.node.id)
                edge[1]
            else if (edge[1].id == current.node.id)
                edge[0]
            else
                continue;

            // std.debug.print("\n\tFound connection with node: {}", .{joined_node.id});

            var joined_node_connection: NodeConnectionCost = undefined;

            for (pending_nodes_queue.items, 0..) |*pending, index| {
                if (joined_node.id == pending.node.id) {
                    joined_node_connection = pending_nodes_queue.removeIndex(index);
                    break;
                }
            } else {
                // std.debug.print("\n\tNode with id: {} not in pending nodes, continue", .{joined_node.id});
                continue;
            }

            // if (joined_node_connection.edge) |current_edge| {
            //     std.debug.print("\n\tCurrent connection: {} with cost: {} and edge: {} - {}", .{ joined_node_connection.node.id, joined_node_connection.cost, current_edge[0].id, current_edge[1].id });
            // } else {
            //     std.debug.print("\n\tCurrent connection: {} with cost: {} and edge: {any}", .{ joined_node_connection.node.id, joined_node_connection.cost, joined_node_connection.edge });
            // }

            const edge_cost = calculateEdgeCost(edge);
            // std.debug.print("\n\tCalculated cost: {}", .{edge_cost});

            if (joined_node_connection.cost > edge_cost) {
                // std.debug.print("\n\tUpdating connection of node: {}, with new cost {} and edge {} - {}", .{ joined_node_connection.node.id, edge_cost, edge[0].id, edge[1].id });
                joined_node_connection.cost = edge_cost;
                joined_node_connection.edge = edge;
            }

            try pending_nodes_queue.add(joined_node_connection);
        }
    }
    return result;
}

// PERF: Transform "Graph.Edge" into an struct to store the edge cost
// so it can be pre-calculated

fn calculateEdgeCost(edge: Graph.Edge) f32 {
    const first_node_center = BspNode.getRectangeCenter(edge[0].area);
    const second_node_center = BspNode.getRectangeCenter(edge[1].area);

    const x_distance = first_node_center.x - second_node_center.x;
    const y_distance = first_node_center.y - second_node_center.y;

    return (x_distance * x_distance) + (y_distance * y_distance);
}
