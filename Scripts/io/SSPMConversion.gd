extends Node

class Map:
	enum Difficulty { # LEGACY SUPPORT
		UNKNOWN,
		EASY,
		MEDIUM,
		HARD,
		LOGIC,
		TASUKETE
	}

	const DifficultyNames = { # LEGACY SUPPORT
		Difficulty.UNKNOWN: "N/A",
		Difficulty.EASY: "Easy",
		Difficulty.MEDIUM: "Medium",
		Difficulty.HARD: "Hard",
		Difficulty.LOGIC: "Logic?!",
		Difficulty.TASUKETE: "Tasukete",
	}
	
	const LegacyCovers = { # LEGACY SUPPORT
		Difficulty.UNKNOWN: null,
		Difficulty.EASY: null,
		Difficulty.MEDIUM: null,
		Difficulty.HARD: null,
		Difficulty.LOGIC: null,
		Difficulty.TASUKETE: null,
	}
	var unsupported:bool = false
	
	var notes:Array
	var data:Dictionary
	var name: String
	var creator: String
	var id: String
	var broken: bool
	
	class Note:
		var index:int
		var x:float
		var y:float
		var time:float
		var data:Dictionary = {}

class Mapset:
	var format:int
	var song:String
	var path:String
	var id: String
	var name: String
	var broken: bool
	var creator: String
	var cover:Texture
	var audio:AudioStream
	var audio_buffer: PackedByteArray
	var maps:Array

const SIGNATURE:PackedByteArray = [0x53,0x53,0x2b,0x6d]

func sspm_to_ssrmap(unconverted:Array, path:String):
	var mapset = read_from_file(path)
	var maps = []
	
	var combined_map_data = {
		"map_metadata": {
			"artist": "",
			"title": mapset.name,
			"mapper": mapset.creator,
			"id": mapset.id,
		},
		"notes": {
			"default": []
		},
		"audio_stream": mapset.audio,
		"audio_buffer": mapset.audio_buffer,
	}
	print("parsing: {ver: ", mapset.format, ", name: \"", mapset.name, "\", mapper: \"", mapset.creator, ", broken: ", mapset.broken, "}")
	if mapset.broken: return
	for note in mapset.maps[0].notes:
		combined_map_data.notes.default.append({"ms": note.time * 1000.0, "x": note.x, "y": note.y})
	unconverted.append({"path": path, "data": combined_map_data})

static func read_from_file(path:String,full:bool=false,index:int=0) -> Mapset:
	var file = FileAccess.open("user://maps/%s" % path,FileAccess.READ)
	assert(file != null)
	assert(file.get_buffer(4) == SIGNATURE)
	var mset = Mapset.new()
	var file_version = file.get_16()
	mset.path = path
	mset.format = file_version
	match file_version:
		1: _sspmv1(file,mset,full)
		2: _sspmv2(file,mset,full)
		3: _sspmv3(file,mset,full,index)
	return mset

static func _sspmv3(file:FileAccess,mset:Mapset,full:bool,index:int=-1):
	file.seek(file.get_position()+2)

	# Metadata
	var id = FileAccess.get_md5(file.get_path())
	mset.id = id
	var online_id_length = file.get_8() # Online ID
	if online_id_length > 0: mset.online_id = file.get_buffer(online_id_length).get_string_from_ascii()
	var name_length = file.get_16() # Map name
	mset.name = file.get_buffer(name_length).get_string_from_utf16()
	var creator_length = file.get_16() # Map creator
	mset.creator = file.get_buffer(creator_length).get_string_from_utf16()

	# Audio
	var audio_length = file.get_64()
	if audio_length > 1:
		var audio_buffer = file.get_buffer(audio_length)
		_audio(audio_buffer,mset)
	else:
		mset.broken = true

	# Cover
	var cover_width = file.get_16()
	if cover_width > 1:
		var cover_height = file.get_16()
		var cover_length = file.get_64()
		var cover_buffer = file.get_buffer(cover_length)
		var image = Image.create_from_data(cover_width,cover_height,false,Image.FORMAT_RGBA8,cover_buffer)
		_cover(image,mset)
	else:
		mset.broken = true

	# Data
	var indexed = index != -1
	var map_count = file.get_8()
	mset.maps = []
	mset.maps.resize(map_count)
	for i in range(map_count):
		print("Reading map %s from mapset" % i)
		var map = Map.new()
		var dname_length = file.get_16()
		map.name = file.get_buffer(dname_length).get_string_from_utf16()
		var data_length = file.get_64()
		var data = file.get_buffer(data_length).get_string_from_utf8()
		if full and (!indexed or index == i):
			var hash_ctx = HashingContext.new()
			hash_ctx.start(HashingContext.HASH_MD5)
			map.id = hash_ctx.finish().hex_encode()
			deserialise_v3_data(data,map)
		mset.maps[i] = map
