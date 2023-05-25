extends Node

func _ready():
	$AudioStream.stream = SSR.current_map.audio_stream
	$AudioManager.play($AudioStream)
