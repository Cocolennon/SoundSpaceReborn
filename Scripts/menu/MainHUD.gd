extends Node

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
