import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/server_node.dart';
import '../theme/app_theme.dart';

class ServerTileTv extends StatefulWidget {
  const ServerTileTv({
    super.key,
    required this.server,
    required this.selected,
    required this.onSelect,
    this.autofocus = false,
  });

  final ServerNode server;
  final bool selected;
  final VoidCallback onSelect;
  final bool autofocus;

  @override
  State<ServerTileTv> createState() => _ServerTileTvState();
}

class _ServerTileTvState extends State<ServerTileTv> {
  late final FocusNode _focusNode = FocusNode(debugLabel: widget.server.id);

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onSelect();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: focused
                    ? AppColors.secondary
                    : (widget.selected
                        ? AppColors.primary
                        : Colors.transparent),
                width: focused ? 3 : (widget.selected ? 2 : 0),
              ),
            ),
            child: InkWell(
              onTap: widget.onSelect,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      widget.selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: widget.selected
                          ? AppColors.secondary
                          : Colors.white38,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.server.remark,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
