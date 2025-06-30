import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

import 'lock_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkTheme') ?? false;

  runApp(MyApp(initialThemeMode: isDark ? ThemeMode.dark : ThemeMode.light));
}

class MyApp extends StatefulWidget {
  final ThemeMode initialThemeMode;
  const MyApp({super.key, required this.initialThemeMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late ValueNotifier<ThemeMode> _themeNotifier;
  final ValueNotifier<bool> _isUnlocked = ValueNotifier(false);
  DateTime? _lastPaused;
  bool _shouldCheckLock = true;

  @override
  void initState() {
    super.initState();
    _themeNotifier = ValueNotifier(widget.initialThemeMode);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerAuth());
  }

  void _toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', isDark);
    _themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void _triggerAuth() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final localAuth = LocalAuthentication();
    final canCheck = await localAuth.canCheckBiometrics || await localAuth.isDeviceSupported();

    if (canCheck) {
      final didAuth = await localAuth.authenticate(
        localizedReason: 'Please authenticate to access your vault',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuth) {
        _isUnlocked.value = true;
        _shouldCheckLock = false;
      }
    }
  }

  void _manualLock() {
    _isUnlocked.value = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      _lastPaused = DateTime.now();
      _shouldCheckLock = true;
    } else if (state == AppLifecycleState.resumed) {
      if (!_shouldCheckLock) return;

      final prefs = await SharedPreferences.getInstance();
      final timeout = prefs.getInt('autoLockTimeout') ?? 60;

      if (_lastPaused != null && timeout > 0) {
        final duration = DateTime.now().difference(_lastPaused!);
        if (duration.inSeconds > timeout) {
          _isUnlocked.value = false;
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeNotifier.dispose();
    _isUnlocked.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Password Manager',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: mode,
          routes: {
            '/settings': (context) => SettingsScreen(
              onThemeChanged: _toggleTheme,
              isDarkTheme: mode == ThemeMode.dark,
            ),
          },
          home: ValueListenableBuilder<bool>(
            valueListenable: _isUnlocked,
            builder: (context, unlocked, _) {
              return unlocked
                  ? HomeScreen(
                onThemeChanged: _toggleTheme,
                isDarkTheme: mode == ThemeMode.dark,
                onManualLock: _manualLock,
              )
                  : LockScreen(
                onAuthenticated: () {
                  _isUnlocked.value = true;
                  _shouldCheckLock = false;
                },
              );
            },
          ),
        );
      },
    );
  }
}
