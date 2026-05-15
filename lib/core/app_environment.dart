enum AppVariant { mobile, tv }

class AppEnvironment {
  AppEnvironment._({
    required this.variant,
    required this.packageName,
    required this.localizedDescription,
  });

  final AppVariant variant;
  final String packageName;
  final String localizedDescription;

  bool get isTv => variant == AppVariant.tv;

  String get providerBundleIdentifier => '$packageName.VPNProvider';
  String get groupIdentifier => 'group.$packageName';

  static late AppEnvironment current;

  static void configureMobile() {
    current = AppEnvironment._(
      variant: AppVariant.mobile,
      packageName: 'com.vpnsc.client',
      localizedDescription: 'VPN-SC',
    );
  }

  static void configureTv() {
    current = AppEnvironment._(
      variant: AppVariant.tv,
      packageName: 'com.vpnsc.client.tv',
      localizedDescription: 'VPN-SC TV',
    );
  }
}
