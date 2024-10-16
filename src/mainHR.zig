const std = @import("std");
const rl = @import("raylib");

const GameStatePtr = *anyopaque;

var game_init: *const fn () GameStatePtr = undefined;
var game_reload: *const fn (GameStatePtr) void = undefined;
var game_tick: *const fn (GameStatePtr) void = undefined;
var game_draw: *const fn (GameStatePtr) void = undefined;

pub fn main() !void {
    recompileGameLib() catch
        std.debug.print("Failed to recompile game.dll\n", .{});
    loadGameLib() catch
        @panic("Failed to load game.dll");
    const game_state = game_init();
    while (!rl.windowShouldClose()) {
        if (rl.isKeyPressed(.key_f5)) {
            unloadGameLib() catch unreachable;
            recompileGameLib() catch
                std.debug.print("Failed to recompile game.dll\n", .{});
            loadGameLib() catch
                @panic("Failed to load game.dll");
            std.log.info("Reloading game", .{});
            game_reload(game_state);
        }
        game_tick(game_state);
        rl.beginDrawing();
        game_draw(game_state);
        rl.endDrawing();
    }
    rl.closeWindow();
}

// main.zig (hot-reload)
var game_dyn_lib: ?std.DynLib = null;
fn loadGameLib() !void {
    if (game_dyn_lib != null) return error.AlreadyLoaded;
    var dyn_lib = std.DynLib.open("zig-out/lib/libgame.so") catch {
        return error.OpenFail;
    };
    game_dyn_lib = dyn_lib;
    game_init = dyn_lib.lookup(@TypeOf(game_init), "init") orelse return error.LookupFail;
    game_reload = dyn_lib.lookup(@TypeOf(game_reload), "reload") orelse return error.LookupFail;
    game_tick = dyn_lib.lookup(@TypeOf(game_tick), "update") orelse return error.LookupFail;
    game_draw = dyn_lib.lookup(@TypeOf(game_draw), "draw") orelse return error.LookupFail;
    std.log.info("Loaded game.so", .{});
}

fn unloadGameLib() !void {
    if (game_dyn_lib) |*dyn_lib| {
        dyn_lib.close();
        game_dyn_lib = null;
    } else {
        return error.AlreadyUnloaded;
    }
}

fn recompileGameLib() !void {
    var gp_alloc = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gp_alloc.allocator();

    const process_args = [_][]const u8{
        "zig",
        "build",
        "-Dhot-reload=lib_only",
        "--search-prefix",
        std.fs.cwd().realpathAlloc(allocator, "zig-out") catch unreachable,
    };
    var build_process = std.process.Child.init(&process_args, allocator);
    try build_process.spawn();

    const term = try build_process.wait();
    switch (term) {
        .Exited => |exited| {
            if (exited == 2) return error.RecompileFail;
        },
        else => return,
    }
}
