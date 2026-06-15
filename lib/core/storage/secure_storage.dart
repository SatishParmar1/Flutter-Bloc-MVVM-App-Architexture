import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<void> saveAccessToken(String token) async {
    await write(_accessTokenKey, token);
  }

  Future<String?> getAccessToken() async {
    return await read(_accessTokenKey);
  }

  Future<void> deleteAccessToken() async {
    await delete(_accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await write(_refreshTokenKey, token);
  }

  Future<String?> getRefreshToken() async {
    return await read(_refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await delete(_refreshTokenKey);
  }
}