static func deserialise_v3_data(data:String,map:Map):
	var parsed = JSON.parse_string(data)
	if parsed.get("version",1) > 1:
		map.unsupported = true
	map.notes = []
	for note_data in parsed.get("notes",[]):
		var note = Map.Note.new()
		note.index = note_data.index
		note.x = note_data.position[0]
		note.y = note_data.position[1]
		note.time = note_data.time
		note.data = note_data
		map.notes.append(note)
	map.data = parsed

static func _cover(image:Image,mset:Mapset):
	var texture = ImageTexture.create_from_image(image)
	mset.cover = texture

static func _audio(buffer:PackedByteArray,mset:Mapset):
	var format = SSR.get_audio_format(buffer)
	match format:
		SSR.AudioFormat.WAV:
			print("Maps with WAVE Audio Files are not supported yet.")
			return
#			var stream = AudioStreamWAV.new()
#			stream.data = buffer
#			set.audio = stream
		SSR.AudioFormat.OGG:
			var stream = AudioStreamOggVorbis.new()
			stream.packet_sequence = SSR.get_ogg_packet_sequence(buffer)
			mset.audio = stream
		SSR.AudioFormat.MP3:
			var stream = AudioStreamMP3.new()
			stream.data = buffer
			mset.audio = stream
		_:
			print("Format not recognised %s" % buffer.slice(0,3))
			mset.broken = true
	mset.audio_buffer = buffer

static func _sspmv1(file:FileAccess,mset:Mapset,full:bool):
	file.seek(file.get_position()+2) # Header reserved space or something
	var map = Map.new()
	mset.maps = [map]
	mset.id = file.get_line()
	map.id = mset.id
	mset.name = file.get_line()
	mset.song = mset.name
	mset.creator = file.get_line()
	map.creator = mset.creator
	file.seek(file.get_position()+4) # skip last_ms
	var note_count = file.get_32()
	var difficulty = file.get_8()
	map.name = Map.DifficultyNames[difficulty]
	# Cover
	var cover_type = file.get_8()
	match cover_type:
		1:
			var height = file.get_16()
			var width = file.get_16()
			var mipmaps = bool(file.get_8())
			var format = file.get_8()
			var length = file.get_64()
			var image = Image.create_from_data(width,height,mipmaps,format,file.get_buffer(length))
			_cover(image,mset)
		2:
			var image = Image.new()
			var length = file.get_64()
			image.load_png_from_buffer(file.get_buffer(length))
			_cover(image,mset)
		_:
			mset.cover = Map.LegacyCovers.get(difficulty)
	if file.get_8() != 1: # No music
		mset.broken = true
		return
	var music_length = file.get_64()
	var music_buffer = file.get_buffer(music_length)
	var music_format = SSR.get_audio_format(music_buffer)
	if music_format == SSR.AudioFormat.UNKNOWN:
		mset.broken = true
	else:
		_audio(music_buffer,mset)
	if not full: return
	map.notes = []
	for i in range(note_count):
		var note = Map.Note.new()
		note.time = float(file.get_32())/1000
		if file.get_8() == 1:
			note.x = file.get_float()
			note.y = file.get_float()
		else:
			note.x = float(file.get_8())
			note.y = float(file.get_8())
		map.notes.append(note)
	map.notes.sort_custom(func(a,b): return a.time < b.time)
	for i in range(map.notes.size()):
		map.notes[i].index = i

