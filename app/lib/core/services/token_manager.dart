// app/lib/core/services/token_manager.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresAtKey = 'token_expires_at';
  static const String _userIdKey = 'user_id';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  Future<void> saveToken({
    required String token,
    required String refreshToken,
    required int expiresIn,
    required String userId,
  }) async {
    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    await Future.wait([
      _secureStorage.write(key: _tokenKey, value: token),
      _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
      _secureStorage.write(key: _userIdKey, value: userId),
      _saveExpiresAt(expiresAt.millisecondsSinceEpoch),
    ]);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: _tokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _secureStorage.delete(key: _userIdKey),
      _deleteExpiresAt(),
    ]);
  }

  Future<void> _saveExpiresAt(int millisecondsSinceEpoch) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_expiresAtKey, millisecondsSinceEpoch);
  }

  Future<void> _deleteExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_expiresAtKey);
  }
}
