extends Node

var current_map = {}
var playing:bool = false

var timer:float = 0
func _process(delta):
	if !playing: return
	timer += delta
