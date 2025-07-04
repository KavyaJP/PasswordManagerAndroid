import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const LockScreen({required this.onAuthenticated, super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkIfLockEnabled();
    _authenticate(); // Trigger authentication as soon as screen opens
  }

  Future<void> _checkIfLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final isLockEnabled = prefs.getBool('lock_enabled') ?? false;

    if (isLockEnabled) {
      _authenticate();
    } else {
      widget.onAuthenticated();
    }
  }

  Future<void> _authenticate() async {
    try {
      bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Authenticate to unlock your password vault',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (didAuthenticate) {
        widget.onAuthenticated();
      }
    } catch (e) {
      _authenticate();
    }
  }


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Authenticating...',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
