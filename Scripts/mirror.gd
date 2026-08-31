extends MeshInstance3D

# Right camera
@onready var dummy_cam_right: Node3D = $DummyCam_Right
@onready var right_camera: Camera3D = $Right_Viewport/Right_Camera
@onready var right_mirror: MeshInstance3D = $Right_Mirror

# Left camera
@onready var dummy_cam_left: Node3D = $"../Door_Mirror_L/DummyCam_Left"
@onready var left_viewport: SubViewport = $"../Door_Mirror_L/Left_Viewport"
@onready var left_camera: Camera3D = $"../Door_Mirror_L/Left_Viewport/Left_Camera"
@onready var left_mirror: MeshInstance3D = $"../Door_Mirror_L/Left_Mirror"

# Rear Camera
@onready var dummy_cam_rear: Node3D = $"../Centre_mirror/DummyCam_Rear"
@onready var rear_viewport: SubViewport = $"../Centre_mirror/Rear_Viewport"
@onready var rear_camera: Camera3D = $"../Centre_mirror/Rear_Viewport/Rear_Camera"
@onready var rear_mirror: CSGPolygon3D = $"../Centre_mirror/Rear_Mirror"


func _ready() -> void:
	add_to_group("mirrors")
	$Right_Viewport.size = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))
	left_viewport.size = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))
	rear_viewport.size = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))
	
	# Right camera 
	var right_mat:= StandardMaterial3D.new()
	right_mat.albedo_texture = $Right_Viewport.get_texture()
	right_mat.roughness = 0.0
	right_mat.metallic = 0.0
	right_mat.uv1_scale.x = -1.0
	right_mirror.set_surface_override_material(0, right_mat)
	
	# Left camera
	var left_mat = StandardMaterial3D.new()
	left_mat.albedo_texture = left_viewport.get_texture()
	left_mat.roughness = 0.0
	left_mat.metallic = 0.0
	left_mat.uv1_scale.x = -1.0
	left_mirror.set_surface_override_material(0, left_mat)
	
	# Rear camera
	var centre_mat = StandardMaterial3D.new()
	centre_mat.albedo_texture = rear_viewport.get_texture()
	centre_mat.roughness = 0.0
	centre_mat.metallic = 0.0
	centre_mat.uv1_scale.x = -1.0
	rear_mirror.material = centre_mat
	#rear_mirror.set_surface_override_material(0, centre_mat)
	
func _process(_float):
	right_camera.global_transform = dummy_cam_right.global_transform	
	left_camera.global_transform = dummy_cam_left.global_transform
	rear_camera.global_transform = dummy_cam_rear.global_transform
