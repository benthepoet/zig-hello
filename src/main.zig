// src/main.zig
const std = @import("std");
const zglfw = @import("zglfw");
const zopengl = @import("zopengl");

pub fn main() !void {
    // Initialize GLFW
    try zglfw.init();
    defer zglfw.terminate();

    // Request OpenGL 4.6 core profile (change to 3.3 if your hardware/driver doesn't support 4.6)
    zglfw.windowHint(.context_version_major, 4);
    zglfw.windowHint(.context_version_minor, 6);
    zglfw.windowHint(.opengl_profile, .opengl_core_profile);
    // Optional: debug context for better error messages
    // zglfw.windowHint(.opengl_debug_context, true);

    // Create the window
    const window = try zglfw.Window.create(800, 600, "zopengl + zglfw Triangle", null);
    defer zglfw.destroyWindow(window);

    // Make the OpenGL context current
    zglfw.makeContextCurrent(window);

    // Optional vsync
    zglfw.swapInterval(1);

    // Load OpenGL functions (core profile 4.6)
    try zopengl.loadCoreProfile(zglfw.getProcAddress, 4, 6);

    // Use the raw bindings (recommended - stable and complete)
    const gl = zopengl.bindings;

    // ------------------------------------------------------------------
    // Triangle vertex data
    // ------------------------------------------------------------------
    const vertices = [_]f32{
        -0.5, -0.5, 0.0,
        0.5,  -0.5, 0.0,
        0.0,  0.5,  0.0,
    };

    // ------------------------------------------------------------------
    // Simple shaders
    // ------------------------------------------------------------------
    const vertex_shader_src =
        \\#version 460 core
        \\layout (location = 0) in vec3 aPos;
        \\void main() {
        \\    gl_Position = vec4(aPos, 1.0);
        \\}
    ;

    const fragment_shader_src =
        \\#version 460 core
        \\out vec4 FragColor;
        \\void main() {
        \\    FragColor = vec4(1.0, 0.5, 0.2, 1.0); // Orange
        \\}
    ;

    // ------------------------------------------------------------------
    // Compile and link shader program
    // ------------------------------------------------------------------
    const vertex_shader = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vertex_shader, 1, &vertex_shader_src.ptr, null);
    gl.compileShader(vertex_shader);

    const fragment_shader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fragment_shader, 1, &fragment_shader_src.ptr, null);
    gl.compileShader(fragment_shader);

    const program = gl.createProgram();
    gl.attachShader(program, vertex_shader);
    gl.attachShader(program, fragment_shader);
    gl.linkProgram(program);

    // ------------------------------------------------------------------
    // Setup VAO and VBO
    // ------------------------------------------------------------------
    var vao: u32 = undefined;
    var vbo: u32 = undefined;

    gl.genVertexArrays(1, &vao);
    gl.genBuffers(1, &vbo);

    gl.bindVertexArray(vao);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.bufferData(gl.ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices, gl.STATIC_DRAW);

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);

    // Unbind
    gl.bindBuffer(gl.ARRAY_BUFFER, 0);
    gl.bindVertexArray(0);

    //const joystick1 = @as(zglfw.Joystick, @enumFromInt(0));
    const joystick: zglfw.Joystick = @enumFromInt(0);

    // ------------------------------------------------------------------
    // Main render loop
    // ------------------------------------------------------------------
    while (!window.shouldClose()) {
        zglfw.pollEvents();

        if (joystick.asGamepad()) |gamepad| {
            const gamepad_state: zglfw.Gamepad.State = gamepad.getState() catch .{};
            const action = gamepad_state.buttons[@intFromEnum(zglfw.Gamepad.Button.a)];
            if (action == .press) {
                std.debug.print("Button A pressed", .{});
            }
        }

        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.useProgram(program);
        gl.bindVertexArray(vao);
        gl.drawArrays(gl.TRIANGLES, 0, 3);

        window.swapBuffers();
    }
}
