import 'dart:convert';

import 'package:flutter_v2ray_plus/flutter_v2ray.dart';

import 'local_proxy_auth.dart';

/// Сборка Xray-конфига с защищённым локальным SOCKS/HTTP inbound.
class VlessConfigBuilder {
  static const socksPort = 10807;
  static const httpPort = 10808;

  static Future<String> fromShareLink(String shareLink) async {
    final parsed = FlutterV2ray.parseFromURL(shareLink);
    final creds = await LocalProxyAuth.getOrCreate();
    return applyLocalProxyAuth(parsed.getFullConfiguration(), creds);
  }

  static String applyLocalProxyAuth(
    String configJson,
    LocalProxyCredentials creds,
  ) {
    final config = jsonDecode(configJson) as Map<String, dynamic>;
    final inbounds =
        (config['inbounds'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    var hasSocks = false;
    var hasHttp = false;

    for (final inbound in inbounds) {
      final protocol = inbound['protocol'] as String?;
      if (protocol == 'socks') {
        hasSocks = true;
        inbound['port'] = socksPort;
        inbound['listen'] = '127.0.0.1';
        inbound['settings'] = {
          'auth': 'password',
          'users': [
            {'user': creds.user, 'pass': creds.pass},
          ],
          'udp': true,
          'userLevel': 8,
        };
      }
    }

    if (!hasSocks) {
      inbounds.insert(0, _socksInbound(creds));
    }

    for (final inbound in inbounds) {
      if (inbound['protocol'] == 'http') {
        hasHttp = true;
        inbound['port'] = httpPort;
        inbound['listen'] = '127.0.0.1';
        inbound['settings'] = {
          'accounts': [
            {'user': creds.user, 'pass': creds.pass},
          ],
        };
      }
    }

    if (!hasHttp) {
      inbounds.add(_httpInbound(creds));
    }

    config['inbounds'] = inbounds;
    config['vpnScLocalProxy'] = {
      'user': creds.user,
      'pass': creds.pass,
      'socksPort': socksPort,
    };
    return jsonEncode(config);
  }

  static Map<String, dynamic> _socksInbound(LocalProxyCredentials creds) =>
      {
        'tag': 'in_proxy',
        'port': socksPort,
        'protocol': 'socks',
        'listen': '127.0.0.1',
        'settings': {
          'auth': 'password',
          'users': [
            {'user': creds.user, 'pass': creds.pass},
          ],
          'udp': true,
          'userLevel': 8,
        },
        'sniffing': {'enabled': false},
      };

  static Map<String, dynamic> _httpInbound(LocalProxyCredentials creds) => {
        'tag': 'http_local',
        'port': httpPort,
        'protocol': 'http',
        'listen': '127.0.0.1',
        'settings': {
          'accounts': [
            {'user': creds.user, 'pass': creds.pass},
          ],
        },
      };
}
