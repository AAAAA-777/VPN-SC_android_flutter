import 'dart:convert';

import 'package:flutter_v2ray_plus/flutter_v2ray.dart';

import 'local_proxy_auth.dart';

/// Защищённый локальный прокси + отдельный SOCKS для VPN-туннеля.
///
/// [publicSocksPort] — с паролем (детект VPN сторонними приложениями).
/// [tunSocksPort] — без пароля (только tun2socks).
class VlessConfigBuilder {
  static const publicSocksPort = 10807;
  static const httpPort = 10808;
  static const tunSocksPort = 10815;

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

    inbounds.removeWhere((ib) {
      final tag = ib['tag'] as String?;
      return tag == 'in_proxy' || tag == 'tun_internal' || tag == 'http_local';
    });

    inbounds.insert(0, _publicSocksInbound(creds));
    inbounds.insert(1, _tunSocksInbound());
    inbounds.add(_httpInbound(creds));

    config['inbounds'] = inbounds;
    config['vpnScLocalProxy'] = {
      'user': '',
      'pass': '',
      'socksPort': tunSocksPort,
    };
    return jsonEncode(config);
  }

  static Map<String, dynamic> _publicSocksInbound(LocalProxyCredentials creds) =>
      {
        'tag': 'in_proxy',
        'port': publicSocksPort,
        'protocol': 'socks',
        'listen': '127.0.0.1',
        'settings': {
          'auth': 'password',
          'accounts': [
            {'user': creds.user, 'pass': creds.pass},
          ],
          'udp': true,
          'userLevel': 8,
        },
        'sniffing': {'enabled': false},
      };

  static Map<String, dynamic> _tunSocksInbound() => {
        'tag': 'tun_internal',
        'port': tunSocksPort,
        'protocol': 'socks',
        'listen': '127.0.0.1',
        'settings': {
          'auth': 'noauth',
          'udp': true,
          'userLevel': 8,
        },
        'sniffing': {
          'enabled': true,
          'destOverride': ['http', 'tls'],
        },
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
