package main

import rl "vendor:raylib"


RAYGUI_WINDOWBOX_STATUSBAR_HEIGHT : i32 = 24
RAYGUI_WINDOW_CLOSEBUTTON_SIZE : i32 = 18
// GuiWindowFloating - Window with title bar and close button

Floating_Window :: struct {
    position : rl.Vector2,
    size : rl.Vector2,
    minimized : bool,
    moving : bool,
    resizing : bool,
    draw_content : proc(rl.Vector2, rl.Vector2),
    content_size : rl.Vector2,
    scroll : rl.Vector2,
    title : cstring,
}

GuiWindowFloating :: proc(fw : ^Floating_Window)
{
    position := &fw.position
    size := &fw.size
    minimized := &fw.minimized
    moving := &fw.moving
    resizing := &fw.resizing
    draw_content := fw.draw_content
    content_size := &fw.content_size
    scroll := &fw.scroll
    title := fw.title
    
    close_title_size_delta_half := (RAYGUI_WINDOWBOX_STATUSBAR_HEIGHT - RAYGUI_WINDOW_CLOSEBUTTON_SIZE) / 2

    if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) && !moving^ && !resizing^ {
        mouse_position := rl.GetMousePosition()

        title_collision_rect := rl.Rectangle{ position.x, position.y, size.x - f32(RAYGUI_WINDOW_CLOSEBUTTON_SIZE + close_title_size_delta_half), f32(RAYGUI_WINDOWBOX_STATUSBAR_HEIGHT) }
        resize_collision_rect := rl.Rectangle{ position.x + size.x - 20, position.y + size.y - 20, 20, 20 }

        if rl.CheckCollisionPointRec(mouse_position, title_collision_rect) {
            moving^ = true
        } else if !minimized^ && rl.CheckCollisionPointRec(mouse_position, resize_collision_rect) {
            resizing^ = true
        }
    }

    if moving^ {
        mouse_delta := rl.GetMouseDelta()
        position.x += mouse_delta.x
        position.y += mouse_delta.y

        if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
            moving^ = false

            if position.x < 0 {
                position.x = 0
            } else if position.x > f32(rl.GetScreenWidth()) - size.x {
                position.x = f32(rl.GetScreenWidth()) - size.x
            }
            if position.y < 0 {
                position.y = 0
            } else if position.y > f32(rl.GetScreenHeight()) {
                position.y = f32(rl.GetScreenHeight() - RAYGUI_WINDOWBOX_STATUSBAR_HEIGHT)
            }
        }

    } else if resizing^ {
        mouse := rl.GetMousePosition()
        if mouse.x > position.x {
            size.x = mouse.x - position.x
        }
        if mouse.y > position.y {
            size.y = mouse.y - position.y
        }

        if size.x < 100 {
            size.x = 100
        } else if size.x > f32(rl.GetScreenWidth()) {
            size.x = f32(rl.GetScreenWidth())
        }
        if size.y < 100 {
            size.y = 100
        } else if size.y > f32(rl.GetScreenHeight()) {
            size.y = f32(rl.GetScreenHeight())
        }

        if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
            resizing^ = false
        }
    }

    if minimized^{
        rl.GuiStatusBar(rl.Rectangle{ position.x, position.y, size.x, f32(RAYGUI_WINDOWBOX_STATUSBAR_HEIGHT) }, title)

        if rl.GuiButton(rl.Rectangle{ position.x + size.x - f32(RAYGUI_WINDOW_CLOSEBUTTON_SIZE + close_title_size_delta_half),
                                   position.y + f32(close_title_size_delta_half),
                                   f32(RAYGUI_WINDOW_CLOSEBUTTON_SIZE),
                                   f32(RAYGUI_WINDOW_CLOSEBUTTON_SIZE) },
                                   "#120#") {
            minimized^ = false
        }
    } else {
        minimized^ = rl.GuiWindowBox(rl.Rectangle{ position.x, position.y, size.x, size.y }, title) == 1

        if draw_content != nil {
            scissor := rl.Rectangle{}
            rl.GuiScrollPanel(rl.Rectangle{ position.x, position.y + f32(RAYGUI_WINDOWBOX_STATUSBAR_HEIGHT), size.x, size.y - f32(RAYGUI_WINDOWBOX_STATUSBAR_HEIGHT) },
                                         nil,
                                         rl.Rectangle{ position.x, position.y, content_size.x, content_size.y },
                                         scroll,
                                         &scissor)

            require_scissor := size.x < content_size.x || size.y < content_size.y

            if require_scissor {
                rl.BeginScissorMode(i32(scissor.x), i32(scissor.y), i32(scissor.width), i32(scissor.height))
            }

            draw_content(position^, scroll^)

            if require_scissor {
                rl.EndScissorMode()
            }
        }
        rl.GuiDrawIcon(rl.GuiIconName.ICON_FOLDER_FILE_OPEN, i32(position.x + size.x - 20), i32(position.y + size.y - 20), 1, rl.WHITE)
    }
}

DrawContent :: proc(position : rl.Vector2, scroll : rl.Vector2)
{
    rl.GuiButton(rl.Rectangle{ position.x + 20 + scroll.x, position.y + 50  + scroll.y, 100, 25 }, "Button 1")
    rl.GuiButton(rl.Rectangle{ position.x + 20 + scroll.x, position.y + 100 + scroll.y, 100, 25 }, "Button 2")
    rl.GuiButton(rl.Rectangle{ position.x + 20 + scroll.x, position.y + 150 + scroll.y, 100, 25 }, "Button 3")
    rl.GuiLabel(rl.Rectangle{ position.x + 20 + scroll.x, position.y + 200 + scroll.y, 250, 25 }, "A Label")
    rl.GuiLabel(rl.Rectangle{ position.x + 20 + scroll.x, position.y + 250 + scroll.y, 250, 25 }, "Another Label")
    rl.GuiLabel(rl.Rectangle{ position.x + 20 + scroll.x, position.y + 300 + scroll.y, 250, 25 }, "Yet Another Label")
}
