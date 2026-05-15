import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_v2ray_plus/flutter_v2ray.dart';
import 'package:vpn_permission/vpn_permission.dart';

import '../constants/app_constants.dart';
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
      providerBundleIdentifier: AppConstants.providerBundleIdentifier,
      groupIdentifier: AppConstants.groupIdentifier,
    );
    coreVersion = await _v2ray.getCoreVersion();
    _statusSub?.cancel();
    _statusSub = _v2ray.onStatusChanged.listen((s) {
      status.value = s;
    });
    _initialized = true;
    await refreshBypassApps();
  }

  List<String> get bypassApps => List.unmodifiable(_bypassApps);

  Future<void> refreshBypassApps({bool forceRefresh = false}) async {
    _bypassApps = await DirectAppsService.instance.load(
      forceRefresh: forceRefresh,
    );
  }

  bool get isConnected =>
      status.value.state.toUpperCase() == 'CONNECTED';

  /// Запрос системного разрешения VPN через [vpn_permission].
  Future<bool> requestPermission() async {
    if (await VpnPermission.checkPermission()) {
      return true;
    }
    final granted = await VpnPermission.requestPermission(
      providerBundleIdentifier: AppConstants.providerBundleIdentifier,
      groupIdentifier: AppConstants.groupIdentifier,
      localizedDescription: AppConstants.localizedDescription,
    );
    if (granted) {
      return true;
    }
    // Резервный запрос через ядро v2ray (тот же системный диалог на Android).
    return _v2ray.requestPermission();
  }

  Future<bool> hasPermission() => VpnPermission.checkPermission();

  Future<String> _securedConfig(ServerNode server) =>
      VlessConfigBuilder.fromShareLink(server.shareLink);

  Future<int> measureDelay(ServerNode server) async {
    if (isConnected) {
      return _v2ray.getConnectedServerDelay();
    }
    final config = await _securedConfig(server);
    return _v2ray.getServerDelay(config: config);
  }

  Future<void> connect(ServerNode server) async {
    final allowed = await requestPermission();
    if (!allowed) {
      throw StateError('Разрешение VPN не предоставлено');
    }
    final config = await _securedConfig(server);
    if (_bypassApps.isEmpty) {
      await refreshBypassApps();
    }
    await _v2ray.startVless(
      remark: server.remark,
      config: config,
      blockedApps: _bypassApps,
      bypassSubnets: const ['0.0.0.0/0'],
      proxyOnly: false,
      notificationDisconnectButtonName: 'Отключить',
    );
  }

  Future<void> disconnect() => _v2ray.stopVless();

  void dispose() {
    _statusSub?.cancel();
    status.dispose();
  }
}
