package quadtree

import rl "vendor:raylib"
import "../boid"

DEFAULT_CAPACITY :: 8
MAX_DEPTH :: 5

Quadtree :: struct {
    bounds : rl.Rectangle,
    capacity: int,
    entities: [dynamic]^boid.Boid,
    divided: bool,
    depth: int,
    total_points: int,
    northWest: ^Quadtree,
    northEast: ^Quadtree,
    southWest: ^Quadtree,
    southEast: ^Quadtree,
}

  // Basic shapes collision detection functions
//   bool CheckCollisionRecs(Rectangle rec1, Rectangle rec2);                                           // Check collision between two rectangles
//   bool CheckCollisionCircles(Vector2 center1, float radius1, Vector2 center2, float radius2);        // Check collision between two circles
//   bool CheckCollisionCircleRec(Vector2 center, float radius, Rectangle rec);                         // Check collision between circle and rectangle
//   bool CheckCollisionPointRec(Vector2 point, Rectangle rec);                                         // Check if point is inside rectangle
//   bool CheckCollisionPointCircle(Vector2 point, Vector2 center, float radius);                       // Check if point is inside circle
//   bool CheckCollisionPointTriangle(Vector2 point, Vector2 p1, Vector2 p2, Vector2 p3);               // Check if point is inside a triangle
//   bool CheckCollisionPointPoly(Vector2 point, Vector2 *points, int pointCount);                      // Check if point is within a polygon described by array of vertices
//   bool CheckCollisionLines(Vector2 startPos1, Vector2 endPos1, Vector2 startPos2, Vector2 endPos2, Vector2 *collisionPoint); // Check the collision between two lines defined by two points each, returns collision point by reference
//   bool CheckCollisionPointLine(Vector2 point, Vector2 p1, Vector2 p2, int threshold);                // Check if point belongs to line created between two points [p1] and [p2] with defined margin in pixels [threshold]
//   Rectangle GetCollisionRec(Rectangle rec1, Rectangle rec2);                                         // Get collision rectangle for two rectangles collision

Make_quadtree :: proc(bounds: rl.Rectangle, capacity: int = DEFAULT_CAPACITY, depth: int = 0) -> ^Quadtree {

    qt := new(Quadtree)
    qt.bounds = bounds
    qt.capacity = capacity
    qt.entities = make([dynamic]^boid.Boid, 0, capacity)
    qt.divided = false
    qt.depth = depth

    return qt
}

get_children :: proc(qt : ^Quadtree) -> [4]^Quadtree {
    if qt.divided {
        return [4]^Quadtree{qt.northWest, qt.northEast, qt.southWest, qt.southEast}
    }
    return [4]^Quadtree{nil, nil, nil, nil}
}

insert :: proc(qt : ^Quadtree, entity : ^boid.Boid) -> bool {
    if !rl.CheckCollisionPointRec(entity.position, qt.bounds) {
        return false
    }

    if !qt.divided{
        if len(qt.entities) < qt.capacity || qt.depth >= MAX_DEPTH {
            append(&qt.entities, entity)
            return true
        }
        subdivide(qt)
    }

    if insert(qt.northWest, entity) || insert(qt.northEast, entity) || insert(qt.southWest, entity) || insert(qt.southEast, entity){
        qt.total_points += 1
        return true
    }
    return false
}

delete_point :: proc(qt : ^Quadtree, entity : boid.Boid) -> bool {
    if !rl.CheckCollisionPointRec(entity.position, qt.bounds) {
        return false
    }

    if qt.divided {
        if delete_point(qt.northWest, entity) || delete_point(qt.northEast, entity) || delete_point(qt.southWest, entity) || delete_point(qt.southEast, entity){
            rebalance(qt)
            qt.total_points -= 1
            return true
        }
    }

    for i in 0..< len(qt.entities) {
        if qt.entities[i].position == entity.position {
            ordered_remove(&qt.entities, i)
            qt.total_points -= 1
            return true
        }
    }
    return false
}

query :: proc(qt : ^Quadtree, range : rl.Rectangle, found : ^[dynamic]^boid.Boid)  {
    if !rl.CheckCollisionRecs(qt.bounds, range) {
        return 
    }

    if qt.divided {
        query(qt.northWest, range, found)
        query(qt.northEast, range, found)
        query(qt.southWest, range, found)
        query(qt.southEast, range, found)
        return 
    } 

    for entity in qt.entities {
        if rl.CheckCollisionPointRec(entity.position, range) {
            append(found, entity)
        }
    }
    return 
}

