extends Node

func load_maps():
	SSR.maps = []
	
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

func _process(delta):
	await load_maps()
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
