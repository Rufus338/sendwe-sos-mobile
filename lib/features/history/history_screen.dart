/// P6 — Historique des demandes (section 9.B : pagination + pull-to-refresh).

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
          await apiClient.get('/emergencies/mine?page=1&page_size=$_pageSize')
              as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _items = data['items'] as List<dynamic>;
        _page = data['page'] as int;
        _hasMore = (_page as int) < (data['pages'] as int);
      });
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getStringList('history_cache') ?? [];
      if (mounted) {
        setState(() => _items = cached.map((e) => e as dynamic).toList());
      }
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
          await apiClient.get(
                '/emergencies/mine?page=$next&page_size=$_pageSize',
              )
              as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...(data['items'] as List<dynamic>)];
        _page = data['page'] as int;
        _hasMore = (_page as int) < (data['pages'] as int);
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
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('Aucune demande pour le moment')),
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
