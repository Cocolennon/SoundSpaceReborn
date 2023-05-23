extends Node

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_K:
			var map_dir = DirAccess.open("user://maps")
			if !map_dir:
				var user_dir = DirAccess.open("user://")
				user_dir.make_dir("maps")
			get_tree().change_scene_to_file("res://Scenes/ConvertMenu.tscn")

func _on_sprite_3d_ready():
	var posIteration = 0
	while true:
		if posIteration <= 75:
			$Sprite3D.position += Vector3(0,0,0.005)
			posIteration += 1
			await get_tree().create_timer(0.0025).timeout
		else:
			$Sprite3D.position -= Vector3(0,0,0.005)
			posIteration += 1
			await get_tree().create_timer(0.0025).timeout
			if posIteration == 150: posIteration = 0
