import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_v2ray_plus/flutter_v2ray.dart';
import 'package:vpn_permission/vpn_permission.dart';

import '../core/app_environment.dart';
import '../core/vpn_connection_exception.dart';
import '../models/server_node.dart';
import 'direct_apps_service.dart';
import 'vless_config_builder.dart';

class VpnController {
  VpnController() : _v2ray = FlutterV2ray();

  final FlutterV2ray _v2ray;
  final ValueNotifier<VlessStatus> status = ValueNotifier(VlessStatus());

  StreamSubscription<VlessStatus>? _statusSub;
  bool _initialized = false;
  String? coreVersion;
  List<String> _bypassApps = [];

  FlutterV2ray get v2ray => _v2ray;

  Future<void> initialize() async {
    if (_initialized) return;
    await _v2ray.initializeVless(
      notificationIconResourceType: 'mipmap',
      notificationIconResourceName: 'ic_launcher',
      providerBundleIdentifier: AppEnvironment.current.providerBundleIdentifier,
      groupIdentifier: AppEnvironment.current.groupIdentifier,
    );
    coreVersion = await _v2ray.getCoreVersion();
    _statusSub?.cancel();
    _statusSub = _v2ray.onStatusChanged.listen((s) {
      status.value = s;
    });
    _initialized = true;
    if (!AppEnvironment.current.isTv) {
      await refreshBypassApps();
    }
  }

  List<String> get bypassApps => List.unmodifiable(_bypassApps);

  Future<void> refreshBypassApps({bool forceRefresh = false}) async {
    if (AppEnvironment.current.isTv) {
      _bypassApps = const [];
      return;
    }
    _bypassApps = await DirectAppsService.instance.load(
      forceRefresh: forceRefresh,
    );
  }

  Future<List<String>> _resolveBypassApps() async {
    if (_bypassApps.isEmpty) {
      await refreshBypassApps();
    }
    return _bypassApps;
  }

  bool get isConnected =>
      status.value.state.toUpperCase() == 'CONNECTED';

  /// Запрос системного разрешения VPN.
  Future<bool> requestPermission() async {
    if (await VpnPermission.checkPermission()) {
      return true;
    }
    // На TV только VpnService.prepare через v2ray — без второго диалога vpn_permission.
    if (AppEnvironment.current.isTv) {
      final granted = await _v2ray.requestPermission();
      if (!granted) return false;
      return VpnPermission.checkPermission();
    }
    final granted = await VpnPermission.requestPermission(
      providerBundleIdentifier: AppEnvironment.current.providerBundleIdentifier,
      groupIdentifier: AppEnvironment.current.groupIdentifier,
      localizedDescription: AppEnvironment.current.localizedDescription,
    );
    if (granted) {
      return true;
    }
    return _v2ray.requestPermission();
  }

  Future<bool> hasPermission() => VpnPermission.checkPermission();

  Future<String> _securedConfig(ServerNode server) =>
      VlessConfigBuilder.fromShareLink(server.shareLink);

  Future<int> measureDelay(ServerNode server) async {
    // 10815 (tun SOCKS) с паролем — getConnectedServerDelay без auth не подходит.
    final config = await _securedConfig(server);
    return _v2ray.getServerDelay(config: config);
  }

  Future<void> connect(ServerNode server) async {
    final allowed = await requestPermission();
    if (!allowed) {
      throw VpnConnectionException('Разрешение VPN не предоставлено');
    }
    // Сброс зависшего VPN после неудачного подключения.
    final state = status.value.state.toUpperCase();
    if (state == 'CONNECTED' || state == 'CONNECTING') {
      await disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }
    final config = await _securedConfig(server);
    final bypassApps = AppEnvironment.current.isTv
        ? const <String>[]
        : await _resolveBypassApps();
    await _v2ray.startVless(
      remark: server.remark,
      config: config,
      blockedApps: bypassApps,
      bypassSubnets: const ['0.0.0.0/0'],
      proxyOnly: false,
      notificationDisconnectButtonName: 'Отключить',
    );

    if (AppEnvironment.current.isTv) {
      await _waitForTvConnection();
    }
  }

  /// TV: [startVless] возвращается сразу; ждём реальный статус CONNECTED.
  Future<void> _waitForTvConnection({
    Duration timeout = const Duration(seconds: 45),
  }) async {
    if (isConnected) return;

    final startedAt = DateTime.now();
    final deadline = startedAt.add(timeout);
    var sawConnecting = status.value.state.toUpperCase() == 'CONNECTING';

    StreamSubscription<VlessStatus>? sub;
    sub = _v2ray.onStatusChanged.listen((s) {
      status.value = s;
    });

    const failureAfterStart = Duration(seconds: 2);
    const tvConnectFailedMessage =
        'VPN не подключился. На приставке: Настройки → Сеть → VPN — '
        'отключите другой VPN. Затем в VPN-SC TV нажмите «Подключить» '
        'и в системном окне выберите «ОК» / «Разрешить».';

    try {
      while (DateTime.now().isBefore(deadline)) {
        final st = status.value.state.toUpperCase();
        final elapsed = DateTime.now().difference(startedAt);

        if (st == 'CONNECTING') sawConnecting = true;
        if (st == 'CONNECTED') return;

        if (st == 'DISCONNECTED' &&
            elapsed > failureAfterStart &&
            (sawConnecting || elapsed > const Duration(seconds: 5))) {
          throw VpnConnectionException(tvConnectFailedMessage);
        }

        await Future<void>.delayed(const Duration(milliseconds: 250));
      }

      throw VpnConnectionException(
        sawConnecting
            ? 'Таймаут подключения (${timeout.inSeconds} с). '
                'Проверьте интернет и сервер.'
            : 'VPN не ответил. Разрешите VPN для VPN-SC TV '
                '(Настройки → Приложения → VPN-SC TV) '
                'и отключите другой VPN в Настройки → Сеть → VPN.',
      );
    } finally {
      await sub.cancel();
    }
  }

  Future<void> disconnect() async {
    await _v2ray.stopVless();
    if (AppEnvironment.current.isTv) {
      await _waitForTvDisconnect();
    }
  }

  /// TV: ждём DISCONNECTED после stopVless (broadcast из VPN-процесса).
  Future<void> _waitForTvDisconnect({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (status.value.state.toUpperCase() == 'DISCONNECTED') return;

    final deadline = DateTime.now().add(timeout);
    StreamSubscription<VlessStatus>? sub;
    sub = _v2ray.onStatusChanged.listen((s) {
      status.value = s;
    });

    try {
      while (DateTime.now().isBefore(deadline)) {
        if (status.value.state.toUpperCase() == 'DISCONNECTED') return;
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      status.value = VlessStatus(state: 'DISCONNECTED');
    } finally {
      await sub.cancel();
    }
  }

  void dispose() {
    _statusSub?.cancel();
    status.dispose();
  }
}
