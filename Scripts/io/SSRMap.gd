extends Node
const data_separator = "Ξζξ"
const note_separator = "ξζΞ"

func convert_txt_audio(txt_data, audio_path, title, artist, mapper, id):
	var output = FileAccess.open("user://maps/%s.ssrmap" % id, FileAccess.WRITE)
	#output.store_8(1)
	
	var meta_ = {}
	meta_["name"] = title
	meta_["artist"] = artist
	meta_["mapper"] = mapper
	meta_["id"] = id
	output.store_string(JSON.stringify(meta_))
	
	output.store_string(data_separator)
	
	for i in txt_data.split(",").slice(1):
		var note_data = i.replace("\r", "").replace("\n", "").split("|")
		var current_note = {"ms": int(note_data[2]), "x": float(note_data[0]), "y": float(note_data[1])}
		output.store_string(JSON.stringify(current_note))
		output.store_string(note_separator)
	
	output.store_string(data_separator)
	
	var audio_bytes = FileAccess.get_file_as_bytes(audio_path)
	output.store_buffer(audio_bytes)
