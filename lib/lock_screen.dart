import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

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
    _authenticate(); // Trigger authentication as soon as screen opens
  }

  Future<void> _authenticate() async {
    print("🔐 Starting authentication...");

    try {
      bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Authenticate to unlock your password vault',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      print("✅ Authentication result: $didAuthenticate");

      if (didAuthenticate) {
        widget.onAuthenticated();
      }
    } catch (e) {
      print("❌ Authentication error: $e");
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
