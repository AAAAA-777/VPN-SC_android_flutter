import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/vpn_controller.dart';
import 'theme/app_theme.dart';

class VpnScApp extends StatefulWidget {
  const VpnScApp({super.key});

  @override
  State<VpnScApp> createState() => _VpnScAppState();
}

class _VpnScAppState extends State<VpnScApp> {
  final VpnController _vpn = VpnController();

  @override
  void dispose() {
    _vpn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VPN-SC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: HomeScreen(vpn: _vpn),
    );
  }
}
