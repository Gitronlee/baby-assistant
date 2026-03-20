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

class _WeightScreenState extends State<WeightScreen> {
  final TextEditingController _controller = TextEditingController();
  List<WeightEntry> _history = [];
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = _prefs.getStringList('weight_history');
    if (jsonList != null) {
      setState(() {
        _history = jsonList
            .map((e) => WeightEntry.fromJson(jsonDecode(e) as Map<String, dynamic>))
            .toList();
        _history.sort((a, b) => b.date.compareTo(a.date));
      });
    }
  }

  Future<void> _addEntry() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final w = double.tryParse(text);
    if (w == null) return;
    final entry = WeightEntry(DateTime.now(), w);
    setState(() {
      _history.insert(0, entry);
    });
    final List<String> jsonList = _history.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList('weight_history', jsonList);
    _controller.clear();
  }

  Future<void> _deleteEntry(int index) async {
    setState(() {
      _history.removeAt(index);
    });
    final List<String> jsonList = _history.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList('weight_history', jsonList);
  }

  List<FlSpot> _buildSpots() {
    final List<WeightEntry> sorted = List.from(_history)..sort((a,b)=> a.date.compareTo(b.date));
    return List.generate(sorted.length, (i) {
      return FlSpot(i.toDouble(), sorted[i].weight);
    });
  }

  String _dateLabel(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    return Scaffold(
      appBar: AppBar(title: const Text("小宝记重")),
      body: SingleChildScrollView(
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
                    Text('Growth Chart', style: Theme.of(context).textTheme.titleLarge),
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
                              spots: _buildSpots(),
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
                    Text('Add Weight', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Weight (kg)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: _addEntry, child: const Text('Save')),
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
                    Text('History', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: _history.isEmpty
                          ? Center(child: const Text('No records yet'))
                          : ListView.builder(
                              itemCount: _history.length,
                              itemBuilder: (ctx, idx) {
                                final e = _history[idx];
                                final dateStr = _dateLabel(e.date);
                                return ListTile(
                                  title: Text(dateStr),
                                  trailing: Text('${e.weight.toStringAsFixed(1)} kg'),
                                  onLongPress: () => _deleteEntry(idx),
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
      ),
    );
  }
}