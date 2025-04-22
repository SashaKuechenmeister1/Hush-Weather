import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final bool isMetric;
  final bool isDarkMode;
  final ValueChanged<bool> onUnitChanged;
  final ValueChanged<bool> onThemeChanged;

  const SettingsPage({
    Key? key,
    required this.isMetric,
    required this.isDarkMode,
    required this.onUnitChanged,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _isMetric;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isMetric = widget.isMetric;
    _isDarkMode = widget.isDarkMode;
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMetric', _isMetric);
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: _isDarkMode ? Colors.black : Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        color: _isDarkMode ? Colors.black : Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Temperature Units",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            SwitchListTile(
              title: Text(
                "Use Metric (Celsius)",
                style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
              ),
              value: _isMetric,
              onChanged: (value) {
                setState(() {
                  _isMetric = value;
                });
                widget.onUnitChanged(value);
                _savePreferences();
              },
            ),
            const SizedBox(height: 20),
            Text(
              "Theme",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            SwitchListTile(
              title: Text(
                "Dark Mode",
                style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
              ),
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
                widget.onThemeChanged(value);
                _savePreferences();
              },
            ),
          ],
        ),
      ),
    );
  }
}