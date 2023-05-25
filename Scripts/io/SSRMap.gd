extends Node
const separator = "COOLSEPARATOR"

var audio_stream: AudioStream
var map_meta = {}
var notes = {}
var map_data = {}

func sspm_to_ssrmap(sspm, combined_map_data):
	var file = FileAccess.open("user://maps/%s.ssrmap" % combined_map_data.map_metadata.id, FileAccess.WRITE)
	print("Converting: %s" % sspm)
	file.store_8(1)
	file.store_string(JSON.stringify(combined_map_data.map_metadata))
	file.store_string(separator)
	file.store_string(JSON.stringify(combined_map_data.notes))
	file.store_string(separator)
	file.store_buffer(combined_map_data.audio_buffer)
	DirAccess.remove_absolute("user://maps/%s" % sspm)

func load_from_path(path):
	var map_file = FileAccess.get_file_as_string("user://maps/%s" % path)
	var map_file_data = map_file.substr(1).split(separator)
	var file = FileAccess.open("user://maps/%s" % path, FileAccess.READ)
	
	var version = file.get_8()
	if version != 1:
		push_error("Map isn't using latest version, not loading")
		return
	file.close()
	var file_bytes = FileAccess.get_file_as_bytes("user://maps/%s" % path)
	
	map_data = JSON.parse_string(map_file_data[0])
	notes = JSON.parse_string(map_file_data[1])
	
	var audio_bytes = file_bytes.slice(get_start_of_audio_buffer(map_file))
	var format = SSR.get_audio_format(audio_bytes)
	print(format)
	match format:
		SSR.AudioFormat.WAV:
			print("Map %s has a WAVE Audio File" % path)
			print("Maps with WAVE Audio Files are not supported yet.")
			return
#			audio_stream = AudioStreamWAV.new()
#			audio_stream.data = audio_bytes
		SSR.AudioFormat.OGG:
			print("Map %s has an OGG Audio File" % path)
			audio_stream = AudioStreamOggVorbis.new()
			audio_stream.packet_sequence = SSR.get_ogg_packet_sequence(audio_bytes)
		SSR.AudioFormat.MP3:
			print("Map %s has a MP3 Audio File" % path)
			audio_stream = AudioStreamMP3.new()
			audio_stream.data = audio_bytes
		_:
			print("File: %s, Invalid format. Magic: %s" % [path, audio_bytes.slice(0,3)])
			return
	
	map_data = {
		"map_data": map_data,
		"notes": notes,
		"audio_stream": audio_stream,
	}
	SSR.maps.append(map_data)

func convert_txt_audio(txt_data, audio_path, songname, artist, mapper, id):
	var output = FileAccess.open("user://maps/%s.ssrmap" % id, FileAccess.WRITE)
	output.store_8(1)
	
	var map_metadata = {}
	map_metadata["name"] = songname
	map_metadata["artist"] = artist
	map_metadata["mapper"] = mapper
	map_metadata["id"] = id
	output.store_string(JSON.stringify(map_metadata))
	
	output.store_string(separator)
	
	var notes_ = {}
	notes_["default"] = []
	
	for i in txt_data.split(",").slice(1):
		var note_data = i.replace("\r", "").replace("\n", "").split("|")
		notes_["default"].append({
			"x": float(note_data[0]),
			"y": float(note_data[1]),
			"ms": int(note_data[2]),
		})
	output.store_string(JSON.stringify(notes_))
	
	output.store_string(separator)
	
	var audio_bytes = FileAccess.get_file_as_bytes(audio_path)
	output.store_buffer(audio_bytes)

func get_start_of_audio_buffer(f_txt: String):
	var a = f_txt.find(separator)
	var b = f_txt.find(separator, a + 1)
	return b + 13
