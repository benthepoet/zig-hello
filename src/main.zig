const std = @import("std");
const zglfw = @import("zglfw");
const zopengl = @import("zopengl");

pub fn main() !void {
    try zglfw.init();
    defer zglfw.terminate();

    // Set OpenGL context hints
    zglfw.windowHint(.client_api, .opengl_api);
    zglfw.windowHint(.context_version_major, 4);
    zglfw.windowHint(.context_version_minor, 6);
    zglfw.windowHint(.opengl_profile, .opengl_core_profile);

    const window = try zglfw.Window.create(800, 600, "zopengl + zglfw Triangle", null);
    defer window.destroy();

    // Make the context current (global function, not method)
    zglfw.makeContextCurrent(window);

    // Load OpenGL functions
    try zopengl.loadCoreProfile(zglfw.getProcAddress, 4, 6);

    const gl = zopengl.bindings;

    // Triangle vertices
    const vertices = [_]f32{
        -0.5, -0.5, 0.0,
        0.5,  -0.5, 0.0,
        0.0,  0.5,  0.0,
    };

    // Shaders
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

    // Compile shaders
    const vertex_shader = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vertex_shader, 1, &vertex_shader_src.ptr, null);
    gl.compileShader(vertex_shader);

    const fragment_shader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fragment_shader, 1, &fragment_shader_src.ptr, null);
    gl.compileShader(fragment_shader);

    // Link program
    const program = gl.createProgram();
    gl.attachShader(program, vertex_shader);
    gl.attachShader(program, fragment_shader);
    gl.linkProgram(program);

    // VAO/VBO setup
    var vao: u32 = undefined;
    var vbo: u32 = undefined;
    gl.genVertexArrays(1, &vao);
    gl.genBuffers(1, &vbo);

    gl.bindVertexArray(vao);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.bufferData(gl.ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices, gl.STATIC_DRAW);

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);

    gl.bindBuffer(gl.ARRAY_BUFFER, 0);
    gl.bindVertexArray(0);

    // Main loop
    while (!window.shouldClose()) {
        zglfw.pollEvents();

        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.useProgram(program);
        gl.bindVertexArray(vao);
        gl.drawArrays(gl.TRIANGLES, 0, 3);

        window.swapBuffers();
    }
}
