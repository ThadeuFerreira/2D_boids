package boid


import rl "vendor:raylib"
import "core:math"
import "core:math/rand"

Boid :: struct {
    position : rl.Vector2,
    velocity : rl.Vector2,
    acceleration : rl.Vector2,
    max_force : f32,
    max_speed : f32,
    color : rl.Color,

    max_width : f32,
    max_height : f32
}

Make_boid :: proc(position : rl.Vector2, max_force : f32, max_speed : f32,max_width, max_height : f32, color : rl.Color) -> ^Boid
{
    boid := new(Boid)
    boid.position = position
    boid.velocity = rl.Vector2{rand.float32() * 2 - 1, rand.float32() * 2 - 1}*max_speed
    boid.acceleration = rl.Vector2{0, 0}
    boid.max_force = max_force
    boid.max_speed = max_speed
    boid.color = color

    boid.max_width = max_width
    boid.max_height = max_height
    return boid
}

Update :: proc(boids : ^[dynamic]^Boid, b : ^Boid)
{
 
    b.acceleration = get_forces(boids, b)
    b.velocity = b.velocity + b.acceleration

    // speed := rl.Vector2Length(b.velocity)
    // if speed > b.max_speed {
    //     b.velocity = rl.Vector2Normalize(b.velocity)*b.max_speed
    // }


    b.position = b.position + b.velocity
    
    if b.position.x > b.max_width {
        b.position.x = 0
    }
    if b.position.x < 0 {
        b.position.x = b.max_width
    }
    if b.position.y > b.max_height {
        b.position.y = 0
    }
    if b.position.y < 0 {
        b.position.y = b.max_height
    }
}

get_forces :: proc(boids : ^[dynamic]^Boid, b : ^Boid) -> rl.Vector2
{
    alignment := get_aligment_force(boids,b)
    cohesion := get_cohesion_force(boids,b)
    separation := get_separation_force(boids,b)
    r := rl.Vector2{rand.float32()*2 -1, rand.float32()*2 -1}*0.2
    r += alignment
    r += cohesion
    r += separation*1.5
    return r
    
}

get_aligment_force :: proc(boids : ^[dynamic]^Boid, b : ^Boid) -> rl.Vector2
{
    perception_radius : f32 = 200
    steering_force := rl.Vector2{0, 0}
    total := 0
    for i in 0..<len(boids) {
        if boids[i] == b {
            continue
        }

        distance := rl.Vector2Distance(boids[i].position, b.position)
        if distance < perception_radius {
            steering_force = steering_force + boids[i].velocity
            total += 1
        }
    }
    if total > 0 {
        steering_force = steering_force / f32(total)
        steering_force = rl.Vector2Normalize(steering_force)*b.max_speed
        steering_force = steering_force - b.velocity
        steering_force = rl.Vector2Normalize(steering_force)*b.max_force
    }
    return steering_force
}

get_cohesion_force :: proc(boids : ^[dynamic]^Boid, b : ^Boid) -> rl.Vector2
{
    perception_radius : f32 = 200
    steering_force := rl.Vector2{0, 0}
    total := 0
    for i in 0..<len(boids) {
        if boids[i].position == b.position {
            continue
        }

        distance := rl.Vector2Distance(boids[i].position, b.position)
        if distance < perception_radius {
            steering_force = steering_force + boids[i].position
            total += 1
        }
    }
    if total > 0 {
        steering_force = steering_force / f32(total)
        steering_force = steering_force - b.position
        steering_force = rl.Vector2Normalize(steering_force)*b.max_speed
        steering_force = steering_force - b.velocity
        steering_force = rl.Vector2Normalize(steering_force)*b.max_force
    }
    return steering_force
}

get_separation_force :: proc(boids : ^[dynamic]^Boid, b : ^Boid) -> rl.Vector2
{
    perception_radius : f32 = 50
    steering_force := rl.Vector2{0, 0}
    total := 0
    for i in 0..<len(boids) {
        if boids[i] == b {
            continue
        }

        distance := rl.Vector2Distance(boids[i].position, b.position)
        if distance < perception_radius {
            diff := b.position - boids[i].position
            diff = rl.Vector2Normalize(diff)
            diff = diff / distance
            steering_force = steering_force + diff
            total += 1
        }
    }
    if total > 0 {
        steering_force = steering_force / f32(total)
        steering_force = rl.Vector2Normalize(steering_force)*b.max_speed
        steering_force = steering_force - b.velocity
        steering_force = rl.Vector2Normalize(steering_force)*b.max_force
    }
    return steering_force
}

Draw_boids :: proc(boids : [dynamic]^Boid)
{
    for i in 0..<len(boids) {
        Draw_boid(boids[i])
    }
}

Draw_boid :: proc(boid : ^Boid)
{
    rl.DrawCircleV(boid.position, 5, boid.color)
}
