# road_scene.gd
extends Node3D
#@onready 
@export var num_segments := 60
@export var segment_length := 25
var scenarioData = Globals.scenario_data
var road_scene: PackedScene = load("res://Scenes/slip_road_scenery.tscn")

func _ready():

	for i in range(num_segments):	
		var segment = road_scene.instantiate()
		var rightLightToggle = segment.get_node("RightLight/RStreetlight/SpotLight3D")
		rightLightToggle.visible = scenarioData["TimeOfDay"] == "Night" or scenarioData["TimeOfDay"] == "Dusk"
		#segment.transform.origin.x = (-10*i)
		segment.transform.origin.z = (-i * segment_length)
		add_child(segment)
