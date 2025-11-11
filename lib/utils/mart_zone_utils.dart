import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/services/mart_vendor_service.dart';
import 'package:jippymart_customer/models/mart_vendor_model.dart';

class MartZoneUtils {
  static List<MartVendorModel>? _cachedMartVendors;
  static DateTime? _lastFetchTime;

  static Future<List<MartVendorModel>> getCachedMartVendors() async {
    if (_cachedMartVendors != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 3) {
      return _cachedMartVendors!;
    }
    final zoneId = Constant.selectedZone?.id;
    if (zoneId == null) return [];
    final vendors = await MartVendorService.getMartVendorsByZone(zoneId);
    _cachedMartVendors = vendors;
    _lastFetchTime = DateTime.now();

    return vendors;
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

  /// Check if mart is temporarily closed in the current zone
  /// Returns true if there are mart vendors but all are closed
  static Future<bool> isMartTemporarilyClosedInCurrentZone() async {
    try {
      print(
        '\n🔍 [MART_ZONE_UTILS] ===== MART TEMPORARILY CLOSED CHECK STARTED =====',
      );
      print(
        '📍 [MART_ZONE_UTILS] Current Zone ID: ${Constant.selectedZone?.id ?? "NULL"}',
      );

      if (Constant.selectedZone?.id == null) {
        print(
          '❌ [MART_ZONE_UTILS] No zone selected - Cannot check mart status',
        );
        return false;
      }
      final martVendors = await MartVendorService.getMartVendorsByZone(
        Constant.selectedZone!.id!,
      );
      if (martVendors.isEmpty) {
        print(
          '📊 [MART_ZONE_UTILS] No mart vendors in zone - Not temporarily closed',
        );
        return false;
      }

      final allClosed = martVendors.every((vendor) => vendor.isOpen == false);
      print('📊 [MART_ZONE_UTILS] Mart vendors in zone: ${martVendors.length}');
      print('📊 [MART_ZONE_UTILS] All vendors closed: $allClosed');

      if (martVendors.isNotEmpty) {
        print('📊 [MART_ZONE_UTILS] Vendor status check:');
        for (int i = 0; i < martVendors.length; i++) {
          final vendor = martVendors[i];
          print('   ${i + 1}. ${vendor.title} - Is Open: ${vendor.isOpen}');
        }
      }

      print(
        '🎯 [MART_ZONE_UTILS] Final Result: Mart Temporarily Closed = $allClosed',
      );
      print(
        '🔍 [MART_ZONE_UTILS] ===== MART TEMPORARILY CLOSED CHECK ENDED =====\n',
      );

      return allClosed;
    } catch (e) {
      print(
        '❌ [MART_ZONE_UTILS] Error checking mart temporarily closed status: $e',
      );
      return false;
    }
  }

  /// Get mart vendors for the current zone
  static Future<List<MartVendorModel>> getMartVendorsForCurrentZone() async {
    try {
      print('🔍 [MART_ZONE_UTILS] Getting mart vendors for current zone');
      print(
        '📍 [MART_ZONE_UTILS] Current Zone ID: ${Constant.selectedZone?.id ?? "NULL"}',
      );

      if (Constant.selectedZone?.id == null) {
        print('❌ [MART_ZONE_UTILS] No zone selected - returning empty list');
        return [];
      }

      final vendors = await MartVendorService.getMartVendorsByZone(
        Constant.selectedZone!.id!,
      );
      print(
        '📊 [MART_ZONE_UTILS] Retrieved ${vendors.length} mart vendors for zone ${Constant.selectedZone!.id}',
      );
      return vendors;
    } catch (e) {
      print(
        '❌ [MART_ZONE_UTILS] Error getting mart vendors for current zone: $e',
      );
      return [];
    }
  }

  /// Check if a specific zone has mart vendors
  static Future<bool> isMartAvailableInZone(String zoneId) async {
    try {
      print(
        '🔍 [MART_ZONE_UTILS] Checking mart availability for specific zone: $zoneId',
      );
      final martVendors = await MartVendorService.getMartVendorsByZone(zoneId);
      final isAvailable = martVendors.isNotEmpty;
      print(
        '📊 [MART_ZONE_UTILS] Zone $zoneId has ${martVendors.length} mart vendors - Available: $isAvailable',
      );
      return isAvailable;
    } catch (e) {
      print(
        '❌ [MART_ZONE_UTILS] Error checking mart availability for zone $zoneId: $e',
      );
      return false;
    }
  }

  /// Get all zones that have mart vendors
  static Future<List<String>> getZonesWithMartVendors() async {
    try {
      print('🔍 [MART_ZONE_UTILS] Getting all zones with mart vendors');
      final allMartVendors = await MartVendorService.getAllMartVendors();
      final zonesWithMart = allMartVendors
          .where((vendor) => vendor.zoneId != null)
          .map((vendor) => vendor.zoneId!)
          .toSet()
          .toList();

      print(
        '📊 [MART_ZONE_UTILS] Total mart vendors found: ${allMartVendors.length}',
      );
      print('📍 [MART_ZONE_UTILS] Zones with mart vendors: $zonesWithMart');
      return zonesWithMart;
    } catch (e) {
      print('❌ [MART_ZONE_UTILS] Error getting zones with mart vendors: $e');
      return [];
    }
  }

  /// Get zone ID for specific coordinates
  /// This is the core method for zone detection during address saving
  static Future<String> getZoneIdForCoordinates(
    double latitude,
    double longitude,
    BuildContext context,
  ) async {
    print(" getZoneIdForCoordinates ${latitude} $longitude ");
    try {
      // Get current zone using the API
      final zoneModel = await HomeProvider.getCurrentZone(latitude, longitude);

      // Check if zoneModel is null (API call failed)
      if (zoneModel == null) {
        print('❌ [MART_ZONE_UTILS] Failed to get zone from API');
        print(
          '🔍 [MART_ZONE_UTILS] ===== ZONE DETECTION ENDED (API FAILED) =====',
        );
        return '';
      }

      // Check if API returned success
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
