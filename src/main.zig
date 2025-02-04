const std = @import("std");

// Configure logging level
pub const std_options: std.Options = .{
    .log_level = .debug,
};

// Import SDL wrapper
const SDL = @import("sdl.zig");

// Alias commonly used utilities
const Color = SDL.Color;

pub fn main() !void {
    // Create a context to render graphics to a window
    var context = ctx: {
        var context = try SDL.Context.new("NTDash", .{ 1024, 1024 }, .{});

        // Enable v-sync
        context.setHint(SDL.c.SDL_HINT_RENDER_VSYNC, "1");

        break :ctx context;
    };
    defer context.quit();

    try context.clear(Color.WHITE);
    try context.present();
}

test {
    _ = SDL;
}
