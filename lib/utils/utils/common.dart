import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';

Map<String, String> get headers => {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

const _devAuthToken =
    'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJkZXZhZG1pbiIsInJvbGVzIjpbXSwidXNlcklkIjo3NywiaWF0IjoxNzgyMjgwMzk0LCJleHAiOjE3ODIzNjY3OTR9.L72qrS1XTdkwUNhHkw03PWlfNz7xonAo7fgyiWkCoMo';

String formatAuthToken(String token, {String tokenType = 'Bearer'}) {
  final trimmed = token.trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.contains(' ')) return trimmed;
  if (tokenType.isEmpty) return trimmed;
  return '$tokenType $trimmed';
}

Future<void> saveAuthToken(
  String accessToken, {
  String tokenType = 'Bearer',
}) async {
  if (accessToken.trim().isEmpty) return;
  const storage = FlutterSecureStorage();
  await storage.write(
    key: 'api_token',
    value: formatAuthToken(accessToken, tokenType: tokenType),
  );
}

Future<void> clearAuthToken() async {
  const storage = FlutterSecureStorage();
  await storage.delete(key: 'api_token');
}

Future<Map<String, String>> getHeaders() async {
  final storedToken = await SqlStorageConst.getAuthToken();
  final authToken = (storedToken != null && storedToken.isNotEmpty)
      ? storedToken
      : _devAuthToken;
  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    "Authorization":
        "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJkZXZhZG1pbiIsInJvbGVzIjpbIlJPTEVfREVWQURNSU4iXSwidXNlcklkIjo3NywiaWF0IjoxNzgyMjk1NjcyLCJleHAiOjE3ODIzODIwNzJ9.kRzi2S4jHvh_MtkvrOrMHFxpx_tgkiWARn__2MAwj-4",
  };
}
