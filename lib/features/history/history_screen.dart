/// P6 — Historique des demandes (section 9.B).

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
          await apiClient.get('/emergencies/mine?page=1&page_size=20')
              as Map<String, dynamic>;
      setState(() => _items = data['items'] as List<dynamic>);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getStringList('history_cache') ?? [];
      setState(() => _items = cached.map((e) => e as dynamic).toList());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('Aucune demande pour le moment')),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (ctx, i) {
                        final item = _items[i] as Map<String, dynamic>;
                        return ListTile(
                          leading: const Icon(Icons.emergency),
                          title: Text(
                            (item['reason_category'] as String? ?? 'Demande')
                                .replaceAll('_', ' '),
                          ),
                          subtitle: Text(
                            '${item['created_at']} — ${item['status']}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        );
                      },
                    ),
            ),
    );
  }
}
