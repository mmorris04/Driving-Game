extends MeshInstance3D

# Left camera
@onready var dummy_cam_left: Node3D = $DummyCam_Left
@onready var left_camera: Camera3D = $Left_Viewport/Left_Camera
@onready var left_mirror: MeshInstance3D = $"."
@onready var left_viewport: SubViewport = $Left_Viewport

func _ready() -> void:
	add_to_group("mirrors")
	left_viewport.size = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))
	
	var left_mat:= StandardMaterial3D.new()
	left_mat.albedo_texture = left_viewport.get_texture()
	left_mat.roughness = 0.0
	left_mat.metallic = 0.0
	left_mat.uv1_scale.y = -1.0
	left_mat.uv1_scale.x = -1.0
	left_mirror.set_surface_override_material(0, left_mat)
	
func _process(_float):
	left_camera.global_transform = dummy_cam_left.global_transform
