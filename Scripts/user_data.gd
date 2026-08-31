extends Node3D

@export var next_scene_path: String = "res://Scenes/menus.tscn"

var userData := {
	"Mirrors":[],
	"Signal":"",
	"Collisions":0
}

func reset() -> void:
	userData = {
		"Mirrors":[],
		"Signal":"",
		"Collisions":0
	}

func mirrorChecked(mirror: String) -> void:
	if(userData["Mirrors"].find(mirror)==-1):
		userData["Mirrors"].append(mirror)

func signaled(signalDir: String) -> void:
	userData["Signal"] = signalDir

# Logging when the user has crashed into an NPCCar.
func crashed() -> void:
	userData["Collisions"] = userData["Collisions"]+1
	get_tree().change_scene_to_file.call_deferred(next_scene_path) # Ending scenario, results page and data logging

func _ready() -> void:
	reset()

func appendJsonFile(userResults) -> void:
	var dataEntry := {
		"Participant": str(Globals.participant_number),
		"Timestamp": Time.get_unix_time_from_system(),
		"Scenario": Globals.scenario_data["ID"],
		"Result":{
			"Mirrors":"Pass",
			"Signal":"Pass",
			"Collisions":"Pass"
		},
		"ResultDetails":{
			"Mirrors": userData["Mirrors"],
			"Signal": userData["Signal"]
		}
	}
	if(userResults["Mirrors"]=="Fail"):
		dataEntry["Result"]["Mirrors"] = "Fail"
	if(userResults["Signal"]=="Fail"):
		dataEntry["Result"]["Signal"] = "Fail"
	if(userResults["Collisions"]=="Fail"):
		dataEntry["Result"]["Collisions"] = "Fail"
	
	
	# Appending to JSON file for logging
	var existing = []
	#var path = "/sdcard/Android/data/com.example.drivinggame/files/userdata.json" # For VR
	var path = "user://userdata.json" # For PC

	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(parsed) == TYPE_ARRAY:
			existing = parsed

	existing.append(dataEntry)
	
	var file_w = FileAccess.open(path, FileAccess.WRITE_READ)
	file_w.store_string(JSON.stringify(existing, "\t"))
	file_w.close()
	print("Resolved file path: ", OS.get_user_data_dir())
