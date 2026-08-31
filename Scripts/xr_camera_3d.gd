extends XRCamera3D

# Signals
signal on_right_trigger_pressure(value)
signal on_left_trigger_pressure(value)

signal right_indicator
signal left_indicator

signal toggle_pause(value)

@onready var left_hand: XRController3D = $"../leftHand"
@onready var right_hand: XRController3D = $"../rightHand"
@onready var pause_value: bool = false

func _process(_delta: float):
	get_tree().call_group("mirrors", "update_cam", global_transform)
	
# Signaling
func _on_left_hand_button_pressed(action_name: String) -> void:
	if action_name == "ax_button":
		emit_signal("left_indicator")
	
func _on_right_hand_button_pressed(action_name: String) -> void:
	if action_name == "ax_button":
		emit_signal("right_indicator")
		
	if action_name == "by_button":
		pause_value = !pause_value
		emit_signal("toggle_pause", pause_value)
		
	
func _on_left_hand_input_float_changed(action_name: String, value: float) -> void:
	if action_name == "trigger":
		emit_signal("on_left_trigger_pressure", value)
	

func _on_right_hand_input_float_changed(action_name: String, value: float) -> void:
	if action_name == "trigger":
		emit_signal("on_right_trigger_pressure", value)
		
