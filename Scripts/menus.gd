extends Node3D

@onready var main_menu_2d = $MainMenuViewport
@onready var welcome_page_2d = $WelcomePageViewport
@onready var number_pad_2d = $NumberPadViewport
@onready var participant_number_2d = $ParticipantNumberViewport
@onready var result_page_2d = $ResultsPageViewport
@onready var controls_page_2d = $ControlsPageViewport

var scenarios = {
	"Scenario 1": {"ID": "1", "TimeOfDay":"Day", "Weather":"Clear",
	 "Answer":{"Mirrors":["Rear", "Right"], "Signal":"Right"}},
	"Scenario 2": {"ID": "2", "TimeOfDay":"Night", "Weather":"Rain", 
	 "Answer":{"Mirrors":["Rear", "Right"], "Signal":"Right"}},
	"Scenario 3": {"ID": "3", "TimeOfDay":"Dusk", "Weather":"Fog", 
	 "Answer":{"Mirrors":["Rear", "Right"], "Signal":"Right"}}
}

var main_menu_ui
var welcome_ui
var number_pad_ui
var participant_number_ui
var result_page_ui
var controls_page_ui

#var settings_ui

var interface: XRInterface

func _pad_button_pressed(num: int):
	Globals.participant_number = int(str(Globals.participant_number) + str(num))
	participant_number_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/TextEdit").text = str(Globals.participant_number)
	
func _on_backspace_pressed():
	Globals.participant_number = 0 if Globals.participant_number == 0 else int(str(Globals.participant_number).substr(0, str(Globals.participant_number).length() - 1))
	participant_number_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/TextEdit").text = str(Globals.participant_number)

func _toggle_number_pad(new: bool):
	number_pad_2d.visible = new
	
func _ready():
	# prepare the Xr
	interface = XRServer.find_interface("OpenXR")
	
	if interface and interface.is_initialized():
		get_viewport().use_xr = true    # for a headset
		
		print("OpenXR initialised successfully")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	else:
		print("OpenXR not initialised")
			
	
	# Get the actual 2D scene instances from each Viewport2Din3D
	main_menu_ui = main_menu_2d.get_scene_instance()
	welcome_ui = welcome_page_2d.get_scene_instance()
	number_pad_ui = number_pad_2d.get_scene_instance()
	participant_number_ui = participant_number_2d.get_scene_instance()
	result_page_ui = result_page_2d.get_scene_instance()
	controls_page_ui = controls_page_2d.get_scene_instance()
	
	
	var grid = number_pad_ui.get_node("Control/ColorRect/MarginContainer/GridContainer")
	for button in grid.get_children():
		if button.has_signal("pressed"):
			button.pressed.connect(_pad_button_pressed.bind(int(button.text)))
	_toggle_number_pad(true)
	
	# Set initial visibility
	if Globals.participant_number == 0:
		_show_menu("participant_number")
	else:
		loadResultsPage() # Updating with global user data
		_show_menu("results")
	
	# Connect signals from the actual 2D UIs
	# deal with participant number ui text edit (
	number_pad_ui.get_node("Control/ColorRect/Delete").pressed.connect(_on_backspace_pressed)
	number_pad_ui.get_node("Control/ColorRect/Confirm").pressed.connect(_on_number_confirmed)
	main_menu_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Start").pressed.connect(_on_start_pressed)
	main_menu_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Controls").pressed.connect(_on_controls_pressed)
	main_menu_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Quit").pressed.connect(_on_quit_pressed)
	result_page_ui.get_node("Control/ColorRect/Continue").pressed.connect(_on_forward_pressed)

	controls_page_ui.get_node("Control/ColorRect/Back").pressed.connect(_on_back_welcome_pressed)
	welcome_ui.get_node("Control/ColorRect/Back").pressed.connect(_on_back_welcome_pressed)
	var button_template = welcome_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Scenario1")	
	_create_scenario_buttons(button_template)


func _show_menu(menu: String):
	main_menu_2d.visible = (menu == "main")
	welcome_page_2d.visible = (menu == "welcome")
	participant_number_2d.visible = (menu == "participant_number")
	controls_page_2d.visible = (menu == "controls")
	result_page_2d.visible = (menu == "results")
	
	if menu != "participant_number":
		_toggle_number_pad(false)

# Formatting arrays as strings
func arrayToString(array) -> String:
	var nString = ""
	for i in range(0,len(array)):
		if(i!=0 and (i+1)==len(array)):
			nString = nString+" & "
		elif(i!=0):
			nString = nString+", "
		nString = nString+array[i].to_lower()
	return nString

