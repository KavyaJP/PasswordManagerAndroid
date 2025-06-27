import 'package:flutter/material.dart';
import 'lock_screen.dart';
import 'home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Password Manager',
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  bool _unlocked = false;
  DateTime? _lastPaused;
  bool _shouldCheckLock = true; // 👈 new flag

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      _shouldCheckLock = true; // allow next resume to trigger lock check
    } else if (state == AppLifecycleState.resumed) {
      if (!_shouldCheckLock) return; // 👈 skip if unlock just happened

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
      _shouldCheckLock = false; // 👈 skip lock check on immediate resume
    });
  }

  @override
  Widget build(BuildContext context) {
    return _unlocked
        ? const HomeScreen()
        : LockScreen(onAuthenticated: _onAuthenticated);
  }
}


// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Your Vault")),
//       body: const Center(child: Text("🔐 Vault unlocked!")),
//     );
//   }
// }
