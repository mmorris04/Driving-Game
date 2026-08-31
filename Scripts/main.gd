extends Node3D

@onready var PlayerCar = $PlayerCar
@onready var Weather = $Weather
@onready var FinishArea = $FinishArea
var interface: XRInterface

var points: int = 0
	
var signalled = false
var checkedMirrors = false
var hitOtherCar = false
var finished = false
var setup = false
		
signal points_changed(new_value: int)


func add_points(amount: int):
	points += amount
	emit_signal("points_changed", points)

func get_points():
	return points  
	
func finish_area_entered():
	finished = true

func set_up_listeners():
	# connect to signal signal
	# connect to hit signal
	# connect to check mirrors signal
	
	setup = true
	
	pass
	
func _process(delta):
	if !setup:
		set_up_listeners()
		
	return
	
func _ready():
	# prepare the actual scenario
	points = 0
	
	# Reset user data
	UserData.reset()
	
	var scenarioData = Globals.scenario_data
	
	print("Currently loaded Scenario:", scenarioData)
	
	var WeatherNode = PlayerCar.get_node("car/RainParticles")
	
	WeatherNode.visible = scenarioData["Weather"] == "Rain"
	
	var sun = Weather.get_node("Sun")
	var moon = Weather.get_node("Moon")
	var environment = Weather.get_node("WorldEnvironment").environment
	
	if scenarioData["Weather"] == "Fog":
		environment.fog_enabled = true
		environment.fog_density = 0.005        # Increase if barely visible
		environment.fog_sky_affect = 1.0      # Sky fogging (optional)
		environment.fog_light_color = Color(1, 1, 1)


	var sky = environment.sky
	var material = sky.sky_material
		
	sun.visible = scenarioData["TimeOfDay"] == "Day"
	moon.visible = scenarioData["TimeOfDay"] == "Night"
	
	if material is ProceduralSkyMaterial:
		
		if scenarioData["TimeOfDay"] == "Night":
			material.energy_multiplier = 0.0 
			material.sky_energy_multiplier = 0.0
		else:
			material.energy_multiplier = 1.0 
			material.sky_energy_multiplier = 1.0
			

#	FinishArea.body_entered.connect(Callable(self, "finish_area_entered"))
#
	#while (!finished):
		#await get_tree().create_timer(1.0).timeout
			
	# deal with ending	
