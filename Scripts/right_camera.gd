extends Camera3D

@onready var right_mirror: MeshInstance3D = $"../.."
@onready var dummy_cam_right: Node3D = $"../../DummyCam_Right"


func _process(_delta):
	# Follow dummy for mirror alignment
	if right_mirror:
		global_transform = dummy_cam_right.global_transform
