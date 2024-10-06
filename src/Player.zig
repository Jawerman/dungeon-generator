const rl = @import("raylib");
const Level = @import("./level/LevelDefinition.zig");
const Self = @This();
const Rectangle = @import("Rectangle.zig");

const UP = rl.Vector3.init(0.0, 1.0, 0.0);

radius: f32,

walk_speed: f32,
mouse_look_speed: rl.Vector2,
keys_look_speed: rl.Vector2,

position: rl.Vector3,
target: rl.Vector3,

pub fn init(radius: f32, walk_speed: f32, mouse_look_speed: rl.Vector2, keys_look_speed: rl.Vector2, position: rl.Vector3, target: rl.Vector3) Self {
    return .{
        .radius = radius,
        .walk_speed = walk_speed,
        .mouse_look_speed = mouse_look_speed,
        .position = position,
        .target = target,
        .keys_look_speed = keys_look_speed,
    };
}

pub fn update(self: *Self, level: Level) void {
    _ = level;
    self.target = self.getNewTargetPosition(rl.getMouseDelta().multiply(self.mouse_look_speed));
    self.target = self.getNewTargetPosition(getViewInputVector().multiply(self.keys_look_speed));
    const position_increment = self.getPositionIncrement();

    // self.position = self.getFinalPosition(position_increment, level);
    self.position = self.position.add(position_increment);
    self.target = self.target.add(position_increment);
}

fn getFinalPosition(self: Self, position_increment: rl.Vector3, level: Level) rl.Vector3 {
    const projected_increment = rl.Vector2.init(position_increment.x, position_increment.z);
    const projected_increment_norm = projected_increment.normalize();

    const initial_position = rl.Vector2.init(self.position.x, self.position.z);

    const maybe_area_container: ?Rectangle = for (level.rooms.items) |room| {
        if (room.area.contains(initial_position)) {
            break room.area;
        }
    } else for (level.doors.items) |door| {
        if (door.area.contains(initial_position)) {
            break door.area;
        }
    } else null;

    if (maybe_area_container) |area_container| {
        const final_position = initial_position
            .add(projected_increment)
            .add(projected_increment_norm.scale(self.radius));

        if (area_container.contains(final_position)) {
            return self.position.add(position_increment);
        }
    }
    return self.position;
}

fn getNewTargetPosition(self: Self, velocity: rl.Vector2) rl.Vector3 {
    const right_vector = self.getRightVector();
    const relative_target_position = self.target.subtract(self.position);

    return relative_target_position
        .rotateByAxisAngle(UP, -velocity.x)
        .rotateByAxisAngle(right_vector, -velocity.y)
        .add(self.position);
}

fn getPositionIncrement(self: Self) rl.Vector3 {
    const input = getMovementInputVector()
        .normalize()
        .scale(self.walk_speed);

    const projectedForwardVector = projectOnFloorAndNormalize(self.getForwardVector());
    const projectedRightVector = projectOnFloorAndNormalize(self.getRightVector());

    return rl.Vector3.zero()
        .add(projectedForwardVector.scale(input.y))
        .add(projectedRightVector.scale(input.x));
}

fn getForwardVector(self: Self) rl.Vector3 {
    return self.target.subtract(self.position).normalize();
}

fn getRightVector(self: Self) rl.Vector3 {
    const forward = self.getForwardVector();
    return forward.crossProduct(UP);
}

fn projectOnFloorAndNormalize(v: rl.Vector3) rl.Vector3 {
    return rl.Vector3.init(v.x, 0.0, v.z).normalize();
}

fn getMouseDeltaVectorScaled(self: Self) rl.Vector2 {
    return rl.getMouseDelta().multiply(self.mouse_look_speed);
}

fn getViewInputVector() rl.Vector2 {
    var input = rl.Vector2.zero();
    if (rl.isKeyDown(rl.KeyboardKey.key_up)) {
        input.y += 1.0;
    }
    if (rl.isKeyDown(rl.KeyboardKey.key_down)) {
        input.y -= 1.0;
    }
    if (rl.isKeyDown(rl.KeyboardKey.key_right)) {
        input.x = 1.0;
    }
    if (rl.isKeyDown(rl.KeyboardKey.key_left)) {
        input.x -= 1.0;
    }
    return input;
}

fn getMovementInputVector() rl.Vector2 {
    var input = rl.Vector2.zero();
    if (rl.isKeyDown(rl.KeyboardKey.key_w)) {
        input.y += 1.0;
    }
    if (rl.isKeyDown(rl.KeyboardKey.key_s)) {
        input.y -= 1.0;
    }
    if (rl.isKeyDown(rl.KeyboardKey.key_d)) {
        input.x = 1.0;
    }
    if (rl.isKeyDown(rl.KeyboardKey.key_a)) {
        input.x -= 1.0;
    }
    return input;
}
