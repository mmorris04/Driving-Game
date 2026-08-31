extends Camera3D
@onready var left_mirror: MeshInstance3D = $"../.."
@onready var dummy_cam_left: Node3D = $"../../DummyCam_Left"

func _process(_delta):
	# Follow dummy for mirror alignment
	if left_mirror:
		global_transform = dummy_cam_left.global_transform
