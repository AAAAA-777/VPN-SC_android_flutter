import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app.dart';
import '../models/server_node.dart';
import '../services/subscription_service.dart';
import '../services/vpn_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_panel_tv.dart';
import '../widgets/server_tile_tv.dart';

class HomeScreenTv extends StatefulWidget {
  const HomeScreenTv({super.key});

  @override
  State<HomeScreenTv> createState() => _HomeScreenTvState();
}

class _HomeScreenTvState extends State<HomeScreenTv> {
  VpnController? _vpn;
  bool _started = false;

  final SubscriptionService _subscription = SubscriptionService();
  final FocusNode _refreshFocus = FocusNode(debugLabel: 'refresh');
  final FocusNode _connectFocus = FocusNode(debugLabel: 'connect');

  List<ServerNode> _servers = [];
  ServerNode? _selected;
  bool _loading = true;
  bool _connectBusy = false;
  String? _bannerMessage;

  static const _selectedKey = 'selected_server_id_tv';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vpn ??= VpnHomeHost.of(context);
    if (!_started) {
      _started = true;
      _init();
    }
  }

  @override
  void dispose() {
    _refreshFocus.dispose();
    _connectFocus.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _vpn!.initialize();
    await _refreshServers();
    await _restoreSelectedFromPrefs();
  }

  Future<void> _restoreSelectedFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_selectedKey);
    if (id == null || !mounted) return;
    final match = _servers.where((s) => s.id == id);
    if (match.isNotEmpty) {
      setState(() => _selected = match.first);
    }
  }

  Future<void> _saveSelected(ServerNode server) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedKey, server.id);
  }

  Future<void> _refreshServers() async {
    setState(() {
      _loading = true;
      _bannerMessage = null;
    });
    final result = await _subscription.fetchServers();
    if (!mounted) return;

    ServerNode? selected = _selected;
    if (result.servers.isNotEmpty) {
      if (selected == null ||
          !result.servers.any((s) => s.id == selected!.id)) {
        selected = result.servers.first;
        await _saveSelected(selected);
      } else {
        selected = result.servers.firstWhere((s) => s.id == selected!.id);
      }
    }

    setState(() {
      _servers = result.servers;
      _selected = selected;
      _loading = false;
      if (result.errorMessage != null) {
        _bannerMessage = result.fromCache
            ? '${result.errorMessage} (показан кэш)'
            : result.errorMessage;
      }
    });
  }

  Future<void> _selectServer(ServerNode server) async {
    setState(() => _selected = server);
    await _saveSelected(server);
  }

  Future<void> _connect() async {
    final server = _selected;
    if (server == null) {
      _showMessage('Выберите сервер');
      return;
    }
    setState(() => _connectBusy = true);
    try {
      await _vpn!.connect(server);
    } catch (e) {
      _showMessage('$e');
    } finally {
      if (mounted) setState(() => _connectBusy = false);
    }
  }

  Future<void> _disconnect() async {
    setState(() => _connectBusy = true);
    try {
      await _vpn!.disconnect();
    } finally {
      if (mounted) setState(() => _connectBusy = false);
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient(),
        child: SafeArea(
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 420, child: _buildServerColumn()),
                Expanded(child: _buildConnectionColumn()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServerColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'VPN-SC TV',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Focus(
                focusNode: _refreshFocus,
                child: IconButton(
                  onPressed: _loading ? null : _refreshServers,
                  icon: const Icon(Icons.refresh, size: 32),
                  tooltip: 'Обновить',
                ),
              ),
            ],
          ),
        ),
        if (_bannerMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Material(
              color: Colors.orange.shade900.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _bannerMessage!,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'Серверы',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _servers.isEmpty
                  ? const Center(
                      child: Text(
                        'Нет серверов.\nНажмите «Обновить».',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _servers.length,
                      itemBuilder: (context, index) {
                        final server = _servers[index];
                        return ServerTileTv(
                          server: server,
                          selected: _selected?.id == server.id,
                          autofocus: index == 0,
                          onSelect: () => _selectServer(server),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildConnectionColumn() {
    return Column(
      children: [
        const SizedBox(height: 8),
        ValueListenableBuilder(
          valueListenable: _vpn!.status,
          builder: (context, status, _) {
            return ConnectionPanelTv(
              status: status,
              selectedRemark: _selected?.remark,
              connectFocusNode: _connectFocus,
              onConnect: _connect,
              onDisconnect: _disconnect,
              busy: _connectBusy,
            );
          },
        ),
      ],
    );
  }
}
