import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'settings_screen.dart';
import 'milk_report_screen.dart';

class FeedingScreen extends StatefulWidget {
  const FeedingScreen({Key? key}) : super(key: key);
  @override
  _FeedingScreenState createState() => _FeedingScreenState();
}

class _FeedingScreenState extends State<FeedingScreen> {
  int _secondsRemaining = 60 * 5; // 5 minutes by default
  Timer? _timer;
  bool _running = false;

  void _start() {
    if (_running) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining <= 0) {
        t.cancel();
        setState(() { _running = false; });
        return;
      }
      setState(() { _secondsRemaining--; _running = true; });
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() { _running = false; });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _running && _secondsRemaining > 0;
    final Color cardColor = isRunning
        ? Theme.of(context).colorScheme.primary.withOpacity(0.25)
        : Theme.of(context).cardColor;
    final statusColor = isRunning ? Colors.orange : Colors.brown[100]!;
    return Scaffold(
      appBar: AppBar(title: const Text("Feeding")),
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
                  Text('Countdown Timer', style: Theme.of(context).textTheme.headline6),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatTime(_secondsRemaining),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(onPressed: _start, child: const Text('Start')),
                      const SizedBox(width: 12),
                      ElevatedButton(onPressed: _stop, child: const Text('Stop')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Settings'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MilkReportScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.assessment),
                        label: const Text('Milk Report'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}