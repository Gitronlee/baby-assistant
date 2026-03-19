Notes:
- SleepScreen uses audioplayers to play a looping white-noise-like audio.
- It first attempts to load assets/audio/hair_dryer.mp3. If missing/invalid, it falls back to a network source.
- Ensure the asset is a valid MP3 for production use; otherwise provide a URL fallback.
