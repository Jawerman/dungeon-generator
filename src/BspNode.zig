const std = @import("std");
const rl = @import("raylib");

const Self = @This();
const Error = error{
    NodeTooSmall,
};

const SplitAxis = enum {
    x,
    y,
};

first_child: ?*Self,
second_child: ?*Self,

min_x: u32,
max_x: u32,

min_y: u32,
max_y: u32,

splitted_axis: ?SplitAxis,

pub fn init(width: u32, height: u32, min_width: u32, min_height: u32, allocator: std.mem.Allocator, max_depth: u32) !?*Self {
    return create_node(0, width, 0, height, min_width, min_height, try getPrng(), allocator, max_depth, 0);
}

pub fn draw(self: Self, colors: []const rl.Color, scaling: u32, max_depth: u32) void {
    self.drawNode(colors, scaling, 0, max_depth);
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

fn create_node(min_x: u32, max_x: u32, min_y: u32, max_y: u32, min_width: u32, min_height: u32, rnd: std.rand.Random, allocator: std.mem.Allocator, max_depth: u32, depth: u32) !?*Self {
    const split_x_min = min_x + min_width;
    const split_x_max = max_x - min_width;

    const split_y_min = min_y + min_height;
    const split_y_max = max_y - min_height;

    const can_split_x = split_x_min <= split_x_max;
    const can_split_y = split_y_min <= split_y_max;
    const can_split = can_split_x or can_split_y;

    var first_child: ?*Self = null;
    var second_child: ?*Self = null;
    var splitted_axis: ?SplitAxis = null;

    if (can_split and depth < max_depth) {
        const is_x_splitted_axis = if (can_split_x and can_split_y)
            rnd.boolean()
        else
            can_split_x;
        // if (rnd.boolean()) can_split_x else !can_split_y;

        if (is_x_splitted_axis) {
            splitted_axis = SplitAxis.x;
            const split_position = if (split_x_min == split_x_max)
                split_x_min
            else
                rnd.intRangeLessThan(u32, split_x_min, split_x_max);

            first_child = try create_node(min_x, split_position, min_y, max_y, min_width, min_height, rnd, allocator, max_depth, depth + 1);
            second_child = try create_node(split_position, max_x, min_y, max_y, min_width, min_height, rnd, allocator, max_depth, depth + 1);
        } else {
            splitted_axis = SplitAxis.y;
            const split_position = if (split_y_min == split_y_max)
                split_y_min
            else
                rnd.intRangeLessThan(u32, split_y_min, split_y_max);

            first_child = try create_node(min_x, max_x, min_y, split_position, min_width, min_height, rnd, allocator, max_depth, depth + 1);
            second_child = try create_node(min_x, max_x, split_position, max_y, min_width, min_height, rnd, allocator, max_depth, depth + 1);
        }
    }

    const node = try allocator.create(Self);
    node.* = .{
        .min_x = min_x,
        .max_x = max_x,
        .min_y = min_y,
        .max_y = max_y,
        .splitted_axis = splitted_axis,
        .first_child = first_child,
        .second_child = second_child,
    };
    return node;
}

fn drawNode(self: Self, colors: []const rl.Color, scaling: u32, current_depth: u32, max_depth: u32) void {
    if (current_depth > max_depth) {
        return;
    }
    const selected_color = colors[current_depth % colors.len];
    if (self.splitted_axis) |axis| {
        switch (axis) {
            .x => {
                const split_position: i32 = @intCast(self.first_child.?.max_x * scaling);
                const min: i32 = @intCast(self.min_y * scaling);
                const max: i32 = @intCast(self.max_y * scaling);
                rl.drawLine(split_position, min, split_position, max, selected_color);
            },
            .y => {
                const split_position: i32 = @intCast(self.first_child.?.max_y * scaling);
                const min: i32 = @intCast(self.min_x * scaling);
                const max: i32 = @intCast(self.max_x * scaling);
                rl.drawLine(min, split_position, max, split_position, selected_color);
            },
        }
    }

    if (self.first_child) |child| {
        child.drawNode(colors, scaling, current_depth + 1, max_depth);
    }
    if (self.second_child) |child| {
        child.drawNode(colors, scaling, current_depth + 1, max_depth);
    }
}

fn getPrng() !std.rand.Random {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    return prng.random();
}
