extends VehicleBody3D
class_name NPCCar

# script to control the behaviour of a non-player car. Drives to given destinations and can loop through them.
# modified heavily from BaseCar.gd

# file variables from BaseCar.gd
@export_group("Car Physics")
@export var STEER_SPEED = 1
@export var STEER_LIMIT = 0.6
@export var engine_force_value = 40
@export var STEERING_WHEEL_ROTATION = 450.0 # Maximum visual turn (degrees)
@export var STEERING_WHEEL_SMOOTHNESS = 2.0 # Higher = snappier, lower = smoother
@export var COLOUR : Color = Color.BLACK

var steer_target = 0.0
var current_wheel_angle := 0.0 # Internal visual rotation tracker


# file variables and constants added by me for this script
@export_group("NPC Driving Controls")
## The list of locations the car is meant to drive to as 3D vectors.
# -1500 is end of road coord
@export var destinations: Array[Vector3] = [Vector3(100, 0, -100)]
## Whether the car should endlessly loop through the destinations or stop at the final one.
@export var loop: bool = true
## The maximum speed the car is allowed to go.
## Note: in the original BaseCar.gd, a conversion ratio is given of 1 speed = ~2.36mph.
@export var speed_limit: float = 20
## The maximum (Euclidean) distance the car can be from a given destination to count it as "reached".
@export var target_radius: float = 10
## How many radians the car can be facing away from the destination to still count as facing it.
## Broadly defines how strictly it will try and follow a straight line to the objective (lower = stricter).
@export var target_range: float = 0.3
## How aggressively the car steers towards the destination when it's off-track (higher = more aggressive).
@export var steer_power: float = 1.5
## How close the car can get from another car before it detects this and brakes.
@export var detection_distance: float = 10

## The current desination the car is attempting to reach.
var current_destination = 0
## A signal that is emitted whenever the car reaches its final destination (regardless of if it loops or stops).
signal destination_reached(npc_car: NPCCar)
## Signal that is emitted whenever the car hits something.
signal collision_detected()
## A RayCast3D object for collision detection
@onready var ray_cast_3d: RayCast3D = $RayCast3D


func _ready() -> void:
	# Setting car colour
	var mat = $"DogeBody/Body".get_active_material(0).duplicate()
	$"DogeBody/Body".set_surface_override_material(0, mat)
	$"DogeBody/Hood".set_surface_override_material(0, mat)
	$"DogeBody/Door_FL".set_surface_override_material(0, mat)
	$"DogeBody/Door_FR".set_surface_override_material(0, mat)
	$"DogeBody/Trunkdoor".set_surface_override_material(0, mat)
	mat.albedo_color = COLOUR
	# set raycast target position
	ray_cast_3d.target_position = Vector3(0, 0, -detection_distance)
	# add to a group with other NPCCars (this does not appear to work as intended)
	add_to_group("npc_cars")

func _physics_process(delta):
	# get speed and apply traction
	var speed = linear_velocity.length() * Engine.get_frames_per_second() * delta
	traction(speed)

	# == COLLISION DETECTION ==
	# raycasting to check for collisions
	# if the raycast has collided, don't bother executing acceleration code
	var has_collided = check_raycast()
	if has_collided:
		return

	# == REVERSE LIGHTS ==
	display_reverse_lights()

	# == DESTINATION CHECKING ==
	# don't want to run main code if we've reached a destination
	var reached_destination = check_destination(speed)
	if reached_destination:
		return

	# == DRIVING ==
	apply_engine_force(speed)
	
	# == STEERING ==
	apply_steering(delta)

# My added functions.
## Checks if the raycast has hit an object and slows down (and returns true) if so.
func check_raycast() -> bool:
	# if the raycast hits something, hit da brakes
	if ray_cast_3d.is_colliding():
		var collision_object = ray_cast_3d.get_collider()

		# if the object collised with is a VehicleBody3D (to avoid issues with colliding with the ground)
		if collision_object != null and collision_object.is_class("VehicleBody3D"):
			engine_force = engine_force_value
			return true
		else:
			return false
	else:
		return false

## Works out if the car is reversing and displays reverse lights if so.
func display_reverse_lights() -> void:
	var forward_dir = -global_transform.basis.z.normalized()
	var velocity_dir = linear_velocity.normalized()
	var movement_dot = forward_dir.dot(velocity_dir)
	if linear_velocity.length() < 0.5 or movement_dot > 0: #Stationary or forwards
		$"DogeBody/Taillights_glass_reverse/Reverse_light_L".hide()
		$"DogeBody/Taillights_glass_reverse/Reverse_light_R".hide()
	else:
		$"DogeBody/Taillights_glass_reverse/Reverse_light_L".show()
		$"DogeBody/Taillights_glass_reverse/Reverse_light_R".show()

