import 'package:flutter/material.dart';
import 'package:flutter_v2ray_plus/model/vless_status.dart';

import '../theme/app_theme.dart';

class ConnectionPanelTv extends StatelessWidget {
  const ConnectionPanelTv({
    super.key,
    required this.status,
    required this.selectedRemark,
    required this.onConnect,
    required this.onDisconnect,
    required this.busy,
    this.connectFocusNode,
  });

  final VlessStatus status;
  final String? selectedRemark;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final bool busy;
  final FocusNode? connectFocusNode;

  bool get _connected => status.state.toUpperCase() == 'CONNECTED';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _statusLabel(status.state),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _connected ? Colors.greenAccent : Colors.white,
                  ),
              textAlign: TextAlign.center,
            ),
            if (selectedRemark != null) ...[
              const SizedBox(height: 12),
              Text(
                selectedRemark!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Зоны .ru и .рф — напрямую',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatBlock(
                    title: 'Отдача',
                    value: _formatBytes(status.upload),
                    speed: '${status.uploadSpeed} B/s',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatBlock(
                    title: 'Загрузка',
                    value: _formatBytes(status.download),
                    speed: '${status.downloadSpeed} B/s',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Время: ${status.duration} с',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.white54),
            ),
            const SizedBox(height: 28),
            Focus(
              focusNode: connectFocusNode,
              child: SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: busy
                      ? null
                      : (_connected ? onDisconnect : onConnect),
                  icon: busy
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _connected ? Icons.power_off : Icons.vpn_key,
                          size: 28,
                        ),
                  label: Text(
                    busy
                        ? 'Подождите…'
                        : (_connected ? 'Отключить' : 'Подключить'),
                    style: const TextStyle(fontSize: 20),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _connected ? Colors.red.shade700 : AppColors.primary,
                  ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.white54)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Text(speed, style: const TextStyle(fontSize: 12, color: Colors.white38)),
        ],
      ),
    );
  }
}
