const std = @import("std");

const Self = @This();

left_child: ?*Self,
right_child: ?*Self,

min_x: u32,
max_x: u32,

min_y: u32,
max_y: u32,

const rl = @import("raylib");

const Error = error{
    NodeTooSmall,
};

fn getPrng() !std.rand.Random {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    return prng.random();
}

pub fn draw(self: Self, line_color: rl.Color, scaling: u32, max_depth: u32) void {
    self.drawNode(line_color, scaling, 0, max_depth);
}

fn drawNode(self: Self, line_color: rl.Color, scaling: u32, current_depth: u32, max_depth: u32) void {
    const has_children = self.left_child != null or self.right_child != null;
    const is_max_depth = current_depth == max_depth;

    if (!has_children or is_max_depth) {
        rl.drawRectangleLines(@intCast(self.min_x * scaling), @intCast(self.min_y * scaling), @intCast((self.max_x - self.min_x) * scaling), @intCast((self.max_y - self.min_y) * scaling), line_color);
    }

    if (self.left_child != null and !is_max_depth) {
        self.left_child.?.drawNode(line_color, scaling, current_depth + 1, max_depth);
    }
    if (self.right_child != null and !is_max_depth) {
        self.right_child.?.drawNode(line_color, scaling, current_depth + 1, max_depth);
    }
}

pub fn New(width: u32, height: u32, min_width: u32, min_height: u32, allocator: std.mem.Allocator) !?*Self {
    return create_node(0, width, 0, height, min_width, min_height, try getPrng(), allocator, 0);
}

fn create_node(min_x: u32, max_x: u32, min_y: u32, max_y: u32, min_width: u32, min_height: u32, rnd: std.rand.Random, allocator: std.mem.Allocator, depth: u32) !?*Self {
    const split_probability = 1;
    const split_x_min = min_x + min_width;
    const split_x_max = max_x - min_width;

    const split_y_min = min_y + min_height;
    const split_y_max = max_y - min_height;

    const can_split_x = split_x_min <= split_x_max;
    const can_split_y = split_y_min <= split_y_max;
    const can_split = (can_split_x or can_split_y) and (split_probability > rnd.float(f32));

    var left_child: ?*Self = null;
    var right_child: ?*Self = null;

    if (can_split) {
        const is_split_x = if (can_split_x and can_split_y)
            rnd.boolean()
        else if (rnd.boolean()) can_split_x else !can_split_y;

        if (is_split_x) {
            const split_position = if (split_x_min == split_x_max)
                split_x_min
            else
                rnd.intRangeLessThan(u32, split_x_min, split_x_max);

            left_child = try create_node(min_x, split_position, min_y, max_y, min_width, min_height, rnd, allocator, depth + 1);
            right_child = try create_node(split_position, max_x, min_y, max_y, min_width, min_height, rnd, allocator, depth + 1);
        } else {
            const split_position = if (split_y_min == split_y_max)
                split_y_min
            else
                rnd.intRangeLessThan(u32, split_y_min, split_y_max);

            left_child = try create_node(min_x, max_x, min_y, split_position, min_width, min_height, rnd, allocator, depth + 1);
            right_child = try create_node(min_x, max_x, split_position, max_y, min_width, min_height, rnd, allocator, depth + 1);
        }
    }

    const node = try allocator.create(Self);
    node.* = .{
        .min_x = min_x,
        .max_x = max_x,
        .min_y = min_y,
        .max_y = max_y,
        .left_child = left_child,
        .right_child = right_child,
    };
    return node;
}
