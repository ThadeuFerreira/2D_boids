package main

import rl "vendor:raylib"
import "core:math"
import "/boid"
import qt "/quadtree"



insert_boid_in_quadtree :: proc(quad_tree : ^qt.Quadtree, boid : ^boid.Boid)
{
    qt.insert(quad_tree, boid)
}

Update :: proc(quad_tree : ^qt.Quadtree, mouse_position : rl.Vector2, query_distance: f32, toggle : bool)
{
    delta_time := rl.GetFrameTime()
    update_boids(quad_tree, mouse_position, query_distance, delta_time, toggle)
}

//LerpHSV
color_hsv_lerp :: proc(color1 : rl.Color, color2 : rl.Color, t : f32) -> rl.Color
{
    t := t
    a := rl.ColorToHSV(color1)
    b := rl.ColorToHSV(color2)

    h : f32 = 0
    d := b.x - a.x
    if a.x > b.x {
        h3 := b.y
        b.x = a.x
        a.x = h3

        d = -d
        t = 1 - t
    }

    if d > 0.5 {
        a.x = a.x + 1
        h = (a.x + t*(b.x - a.x)) 
    }
    if d <= 0.5 {
        h = a.x + t*d
    }

    s := math.lerp(a.y, b.y, t)
    v := math.lerp(a.z, b.z, t)

    return rl.ColorFromHSV(h, s, v)

}

color_lerp :: proc(color1 : rl.Color, color2 : rl.Color, t : f32) -> rl.Color
{
    r1 := f32(color1.r)
    g1 := f32(color1.g)
    b1 := f32(color1.b)
    a1 := f32(color1.a)

    r2 := f32(color2.r)
    g2 := f32(color2.g)
    b2 := f32(color2.b)
    a2 := f32(color2.a)

    r := math.lerp(r1, r2, t)
    g := math.lerp(g1, g2, t)
    b := math.lerp(b1, b2, t)
    a := math.lerp(a1, a2, t)


    return rl.Color{u8(r), u8(g), u8(b), u8(a)}
}

update_boids :: proc(quad_tree : ^qt.Quadtree, mouse_position : rl.Vector2, query_distance: f32, delta_time : f32, toggle : bool)
{
    speed : f32 = 100
    if quad_tree.divided { 
        update_boids(quad_tree.northEast, mouse_position, query_distance, delta_time, toggle)
        update_boids(quad_tree.northWest, mouse_position, query_distance, delta_time, toggle)
        update_boids(quad_tree.southWest, mouse_position, query_distance, delta_time, toggle)
        update_boids(quad_tree.southEast, mouse_position, query_distance, delta_time, toggle)
    } 
    for i in 0..< len(quad_tree.entities) {
        close_boids := qt.query_circle(quad_tree, quad_tree.entities[i].position, query_distance)

        //normalize the number of close boids
        neighbors := len(close_boids)
        if neighbors > int(query_distance/2) {
            neighbors = int(query_distance/2)
        }

        //color := color_lerp(rl.GREEN, rl.RED, f32(neighbors)/20)
        color := color_hsv_lerp(rl.RED, rl.SKYBLUE, f32(neighbors)/(query_distance/2))
        quad_tree.entities[i].color = color
        
        separation_force := boid.get_separation_force(&close_boids, quad_tree.entities[i])
        alignment_force := boid.get_aligment_force(&close_boids, quad_tree.entities[i])
        cohesion_force := boid.get_cohesion_force(&close_boids, quad_tree.entities[i])
        
        quad_tree.entities[i].acceleration = separation_force + alignment_force + cohesion_force
        quad_tree.entities[i].velocity = quad_tree.entities[i].velocity + quad_tree.entities[i].acceleration
        quad_tree.entities[i].position = quad_tree.entities[i].position + quad_tree.entities[i].velocity * delta_time*speed

        if quad_tree.entities[i].position.x > quad_tree.entities[i].max_width {
            quad_tree.entities[i].position.x = 0
        }
        if quad_tree.entities[i].position.x < 0 {
            quad_tree.entities[i].position.x = quad_tree.entities[i].max_width -1
        }
        if quad_tree.entities[i].position.y > quad_tree.entities[i].max_height {
            quad_tree.entities[i].position.y = 0
        }
        if quad_tree.entities[i].position.y < 0 {
            quad_tree.entities[i].position.y = quad_tree.entities[i].max_height -1
        }
        delete(close_boids)
    }

    if toggle {
        query_circle := qt.query_circle(quad_tree, mouse_position, query_distance)
        for b in query_circle {
            b.color = rl.YELLOW
        }

        delete (query_circle)
    }
    
}

Draw :: proc(quad_tree : ^qt.Quadtree, toggle : bool)
{    
    draw_quadtree(quad_tree, toggle)
}


draw_quadtree :: proc(quad_tree : ^qt.Quadtree, toggle : bool) {
    if quad_tree.divided {
        draw_quadtree(quad_tree.northWest, toggle)
        draw_quadtree(quad_tree.northEast, toggle)
        draw_quadtree(quad_tree.southWest, toggle)
        draw_quadtree(quad_tree.southEast, toggle)
    } else if toggle {
        rl.DrawRectangleLinesEx(quad_tree.bounds, 1, rl.WHITE)
    }
    draw_boids(quad_tree)  
}

draw_boids :: proc(quad_tree : ^qt.Quadtree) {
    for entity in quad_tree.entities {
        boid.Draw_boid(entity)
    }
}
