import 'dart:convert';

import 'package:flutter_v2ray_plus/flutter_v2ray.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/server_node.dart';

class SubscriptionResult {
  const SubscriptionResult({
    required this.servers,
    this.fromCache = false,
    this.errorMessage,
  });

  final List<ServerNode> servers;
  final bool fromCache;
  final String? errorMessage;
}

class SubscriptionService {
  static const subscriptionUrl =
      'https://connect.vpn-sc.com/?id=c177b636-01a1-42be-953a-f240b508ac0a';

  static const Map<String, String> headers = {
    'User-Agent': 'VPN-SC',
  };

  static const _cacheKey = 'subscription_servers_cache';

  Future<SubscriptionResult> fetchServers() async {
    try {
      final response = await http
          .get(Uri.parse(subscriptionUrl), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 403) {
        final cached = await _loadCache();
        return SubscriptionResult(
          servers: cached,
          fromCache: cached.isNotEmpty,
          errorMessage:
              'Доступ запрещён (403). Требуется заголовок User-Agent: VPN-SC.',
        );
      }

      if (response.statusCode != 200) {
        final cached = await _loadCache();
        return SubscriptionResult(
          servers: cached,
          fromCache: cached.isNotEmpty,
          errorMessage: 'Ошибка сервера: ${response.statusCode}',
        );
      }

      final servers = _parseBody(response.body);
      if (servers.isEmpty) {
        final cached = await _loadCache();
        return SubscriptionResult(
          servers: cached,
          fromCache: cached.isNotEmpty,
          errorMessage: 'Список серверов пуст',
        );
      }

      await _saveCache(servers);
      return SubscriptionResult(servers: servers);
    } catch (e) {
      final cached = await _loadCache();
      return SubscriptionResult(
        servers: cached,
        fromCache: cached.isNotEmpty,
        errorMessage: 'Нет сети или таймаут: $e',
      );
    }
  }

  List<ServerNode> _parseBody(String body) {
    final text = _normalizeBody(body.trim());
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final servers = <ServerNode>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!line.startsWith('vless://') &&
          !line.startsWith('vmess://') &&
          !line.startsWith('trojan://')) {
        continue;
      }
      try {
        final parsed = FlutterV2ray.parseFromURL(line);
        final remark = parsed.remark.isNotEmpty ? parsed.remark : 'Сервер ${i + 1}';
        servers.add(
          ServerNode(
            id: '${remark}_$i',
            remark: remark,
            shareLink: line,
            configJson: parsed.getFullConfiguration(),
          ),
        );
      } catch (_) {
        continue;
      }
    }
    return servers;
  }

  String _normalizeBody(String body) {
    if (body.contains('vless://') || body.contains('vmess://')) {
      return body;
    }
    try {
      final decoded = utf8.decode(base64.decode(body));
      if (decoded.contains('vless://') || decoded.contains('vmess://')) {
        return decoded;
      }
    } catch (_) {}
    return body;
  }

  Future<void> _saveCache(List<ServerNode> servers) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(servers.map((s) => s.toJson()).toList());
    await prefs.setString(_cacheKey, encoded);
  }

  Future<List<ServerNode>> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ServerNode.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
