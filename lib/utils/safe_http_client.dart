import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:jippymart_customer/services/network_connectivity_service.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/production_logger.dart';

/// Safe HTTP client that handles network errors gracefully
/// and automatically refreshes JWT tokens on 403 responses.
class SafeHttpClient {
  /// Make a safe GET request with network error handling and auto token refresh
  static Future<http.Response?> safeGet(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
    bool checkConnectivity = true,
    bool throwOnError = false,
  }) async {
    try {
      // Check connectivity before making request
      if (checkConnectivity) {
        final connectivityService = NetworkConnectivityService();
        final isConnected = await connectivityService.checkConnectivity();
        if (!isConnected) {
          ProductionLogger.error(
            'SAFE_HTTP',
            'Connectivity check failed for ${url.host}',
          );
          if (throwOnError) {
            throw SocketException('No internet connection');
          }
          return null;
        }
      }

      // Build headers with auth token if available
      final authHeaders = await _buildAuthHeaders();
      final requestHeaders = _mergeHeaders(headers, authHeaders);

      // Make the request with timeout
      final response = await http
          .get(url, headers: requestHeaders)
          .timeout(
            timeout ?? const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out');
            },
          );

      // If 403, try to refresh token and retry once
      if (response.statusCode == 403) {
        final refreshedHeaders = await _refreshToken();
        if (refreshedHeaders != null) {
          final retryResponse = await http
              .get(url, headers: _mergeHeaders(headers, refreshedHeaders))
              .timeout(
                timeout ?? const Duration(seconds: 30),
                onTimeout: () {
                  throw TimeoutException('Request timed out');
                },
              );
          if (retryResponse.statusCode == 200) {
            return retryResponse;
          }
        }
      }

      return response;
    } on SocketException catch (e) {
      ProductionLogger.error('SAFE_HTTP', 'SocketException: ${e.message}', e);
      if (throwOnError) {
        rethrow;
      }
      return null;
    } on TimeoutException catch (e) {
      ProductionLogger.error('SAFE_HTTP', 'TimeoutException: ${e.message}', e);
      if (throwOnError) {
        rethrow;
      }
      return null;
    } on HttpException catch (e) {
      ProductionLogger.error('SAFE_HTTP', 'HttpException: ${e.message}', e);
      if (throwOnError) {
        rethrow;
      }
      return null;
    } catch (e) {
      ProductionLogger.error('SAFE_HTTP', 'Unexpected error', e);
      if (throwOnError) {
        rethrow;
      }
      return null;
    }
  }

  /// Make a safe POST request with network error handling and auto token refresh
  static Future<http.Response?> safePost(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    bool checkConnectivity = true,
    bool throwOnError = false,
  }) async {
    try {
      // Check connectivity before making request
      if (checkConnectivity) {
        final connectivityService = NetworkConnectivityService();
        final isConnected = await connectivityService.checkConnectivity();
        if (!isConnected) {
          ProductionLogger.error(
            'SAFE_HTTP',
            'Connectivity check failed for ${url.host}',
          );
          if (throwOnError) {
            throw SocketException('No internet connection');
          }
          return null;
        }
      }

      // Build headers with auth token if available
      final authHeaders = await _buildAuthHeaders();
      final requestHeaders = _mergeHeaders(headers, authHeaders);

      // Make the request with timeout
      final response = await http
          .post(url, headers: requestHeaders, body: body)
          .timeout(
            timeout ?? const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out');
            },
          );

      // If 403, try to refresh token and retry once
      if (response.statusCode == 403) {
        final refreshedHeaders = await _refreshToken();
        if (refreshedHeaders != null) {
          final retryResponse = await http
              .post(url, headers: _mergeHeaders(headers, refreshedHeaders),
                  body: body)
              .timeout(
                timeout ?? const Duration(seconds: 30),
                onTimeout: () {
                  throw TimeoutException('Request timed out');
                },
              );
          if (retryResponse.statusCode == 200) {
            return retryResponse;
          }
        }
      }

      return response;
    } on SocketException catch (e) {
      ProductionLogger.error('SAFE_HTTP', 'SocketException: ${e.message}', e);
      if (throwOnError) {
        rethrow;
      }
      return null;
    } on TimeoutException catch (e) {
      ProductionLogger.error('SAFE_HTTP', 'TimeoutException: ${e.message}', e);
      if (throwOnError) {
        rethrow;
      }
      return null;
    } on HttpException catch (e) {
      ProductionLogger.error('SAFE_HTTP', 'HttpException: ${e.message}', e);
      if (throwOnError) {
        rethrow;
      }
      return null;
    } catch (e) {
      ProductionLogger.error('SAFE_HTTP', 'Unexpected error', e);
      if (throwOnError) {
        rethrow;
      }
      return null;
    }
  }

  /// Make a safe PUT request with network error handling and auto token refresh
  static Future<http.Response?> safePut(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    bool checkConnectivity = true,
    bool throwOnError = false,
  }) async {
    try {
      // Check connectivity before making request
      if (checkConnectivity) {
        final connectivityService = NetworkConnectivityService();
        final isConnected = await connectivityService.checkConnectivity();
        if (!isConnected) {
          ProductionLogger.error(
            'SAFE_HTTP',
            'Connectivity check failed for ${url.host}',
          );
          if (throwOnError) {
            throw SocketException('No internet connection');
          }
          return null;
        }
      }

      // Build headers with auth token if available
      final authHeaders = await _buildAuthHeaders();
      final requestHeaders = _mergeHeaders(headers, authHeaders);

      // Make the request with timeout
      final response = await http
          .put(url, headers: requestHeaders, body: body)
          .timeout(
            timeout ?? const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out');
            },
          );

      // If 403, try to refresh token and retry once
      if (response.statusCode == 403) {
        final refreshedHeaders = await _refreshToken();
        if (refreshedHeaders != null) {
          final retryResponse = await http
              .put(url, headers: _mergeHeaders(headers, refreshedHeaders),
                  body: body)
              .timeout(
                timeout ?? const Duration(seconds: 30),
                onTimeout: () {
                  throw TimeoutException('Request timed out');
                },
              );
          if (retryResponse.statusCode == 200) {
            return retryResponse;
          }
        }
      }

      return response;
    } on SocketException catch (e) {
      ProductionLogger.error('SAFE_HTTP', 'SocketException: ${e.message}', e);
      if (throwOnError) {
        rethrow;
      }
      return null;
    } on TimeoutException catch (e) {
      ProductionLogger.error('SAFE_HTTP', 'TimeoutException: ${e.message}', e);
      if (throwOnError) {
        rethrow;
      }
      return null;
    } on HttpException catch (e) {
      ProductionLogger.error('SAFE_HTTP', 'HttpException: ${e.message}', e);
      if (throwOnError) {
        rethrow;
      }
      return null;
    } catch (e) {
      ProductionLogger.error('SAFE_HTTP', 'Unexpected error', e);
      if (throwOnError) {
        rethrow;
      }
      return null;
    }
  }

  /// Make a safe DELETE request with network error handling and auto token refresh
  static Future<http.Response?> safeDelete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    bool checkConnectivity = true,
    bool throwOnError = false,
  }) async {
    try {
      // Check connectivity before making request
      if (checkConnectivity) {
        final connectivityService = NetworkConnectivityService();
        final isConnected = await connectivityService.checkConnectivity();
        if (!isConnected) {
          ProductionLogger.error(
            'SAFE_HTTP',
            'Connectivity check failed for ${url.host}',
          );
          if (throwOnError) {
            throw SocketException('No internet connection');
          }
          return null;
        }
      }

      // Build headers with auth token if available
      final authHeaders = await _buildAuthHeaders();
      final requestHeaders = _mergeHeaders(headers, authHeaders);

      // Make the request with timeout
      final response = await http
          .delete(url, headers: requestHeaders, body: body)
          .timeout(
            timeout ?? const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out');
            },
          );

      // If 403, try to refresh token and retry once
      if (response.statusCode == 403) {
        final refreshedHeaders = await _refreshToken();
        if (refreshedHeaders != null) {
          final retryResponse = await http
              .delete(url, headers: _mergeHeaders(headers, refreshedHeaders),
                  body: body)
              .timeout(
                timeout ?? const Duration(seconds: 30),
                onTimeout: () {
                  throw TimeoutException('Request timed out');
                },
              );
          if (retryResponse.statusCode == 200) {
            return retryResponse;
          }
        }
      }

      return response;
    } on SocketException catch (e) {
      ProductionLogger.error('SAFE_HTTP', 'SocketException: ${e.message}', e);
      if (throwOnError) {
        rethrow;
      }
      return null;
    } on TimeoutException catch (e) {
      ProductionLogger.error('SAFE_HTTP', 'TimeoutException: ${e.message}', e);
      if (throwOnError) {
        rethrow;
      }
      return null;
    } on HttpException catch (e) {
      ProductionLogger.error('SAFE_HTTP', 'HttpException: ${e.message}', e);
      if (throwOnError) {
        rethrow;
      }
      return null;
    } catch (e) {
      ProductionLogger.error('SAFE_HTTP', 'Unexpected error', e);
      if (throwOnError) {
        rethrow;
      }
      return null;
    }
  }

  /// Build authentication headers from stored tokens
  static Future<Map<String, String>> _buildAuthHeaders() async {
    final tokens = await getAuthTokens();

    final headers = <String, String>{};
    final accessToken = tokens != null ? tokens['accessToken'] : null;
    if (accessToken != null && accessToken.isNotEmpty) {
      // Token already has "Bearer " prefix from storage
      headers['Authorization'] = accessToken;
    }
    headers['Content-Type'] = 'application/json';
    headers['Accept'] = 'application/json';
    return headers;
  }

  /// Merge two header maps, with merge taking precedence over base
  static Map<String, String> _mergeHeaders(
      Map<String, String>? base, Map<String, String>? merge) {
    final result = <String, String>{};
    if (base != null) {
      result.addAll(base);
    }
    if (merge != null) {
      result.addAll(merge);
    }
    return result;
  }

  /// Refresh the access token using the stored refresh token
  static Future<Map<String, String>?> _refreshToken() async {
    final tokens = await getAuthTokens();
    final refreshToken = tokens?['refreshToken'];

    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    // Use the app's base URL for the refresh API
    final refreshUrl = Uri.parse('${AppConst.baseUrl}fm/auth/refresh');

    final response = await http
        .post(
          refreshUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'refreshToken': refreshToken}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final newJwt = data['jwtToken']?.toString() ?? '';
      final newRefreshToken = data['refreshToken']?.toString() ?? '';

      if (newJwt.isNotEmpty) {
        await saveAuthToken(
          accessToken: newJwt,
          refreshToken: newRefreshToken,
        );
      }

      return {
        'Authorization': 'Bearer $newJwt',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
    }

    return null;
  }
}