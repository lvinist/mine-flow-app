import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service providing encrypted storage for sensitive tokens and user session data.
///
/// Follows Doc 15 — Native App Architecture (§2.2 Security & Token Storage)
/// and Doc 16 — Identity & Auth (§6 Sessions & Tokens).
/// On Android, uses Android Keystore with `encryptedSharedPreferences: true`.
/// On iOS, uses Keychain with accessibility `first_unlock`.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  // Key constants for storage keys
  static const String keyAuthToken = 'mine_flow_auth_token';
  static const String keyRefreshToken = 'mine_flow_refresh_token';
  static const String keyUserId = 'mine_flow_user_id';
  static const String keyUserRole = 'mine_flow_user_role';
  static const String keySiteId = 'mine_flow_site_id';

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  /// Writes a key-value pair to encrypted secure storage.
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  /// Reads a value by key from encrypted secure storage.
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  /// Deletes a key from encrypted secure storage.
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  /// Clears all stored keys and secrets.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Persists the Auth access token.
  Future<void> saveAuthToken(String token) async {
    await write(key: keyAuthToken, value: token);
  }

  /// Retrieves the saved Auth access token.
  Future<String?> getAuthToken() async {
    return await read(key: keyAuthToken);
  }

  /// Persists the Auth refresh token.
  Future<void> saveRefreshToken(String token) async {
    await write(key: keyRefreshToken, value: token);
  }

  /// Retrieves the saved Auth refresh token.
  Future<String?> getRefreshToken() async {
    return await read(key: keyRefreshToken);
  }

  /// Persists full user session parameters securely on device.
  Future<void> saveSessionData({
    required String userId,
    required String role,
    String? siteId,
    String? token,
    String? refreshToken,
  }) async {
    await write(key: keyUserId, value: userId);
    await write(key: keyUserRole, value: role);
    if (siteId != null) {
      await write(key: keySiteId, value: siteId);
    }
    if (token != null) {
      await saveAuthToken(token);
    }
    if (refreshToken != null) {
      await saveRefreshToken(refreshToken);
    }
  }

  /// Retrieves saved session parameters from secure storage.
  Future<Map<String, String?>> getSessionData() async {
    final token = await getAuthToken();
    final refreshToken = await getRefreshToken();
    final userId = await read(key: keyUserId);
    final role = await read(key: keyUserRole);
    final siteId = await read(key: keySiteId);

    return {
      'token': token,
      'refreshToken': refreshToken,
      'userId': userId,
      'role': role,
      'siteId': siteId,
    };
  }
}
