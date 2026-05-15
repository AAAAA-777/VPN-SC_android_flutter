import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/app_environment.dart';
import 'screens/home_screen_tv.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppEnvironment.configureTv();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(
    const VpnScApp(
      title: 'VPN-SC TV',
      home: HomeScreenTv(),
    ),
  );
}
