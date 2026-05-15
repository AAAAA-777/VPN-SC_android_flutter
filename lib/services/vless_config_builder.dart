import 'dart:convert';

import 'package:flutter_v2ray_plus/flutter_v2ray.dart';

import 'local_proxy_auth.dart';

/// Два локальных SOCKS с одной парой учётных данных.
///
/// [publicSocksPort] — для внешних проверок (отдельный порт).
/// [tunSocksPort] — только tun2socks; с паролем, иначе сторонние приложения
/// на 127.0.0.1:10815 обходят детект (VPN Dead и аналоги).
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
    inbounds.insert(1, _tunSocksInbound(creds));
    inbounds.add(_httpInbound(creds));

    config['inbounds'] = inbounds;
    config['vpnscLocalProxy'] = {
      'user': creds.user,
      'pass': creds.pass,
      'socksPort': tunSocksPort,
    };
    _applyDirectZoneRouting(config);
    return jsonEncode(config);
  }

  /// Punycode зоны .рф (без кириллицы в конфиге Xray).
  static const rfZonePunycode = 'xn--p1ai';

  /// Трафик к зонам .ru и .рф (через regexp + punycode) — outbound [direct].
  static void _applyDirectZoneRouting(Map<String, dynamic> config) {
    final routing =
        (config['routing'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    routing['domainStrategy'] = 'AsIs';

    final rules =
        (routing['rules'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[];

    rules.insert(0, {
      'type': 'field',
      'domain': [
        r'regexp:(?i)(^|.*\.)ru$',
        'regexp:(?i)(^|.*\\.)$rfZonePunycode\$',
      ],
      'outboundTag': 'direct',
    });

    routing['rules'] = rules;
    config['routing'] = routing;
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

  static Map<String, dynamic> _tunSocksInbound(LocalProxyCredentials creds) =>
      {
        'tag': 'tun_internal',
        'port': tunSocksPort,
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
