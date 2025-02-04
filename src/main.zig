const std = @import("std");

// Configure logging level
pub const std_options: std.Options = .{
    .log_level = .debug,
};

// Import SDL wrapper
const SDL = @import("sdl.zig");
const c = SDL.c;

// Alias commonly used utilities
const Color = SDL.Color;

const E = SDL.Ret.Err;
const W = SDL.Ret.Warn;
const EM = SDL.Ret.ErrWithMsg;
const WM = SDL.Ret.WarnWithMsg;

pub fn main() !void {
    // Create a context to render graphics to a window
    var context = ctx: {
        var context = try SDL.Context.new("NTDash", .{ 1024, 1024 }, .{});

        // Enable v-sync
        context.setHint(SDL.c.SDL_HINT_RENDER_VSYNC, "1");

        break :ctx context;
    };
    // Destroy the context on exit
    defer context.quit();

    // Fill the window with white
    try context.clear(Color.WHITE);
    try context.present();

    var running = true;
    var event: c.SDL_Event = undefined;

    while (running) {
        // Process all events
        while (c.SDL_PollEvent(&event)) {
            if (event.type == c.SDL_EVENT_QUIT) {
                running = false;
            }
        }

        // Update at ~60 FPS
        c.SDL_Delay(@intCast(1000 / 60));
    }
}

test "test" {
    _ = SDL;
}
