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
  final ScrollController _scroll = ScrollController();
  List<dynamic> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _page = 1;
      _hasMore = true;
    });
    try {
      final data =
          await apiClient.get('/trips/mine?page=1&page_size=$_pageSize')
              as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _items = data['items'] as List<dynamic>;
        _page = data['page'] as int;
        _hasMore = _page < (data['pages'] as int);
      });
    } catch (_) {
      /* ignore */
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final next = _page + 1;
      final data =
          await apiClient.get('/trips/mine?page=$next&page_size=$_pageSize')
              as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...(data['items'] as List<dynamic>)];
        _page = data['page'] as int;
        _hasMore = _page < (data['pages'] as int);
      });
    } catch (_) {
      /* ignore */
    } finally {
      if (mounted) setState(() => _loadingMore = false);
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
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('Aucune intervention passée')),
                      ],
                    )
                  : ListView.builder(
                      controller: _scroll,
                      itemCount: _items.length + (_hasMore ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i >= _items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
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
