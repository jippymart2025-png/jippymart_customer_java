import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/services/mart_vendor_service.dart';
import 'package:jippymart_customer/models/mart_vendor_model.dart';

class MartZoneUtils {
  static List<MartVendorModel>? _cachedMartVendors;
  static String? _cachedZoneId;
  static DateTime? _lastFetchTime;
  static const Duration _cacheTTL = Duration(minutes: 5);

  /// Clear mart vendor cache - call this when zone changes
  static void clearMartVendorCache() {
    _cachedMartVendors = null;
    _cachedZoneId = null;
    _lastFetchTime = null;
    debugPrint('🗑️ [MART_ZONE_UTILS] Cleared mart vendor cache');
  }

  static Future<List<MartVendorModel>> getCachedMartVendors() async {
    final zoneId = Constant.selectedZone?.id;
    if (zoneId == null || zoneId.isEmpty) {
      clearMartVendorCache();
      return [];
    }

    // CRITICAL: If zone changed, clear cache to ensure fresh data for new zone
    if (_cachedZoneId != null && _cachedZoneId != zoneId) {
      debugPrint(
        '🔄 [MART_ZONE_UTILS] Zone changed from $_cachedZoneId to $zoneId - clearing cache',
      );
      clearMartVendorCache();
    }

    // Return cached data if valid for current zone
    if (_cachedMartVendors != null &&
        _cachedZoneId == zoneId &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheTTL) {
      debugPrint(
        '✅ [MART_ZONE_UTILS] Using cached vendors for zone: $zoneId (${_cachedMartVendors!.length} vendors)',
      );
      return _cachedMartVendors!;
    }

    // Fetch fresh data for current zone
    debugPrint('🔍 [MART_ZONE_UTILS] Fetching fresh vendors for zone: $zoneId');
    
    // Use zone-specific API first (more efficient and zone-accurate)
    final zoneStr = zoneId.toString().trim();
    var vendors = await MartVendorService.getMartVendorsByZone(zoneStr);
    
    // Additional client-side validation: ensure vendors actually belong to this zone
    vendors = vendors.where((vendor) {
      final vendorZoneId = vendor.zoneId?.toString().trim();
      return vendorZoneId != null && 
             vendorZoneId.isNotEmpty && 
             vendorZoneId == zoneStr;
    }).toList();

    // Fallback: if zone-specific API returns empty, try filtering all vendors
    // This handles cases where zone ID format might mismatch
    // NOTE: We do NOT fallback to all vendors - if no zone-specific vendors exist,
    // mart is NOT available in this zone (this prevents mart from opening in all zones)
    if (vendors.isEmpty) {
      debugPrint(
        '⚠️ [MART_ZONE_UTILS] Zone-specific API returned empty, trying fallback filter...',
      );
      final allVendors = await MartVendorService.getAllMartVendors(search: '');
      vendors = allVendors
          .where((v) =>
              v.zoneId != null &&
              v.zoneId!.toString().trim() == zoneStr)
          .toList();

      // CRITICAL: Do NOT fallback to all vendors - if no vendors match this zone,
      // mart is NOT available. This ensures mart only opens in zones where it's actually available.
      if (vendors.isEmpty) {
        debugPrint(
          '❌ [MART_ZONE_UTILS] No vendors found for zone $zoneStr - mart NOT available in this zone',
        );
        // Return empty list - mart is not available
      }
    }

    // Cache the results
    _cachedMartVendors = vendors;
    _cachedZoneId = zoneId;
    _lastFetchTime = DateTime.now();
    
    debugPrint(
      '✅ [MART_ZONE_UTILS] Cached ${vendors.length} vendors for zone: $zoneId',
    );
    
    return vendors;
  }

  /// Prefetch vendors when tab bar is shown so first Mart click is fast
  static void prefetchMartVendors() {
    getCachedMartVendors();
  }

