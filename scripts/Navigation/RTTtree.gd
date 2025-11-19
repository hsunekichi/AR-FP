## Simple kd-tree-like structure to hold points for RTT*
class_name RTTtreeGD

var points: PackedVector2Array
var connections: PackedInt32Array # Index of the father of each node
var origin: int = -1

func clear() -> void:
    points = []
    connections = []
    origin = -1
func isEmpty() -> bool:
    return points.size() == 0
func size() -> int:
    return points.size()

func set_origin(point: Vector2) -> int:
    origin = connect_point(point, -1)
    return origin
func get_origin() -> Vector2:
    return points[origin]
func connect_point(point: Vector2, father_idx: int) -> int:
    points.append(point)
    connections.append(father_idx)
    return points.size() - 1

func reconnect_point(idx: int, new_father_idx: int) -> void:
    connections[idx] = new_father_idx

func get_point(idx: int) -> Vector2:
    return points[idx]

## Returns the total travel distance from this node to the tree root
func compute_cost(idx: int) -> float:
    var total_distance := 0.0
    var current_idx := idx
    var father_idx := connections[current_idx]

    # Traverse up to the root
    while father_idx != -1:
        total_distance += points[current_idx].distance_to(points[father_idx])

        current_idx = father_idx
        father_idx = connections[current_idx]

    return total_distance

## Get the k nearest neighbors to a point
func get_k_nearest(point: Vector2, k: int) -> PackedInt32Array:
    var nearest_idx: PackedInt32Array = []
    var distances: PackedFloat32Array = []
    
    nearest_idx.resize(k)
    distances.resize(k)
    distances.fill(INF)

    for i in range(points.size()):
        var p := points[i]
        var dist := point.distance_squared_to(p) # Since we are only comparing, sqrt is not necessary
        var idx := distances.bsearch(dist)

        if idx != distances.size(): # The point is closer than some existant
            distances.insert(idx, dist)
            nearest_idx.insert(idx, i)
            distances.remove_at(distances.size()-1)
            nearest_idx.remove_at(nearest_idx.size()-1)

    # Remove INFs from the array
    for i in range(distances.size()-1, -1, -1):
        if distances[i] == INF:
            nearest_idx.remove_at(nearest_idx.size()-1)

    return nearest_idx

## Get all neighbors within a certain radius
func get_nearest(point: Vector2, radius: float) -> PackedInt32Array:
    var nearest_idx: PackedInt32Array = []
    var sqr_radius := radius * radius
    
    for i in range(points.size()):
        var p := points[i]
        var dist := point.distance_squared_to(p) # SInce we are only comparing, sqrt is not necessary

        if dist < sqr_radius: # The point is within the search radius
            nearest_idx.append(i)

    return nearest_idx

## Computes the best known path from the tree origin to the goal,
##  or an empty array if no path was found
func build_path(goal: Vector2, max_neighbors: int) -> PackedVector2Array:
    # Find best goal parent
    var nearest := get_k_nearest(goal, max_neighbors)

    var parent: int = -1
    var min_distance := INF
    for i in range(nearest.size()):
        var p := points[nearest[i]]
        var d = compute_cost(nearest[i]) + p.distance_to(goal)
        
        # Find the best reachable neighbor
        if not World.ray_intersects_ground(p, goal) \
                and d < min_distance:
            parent = nearest[i]
            min_distance = d 

    if parent == -1:
        return PackedVector2Array() # No path found
            
    # Build path from goal parent to root
    var path: PackedVector2Array = []

    # Traverse up to the root
    while parent != -1:
        path.append(points[parent])
        parent = connections[parent]
    
    path.reverse()
    path.append(goal)
    
    return path
