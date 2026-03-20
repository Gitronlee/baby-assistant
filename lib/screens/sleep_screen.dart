import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});
  @override
  _SleepScreenState createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  final Map<String, String> _noiseTypes = {
    '吹风机': 'https://www.soundjay.com/ambient/sounds/hair-dryer-1.mp3',
    '雨声': 'https://www.soundjay.com/nature/sounds/rain-01.mp3',
    '海浪': 'https://www.soundjay.com/nature/sounds/ocean-wave-1.mp3',
    '白噪音': 'https://www.soundjay.com/ambient/sounds/white-noise-1.mp3',
  };

  String _currentNoise = '吹风机';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _play();
  }

  Future<void> _play() async {
    try {
      setState(() => _isLoading = true);
      await _audioPlayer.play(UrlSource(_noiseTypes[_currentNoise]!));
      setState(() {
        _isPlaying = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pause() async {
    await _audioPlayer.pause();
    setState(() => _isPlaying = false);
  }

  void _toggle() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _showNoiseSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '选择白噪音',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(_noiseTypes.length, (index) {
              final noise = _noiseTypes.keys.elementAt(index);
              final isSelected = noise == _currentNoise;
              return ListTile(
                leading: Icon(
                  _getNoiseIcon(noise),
                  color: isSelected ? Colors.pink : Colors.grey,
                ),
                title: Text(
                  noise,
                  style: TextStyle(
                    color: isSelected ? Colors.pink : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.pink)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _switchNoise(noise);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getNoiseIcon(String noise) {
    switch (noise) {
      case '吹风机':
        return Icons.air;
      case '雨声':
        return Icons.water_drop;
      case '海浪':
        return Icons.waves;
      case '白噪音':
        return Icons.surround_sound;
      default:
        return Icons.music_note;
    }
  }

  Future<void> _switchNoise(String noise) async {
    if (noise == _currentNoise) return;
    setState(() {
      _currentNoise = noise;
      _isLoading = true;
    });
    await _audioPlayer.stop();
    await _play();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _toggle,
        onLongPress: _showNoiseSelector,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _isPlaying
                  ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
                  : [const Color(0xFFf5f5f5), const Color(0xFFe0e0e0)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: _isPlaying ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isPlaying ? _pulseAnimation.value : 1.0,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isPlaying
                                ? Colors.pink.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.2),
                            boxShadow: _isPlaying
                                ? [
                                    BoxShadow(
                                      color: Colors.pink.withOpacity(0.4),
                                      blurRadius: 40,
                                      spreadRadius: 20,
                                    )
                                  ]
                                : null,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 80,
                                  color: _isPlaying ? Colors.white : Colors.black54,
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        _currentNoise,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          color: _isPlaying ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isPlaying ? '点击暂停' : '点击播放',
                        style: TextStyle(
                          fontSize: 14,
                          color: _isPlaying ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '长按切换白噪音',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isPlaying ? Colors.white24 : Colors.black26,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}