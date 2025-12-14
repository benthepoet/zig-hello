const std = @import("std");
const zig_hello = @import("zig_hello");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const sdl = c;

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    try zig_hello.bufferedPrint();

    // Initialize SDL
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
        sdl.SDL_Log("Unable to initialize SDL: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer sdl.SDL_Quit();

    // Create window
    const window = sdl.SDL_CreateWindow(
        "Zig + SDL2 — Press ESC to quit",
        sdl.SDL_WINDOWPOS_CENTERED,
        sdl.SDL_WINDOWPOS_CENTERED,
        800,
        600,
        sdl.SDL_WINDOW_RESIZABLE,
    ) orelse {
        sdl.SDL_Log("Failed to create window: %s", sdl.SDL_GetError());
        return error.WindowCreationFailed;
    };
    defer sdl.SDL_DestroyWindow(window);

    // Create renderer
    const renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED) orelse {
        sdl.SDL_Log("Failed to create renderer: %s", sdl.SDL_GetError());
        return error.RendererCreationFailed;
    };
    defer sdl.SDL_DestroyRenderer(renderer);

    var quit = false;
    var event: sdl.SDL_Event = undefined;

    // Main loop
    while (!quit) {
        while (sdl.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                sdl.SDL_QUIT => quit = true,
                sdl.SDL_KEYDOWN => {
                    if (event.key.keysym.sym == sdl.SDLK_ESCAPE) {
                        quit = true;
                    }
                },
                else => {},
            }
        }

        // Clear screen to dark blue
        _ = sdl.SDL_SetRenderDrawColor(renderer, 20, 30, 70, 255);
        _ = sdl.SDL_RenderClear(renderer);

        // Present
        sdl.SDL_RenderPresent(renderer);
        sdl.SDL_Delay(16); // ~60 FPS
    }
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
