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
    boid.velocity = rl.Vector2{rand.float32() * 2 - 1, rand.float32() * 2 - 1}*10
    boid.acceleration = rl.Vector2{0, 0}
    boid.max_force = max_force
    boid.max_speed = max_speed
    boid.color = color

    boid.max_width = max_width
    boid.max_height = max_height
    return boid
}

Update :: proc(boids : [dynamic]^Boid, index : int)
{
 
    boids[index].acceleration = get_forces(boids, index)
    boids[index].velocity = boids[index].velocity + boids[index].acceleration

    // speed := rl.Vector2Length(boids[index].velocity)
    // if speed > boids[index].max_speed {
    //     boids[index].velocity = rl.Vector2Normalize(boids[index].velocity)*boids[index].max_speed
    // }


    boids[index].position = boids[index].position + boids[index].velocity
    
    if boids[index].position.x > boids[index].max_width {
        boids[index].position.x = 0
    }
    if boids[index].position.x < 0 {
        boids[index].position.x = boids[index].max_width
    }
    if boids[index].position.y > boids[index].max_height {
        boids[index].position.y = 0
    }
    if boids[index].position.y < 0 {
        boids[index].position.y = boids[index].max_height
    }
}

get_forces :: proc(boids : [dynamic]^Boid, index: int) -> rl.Vector2
{

    alignment := get_aligment_force(boids , index)
    cohesion := get_cohesion_force(boids, index)
    separation := get_separation_force(boids, index)
    r := rl.Vector2{rand.float32()*2 -1, rand.float32()*2 -1}*0.2
    r += alignment
    r += cohesion
    r += separation*1.5
    return r
    
}

get_aligment_force :: proc(boids : [dynamic]^Boid, index :int) -> rl.Vector2
{
    perception_radius : f32 = 200
    steering_force := rl.Vector2{0, 0}
    total := 0
    for i in 0..<len(boids) {
        if i == index {
            continue
        }

        distance := rl.Vector2Distance(boids[i].position, boids[index].position)
        if distance < perception_radius {
            steering_force = steering_force + boids[i].velocity
            total += 1
        }
    }
    if total > 0 {
        steering_force = steering_force / f32(total)
        steering_force = rl.Vector2Normalize(steering_force)*boids[index].max_speed
        steering_force = steering_force - boids[index].velocity
        steering_force = rl.Vector2Normalize(steering_force)*boids[index].max_force
    }
    return steering_force
}

get_cohesion_force :: proc(boids : [dynamic]^Boid, index :int) -> rl.Vector2
{
    perception_radius : f32 = 200
    steering_force := rl.Vector2{0, 0}
    total := 0
    for i in 0..<len(boids) {
        if i == index {
            continue
        }

        distance := rl.Vector2Distance(boids[i].position, boids[index].position)
        if distance < perception_radius {
            steering_force = steering_force + boids[i].position
            total += 1
        }
    }
    if total > 0 {
        steering_force = steering_force / f32(total)
        steering_force = steering_force - boids[index].position
        steering_force = rl.Vector2Normalize(steering_force)*boids[index].max_speed
        steering_force = steering_force - boids[index].velocity
        steering_force = rl.Vector2Normalize(steering_force)*boids[index].max_force
    }
    return steering_force
}

get_separation_force :: proc(boids : [dynamic]^Boid, index :int) -> rl.Vector2
{
    perception_radius : f32 = 50
    steering_force := rl.Vector2{0, 0}
    total := 0
    for i in 0..<len(boids) {
        if i == index {
            continue
        }

        distance := rl.Vector2Distance(boids[i].position, boids[index].position)
        if distance < perception_radius {
            diff := boids[index].position - boids[i].position
            diff = rl.Vector2Normalize(diff)
            diff = diff / distance
            steering_force = steering_force + diff
            total += 1
        }
    }
    if total > 0 {
        steering_force = steering_force / f32(total)
        steering_force = rl.Vector2Normalize(steering_force)*boids[index].max_speed
        steering_force = steering_force - boids[index].velocity
        steering_force = rl.Vector2Normalize(steering_force)*boids[index].max_force
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
