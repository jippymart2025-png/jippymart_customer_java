import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/wallet_config.dart';
import 'package:jippymart_customer/services/wallet_api_service.dart';
import 'package:jippymart_customer/utils/preferences.dart';

/// Loads wallet & coin configuration from backend once in a while and caches it
/// in [Preferences]. The rest of the app reads values via [Constant] getters.
class WalletConfigService {
  WalletConfigService._();

  static final WalletConfigService instance = WalletConfigService._();

  static const Duration _maxCacheAge = Duration(hours: 1);
  
  Future<void> initialize() async {
    // 1) Apply cached config immediately if available (no network).
    _loadFromCache();

    // 2) In background, refresh from backend if cache is stale.
    _refreshIfStale();
  }

  void _loadFromCache() {
    try {
      final cached =
          Preferences.getString(Preferences.walletConfigJson, defaultValue: '');
      if (cached.isEmpty) return;
      final map = json.decode(cached) as Map<String, dynamic>;
      final config = WalletConfig.fromJson(map);
      Constant.applyWalletConfig(config);
      if (kDebugMode) {
        print('[WalletConfigService] Applied cached wallet config');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[WalletConfigService] Failed to parse cached config: $e');
      }
    }
  }

  void _refreshIfStale() {
    Future.microtask(() async {
      try {
        final lastMs = Preferences.getInt(
          Preferences.walletConfigLastUpdatedMillis,
          defaultValue: 0,
        );
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        if (lastMs > 0 &&
            nowMs - lastMs < _maxCacheAge.inMilliseconds) {
          return;
        }
        await refreshFromBackend();
      } catch (e) {
        if (kDebugMode) {
          print('[WalletConfigService] _refreshIfStale error: $e');
        }
      }
    });
  }

  /// Force-refresh from backend (e.g. after app update or settings change).
  Future<void> refreshFromBackend() async {
    try {
      final data = await WalletApiService.instance.getWalletConfig();
      if (data == null) {
        if (kDebugMode) {
          print('[WalletConfigService] No wallet config from backend');
        }
        return;
      }
      final config = WalletConfig.fromJson(data);
      Constant.applyWalletConfig(config);
      await Preferences.setString(
        Preferences.walletConfigJson,
        json.encode(config.toJson()),
      );
      await Preferences.setInt(
        Preferences.walletConfigLastUpdatedMillis,
        DateTime.now().millisecondsSinceEpoch,
      );
      if (kDebugMode) {
        print('[WalletConfigService] Wallet config refreshed from backend');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[WalletConfigService] refreshFromBackend error: $e');
      }
    }
  }
}

