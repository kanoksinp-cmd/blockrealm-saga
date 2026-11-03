#!/bin/sh
# Re-encode music (stereo 64 kbps) and ambience (mono 40 kbps) from the project's originals.
# Usage: sh encode_audio.sh "<Godot project>/assets/audio" <out-dir>
SRC="$1"; OUT="$2"; mkdir -p "$OUT/music" "$OUT/ambient"
for f in "$SRC"/music/*.ogg; do ffmpeg -v error -y -i "$f" -map_metadata -1 -c:a libvorbis -ac 2 -ar 44100 -b:a 64k "$OUT/music/$(basename "$f")"; done
for f in "$SRC"/ambient/*.ogg; do ffmpeg -v error -y -i "$f" -map_metadata -1 -c:a libvorbis -ac 1 -ar 44100 -b:a 40k "$OUT/ambient/$(basename "$f")"; done
