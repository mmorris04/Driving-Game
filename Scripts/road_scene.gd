# road_scene.gd
extends Node3D
@onready var road_scene: PackedScene = load("res://Scenes/road_scene.tscn")
var scenarioData = Globals.scenario_data
@export var num_segments := 60
@export var segment_length := 25

func _ready():
	for i in range(num_segments):
		var segment = road_scene.instantiate()
		
		if(i > 6): #slip road no longer adds width
			segment.transform.origin.x = 9
		elif(i > 0): #slip road no longer adds width
			segment.transform.origin.x = 5

		var leftLightToggle = segment.get_node("LeftLight/LStreetlight/SpotLight3D")
		leftLightToggle.visible = scenarioData["TimeOfDay"] == "Night" or scenarioData["TimeOfDay"] == "Dusk"
			
		segment.transform.origin.z = (-i * segment_length)
		add_child(segment)
