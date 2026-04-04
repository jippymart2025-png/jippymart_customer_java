import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';

/// Shared Dio instance for **new** HTTP code paths. Existing callers keep using
/// [SafeHttpClient] / `http` until migrated.
///
/// Call [updateBaseUrl] when [AppConst.baseUrl] changes (e.g. Remote Config)
/// so subsequent requests use the new origin.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  late final Dio _dio = _createDio();

  Dio get dio => _dio;

  static Dio _createDio() {
    final client = Dio(
      BaseOptions(
        baseUrl: AppConst.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        validateStatus: (status) => status != null && status < 600,
      ),
    );

    client.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          final code = response.statusCode;
          if (kDebugMode && code != null && code >= 400) {
            final req = response.requestOptions;
            debugPrint('[ApiClient] HTTP $code ${req.method} ${req.uri}');
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            final req = error.requestOptions;
            debugPrint(
              '[ApiClient] ${req.method} ${req.uri} — ${error.message}',
            );
            if (error.response != null) {
              debugPrint(
                '[ApiClient] response: ${error.response?.statusCode} ${error.response?.data}',
              );
            }
          }
          handler.next(error);
        },
      ),
    );

    return client;
  }

  /// Sync Dio [BaseOptions.baseUrl] with [AppConst.baseUrl].
  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }
}
