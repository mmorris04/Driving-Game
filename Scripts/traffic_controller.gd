extends Node3D

# public parameters
# the parameters of the controller (i.e. how the controller is configured)
@export_group("Controller Parameters")
## The direction this controller will spawn cars facing.
## 0 is -Z, 1 is -X, 2 is +Z, and 3 is +X
## Values are treated as multiples of pi/2 radians.
@export var spawn_direction: int = 0
## The location cars are expected to drive to (lane offsets are calculated automatically).
@export var destination: Vector3 = Vector3(0, 0, 0)
## The maximum number of cars this traffic controller will spawn at once.
@export var max_population: int = 30
## How long in seconds the controller waits between spawning cars.
@export var spawn_timer: float = 1
## How many lanes of cars are spawned by the controller.
@export var lane_count: int = 3
## How far apart each lane of cars are.
@export var lane_distance: float = 5
## Whether or not the controller attempts to connect to and account for other, user-added NPCCars in the scene.
## i.e. The cars would be counted as part of this controller's population and deleted upon hitting their destination.
@export var control_other_cars: bool = false
## Variables specifically tied to the "Spawn Initial Traffic" feature. 
@export_subgroup("initial Traffic Configuration")
## Whether or not the controller should spawn an initial round of traffic before its regular pattern.
@export var place_initial_traffic: bool = true
## How many rows ahead of the controller spawns will be attempted in.
@export var rows: int = 5
## The chance (between 0 and 1) that a car is spawned each time the controller tries.
## Please do not enter a value that isn't between 0 and 1, you will make the code sad.
@export var spawn_chance: float = 0.8

# the paramaters of the spawned cars
@export_group("Car Parameters")
@export_subgroup("Car Physics")
@export var STEER_SPEED = 1
@export var STEER_LIMIT = 0.6
@export var engine_force_value = 40
@export var STEERING_WHEEL_ROTATION = 450.0 # Maximum visual turn (degrees)
@export var STEERING_WHEEL_SMOOTHNESS = 2.0 # Higher = snappier, lower = smoother

@export_subgroup("NPC Driving Controls")
## The maximum speed the car is allowed to go.
## Note: in the original BaseCar.gd, a conversion ratio is given of 1 speed = ~2.36mph.
@export var speed_limit: float = 30
## The maximum (Euclidean) distance the car can be from a given destination to count it as "reached".
@export var target_radius: float = 5
## How many radians the car can be facing away from the destination to still count as facing it.
## Broadly defines how strictly it will try and follow a straight line to the objective.
## (Lower value = stricter).
@export var target_range: float = 0.02
## How aggressively the car steers towards the destination when it's off-track.
## (Higher value = more aggressive).
@export var steer_power: float = 1.5
## How close the car can get from another car before it detects this and brakes.
@export var detection_distance: float = 10

# local variables
## Self-explanatory, once this exceeds spawn_gap we can spawn a car.
var time_since_last_spawn = 0
## The number of cars spawned by the controller that are currently active.
var alive_cars = 0
## A packed version of the NPCCar scene for instancing.
var npc_car = preload("res://Scenes/npc_car.tscn")
## The last lane a car was spawned down.
var last_lane = null
## Available colours.
var colours = [Color.BLACK, Color.DIM_GRAY, Color.MIDNIGHT_BLUE, Color.DARK_RED, Color.WEB_MAROON, Color.GRAY, Color.WHITE_SMOKE]

func _ready() -> void:
	# run functions based on given parameters
	if control_other_cars:
		add_other_cars()
	if place_initial_traffic:
		spawn_initial_traffic()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# increase time since last spawn
	time_since_last_spawn = time_since_last_spawn + delta

	# if we can spawn a car, spawn one
	if (time_since_last_spawn > spawn_timer && alive_cars < max_population):
		# randomly pick which lane to spawn down
		var current_lane = randi_range(0, lane_count - 1)
		# to avoid problems of colliding cars, regenerate if this is the same lane as last time
		while (current_lane == last_lane):
			current_lane = randi_range(0, lane_count - 1)

		# spawn and configure car
		var instance = npc_car.instantiate() as NPCCar
		configure_car(instance, current_lane)

		# connect to the car's signals, to delete the car once it's emitted and report crashes
		instance.destination_reached.connect(delete_car)
		instance.collision_detected.connect(_on_npc_car_collision_detected)
		add_child(instance)

		# update tracking variables
		alive_cars = alive_cars + 1
		time_since_last_spawn = 0
		last_lane = current_lane

