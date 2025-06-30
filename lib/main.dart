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

class _MyAppState extends State<MyApp> {
  late ValueNotifier<ThemeMode> _themeNotifier;

  @override
  void initState() {
    super.initState();
    _themeNotifier = ValueNotifier(widget.initialThemeMode);
  }

  void _toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', isDark);
    _themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
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
          home: AuthGate(
            onThemeChanged: _toggleTheme,
            isDark: mode == ThemeMode.dark,
          ),
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  final void Function(bool isDark) onThemeChanged;
  final bool isDark;
  const AuthGate({super.key, required this.onThemeChanged, required this.isDark});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  bool _unlocked = false;
  DateTime? _lastPaused;
  bool _shouldCheckLock = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerAuth());
  }

  void _triggerAuth() async {
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 500));

    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;

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

      if (didAuth && mounted) {
        setState(() {
          _unlocked = true;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastPaused = DateTime.now();
      _shouldCheckLock = true;
    } else if (state == AppLifecycleState.resumed) {
      if (!_shouldCheckLock) return;

      if (_lastPaused != null) {
        final duration = DateTime.now().difference(_lastPaused!);
        if (duration.inSeconds > 10) {
          setState(() {
            _unlocked = false;
          });
        }
      }
    }
  }

  void _onAuthenticated() {
    setState(() {
      _unlocked = true;
      _shouldCheckLock = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _unlocked
        ? HomeScreen(
      onThemeChanged: widget.onThemeChanged,
      isDarkTheme: widget.isDark,
    )
        : LockScreen(onAuthenticated: _onAuthenticated);
  }
}
