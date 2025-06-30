import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final void Function(bool) onThemeChanged;
  final bool isDarkTheme;

  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
    required this.isDarkTheme,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _autoLockTimeout = 60; // default: 1 min
  int _clipboardClearTime = 10; // default: 10 seconds

  final List<int> _autoLockOptions = [15, 30, 60, 120, 300]; // in seconds
  final List<int> _clipboardOptions = [5, 10, 20, 30, 60];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoLockTimeout = prefs.getInt('autoLockTimeout') ?? 60;
      _clipboardClearTime = prefs.getInt('clipboardClearTime') ?? 10;
    });
  }

  Future<void> _updateAutoLockTimeout(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('autoLockTimeout', seconds);
    setState(() => _autoLockTimeout = seconds);
  }

  Future<void> _updateClipboardTimeout(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('clipboardClearTime', seconds);
    setState(() => _clipboardClearTime = seconds);
  }

  String _formatSeconds(int seconds) {
    if (seconds < 60) return "$seconds sec";
    return "${(seconds / 60).round()} min";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("⚙️ Settings")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("🌗 Dark Mode"),
            value: widget.isDarkTheme,
            onChanged: widget.onThemeChanged,
          ),

          const Divider(height: 32),

          const ListTile(
            title: Text("🔒 Auto-lock timeout"),
            subtitle: Text("Lock the app after a period of inactivity."),
          ),
          ..._autoLockOptions.map((seconds) => RadioListTile<int>(
            title: Text(_formatSeconds(seconds)),
            value: seconds,
            groupValue: _autoLockTimeout,
            onChanged: (value) {
              if (value != null) _updateAutoLockTimeout(value);
            },
          )),

          const Divider(height: 32),

          const ListTile(
            title: Text("📋 Clipboard auto-clear"),
            subtitle: Text("Clear copied password after a short duration."),
          ),
          ..._clipboardOptions.map((seconds) => RadioListTile<int>(
            title: Text(_formatSeconds(seconds)),
            value: seconds,
            groupValue: _clipboardClearTime,
            onChanged: (value) {
              if (value != null) _updateClipboardTimeout(value);
            },
          )),
        ],
      ),
    );
  }
}
