const std = @import("std");
const rl = @import("raylib");
const utils = @import("../utils.zig");
const Rectangle = @import("../Rectangle.zig");
const Self = @This();

const Error = error{
    NodeTooSmall,
};

var next_id: u32 = 0;

const BspNode = struct {
    first_child: ?usize = null,
    second_child: ?usize = null,

    up_nodes: std.ArrayList(usize),
    down_nodes: std.ArrayList(usize),
    left_nodes: std.ArrayList(usize),
    right_nodes: std.ArrayList(usize),

    splitted_axis: ?utils.Axis = null,

    fn init(allocator: std.mem.Allocator) @This() {
        return .{
            .up_nodes = std.ArrayList(usize).init(allocator),
            .down_nodes = std.ArrayList(usize).init(allocator),
            .left_nodes = std.ArrayList(usize).init(allocator),
            .right_nodes = std.ArrayList(usize).init(allocator),
        };
    }
};

nodes: std.ArrayList(BspNode),
areas: std.ArrayList(Rectangle),

pub fn init(area: Rectangle, min_width: i32, min_height: i32, allocator: std.mem.Allocator, max_depth: u32) !Self {
    var result = Self{
        .nodes = std.ArrayList(BspNode).init(allocator),
        .areas = std.ArrayList(Rectangle).init(allocator),
    };
    const rnd = try getPrng();
    _ = try result.add(area, min_width, min_height, rnd, allocator, max_depth, 0);
    return result;
}

fn getSplitAxis(split_x_min: i32, split_x_max: i32, split_y_min: i32, split_y_max: i32, rnd: std.rand.Random) ?utils.Axis {
    const can_split_x = split_x_min <= split_x_max;
    const can_split_y = split_y_min <= split_y_max;

    return if (can_split_x and can_split_y)
        if (rnd.boolean()) utils.Axis.x else utils.Axis.y
    else if (can_split_x)
        utils.Axis.x
    else if (can_split_y)
        utils.Axis.y
    else
        null;
}

pub fn getNode(self: Self, index: usize) BspNode {
    std.debug.assert(self.nodes.items.len > index);
    return self.nodes.items[index];
}

pub fn getArea(self: Self, index: usize) Rectangle {
    std.debug.assert(self.areas.items.len > index);
    return self.areas.items[index];
}

fn add(self: *Self, area: Rectangle, min_width: i32, min_height: i32, rnd: std.rand.Random, allocator: std.mem.Allocator, max_depth: u32, depth: u32) !usize {
    std.debug.print("\nDEPTH {}", .{depth});
    const node_index = self.areas.items.len;

    std.debug.assert(self.areas.items.len == node_index);
    try self.areas.append(area);
    try self.nodes.append(BspNode.init(allocator));
    std.debug.print("\n\tAdding area: {}, (x: {}, y: {}, width:{}, height: {})", .{ node_index, area.x, area.y, area.width, area.height });

    const split_x_min = min_width;
    const split_x_max = area.width - min_width;
    const split_y_min = min_height;
    const split_y_max = area.height - min_height;

    const max_depth_reached = depth >= max_depth;
    const splitted_axis = if (max_depth_reached)
        null
    else
        getSplitAxis(split_x_min, split_x_max, split_y_min, split_y_max, rnd);

    std.debug.print("\n\tAxis {any}", .{splitted_axis});

    var first_child_index: ?usize = null;
    var second_child_index: ?usize = null;

    if (splitted_axis) |axis| {
        var first_child_area: Rectangle = undefined;
        var second_child_area: Rectangle = undefined;

        switch (axis) {
            .x => {
                const split_position = rnd.intRangeAtMost(i32, split_x_min, split_x_max);
                first_child_area = Rectangle.init(area.x, area.y, split_position, area.height);
                second_child_area = Rectangle.init(area.x + split_position, area.y, area.width - split_position, area.height);
            },
            .y => {
                const split_position = rnd.intRangeAtMost(i32, split_y_min, split_y_max);
                first_child_area = Rectangle.init(area.x, area.y, area.width, split_position);
                second_child_area = Rectangle.init(area.x, area.y + split_position, area.width, area.height - split_position);
            },
        }
        first_child_index = try self.add(first_child_area, min_width, min_height, rnd, allocator, max_depth, depth + 1);
        second_child_index = try self.add(second_child_area, min_width, min_height, rnd, allocator, max_depth, depth + 1);
    }
    self.nodes.items[node_index].splitted_axis = splitted_axis;
    self.nodes.items[node_index].first_child = first_child_index;
    self.nodes.items[node_index].second_child = second_child_index;
    try self.updateNeightbors(node_index);

    const node = self.nodes.items[node_index];
    std.debug.print("\n\tneightbors to node: {}, (up: {any}, down: {any}, left: {any}, right:{any})", .{ node_index, node.up_nodes.items, node.down_nodes.items, node.left_nodes.items, node.right_nodes.items });

    return node_index;
}

