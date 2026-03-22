import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:ui';
import 'screens/weight_screen.dart';
import 'screens/about_screen.dart';

void main() {
  runApp(const BabyAssistantApp());
}

class BabyAssistantApp extends StatelessWidget {
  const BabyAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '萌宝助手',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFB6C1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8E8E8),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.brown.shade700,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.brown.shade700,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB6C1).withOpacity(0.9),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.pink.shade200, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.85),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '选择白噪音',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(_defaultNoises.length, (index) {
                  final noise = _defaultNoises.keys.elementAt(index);
                  final isSelected = noise == _currentNoise && _customAudioPath == null;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected ? Colors.pink.shade50.withOpacity(0.5) : Colors.transparent,
                    ),
                    child: ListTile(
                      leading: Icon(
                        _getNoiseIcon(noise),
                        color: isSelected ? Colors.pink : Colors.grey.shade600,
                      ),
                      title: Text(
                        noise,
                        style: TextStyle(
                          color: isSelected ? Colors.pink.shade700 : Colors.grey.shade800,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: Colors.pink.shade400)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        _switchNoise(noise);
                      },
                    ),
                  );
                }),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _customAudioPath != null ? Colors.pink.shade50.withOpacity(0.5) : Colors.transparent,
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.upload_file,
                      color: _customAudioPath != null ? Colors.pink : Colors.grey.shade600,
                    ),
                    title: Text(
                      '自定义音频',
                      style: TextStyle(
                        color: _customAudioPath != null ? Colors.pink.shade700 : Colors.grey.shade800,
                        fontWeight: _customAudioPath != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: _customAudioPath != null
                        ? Icon(Icons.check_circle, color: Colors.pink.shade400)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _selectCustomAudio();
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
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
          '萌宝助手',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,

      ),
      body: Stack(
        children: [
          // 底层渐变背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF5F5),
                  Color(0xFFFFE4E1),
                  Color(0xFFFFDAB9),
                  Color(0xFFE8F5E9),
                ],
              ),
            ),
          ),
          // 装饰圆形 - 增加层次感和深度
          // 右上角粉色圆形 - 主装饰
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.pink.shade300.withOpacity(0.5),
                    Colors.pink.shade200.withOpacity(0.3),
                    Colors.pink.shade100.withOpacity(0.1),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.shade200.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          // 左下角绿色圆形 - 平衡装饰
          Positioned(
            bottom: 80,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.green.shade300.withOpacity(0.4),
                    Colors.green.shade200.withOpacity(0.2),
                    Colors.green.shade100.withOpacity(0.05),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade200.withOpacity(0.25),
                    blurRadius: 25,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          // 中间右侧橙色圆形 - 活力装饰
          Positioned(
            top: 180,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.orange.shade300.withOpacity(0.4),
                    Colors.orange.shade200.withOpacity(0.2),
                    Colors.orange.shade100.withOpacity(0.05),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.shade200.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
          // 左上角紫色圆形 - 柔和装饰
          Positioned(
            top: 100,
            left: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.purple.shade200.withOpacity(0.35),
                    Colors.purple.shade100.withOpacity(0.15),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          // 右下角靛蓝色圆形 - 深度装饰
          Positioned(
            bottom: 200,
            right: 20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.indigo.shade200.withOpacity(0.3),
                    Colors.indigo.shade100.withOpacity(0.1),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          // 主内容
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildSleepCard(context),
                  _buildGridItem(
                    context,
                    icon: Icons.child_care,
                    title: '成长轨迹',
                    middleText: '记录成长数据',
                    subtitle: '点击查看详情',
                    gradientColors: [
                      Colors.green.shade300,
                      Colors.teal.shade300,
                    ],
                    iconColor: Colors.green.shade700,
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
                    middleText: '版本信息',
                    subtitle: '点击查看详情',
                    gradientColors: [
                      Colors.purple.shade200,
                      Colors.indigo.shade200,
                    ],
                    iconColor: Colors.purple.shade700,
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
          ),
        ],
      ),
    );
  }

  Widget _buildSleepCard(BuildContext context) {
    final isActive = _isPlaying;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        // 多层阴影创造厚度感和实体感
        boxShadow: [
          // 底层深阴影 - 模拟卡片底部接触面
          BoxShadow(
            color: isActive 
                ? Colors.indigo.shade900.withOpacity(0.5)
                : Colors.grey.shade400.withOpacity(0.4),
            blurRadius: 0,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
          // 中层柔和阴影 - 过渡效果
          BoxShadow(
            color: isActive 
                ? Colors.indigo.shade700.withOpacity(0.4)
                : Colors.grey.shade300.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          // 上层模糊阴影 - 悬浮效果
          BoxShadow(
            color: isActive 
                ? Colors.indigo.shade500.withOpacity(0.3)
                : Colors.indigo.shade200.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          // 顶部高光 - 增强立体感
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 0,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // 底部厚度层
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              isActive 
                  ? Colors.indigo.shade900.withOpacity(0.3)
                  : Colors.grey.shade300.withOpacity(0.3),
            ],
            stops: const [0.85, 1.0],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isActive
                  ? [
                      Colors.indigo.shade400,
                      Colors.indigo.shade600,
                    ]
                  : [
                      Colors.white,
                      Colors.indigo.shade50,
                    ],
            ),
            border: Border.all(
              color: isActive 
                  ? Colors.indigo.shade300.withOpacity(0.6)
                  : Colors.white,
              width: 2,
            ),
            boxShadow: [
              // 内阴影 - 增强实体感
              BoxShadow(
                color: isActive 
                    ? Colors.indigo.shade900.withOpacity(0.3)
                    : Colors.grey.shade200.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 2),
                spreadRadius: -5,
              ),
              // 内部高光
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 0,
                offset: const Offset(0, 1),
                spreadRadius: -1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isActive
                        ? [
                            Colors.indigo.shade400.withOpacity(0.85),
                            Colors.indigo.shade600.withOpacity(0.75),
                          ]
                        : [
                            Colors.white.withOpacity(0.9),
                            Colors.indigo.shade50.withOpacity(0.8),
                          ],
                  ),
                  border: Border.all(
                    color: isActive 
                        ? Colors.white.withOpacity(0.3)
                        : Colors.white.withOpacity(0.8),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleSleep,
                    onLongPress: _showNoiseSelector,
                    borderRadius: BorderRadius.circular(24),
                    splashColor: Colors.indigo.withOpacity(0.1),
                    highlightColor: Colors.indigo.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 图标容器 - 增加厚度感
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isActive
                                    ? [
                                        Colors.white.withOpacity(0.3),
                                        Colors.white.withOpacity(0.1),
                                      ]
                                    : [
                                        Colors.indigo.shade100.withOpacity(0.6),
                                        Colors.indigo.shade50.withOpacity(0.4),
                                      ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isActive 
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.indigo.shade200.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isActive ? Icons.nightlight_round : Icons.nightlight_outlined,
                              size: 36,
                              color: isActive ? Colors.white : Colors.indigo.shade500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '助眠白噪声',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.white.withOpacity(0.9) : Colors.indigo.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _customAudioPath != null ? '自定义音频' : _currentNoise,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.white : Colors.indigo.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isActive ? '点击暂停' : '点击播放 · 长按选择',
                            style: TextStyle(
                              fontSize: 10,
                              color: isActive 
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.indigo.shade400,
                            ),
                          ),
                        ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedingCard(BuildContext context) {
    final canFeed = _feedingRemaining.isNegative || _feedingRemaining == Duration.zero;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        // 多层阴影创造厚度感和实体感
        boxShadow: [
          // 底层深阴影 - 模拟卡片底部接触面
          BoxShadow(
            color: canFeed 
                ? Colors.green.shade900.withOpacity(0.5)
                : Colors.orange.shade900.withOpacity(0.5),
            blurRadius: 0,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
          // 中层柔和阴影 - 过渡效果
          BoxShadow(
            color: canFeed 
                ? Colors.green.shade700.withOpacity(0.4)
                : Colors.orange.shade700.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          // 上层模糊阴影 - 悬浮效果
          BoxShadow(
            color: canFeed 
                ? Colors.green.shade500.withOpacity(0.3)
                : Colors.orange.shade500.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          // 顶部高光 - 增强立体感
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 0,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // 底部厚度层
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              canFeed 
                  ? Colors.green.shade900.withOpacity(0.3)
                  : Colors.orange.shade900.withOpacity(0.3),
            ],
            stops: const [0.85, 1.0],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: canFeed
                  ? [
                      Colors.green.shade400,
                      Colors.green.shade600,
                    ]
                  : [
                      Colors.orange.shade400,
                      Colors.orange.shade600,
                    ],
            ),
            border: Border.all(
              color: canFeed 
                  ? Colors.green.shade300.withOpacity(0.6)
                  : Colors.orange.shade300.withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              // 内阴影 - 增强实体感
              BoxShadow(
                color: canFeed 
                    ? Colors.green.shade900.withOpacity(0.3)
                    : Colors.orange.shade900.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
                spreadRadius: -5,
              ),
              // 内部高光
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 0,
                offset: const Offset(0, 1),
                spreadRadius: -1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: canFeed
                        ? [
                            Colors.green.shade400.withOpacity(0.85),
                            Colors.green.shade600.withOpacity(0.75),
                          ]
                        : [
                            Colors.orange.shade400.withOpacity(0.85),
                            Colors.orange.shade600.withOpacity(0.75),
                          ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showFeedingResetDialog(context),
                    onLongPress: () => _showFeedingSettings(context),
                    borderRadius: BorderRadius.circular(24),
                    splashColor: (canFeed ? Colors.green : Colors.orange).withOpacity(0.1),
                    highlightColor: (canFeed ? Colors.green : Colors.orange).withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 图标容器 - 增加厚度感
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              canFeed ? Icons.baby_changing_station : Icons.local_drink,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            canFeed ? '可以喂奶了' : '距离下次喂奶',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatFeedingDuration(_feedingRemaining),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '长按设置',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                  ),
                ),
              ),
            ),
          ),
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
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
          elevation: 20,
          shadowColor: Colors.black.withOpacity(0.2),
          title: Text(
            '重新计时',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          content: Text(
            '确定要重新开始计时吗？\n将清除下次提醒时间，仅以间隔时间倒计时。',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
              ),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetFeedingTimer();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.pink.shade400,
              ),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedingSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.85),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '喂奶设置',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50.withOpacity(0.5),
                  ),
                  child: ListTile(
                    title: Text(
                      '喂奶间隔',
                      style: TextStyle(color: Colors.grey.shade800),
                    ),
                    subtitle: Text(
                      '${_intervalMinutes ~/ 60}小时${_intervalMinutes % 60}分钟',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey.shade600),
                    onTap: () {
                      Navigator.pop(context);
                      _showIntervalPicker(context);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50.withOpacity(0.5),
                  ),
                  child: ListTile(
                    title: Text(
                      '应喂奶时间',
                      style: TextStyle(color: Colors.grey.shade800),
                    ),
                    subtitle: Text(
                      _nextFeedingTime != null
                          ? '${_nextFeedingTime!.hour.toString().padLeft(2, '0')}:${_nextFeedingTime!.minute.toString().padLeft(2, '0')}'
                          : '未设置',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey.shade600),
                    onTap: () {
                      Navigator.pop(context);
                      _showTimePicker(context);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50.withOpacity(0.5),
                  ),
                  child: ListTile(
                    title: Text(
                      '重新计时',
                      style: TextStyle(color: Colors.grey.shade800),
                    ),
                    subtitle: Text(
                      '复位倒计时，重新开始',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: Icon(Icons.refresh, color: Colors.grey.shade600),
                    onTap: () {
                      Navigator.pop(context);
                      _resetFeedingTimer();
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
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
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
          elevation: 20,
          shadowColor: Colors.black.withOpacity(0.2),
          title: Text(
            '设置喂奶间隔',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
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
                      style: TextStyle(color: Colors.grey.shade800),
                      decoration: InputDecoration(
                        labelText: '小时',
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: Colors.grey.shade50.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.pink.shade300),
                        ),
                      ),
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
                      style: TextStyle(color: Colors.grey.shade800),
                      decoration: InputDecoration(
                        labelText: '分钟',
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: Colors.grey.shade50.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.pink.shade300),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
              ),
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.pink.shade400,
              ),
              child: const Text('确定'),
            ),
          ],
        ),
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
    required List<Color> gradientColors,
    required Color iconColor,
    required VoidCallback onTap,
    String? middleText,
    String? subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        // 多层阴影创造厚度感和实体感
        boxShadow: [
          // 底层深阴影 - 模拟卡片底部接触面
          BoxShadow(
            color: gradientColors.last.withOpacity(0.5),
            blurRadius: 0,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
          // 中层柔和阴影 - 过渡效果
          BoxShadow(
            color: gradientColors.last.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          // 上层模糊阴影 - 悬浮效果
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          // 顶部高光 - 增强立体感
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 0,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // 底部厚度层
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              gradientColors.last.withOpacity(0.3),
            ],
            stops: const [0.85, 1.0],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradientColors.first,
                gradientColors.last,
              ],
            ),
            border: Border.all(
              color: gradientColors.first.withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              // 内阴影 - 增强实体感
              BoxShadow(
                color: gradientColors.last.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
                spreadRadius: -5,
              ),
              // 内部高光
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 0,
                offset: const Offset(0, 1),
                spreadRadius: -1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      gradientColors.first.withOpacity(0.85),
                      gradientColors.last.withOpacity(0.75),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(24),
                    splashColor: gradientColors.first.withOpacity(0.1),
                    highlightColor: gradientColors.first.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 图标容器 - 增加厚度感
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.4),
                                  Colors.white.withOpacity(0.2),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: gradientColors.first.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              size: 36,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                          if (middleText != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              middleText,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ] else if (middleText == null) ...[
                            const SizedBox(height: 20),
                          ],
                        ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}