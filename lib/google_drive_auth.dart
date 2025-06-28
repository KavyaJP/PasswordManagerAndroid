import 'package:google_sign_in/google_sign_in.dart';

class GoogleDriveAuth {
  static final _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file', // access to user's files created by your app
    ],
  );

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      print("Google sign-in error: $e");
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  static Future<String?> getAccessToken() async {
    final account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    final auth = await account?.authentication;
    return auth?.accessToken;
  }

  static bool isSignedIn() {
    return _googleSignIn.currentUser != null;
  }

  static GoogleSignInAccount? currentUser() {
    return _googleSignIn.currentUser;
  }
}

