extends Node3D

@export var pedestrian_scene : PackedScene
@export var police_scene : PackedScene
@export var total_pedestrians : int = 50
@export var total_police : int = 10
@export var spawn_radius : float = 100.0

func _ready():
	randomize()
	var map = get_world_3d().navigation_map
	
	NavigationServer3D.map_force_update(map)
	
	while NavigationServer3D.map_get_random_point(map, 1, false) == Vector3.ZERO:
		await get_tree().physics_frame
		NavigationServer3D.map_force_update(map)
		
	spawn_on_navmesh(map)

func spawn_on_navmesh(map: RID):
	await _spawn_entities(pedestrian_scene, total_pedestrians, map)
	await _spawn_entities(police_scene, total_police, map)

func _spawn_entities(scene_to_spawn: PackedScene, amount: int, map: RID):
	if not scene_to_spawn:
		return
	
	for i in range(amount):
		var new_entity = scene_to_spawn.instantiate()
		
		var random_x = randf_range(-spawn_radius, spawn_radius) 
		var random_z = randf_range(-spawn_radius, spawn_radius)
		var search_point = Vector3(random_x, 0.0, random_z)
		
		var safe_point = NavigationServer3D.map_get_closest_point(map, search_point)
		
		new_entity.position = safe_point
		add_child(new_entity)
		
		await get_tree().physics_frame
