extends VehicleBody3D

@export var STEER_SPEED = 1
@export var STEER_LIMIT = 0.6
@export var engine_force_value = 40
@export var STEERING_WHEEL_ROTATION = 450.0 # Maximum visual turn (degrees)
@export var STEERING_WHEEL_SMOOTHNESS = 2.0 # Higher = snappier, lower = smoother

var steer_target = 0.0
var current_wheel_angle := 0.0 # Internal visual rotation tracker
var indicateDir = 0

var throttle := 0.0
var brake_pressure := 0.0

@onready var vr_cam = $vrPlayer.get_node("XRCamera3D")
@onready var right_mirror_mesh: MeshInstance3D = $"doge-body/Door_Mirror_R/Right_Mirror"
@onready var left_mirror_mesh: MeshInstance3D = $"doge-body/Door_Mirror_L/Left_Mirror"
@onready var rear_mirror_mesh: CSGPolygon3D = $"doge-body/Centre_mirror/Rear_Mirror"

func _ready() -> void:
	$"doge-body/Signal_L".hide()
	$"doge-body/Signal_R".hide()
	
	vr_cam.connect("on_right_trigger_pressure", Callable(self, "accelerate_car"))
	vr_cam.connect("on_left_trigger_pressure", Callable(self, "use_car_brakes"))
	vr_cam.connect("left_indicator", Callable(self, "left_indicate"))
	vr_cam.connect("right_indicator", Callable(self, "right_indicate"))
	vr_cam.connect("toggle_pause", Callable($vrPlayer, "pause_function"))
	
	# Toggling headlights if night or foggy
	if(Globals.scenario_data["TimeOfDay"]=="Night" or Globals.scenario_data["Weather"]=="Fog"):
		toggleHeadlights()

func _physics_process(delta):
	# --- Determining and displaying speed ---
	var speed = linear_velocity.length() * Engine.get_frames_per_second() * delta
	traction(speed)
	$"doge-body/Dashboard_screen/speed_dial_viewport/Speed_label".text = str(int(round(speed * 6.36)))

	# --- Determining direction for reverse lights ---
	#var fwd_mps = transform.basis.x.x
	var forward_dir = -global_transform.basis.z.normalized()
	var velocity_dir = linear_velocity.normalized()
	var movement_dot = forward_dir.dot(velocity_dir)
	if linear_velocity.length() < 0.5 or movement_dot > 0: #Stationary or forwards
		$"doge-body/Taillights_glass_reverse/Reverse_light_L".hide()
		$"doge-body/Taillights_glass_reverse/Reverse_light_R".hide()
	else:
		$"doge-body/Taillights_glass_reverse/Reverse_light_L".show()
		$"doge-body/Taillights_glass_reverse/Reverse_light_R".show()

	# --- Engine / Brake Logic ---
	var applied_engine = -throttle * engine_force_value
	#print(applied_engine)
	var applied_brake = brake_pressure * 1.0
	

	if applied_engine < 0 and not $AccelerationSound.is_playing():
		$AccelerationSound.play()
	elif applied_engine == 0 and $AccelerationSound.is_playing():
		var tween = get_tree().create_tween()
		tween.tween_property($AccelerationSound, "volume_db", -40, 0.5) # fade to silence over 0.5 seconds
		tween.finished.connect(func():
			$AccelerationSound.stop()
			$AccelerationSound.volume_db = -25 # restore default volume
		)


	# Assign to all wheels
	$wheal0.engine_force = applied_engine
	$wheal1.engine_force = applied_engine
	$wheal2.engine_force = applied_engine
	$wheal3.engine_force = applied_engine

	$wheal0.brake = applied_brake
	$wheal1.brake = applied_brake
	$wheal2.brake = applied_brake
	$wheal3.brake = applied_brake

	# Brake lights
	if brake_pressure > 0.05:
		$"doge-body/Taillights_glass_brakelights/Break_light_L".show()
		$"doge-body/Taillights_glass_brakelights/Break_light_R".show()
		
		$wheal2.wheel_friction_slip = lerp(3.0, 0.8, brake_pressure)
		$wheal3.wheel_friction_slip = lerp(3.0, 0.8, brake_pressure)
	else:
		$"doge-body/Taillights_glass_brakelights/Break_light_L".hide()
		$"doge-body/Taillights_glass_brakelights/Break_light_R".hide()
		
		$wheal2.wheel_friction_slip = 3
		$wheal3.wheel_friction_slip = 3

	# Smoothly adjust vehicle steering
	steering = move_toward(steering, steer_target, STEER_SPEED * delta)

	# Smoothly rotate the steering wheel
	update_steering_wheel(delta)
	check_mirrors()


