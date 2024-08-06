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
    update_boids(quad_tree)
}

update_boids :: proc(quad_tree : ^qt.Quadtree)
{
    if quad_tree.divided {
        update_boids(quad_tree.northWest)
        update_boids(quad_tree.northEast)
        update_boids(quad_tree.southWest)
        update_boids(quad_tree.southEast)
    } 
    for i in 0..< len(quad_tree.points) {
        close_boids := &[dynamic]^boid.Boid{}
        qt.query_circle(quad_tree, quad_tree.points[i].position, 50, close_boids)
        separation_force := boid.get_separation_force(close_boids^, quad_tree.points[i])
        alignment_force := boid.get_aligment_force(close_boids^, quad_tree.points[i])
        cohesion_force := boid.get_cohesion_force(close_boids^, quad_tree.points[i])
        
        quad_tree.points[i].acceleration = separation_force + alignment_force + cohesion_force
        quad_tree.points[i].velocity = quad_tree.points[i].velocity + quad_tree.points[i].acceleration
        quad_tree.points[i].position = quad_tree.points[i].position + quad_tree.points[i].velocity

        if quad_tree.points[i].position.x > quad_tree.points[i].max_width {
            quad_tree.points[i].position.x = 0
        }
        if quad_tree.points[i].position.x < 0 {
            quad_tree.points[i].position.x = quad_tree.points[i].max_width
        }
        if quad_tree.points[i].position.y > quad_tree.points[i].max_height {
            quad_tree.points[i].position.y = 0
        }
        if quad_tree.points[i].position.y < 0 {
            quad_tree.points[i].position.y = quad_tree.points[i].max_height
        }
    }
}

Draw :: proc(quad_tree : ^qt.Quadtree)
{    
    draw_quadtree(quad_tree)
}


draw_quadtree :: proc(quad_tree : ^qt.Quadtree) {
    if quad_tree.divided {
        Draw(quad_tree.northWest)
        Draw(quad_tree.northEast)
        Draw(quad_tree.southWest)
        Draw(quad_tree.southEast)
    } else {
        rl.DrawRectangleLinesEx(quad_tree.bounds, 1, rl.WHITE)
    }
    draw_boids(quad_tree)  
}

draw_boids :: proc(quad_tree : ^qt.Quadtree) {
    for point in quad_tree.points {
        rl.DrawCircleV(point.position, 2, rl.WHITE)
    }
}
