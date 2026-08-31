extends XROrigin3D

signal steering_changed
signal steering_reset

var leftHandEntered = false
var rightHandEntered = false
var leftSteeringAttempt = false
var rightSteeringAttempt = false
var currentAngle = 0

@onready var pause_menu_viewport: XRToolsViewport2DIn3D = $"../PauseMenuViewport"	
@onready var vr_player: XROrigin3D = $"."
var pause_menu_ui

func _physics_process(delta: float) -> void:
	leftSteeringAttempt = $leftHand/LeftHand.getHandClenching()&&leftHandEntered
	rightSteeringAttempt = $rightHand/RightHand.getHandClenching()&&rightHandEntered
	
	# Updating steering direction
	if(leftSteeringAttempt or rightSteeringAttempt):
		_update_steering(delta)
	else:
		currentAngle = _find_wheel_angle()
		emit_signal("steering_reset")
	
func _convert_to_angle(direction: Vector2) -> float:
	return Vector2.UP.angle_to(direction) # Angle between 0 and the hand
	
func _find_rotation_sensitivity() -> float:
	if(leftSteeringAttempt&&rightSteeringAttempt): # Reducing sensitivity if 2 hands steering
		return 1.0/2
	else:
		return 1.0
	
func _find_wheel_angle() -> float:
	var totalAngle = 0
	if(leftSteeringAttempt):
		var direction = $"../Steer".to_local($leftHand/LeftHand.getGlobalPosition())
		var directionv2 = Vector2(direction.x, direction.y)
		totalAngle += _convert_to_angle(directionv2)*_find_rotation_sensitivity()
	if(rightSteeringAttempt):
		var direction = $"../Steer".to_local($rightHand/RightHand.getGlobalPosition())
		var directionv2 = Vector2(direction.x, direction.y)
		totalAngle += _convert_to_angle(directionv2)*_find_rotation_sensitivity()
	return totalAngle

func _update_steering(_delta: float) -> void:
	var totalAngle = _find_wheel_angle()
	var angleDifference = currentAngle - totalAngle
	var clamped_angle = clamp(-angleDifference, -0.1, 0.1)
	emit_signal("steering_changed", clamped_angle) # Controlling car steering direction and wheel
	currentAngle = totalAngle

func _on_area_3d_area_entered(area: Area3D) -> void:
	currentAngle = _find_wheel_angle()
	if(area==$leftHand/LeftHand/Area3D):
		$"../Steer/Highlighter_left".hide()
		leftHandEntered = true
	elif(area==$rightHand/RightHand/Area3D):
		$"../Steer/Highlighter_right".hide()
		rightHandEntered = true

func _on_area_3d_area_exited(area: Area3D) -> void:
	currentAngle = _find_wheel_angle()
	if(area==$leftHand/LeftHand/Area3D):
		$"../Steer/Highlighter_left".show()
		leftHandEntered = false
	elif(area==$rightHand/RightHand/Area3D):
		$"../Steer/Highlighter_right".show()
		rightHandEntered = false
	
var paused: bool = false 

func _on_resume_pressed():
	pause_function(false)
	
func _on_quit_pressed():
	pause_function(false)
	get_tree().change_scene_to_file("res://Scenes/menus.tscn")

func pause_function(newval: bool):	
	pause_menu_ui = pause_menu_viewport.get_scene_instance()
	
	var resume_btn = pause_menu_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Resume")
	var quit_btn = pause_menu_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Quit")

	var resume_callable = Callable(self, "_on_resume_pressed")
	var quit_callable = Callable(self, "_on_quit_pressed")

	if resume_btn.pressed.is_connected(resume_callable):
		resume_btn.pressed.disconnect(resume_callable)
	resume_btn.pressed.connect(resume_callable)

	if quit_btn.pressed.is_connected(quit_callable):
		quit_btn.pressed.disconnect(quit_callable)
	quit_btn.pressed.connect(quit_callable)


	paused = newval
	
	pause_menu_viewport.visible = paused
	
	for n in get_tree().get_nodes_in_group("pausable"):
		if paused:
			n.process_mode =  Node.PROCESS_MODE_DISABLED
		else:
			n.process_mode =  Node.PROCESS_MODE_INHERIT

	
