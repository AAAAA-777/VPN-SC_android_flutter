# Android TV — VPN-SC

Краткая документация по TV-сборке и контексту для разработки.  
Ветка: **`feature/android-tv`** · Репозиторий: [VPN-SC_android_flutter](https://github.com/AAAAA-777/VPN-SC_android_flutter)

## Сборки (flavors)

| Flavor | Package | Точка входа | APK |
|--------|---------|-------------|-----|
| **mobile** | `com.vpnsc.client` | `lib/main.dart` | `app-mobile-release.apk` |
| **tv** | `com.vpnsc.client.tv` | `lib/main_tv.dart` | `app-tv-release.apk` |

```bash
flutter pub get

# Телефон
flutter build apk --flavor mobile -t lib/main.dart --release

# Android TV / приставка
flutter build apk --flavor tv -t lib/main_tv.dart --release
```

APK: `build/app/outputs/flutter-apk/`

## Что есть на TV, чего нет

| Функция | Mobile | TV |
|---------|--------|-----|
| Список серверов, подключение | ✓ | ✓ |
| Ping | ✓ | ✗ |
| Обход приложений (`direct_android.txt`) | ✓ | ✗ (`blockedApps: []`) |
| UI под пульт (D-pad) | — | ✓ |
| Лаунчер | `LAUNCHER` | `LEANBACK_LAUNCHER` + `LAUNCHER` |

Маршрутизация `.ru` / `.рф` — как на телефоне.

## Структура кода (TV)

```
lib/main_tv.dart              → AppEnvironment.configureTv()
lib/screens/home_screen_tv.dart
lib/widgets/connection_panel_tv.dart
lib/widgets/server_tile_tv.dart
lib/core/app_environment.dart
lib/services/vpn_controller.dart   → ветки if (AppEnvironment.current.isTv)
android/app/src/tv/AndroidManifest.xml
```

Общий VPN и подписка: `VpnController`, `SubscriptionService`, `VlessConfigBuilder`.

## Патчи vendored-плагина (обязательно сохранять)

Путь: `packages/flutter_v2ray_plus/`  
При обновлении с pub.dev патчи **перезапишутся** — переносить в форк или снова патчить.

### Зачем патчили (Mi Box 3, Android 9)

1. **Уведомление на TV** — нет обычного `LAUNCHER` → `PendingIntent` был `null` → VPN падал сразу после подъёма.  
   → `resolveLauncherIntent()` (LEANBACK), безопасный `PendingIntent`.

2. **Передача TUN в tun2socks** — `onVpnEstablished` только после успешной передачи FD; вызов с **main thread** (`Handler`).

3. **Статусы во Flutter** — broadcast `CONNECTING` / `CONNECTED` с **`intent.setPackage(packageName)`** (процесс `:RunSoLibXrayDaemon`).

4. **Приёмник** — регистрация на `applicationContext`, доставка в EventChannel через `mainHandler`.

5. **`stopVless`** — `stopService` + команда `STOP_SERVICE` (надёжное отключение).

### Файлы плагина

- `android/.../XrayCoreManager.kt` — broadcast, уведомления, таймер нативно  
- `android/.../XrayVPNService.kt` — FD, main thread, `notifyVpnEstablished()`  
- `android/.../FlutterV2rayPlugin.kt` — приёмник, `stopVless`  
- `lib/flutter_v2ray_method_channel.dart` — безопасный разбор чисел из EventChannel  

## Поведение UI на TV

- **`startVless`** на Android возвращается сразу → `VpnController._waitForTvConnection()` ждёт `CONNECTED` (до 45 с).
- **Отключить** — `InkWell` + `Focus` (пульт OK/Enter); `_waitForTvDisconnect()` ждёт `DISCONNECTED`.
- **Таймер «Время: N с»** — нативный счётчик + **локальный** `Timer` в `connection_panel_tv.dart` (страховка, если broadcast `DURATION` не доходит до Flutter на приставке). На экране **одно** число: `max(нативное, локальное)`.
- Ошибки без префикса «Bad state»: `VpnConnectionException`, `vpnErrorMessage()`.

## Установка и ADB (пример: Mi Box)

1. **Настройки → О приставке** → 7× по номеру сборки.  
2. **Для разработчиков** → отладка по USB / по сети.  
3. На Mac:

```bash
export ADB=~/Library/Android/sdk/platform-tools/adb
$ADB connect 192.168.0.13:5555   # IP приставки
$ADB devices
$ADB -s 192.168.0.13:5555 install -r build/app/outputs/flutter-apk/app-tv-release.apk
```

Лог при проблемах с VPN:

```bash
$ADB -s 192.168.0.13:5555 logcat -v time | grep -iE "XrayVPN|XrayCore|tun2socks|flutter|VpnService"
```

### Перед подключением на приставке

- Отключить другие VPN (в т.ч. Amnezia и т.п.) в **Настройки → Сеть → VPN**.
- В VPN-SC TV нажать «Подключить» → в системном диалоге **Разрешить**.

## Коммиты ветки (ориентир)

| Коммит | Содержание |
|--------|------------|
| `b7918ec` | Flavor tv/mobile, TV UI, D-pad |
| `086fced` | Разрешение VPN, кнопка Connect |
| `3c76017` | Ожидание CONNECTED |
| `570e26c` | Mi Box: уведомление, FD, статусы |
| `646dcc6` | Отключить, таймер, broadcast `setPackage` |

## Продолжить работу в Cursor

В новом чате достаточно:

```
Проект VPN-SC Flutter, ветка feature/android-tv.
TV: com.vpnsc.client.tv, main_tv.dart.
Патчи в packages/flutter_v2ray_plus (см. docs/android-tv.md).
Тест: Mi Box, Android 9.
```

Код на GitHub — главный источник правды; этот файл — краткий контекст.

## Ограничения

- Не все приставки дают `VpnService` (OEM).
- Release подписан debug-keystore (для продакшена — свой keystore).
- Google Play для TV — отдельные ассеты и карточка.
