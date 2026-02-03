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

  static Future<List<MartVendorModel>> getCachedMartVendors() async {
    final zoneId = Constant.selectedZone?.id;
    if (zoneId == null || zoneId.isEmpty) return [];

    if (_cachedMartVendors != null &&
        _cachedZoneId == zoneId &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheTTL) {
      return _cachedMartVendors!;
    }

    // Use same API as mart_provider (mart-items/getMartVendors) and filter by zone.
    // mart-vendor/zone/$zoneId can return empty due to zone ID format mismatch.
    final allVendors = await MartVendorService.getAllMartVendors(search: '');
    final zoneStr = zoneId.toString().trim();
    var vendors = allVendors
        .where((v) =>
            v.zoneId != null &&
            v.zoneId!.toString().trim() == zoneStr)
        .toList();

    // Fallback: if zone filter gives empty but mart has vendors, use all (same as mart_provider)
    if (vendors.isEmpty && allVendors.isNotEmpty) {
      vendors = allVendors;
    }

    _cachedMartVendors = vendors;
    _cachedZoneId = zoneId;
    _lastFetchTime = DateTime.now();
    return vendors;
  }

  /// Prefetch vendors when tab bar is shown so first Mart click is fast
  static void prefetchMartVendors() {
    getCachedMartVendors();
  }

  /// Check if mart is available in the current zone
  /// Returns true if there's at least one mart vendor in the current zone
  static Future<bool> isMartAvailableInCurrentZone() async {
    try {
      print('\n🔍 [MART_ZONE_UTILS] ===== MART ZONE CHECKING STARTED =====');
      print(
        '📍 [MART_ZONE_UTILS] Current Zone ID: ${Constant.selectedZone?.id ?? "NULL"}',
      );
      print(
        '📍 [MART_ZONE_UTILS] Current Zone Name: ${Constant.selectedZone?.name ?? "NULL"}',
      );
      print(
        '📍 [MART_ZONE_UTILS] Zone Latitude: ${Constant.selectedZone?.latitude ?? "NULL"}',
      );
      print(
        '📍 [MART_ZONE_UTILS] Zone Longitude: ${Constant.selectedZone?.longitude ?? "NULL"}',
      );
      print(
        '📍 [MART_ZONE_UTILS] Zone Published: ${Constant.selectedZone?.publish ?? "NULL"}',
      );
      // Check if we have a selected zone
      if (Constant.selectedZone?.id == null) {
        print('❌ [MART_ZONE_UTILS] No zone selected - Mart not available');
        print('🔍 [MART_ZONE_UTILS] ===== MART ZONE CHECKING ENDED =====\n');
        return false;
      }
      print(
        '🔍 [MART_ZONE_UTILS] Fetching mart vendors for zone: ${Constant.selectedZone!.id}',
      );
      print(
        '🔍 [MART_ZONE_UTILS] DEBUG: Current zone ID type: ${Constant.selectedZone!.id.runtimeType}',
      );
      print(
        '🔍 [MART_ZONE_UTILS] DEBUG: Current zone ID length: ${Constant.selectedZone!.id!.length}',
      );
      print(
        '🔍 [MART_ZONE_UTILS] DEBUG: Current zone ID bytes: ${Constant.selectedZone!.id!.codeUnits}',
      );

      // DEBUG: Let's also check all mart vendors to see what zones they're in
      print(
        '🔍 [MART_ZONE_UTILS] DEBUG: Checking all mart vendors in database...',
      );
      final allMartVendors = await MartVendorService.getAllMartVendors();
      print(
        '📊 [MART_ZONE_UTILS] DEBUG: Total mart vendors in database: ${allMartVendors.length}',
      );

      if (allMartVendors.isNotEmpty) {
        print('📊 [MART_ZONE_UTILS] DEBUG: All mart vendors and their zones:');
        for (int i = 0; i < allMartVendors.length; i++) {
          final vendor = allMartVendors[i];
          print('   ${i + 1}. ${vendor.title} (ID: ${vendor.id})');
          print('      Zone ID: ${vendor.zoneId}');
          print('      Zone ID type: ${vendor.zoneId.runtimeType}');
          print('      Zone ID length: ${vendor.zoneId?.length}');
          print('      Zone ID bytes: ${vendor.zoneId?.codeUnits}');
          print('      vType: ${vendor.vType}');
          print('      Is Open: ${vendor.isOpen}');
          print('      Location: ${vendor.latitude}, ${vendor.longitude}');
          // Check if zone IDs match
          final currentZoneId = Constant.selectedZone!.id!;
          final vendorZoneId = vendor.zoneId;
          print('      Zone ID Match: ${currentZoneId == vendorZoneId}');
          print('      Zone ID Equals: ${currentZoneId == vendorZoneId}');
          print(
            '      Zone ID Contains: ${currentZoneId.contains(vendorZoneId ?? '')}',
          );
        }
      }
      // Get mart vendors for the current zone
      final martVendors = await MartVendorService.getMartVendorsByZone(
        Constant.selectedZone!.id!,
      );
      // Check if there are any mart vendors in this zone
      final isAvailable = martVendors.isNotEmpty;
      print('📊 [MART_ZONE_UTILS] Mart vendors found: ${martVendors.length}');
      if (martVendors.isNotEmpty) {
        print('✅ [MART_ZONE_UTILS] Mart vendors in zone:');
        for (int i = 0; i < martVendors.length; i++) {
          final vendor = martVendors[i];
          print('   ${i + 1}. Vendor ID: ${vendor.id}');
          print('      Name: ${vendor.title}');
          print('      vType: ${vendor.vType}');
          print('      Zone ID: ${vendor.zoneId}');
          print('      Is Open: ${vendor.isOpen}');
          print('      Location: ${vendor.latitude}, ${vendor.longitude}');
        }
      } else {
        print('❌ [MART_ZONE_UTILS] No mart vendors found in this zone');
      }
      print('🎯 [MART_ZONE_UTILS] Final Result: Mart Available = $isAvailable');
      print('🔍 [MART_ZONE_UTILS] ===== MART ZONE CHECKING ENDED =====\n');
      return isAvailable;
    } catch (e) {
      print('❌ [MART_ZONE_UTILS] Error checking mart availability: $e');
      print(
        '🔍 [MART_ZONE_UTILS] ===== MART ZONE CHECKING ENDED (ERROR) =====\n',
      );
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
