const std = @import("std");
pub const std_options: std.Options = .{
    .log_level = .debug,
};

const c = @cImport({
    @cDefine("SDL_DISABLE_OLD_NAMES", {});
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3/SDL_revision.h");
    @cDefine("SDL_MAIN_HANDLED", {});
    @cInclude("SDL3/SDL_main.h");
});

const SDL = struct {
    /// Logs an SDL error with the error string.
    pub fn logError(err: anyerror) !void {
        if (err == error.SDLError) std.log.err("SDL Error: ", .{c.SDL_GetError()});
    }

    /// Converts an SDL function's success to an error if failed.
    pub fn @"?"(ret: bool) !void {
        if (ret) return error.SDLError;
    }

    const Context = struct {
        window: *c.SDL_Window,
        renderer: *c.SDL_Renderer,

        pub fn new(title: []const u8, window_size: struct { u32, u32 }) Context {
            errdefer logError;

            // Bypass the requirement for the entrypoint to be "SDL_main".
            c.SDL_SetMainReady();

            // Initialize SDL with the configured flags, only video by default.
            try @"?"(c.SDL_Init(config.initialization_flags));

            // Set the configured hints for the program.
            for (config.hints) |hint| {
                try @"?"(c.SDL_SetHint(hint[0], hint[1]));
            }

            // Create the window with the supplied title and the renderer
            const window: *c.SDL_Window, const renderer: *c.SDL_Renderer = create_window_and_renderer: {
                var window: ?*c.SDL_Window = null;
                var renderer: ?*c.SDL_Renderer = null;
                try @"?"(c.SDL_CreateWindowAndRenderer(title, window_size.width, window_size.height, 0, &window, &renderer));

                break :create_window_and_renderer .{ window.?, renderer.? };
            };

            return .{ .window = window, .renderer = renderer };
        }

        // Hints

        pub fn setHint(name: []const u8, value: []const u8) void {
            try c.SDL_SetHint(name, value) catch logError;
        }

        // Destroy

        pub fn quit(self: *Context) void {
            c.SDL_DestroyRenderer(&self.renderer);
            c.SDL_DestroyWindow(&self.window);

            c.SDL_Quit();
        }

        // Structs

        const Config = struct {
            initialization_flags: c.SDL_InitFlags = c.SDL_INIT_VIDEO,
        };
    };
};

pub fn main() !void {
    errdefer SDL.logError;

    var ctx = SDL.Context.new("Physics Simulation", .{ 1024, 1024 }, .{});
}
