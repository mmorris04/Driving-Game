extends CanvasLayer

@onready var pointsLabel = $ColorRect/Points


func _ready():
	var main = get_tree().current_scene  # or get_node("/root/Main") if you prefer an absolute path
	
	main.connect("points_changed", Callable(self, "_on_points_changed"))
	
	pointsLabel.text = "0 Points"


func _on_points_changed(new_value: int) -> void:
	pointsLabel.text = "+%d Points" % new_value
	
