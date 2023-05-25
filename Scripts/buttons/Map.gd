extends Node

signal map_selected(map_data)

var map_data = {}

func update(data):
	map_data = data
	
	if not data.map_data.artist == "":
		$Title.text = "%s - %s" % [data.map_data.artist, data.map_data.title]
	else:
		$Title.text = data.map_data.title
		
	$Mapper.text = "%s" % data.map_data.mapper
	$Length.text = SSR.get_map_len_str(data)

func _on_pressed():
	map_selected.emit(map_data)
