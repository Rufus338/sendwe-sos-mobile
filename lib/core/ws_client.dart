/// Client WebSocket avec reconnexion (backoff exponentiel, section 16.1).

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'token_storage.dart';

class WSClient {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _closed = false;
  Duration _backoff = const Duration(seconds: 1);
  static const _maxBackoff = Duration(seconds: 30);

  final Map<String, void Function(Map<String, dynamic>)> handlers;
  final void Function(bool connected)? onStatusChange;

  WSClient({required this.handlers, this.onStatusChange});

  static String get _baseWsUrl {
    const apiUrl = String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://10.0.2.2:8000/api/v1',
    );
    // http://host:port/api/v1 → ws://host:port/ws
    return apiUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('/api/v1', '/ws');
  }

  Future<void> connect() async {
    final token = await TokenStorage.accessToken();
    if (token == null) return;
    _closed = false;
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$_baseWsUrl?token=$token'),
      );
      onStatusChange?.call(true);
      _channel!.stream.listen(
        _onMessage,
        onDone: _onClose,
        onError: (_) => _onClose(),
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = msg['event'] as String?;
      if (event == 'ping') {
        _channel?.sink.add(jsonEncode({'event': 'pong'}));
        return;
      }
      final handler = handlers[event];
      if (handler != null) {
        final data = msg['data'];
        final map = data is Map<String, dynamic>
            ? data
            : (data is Map
                  ? Map<String, dynamic>.from(data)
                  : <String, dynamic>{});
        handler(map);
      }
    } catch (_) {
      /* ignore */
    }
  }

  void _onClose() {
    onStatusChange?.call(false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_closed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_backoff, connect);
    _backoff = Duration(
      milliseconds: (_backoff.inMilliseconds * 2).clamp(
        1000,
        _maxBackoff.inMilliseconds,
      ),
    );
  }

  Future<void> sendLocation(Map<String, dynamic> payload) async {
    _channel?.sink.add(jsonEncode({'event': 'location.push', 'data': payload}));
  }

  void close() {
    _closed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
  }
}
