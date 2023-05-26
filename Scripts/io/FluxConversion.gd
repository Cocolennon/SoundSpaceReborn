extends Node

var meta = {}
var audio_stream: AudioStream
var notes = {}
var flux_separator = "Ξζξ"

var combined_map_data = {}

func flux_to_ssrmap(unconverted, map_path):
	var map_file = FileAccess.get_file_as_string("user://maps/%s" % map_path)
	var map_data = map_file.substr(1).split(flux_separator)
	
	var file = FileAccess.open("user://maps/%s" % map_path, FileAccess.READ)
	var version = file.get_8()
	if version != 2:
		push_error("Invalid Flux map version")
		return
	file.close()

	var file_bytes = FileAccess.get_file_as_bytes("user://maps/%s" % map_path)
	
	meta = JSON.parse_string(map_data[0])
	
	notes = JSON.parse_string(map_data[1])
	
	var audio_bytes = file_bytes.slice(get_start_of_audio_buffer(map_file))
	var format = SSR.get_audio_format(audio_bytes)
	match format:
		SSR.AudioFormat.WAV:
			print("Map %s has a WAVE Audio File" % map_path)
			print("Maps with WAVE Audio Files are not supported yet.")
			return
#			audio_stream = AudioStreamWAV.new()
#			audio_stream.data = audio_bytes
		SSR.AudioFormat.OGG:
			print("Map %s has an OGG Audio File" % map_path)
			audio_stream = AudioStreamOggVorbis.new()
			audio_stream.packet_sequence = SSR.get_ogg_packet_sequence(audio_bytes)
		SSR.AudioFormat.MP3:
			print("Map %s has an MP3 Audio File" % map_path)
			audio_stream = AudioStreamMP3.new()
			audio_stream.data = audio_bytes
		_:
			print("File: %s, Invalid format. Magic: %s" % [map_path, audio_bytes.slice(0,3)])
			return
	
	combined_map_data = {
		"map_data": meta,
		"notes": notes,
		"audio_stream": audio_stream,
		"audio_buffer": audio_bytes,
	}
	unconverted.append({"path": map_path, "data": combined_map_data})

func get_start_of_audio_buffer(f_txt: String):
	var a = f_txt.find(flux_separator)
	var b = f_txt.find(flux_separator, a + 1)
	var c = f_txt.find(flux_separator, b + 1)
	return c + 12
