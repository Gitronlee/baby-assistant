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
    final List<String> jsonList = _weightHistory.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList('weight_history', jsonList);
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
    final List<String> jsonList = _milkHistory.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList('milk_history', jsonList);
    _milkController.clear();
  }

  Future<void> _deleteWeight(int index) async {
    setState(() {
      _weightHistory.removeAt(index);
    });
    final List<String> jsonList = _weightHistory.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList('weight_history', jsonList);
  }

  Future<void> _deleteMilk(int index) async {
    setState(() {
      _milkHistory.removeAt(index);
    });
    final List<String> jsonList = _milkHistory.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList('milk_history', jsonList);
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

  String _dateLabel(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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
                              return ListTile(
                                title: Text(dateStr),
                                trailing: Text('${e.weight.toStringAsFixed(1)} kg'),
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
                              return ListTile(
                                title: Text(dateStr),
                                trailing: Text('${e.amount.toStringAsFixed(0)} ml'),
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
}