extends Node

var unconverted = []

func load_sspms():
	var maps = DirAccess.open("user://maps")
	var files = maps.get_files()
	for file_path in files:
		if not file_path.ends_with(".sspm"):
			print(file_path + " is not an SSP map!")
			return
		SSPMConversion.sspm_to_ssrmap(unconverted, file_path)

func load_maps():
	SSR.maps = []
	
	load_sspms()
	for i in unconverted:
		SSRMap.sspm_to_ssrmap(i.path, i.data)
	unconverted = []
	
	var map_dir = DirAccess.open("user://maps")
	if map_dir:
		var files = map_dir.get_files()
		for map_path in files:
			if not map_path.ends_with(".ssrmap"):
				map_dir.get_next()
				continue
			await SSRMap.load_from_path(map_path)
	else:
		var user_dir = DirAccess.open("user://")
		user_dir.make_dir("maps")

func _process(_delta):
	await load_maps()
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
