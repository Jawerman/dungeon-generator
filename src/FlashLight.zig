const rl = @import("raylib");
const Self = @This();

position: rl.Vector3,
direction: rl.Vector3,
color: rl.Color,

position_loc: i32,
direction_loc: i32,
color_loc: i32,

pub fn init(
    position: rl.Vector3,
    direction: rl.Vector3,
    color: rl.Color,
    shader: rl.Shader,
) Self {
    var result = Self{
        .position = position,
        .direction = direction,
        .color = color,

        .position_loc = rl.getShaderLocation(shader, "flashLight.position"),
        .direction_loc = rl.getShaderLocation(shader, "flashLight.direction"),
        .color_loc = rl.getShaderLocation(shader, "flashLight.color"),
    };
    result.update(shader);
    return result;
}

pub fn update(self: Self, shader: rl.Shader) void {
    const position = [_]f32{ self.position.x, self.position.y, self.position.z };
    rl.setShaderValue(shader, self.position_loc, &position, rl.ShaderUniformDataType.shader_uniform_vec3);
    const direction = [_]f32{ self.direction.x, self.direction.y, self.direction.z };
    rl.setShaderValue(shader, self.direction_loc, &direction, rl.ShaderUniformDataType.shader_uniform_vec3);

    const color = [_]f32{
        @as(f32, @floatFromInt(self.color.r)) / 255.0,
        @as(f32, @floatFromInt(self.color.g)) / 255.0,
        @as(f32, @floatFromInt(self.color.b)) / 255.0,
        @as(f32, @floatFromInt(self.color.a)) / 255.0,
    };
    rl.setShaderValue(shader, self.color_loc, &color, rl.ShaderUniformDataType.shader_uniform_vec4);
}
