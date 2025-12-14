const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("glad/glad.h"); // GLAD header
});

pub fn main() !void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) return error.SDLInit;
    defer c.SDL_Quit();

    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_PROFILE_MASK, c.SDL_GL_CONTEXT_PROFILE_CORE);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 3);

    const window = c.SDL_CreateWindow("SDL + GLAD Triangle", 100, 100, 800, 600, c.SDL_WINDOW_OPENGL | c.SDL_WINDOW_SHOWN) orelse return error.SDLWindow;
    defer c.SDL_DestroyWindow(window);

    const ctx = c.SDL_GL_CreateContext(window) orelse return error.GLContext;
    defer c.SDL_GL_DeleteContext(ctx);

    // Load OpenGL with GLAD (using SDL's proc address)
    if (c.gladLoadGLLoader(@ptrCast(&c.SDL_GL_GetProcAddress)) == 0) {
        return error.GLADLoadFailed;
    }

    // Now you can use prefixed GL functions: c.glClearColor, c.glClear, etc.

    // Triangle vertices
    const vertices = [_]f32{
        -0.5, -0.5, 0.0,
        0.5,  -0.5, 0.0,
        0.0,  0.5,  0.0,
    };

    // Shaders (same as before, but using prefixed calls)
    const vertex_src =
        \\#version 330 core
        \\layout (location = 0) in vec3 aPos;
        \\void main() { gl_Position = vec4(aPos, 1.0); }
    ;
    const fragment_src =
        \\#version 330 core
        \\out vec4 FragColor;
        \\void main() { FragColor = vec4(1.0, 0.5, 0.2, 1.0); }
    ;

    const vertex_shader = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vertex_shader, 1, &vertex_src.ptr, null);
    c.glCompileShader(vertex_shader);

    const fragment_shader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(fragment_shader, 1, &fragment_src.ptr, null);
    c.glCompileShader(fragment_shader);

    const program = c.glCreateProgram();
    c.glAttachShader(program, vertex_shader);
    c.glAttachShader(program, fragment_shader);
    c.glLinkProgram(program);

    // VAO/VBO
    var vao: u32 = undefined;
    var vbo: u32 = undefined;
    c.glGenVertexArrays(1, &vao);
    c.glGenBuffers(1, &vbo);

    c.glBindVertexArray(vao);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);

    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
    c.glEnableVertexAttribArray(0);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    c.glBindVertexArray(0);

    // Main loop
    var quit = false;
    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            if (event.type == c.SDL_QUIT) quit = true;
        }

        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glUseProgram(program);
        c.glBindVertexArray(vao);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        c.SDL_GL_SwapWindow(window);
    }
}
