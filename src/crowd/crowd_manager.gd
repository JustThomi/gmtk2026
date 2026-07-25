extends Node3D

@export var pedestrian_scene : PackedScene
@export var police_scene : PackedScene
@export var total_pedestrians : int = 30
@export var total_police : int = 5

func _ready():
	randomize()
	
	var map = get_world_3d().navigation_map
	while map == RID():
		await get_tree().physics_frame
		map = get_world_3d().navigation_map
	
	spawn_on_navmesh()

func spawn_on_navmesh():
	var map = get_world_3d().navigation_map
	_spawn_entities(pedestrian_scene, total_pedestrians, map)
	_spawn_entities(police_scene, total_police, map)

func _spawn_entities(scene_to_spawn: PackedScene, amount: int, map: RID):
	if not scene_to_spawn:
		return
	
	for i in range(amount):
		var new_entity = scene_to_spawn.instantiate()
		
		var random_x = randf_range(-50.0, 50.0) 
		var random_z = randf_range(-50.0, 50.0)
		var search_point = Vector3(random_x, 0.0, random_z)
		
		var safe_point = NavigationServer3D.map_get_closest_point(map, search_point)
		
		new_entity.position = safe_point
		add_child(new_entity)
