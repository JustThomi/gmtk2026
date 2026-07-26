extends Node

@export var player: CharacterBody3D
@export var camera: Camera3D

@export_flags_3d_physics var building_collision_mask := 1 << 1

@export_range(0.0, 1.0) var faded_visibility := 0.35
@export var fade_speed := 6.0
@export var restore_delay := 0.2
@export var ray_width := 1

var faded_meshes: Dictionary = {}
var currently_blocking: Dictionary = {}
var last_blocked_time: Dictionary = {}


func _process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(camera):
		return

	currently_blocking.clear()

	_find_blocking_buildings()
	_update_fades(delta)

func _find_blocking_buildings() -> void:
	var space_state := get_viewport().world_3d.direct_space_state
	var from := camera.global_position

	var camera_right := camera.global_transform.basis.x.normalized()
	var camera_forward := -camera.global_transform.basis.z.normalized()

	var player_center := player.global_position + Vector3.UP * 1.0

	var targets: Array[Vector3] = [
		player_center,
		player_center + camera_right * ray_width,
		player_center - camera_right * ray_width,
		player_center + camera_forward * ray_width,
		player_center - camera_forward * ray_width
	]

	for target in targets:
		_cast_ray_for_buildings(space_state, from, target)

func _cast_ray_for_buildings(
	space_state: PhysicsDirectSpaceState3D,
	from: Vector3,
	to: Vector3
) -> void:
	var excluded_rids: Array[RID] = [player.get_rid()]

	while true:
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = building_collision_mask
		query.exclude = excluded_rids
		query.collide_with_areas = false
		query.collide_with_bodies = true

		var result := space_state.intersect_ray(query)

		if result.is_empty():
			break

		var collider := result.get("collider") as CollisionObject3D

		if collider == null:
			break

		var building_root := _find_building_root(collider)

		if building_root != null:
			currently_blocking[building_root] = true
			last_blocked_time[building_root] = Time.get_ticks_msec() / 1000.0

			_register_building_meshes(building_root)

		excluded_rids.append(collider.get_rid())

func _find_building_root(node: Node) -> Node:
	var current := node

	while current != null:
		if current.is_in_group("Buildings"):
			return current

		current = current.get_parent()

	return null

func _register_building_meshes(building: Node) -> void:
	for child in building.find_children(
		"*",
		"MeshInstance3D",
		true,
		false
	):
		var mesh := child as MeshInstance3D

		if mesh == null:
			continue

		if not faded_meshes.has(mesh):
			faded_meshes[mesh] = true

func _update_fades(delta: float) -> void:
	var meshes_to_remove: Array[MeshInstance3D] = []
	var current_time := Time.get_ticks_msec() / 1000.0

	for mesh_variant in faded_meshes.keys():
		var mesh := mesh_variant as MeshInstance3D

		if not is_instance_valid(mesh):
			meshes_to_remove.append(mesh)
			continue

		var building := _find_building_root(mesh)

		if building == null:
			meshes_to_remove.append(mesh)
			continue

		var should_fade := currently_blocking.has(building)

		if not should_fade and last_blocked_time.has(building):
			var time_since_blocked: float = (
				current_time - float(last_blocked_time[building])
			)

			should_fade = time_since_blocked < restore_delay

		var target_transparency := (
			1.0 - faded_visibility
			if should_fade
			else 0.0
		)

		mesh.transparency = move_toward(
			mesh.transparency,
			target_transparency,
			fade_speed * delta
		)

		if not should_fade and is_zero_approx(mesh.transparency):
			mesh.transparency = 0.0
			meshes_to_remove.append(mesh)

	for mesh in meshes_to_remove:
		faded_meshes.erase(mesh)

		if is_instance_valid(mesh):
			var building := _find_building_root(mesh)

			if building != null:
				last_blocked_time.erase(building)
