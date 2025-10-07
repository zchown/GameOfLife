const std = @import("std");
const rl = @import("raylib");
const gr = @import("gameRenderer.zig");

pub fn main() void {
    const screenWidth = 800;
    const screenHeight = 800;

    var renderer = gr.Renderer.new();
    renderer.init(std.heap.page_allocator, 50, 50, screenWidth, screenHeight) catch {
        std.debug.print("Failed to initialize renderer\n", .{});
        return;
    };
    defer renderer.deinit();

    rl.initWindow(screenWidth, screenHeight, "Conway's Game of Life");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var timeAccumulator: f64 = 0.0;

    while (!rl.windowShouldClose()) {
        if (rl.isKeyPressed(rl.KeyboardKey.space)) {
            renderer.game_state.randomize();
        }

        timeAccumulator += rl.getFrameTime();
        if (timeAccumulator >= 0.5) {
            renderer.update();
            timeAccumulator = 0.0;
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.colorFromHSV(100, 0.0, 0.0));


        if (rl.getTime() < 5.0) {
            welcomeMessage();
        }
        renderer.draw();
    }
}

pub fn welcomeMessage() void {
    const baseColor = rl.colorFromHSV(100, 1.0, 0.1);
            const newColor = rl.colorAlpha(baseColor, @floatCast(1.0 - (rl.getTime() / 5.0)));
            rl.drawText("Welcome to Conway's Game of Life!", 190, 200, 20, newColor);

}
