import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'milk_report_screen.dart';

class FeedingScreen extends StatefulWidget {
  const FeedingScreen({super.key});
  @override
  _FeedingScreenState createState() => _FeedingScreenState();
}

class _FeedingScreenState extends State<FeedingScreen> {
  Timer? _timer;
  int _intervalMinutes = 180;
  DateTime? _nextFeedingTime;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
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
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_nextFeedingTime == null) return;
      final now = DateTime.now();
      setState(() {
        _remaining = _nextFeedingTime!.difference(now);
      });
    });
  }

  void _showResetDialog() {
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
              _resetTimer();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('next_feeding_time');
    setState(() {
      _nextFeedingTime = DateTime.now().add(Duration(minutes: _intervalMinutes));
      _remaining = Duration(minutes: _intervalMinutes);
    });
    prefs.setString('next_feeding_time', _nextFeedingTime!.toIso8601String());
  }

  void _showSettings() {
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
                _showIntervalPicker();
              },
            ),
            ListTile(
              title: const Text('下次提醒时间'),
              subtitle: Text(_nextFeedingTime != null
                  ? '${_nextFeedingTime!.hour.toString().padLeft(2, '0')}:${_nextFeedingTime!.minute.toString().padLeft(2, '0')}'
                  : '未设置'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _showTimePicker();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showIntervalPicker() {
    final hours = _intervalMinutes ~/ 60;
    final minutes = _intervalMinutes % 60;
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
                    controller: TextEditingController(text: hours.toString()),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(labelText: '小时'),
                    onChanged: (value) {},
                  ),
                ),
                const SizedBox(width: 16),
                const Text(':', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 16),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: TextEditingController(text: minutes.toString()),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(labelText: '分钟'),
                    onChanged: (value) {},
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
              final navigator = Navigator.of(context);
              final newHours = int.tryParse(hours.toString()) ?? hours;
              final newMinutes = int.tryParse(minutes.toString()) ?? minutes;
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

  void _showTimePicker() async {
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
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

  @override
  Widget build(BuildContext context) {
    final canFeed = _remaining.isNegative || _remaining == Duration.zero;
    final backgroundColor = canFeed
        ? Colors.green.shade50
        : Colors.orange.shade50;

    return Scaffold(
      appBar: AppBar(
        title: const Text('小宝记奶'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MilkReportScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: canFeed ? null : _showResetDialog,
        onLongPress: _showSettings,
        child: Container(
          color: backgroundColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  canFeed ? '可以喂奶了' : '距离下次喂奶',
                  style: TextStyle(
                    fontSize: 20,
                    color: canFeed ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _formatDuration(_remaining),
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: canFeed ? Colors.green.shade700 : Colors.orange.shade700,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '下次: ${_nextFeedingTime != null ? "${_nextFeedingTime!.hour.toString().padLeft(2, '0')}:${_nextFeedingTime!.minute.toString().padLeft(2, '0')}" : "未设置"}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  canFeed ? '点击长按设置' : '点击重新计时  长按设置',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
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