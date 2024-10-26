extends Node
class_name MidiStrummer

# Buckets are created for each BUCKET_MS milliseconds.
# If 2 notes are in the same bucket, they're being played at the same time.
var BUCKET_MS = 2

# Delay before notes are played, in milliseconds
var DELAY_MS = 10.0

var RAND = RandomNumberGenerator.new()

# pitch: [string, fret]
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

# string: how many frets the note is shifted up on the previous string
var string_to_prev_string_interval = {
	0: 0,
	1: 5,
	2: 5,
	3: 5,
	4: 4,
	5: 5
}

# string: [msec, fret]
var last_strum = {
	0: [0, 0],
	1: [0, 0],
	2: [0, 0],
	3: [0, 0],
	4: [0, 0],
	5: [0, 0]
}

# bucket: [string, fret, note_rand_id]
# The bucket key is $"{timestamp}-{note_rand_id}"
var upcoming_notes = {}

func _ready():
	print("MidiStrummer: _ready()")
	OS.open_midi_inputs()

func _input(event):
	# Get current time at beginning of method for more accurate delay.
	var current_time_before = OS.get_system_time_msecs()
	if !(event is InputEventMIDI) or !(event.message == MIDI_MESSAGE_NOTE_ON and event.velocity): return

	var pitch = event.pitch
	if !pitch_to_fret.has(pitch): return

	var initial_string = pitch_to_fret[pitch][0]
	var initial_fret = pitch_to_fret[pitch][1]
	var note_rand_id =  str(RAND.randi())

	# Dictionary doesn't have get_or_add() in Godot 3.5, so this is what you get.
	# Create dictionary key with $"{timestamp}-{random integer}".
	# After the delay, we'll iterate through all keys and select the ones with correct timestamp.
	var bucket_ms = current_time_before - (current_time_before % BUCKET_MS)
	var bucket_key = str(bucket_ms) + "-" + note_rand_id
	upcoming_notes[bucket_key] = [initial_string, initial_fret, note_rand_id]

	# Delay note, so other notes could potentially fall into this note's bucket.
	var delay_ms = DELAY_MS - (OS.get_system_time_msecs() - current_time_before)
	yield(get_tree().create_timer(delay_ms / 1000), "timeout")

	# Get the array of notes in this bucket, as [string, fret, note_rand_id] tuples.
	var bucket_notes = []
	for upcoming_notes_key in upcoming_notes.keys():
		if (upcoming_notes_key.begins_with(str(bucket_ms))):
			bucket_notes.append(upcoming_notes[upcoming_notes_key])

	# Sort notes in ascending order.
	bucket_notes.sort_custom(UpcomingNotesSorter, "sort_ascending")

	# Determine current strum, and move notes around if needed to avoid conflicts.
	# string: [fret, note_rand_id]
	var current_strum = {
		0: [-1, ""],
		1: [-1, ""],
		2: [-1, ""],
		3: [-1, ""],
		4: [-1, ""],
		5: [-1, ""],
	}
	for bucket_note in bucket_notes:
		var bucket_string = bucket_note[0]
		var bucket_fret = bucket_note[1]
		var bucket_note_rand_id = bucket_note[2]
		
		# Try to shift the note down as many strings as possible.
		while true:
			# Stop shifting down if any of the following happens:
			# 1. We're on the lowest string.
			# 2. The lower string already has a note on it.
			# 3. Shifting the note to the lower string will cause the notes to be out of bounds.
			if bucket_string == 0 or current_strum[bucket_string - 1][0] != -1 or bucket_fret + string_to_prev_string_interval[bucket_string] > 15:
				break
			bucket_fret += string_to_prev_string_interval[bucket_string]
			bucket_string -= 1

		# Only strum the note if there isn't a note on that string already.
		# However, if it's the highest string, always play it, since it's likely the melody.
		if current_strum[bucket_string][0] == -1 or bucket_string == 5:
			current_strum[bucket_string] = [bucket_fret, bucket_note_rand_id]

	# Get the actual string and fret to play
	var string = null
	var fret = null
	for current_strum_string in current_strum:
		if current_strum[current_strum_string][1] == note_rand_id:
			string = current_strum_string
			fret = current_strum[current_strum_string][0]

	# Clean up note from dictionary.
	upcoming_notes.erase(bucket_key)

	# Return early if this note is not being played.
	if string == null or fret == null:
		return

	var current_time_after = OS.get_system_time_msecs()
	var delta = current_time_after - last_strum[string][0]

	if delta < 500 and last_strum[string][1] != fret:
		PlayerData.emit_signal("_hammer_guitar", string, fret)
	else:
		PlayerData.emit_signal("_play_guitar", string, fret, 1.0)
		last_strum[string] = [current_time_after, fret]

class UpcomingNotesSorter:
	func sort_ascending(a, b):
		if a[0] != b[0]:
			return a[0] < b[0]
		return a[1] < b[1]
