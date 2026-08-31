extends Node3D

@export var min_angle := -450.0
@export var max_angle := 450.0

var angle := 0.0
var last_handle_rot := 0.0
var grabbing := false

@onready var handle := $Interactable_handle

func _ready():
	print("start")
	# We override the pick_up & let_go methods using Callables
	handle.connect("picked_up", Callable(self, "_on_grabbed"))
	handle.connect("released", Callable(self, "_on_released"))

func _on_grabbed(by):
	grabbing = true
	last_handle_rot = handle.rotation.y


func _on_released(by, _linvel, _angvel):
	grabbing = false


func _physics_process(_delta):
	if !grabbing:
		return

	print("dsfdsfdsf")
	var current_rot = handle.rotation.y
	var delta = wrapf(current_rot - last_handle_rot, -PI, PI)

	angle += rad_to_deg(delta)
	angle = clamp(angle, min_angle, max_angle)

	rotation_degrees.z = angle
	last_handle_rot = current_rot
