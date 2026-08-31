extends Camera3D

@export var car: Node3D
@export var offset := Vector3(0, 1.5, 2.0) # relative position behind car
@export var look_back := true

func _process(_delta):
	if car:
		# Position the mirror camera relative to the car
		global_transform = car.global_transform.translated_local(offset)
		
		# Face backwards relative to car
		if look_back:
			var basis = car.global_transform.basis
			var back_dir = -basis.z  # car’s forward direction is -Z
			look_at(global_position - back_dir, Vector3.UP)
