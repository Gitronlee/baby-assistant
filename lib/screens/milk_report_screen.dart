import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';

class MilkReportScreen extends StatefulWidget {
  const MilkReportScreen({super.key});
  @override
  _MilkReportScreenState createState() => _MilkReportScreenState();
}

class MilkRecord {
  final DateTime date;
  final double amount;
  MilkRecord(this.date, this.amount);
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'amount': amount,
  };
  static MilkRecord fromJson(Map<String, dynamic> json) => MilkRecord(
        DateTime.parse(json['date']),
        (json['amount'] as num).toDouble(),
      );
}

class _MilkReportScreenState extends State<MilkReportScreen> {
  final TextEditingController _controller = TextEditingController();
  List<MilkRecord> _records = [];
  int _daysWindow = 7;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = _prefs.getStringList('milk_records');
    if (jsonList != null) {
      setState(() {
        _records = jsonList
            .map((e) => MilkRecord.fromJson(jsonDecode(e) as Map<String, dynamic>))
            .toList();
        _records.sort((a,b)=> b.date.compareTo(a.date));
      });
    }
  }

  Future<void> _addRecord() async {
    final val = double.tryParse(_controller.text.trim());
    if (val == null) return;
    final r = MilkRecord(DateTime.now(), val);
    setState(() => _records.insert(0, r));
    final List<String> jsonList = _records.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList('milk_records', jsonList);
    _controller.clear();
  }

  List<FlSpot> _buildSpots7or30() {
    final DateTime end = DateTime.now();
    final DateTime start = end.subtract(Duration(days: _daysWindow - 1));
    List<MilkRecord> window = _records.where((r) => r.date.isAfter(start) || r.date.isAtSameMomentAs(start)).toList();
    window.sort((a,b)=> a.date.compareTo(b.date));
    return List.generate(window.length, (i) {
      return FlSpot(i.toDouble(), window[i].amount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final spots = _buildSpots7or30();
    return Scaffold(
      appBar: AppBar(title: const Text("奶量统计")),
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
                    Text('Totals', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    _TotalsView(records: _records),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true, drawVerticalLine: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: Theme.of(context).colorScheme.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Days window'),
                        Row(
                          children: [
                            TextButton(onPressed: () { setState(() { _daysWindow = 7; }); }, child: const Text('7d')),
                            TextButton(onPressed: () { setState(() { _daysWindow = 30; }); }, child: const Text('30d')),
                          ],
                        )
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
                    Text('Add Milk', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Milk amount (ml)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: _addRecord, child: const Text('Add')),
                      ],
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

class _TotalsView extends StatelessWidget {
  final List<MilkRecord> records;
  const _TotalsView({required this.records});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todaySum = records.where((r) => DateTime(r.date.year, r.date.month, r.date.day) == today).fold(0.0, (s, r) => s + r.amount);
    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final weekSum = records.where((r) => r.date.isAfter(weekStart) || r.date.isAtSameMomentAs(weekStart)).fold(0.0, (s, r) => s + r.amount);
    final monthStart = DateTime(now.year, now.month, 1);
    final monthSum = records.where((r) => r.date.isAfter(monthStart) || r.date.isAtSameMomentAs(monthStart)).fold(0.0, (s, r) => s + r.amount);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StatTile(label: 'Today', value: todaySum),
        _StatTile(label: 'This Week', value: weekSum),
        _StatTile(label: 'This Month', value: monthSum),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label; final double value;
  const _StatTile({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 4),
              Text('${value.toStringAsFixed(0)} ml', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}