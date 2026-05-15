import 'package:flutter/material.dart';

import 'services/vpn_controller.dart';
import 'theme/app_theme.dart';

class VpnScApp extends StatefulWidget {
  const VpnScApp({
    super.key,
    required this.home,
    this.title = 'VPN-SC',
    this.vpn,
  });

  final Widget home;
  final String title;
  final VpnController? vpn;

  @override
  State<VpnScApp> createState() => _VpnScAppState();
}

class _VpnScAppState extends State<VpnScApp> {
  late final VpnController _vpn = widget.vpn ?? VpnController();

  @override
  void dispose() {
    _vpn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: VpnHomeHost(vpn: _vpn, child: widget.home),
    );
  }
}

/// Прокидывает [VpnController] вниз по дереву.
class VpnHomeHost extends InheritedWidget {
  const VpnHomeHost({
    super.key,
    required this.vpn,
    required super.child,
  });

  final VpnController vpn;

  static VpnController of(BuildContext context) {
    final host = context.dependOnInheritedWidgetOfExactType<VpnHomeHost>();
    assert(host != null, 'VpnController not found above widget tree');
    return host!.vpn;
  }

  @override
  bool updateShouldNotify(VpnHomeHost oldWidget) => vpn != oldWidget.vpn;
}