query_circle :: proc(qt: ^Quadtree, center: rl.Vector2, radius: f32) -> [dynamic]^boid.Boid {
    found := [dynamic]^boid.Boid{}
    query_circle_impl(qt, center, radius, &found)
    return found
}

query_circle_impl :: proc(qt : ^Quadtree, center : rl.Vector2, radius : f32, found : ^[dynamic]^boid.Boid) {
    //CheckCollisionCircleRec(Vector2 center, float radius, Rectangle rec);                         // Check collision between circle and rectangle

    if !rl.CheckCollisionCircleRec(center, radius, qt.bounds) {
        return 
    }

    if qt.divided {
        query_circle_impl(qt.northWest, center, radius, found)
        query_circle_impl(qt.northEast, center, radius, found)
        query_circle_impl(qt.southWest, center, radius, found)
        query_circle_impl(qt.southEast, center, radius, found)
        return 
    }

    for entity in qt.entities {
        if rl.CheckCollisionPointCircle(entity.position, center, radius) {
            append(found, entity)
        }
    }
}

rebalance :: proc(qt : ^Quadtree) {
    children := get_children(qt)
    children_points := 0
    for child in children {
        if child != nil {
            children_points += child.total_points
        }
    }
    if len(qt.entities) + children_points <= qt.capacity {
        qt.divided = false
        for child in children {
            if child != nil {
                for entity in child.entities {
                    insert(qt, entity)
                }
                clear_quadtree(child)
            }
        }
    }
}

subdivide :: proc(qt : ^Quadtree) {
    x := qt.bounds.x
    y := qt.bounds.y
    w := qt.bounds.width / 2
    h := qt.bounds.height / 2

    qt.northWest = Make_quadtree(rl.Rectangle{x, y, w, h}, qt.capacity, qt.depth + 1)
    qt.northEast = Make_quadtree(rl.Rectangle{x + w, y, w, h}, qt.capacity, qt.depth + 1)
    qt.southWest = Make_quadtree(rl.Rectangle{x, y + h, w, h}, qt.capacity, qt.depth + 1)
    qt.southEast = Make_quadtree(rl.Rectangle{x + w, y + h, w, h}, qt.capacity, qt.depth + 1)
    qt.divided = true

    inserted := false

    for entity in qt.entities {
        inserted = insert(qt.northEast, entity) || insert(qt.northWest, entity) || insert(qt.southEast, entity) || insert(qt.southWest, entity)
        if !inserted {
            rl.TraceLog(rl.TraceLogLevel.TRACE, "Failed to insert entity into children")
        }
    }
    delete(qt.entities)
    qt.entities = nil
    //rl.TraceLog(rl.TraceLogLevel.TRACE, "Subdivided quadtree at depth %d", qt.depth)
}

Draw :: proc(qt : ^Quadtree, toggle : bool = false) {
    if qt.divided {
        Draw(qt.northWest)
        Draw(qt.northEast)
        Draw(qt.southWest)
        Draw(qt.southEast)
    } else if toggle {
        rl.DrawRectangleLinesEx(qt.bounds, 1, rl.WHITE)
    }
    for entity in qt.entities {
        rl.DrawCircleV(entity.position, 2, rl.WHITE)
    }
}

Get_all_boids :: proc(qt : ^Quadtree) -> [dynamic]^boid.Boid {
    boids := [dynamic]^boid.Boid{}
    get_all_boids(qt, &boids)
    return boids
}

get_all_boids :: proc(qt : ^Quadtree, boids : ^[dynamic]^boid.Boid) {
    if qt.divided {
        get_all_boids(qt.northWest, boids)
        get_all_boids(qt.northEast, boids)
        get_all_boids(qt.southWest, boids)
        get_all_boids(qt.southEast, boids)
    } else {
        for entity in qt.entities {
            append(boids, entity)
        }
    }
}

clear_quadtree :: proc(qt : ^Quadtree) {
    // for entity in qt.entities {
    //     free(entity)
    // }
    delete(qt.entities)
    if !qt.divided {
        return
    }
    clear_quadtree(qt.northWest)
    clear_quadtree(qt.northEast)
    clear_quadtree(qt.southWest)
    clear_quadtree(qt.southEast)
    free(qt.northWest)
    free(qt.northEast)
    free(qt.southWest)
    free(qt.southEast)
    qt.divided = false 
}