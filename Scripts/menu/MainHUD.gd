extends Node

var map_data = []
var selected_map = {}

func _ready():
	map_list()

func _process(_d):
	for child in $MapList/MapListBackground/MapScroller/MapGrid.get_children():
		if child.name.begins_with("Map_"):
			child.visible = true

func _on_import_ssp_maps_pressed():
	$SSPDirectoryDialog.popup_centered(Vector2(get_window().size.x / 2.0, get_window().size.y / 1.25))

func _on_ssp_directory_dialog_dir_selected(dir):
	var sspmapsdir = DirAccess.open(dir + "/maps")
	if sspmapsdir:
		for i in sspmapsdir.get_files():
			if not i.ends_with(".sspm"): return
			var current_map_as_string = FileAccess.get_file_as_string(dir + "/maps/" + i)
			var map_copied_to_user = FileAccess.open("user://maps/" + i, FileAccess.WRITE)
			if map_copied_to_user:
				map_copied_to_user.store_string(current_map_as_string)
				print(i + " has been copied to SSR's maps folder")

func _on_reload_pressed():
	print("Reloading game")
	get_tree().change_scene_to_file("res://Scenes/Loading.tscn")

func map_list():
	print("Updating maps...")
	for child in $MapList/MapListBackground/MapScroller/MapGrid.get_children():
		if child.name.begins_with("Map_"):
			child.queue_free()
			if child in $MapList/MapListBackground/MapScroller/MapGrid.get_children():
				child.queue_free()
	map_data = []
	
	for map in SSR.maps:
		map_data.append(map)
	var i = 0
	for data in map_data:
		var button = $MapList/MapListBackground/MapScroller/MapGrid/Map_.duplicate()
		button.name = "Map_%d" % i
		button.visible = false
		button.update(data)
		i += 1
		$MapList/MapListBackground/MapScroller/MapGrid.add_child(button)

func _on_map__map_selected(map_data):
	selected_map = map_data

func _on_play_pressed():
	SSR.current_map = selected_map
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
