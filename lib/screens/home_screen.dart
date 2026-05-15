import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/server_node.dart';
import '../services/subscription_service.dart';
import '../services/vpn_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_panel.dart';
import '../widgets/server_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.vpn});

  final VpnController vpn;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SubscriptionService _subscription = SubscriptionService();
  final Map<String, int?> _pings = {};
  final Set<String> _measuringPing = {};

  List<ServerNode> _servers = [];
  ServerNode? _selected;
  bool _loading = true;
  bool _connectBusy = false;
  String? _bannerMessage;

  static const _selectedKey = 'selected_server_id';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await widget.vpn.initialize();
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

    if (result.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage!)),
      );
    }
  }

  Future<void> _selectServer(ServerNode server) async {
    setState(() => _selected = server);
    await _saveSelected(server);
  }

  Future<void> _pingServer(ServerNode server) async {
    setState(() => _measuringPing.add(server.id));
    try {
      final ms = await widget.vpn.measureDelay(server);
      if (mounted) setState(() => _pings[server.id] = ms);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка ping: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _measuringPing.remove(server.id));
    }
  }

  Future<void> _connect() async {
    final server = _selected;
    if (server == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите сервер')),
      );
      return;
    }
    setState(() => _connectBusy = true);
    try {
      await widget.vpn.connect(server);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _connectBusy = false);
    }
  }

  Future<void> _disconnect() async {
    setState(() => _connectBusy = true);
    try {
      await widget.vpn.disconnect();
    } finally {
      if (mounted) setState(() => _connectBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 600;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 360, child: _buildServerList()),
                    Expanded(child: _buildDetailColumn()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildDetailColumn(compact: true),
                  Expanded(child: _buildServerList()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailColumn({bool compact = false}) {
    return Column(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        _buildAppBar(),
        if (_bannerMessage != null) _buildBanner(),
        ValueListenableBuilder(
          valueListenable: widget.vpn.status,
          builder: (context, status, _) {
            return ConnectionPanel(
              status: status,
              coreVersion: widget.vpn.coreVersion,
              selectedRemark: _selected?.remark,
              onConnect: _connect,
              onDisconnect: _disconnect,
              busy: _connectBusy,
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'VPN-SC',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          IconButton(
            onPressed: _loading ? null : _refreshServers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.orange.shade900.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            _bannerMessage!,
            style: const TextStyle(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildServerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Серверы',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _servers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Нет серверов.\nПотяните вниз для обновления.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshServers,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _servers.length,
                        itemBuilder: (context, index) {
                          final server = _servers[index];
                          return ServerTile(
                            server: server,
                            selected: _selected?.id == server.id,
                            pingMs: _pings[server.id],
                            measuringPing: _measuringPing.contains(server.id),
                            onTap: () => _selectServer(server),
                            onPing: () => _pingServer(server),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
