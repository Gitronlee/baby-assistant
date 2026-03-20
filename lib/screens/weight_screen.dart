import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});
  @override
  _WeightScreenState createState() => _WeightScreenState();
}

class WeightEntry {
  final DateTime date;
  final double weight;
  WeightEntry(this.date, this.weight);
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'weight': weight,
      };
  static WeightEntry fromJson(Map<String, dynamic> json) {
    return WeightEntry(DateTime.parse(json['date']), (json['weight'] as num).toDouble());
  }
}

class MilkEntry {
  final DateTime date;
  final double amount;
  MilkEntry(this.date, this.amount);
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'amount': amount,
      };
  static MilkEntry fromJson(Map<String, dynamic> json) {
    return MilkEntry(DateTime.parse(json['date']), (json['amount'] as num).toDouble());
  }
}

class _WeightScreenState extends State<WeightScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _milkController = TextEditingController();
  List<WeightEntry> _weightHistory = [];
  List<MilkEntry> _milkHistory = [];
  late SharedPreferences _prefs;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      final weightJson = _prefs.getStringList('weight_history');
      if (weightJson != null) {
        _weightHistory = weightJson
            .map((e) => WeightEntry.fromJson(jsonDecode(e) as Map<String, dynamic>))
            .toList();
        _weightHistory.sort((a, b) => b.date.compareTo(a.date));
      }
      final milkJson = _prefs.getStringList('milk_history');
      if (milkJson != null) {
        _milkHistory = milkJson
            .map((e) => MilkEntry.fromJson(jsonDecode(e) as Map<String, dynamic>))
            .toList();
        _milkHistory.sort((a, b) => b.date.compareTo(a.date));
      }
    });
  }

  Future<void> _addWeight() async {
    final text = _weightController.text.trim();
    if (text.isEmpty) return;
    final w = double.tryParse(text);
    if (w == null) return;
    final entry = WeightEntry(DateTime.now(), w);
    setState(() {
      _weightHistory.insert(0, entry);
    });
    await _saveWeightHistory();
    _weightController.clear();
  }

  Future<void> _addMilk() async {
    final text = _milkController.text.trim();
    if (text.isEmpty) return;
    final amount = double.tryParse(text);
    if (amount == null) return;
    final entry = MilkEntry(DateTime.now(), amount);
    setState(() {
      _milkHistory.insert(0, entry);
    });
    await _saveMilkHistory();
    _milkController.clear();
  }

  Future<void> _saveWeightHistory() async {
    final List<String> jsonList = _weightHistory.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList('weight_history', jsonList);
  }

  Future<void> _saveMilkHistory() async {
    final List<String> jsonList = _milkHistory.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList('milk_history', jsonList);
  }

  Future<void> _deleteWeight(int index) async {
    setState(() {
      _weightHistory.removeAt(index);
    });
    await _saveWeightHistory();
  }

  Future<void> _deleteMilk(int index) async {
    setState(() {
      _milkHistory.removeAt(index);
    });
    await _saveMilkHistory();
  }

  void _editWeight(int index) {
    final entry = _weightHistory[index];
    final controller = TextEditingController(text: entry.weight.toString());
    DateTime selectedDate = entry.date;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(entry.date);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('修改体重记录'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '体重 (kg)'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('日期'),
                subtitle: Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedDate = picked;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text('时间'),
                subtitle: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedTime = picked;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final newWeight = double.tryParse(controller.text);
                if (newWeight != null) {
                  final newDate = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                  setState(() {
                    _weightHistory[index] = WeightEntry(newDate, newWeight);
                  });
                  _saveWeightHistory();
                }
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _editMilk(int index) {
    final entry = _milkHistory[index];
    final controller = TextEditingController(text: entry.amount.toString());
    DateTime selectedDate = entry.date;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(entry.date);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('修改奶量记录'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: '奶量 (ml)'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('日期'),
                subtitle: Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedDate = picked;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text('时间'),
                subtitle: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedTime = picked;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final newAmount = double.tryParse(controller.text);
                if (newAmount != null) {
                  final newDate = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                  setState(() {
                    _milkHistory[index] = MilkEntry(newDate, newAmount);
                  });
                  _saveMilkHistory();
                }
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildWeightSpots() {
    final List<WeightEntry> sorted = List.from(_weightHistory)..sort((a,b)=> a.date.compareTo(b.date));
    return List.generate(sorted.length, (i) {
      return FlSpot(i.toDouble(), sorted[i].weight);
    });
  }

  List<FlSpot> _buildMilkSpots() {
    final List<MilkEntry> sorted = List.from(_milkHistory)..sort((a,b)=> a.date.compareTo(b.date));
    return List.generate(sorted.length, (i) {
      return FlSpot(i.toDouble(), sorted[i].amount);
    });
  }

  double _getMilkTotalForDay(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _milkHistory
        .where((e) => e.date.isAfter(startOfDay) && e.date.isBefore(endOfDay))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double _getMilkTotalForWeek() {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    return _milkHistory
        .where((e) => e.date.isAfter(startOfWeek) || e.date.isAtSameMomentAs(startOfWeek))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double _getMilkTotalForMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _milkHistory
        .where((e) => e.date.isAfter(startOfMonth) || e.date.isAtSameMomentAs(startOfMonth))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  String _dateLabel(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _timeLabel(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    return Scaffold(
      appBar: AppBar(title: const Text("萌宝笔记")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedTab = 0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 0 ? Colors.green.shade100 : Colors.grey.shade200,
                    ),
                    child: const Text('体重记录'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedTab = 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 1 ? Colors.orange.shade100 : Colors.grey.shade200,
                    ),
                    child: const Text('奶量统计'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0 ? _buildWeightTab(cardColor) : _buildMilkTab(cardColor),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightTab(Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('成长曲线', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _buildWeightSpots(),
                            isCurved: true,
                            color: Theme.of(context).colorScheme.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('记录体重', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: '体重 (kg)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _addWeight, child: const Text('保存')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('历史记录', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: _weightHistory.isEmpty
                        ? const Center(child: Text('暂无记录'))
                        : ListView.builder(
                            itemCount: _weightHistory.length,
                            itemBuilder: (ctx, idx) {
                              final e = _weightHistory[idx];
                              final dateStr = _dateLabel(e.date);
                              final timeStr = _timeLabel(e.date);
                              return ListTile(
                                title: Text('$dateStr $timeStr'),
                                trailing: Text('${e.weight.toStringAsFixed(1)} kg'),
                                onTap: () => _editWeight(idx),
                                onLongPress: () => _deleteWeight(idx),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilkTab(Color cardColor) {
    final today = _getMilkTotalForDay(DateTime.now());
    final week = _getMilkTotalForWeek();
    final month = _getMilkTotalForMonth();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('奶量统计', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('今日', today, Colors.orange),
                      _buildStatItem('本周', week, Colors.blue),
                      _buildStatItem('本月', month, Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('奶量趋势', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _buildMilkSpots(),
                            isCurved: true,
                            color: Colors.orange,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('记录奶量', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _milkController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: '奶量 (ml)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _addMilk, child: const Text('保存')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('历史记录', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: _milkHistory.isEmpty
                        ? const Center(child: Text('暂无记录'))
                        : ListView.builder(
                            itemCount: _milkHistory.length,
                            itemBuilder: (ctx, idx) {
                              final e = _milkHistory[idx];
                              final dateStr = _dateLabel(e.date);
                              final timeStr = _timeLabel(e.date);
                              return ListTile(
                                title: Text('$dateStr $timeStr'),
                                trailing: Text('${e.amount.toStringAsFixed(0)} ml'),
                                onTap: () => _editMilk(idx),
                                onLongPress: () => _deleteMilk(idx),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          '${value.toStringAsFixed(0)} ml',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}