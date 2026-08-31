extends MeshInstance3D

# Right camera
@onready var dummy_cam_right: Node3D = $DummyCam_Right
@onready var right_camera: Camera3D = $Right_Viewport/Right_Camera
@onready var right_mirror: MeshInstance3D = $"."
@onready var right_viewport: SubViewport = $Right_Viewport

func _ready() -> void:
	add_to_group("mirrors")
	right_viewport.size = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))
	
	var right_mat:= StandardMaterial3D.new()
	right_mat.albedo_texture = right_viewport.get_texture()
	right_mat.roughness = 0.0
	right_mat.metallic = 0.0
	right_mat.uv1_scale.y = -1.0
	right_mat.uv1_scale.x = -1.0
	right_mirror.set_surface_override_material(0, right_mat)
	
func _process(_float):
	right_camera.global_transform = dummy_cam_right.global_transform
