extends Camera3D

@onready var vr_player: XROrigin3D = $"../../vrPlayer"

@onready var camera = vr_player.get_node("XRCamera3D")
@onready var leftHand = vr_player.get_node("leftHand")
@onready var rightHand = vr_player.get_node("rightHand")
@onready var anchor: Node3D = $"../../anchor"
@onready var look: Node3D = $".."

func _physics_process(_delta):
	if not vr_player or not anchor:
		return
		
	var player = vr_player.global_transform
	player.origin = anchor.global_position
	player.basis = anchor.global_basis
	vr_player.global_transform = player
	
	## Simply lock the camera to match its current local transform relative to the parentw
	
	#if camera != null:
		#camera.global_position = look.global_position
		#
		#leftHand.global_position = vrPlayer.global_position
		#rightHand.global_position = vrPlayer.global_position
		#
