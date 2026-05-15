import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_v2ray_plus/model/vless_status.dart';

import '../theme/app_theme.dart';

class ConnectionPanelTv extends StatefulWidget {
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

  @override
  State<ConnectionPanelTv> createState() => _ConnectionPanelTvState();
}

class _ConnectionPanelTvState extends State<ConnectionPanelTv> {
  late final FocusNode _connectFocus =
      widget.connectFocusNode ?? FocusNode(debugLabel: 'connect');

  bool get _connected => widget.status.state.toUpperCase() == 'CONNECTED';

  @override
  void dispose() {
    if (widget.connectFocusNode == null) {
      _connectFocus.dispose();
    }
    super.dispose();
  }

  void _activatePrimaryAction() {
    if (widget.busy) return;
    if (_connected) {
      widget.onDisconnect();
    } else {
      widget.onConnect();
    }
  }

  bool _isActivateKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final key = event.logicalKey;
    return key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA;
  }

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
              _statusLabel(widget.status.state),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _connected ? Colors.greenAccent : Colors.white,
                  ),
              textAlign: TextAlign.center,
            ),
            if (widget.selectedRemark != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.selectedRemark!,
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
                    value: _formatBytes(widget.status.upload),
                    speed: '${widget.status.uploadSpeed} B/s',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatBlock(
                    title: 'Загрузка',
                    value: _formatBytes(widget.status.download),
                    speed: '${widget.status.downloadSpeed} B/s',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Время: ${widget.status.duration} с',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.white54),
            ),
            const SizedBox(height: 28),
            Actions(
              actions: <Type, Action<Intent>>{
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    _activatePrimaryAction();
                    return null;
                  },
                ),
              },
              child: Focus(
                focusNode: _connectFocus,
                onKeyEvent: (node, event) {
                  if (_isActivateKey(event)) {
                    _activatePrimaryAction();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Builder(
                  builder: (context) {
                    final focused = Focus.of(context).hasFocus;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: focused
                            ? Border.all(color: AppColors.secondary, width: 3)
                            : null,
                      ),
                      child: SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed:
                              widget.busy ? null : _activatePrimaryAction,
                          icon: widget.busy
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
                            widget.busy
                                ? 'Подождите…'
                                : (_connected
                                    ? 'Отключить'
                                    : 'Подключить'),
                            style: const TextStyle(fontSize: 20),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _connected
                                ? Colors.red.shade700
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  },
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
