extends Node

var audioPath = ""
var textPath = ""

var notes = []
var note_index = 0
var timer:float = 0
func _process(delta):
	if !SoundSpaceReborn.playing: return
	timer = SoundSpaceReborn.timer
	$MSIndicator.text = str(floor(timer * 1000.0)) + " ms"
	if note_index + 1 > len(notes): return
	var current_note:Dictionary = notes[note_index]
	if  timer * 1000.0 > current_note["ms"]:
		print("Current MS: " + str(timer * 1000.0) + " | Note MS: " + str(current_note["ms"]) + " | Note X: " + str(current_note["x"]) + " | Note Y: " + str(current_note["y"]) + " | Note Index: " + str(note_index))
		note_index += 1

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_K:
			get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _on_text_file_dialog_file_selected(path):
	$TextFileDialogPath.text = path
	textPath = path

func _on_text_file_dialog_button_pressed():
	$TextFileDialog.popup_centered(Vector2(get_window().size.x / 2.0, get_window().size.y / 2.0))

func _on_audio_file_dialog_button_pressed():
	$AudioFileDialog.popup_centered(Vector2(get_window().size.x / 2.0, get_window().size.y / 2.0))

func _on_audio_file_dialog_file_selected(path):
	$AudioFileDialogPath.text = path
	audioPath = path

func _on_button_pressed():
	text_stuff()
	audio_stuff()
	SoundSpaceReborn.playing = true

func text_stuff():
	if textPath != "":
		var f = FileAccess.open(textPath, FileAccess.READ)
		var splitText = f.get_as_text().split("Ξζξ")
		var jsonText = JSON.parse_string(splitText[0])
		$TextFileLabel.text = jsonText["name"] + ", " + jsonText["artist"] + ", " + jsonText["mapper"] + "\nThere are " + str(splitText.size()) + " notes in this map\n" + splitText[2]
	
		var map_data = splitText[1].split("ξζΞ")
		SoundSpaceReborn.current_map = map_data
		print(SoundSpaceReborn.current_map)
		for i in len(map_data):
			var note_data = JSON.parse_string(map_data[i])
			notes.append(note_data)

func audio_stuff():
	if audioPath != "":
		var Sound = load(audioPath)
		if !$AudioStreamPlayer2D.is_playing():
			$AudioStreamPlayer2D.stream = Sound
			$AudioStreamPlayer2D.play()
