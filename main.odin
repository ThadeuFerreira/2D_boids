package main

import rl "vendor:raylib"
import "core:math"
import "core:math/rand"
import "core:fmt"
import "core:strings"
import "/boid"
import qt "/quadtree"


screen_width : i32 = 1400
screen_height : i32 = 1000
play_width : f32 = 1000
score_width : f32 = f32(screen_width) - play_width

SHIP_SIZE : i32 = 30

BRUSH_SHAPE :: enum {
    SQUARE,
    CIRCLE
}

main :: proc()
{
    // Initialization
    //--------------------------------------------------------------------------------------

    rl.SetConfigFlags(rl.ConfigFlags{rl.ConfigFlag.WINDOW_TRANSPARENT});

    rl.InitWindow(screen_width, screen_height, "Boids - basic window");
    rl.HideCursor()
        
    //boids := make([dynamic]^boid.Boid, 0, 100) 
    quad_tree := qt.Make_quadtree(rl.Rectangle{0, 0, f32(screen_width), f32(screen_height)}, 10, 0)
    rl.SetTargetFPS(120) // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------
    rl.SetTraceLogLevel(rl.TraceLogLevel.ALL) // Show trace log messages (LOG_INFO, LOG_WARNING, LOG_ERROR, LOG_DEBUG)
    // Main game loop
    for !rl.WindowShouldClose()    // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        
        mouse_pos := rl.GetMousePosition()
        if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
            for i in 0..<100 {
                mouse_pos.x += rand.float32()*10 - 5
                mouse_pos.y += rand.float32()*10 - 5
                b := boid.Make_boid(mouse_pos, 0.1, 2, f32(screen_width), f32(screen_height), rl.WHITE)
                insert_boid_in_quadtree(quad_tree, b)
            }
        }

        st_mouse_pos :=  fmt.tprintf( "%v, %v", mouse_pos.x ,mouse_pos.y)
        rl.DrawText(strings.clone_to_cstring(st_mouse_pos), i32(mouse_pos.x), i32(mouse_pos.y), 20, rl.WHITE)

        average_speed : f32= 0

        Update(quad_tree)

        
        // for i in 0..<len(boids) {
        //     velocity := boids[i].velocity
        //     speed := rl.Vector2Length(velocity)  
        //     if math.is_nan_f32(speed) {
        //         speed = 0
        //     }
        //     average_speed += speed
        // }
        // average_speed /= f32(len(boids))

        Draw(quad_tree)           
        rl.DrawText(strings.clone_to_cstring(fmt.tprintf("Average speed: %v", average_speed)), 10, 10, 20, rl.RED)
        fps := rl.GetFPS()
        rl.DrawText(strings.clone_to_cstring(fmt.tprintf("FPS: %v", fps)), 10, 30, 20, rl.RED)
        boids := &[dynamic]^boid.Boid{}
        qt.Get_all_boids(quad_tree, boids)
        free(quad_tree)
        quad_tree = qt.Make_quadtree(rl.Rectangle{0, 0, f32(screen_width), f32(screen_height)}, 10, 0)
        for i in 0..<len(boids) {
            insert_boid_in_quadtree(quad_tree, boids[i])
        }
        rl.DrawText(strings.clone_to_cstring(fmt.tprintf("Total Boids: %v", len(boids))), 10, 50, 20, rl.RED)
        rl.EndDrawing()
    }

    rl.CloseWindow()
}