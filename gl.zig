const std = @import("std");
const c = @import("bindings.zig");

pub const Vec2 = struct {
    x: f32,
    y: f32,
};

pub const Color = struct {
    r: f32,
    g: f32,
    b: f32,
};

pub const Vertex = struct {
    pos: Vec2,
    color: Color,
};

pub const Shader = struct {
    id: u32 = 0,

    fn compile(source: [*]const u8, shaderType: c_uint, alloc: std.mem.Allocator) !u32 {
        var glint = c.glCreateShader(shaderType);
        c.glShaderSource(glint, 1, &source, null);
        c.glCompileShader(glint);

        var whu: i32 = undefined;
        c.glGetShaderiv(glint, c.GL_COMPILE_STATUS, &whu);
        if (whu == c.GL_FALSE) {
            defer c.glDeleteShader(glint);

            var length: i32 = undefined;
            c.glGetShaderiv(glint, c.GL_INFO_LOG_LENGTH, &length);

            var message = try alloc.alloc(u8, @intCast(usize, length));
            defer alloc.free(message);

            c.glGetShaderInfoLog(glint, length, &length, @ptrCast([*c]u8, message));

            const mtype: *const [4:0]u8 = if (shaderType == c.GL_VERTEX_SHADER) "VERT" else "FRAG";
            std.log.warn("Failed to compile shader(Type: {*})!\nError: {*}\n", .{ mtype, message });
        }

        return glint;
    }

    pub fn create(vertexShader: [*]const u8, fragShader: [*]const u8, alloc: std.mem.Allocator) !Shader {
        const vs = try Shader.compile(vertexShader, c.GL_VERTEX_SHADER, alloc);
        const fs = try Shader.compile(fragShader, c.GL_FRAGMENT_SHADER, alloc);
        defer c.glDeleteShader(vs);
        defer c.glDeleteShader(fs);

        var result = Shader{};
        result.id = c.glCreateProgram();
        c.glAttachShader(result.id, vs);
        c.glAttachShader(result.id, fs);
        c.glLinkProgram(result.id);

        var ok: i32 = 0;
        c.glGetProgramiv(result.id, c.GL_LINK_STATUS, &ok);
        if (ok == c.GL_FALSE) {
            defer c.glDeleteProgram(result.id);

            var error_size: i32 = undefined;
            c.glGetProgramiv(result.id, c.GL_INFO_LOG_LENGTH, &error_size);

            var message = try alloc.alloc(u8, @intCast(usize, error_size));
            defer alloc.free(message);

            c.glGetProgramInfoLog(result.id, error_size, &error_size, @ptrCast([*c]u8, message));
            std.log.warn("Error occured while linking shader program:\n\t{*}\n", .{message});
        }
        c.glValidateProgram(result.id);

        return result;
    }

    pub fn destroy(self: Shader) Shader {
        c.glDeleteProgram(self.id);
        return Shader{};
    }

    pub fn attach(self: Shader) void {
        c.glUseProgram(self.id);
    }
};
