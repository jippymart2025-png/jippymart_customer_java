import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/services/network_connectivity_service.dart';

/// Safe HTTP client that handles network errors gracefully
class SafeHttpClient {
  /// Make a safe GET request with network error handling
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
          if (throwOnError) {
            throw SocketException('No internet connection');
          }
          return null;
        }
      }

      // Make the request with timeout
      final response = await http
          .get(url, headers: headers)
          .timeout(
            timeout ?? const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out');
            },
          );

      return response;
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('❌ [SAFE_HTTP] SocketException: ${e.message}');
      }
      if (throwOnError) {
        rethrow;
      }
      return null;
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('❌ [SAFE_HTTP] TimeoutException: ${e.message}');
      }
      if (throwOnError) {
        rethrow;
      }
      return null;
    } on HttpException catch (e) {
      if (kDebugMode) {
        print('❌ [SAFE_HTTP] HttpException: ${e.message}');
      }
      if (throwOnError) {
        rethrow;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SAFE_HTTP] Unexpected error: $e');
      }
      if (throwOnError) {
        rethrow;
      }
      return null;
    }
  }

  /// Make a safe POST request with network error handling
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
          if (throwOnError) {
            throw SocketException('No internet connection');
          }
          return null;
        }
      }

      // Make the request with timeout
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(
            timeout ?? const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out');
            },
          );

      return response;
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('❌ [SAFE_HTTP] SocketException: ${e.message}');
      }
      if (throwOnError) {
        rethrow;
      }
      return null;
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('❌ [SAFE_HTTP] TimeoutException: ${e.message}');
      }
      if (throwOnError) {
        rethrow;
      }
      return null;
    } on HttpException catch (e) {
      if (kDebugMode) {
        print('❌ [SAFE_HTTP] HttpException: ${e.message}');
      }
      if (throwOnError) {
        rethrow;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SAFE_HTTP] Unexpected error: $e');
      }
      if (throwOnError) {
        rethrow;
      }
      return null;
    }
  }

  /// Make a safe PUT request with network error handling
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
          if (throwOnError) {
            throw SocketException('No internet connection');
          }
          return null;
        }
      }

      // Make the request with timeout
      final response = await http
          .put(url, headers: headers, body: body)
          .timeout(
            timeout ?? const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out');
            },
          );

      return response;
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('❌ [SAFE_HTTP] SocketException: ${e.message}');
      }
      if (throwOnError) {
        rethrow;
      }
      return null;
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('❌ [SAFE_HTTP] TimeoutException: ${e.message}');
      }
      if (throwOnError) {
        rethrow;
      }
      return null;
    } on HttpException catch (e) {
      if (kDebugMode) {
        print('❌ [SAFE_HTTP] HttpException: ${e.message}');
      }
      if (throwOnError) {
        rethrow;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SAFE_HTTP] Unexpected error: $e');
      }
      if (throwOnError) {
        rethrow;
      }
      return null;
    }
  }

  /// Make a safe DELETE request with network error handling
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
          if (throwOnError) {
            throw SocketException('No internet connection');
          }
          return null;
        }
      }

      // Make the request with timeout
      final response = await http
          .delete(url, headers: headers, body: body)
          .timeout(
            timeout ?? const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out');
            },
          );

      return response;
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('❌ [SAFE_HTTP] SocketException: ${e.message}');
      }
      if (throwOnError) {
        rethrow;
      }
      return null;
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('❌ [SAFE_HTTP] TimeoutException: ${e.message}');
      }
      if (throwOnError) {
        rethrow;
      }
      return null;
    } on HttpException catch (e) {
      if (kDebugMode) {
        print('❌ [SAFE_HTTP] HttpException: ${e.message}');
      }
      if (throwOnError) {
        rethrow;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SAFE_HTTP] Unexpected error: $e');
      }
      if (throwOnError) {
        rethrow;
      }
      return null;
    }
  }
}

