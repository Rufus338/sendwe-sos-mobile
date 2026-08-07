/// Client HTTP avec rafraîchissement silencieux du token (section 15.1, 20).

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'token_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String errorCode;
  final String message;

  ApiException(this.statusCode, this.errorCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue:
        'http://10.0.2.2:8000/api/v1', // émulateur Android → hôte local
  );

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth) {
      final token = await TokenStorage.accessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Object? body,
    bool withAuth = true,
    bool retried = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers(withAuth: withAuth);
    http.Response res;
    switch (method) {
      case 'GET':
        res = await http.get(uri, headers: headers);
      case 'DELETE':
        res = await http.delete(uri, headers: headers);
      case 'PATCH':
        res = await http.patch(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      default:
        res = await http.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
    }

    // Rafraîchissement silencieux (une seule tentative)
    if (res.statusCode == 401 && withAuth && !retried) {
      final ok = await _refresh();
      if (ok)
        return _request(
          method,
          path,
          body: body,
          withAuth: withAuth,
          retried: true,
        );
      throw ApiException(
        401,
        'TOKEN_EXPIRED',
        'Votre session a expiré, reconnectez-vous',
      );
    }

    if (res.statusCode >= 400) {
      String message = 'Erreur ${res.statusCode}';
      String errorCode = 'SERVER_UNAVAILABLE';
      try {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        message = (data['message'] ?? data['detail'] ?? message) as String;
        errorCode = (data['error_code'] ?? errorCode) as String;
      } catch (_) {
        /* ignore */
      }
      throw ApiException(res.statusCode, errorCode, message);
    }

    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  Future<bool> _refresh() async {
    final refreshToken = await TokenStorage.refreshToken();
    if (refreshToken == null) return false;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );
      if (res.statusCode != 200) return false;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      await TokenStorage.save(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        role: data['role'] as String,
        userId: data['user_id'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<dynamic> get(String path) => _request('GET', path);
  Future<dynamic> post(String path, {Object? body}) =>
      _request('POST', path, body: body);
  Future<dynamic> patch(String path, {Object? body}) =>
      _request('PATCH', path, body: body);
  Future<dynamic> delete(String path) => _request('DELETE', path);
}

final apiClient = ApiClient();
