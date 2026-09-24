import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jippymart_customer/utils/production_logger.dart';

const FlutterSecureStorage storage = FlutterSecureStorage();

Map<String, String> get headers => {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

String formatAuthToken(String token, {String tokenType = 'Bearer'}) {
  final trimmed = token.trim();

  if (trimmed.isEmpty) return trimmed;

  if (trimmed.startsWith('Bearer ')) {
    return trimmed;
  }

  return '$tokenType $trimmed';
}

/// Save token after login
Future<void> saveAuthToken(
  String accessToken, {
  String tokenType = 'Bearer',
}) async {
  if (accessToken.trim().isEmpty) return;

  await writeSecureStorage(
    'api_token',
    formatAuthToken(accessToken, tokenType: tokenType),
  );
}

/// Get saved token
Future<String?> getAuthToken() async {
  return await readSecureStorage('api_token');
}

/// Remove token on logout
Future<void> clearAuthToken() async {
  await deleteSecureStorage('api_token');
}

/// Reads a value from secure storage, automatically recovering when the stored
/// value cannot be decrypted. A corrupt entry (throws
/// `javax.crypto.BadPaddingException: BAD_DECRYPT`) happens when the Android
/// Keystore key no longer matches the ciphertext, e.g. after a reinstall or
/// switching between debug/release signing. The affected storage is reset so
/// later reads/writes work again.
Future<String?> readSecureStorage(String key) async {
  try {
    return await storage.read(key: key);
  } on PlatformException catch (e) {
    ProductionLogger.error('SECURE_STORAGE', 'read failed for key $key', e);
    await _resetSecureStorage();
    return null;
  } catch (_) {
    return null;
  }
}

/// Writes a value to secure storage, recovering from corrupt data first.
Future<void> writeSecureStorage(String key, String? value) async {
  try {
    if (value == null) {
      await storage.delete(key: key);
    } else {
      await storage.write(key: key, value: value);
    }
  } on PlatformException catch (e) {
    ProductionLogger.error('SECURE_STORAGE', 'write failed for key $key', e);
    await _resetSecureStorage();
    if (value == null) return;
    try {
      await storage.write(key: key, value: value);
    } catch (_) {}
  } catch (_) {}
}

/// Deletes a value from secure storage, ignoring corruption errors.
Future<void> deleteSecureStorage(String key) async {
  try {
    await storage.delete(key: key);
  } catch (_) {}
}

Future<void> _resetSecureStorage() async {
  try {
    await storage.deleteAll();
    ProductionLogger.info(
      'SECURE_STORAGE',
      'Storage reset after decryption failure',
    );
  } catch (_) {}
}

/// Common headers for all API calls
Future<Map<String, String>> getHeaders() async {
  final token = await getAuthToken();

  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': token,
  };
}
