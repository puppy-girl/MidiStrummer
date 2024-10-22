extends Node
class_name MidiStrummer

# [string, fret]
var pitch_to_fret = {
	40: [0, 0],
	41: [0, 1],
	42: [0, 2],
	43: [0, 3],
	44: [0, 4],
	45: [1, 0],
	46: [1, 1],
	47: [1, 2],
	48: [1, 3],
	49: [1, 4],
	50: [2, 0],
	51: [2, 1],
	52: [2, 2],
	53: [2, 3],
	54: [2, 4],
	55: [3, 0],
	56: [3, 1],
	57: [3, 2],
	58: [3, 3],
	59: [4, 0],
	60: [4, 1],
	61: [4, 2],
	62: [4, 3],
	63: [4, 4],
	64: [5, 0],
	65: [5, 1],
	66: [5, 2],
	67: [5, 3],
	68: [5, 4],
	69: [5, 5],
	70: [5, 6],
	71: [5, 7],
	72: [5, 8],
	73: [5, 9],
	74: [5, 10],
	75: [5, 11],
	76: [5, 12],
	77: [5, 13],
	78: [5, 14],
	79: [5, 15],
	80: [5, 16]
}

# [msec, fret]
var last_strum = {
	0: [0, 0],
	1: [0, 0],
	2: [0, 0],
	3: [0, 0],
	4: [0, 0],
	5: [0, 0]
}

func _ready():
	print("MidiStrummer: _ready()")

	OS.open_midi_inputs()
	
func _input(event):
	if !(event is InputEventMIDI) or !(event.message == MIDI_MESSAGE_NOTE_ON and event.velocity): return
	
	var pitch = event.pitch
	if !pitch_to_fret.has(pitch): return
	
	var string = pitch_to_fret[pitch][0]
	var fret = pitch_to_fret[pitch][1]
	
	var delta = OS.get_system_time_msecs() - last_strum[string][0]
	
	if delta < 500 and last_strum[string][1] != fret:
		PlayerData.emit_signal("_hammer_guitar", string, fret)
	else:
		PlayerData.emit_signal("_play_guitar", string, fret, 1.0)
		last_strum[string] = [OS.get_system_time_msecs(), fret]
