import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'screens/weight_screen.dart';
import 'screens/about_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const BabyAssistantApp());
}

class BabyAssistantApp extends StatelessWidget {
  const BabyAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '小宝助手',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFB6C1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'CN'),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String _currentNoise = '吹风机';
  String? _customAudioPath;

  final Map<String, String> _defaultNoises = {
    '吹风机': 'assets/audio/hair_dryer.mp3',
    '雨声': 'https://www.soundjay.com/nature/sounds/rain-01.mp3',
    '海浪': 'https://www.soundjay.com/nature/sounds/ocean-wave-1.mp3',
    '白噪音': 'https://www.soundjay.com/ambient/sounds/white-noise-1.mp3',
  };

  Timer? _feedingTimer;
  int _intervalMinutes = 180;
  DateTime? _nextFeedingTime;
  Duration _feedingRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentNoise = prefs.getString('selected_noise') ?? '吹风机';
      _customAudioPath = prefs.getString('custom_audio_path');
      _intervalMinutes = prefs.getInt('feeding_interval') ?? 180;
      final nextTimeStr = prefs.getString('next_feeding_time');
      if (nextTimeStr != null) {
        _nextFeedingTime = DateTime.tryParse(nextTimeStr);
      }
      if (_nextFeedingTime == null) {
        _nextFeedingTime = DateTime.now().add(Duration(minutes: _intervalMinutes));
        prefs.setString('next_feeding_time', _nextFeedingTime!.toIso8601String());
      }
    });
    _startFeedingTimer();
  }

  void _startFeedingTimer() {
    _feedingTimer?.cancel();
    _feedingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_nextFeedingTime == null) return;
      final now = DateTime.now();
      setState(() {
        _feedingRemaining = _nextFeedingTime!.difference(now);
      });
    });
  }

  Future<void> _resetFeedingTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('next_feeding_time');
    setState(() {
      _nextFeedingTime = DateTime.now().add(Duration(minutes: _intervalMinutes));
      _feedingRemaining = Duration(minutes: _intervalMinutes);
    });
    prefs.setString('next_feeding_time', _nextFeedingTime!.toIso8601String());
  }

  Future<void> _play() async {
    try {
      if (_customAudioPath != null) {
        await _audioPlayer.play(DeviceFileSource(_customAudioPath!));
      } else {
        final source = _defaultNoises[_currentNoise]!;
        if (source.startsWith('http')) {
          await _audioPlayer.play(UrlSource(source));
        } else {
          await _audioPlayer.play(AssetSource(source.replaceFirst('assets/', '')));
        }
      }
      setState(() => _isPlaying = true);
    } catch (e) {
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _pause() async {
    await _audioPlayer.pause();
    setState(() => _isPlaying = false);
  }

  void _toggleSleep() {
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
            ...List.generate(_defaultNoises.length, (index) {
              final noise = _defaultNoises.keys.elementAt(index);
              final isSelected = noise == _currentNoise && _customAudioPath == null;
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
            ListTile(
              leading: Icon(
                Icons.upload_file,
                color: _customAudioPath != null ? Colors.pink : Colors.grey,
              ),
              title: Text(
                '自定义音频',
                style: TextStyle(
                  color: _customAudioPath != null ? Colors.pink : Colors.black87,
                  fontWeight: _customAudioPath != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: _customAudioPath != null
                  ? const Icon(Icons.check_circle, color: Colors.pink)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _selectCustomAudio();
              },
            ),
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
    if (noise == _currentNoise && _customAudioPath == null) return;
    final wasPlaying = _isPlaying;
    if (wasPlaying) await _audioPlayer.stop();
    setState(() {
      _currentNoise = noise;
      _customAudioPath = null;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_noise', noise);
    await prefs.remove('custom_audio_path');
    if (wasPlaying) await _play();
  }

  Future<void> _selectCustomAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final wasPlaying = _isPlaying;
        if (wasPlaying) await _audioPlayer.stop();

        setState(() {
          _customAudioPath = filePath;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('custom_audio_path', filePath);

        if (wasPlaying) {
          await _play();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已选择音频: ${result.files.single.name}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _feedingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '小宝助手',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildSleepCard(context),
            _buildGridItem(
              context,
              icon: Icons.monitor_weight,
              title: '萌宝笔记',
              color: Colors.green.shade100,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WeightScreen(),
                  ),
                );
              },
            ),
            _buildFeedingCard(context),
            _buildGridItem(
              context,
              icon: Icons.info_outline,
              title: '关于',
              color: Colors.purple.shade100,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepCard(BuildContext context) {
    return Card(
      color: _isPlaying ? Colors.indigo.shade200 : Colors.indigo.shade100,
      child: InkWell(
        onTap: _toggleSleep,
        onLongPress: _showNoiseSelector,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              size: 48,
              color: _isPlaying ? Colors.white : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              '助眠白噪声',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isPlaying ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _customAudioPath != null ? '自定义' : _currentNoise,
              style: TextStyle(
                fontSize: 12,
                color: _isPlaying ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedingCard(BuildContext context) {
    final canFeed = _feedingRemaining.isNegative || _feedingRemaining == Duration.zero;
    final backgroundColor = canFeed ? Colors.green.shade100 : Colors.orange.shade100;

    return Card(
      color: backgroundColor,
      child: InkWell(
        onTap: canFeed ? null : () => _showFeedingResetDialog(context),
        onLongPress: () => _showFeedingSettings(context),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              canFeed ? Icons.check_circle : Icons.timer,
              size: 48,
              color: canFeed ? Colors.green.shade700 : Colors.orange.shade700,
            ),
            const SizedBox(height: 8),
            Text(
              canFeed ? '可以喂奶了' : '距离下次喂奶',
              style: TextStyle(
                fontSize: 12,
                color: canFeed ? Colors.green.shade700 : Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatFeedingDuration(_feedingRemaining),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: canFeed ? Colors.green.shade700 : Colors.orange.shade700,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '长按设置',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFeedingDuration(Duration duration) {
    if (duration.isNegative) {
      final absDuration = duration.abs();
      final hours = absDuration.inHours;
      final minutes = absDuration.inMinutes % 60;
      final seconds = absDuration.inSeconds % 60;
      return '-${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showFeedingResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重新计时'),
        content: const Text('确定要重新开始计时吗？\n将清除下次提醒时间，仅以间隔时间倒计时。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetFeedingTimer();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showFeedingSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
              '喂奶设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('喂奶间隔'),
              subtitle: Text('${_intervalMinutes ~/ 60}小时${_intervalMinutes % 60}分钟'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _showIntervalPicker(context);
              },
            ),
            ListTile(
              title: const Text('应喂奶时间'),
              subtitle: Text(_nextFeedingTime != null
                  ? '${_nextFeedingTime!.hour.toString().padLeft(2, '0')}:${_nextFeedingTime!.minute.toString().padLeft(2, '0')}'
                  : '未设置'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _showTimePicker(context);
              },
            ),
            ListTile(
              title: const Text('重新计时'),
              subtitle: const Text('复位倒计时，重新开始'),
              trailing: const Icon(Icons.refresh),
              onTap: () {
                Navigator.pop(context);
                _resetFeedingTimer();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showIntervalPicker(BuildContext context) {
    final hoursController = TextEditingController(text: (_intervalMinutes ~/ 60).toString());
    final minutesController = TextEditingController(text: (_intervalMinutes % 60).toString());
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置喂奶间隔'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: hoursController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(labelText: '小时'),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(':', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 16),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: minutesController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(labelText: '分钟'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final newHours = int.tryParse(hoursController.text) ?? 0;
              final newMinutes = int.tryParse(minutesController.text) ?? 0;
              final newInterval = newHours * 60 + newMinutes;
              if (newInterval > 0) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('feeding_interval', newInterval);
                if (mounted) {
                  setState(() {
                    _intervalMinutes = newInterval;
                    _nextFeedingTime = DateTime.now().add(Duration(minutes: newInterval));
                  });
                }
                await prefs.setString('next_feeding_time', _nextFeedingTime!.toIso8601String());
              }
              navigator.pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showTimePicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_nextFeedingTime ?? now),
    );
    if (picked != null) {
      setState(() {
        _nextFeedingTime = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        if (_nextFeedingTime!.isBefore(now)) {
          _nextFeedingTime = _nextFeedingTime!.add(const Duration(days: 1));
        }
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('next_feeding_time', _nextFeedingTime!.toIso8601String());
    }
  }

  Widget _buildGridItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}