static func _read_data_type(file:FileAccess,skip_type:bool=false,skip_array_type:bool=false,type:int=0,array_type:int=0):
	if !skip_type:
		type = file.get_8()
	match type:
		1: return file.get_8()
		2: return file.get_16()
		3: return file.get_32()
		4: return file.get_64()
		5: return file.get_float()
		6: return file.get_real()
		7:
			var value:Vector2
			var t = file.get_8()
			if t == 0:
				value = Vector2(file.get_8(),file.get_8())
				return value
			value = Vector2(file.get_float(),file.get_float())
			return value
		8: return file.get_buffer(file.get_16())
		9: return file.get_buffer(file.get_16()).get_string_from_utf8()
		10: return file.get_buffer(file.get_32())
		11: return file.get_buffer(file.get_32()).get_string_from_utf8()
		12:
			if !skip_array_type:
				array_type = file.get_8()
			var array = []
			array.resize(file.get_16())
			for i in range(array.size()):
				array[i] = _read_data_type(file,true,false,array_type)
			return array
static func _sspmv2(file:FileAccess,mset:Mapset,_full:bool):
	var map = Map.new()
	mset.maps = [map]
	file.seek(0x26)
	var marker_count = file.get_32()
	var difficulty = file.get_8()
	map.name = Map.DifficultyNames[difficulty]
	file.get_16()
	if !bool(file.get_8()): # Does the map have music?
		map.broken = true
		return
	var cover_exists = bool(file.get_8())
	file.seek(0x40)
	var audio_offset = file.get_64()
	var audio_length = file.get_64()
	var cover_offset = file.get_64()
	var cover_length = file.get_64()
	var marker_def_offset = file.get_64()
	file.seek(0x70)
	var markers_offset = file.get_64()
	file.seek(0x80)
	mset.id = file.get_buffer(file.get_16()).get_string_from_utf8()
	map.id = mset.id
	mset.name = file.get_buffer(file.get_16()).get_string_from_utf8()
	mset.song = file.get_buffer(file.get_16()).get_string_from_utf8()
	mset.creator = ""
	for i in range(file.get_16()):
		var creator = file.get_buffer(file.get_16()).get_string_from_utf8()
		if i != 0:
			mset.creator += " & "
		mset.creator += creator
	map.creator = mset.creator
	for i in range(file.get_16()):
		var key_length = file.get_16()
		var key = file.get_buffer(key_length).get_string_from_utf8()
		var value = _read_data_type(file)
		if key == "difficulty_name" and typeof(value) == TYPE_STRING:
			map.name = str(value)
	# Cover
	if cover_exists:
		file.seek(cover_offset)
		var image = Image.new()
		image.load_png_from_buffer(file.get_buffer(cover_length))
		_cover(image,mset)
	else:
		mset.cover = Map.LegacyCovers.get(difficulty)
	# Audio
	file.seek(audio_offset)
	_audio(file.get_buffer(audio_length),mset)
#	if not full: return
	# Markers
	file.seek(marker_def_offset)
	var markers = {}
	var types = []
	for _i in range(file.get_8()):
		var type = []
		types.append(type)
		type.append(file.get_buffer(file.get_16()).get_string_from_utf8())
		markers[type[0]] = []
		var count = file.get_8()
		for _o in range(1,count+1):
			type.append(file.get_8())
		file.get_8()
	file.seek(markers_offset)
	for _i in range(marker_count):
		var marker = []
		var ms = file.get_32()
		marker.append(ms)
		var type_id = file.get_8()
		var type = types[type_id]
		for i in range(1,type.size()):
			var data_type = type[i]
			var v = _read_data_type(file,true,false,data_type)
			marker.append_array([data_type,v])
		markers[type[0]].append(marker)
	if !markers.has("ssp_note"):
		map.broken = true
		return
	map.notes = []
	for note_data in markers.get("ssp_note"):
		if note_data[1] != 7: continue
		var note = Map.Note.new()
		note.time = float(note_data[0])/1000
		note.x = note_data[2].x
		note.y = note_data[2].y
		map.notes.append(note)
	map.notes.sort_custom(func(a,b): return a.time < b.time)
	for i in range(map.notes.size()):
		map.notes[i].index = i
