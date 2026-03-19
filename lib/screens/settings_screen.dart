import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedNoise = 'Hair Dryer';
  int _intervalMin = 30;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedNoise = _prefs.getString('noise_source') ?? 'Hair Dryer';
      _intervalMin = _prefs.getInt('feed_interval_min') ?? 30;
    });
  }

  Future<void> _save() async {
    await _prefs.setString('noise_source', _selectedNoise);
    await _prefs.setInt('feed_interval_min', _intervalMin);
  }

  void _donate() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your generosity!')));
  }

  void _openAbout() {
    Navigator.of(context).pushNamed('/about');
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Audio & Feeding Settings', style: Theme.of(context).textTheme.headline6),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedNoise,
                    items: const [
                      DropdownMenuItem(value: 'Hair Dryer', child: Text('Hair Dryer')),
                      DropdownMenuItem(value: 'Rain', child: Text('Rain')),
                      DropdownMenuItem(value: 'White Noise', child: Text('White Noise')),
                    ],
                    onChanged: (v) { setState(() { _selectedNoise = v ?? _selectedNoise; }); },
                    decoration: const InputDecoration(labelText: 'White Noise Source'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _intervalMin.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Feeding interval (min)'),
                    onChanged: (v) { final n = int.tryParse(v); if (n != null) _intervalMin = n; },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(onPressed: _save, child: const Text('Save')),
                      ElevatedButton(onPressed: _donate, child: const Text('Donate')),
                      ElevatedButton(onPressed: _openAbout, child: const Text('Help/About')),
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
}