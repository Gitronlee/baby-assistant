import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});
  @override
  _SleepScreenState createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String _status = "空闲";

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> _play() async {
    try {
      // 使用网络音频源（请替换为实际的吹风机白噪音URL）
      await _audioPlayer.setSourceUrl("https://www.example.com/hair-dryer.mp3");
      await _audioPlayer.resume();
      setState(() {
        _isPlaying = true;
        _status = "正在播放吹风机白噪音…";
      });
    } catch (e) {
      setState(() {
        _status = "加载音频失败: $e";
      });
    }
  }

  Future<void> _pause() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
      _status = "已暂停";
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
      appBar: AppBar(title: const Text("助眠")),
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
                  Text("白噪音助眠", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(_status, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _toggle, child: Text(_isPlaying ? "暂停" : "播放")),
                  const SizedBox(height: 8),
                  const Text(
                    "音频将在后台循环播放。请确保已在平台配置中启用后台播放权限。",
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