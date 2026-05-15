import 'package:flutter/material.dart';

import '../models/server_node.dart';
import '../theme/app_theme.dart';

class ServerTile extends StatelessWidget {
  const ServerTile({
    super.key,
    required this.server,
    required this.selected,
    required this.pingMs,
    required this.measuringPing,
    required this.onTap,
    required this.onPing,
  });

  final ServerNode server;
  final bool selected;
  final int? pingMs;
  final bool measuringPing;
  final VoidCallback onTap;
  final VoidCallback onPing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? AppColors.secondary : Colors.white38,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  server.remark,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (measuringPing)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (pingMs != null)
                Chip(
                  label: Text('$pingMs мс'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.35),
                ),
              IconButton(
                onPressed: onPing,
                icon: const Icon(Icons.speed),
                tooltip: 'Проверить задержку',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
