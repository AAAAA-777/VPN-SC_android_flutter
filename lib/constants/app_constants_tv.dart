import '../core/app_environment.dart';

/// TV-константы (см. [AppEnvironment.configureTv]).
class AppConstants {
  static String get packageName => AppEnvironment.current.packageName;
  static String get providerBundleIdentifier =>
      AppEnvironment.current.providerBundleIdentifier;
  static String get groupIdentifier => AppEnvironment.current.groupIdentifier;
  static String get localizedDescription =>
      AppEnvironment.current.localizedDescription;
}
