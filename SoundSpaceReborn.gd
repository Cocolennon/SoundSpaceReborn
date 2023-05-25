extends Node

var maps = []
var current_map = {}
var playing:bool = false

var timer:float = 0
func _process(delta):
	if !playing: return
	timer += delta
	
enum AudioFormat {
	OGG,
	WAV,
	MP3,
	UNKNOWN,
}

func get_ogg_packet_sequence(data:PackedByteArray):
	var packets = []
	var granule_positions = []
	var sampling_rate = 0
	var pos = 0
	while pos < data.size():
		var header = data.slice(pos, pos + 27)
		pos += 27
		if header.slice(0, 4) != "OggS".to_ascii_buffer():
			break

		var packet_type = header.decode_u8(5)
		var granule_position = header.decode_u64(6)

		granule_positions.append(granule_position)

		var segment_table_length = header.decode_u8(26)

		var segment_table = data.slice(pos, pos + segment_table_length)
		pos += segment_table_length

		var packet_data = []
		var appending = false
		for i in range(segment_table_length):
			var segment_size = segment_table.decode_u8(i)
			var segment = data.slice(pos, pos + segment_size)
			if appending: packet_data.back().append_array(segment)
			else: packet_data.append(segment)
			appending = segment_size == 255
			pos += segment_size

		packets.append(packet_data)
		if sampling_rate == 0 and packet_type == 2:
			var info_header = packet_data[0]
			if info_header.slice(1, 7).get_string_from_ascii() != "vorbis":
				break
			sampling_rate = info_header.decode_u32(12)
	var packet_sequence = OggPacketSequence.new()
	packet_sequence.sampling_rate = sampling_rate
	packet_sequence.granule_positions = granule_positions
	packet_sequence.packet_data = packets
	return packet_sequence

func get_audio_format(buffer:PackedByteArray):
	if buffer.slice(0,4) == PackedByteArray([0x4F,0x67,0x67,0x53]): return AudioFormat.OGG
	
	if (buffer.slice(0,4) == PackedByteArray([0x52,0x49,0x46,0x46])
	and buffer.slice(8,12) == PackedByteArray([0x57,0x41,0x56,0x45])): return AudioFormat.WAV
	
	if (buffer.slice(0,2) == PackedByteArray([0xFF,0xFB])
	or buffer.slice(0,2) == PackedByteArray([0xFF,0xF3])
	or buffer.slice(0,2) == PackedByteArray([0xFF,0xFA])
	or buffer.slice(0,2) == PackedByteArray([0xFF,0xF2])
	or buffer.slice(0,3) == PackedByteArray([0x49,0x44,0x33])): return AudioFormat.MP3

	return AudioFormat.UNKNOWN
