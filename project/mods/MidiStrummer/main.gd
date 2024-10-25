extends Node
class_name MidiStrummer

#the midi value each string begins on
var string_pitch_indices = [40,45,50,55,59,64]

func pitch_is_in_bounds(pitch):
	return pitch >= string_pitch_indices[0] or pitch <= string_pitch_indices[5] + 16

# [msec, fret]
var last_strum = {
	0: [0, 0],
	1: [0, 0],
	2: [0, 0],
	3: [0, 0],
	4: [0, 0],
	5: [0, 0]
}

const QUEUE_MAX_SIZE = 6
var string_queue = [0,1,2,3,4,5]

func update_string_queue(last_played_string: int):
	var last_string_index = string_queue.find(last_played_string)
	if last_string_index != -1:
		string_queue.pop_at(last_string_index)
	string_queue.append(last_played_string)

#returns array of possible guitar notes for a given pitch 
#returns notes in format [string, fret]
func pitch_to_notes(pitch):
	if !pitch_is_in_bounds(pitch):
		return
	
	var possible_notes = []
	
	var string = 0
	for index in string_pitch_indices:
		if pitch >= index and pitch < index + 16:
			var relative_pitch = pitch - index
			possible_notes.append([string,relative_pitch])
		string += 1
	
	return possible_notes

#takes an array of notes in format [string, fret] provided by pitch_to_notes()
#returns the note on the string which was least recently played
#by iterating across the possible notes n seeing which is closest to the front in the string queue
func get_best_note(notes):
	var note_choice
	#starts at the top of the queue
	var least_recent_string_index = QUEUE_MAX_SIZE
	
	for note in notes:
		var string_index = string_queue.find(note[0])
		if string_index < least_recent_string_index:
			note_choice = note
			least_recent_string_index = string_index
	
	return note_choice


#takes note as [string, fret]
func play_note(note: Array):
	var string = note[0]
	var fret = note[1]
	
	var delta = OS.get_system_time_msecs() - last_strum[string][0]
	
	if delta < 500 and last_strum[string][1] != fret:
		PlayerData.emit_signal("_hammer_guitar", string, fret)
		pass
	else:
		PlayerData.emit_signal("_play_guitar", string, fret, 1.0)
		last_strum[string] = [OS.get_system_time_msecs(), fret]
	update_string_queue(string)

func test_play(pitch):
	var notes = pitch_to_notes(pitch)
	var note = get_best_note(notes)
	print("pitch: %s" % pitch)
	print(note)
	update_string_queue(note[0])


func _ready():
	print("MidiStrummer: _ready()")

	OS.open_midi_inputs()


func _input(event):
	if !(event is InputEventMIDI) or !(event.message == MIDI_MESSAGE_NOTE_ON and event.velocity): return
	
	var pitch = event.pitch
	if !pitch_is_in_bounds(pitch): return
	
	var notes = pitch_to_notes(pitch)
	var note = get_best_note(notes)
	play_note(note)
