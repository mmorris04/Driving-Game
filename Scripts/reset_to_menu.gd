extends Area3D

# This export variable lets you select the target scene directly in the Godot Inspector.
@export var next_scene_path: String = "res://Scenes/menus.tscn"

func _on_body_entered(body: Node3D):
	if body.name == "car":
		get_tree().change_scene_to_file.call_deferred(next_scene_path) # Ending scenario, results page and data logging
