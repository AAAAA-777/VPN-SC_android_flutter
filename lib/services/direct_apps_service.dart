import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Приложения из списка [directListUrl] идут в обход VPN (прямой интернет).
/// В flutter_v2ray_plus это параметр `blockedApps` → `addDisallowedApplication`.
class DirectAppsService {
  DirectAppsService._();
  static final DirectAppsService instance = DirectAppsService._();

  static const directListUrl =
      'https://vpn-sc.com/api/route/direct_android.txt';

  static const _cacheKey = 'direct_android_package_ids';
  static final _packageIdPattern = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$');

  List<String> _cached = [];

  List<String> get cached => List.unmodifiable(_cached);

  Future<List<String>> load({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached.isNotEmpty) {
      return _cached;
    }

    final fromDisk = await _readCache();
    if (!forceRefresh && fromDisk.isNotEmpty) {
      _cached = fromDisk;
    }

    try {
      final response = await http
          .get(
            Uri.parse(directListUrl),
            headers: const {'User-Agent': 'VPN-SC'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final parsed = _parseBody(response.body);
        if (parsed.isNotEmpty) {
          _cached = parsed;
          await _writeCache(parsed);
          return _cached;
        }
      }
    } catch (_) {}

    if (_cached.isEmpty && fromDisk.isNotEmpty) {
      _cached = fromDisk;
    }
    return _cached;
  }

  List<String> _parseBody(String body) {
    final ids = <String>{};
    for (final raw in body.split(RegExp(r'\r?\n'))) {
      final line = raw.trim().toLowerCase();
      if (line.isEmpty) continue;
      if (!_packageIdPattern.hasMatch(line)) continue;
      ids.add(line);
    }
    return ids.toList()..sort();
  }

  Future<List<String>> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).where(_packageIdPattern.hasMatch).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeCache(List<String> packages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(packages));
  }
}
