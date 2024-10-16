const std = @import("std");
const rl = @import("raylib");
const game = @import("game.zig");

const GameStatePtr = *anyopaque;

pub fn main() !void {
    const game_state = game.init();
    while (!rl.windowShouldClose()) {
        if (rl.isKeyPressed(.key_f5)) {
            game.reload(game_state);
        }
        game.update(game_state);
        rl.beginDrawing();
        game.draw(game_state);
        rl.endDrawing();
    }
    rl.closeWindow();
}
