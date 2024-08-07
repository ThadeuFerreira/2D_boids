package main

import rl "vendor:raylib"
import "/boid"
import qt "/quadtree"



insert_boid_in_quadtree :: proc(quad_tree : ^qt.Quadtree, boid : ^boid.Boid)
{
    qt.insert(quad_tree, boid)
}

Update :: proc(quad_tree : ^qt.Quadtree)
{
    delta_time := rl.GetFrameTime()
    update_boids(quad_tree, delta_time)
}

update_boids :: proc(quad_tree : ^qt.Quadtree, delta_time : f32)
{
    speed : f32 = 100
    if quad_tree.divided { 
        update_boids(quad_tree.northWest, delta_time)
        update_boids(quad_tree.northEast, delta_time)
        update_boids(quad_tree.southWest, delta_time)
        update_boids(quad_tree.southEast, delta_time)
    } 
    for i in 0..< len(quad_tree.entities) {
        close_boids := qt.query_circle(quad_tree, quad_tree.entities[i].position, 50)
        
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
        rl.DrawCircleV(entity.position, 2, rl.WHITE)
    }
}
