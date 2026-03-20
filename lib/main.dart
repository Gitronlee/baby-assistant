import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/weight_screen.dart';
import 'screens/feeding_screen.dart';
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
    });
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请将音频文件放到 /storage/emulated/0/Download/ 目录下，文件名为 baby_sleep.mp3')),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
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
              title: '小宝记重',
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
            _buildGridItem(
              context,
              icon: Icons.baby_changing_station,
              title: '小宝记奶',
              color: Colors.orange.shade100,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FeedingScreen(),
                  ),
                );
              },
            ),
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
              '小宝助眠',
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