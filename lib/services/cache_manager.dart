import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/vendor_model.dart';

enum CacheType {
  banners, // 30 minutes
  categories, // 15 minutes
  restaurants, // 30 minutes
  userProfile, // 10 minutes
  martItems, // 5 minutes
  zones, // 30 minutes
  general, // 10 minutes (default)
}

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry({required this.data, required this.ttl})
    : timestamp = DateTime.now();

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;

  Duration get timeUntilExpiry => ttl - DateTime.now().difference(timestamp);
}

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();

  factory CacheManager() => _instance;

  CacheManager._internal();

  final Map<String, CacheEntry> _cache = {};
  Timer? _cleanupTimer;

  // TTL values for different cache types
  static const Duration _bannerTTL = Duration(minutes: 30);
  static const Duration _categoryTTL = Duration(minutes: 15);
  static const Duration _restaurantTTL = Duration(minutes: 30);
  static const Duration _userProfileTTL = Duration(minutes: 10);
  static const Duration _martItemTTL = Duration(minutes: 5);
  static const Duration _zoneTTL = Duration(minutes: 30);
  static const Duration _generalTTL = Duration(minutes: 10);

  Duration _getTTLForType(CacheType type) {
    switch (type) {
      case CacheType.banners:
        return _bannerTTL;
      case CacheType.categories:
        return _categoryTTL;
      case CacheType.restaurants:
        return _restaurantTTL;
      case CacheType.userProfile:
        return _userProfileTTL;
      case CacheType.martItems:
        return _martItemTTL;
      case CacheType.zones:
        return _zoneTTL;
      case CacheType.general:
        return _generalTTL;
    }
  }

  /// Store data in cache
  void set<T>(String key, T data, {CacheType type = CacheType.general}) {
    final ttl = _getTTLForType(type);
    _cache[key] = CacheEntry<T>(data: data, ttl: ttl);
    print(
      '[CACHE] 💾 Cached: $key (TTL: ${ttl.inMinutes}min, Type: ${data.runtimeType})',
    );

    // Start cleanup timer if not already running
    _startCleanupTimer();
  }

  /// Retrieve data from cache
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) {
      print('[CACHE] ❌ Cache miss: $key (expected type: $T)');
      return null;
    }

    if (entry.isExpired) {
      print('[CACHE] ⏰ Cache expired: $key');
      _cache.remove(key);
      return null;
    }

    print(
      '[CACHE] ✅ Cache hit: $key (type: ${entry.data.runtimeType}, expected: $T, expires in: ${entry.timeUntilExpiry.inMinutes}min)',
    );

    // Handle type casting with better error reporting
    try {
      return entry.data as T;
    } catch (e) {
      print(
        '[CACHE] ❌ Type cast error: ${entry.data.runtimeType} is not a subtype of $T',
      );
      print('[CACHE] Actual data: ${entry.data}');
      return null;
    }
  }

  /// Check if cache contains valid data
  bool hasValid(String key) {
    final entry = _cache[key];
    return entry != null && !entry.isExpired;
  }

  /// Get or set data (cache-first approach) - FIXED VERSION
  Future<T> getOrSet<T>(
    String key,
    Future<T> Function() fetchFunction, {
    CacheType type = CacheType.general,
  }) async {
    print('[CACHE] 🔍 getOrSet START - Key: $key, Expected Type: $T');

    // Try cache first
    final cached = get<T>(key);
    if (cached != null) {
      print('[CACHE] ✅ Returning cached data');
      return cached;
    }

    // Fetch fresh data
    print('[CACHE] 🔄 Cache miss, fetching fresh data for: $key');
    try {
      final data = await fetchFunction();
      print('[CACHE] 📦 Fetched data type: ${data.runtimeType}, Expected: $T');

      // Special handling for common type mismatches
      dynamic dataToStore = data;

      // If we got List<VendorModel> but T is Future<List<VendorModel>>
      if (data is List && T.toString().contains('Future<List<VendorModel>>')) {
        print('[CACHE] 🔧 Type adjustment: Storing List directly (not Future)');
        // Store the list directly, not wrapped in Future
        set(key, data, type: type);
        return data as T;
      }
      // If we got Future but should store direct value
      else if (data is Future && !T.toString().contains('Future')) {
        print('[CACHE] 🔧 Awaiting Future before storing');
        dataToStore = await data;
        set(key, dataToStore, type: type);
        return dataToStore as T;
      } else {
        // Normal case
        set(key, data, type: type);
        return data;
      }
    } catch (e, stackTrace) {
      print('[CACHE] ❌ Fetch failed for: $key - $e');
      print('[CACHE] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Force refresh cache entry
  Future<T> refresh<T>(
    String key,
    Future<T> Function() fetchFunction, {
    CacheType type = CacheType.general,
  }) async {
    print('[CACHE] 🔄 Force refresh: $key');
    try {
      final data = await fetchFunction();
      set(key, data, type: type);
      return data;
    } catch (e) {
      print('[CACHE] ❌ Refresh failed for: $key - $e');
      rethrow;
    }
  }

  /// Remove specific cache entry
  void remove(String key) {
    _cache.remove(key);
    print('[CACHE] 🗑️ Removed: $key');
  }

  /// Clear all expired entries
  void clearExpired() {
    final keysToRemove = <String>[];

    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      print('[CACHE] 🧹 Cleared ${keysToRemove.length} expired entries');
    }
  }

  /// Clear all cache entries
  void clearAll() {
    final count = _cache.length;
    _cache.clear();
    print('[CACHE] 🧹 Cleared all $count cache entries');
  }

  /// Clear cache entries by type pattern
  void clearByPattern(String pattern) {
    final keysToRemove = _cache.keys
        .where((key) => key.contains(pattern))
        .toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      print(
        '[CACHE] 🧹 Cleared ${keysToRemove.length} entries matching: $pattern',
      );
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    int totalEntries = _cache.length;
    int expiredEntries = 0;
    int validEntries = 0;
    final expiryTimes = <String, Duration>{};

    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredEntries++;
      } else {
        validEntries++;
        expiryTimes[entry.key] = entry.value.timeUntilExpiry;
      }
    }

    return {
      'totalEntries': totalEntries,
      'validEntries': validEntries,
      'expiredEntries': expiredEntries,
      'hitRate': totalEntries > 0
          ? (validEntries / totalEntries * 100).round()
          : 0,
      'upcomingExpiries': expiryTimes,
    };
  }

  /// Start periodic cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      clearExpired();
    });
  }

  /// Dispose cache manager
  void dispose() {
    _cleanupTimer?.cancel();
    clearAll();
  }

  // Convenience methods for specific cache types

  /// Banner cache operations
  T? getBanners<T>(String key) => get<T>(key);

  void setBanners<T>(String key, T data) =>
      set(key, data, type: CacheType.banners);

  Future<T> getOrSetBanners<T>(String key, Future<T> Function() fetch) =>
      getOrSet(key, fetch, type: CacheType.banners);

  /// Category cache operations
  T? getCategories<T>(String key) => get<T>(key);

  void setCategories<T>(String key, T data) =>
      set(key, data, type: CacheType.categories);

  Future<T> getOrSetCategories<T>(String key, Future<T> Function() fetch) =>
      getOrSet(key, fetch, type: CacheType.categories);

  /// Restaurant cache operations - FIXED VERSION
  T? getRestaurants<T>(String key) => get<T>(key);

  void setRestaurants<T>(String key, T data) =>
      set(key, data, type: CacheType.restaurants);

  Future<T> getOrSetRestaurants<T>(
    String key,
    Future<T> Function() fetch,
  ) async {
    print(
      '[CACHE RESTAURANTS] 🍽️ getOrSetRestaurants for: $key with type: $T',
    );

    // Try cache first (restaurants are always stored as List<VendorModel>)
    final cached = get<List<VendorModel>>(key);
    if (cached != null) {
      print('[CACHE RESTAURANTS] ✅ Cache hit: ${cached.length} restaurants');

      // If caller expects Future<List<VendorModel>>
      if (T == Future<List<VendorModel>>) {
        return Future.value(cached) as T;
      }

      // If caller expects List<VendorModel>
      return cached as T;
    }

    // Cache miss → fetch
    print('[CACHE RESTAURANTS] 🔄 Cache miss, fetching...');
    try {
      final data = await fetch();
      print('[CACHE RESTAURANTS] 📦 Fetched type: ${data.runtimeType}');

      // Normalize to List<VendorModel> before caching
      List<VendorModel>? list;

      if (data is List<VendorModel>) {
        list = data;
      } else if (data is Future<List<VendorModel>>) {
        list = await data;
      }

      if (list != null) {
        set(key, list, type: CacheType.restaurants);
        print('[CACHE RESTAURANTS] 💾 Stored ${list.length} restaurants');
      }

      return data;
    } catch (e) {
      print('[CACHE RESTAURANTS] ❌ Error: $e');
      rethrow;
    }
  }

  /// User profile cache operations
  T? getUserProfile<T>(String key) => get<T>(key);

  void setUserProfile<T>(String key, T data) =>
      set(key, data, type: CacheType.userProfile);

  Future<T> getOrSetUserProfile<T>(String key, Future<T> Function() fetch) =>
      getOrSet(key, fetch, type: CacheType.userProfile);

  /// Mart items cache operations
  T? getMartItems<T>(String key) => get<T>(key);

  void setMartItems<T>(String key, T data) =>
      set(key, data, type: CacheType.martItems);

  Future<T> getOrSetMartItems<T>(String key, Future<T> Function() fetch) =>
      getOrSet(key, fetch, type: CacheType.martItems);

  /// Zone cache operations
  T? getZones<T>(String key) => get<T>(key);

  void setZones<T>(String key, T data) => set(key, data, type: CacheType.zones);

  Future<T> getOrSetZones<T>(String key, Future<T> Function() fetch) =>
      getOrSet(key, fetch, type: CacheType.zones);
}
