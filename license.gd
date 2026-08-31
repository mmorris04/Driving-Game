extends Control

@onready var pointsLabel = $CanvasLayer/ColorRect/Points


func _ready():
	var main = get_tree().current_scene  # or get_node("/root/Main") if you prefer an absolute path
	
	main.connect("points_changed", Callable(self, "_on_points_changed"))
	
	pointsLabel.text = "Score: 0"


func _on_points_changed(new_value: int) -> void:
	pointsLabel.text = "Score: %d" % new_value
	
