const std = @import("std");
const rl = @import("raylib");
// const gr = @import("gameRenderer.zig");

pub fn main() !void {
    const screenWidth = 1000;
    const screenHeight = 1000;

    rl.initWindow(screenWidth, screenHeight, "Conway's Game of Life");
    defer rl.closeWindow();

    // rl.setTargetFPS(60);

    const gridWidth = 4096 * 4;
    const gridHeight = 4096 * 4;

    var rtA = try rl.loadRenderTexture(gridWidth, gridHeight);
    var rtB = try rl.loadRenderTexture(gridWidth, gridHeight);
    defer rl.unloadRenderTexture(rtA);
    defer rl.unloadRenderTexture(rtB);

    rl.setTextureFilter(rtA.texture, rl.TextureFilter.point);
    rl.setTextureFilter(rtB.texture, rl.TextureFilter.point);

    const vsPath = "src/vertex.vs";
    const fsPath = "src/frag.fs";

    const shader = try rl.loadShader(vsPath, fsPath);
    defer rl.unloadShader(shader);
    if (shader.id == 0) {
        std.debug.print("Shader failed to load!\n", .{});
    }

    const locPrevState = rl.getShaderLocation(shader, "prevState");
    const locTexelSize = rl.getShaderLocation(shader, "texelSize");

    var image = rl.genImageColor(gridWidth, gridHeight, rl.Color.black);
    var random = @as(u64, @intCast(std.time.milliTimestamp()));

    const numAcorns = @divFloor(gridWidth, 25);
    for (0..numAcorns) |_| {
        random = splitMix64(random);
        const x: i32 = @intCast((random % (gridWidth - 100)) + 50);
        random = splitMix64(random);
        const y: i32 = @intCast((random % (gridHeight - 100)) + 50);

        drawAcorn(&image, x, y);
    }

    // save image to file for debugging
    _ = rl.exportImage(image, "initial_state.png");

    const texture = try rl.loadTextureFromImage(image);
    defer rl.unloadTexture(texture);
    rl.unloadImage(image);

    rl.beginTextureMode(rtA);
    rl.clearBackground(rl.Color.black);
    rl.drawTexture(texture, 0, 0, rl.Color.white);
    rl.endTextureMode();

    var cur = &rtA;
    var next = &rtB;

    const gridCenterX = @as(f32, @floatFromInt(gridWidth)) / 2.0;
    const gridCenterY = @as(f32, @floatFromInt(gridHeight)) / 2.0;
    const screenCenterX = @as(f32, @floatFromInt(screenWidth)) / 2.0;
    const screenCenterY = @as(f32, @floatFromInt(screenHeight)) / 2.0;

    var camera = rl.Camera2D{
        .offset = rl.Vector2{ .x = screenCenterX - gridCenterX * 0.5, .y = screenCenterY - gridCenterY * 0.5 },
        .target = rl.Vector2{ .x = 0, .y = 0 },
        .rotation = 0.0,
        .zoom = 0.5,
    };

    var isDragging = false;
    var lastMousePos = rl.Vector2{ .x = 0, .y = 0 };
    const zoomIncrement: f32 = 0.125;

    while (!rl.windowShouldClose()) {
        const mousePos = rl.getMousePosition();
        const mouseWheel = rl.getMouseWheelMove();

        if (mouseWheel != 0) {
            const oldZoom = camera.zoom;
            camera.zoom += mouseWheel * zoomIncrement;
            camera.zoom = if (camera.zoom < 0.1) 0.1 else if (camera.zoom > 5.0) 5.0 else camera.zoom;

            // Zoom towards mouse position
            const zoomRatio = camera.zoom / oldZoom;
            camera.offset.x = mousePos.x - (mousePos.x - camera.offset.x) * zoomRatio;
            camera.offset.y = mousePos.y - (mousePos.y - camera.offset.y) * zoomRatio;
        }

        if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
            // std.debug.print("Mouse pressed at: ({}, {})\n", .{mousePos.x, mousePos.y});
            isDragging = true;
            lastMousePos = mousePos;
        } else if (rl.isMouseButtonReleased(rl.MouseButton.left)) {
            // std.debug.print("Mouse released at: ({}, {})\n", .{mousePos.x, mousePos.y});
            isDragging = false;
        }

        if (isDragging) {
            const delta = rl.Vector2{
                .x = mousePos.x - lastMousePos.x,
                .y = mousePos.y - lastMousePos.y,
            };
            camera.offset.x += delta.x;
            camera.offset.y += delta.y;
            lastMousePos = mousePos;
        }

        if (rl.isMouseButtonDown(rl.MouseButton.right)) {
            const worldX = (mousePos.x - camera.offset.x) / camera.zoom;
            const worldY = (mousePos.y - camera.offset.y) / camera.zoom;

            if (worldX >= 0 and worldX < gridWidth and worldY >= 0 and worldY < gridHeight) {
                rl.beginTextureMode(cur.*);

                const blockX: i32 = @intFromFloat(worldX);
                const blockY: i32 = @intFromFloat(worldY);

                rl.drawRectangle(blockX - 10, blockY - 10, 20, 20, rl.Color.white);

                rl.endTextureMode();
            }
        }

        const texelSize = [_]f32{ 1.0 / @as(f32, gridWidth), 1.0 / @as(f32, gridHeight) };
        rl.beginTextureMode(next.*);
        rl.clearBackground(rl.Color.black);

        rl.beginShaderMode(shader);
        rl.setShaderValueTexture(shader, locPrevState, cur.*.texture);
        rl.setShaderValue(shader, locTexelSize, &texelSize, rl.ShaderUniformDataType.vec2);

        rl.drawTextureRec(
            cur.*.texture,
            rl.Rectangle{ .x = 0, .y = 0, .width = @as(f32, @floatFromInt(cur.*.texture.width)), .height = -@as(f32, @floatFromInt(cur.*.texture.height)) },
            rl.Vector2{ .x = 0, .y = 0 },
            rl.Color.white,
        );

        rl.endShaderMode();
        rl.endTextureMode();

        const tmp = cur;
        cur = next;
        next = tmp;

        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);
        const destRect = rl.Rectangle{
            .x = camera.offset.x,
            .y = camera.offset.y,
            .width = @as(f32, @floatFromInt(gridWidth)) * camera.zoom,
            .height = @as(f32, @floatFromInt(gridHeight)) * camera.zoom,
        };

        const sourceRect = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @as(f32, @floatFromInt(cur.*.texture.width)),
            .height = -@as(f32, @floatFromInt(cur.*.texture.height)),
        };

        rl.drawTexturePro(
            cur.*.texture,
            sourceRect,
            destRect,
            rl.Vector2{ .x = 0, .y = 0 },
            0.0,
            rl.Color.white,
        );
        rl.drawFPS(10, 10);
        defer rl.endDrawing();
    }
}

fn splitMix64(x: u64) u64 {
    var y = (x ^ (x >> 30)) *% 0xbf58476d1ce4e5b9;
    y = (y ^ (y >> 27)) *% 0x94d049bb133111eb;
    return y ^ (y >> 31);
}

fn drawAcorn(image: *rl.Image, x: i32, y: i32) void {
    const pattern = [_][2]i32{
        .{ 1, 0 },
        .{ 3, 1 },
        .{ 0, 2 },
        .{ 1, 2 },
        .{ 4, 2 },
        .{ 5, 2 },
        .{ 6, 2 },
    };

    for (pattern) |pos| {
        const px = x + pos[0];
        const py = y + pos[1];
        if (px >= 0 and px < image.width and py >= 0 and py < image.height) {
            rl.imageDrawPixel(image, px, py, rl.Color.white);
        }
    }
}