## Checks whether or not the car has reached its destination.
func check_destination(speed: float) -> bool:
	# compare car's current location in scene against desired destination,
	# if it's close enough, count the destination as reached
	var current_position = global_position
	var target_position = destinations[current_destination] - current_position
	var target_distance = target_position.length()

	if (target_distance < target_radius):
		# if we're not at the last destination, just increment current_destination
		if (current_destination < (destinations.size() - 1)):
			current_destination = current_destination + 1
			return false

		else:
			# emit our signal to indicate we've reached the last destination
			destination_reached.emit(self)

			# if we are looping, reset current_destination to the first one
			if (loop):
				current_destination = 0

			# if not, hit da brakes (logic from BaseCar.gd)
			else:
				if speed < 20 and speed != 0:
					engine_force = clamp(engine_force_value * 3 / speed, 0, 300)
				else:
					engine_force = engine_force_value
				$"DogeBody/Taillights_glass_brakelights/Break_light_L".show()
				$"DogeBody/Taillights_glass_brakelights/Break_light_R".show()
			return true
	else:
		return false

## Apply engine logic to the car to work out if it should accelerate.
func apply_engine_force(speed: float) -> void:
	# if > speed limit, go slower, else go faster
	if (speed > speed_limit):
		if speed < 20 and speed != 0:
			engine_force = clamp(engine_force_value * 3 / speed, 0, 300)
		else:
			engine_force = engine_force_value
		$"DogeBody/Taillights_glass_brakelights/Break_light_L".hide()
		$"DogeBody/Taillights_glass_brakelights/Break_light_R".hide()

	else:
		if speed < 30 and speed != 0:
			engine_force = -clamp(engine_force_value * 10 / speed, 0, 300)
		else:
			engine_force = -engine_force_value
		#might be too frequent showing them every time the car slows down?
		#$"DogeBody/Taillights_glass_brakelights/Break_light_L".show()
		#$"DogeBody/Taillights_glass_brakelights/Break_light_R".show()

## Applies steering to the car if it's not facing its destination.
func apply_steering(delta: float) -> void:
	# calculate vectors for where car is currently pointing and where it should point
	# and get the angle (in radians) between them
	var current_position = global_position
	var target_direction = current_position.direction_to(destinations[current_destination])
	var current_direction = -global_transform.basis.z
	var angle = current_direction.signed_angle_to(target_direction, Vector3.UP)

	# if the angle is outside the target range, apply steering
	if (abs(angle) > target_range):
		# if angle is positive, target_direction is to our "left", and we need to turn counter-clockwise
		# if angle is negative, target_direction is to our "right", and we need to turn clockwise
		if (angle > 0):
			steer_target = steer_power
		else:
			steer_target = -steer_power
		steer_target *= STEER_LIMIT

		# Smoothly adjust vehicle steering
		steering = move_toward(steering, steer_target, STEER_SPEED * delta)

		# Smoothly rotate the steering wheel
		update_steering_wheel(delta)

	# stop the car from oversteering by blocking it when it's facing the destination
	else:
		steering = 0

## Toggles the car's headlights.
func toggle_headlights() -> void:
	%"Headlight_L".visible = !%"Headlight_L".visible
	%"Headlight_R".visible = !%"Headlight_R".visible
	%"Headlight_bulb_L".visible = !%"Headlight_bulb_L".visible
	%"Headlight_bulb_R".visible = !%"Headlight_bulb_R".visible

# unmodified functions from base_car.gd

func traction(speed):
	apply_central_force(Vector3.DOWN * speed)

func update_steering_wheel(delta: float) -> void:
	var steer_wheel = $Steer
	if steer_wheel == null:
		return

	# Compute target rotation angle in radians
	var target_angle = deg_to_rad(STEERING_WHEEL_ROTATION * steer_target / STEER_LIMIT)

	# Smooth interpolation toward the target
	current_wheel_angle = lerp(current_wheel_angle, target_angle, delta * STEERING_WHEEL_SMOOTHNESS)

	# Apply local rotation (adjust axis as needed)
	steer_wheel.rotation.z = current_wheel_angle

## If a player car has entered our Area3D, emit a collision_detected() signal.
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method('indicate'):
		collision_detected.emit()
