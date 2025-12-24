import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service to check and monitor network connectivity
class NetworkConnectivityService {
  static final NetworkConnectivityService _instance =
      NetworkConnectivityService._internal();
  factory NetworkConnectivityService() => _instance;
  NetworkConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;
  final _connectionController = StreamController<bool>.broadcast();

  /// Stream of connectivity status changes
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Initialize the service and start monitoring
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      await checkConnectivity();

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) async {
          await _handleConnectivityChange(results);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ [NETWORK] Error initializing connectivity service: $e');
      }
      // Assume connected if we can't check
      _isConnected = true;
    }
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      final bool wasConnected = _isConnected;
      _isConnected = await _hasInternetConnection(results);

      if (wasConnected != _isConnected) {
        _connectionController.add(_isConnected);
      }

      return _isConnected;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [NETWORK] Error checking connectivity: $e');
      }
      // Assume connected if we can't check
      _isConnected = true;
      return true;
    }
  }

  /// Handle connectivity change
  Future<void> _handleConnectivityChange(
    List<ConnectivityResult> results,
  ) async {
    final bool wasConnected = _isConnected;
    _isConnected = await _hasInternetConnection(results);

    if (wasConnected != _isConnected) {
      if (kDebugMode) {
        print(
          '🌐 [NETWORK] Connectivity changed: ${_isConnected ? "Connected" : "Disconnected"}',
        );
      }
      _connectionController.add(_isConnected);
    }
  }

  /// Check if device has actual internet connection (not just network interface)
  Future<bool> _hasInternetConnection(
    List<ConnectivityResult> results,
  ) async {
    // If no connectivity result, assume disconnected
    if (results.isEmpty) {
      return false;
    }

    // Check if any result indicates connectivity
    final hasConnectivity = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn ||
          result == ConnectivityResult.other,
    );

    if (!hasConnectivity) {
      return false;
    }

    // Additional check: Try to reach a reliable server
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [NETWORK] Internet lookup failed: $e');
      }
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionController.close();
  }
}


