const rl = @import("raylib");

pub fn main() void {
    const screenWidth = 800;
    const screenHeight = 500;

    rl.initWindow(screenWidth, screenHeight, "Conway's Game of Life");
    defer rl.closeWindow();

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        rl.clearBackground(rl.colorFromHSV(210, 0.5, 0.9));
        rl.drawText("Welcome to Conway's Game of Life!", 190, 200, 20, rl.colorFromHSV(100, 0.9, 0.1));
        rl.endDrawing();
    }
}

