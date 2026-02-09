import 'package:flutter/foundation.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Utility class for caching and managing delivery charges dynamically
/// Validates cache on app launch without blocking the UI
class DeliveryChargeCache {
  static DeliveryChargeCache? _instance;
  static DeliveryChargeCache get instance {
    _instance ??= DeliveryChargeCache._();
    return _instance!;
  }

  DeliveryChargeCache._();

  // Cache storage
  DeliveryCharge? _cachedDeliveryCharge;
  DateTime? _lastFetchTime;
  bool _isValidating = false;
  static const String _cacheKey = 'delivery_charge_cache';
  static const String _timestampKey = 'delivery_charge_timestamp';
  static const Duration _cacheExpiry = Duration(hours: 24); // Cache for 24 hours
  static const Duration _validationInterval = Duration(minutes: 5); // Validate every 5 minutes

  /// Get cached delivery charge (returns cached value immediately if available)
  DeliveryCharge? getCachedDeliveryCharge() {
    return _cachedDeliveryCharge;
  }

  /// Check if cache is valid
  bool isCacheValid() {
    if (_cachedDeliveryCharge == null || _lastFetchTime == null) {
      return false;
    }
    return DateTime.now().difference(_lastFetchTime!) < _cacheExpiry;
  }

  /// Check if cache needs validation (for background refresh)
  bool needsValidation() {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) > _validationInterval;
  }

  /// Load delivery charge from cache or fetch from API
  /// Returns cached value immediately if available, fetches in background if needed
  Future<DeliveryCharge?> getDeliveryCharge({bool forceRefresh = false}) async {
    // Return cached value immediately if valid and not forcing refresh
    if (!forceRefresh && isCacheValid() && _cachedDeliveryCharge != null) {
      debugPrint('[DELIVERY_CACHE] ✅ Using cached delivery charge');
      return _cachedDeliveryCharge;
    }

    // If cache is invalid or force refresh, fetch from API
    if (forceRefresh || !isCacheValid()) {
      return await _fetchAndCacheDeliveryCharge();
    }

    // If cache exists but needs validation, return cached value and validate in background
    if (_cachedDeliveryCharge != null && needsValidation()) {
      debugPrint('[DELIVERY_CACHE] 🔄 Cache needs validation, validating in background');
      _validateCacheInBackground();
      return _cachedDeliveryCharge;
    }

    return _cachedDeliveryCharge;
  }

  /// Fetch delivery charge from API and cache it
  Future<DeliveryCharge?> _fetchAndCacheDeliveryCharge() async {
    if (_isValidating) {
      debugPrint('[DELIVERY_CACHE] ⏳ Already validating, returning cached value');
      return _cachedDeliveryCharge;
    }

    _isValidating = true;
    try {
      debugPrint('[DELIVERY_CACHE] 🔍 Fetching delivery charge from API...');
      final deliveryCharge = await FireStoreUtils.getDeliveryCharge();
      
      if (deliveryCharge != null) {
        _cachedDeliveryCharge = deliveryCharge;
        _lastFetchTime = DateTime.now();
        await _saveToSharedPreferences(deliveryCharge);
        debugPrint('[DELIVERY_CACHE] ✅ Delivery charge cached successfully');
      } else {
        debugPrint('[DELIVERY_CACHE] ⚠️ API returned null, using cached value if available');
      }
      
      return _cachedDeliveryCharge;
    } catch (e) {
      debugPrint('[DELIVERY_CACHE] ❌ Error fetching delivery charge: $e');
      // Return cached value even if fetch fails
      return _cachedDeliveryCharge;
    } finally {
      _isValidating = false;
    }
  }

  /// Validate cache in background without blocking
  void _validateCacheInBackground() {
    if (_isValidating) return;
    
    Future.microtask(() async {
      await _fetchAndCacheDeliveryCharge();
    });
  }

  /// Load cache from SharedPreferences on app launch
  Future<void> loadCacheFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);
      final timestampStr = prefs.getString(_timestampKey);

      if (cacheJson != null && timestampStr != null) {
        final timestamp = DateTime.tryParse(timestampStr);
        if (timestamp != null && DateTime.now().difference(timestamp) < _cacheExpiry) {
          // Parse cached delivery charge (simplified - you may need to adjust based on your model)
          // For now, we'll fetch fresh data on launch but use cache during session
          debugPrint('[DELIVERY_CACHE] 📦 Cache found in storage, will validate in background');
          _validateCacheInBackground();
        }
      }
    } catch (e) {
      debugPrint('[DELIVERY_CACHE] ❌ Error loading cache from storage: $e');
    }
  }

  /// Save delivery charge to SharedPreferences
  Future<void> _saveToSharedPreferences(DeliveryCharge deliveryCharge) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Save timestamp
      await prefs.setString(_timestampKey, DateTime.now().toIso8601String());
      // Note: DeliveryCharge model needs toJson() method for full serialization
      // For now, we'll just cache in memory and validate on launch
      debugPrint('[DELIVERY_CACHE] 💾 Cache timestamp saved');
    } catch (e) {
      debugPrint('[DELIVERY_CACHE] ❌ Error saving cache to storage: $e');
    }
  }

  /// Clear cache (useful for testing or when needed)
  Future<void> clearCache() async {
    _cachedDeliveryCharge = null;
    _lastFetchTime = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_timestampKey);
      debugPrint('[DELIVERY_CACHE] 🗑️ Cache cleared');
    } catch (e) {
      debugPrint('[DELIVERY_CACHE] ❌ Error clearing cache: $e');
    }
  }

  /// Initialize cache on app launch (non-blocking)
  /// Call this in your app initialization
  Future<void> initializeOnAppLaunch() async {
    debugPrint('[DELIVERY_CACHE] 🚀 Initializing delivery charge cache on app launch...');
    
    // Load from storage first (if available)
    await loadCacheFromStorage();
    
    // Fetch fresh data in background (non-blocking)
    Future.microtask(() async {
      await getDeliveryCharge(forceRefresh: true);
    });
  }

  /// Get base delivery charge with fallback
  double getBaseDeliveryCharge({double fallback = 21.0}) {
    return _cachedDeliveryCharge?.baseDeliveryCharge?.toDouble() ?? fallback;
  }

  /// Get item total threshold with fallback
  double getItemTotalThreshold({double fallback = 299.0}) {
    return _cachedDeliveryCharge?.itemTotalThreshold?.toDouble() ?? fallback;
  }

  /// Get free delivery distance in km with fallback
  double getFreeDeliveryDistanceKm({double fallback = 7.0}) {
    return _cachedDeliveryCharge?.freeDeliveryDistanceKm?.toDouble() ?? fallback;
  }

  /// Get per km charge above free distance with fallback
  double getPerKmChargeAboveFreeDistance({double fallback = 8.0}) {
    return _cachedDeliveryCharge?.perKmChargeAboveFreeDistance?.toDouble() ?? fallback;
  }
}
