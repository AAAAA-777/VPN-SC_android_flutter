# VPN-SC

Android VPN client (VLESS) built with Flutter and [flutter_v2ray_plus](https://pub.dev/packages/flutter_v2ray_plus).

Поддерживаются две сборки (product flavors):

| Flavor | Package | Entry point |
|--------|---------|-------------|
| **mobile** | `com.vpnsc.client` | `lib/main.dart` |
| **tv** | `com.vpnsc.client.tv` | `lib/main_tv.dart` |

## Build — телефон

```bash
flutter pub get
flutter build apk --flavor mobile -t lib/main.dart --release
```

APK: `build/app/outputs/flutter-apk/app-mobile-release.apk`

## Build — Android TV

```bash
flutter build apk --flavor tv -t lib/main_tv.dart --release
```

APK: `build/app/outputs/flutter-apk/app-tv-release.apk`

TV-сборка: упрощённый UI под пульт (сервер + подключение), без ping и без обхода приложений (`direct_android`). Иконка в лаунчере TV через `LEANBACK_LAUNCHER`.

Подробнее: **[docs/android-tv.md](docs/android-tv.md)** (патчи плагина, Mi Box, ADB, контекст для Cursor).

## Ручной тест Android TV

1. Установить `app-tv-release.apk` на приставку или эмулятор Android TV (API 28+).
2. Запуск из лаунчера TV (категория «Приложения»).
3. Пульт: выбор сервера, кнопка «Подключить», разрешение VPN.
4. Проверить интернет через VPN и отключение.
5. Регрессия: `app-mobile-release.apk` на телефоне — полный функционал без изменений.

## Ограничения TV

- Не все приставки разрешают `VpnService` (зависит от OEM).
- Google Play для TV требует отдельные TV-ассеты и карточку.
- Обход приложений из `direct_android.txt` на TV не используется.
