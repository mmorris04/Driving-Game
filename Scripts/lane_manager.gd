extends Node

@export var motorway_path: NodePath
@onready var car: Node3D = $"../PlayerCar".get_node("car")

var motorway: Node
var lane_curve: Curve3D
var path_follow: PathFollow3D 

const LANE_WIDTH := 3.6
const REQUIRE_WITHIN := 3.0

@onready var last_lane := "Slip"
@onready var current_lane := "Slip"

var mirror_recent := false
var signal_recent := false
var mirror_timer := 0.0
var signal_timer := 0.0

var recent_mirrors := []

func _ready():
	# Get motorway
	motorway = get_node(motorway_path)
	
	# Get lane Path3D inside motorway
	var lane_node: Path3D = motorway.get_node("RoadManager/Forward Road/Node3D/MidLane") as Path3D
	if not lane_node:
		push_error("LeftLane Path3D not found!")
		return
	
	lane_curve = lane_node.curve
	lane_curve.bake_interval = 0.5
	
	path_follow = PathFollow3D.new()
	lane_node.add_child(path_follow)
	
func notify_mirror_check(mirror_name):
	mirror_recent = true
	mirror_timer = REQUIRE_WITHIN
	
	if mirror_name not in recent_mirrors:
		recent_mirrors.append(mirror_name)

func notify_signal_used():
	signal_recent = true
	signal_timer = REQUIRE_WITHIN

func _process(delta):
	# Update timers
	mirror_timer = max(mirror_timer - delta, 0.0)
	if mirror_timer == 0.0:
		mirror_recent = false
		recent_mirrors.clear()
	
	signal_timer = max(signal_timer - delta, 0.0)
	if signal_timer == 0.0:
		signal_recent = false

	var offset = get_car_offset(car.global_position)
	#print("Car offset from path center: ", offset) 
	
	current_lane = get_current_lane(offset)

	# Lane change detection
	if current_lane != last_lane: 
		_on_lane_changed(current_lane, last_lane)
		last_lane = current_lane

func get_car_offset(car_pos: Vector3) -> float:
	# Simple X offset if road is along Z
	var path_center = path_follow.global_position   
	var offset = car_pos.x - path_center.x
	return offset
 

func get_current_lane(offset: float) -> String:
	if offset < -LANE_WIDTH - 4:
		return "Slip"
	elif offset < -LANE_WIDTH / 2.0:
		return "Left" 
	elif offset < LANE_WIDTH / 2.0:
		return "Mid"   
	else:
		return "Right" 

func _on_lane_changed(new_lane, old_lane):
	var valid := true
	
	if not mirror_recent:
		valid = false
		print("Didnt check mirrors")
	
	if not signal_recent:
		valid = false
		print("Didnt signal")
	
	for mirror_name in recent_mirrors:
		UserData.mirrorChecked(mirror_name)
		
	recent_mirrors.clear()
	print("Merge")
	
	mirror_recent = false
	signal_recent = false
