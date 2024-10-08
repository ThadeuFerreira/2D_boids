package main

import rl "vendor:raylib"
import "core:math"
import "core:mem"
import "core:math/rand"
import "core:fmt"
import "core:strings"
import "/boid"
import qt "/quadtree"


screen_width : i32 = 2000
screen_height : i32 = 2000
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

    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    temp_track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&temp_track, context.temp_allocator)
    context.temp_allocator = mem.tracking_allocator(&temp_track)

    defer {
        if len(temp_track.allocation_map) > 0 {
            fmt.eprintf("=== %v allocations not freed: ===\n", len(temp_track.allocation_map))
            for _, entry in temp_track.allocation_map {
                fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
            }
        }
        if len(temp_track.bad_free_array) > 0 {
            fmt.eprintf("=== %v incorrect frees: ===\n", len(temp_track.bad_free_array))
            for entry in temp_track.bad_free_array {
                fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
            }
        }
        mem.tracking_allocator_destroy(&temp_track)

        if len(track.allocation_map) > 0 {
            fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
            for _, entry in track.allocation_map {
                fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
            }
        }
        if len(track.bad_free_array) > 0 {
            fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
            for entry in track.bad_free_array {
                fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
            }
        }
        mem.tracking_allocator_destroy(&track)
    }

    rl.SetConfigFlags(rl.ConfigFlags{rl.ConfigFlag.WINDOW_TRANSPARENT});

    rl.InitWindow(screen_width, screen_height, "Boids - basic window");
    rl.HideCursor()
    toggle := false
    query_distance : f32 = 100
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
        if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
            toggle = !toggle
        }
        
        mouse_pos := rl.GetMousePosition()
        if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
            for i in 0..<100 {
                mouse_pos.x += rand.float32()*10 - 5
                mouse_pos.y += rand.float32()*10 - 5
                b := boid.Make_boid(mouse_pos, 0.1, 2, f32(screen_width), f32(screen_height), rl.WHITE)
                insert_boid_in_quadtree(quad_tree, b)
            }
        }

        st_mouse_pos :=  rl.TextFormat( "%v, %v", mouse_pos.x ,mouse_pos.y)
        rl.DrawText(st_mouse_pos, i32(mouse_pos.x), i32(mouse_pos.y), 20, rl.WHITE)
        
       
        query_distance += rl.GetMouseWheelMove()*10
        query_distance = math.clamp(query_distance, 0, 1000)
        
        Update(quad_tree, mouse_pos, query_distance, toggle)
        rl.DrawCircleLines(i32(mouse_pos.x), i32(mouse_pos.y), query_distance, rl.YELLOW)
        

        Draw(quad_tree, toggle)           
        
        fps := rl.GetFPS()
        rl.DrawText(rl.TextFormat("FPS: %v", fps), 10, 30, 20, rl.RED)
        boids := qt.Get_all_boids(quad_tree)
        
        qt.clear_quadtree(quad_tree)
        free(quad_tree)
        quad_tree = qt.Make_quadtree(rl.Rectangle{0, 0, f32(screen_width), f32(screen_height)}, 10, 0)
        for i in 0..<len(boids) {
            insert_boid_in_quadtree(quad_tree, boids[i])
        }
        rl.DrawText(rl.TextFormat("Total Boids: %v", len(boids)), 10, 50, 20, rl.RED)
        rl.EndDrawing()
        delete(boids)
        free_all(context.temp_allocator)
    }
    delete_boids :: proc(qt : ^qt.Quadtree) {
        if qt.divided {
            delete_boids(qt.northWest)
            delete_boids(qt.northEast)
            delete_boids(qt.southWest)
            delete_boids(qt.southEast)
        } else {
            for i in 0..<len(qt.entities) {
                free(qt.entities[i])
            }
        }
    }
    delete_boids(quad_tree)
    qt.clear_quadtree(quad_tree)
    free(quad_tree)

    rl.CloseWindow()
}