/// D4 — Historique des interventions de l'ambulancier (section 9.C).

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../shared/widgets.dart';

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data =
          await apiClient.get('/trips/mine?page=1&page_size=20')
              as Map<String, dynamic>;
      setState(() => _items = data['items'] as List<dynamic>);
    } catch (_) {
      /* ignore */
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: _loading
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('Aucune intervention passée')),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (ctx, i) {
                        final t = _items[i] as Map<String, dynamic>;
                        return ListTile(
                          leading: const Icon(Icons.emergency),
                          title: Text(
                            (t['status'] as String? ?? '').replaceAll('_', ' '),
                          ),
                          subtitle: Text('${t['assigned_at'] ?? '—'}'),
                          trailing: const Icon(Icons.chevron_right),
                        );
                      },
                    ),
            ),
    );
  }
}