func traction(speed):
	apply_central_force(Vector3.DOWN * speed)

func update_steering_wheel(delta: float) -> void:
	var steer_wheel = $Steer
	# Compute target rotation angle in radians
	var target_angle = deg_to_rad(STEERING_WHEEL_ROTATION * steer_target / STEER_LIMIT)
	# Smooth interpolation toward the target
	current_wheel_angle = lerp(current_wheel_angle, float(clamp(target_angle,-8,8)), delta*STEERING_WHEEL_SMOOTHNESS)
	# Apply local rotation (adjust axis as needed)
	steer_wheel.rotation.z = current_wheel_angle
	
func indicate(direction: int) -> void:
	get_parent().get_parent().get_node("LaneManager").notify_signal_used()
	
	$"doge-body/Turnsignals_glass/Signal_light_FL".hide()
	$"doge-body/Turnsignals_glass/Signal_light_BL".hide()
	$"doge-body/Turnsignals_glass/Signal_light_FR".hide()
	$"doge-body/Turnsignals_glass/Signal_light_BR".hide()
	$"doge-body/Signal_R".hide()
	$"doge-body/Signal_L".hide()
	if(direction==1 and indicateDir!=1): #Left
		UserData.signaled("Left")
		$IndicatorSound.play()
		indicateDir=1
	elif(direction==2 and indicateDir!=2): #Right
		UserData.signaled("Right")
		$IndicatorSound.play()
		indicateDir=2
	else:
		indicateDir=0
		$IndicatorSound.stop()
		
func toggleHeadlights() -> void:
	%"Headlight_L".visible = !%"Headlight_L".visible
	%"Headlight_R".visible = !%"Headlight_R".visible
	%"Headlight_bulb_L".visible = !%"Headlight_bulb_L".visible
	%"Headlight_bulb_R".visible = !%"Headlight_bulb_R".visible

# Flashing indicator lights
func _on_timer_timeout() -> void:
	if(indicateDir==1):
		$"doge-body/Signal_L".visible = !$"doge-body/Signal_L".visible
		$"doge-body/Turnsignals_glass/Signal_light_FL".visible = !$"doge-body/Turnsignals_glass/Signal_light_FL".visible
		$"doge-body/Turnsignals_glass/Signal_light_BL".visible = !$"doge-body/Turnsignals_glass/Signal_light_BL".visible
	elif(indicateDir==2):
		$"doge-body/Signal_R".visible = !$"doge-body/Signal_R".visible
		$"doge-body/Turnsignals_glass/Signal_light_FR".visible = !$"doge-body/Turnsignals_glass/Signal_light_FR".visible
		$"doge-body/Turnsignals_glass/Signal_light_BR".visible = !$"doge-body/Turnsignals_glass/Signal_light_BR".visible

# Changing direction based on user input to wheel
func _on_vr_player_steering_changed(angle) -> void:
	steer_target = steer_target+angle*STEER_LIMIT

# Auto staightening car when not holding wheel
func _on_vr_player_steering_reset() -> void:
	steer_target = 0
	
func accelerate_car(value):
	throttle = value * 1.4
	
func use_car_brakes(value):
	brake_pressure = value

func left_indicate():
	indicate(1)
	
func right_indicate():
	indicate(2)

func check_mirrors():
	# Mirror checks for the mirrors
	var playerCam = -vr_cam.global_transform.basis.z.normalized()#
	
	var look_thresh = 0.9
	var max_dist = 20.0
	
	var mirrors = {
		"Right": right_mirror_mesh, 
		"Left": left_mirror_mesh,
		"Rear": rear_mirror_mesh
	}
	
	for mirror_Name in mirrors.keys():
		var targMirror = mirrors[mirror_Name]
	
		var target = (targMirror.global_position - vr_cam.global_position).normalized()
		var dotProduct = playerCam.dot(target)
		
		var dist_to_mirror = vr_cam.global_position.distance_to(targMirror.global_position)
		
		if dotProduct > look_thresh and dist_to_mirror < max_dist:
			
			get_parent().get_parent().get_node("LaneManager").notify_mirror_check(mirror_Name)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("LampPost"):
		UserData.crashed()
