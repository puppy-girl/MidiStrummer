# MIDI Strummer
A WEBFISHING mod to play guitars with a MIDI input device! 🎶

the guitar will play with or without the menu open; feel free to run around, fish, and talk in chat while playing!

## Installation
> [!NOTE]  
> GDWeave is required to use the mod—[head here](https://github.com/NotNite/GDWeave/) if it isn't installed

[Download MIDI Strummer](https://github.com/puppy-girl/MidiStrummer/releases/latest/download/MidiStrummer.zip) and put the extracted mod folder into `GDWeave/mods`. Your `mods` folder should hold a `MidiStrummer` directory with all the mod files inside it ૮˶• ﻌ •˶ა

## Playing from MIDI files
> [!TIP]
> WEBFISHING won't detect MIDI devices connected after launching; try restarting if it doesn't work ૮ • ﻌ - ა

to play from a midi file I recommend installing [loopMIDI](https://www.tobias-erichsen.de/software/loopmidi.html) and creating a virtual loopback port with the add icon on the bottom left. in a midi player of your choice, set the output device to your new virtual loopback port: I use [MidiPlay](https://chrishills.org.uk/ChrisHills/midiplay/index.html) for its simplicity and ease of muting instruments, but feel free to use any player!

notes outside of the guitars' range will be ignored and simultaneous notes/notes in quick succession can cause some audio quirks; if/when this is an issue i suggest muting instruments or editing the midi file. WEBFISHING's guitars can play notes from the midi pitches 40 to 80, or from E2 to G#5, and faster notes tend to sound better in the middle of that range where there's more available strings to play them
