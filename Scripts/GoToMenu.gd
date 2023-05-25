extends Node

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_K:
				get_tree().change_scene_to_file("res://Scenes/ConvertMenu.tscn")
			if event.keycode == KEY_L:
				get_tree().change_scene_to_file("res://Scenes/Game.tscn")

func _ready():
	print(len(SSR.maps))
