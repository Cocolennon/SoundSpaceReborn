extends Node

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_K:
			get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn") #eea

func _opentxtfile_pressed():
	$TextFileDialog.popup_centered(Vector2(get_window().size.x / 2.0, get_window().size.y / 2.0))

func on_txtfiledialog_selected(path):
	var f = FileAccess.get_file_as_string(path)
	$MapTXTData.text = f

func _openaudiofile_pressed():
	$AudioFileDialog.popup_centered(Vector2(get_window().size.x / 2.0, get_window().size.y / 2.0))

func _on_audiofiledialog_selected(path):
	$AudioPath.text = path

func check_map_data(map_data: String):
	var splitted = map_data.split(",")
	if len(splitted) < 2:
		return false
	var splitted_noid = splitted.slice(1)
	for note in splitted_noid:
		var note_data = note.split("|")
		for nl in note_data:
			if not nl.is_valid_float() || not nl.is_valid_int():
				return false
		if len(note_data) != 3:
			return false
	return true


func _convert_pressed():
	if $MapTXTData.text == "":
		$MapTXTData.add_theme_color_override("font_placeholder_color", Color(1, 0, 0))
		return
	if !check_map_data($MapTXTData.text):
		$MapTXTData.add_theme_color_override("font_placeholder_color", Color(1, 0, 0))
		return
	if $AudioPath.text == "Select an audio file":
		$AudioPath.add_theme_color_override("font_color", Color(1, 0, 0))
		return
	if $MapName.text == "":
		$MapName.add_theme_color_override("font_placeholder_color", Color(1, 0, 0))
		return
	if $Artist.text == "":
		$Artist.add_theme_color_override("font_placeholder_color", Color(1, 0, 0))
		return
	if $ID.text == "":
		$ID.add_theme_color_override("font_placeholder_color", Color(1, 0, 0))
		return
	if $Mapper.text == "":
		$Mapper.add_theme_color_override("font_placeholder_color", Color(1, 0, 0))
		return
	
	SSRMap.convert_txt_audio($MapTXTData.text, $AudioPath.text, $MapName.text, $Artist.text, $Mapper.text, $ID.text)
