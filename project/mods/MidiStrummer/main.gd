class_name MidiStrummer
extends Node

const OPEN_STRING_PITCHES := [40, 45, 50, 55, 59, 64]
const HIGHEST_FRET := 16

# The timestamp and fret most recently played on each string
var _last_strum: Array = [[0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0]]
# Strings ordered from least to most recently played
var _string_queue: Array = [0, 1, 2, 3, 4, 5]

func _ready() -> void:
	OS.open_midi_inputs()


func _input(event) -> void:
	if (
			!(event is InputEventMIDI) or
			!(event.message == MIDI_MESSAGE_NOTE_ON and event.velocity)
	):
		return
	
	var pitch: int = event.pitch
	if !is_pitch_in_bounds(pitch):
		return
	
	var possible_notes := get_possible_notes(pitch)
	var note := get_best_note(possible_notes)
	play_note(note)


func is_pitch_in_bounds(pitch: int) -> bool:
	return (
			pitch >= OPEN_STRING_PITCHES[0] and
			pitch <= OPEN_STRING_PITCHES[5] + HIGHEST_FRET
	)


# returns array of possible guitar notes for a given pitch in format [string, fret]
func get_possible_notes(pitch: int) -> Array:
	var possible_notes := []
	
	var string: int = 0
	for string_pitch in OPEN_STRING_PITCHES:
		if pitch >= string_pitch and pitch <= string_pitch + HIGHEST_FRET:
			var fret: int = pitch - string_pitch
			possible_notes.append([string, fret])
		string += 1
	
	return possible_notes


# takes an array of notes in format [string, fret] provided by get_possible_notes()
# returns the note on the string which was least recently played
# by iterating across the possible notes n seeing which is closest to the front in the string queue
func get_best_note(notes: Array) -> Array:
	var best_note: Array
	# starts at the top of the queue
	var least_recent_string_index = _string_queue.size() - 1
	
	for note in notes:
		var string_index = _string_queue.find(note[0])
		
		if string_index <= least_recent_string_index:
			best_note = note
			least_recent_string_index = string_index
	
	return best_note


# takes note as [string, fret]
func play_note(note: Array):
	var string: int = note[0]
	var fret: int = note[1]
	
	var delta: int = OS.get_system_time_msecs() - _last_strum[string][0]
	
	if delta < 500 and _last_strum[string][1] != fret:
		PlayerData.emit_signal("_hammer_guitar", string, fret)
		pass
	else:
		PlayerData.emit_signal("_play_guitar", string, fret, 1.0)
		_last_strum[string] = [OS.get_system_time_msecs(), fret]
	
	update_string_queue(string)


func update_string_queue(last_played_string: int):
	var last_string_index = _string_queue.find(last_played_string)

	if last_string_index != -1:
		_string_queue.pop_at(last_string_index)
	
	_string_queue.append(last_played_string)