  /// Check if mart is available in the current zone
  /// Returns true if there's at least one mart vendor in the current zone
  /// Uses cached data when available for faster response
  /// CRITICAL: This method validates zone and location before checking availability
  static Future<bool> isMartAvailableInCurrentZone() async {
    try {
      debugPrint('🔍 [MART_ZONE_UTILS] Checking mart availability for current zone');
      
      // CRITICAL: First validate that we have a selected zone
      if (Constant.selectedZone?.id == null || Constant.selectedZone!.id!.isEmpty) {
        debugPrint('❌ [MART_ZONE_UTILS] No zone selected - Mart not available');
        return false;
      }

      final currentZoneId = Constant.selectedZone!.id!;
      
      // CRITICAL: Validate that we have a valid location
      // Zone without location means location wasn't properly set
      if (Constant.selectedLocation.location?.latitude == null ||
          Constant.selectedLocation.location?.longitude == null ||
          Constant.selectedLocation.location!.latitude == 0.0 ||
          Constant.selectedLocation.location!.longitude == 0.0) {
        debugPrint('❌ [MART_ZONE_UTILS] No valid location - Mart not available');
        return false;
      }

      // CRITICAL: Validate zone matches location's zoneId if available
      // This ensures zone and location are in sync
      if (Constant.selectedLocation.zoneId != null &&
          Constant.selectedLocation.zoneId!.isNotEmpty &&
          Constant.selectedLocation.zoneId != currentZoneId) {
        debugPrint(
          '❌ [MART_ZONE_UTILS] Zone mismatch: location zone (${Constant.selectedLocation.zoneId}) != selected zone ($currentZoneId) - Mart not available',
        );
        return false;
      }
      
      // OPTIMIZATION: Use cached data if available and valid for current zone
      // Only fetch fresh if cache is invalid or zone changed
      // This makes the check much faster on subsequent clicks
      final martVendors = await getCachedMartVendors();
      
      // CRITICAL: Double-check that vendors actually belong to current zone
      // Filter out any vendors that don't match the zone (defense in depth)
      final validVendors = martVendors.where((vendor) {
        final vendorZoneId = vendor.zoneId?.toString().trim();
        return vendorZoneId != null &&
               vendorZoneId.isNotEmpty &&
               vendorZoneId == currentZoneId;
      }).toList();
      
      // Check if there are any valid mart vendors in this zone
      final isAvailable = validVendors.isNotEmpty;
      
      debugPrint(
        '🎯 [MART_ZONE_UTILS] Mart Available: $isAvailable (${validVendors.length} valid vendors in zone $currentZoneId)',
      );
      
      return isAvailable;
    } catch (e) {
      debugPrint('❌ [MART_ZONE_UTILS] Error checking mart availability: $e');
      // On error, try to use cached data as fallback (don't show "coming soon" on network errors)
      if (_cachedMartVendors != null && 
          _cachedZoneId == Constant.selectedZone?.id &&
          _cachedMartVendors!.isNotEmpty) {
        debugPrint('⚠️ [MART_ZONE_UTILS] Using cached vendors as fallback after error');
        return true; // If we have cached vendors, assume available
      }
      return false;
    }
  }

  /// Get zone ID for specific coordinates
  /// This is the core method for zone detection during address saving
  static Future<String> getZoneIdForCoordinates(
    double latitude,
    double longitude,
    BuildContext context,
  ) async {
    try {
      final zoneModel = await HomeProvider.getCurrentZone(latitude, longitude);
      if (zoneModel == null) {
        return '';
      }

      if (zoneModel.success != true) {
        print('❌ [MART_ZONE_UTILS] API returned false: ${zoneModel.message}');
        print(
          '🔍 [MART_ZONE_UTILS] ===== ZONE DETECTION ENDED (API FALSE) =====',
        );
        return '';
      }
      // Check if zone is available and valid
      if (zoneModel.isZoneAvailable != true || zoneModel.zone == null) {
        print('❌ [MART_ZONE_UTILS] No zone available at these coordinates');
        print(
          '🔍 [MART_ZONE_UTILS] ===== ZONE DETECTION ENDED (NO ZONE) =====',
        );
        return '';
      }

      final zone = zoneModel.zone!;

      print('✅ [MART_ZONE_UTILS] Zone found: ${zone.name} (ID: ${zone.id})');
      print('📍 Zone center: lat=${zone.latitude}, lng=${zone.longitude}');
      print('📍 Zone area points: ${zone.area?.length ?? 0}');
      print('📍 Zone published: ${zone.publish}');

      // Check if zone is published
      if (zone.publish != true) {
        print('❌ [MART_ZONE_UTILS] Zone is not published');
        print(
          '🔍 [MART_ZONE_UTILS] ===== ZONE DETECTION ENDED (UNPUBLISHED) =====',
        );
        return '';
      }

      print('🔍 [MART_ZONE_UTILS] ===== ZONE DETECTION ENDED (SUCCESS) =====');
      return zone.id ?? '';
    } catch (e) {
      print('❌ [MART_ZONE_UTILS] Error detecting zone for coordinates: $e');
      print('🔍 [MART_ZONE_UTILS] ===== ZONE DETECTION ENDED (ERROR) =====');
      return '';
    }
  }
}
