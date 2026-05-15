import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class LocalProxyCredentials {
  const LocalProxyCredentials({required this.user, required this.pass});

  final String user;
  final String pass;
}

/// Учётные данные локального SOCKS/HTTP (127.0.0.1).
/// Без логина/пароля сторонние приложения не смогут использовать прокси для детекта VPN.
class LocalProxyAuth {
  static const _userKey = 'local_proxy_user';
  static const _passKey = 'local_proxy_pass';

  static final _random = Random.secure();

  static Future<LocalProxyCredentials> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    var user = prefs.getString(_userKey);
    var pass = prefs.getString(_passKey);
    if (user == null || pass == null || user.isEmpty || pass.isEmpty) {
      user = _token(16);
      pass = _token(24);
      await prefs.setString(_userKey, user);
      await prefs.setString(_passKey, pass);
    }
    return LocalProxyCredentials(user: user, pass: pass);
  }

  static String _token(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (_) => chars[_random.nextInt(chars.length)]).join();
  }
}
