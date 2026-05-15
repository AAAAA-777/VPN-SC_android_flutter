import 'package:flutter_test/flutter_test.dart';
import 'package:vpn_sc/app.dart';

void main() {
  testWidgets('VPN-SC app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VpnScApp());
    expect(find.text('VPN-SC'), findsOneWidget);
  });
}