fn updateNeightbors(self: *Self, node_index: usize) !void {
    std.debug.assert(self.nodes.items.len > node_index);
    var node = &(self.nodes.items[node_index]);

    if (node.splitted_axis) |axis| {
        const first_child_index = node.first_child.?;
        const second_child_index = node.second_child.?;

        std.debug.assert(self.nodes.items.len > first_child_index);
        const first_child = self.nodes.items[first_child_index];

        std.debug.assert(self.nodes.items.len > second_child_index);
        const second_child = self.nodes.items[second_child_index];

        switch (axis) {
            .x => {
                try node.left_nodes.appendSlice(first_child.left_nodes.items);
                try node.up_nodes.appendSlice(first_child.up_nodes.items);
                try node.down_nodes.appendSlice(first_child.down_nodes.items);

                try node.right_nodes.appendSlice(second_child.right_nodes.items);
                try node.up_nodes.appendSlice(second_child.up_nodes.items);
                try node.down_nodes.appendSlice(second_child.down_nodes.items);
            },
            .y => {
                try node.up_nodes.appendSlice(first_child.up_nodes.items);
                try node.left_nodes.appendSlice(first_child.left_nodes.items);
                try node.right_nodes.appendSlice(first_child.right_nodes.items);

                try node.down_nodes.appendSlice(second_child.down_nodes.items);
                try node.left_nodes.appendSlice(second_child.left_nodes.items);
                try node.right_nodes.appendSlice(second_child.right_nodes.items);
            },
        }
    } else {
        try node.up_nodes.append(node_index);
        try node.down_nodes.append(node_index);
        try node.left_nodes.append(node_index);
        try node.right_nodes.append(node_index);
    }
}

pub fn draw(self: Self, colors: []const rl.Color, scale_x: f32, scale_y: f32) !void {
    const index = 0;
    try self.drawNode(index, colors, scale_x, scale_y, 0);
}

fn drawNode(self: Self, node_index: usize, colors: []const rl.Color, scale_x: f32, scale_y: f32, current_depth: u32) !void {
    std.debug.assert(self.nodes.items.len > node_index);
    const node = self.nodes.items[node_index];

    const selected_color = colors[current_depth % colors.len];

    if (node.splitted_axis) |axis| {
        std.debug.assert(self.areas.items.len > node.first_child.?);
        const first_child_area = self.areas.items[node.first_child.?];
        switch (axis) {
            .x => {
                const split_position: i32 = utils.scaleByFloat(first_child_area.x + first_child_area.width, scale_x);
                const min: i32 = utils.scaleByFloat(first_child_area.y, scale_y);
                const max: i32 = utils.scaleByFloat(first_child_area.y + first_child_area.height, scale_y);
                rl.drawLine(split_position, min, split_position, max, selected_color);
            },
            .y => {
                const split_position: i32 = utils.scaleByFloat(first_child_area.y + first_child_area.height, scale_y);
                const min: i32 = utils.scaleByFloat(first_child_area.x, scale_x);
                const max: i32 = utils.scaleByFloat(first_child_area.x + first_child_area.width, scale_x);
                rl.drawLine(min, split_position, max, split_position, selected_color);
            },
        }
    } else {
        std.debug.assert(self.areas.items.len > node_index);
        const node_area = self.areas.items[node_index];
        const center = node_area.center();

        var buf: [10:0]u8 = .{0} ** 10;
        _ = try std.fmt.bufPrint(&buf, "{}", .{node_index});

        const ptr_to_buf = @as([*:0]const u8, &buf);
        rl.drawText(ptr_to_buf, @intFromFloat(center.x * scale_x), @intFromFloat(center.y * scale_y), 20, rl.Color.white);
    }

    if (node.first_child) |child| {
        try self.drawNode(child, colors, scale_x, scale_y, current_depth + 1);
    }
    if (node.second_child) |child| {
        try self.drawNode(child, colors, scale_x, scale_y, current_depth + 1);
    }
}

pub fn getPrng() !std.rand.Random {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        std.debug.print("Seed {}", .{seed});
        break :blk seed;
    });
    return prng.random();
}
