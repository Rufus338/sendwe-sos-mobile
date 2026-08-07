/// Gestion des tokens en secure storage (section 9.A).

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _roleKey = 'role';
  static const _userIdKey = 'user_id';

  static Future<void> save({
    required String accessToken,
    required String refreshToken,
    required String role,
    required String userId,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(key: _userIdKey, value: userId);
  }

  static Future<String?> accessToken() => _storage.read(key: _accessKey);
  static Future<String?> refreshToken() => _storage.read(key: _refreshKey);
  static Future<String?> role() => _storage.read(key: _roleKey);
  static Future<String?> userId() => _storage.read(key: _userIdKey);

  static Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _userIdKey);
  }
}
