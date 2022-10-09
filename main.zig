const std = @import("std");
const c = @import("bindings.zig");
const gl = @import("gl.zig");

const WINDOW_SIZE = [2]c_int{ 500, 500 };
const WINDOW_TITLE = "OpenGL Example";

/// Vertex data
pub const vertices = [3]gl.Vertex{
    gl.Vertex{ .pos = gl.Vec2{ .x = -0.6, .y = -0.4 }, .color = gl.Color{ .r = 1.0, .g = 0.0, .b = 0.0 } },
    gl.Vertex{ .pos = gl.Vec2{ .x = 0.6, .y = -0.4 }, .color = gl.Color{ .r = 0.0, .g = 1.0, .b = 0.0 } },
    gl.Vertex{ .pos = gl.Vec2{ .x = 0.0, .y = 0.6 }, .color = gl.Color{ .r = 0.0, .g = 0.0, .b = 1.0 } },
};

/// Vertex shader source
pub const vs_src = @embedFile("shader.vs.glsl");

/// Fragment shader source
pub const fs_src = @embedFile("shader.fs.glsl");

pub fn main() anyerror!void {
    if (c.glfwInit() == 0) {
        @panic("Failed to initialize GLFW");
    }
    defer c.glfwTerminate();

    // Setup OpenGL context and window hints
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_RESIZABLE, 1);

    var window = c.glfwCreateWindow(WINDOW_SIZE[0], WINDOW_SIZE[1], WINDOW_TITLE, null, null);
    defer c.glfwDestroyWindow(window);

    c.glfwMakeContextCurrent(window);

    if (c.gladLoadGLLoader(@ptrCast(fn ([*c]const u8) callconv(.C) ?*anyopaque, c.glfwGetProcAddress)) == 0) {
        @panic("Failed to load OpenGL/GLAD!");
    }

    // Vertex buffer and array buffer
    var vbo: u32 = undefined;
    var vao: u32 = undefined;

    // Create shader program
    var program = try gl.Shader.create(vs_src, fs_src, std.heap.page_allocator);
    defer program = program.destroy();

    // Generate buffers
    c.glGenVertexArrays(1, &vao);
    c.glGenBuffers(1, &vbo);

    // Bind vertex array
    c.glBindVertexArray(vao);

    // Bind vertex buffer to the current array
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(gl.Vertex) * 3, @ptrCast(*const anyopaque, &vertices), c.GL_STATIC_DRAW);

    // set offset and stride to determine where point data and color data are
    const offset: usize = @sizeOf(gl.Vec2);
    const stride: i32 = @sizeOf(gl.Vertex);

    // Setup shader attribute arrays
    c.glEnableVertexAttribArray(0);
    c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, stride, null);
    c.glEnableVertexAttribArray(1);
    c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, stride, @intToPtr(*i32, offset));

    // Unbind buffers
    c.glBindVertexArray(0);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);

    var lastFPSReport: f64 = undefined;
    var previousTime: f64 = undefined;
    var fps: f64 = undefined;

    while (c.glfwWindowShouldClose(window) == 0) {
        defer c.glfwSwapBuffers(window);
        defer c.glfwPollEvents();

        var width: c_int = 0;
        var height: c_int = 0;
        c.glfwGetFramebufferSize(window, &width, &height);
        c.glViewport(0, 0, width, height);

        // Count FPS
        var currentTime = c.glfwGetTime();
        fps = 1.0 / (currentTime - previousTime);
        previousTime = currentTime;

        if (currentTime - lastFPSReport > 1) {
            lastFPSReport = currentTime;

            const title = try std.fmt.allocPrint(std.heap.page_allocator, "{s} - FPS: {d:.2}", .{ WINDOW_TITLE, fps });
            defer std.heap.page_allocator.free(title);

            c.glfwSetWindowTitle(window, @ptrCast([*c]const u8, title));
        }

        c.glClear(c.GL_COLOR_BUFFER_BIT);

        // Attach shader program and draw vertex array
        program.attach();
        c.glBindVertexArray(vao);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
    }
}
