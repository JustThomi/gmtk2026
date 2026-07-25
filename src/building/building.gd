extends Node3D

@export_range(0.0, 1.0) var faded_alpha := 0.25
@export var fade_duration := 0.2

var building_meshes: Array[MeshInstance3D] = []
var active_tween: Tween


func _ready() -> void:
	for child in find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D

		if mesh != null:
			building_meshes.append(mesh)


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		fade_building(faded_alpha)


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		fade_building(1.0)


func fade_building(target_alpha: float) -> void:
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()

	active_tween = create_tween()

	var target_transparency := 1.0 - target_alpha

	for mesh in building_meshes:
		if not is_instance_valid(mesh):
			continue

		active_tween.parallel().tween_property(
			mesh,
			"transparency",
			target_transparency,
			fade_duration
		)
