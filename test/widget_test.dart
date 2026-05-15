import 'package:flutter_test/flutter_test.dart';
import 'package:vpn_sc/app.dart';
import 'package:vpn_sc/core/app_environment.dart';
import 'package:vpn_sc/screens/home_screen.dart';

void main() {
  testWidgets('VPN-SC app smoke test', (WidgetTester tester) async {
    AppEnvironment.configureMobile();
    await tester.pumpWidget(
      const VpnScApp(
        home: HomeScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('VPN-SC'), findsOneWidget);
  });
}
