# Faster web loading: smaller audio — 2026-11-04

## Measured (live site, Cloudflare)
| file | size | served |
|---|---|---|
| index.wasm | 39.5 MB | brotli (already compressed) |
| index.pck | 22.7 MB | not compressed; contents already compressed (gzip only −5.6%) |
Inside index.pck, 10.7 MB (47%) was 15 music/ambience tracks at ~105 kbps stereo.

## Change
- Music (9 tracks): Vorbis stereo 64 kbps. Ambience (6 loops): Vorbis mono 40 kbps.
- Re-encoded from `Blockrealm Saga/assets/audio` originals (`encode_audio.sh`), imported with
  Godot 4.7.2 using the original `.import` settings, and only the 15 `.oggvorbisstr` entries replaced.
- index.pck: 22.66 MB → 16.93 MB (−5.7 MB, −25%).
- All 15 streams: same length and loop flag as before. Startup log unchanged; account login/load tests pass.

## Next bottleneck (not changed here)
After pressing Play, `village_builder.gd` build() takes ~4.1 s natively (slower on Web):
`micro_voxel` 10 cm details mesh 2.0 s (1.76 M vertices), `_forest` 0.84 s, block mesh 0.81 s.
Baking the details mesh would add tens of MB of download, so it was not done.
