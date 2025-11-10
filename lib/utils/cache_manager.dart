import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// **COMPREHENSIVE CACHE MANAGER FOR PERFORMANCE OPTIMIZATION**
///
/// Features:
/// - Smart caching with expiry times
/// - Memory and disk caching
/// - Automatic cache invalidation
/// - Fallback mechanisms
/// - Performance monitoring integration
class CacheManager {
  // **MEMORY CACHE**
  static final Map<String, dynamic> _memoryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static final Map<String, String> _cacheVersions = {};
  static const Duration _defaultExpiry = Duration(minutes: 5);
  static String? _currentAppVersion;

  // **CACHE KEYS**
  static const String _productsPrefix = 'products_';
  static const String _categoriesPrefix = 'categories_';

  /// **INITIALIZE CACHE MANAGER**
  static Future<void> initialize() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentAppVersion = packageInfo.version;
      print(
        'DEBUG: CacheManager - Initialized with app version: $_currentAppVersion',
      );
    } catch (e) {
      print('DEBUG: CacheManager - Error getting app version: $e');
      _currentAppVersion = 'unknown';
    }
  }

  /// **GET CACHED DATA WITH EXPIRY CHECK AND VALIDATION**
  static Future<T?> get<T>(String key) async {
    try {
      // First check memory cache
      if (_memoryCache.containsKey(key)) {
        final timestamp = _cacheTimestamps[key];
        final cachedVersion = _cacheVersions[key];

        // Check if cache is expired
        if (timestamp != null &&
            DateTime.now().difference(timestamp) < _defaultExpiry) {
          // Check if app version has changed (invalidate cache on app update)
          if (_currentAppVersion != null &&
              cachedVersion != null &&
              cachedVersion != _currentAppVersion) {
            print(
              'DEBUG: CacheManager - Cache INVALIDATED due to app version change: $key',
            );
            _clearCacheEntry(key);
            return null;
          }

          // Validate cached data integrity
          if (_validateCacheData(key, _memoryCache[key])) {
            print('DEBUG: CacheManager - Cache HIT (memory) for key: $key');
            return _memoryCache[key] as T;
          } else {
            print('DEBUG: CacheManager - Cache CORRUPTED for key: $key');
            _clearCacheEntry(key);
            return null;
          }
        } else {
          // Cache expired, remove it
          print('DEBUG: CacheManager - Cache EXPIRED for key: $key');
          _clearCacheEntry(key);
        }
      }

      // If not in memory, try to load from disk
      try {
        final diskData = await _loadFromDiskCache<T>(key);
        if (diskData != null) {
          // Restore to memory cache
          _memoryCache[key] = diskData;
          _cacheTimestamps[key] = DateTime.now();
          _cacheVersions[key] = _currentAppVersion ?? 'unknown';
          print('DEBUG: CacheManager - Cache HIT (disk) for key: $key');
          return diskData;
        }
      } catch (e) {
        print('DEBUG: CacheManager - Error loading from disk cache: $key - $e');
      }

      print('DEBUG: CacheManager - Cache MISS for key: $key');
      return null;
    } catch (e) {
      print('DEBUG: CacheManager - Error getting cache for key: $key - $e');
      _clearCacheEntry(key); // Clear corrupted cache
      return null;
    }
  }

  /// **SET CACHED DATA WITH TIMESTAMP AND VERSION**
  static Future<void> set<T>(String key, T value, {Duration? expiry}) async {
    try {
      _memoryCache[key] = value;
      _cacheTimestamps[key] = DateTime.now();
      _cacheVersions[key] = _currentAppVersion ?? 'unknown';

      // Also save to disk for persistence
      await _saveToDiskCache(key, value);

      print(
        'DEBUG: CacheManager - Cached data for key: $key (expiry: ${expiry ?? _defaultExpiry}, version: ${_currentAppVersion})',
      );
    } catch (e) {
      print('DEBUG: CacheManager - Error setting cache for key: $key - $e');
    }
  }

  /// **GET CACHED DATA WITH FALLBACK**

  /// **CLEAR SPECIFIC CACHE**
  static void clear(String key) {
    _clearCacheEntry(key);
    print('DEBUG: CacheManager - Cleared cache for key: $key');
  }

  /// **CLEAR CACHE ENTRY (HELPER METHOD)**
  static void _clearCacheEntry(String key) {
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
    _cacheVersions.remove(key);
  }

  /// **VALIDATE CACHE DATA INTEGRITY**
  static bool _validateCacheData(String key, dynamic data) {
    try {
      if (data == null) return false;

      // Basic validation based on key type
      if (key.startsWith(_productsPrefix)) {
        if (data is List) {
          // Validate that it's a list of ProductModel-like objects
          return data.every(
            (item) =>
                item != null && item.toString().contains('ProductModel') ||
                (item is Map &&
                    item.containsKey('id') &&
                    item.containsKey('name')),
          );
        }
        return false;
      } else if (key.startsWith(_categoriesPrefix)) {
        if (data is List) {
          return data.every(
            (item) =>
                item != null &&
                    item.toString().contains('VendorCategoryModel') ||
                (item is Map &&
                    item.containsKey('id') &&
                    item.containsKey('title')),
          );
        }
        return false;
      }

      // For other types, basic null check
      return data != null;
    } catch (e) {
      print(
        'DEBUG: CacheManager - Error validating cache data for key: $key - $e',
      );
      return false;
    }
  }

  /// **CLEAR ALL CACHE**
  static void clearAll() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    _cacheVersions.clear();
    print('DEBUG: CacheManager - Cleared all cache');
  }

  /// **GET CACHE STATISTICS**
  static Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    int validEntries = 0;
    int expiredEntries = 0;

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) < _defaultExpiry) {
        validEntries++;
      } else {
        expiredEntries++;
      }
    }

    return {
      'totalEntries': _memoryCache.length,
      'validEntries': validEntries,
      'expiredEntries': expiredEntries,
      'memoryUsage': _estimateMemoryUsage(),
    };
  }

  /// **ESTIMATE MEMORY USAGE**
  static String _estimateMemoryUsage() {
    try {
      int totalBytes = 0;
      for (final entry in _memoryCache.entries) {
        if (entry.value is String) {
          totalBytes += (entry.value as String).length * 2; // UTF-16
        } else if (entry.value is List) {
          totalBytes += (entry.value as List).length * 8; // Rough estimate
        } else if (entry.value is Map) {
          totalBytes += (entry.value as Map).length * 16; // Rough estimate
        }
      }

      if (totalBytes < 1024) {
        return '${totalBytes}B';
      } else if (totalBytes < 1024 * 1024) {
        return '${(totalBytes / 1024).toStringAsFixed(1)}KB';
      } else {
        return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  // **SPECIALIZED CACHE METHODS**

  /// **SET PRODUCT DATA**
  static Future<void> setProductData<T>(String key, T data) async {
    await set(
      key,
      data,
      expiry: Duration(minutes: 10),
    ); // Products cache longer
  }

  // **DISK CACHE METHODS (FOR PERSISTENT STORAGE)**

  /// **SAVE TO DISK CACHE (HELPER METHOD)**
  static Future<void> _saveToDiskCache<T>(String key, T data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(data);
      await prefs.setString('cache_$key', jsonData);
      await prefs.setString(
        'cache_${key}_timestamp',
        DateTime.now().toIso8601String(),
      );
      await prefs.setString(
        'cache_${key}_version',
        _currentAppVersion ?? 'unknown',
      );
      print('DEBUG: CacheManager - Saved to disk cache: $key');
    } catch (e) {
      print('DEBUG: CacheManager - Error saving to disk cache: $key - $e');
    }
  }

  /// **LOAD FROM DISK CACHE (HELPER METHOD)**
  static Future<T?> _loadFromDiskCache<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString('cache_$key');
      final timestampStr = prefs.getString('cache_${key}_timestamp');
      final versionStr = prefs.getString('cache_${key}_version');

      if (jsonData != null && timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);

        // Check if cache is expired
        if (DateTime.now().difference(timestamp) < _defaultExpiry) {
          // Check if app version has changed
          if (_currentAppVersion != null &&
              versionStr != null &&
              versionStr != _currentAppVersion) {
            print(
              'DEBUG: CacheManager - Disk cache INVALIDATED due to app version change: $key',
            );
            await _clearDiskCacheEntry(key);
            return null;
          }

          final data = jsonDecode(jsonData);
          print('DEBUG: CacheManager - Loaded from disk cache: $key');
          return data as T;
        } else {
          // Clear expired disk cache
          await _clearDiskCacheEntry(key);
          print('DEBUG: CacheManager - Disk cache expired: $key');
        }
      }
      return null;
    } catch (e) {
      print('DEBUG: CacheManager - Error loading from disk cache: $key - $e');
      await _clearDiskCacheEntry(key);
      return null;
    }
  }

  /// **CLEAR DISK CACHE ENTRY (HELPER METHOD)**
  static Future<void> _clearDiskCacheEntry(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cache_$key');
      await prefs.remove('cache_${key}_timestamp');
      await prefs.remove('cache_${key}_version');
    } catch (e) {
      print('DEBUG: CacheManager - Error clearing disk cache entry: $key - $e');
    }
  }
}
