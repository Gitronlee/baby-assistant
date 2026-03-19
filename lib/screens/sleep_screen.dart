import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({Key? key}) : super(key: key);
  @override
  _SleepScreenState createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String _status = "Idle";

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> _play() async {
    try {
      await _audioPlayer.setSourceAsset("hair_dryer.mp3");
      await _audioPlayer.resume();
      setState(() {
        _isPlaying = true;
        _status = "Playing hair dryer white noise…";
      });
    } catch (e) {
      setState(() {
        _status = "Error loading audio: $e";
      });
    }
  }

  Future<void> _pause() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
      _status = "Paused";
    });
  }

  void _toggle() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    return Scaffold(
      appBar: AppBar(title: const Text("Sleep")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("White Noise Sleep Aid", style: Theme.of(context).textTheme.headline6),
                  const SizedBox(height: 12),
                  Text(_status, style: Theme.of(context).textTheme.subtitle1),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _toggle, child: Text(_isPlaying ? "Pause" : "Play")),
                  const SizedBox(height: 8),
                  const Text(
                    "This audio loops in the background. Ensure you have background playback permission enabled in your platform configs.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}