## Configure the spawned NPCCar's parameters.
func configure_car(car: NPCCar, lane: int) -> void:
	# first wave of parameters: basic assignment ones
	car.STEER_SPEED = STEER_SPEED
	car.STEER_LIMIT = STEER_LIMIT
	car.engine_force_value = engine_force_value
	car.STEERING_WHEEL_ROTATION = STEERING_WHEEL_ROTATION
	car.STEERING_WHEEL_SMOOTHNESS = STEERING_WHEEL_SMOOTHNESS
	car.COLOUR = colours[randi()%colours.size()]

	car.speed_limit = speed_limit
	car.target_radius = target_radius
	car.target_range = target_range
	car.steer_power = steer_power
	car.detection_distance = detection_distance

	# second wave: define the more complex stuff (destination, rotation, lane)
	# set the rotation based on the value of spawn_direction
	car.rotation = set_initial_rotation()

	# modify the car's start position & destination based on facing direction and chosen lane
	# if spawn_direction is even (facing Z), move along X dimension
	# if spawn_direction is odd (facing X), move along Z dimension
	car.destinations.clear()
	if (spawn_direction % 2 == 0):
		car.position = Vector3(car.position.x + (lane_distance * lane), car.position.y, car.position.z)
		car.destinations.append(Vector3(destination.x + (lane_distance * lane), destination.y, destination.z))
	else:
		car.position = Vector3(car.position.x, car.position.y, car.position.z + (lane_distance * lane))
		car.destinations.append(Vector3(destination.x, destination.y, destination.z + (lane_distance * lane)))

	# if the weather of the global scene is night or fog; enable the car's headlights
	# (trying to avoid a crash if time and weather haven't been configured)
	if (Globals.scenario_data["TimeOfDay"]):
		if (Globals.scenario_data["TimeOfDay"] == "Night" or Globals.scenario_data["Weather"] == "Fog"):
			car.toggle_headlights()

## Removes a car from memory (and from the controller's counter).
func delete_car(car: NPCCar) -> void:
	car.queue_free()
	alive_cars = alive_cars - 1

## Returns a Vector3 representing the direction the car should be facing when spawned.
func set_initial_rotation() -> Vector3:
	# since each direction's degrees is a multiple of 90 (or pi/2 radians);
	return Vector3(0, spawn_direction * (PI/2), 0)

## Adds all NPCCars in the scene to the TrafficController when called.
func add_other_cars() -> void:
	# get everything in the npc_cars group
	var cars = get_tree().get_nodes_in_group('npc_cars')
	for car in cars:
		# add the car to our count and connect to their signals
		alive_cars = alive_cars + 1
		car.destination_reached.connect(delete_car)
		car.collision_detected.connect(_on_npc_car_collision_detected)

## Spawns a round of initial traffic whilst the controller starts building up its main traffic.
func spawn_initial_traffic() -> void:
	# one car for each row and lane position
	# god i wish i had regular for loops
	var i = 0
	#lanes already have a column (lane) offset system, but implement a row offset system for this
	var row_offset = -0
	
	while i < rows:
		var j = 0
		while j < lane_count:
			# roll to see if we can generate a car here
			var chance = randf()
			if chance < spawn_chance:
				#spawn and configure the car
				var instance = npc_car.instantiate() as NPCCar
				configure_car(instance, j)	# j is the lane being spawned down
				instance.destination_reached.connect(delete_car)
				instance.collision_detected.connect(_on_npc_car_collision_detected)
				add_child(instance)
				alive_cars = alive_cars + 1
				#override the start provided by configure_car() to account for row_offset
				if (spawn_direction % 2 == 0):
					instance.position = Vector3(instance.position.x, instance.position.y, instance.position.z + row_offset)
				else:
					instance.position = Vector3(instance.position.x + row_offset, instance.position.y, instance.position.z)
			j = j + 1
		row_offset = row_offset - 20
		i = i + 1

## An NPCCar has crashed in Lego City, use the TrafficController to report the incident.
## Done here instead of there in the aim of having npc_car focussed on driving the car and this focussed on the logic.
func _on_npc_car_collision_detected() -> void:
	UserData.crashed()