# Load results from data
func loadResultsPage():
	# Loading correct and user outcomes for comparison
	var correctSignal = String(Globals.scenario_data["Answer"]["Signal"]).to_lower()
	var userSignal = String(UserData.userData["Signal"]).to_lower()
	Globals.scenario_data["Answer"]["Mirrors"].sort()
	UserData.userData["Mirrors"].sort()
	var correctMirrors = Globals.scenario_data["Answer"]["Mirrors"]
	var userMirrors = UserData.userData["Mirrors"]
	var userCollisions = UserData.userData["Collisions"]
	
	# Data for logging
	var signalResult = "Pass"
	var mirrorsResult = "Pass"
	var collisionsResult = "Pass"
	
	# Intially setting outcomes to pass
	result_page_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Mirrors/Result").texture = load("res://icons/passIcon.png")
	result_page_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Mirrors/Description").text = "Correctly checked your "+arrayToString(correctMirrors)+" mirror(s)"
	result_page_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Signalling/Result").texture = load("res://icons/passIcon.png")
	result_page_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Signalling/Description").text = "Correctly signalled "+correctSignal
	result_page_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Collisions/Result").texture = load("res://icons/passIcon.png")
	result_page_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Collisions/Description").text = "No collisions"
	
	# Checking collisions
	if(userCollisions!=0):
		collisionsResult = "Fail"
		result_page_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Collisions/Result").texture = load("res://icons/failIcon.png")
		result_page_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Collisions/Description").text = "You had a collision!"
		
	# Checking signal
	if(correctSignal!=userSignal):
		signalResult = "Fail"
		result_page_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Signalling/Result").texture = load("res://icons/failIcon.png")
		if(userSignal==""):
			result_page_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Signalling/Description").text = "You forgot to signal!\nNeeded to signal "+correctSignal
		else:
			result_page_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Signalling/Description").text = "You signalled "+userSignal+"\nNeeded to signal "+correctSignal

	# Checking mirrors
	if(len(userMirrors)==0):
		mirrorsResult = "Fail"
		result_page_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Mirrors/Result").texture = load("res://icons/failIcon.png")
		result_page_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Mirrors/Description").text = "You forgot to check your mirrors!\nNeeded to check your "+arrayToString(correctMirrors)+" mirror(s)"
	else:
		var mirrors = {}
		for elem in userMirrors:
			mirrors[elem] = 1
		for elem in correctMirrors:
			if not(elem in mirrors):
				mirrorsResult = "Fail"
				result_page_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Mirrors/Result").texture = load("res://icons/failIcon.png")
				result_page_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/Mirrors/Description").text = "You checked your "+arrayToString(userMirrors)+" mirror(s)\nNeeded to check your "+arrayToString(correctMirrors)+" mirror(s)"
				break
	
	# Logging data to JSON file
	UserData.appendJsonFile({"Signal":signalResult, "Mirrors":mirrorsResult, "Collisions":collisionsResult})


# --- Button callbacks ---
func _on_start_pressed():
	_show_menu("welcome")

func _on_controls_pressed():
	_show_menu("controls")

func _on_quit_pressed():
	get_tree().quit()

func _create_scenario_buttons(button_template):
	var vbox = welcome_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer")

	for name in scenarios.keys():
		var scenario_data = scenarios[name]
		var new_button = button_template.duplicate()
		
		var label = new_button.get_node("ScenarioName")
		var description = new_button.get_node("ScenarioDescription")
		var icon = new_button.get_node("TextureRect")
		
		label.text = name
		description.text = "Time of Day: "+scenario_data.TimeOfDay+", Weather: "+scenario_data.Weather+"."
		
		new_button.visible = true
		vbox.add_child(new_button)

		new_button.pressed.connect(_on_scenario_pressed.bind(name))
	
	button_template.visible = false


func _on_scenario_pressed(name: String):
	var scenario_data = scenarios[name]
	# Store parameters globally
	Globals.scenario_data = scenario_data
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
	
func _on_back_welcome_pressed():
	_show_menu("main")
	
func _on_forward_pressed():
	_show_menu("main")

func _on_back_settings_pressed():
	_show_menu("main")


# virtual keyboard
func _on_key_pressed(value: String):
	get_parent()._vr_key_input(value)

func _vr_key_input(value: String):
	var edit = number_pad_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/TextEdit")
	edit.text += value
	edit.caret_position = edit.text.length()

func _vr_key_backspace():
	var edit = number_pad_ui.get_node("Control/ColorRect/MarginContainer/VBoxContainer/TextEdit")
	if edit.text.length() > 0:
		edit.text = edit.text.substr(0, edit.text.length() - 1)
		edit.caret_position = edit.text.length()

func _on_number_confirmed():
	_show_menu("main")
