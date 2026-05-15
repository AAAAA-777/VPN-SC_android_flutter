import 'package:flutter/material.dart';
import 'package:flutter_v2ray_plus/model/vless_status.dart';

import '../theme/app_theme.dart';

class ConnectionPanel extends StatelessWidget {
  const ConnectionPanel({
    super.key,
    required this.status,
    required this.coreVersion,
    required this.selectedRemark,
    required this.onConnect,
    required this.onDisconnect,
    required this.busy,
    this.bypassAppsCount = 0,
  });

  final VlessStatus status;
  final String? coreVersion;
  final String? selectedRemark;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final bool busy;
  final int bypassAppsCount;

  bool get _connected => status.state.toUpperCase() == 'CONNECTED';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _statusLabel(status.state),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _connected ? Colors.greenAccent : Colors.white,
                  ),
              textAlign: TextAlign.center,
            ),
            if (selectedRemark != null) ...[
              const SizedBox(height: 8),
              Text(
                selectedRemark!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              bypassAppsCount > 0
                  ? 'Зоны .ru / .рф и $bypassAppsCount прилож. — напрямую'
                  : 'Зоны .ru и .рф — напрямую',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatBlock(
                    title: 'Отдача',
                    value: _formatBytes(status.upload),
                    speed: '${status.uploadSpeed} B/s',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBlock(
                    title: 'Загрузка',
                    value: _formatBytes(status.download),
                    speed: '${status.downloadSpeed} B/s',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Время: ${status.duration} с',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.white54),
            ),
            if (coreVersion != null) ...[
              const SizedBox(height: 4),
              Text(
                'Ядро: $coreVersion',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: busy
                    ? null
                    : (_connected ? onDisconnect : onConnect),
                icon: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_connected ? Icons.power_off : Icons.vpn_key),
                label: Text(
                  busy
                      ? 'Подождите…'
                      : (_connected ? 'Отключить' : 'Подключить'),
                  style: const TextStyle(fontSize: 17),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _connected ? Colors.red.shade700 : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _statusLabel(String state) {
    switch (state.toUpperCase()) {
      case 'CONNECTED':
        return 'Подключено';
      case 'CONNECTING':
        return 'Подключение…';
      case 'DISCONNECTED':
        return 'Отключено';
      default:
        return state.isEmpty ? 'Отключено' : state;
    }
  }

  static String _formatBytes(int? bytes) {
    if (bytes == null) return '—';
    const units = ['B', 'KB', 'MB', 'GB'];
    var b = bytes.toDouble();
    var i = 0;
    while (b >= 1024 && i < units.length - 1) {
      b /= 1024;
      i++;
    }
    return '${b.toStringAsFixed(b >= 10 ? 0 : 1)} ${units[i]}';
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.title,
    required this.value,
    required this.speed,
  });

  final String title;
  final String value;
  final String speed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(speed, style: const TextStyle(fontSize: 11, color: Colors.white38)),
        ],
      ),
    );
  }
}
