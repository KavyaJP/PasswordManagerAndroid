import 'dart:math';

class PasswordGenerator {
  static const String _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()-_=+[]{}|;:,.<>?';

  static String generate({
    int length = 16,
    bool includeUpper = true,
    bool includeLower = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
  }) {
    String chars = '';
    if (includeUpper) chars += _upper;
    if (includeLower) chars += _lower;
    if (includeNumbers) chars += _numbers;
    if (includeSymbols) chars += _symbols;

    if (chars.isEmpty) return '';

    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
