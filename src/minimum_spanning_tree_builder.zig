const std = @import("std");
const BspNode = @import("BspNode.zig");
const Graph = @import("Graph.zig");

const NodeConnectionCost = struct {
    node: *BspNode,
    cost: u32,
    edge: ?Graph.Edge,
};

fn cmpNodeConnectionCosts(context: void, a: NodeConnectionCost, b: NodeConnectionCost) std.math.Order {
    _ = context;
    return std.math.order(a.cost, b.cost);
}

pub fn buildMSTGraph(graph: Graph, allocator: std.mem.Allocator) Graph {
    var pending_nodes_queue = std.PriorityQueue(NodeConnectionCost, void, cmpNodeConnectionCosts).init(allocator, undefined);
    const result = Graph.init(allocator);
    result.nodes.appendSlice(graph.nodes.items);

    for (graph.nodes.items) |node| {
        pending_nodes_queue.add(.{
            .node = node,
            .cost = std.math.maxInt(u32),
            .edge = null,
        });
    }

    while (pending_nodes_queue.items.len > 0) {
        const current = pending_nodes_queue.remove();
        if (current.edge) |edge| {
            result.edges.append(edge);
        }

        for (graph.edges) |edge| {
            // var joined_node: ?BspNode = null;
            const joined_node = if (edge[0] == current.node.*)
                edge[1]
            else if (edge[1] == current.node.*)
                edge[0]
            else
                continue;

            const joined_node_connection_const = for (pending_nodes_queue.items) |pending| {
                if (joined_node == pending.node) break pending;
            } else {
                continue;
            };

            _ = joined_node_connection_const;

            // const edge_cost = edge[0].

        }
    }

    return result;
}

// PERF: Transform "Graph.Edge" into an struct to store the edge cost
// so it can be pre-calculated

// fn calculateEdgeCost(edge: Graph.Edge): u32 {
// }
