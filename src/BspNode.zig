const std = @import("std");
const rl = @import("raylib");
const utils = @import("utils.zig");
const Rectangle = @import("Rectangle.zig");

const Self = @This();
const Error = error{
    NodeTooSmall,
};

var next_id: u32 = 0;

first_child: ?*Self,
second_child: ?*Self,

area: Rectangle,

up_nodes: std.ArrayList(*Self),
down_nodes: std.ArrayList(*Self),
left_nodes: std.ArrayList(*Self),
right_nodes: std.ArrayList(*Self),

id: u32,

splitted_axis: ?utils.Axis,

pub fn init(area: Rectangle, min_width: i32, min_height: i32, allocator: std.mem.Allocator, max_depth: u32) !?*Self {
    const rnd = try getPrng();
    return create_node(area, min_width, min_height, rnd, allocator, max_depth, 0);
}

pub fn draw(self: Self, colors: []const rl.Color, scale_x: f32, scale_y: f32, max_depth: u32) !void {
    try self.drawNode(colors, scale_x, scale_y, 0, max_depth);
}

pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    if (self.first_child) |node| {
        node.deinit(allocator);
    }
    if (self.second_child) |node| {
        node.deinit(allocator);
    }
    allocator.destroy(self);
}

fn create_node(area: Rectangle, min_width: i32, min_height: i32, rnd: std.rand.Random, allocator: std.mem.Allocator, max_depth: u32, depth: u32) !?*Self {
    const split_x_min = min_width;
    const split_x_max = area.width - min_width;

    const split_y_min = min_height;
    const split_y_max = area.height - min_height;

    const max_depth_reached = depth >= max_depth;
    const can_split_x = split_x_min <= split_x_max and !max_depth_reached;
    const can_split_y = split_y_min <= split_y_max and !max_depth_reached;

    var first_child: ?*Self = null;
    var second_child: ?*Self = null;

    const splitted_axis = if (can_split_x and can_split_y)
        if (rnd.boolean()) utils.Axis.x else utils.Axis.y
    else if (can_split_x)
        utils.Axis.x
    else if (can_split_y)
        utils.Axis.y
    else
        null;

    if (splitted_axis != null) {
        var first_child_area: Rectangle = undefined;
        var second_child_area: Rectangle = undefined;

        switch (splitted_axis.?) {
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

        first_child = try create_node(first_child_area, min_width, min_height, rnd, allocator, max_depth, depth + 1);
        second_child = try create_node(second_child_area, min_width, min_height, rnd, allocator, max_depth, depth + 1);
    }

    const id = next_id;
    next_id += 1;

    const node = try allocator.create(Self);
    node.* = .{
        .id = id,
        .area = area,
        .splitted_axis = splitted_axis,
        .up_nodes = std.ArrayList(*Self).init(allocator),
        .down_nodes = std.ArrayList(*Self).init(allocator),
        .left_nodes = std.ArrayList(*Self).init(allocator),
        .right_nodes = std.ArrayList(*Self).init(allocator),
        .first_child = first_child,
        .second_child = second_child,
    };

    if (splitted_axis) |axis| switch (axis) {
        .x => {
            if (first_child) |child| {
                try node.*.left_nodes.appendSlice(child.left_nodes.items);
                try node.*.up_nodes.appendSlice(child.up_nodes.items);
                try node.*.down_nodes.appendSlice(child.down_nodes.items);
            }
            if (second_child) |child| {
                try node.*.right_nodes.appendSlice(child.right_nodes.items);
                try node.*.up_nodes.appendSlice(child.up_nodes.items);
                try node.*.down_nodes.appendSlice(child.down_nodes.items);
            }
        },
        .y => {
            if (first_child) |child| {
                try node.*.up_nodes.appendSlice(child.up_nodes.items);
                try node.*.left_nodes.appendSlice(child.left_nodes.items);
                try node.*.right_nodes.appendSlice(child.right_nodes.items);
            }
            if (second_child) |child| {
                try node.*.down_nodes.appendSlice(child.down_nodes.items);
                try node.*.left_nodes.appendSlice(child.left_nodes.items);
                try node.*.right_nodes.appendSlice(child.right_nodes.items);
            }
        },
    } else {
        try node.*.up_nodes.append(node);
        try node.*.down_nodes.append(node);
        try node.*.left_nodes.append(node);
        try node.*.right_nodes.append(node);
    }

    return node;
}

fn drawNode(self: Self, colors: []const rl.Color, scale_x: f32, scale_y: f32, current_depth: u32, max_depth: u32) !void {
    if (current_depth > max_depth) {
        return;
    }
    const selected_color = colors[current_depth % colors.len];
    if (self.splitted_axis) |axis| {
        const first_child_area = self.first_child.?.area;
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
        const center = self.area.center();

        var buf: [10:0]u8 = .{0} ** 10;
        _ = try std.fmt.bufPrint(&buf, "{}", .{self.id});

        const ptr_to_buf = @as([*:0]const u8, &buf);
        rl.drawText(ptr_to_buf, @intFromFloat(center.x * scale_x), @intFromFloat(center.y * scale_y), 20, rl.Color.white);
    }

    if (self.first_child) |child| {
        try child.drawNode(colors, scale_x, scale_y, current_depth + 1, max_depth);
    }
    if (self.second_child) |child| {
        try child.drawNode(colors, scale_x, scale_y, current_depth + 1, max_depth);
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
