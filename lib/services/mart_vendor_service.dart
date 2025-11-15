import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippymart_customer/models/mart_vendor_model.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';

class MartVendorService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'vendors';

  static Future<List<MartVendorModel>> getAllMartVendors({
    String search = 'Jippy mart',
  }) async {
    try {
      print('🔍 [MART_VENDOR_SERVICE] Querying ALL mart vendors via API');
      // Build the API URL
      String apiUrl = '${AppConst.baseUrl}mart-items/getMartVendors';
      if (search.isNotEmpty) {
        apiUrl += '?search=$search';
      }
      print('🌐 [MART_VENDOR_SERVICE] API Call: $apiUrl');
      // Make the API call
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: await getHeaders(),
      );
      // Check if the request was successful
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> vendorsData = responseData['data'];
          final vendors = <MartVendorModel>[];
          print(
            '📊 [MART_VENDOR_SERVICE] Processing ${vendorsData.length} vendors from API',
          );
          for (var vendorData in vendorsData) {
            try {
              // Convert the API data to match your model structure
              final processedData = _processApiData(vendorData);
              print(
                '🔍 [MART_VENDOR_SERVICE] DEBUG: Processing vendor ${vendorData['id']}:',
              );
              print('   zoneId: ${processedData['zoneId']}');
              print('   vType: ${processedData['vType']}');
              print('   isOpen: ${processedData['isOpen']}');
              print('   title: ${processedData['title']}');

              final vendor = MartVendorModel.fromJson(processedData);
              vendors.add(vendor);
            } catch (e) {
              print(
                '❌ [MART_VENDOR_SERVICE] Error processing vendor ${vendorData['id']}: $e',
              );
              print('   Raw data: $vendorData');
              // Continue with next vendor
            }
          }
          print(
            '✅ [MART_VENDOR_SERVICE] Successfully processed ${vendors.length} mart vendors',
          );
          return vendors;
        } else {
          print('❌ [MART_VENDOR_SERVICE] API returned success: false');
          return [];
        }
      } else {
        print('❌ [MART_VENDOR_SERVICE] HTTP Error: ${response.statusCode}');
        print('   Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ [MART_VENDOR_SERVICE] Error fetching all mart vendors: $e');
      return [];
    }
  }

  // Helper method to process API data and convert it to your model format
  static Map<String, dynamic> _processApiData(Map<String, dynamic> apiData) {
    // Create a copy of the API data
    final processedData = Map<String, dynamic>.from(apiData);

    // Convert string representations to actual objects if needed
    // For example, if your model expects certain fields to be parsed from JSON strings
    // Parse photos array if it's stored as string
    if (processedData['photos'] is String) {
      try {
        processedData['photos'] = json.decode(processedData['photos']);
      } catch (e) {
        print('⚠️ Error parsing photos: $e');
        processedData['photos'] = [];
      }
    }
    // Parse workingHours if it's stored as string
    if (processedData['workingHours'] is String) {
      try {
        processedData['workingHours'] = json.decode(
          processedData['workingHours'],
        );
      } catch (e) {
        print('⚠️ Error parsing workingHours: $e');
        processedData['workingHours'] = [];
      }
    }
    // Parse categoryID if it's stored as string
    if (processedData['categoryID'] is String) {
      try {
        processedData['categoryID'] = json.decode(processedData['categoryID']);
      } catch (e) {
        print('⚠️ Error parsing categoryID: $e');
        processedData['categoryID'] = [];
      }
    }
    // Parse categoryTitle if it's stored as string
    if (processedData['categoryTitle'] is String) {
      try {
        processedData['categoryTitle'] = json.decode(
          processedData['categoryTitle'],
        );
      } catch (e) {
        print('⚠️ Error parsing categoryTitle: $e');
        processedData['categoryTitle'] = [];
      }
    }
    // Parse filters if it's stored as string
    if (processedData['filters'] is String) {
      try {
        processedData['filters'] = json.decode(processedData['filters']);
      } catch (e) {
        print('⚠️ Error parsing filters: $e');
        processedData['filters'] = {};
      }
    }
    // Parse adminCommission if it's stored as string
    if (processedData['adminCommission'] is String) {
      try {
        processedData['adminCommission'] = json.decode(
          processedData['adminCommission'],
        );
      } catch (e) {
        print('⚠️ Error parsing adminCommission: $e');
        processedData['adminCommission'] = {};
      }
    }
    // Parse specialDiscount if it's stored as string
    if (processedData['specialDiscount'] is String) {
      try {
        processedData['specialDiscount'] = json.decode(
          processedData['specialDiscount'],
        );
      } catch (e) {
        print('⚠️ Error parsing specialDiscount: $e');
        processedData['specialDiscount'] = [];
      }
    }

    // Parse coordinates if it's stored as string
    if (processedData['coordinates'] is String) {
      try {
        processedData['coordinates'] = json.decode(
          processedData['coordinates'],
        );
      } catch (e) {
        print('⚠️ Error parsing coordinates: $e');
        processedData['coordinates'] = {'latitude': 0.0, 'longitude': 0.0};
      }
    }

    return processedData;
  }

  // Get mart vendor by ID
  static Future<MartVendorModel?> getMartVendorById(String vendorId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(vendorId)
          .get();
      if (doc.exists) {
        return MartVendorModel.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error fetching mart vendor by ID: $e');
      return null;
    }
  }

  // Get default mart vendor (first available)
  static Future<MartVendorModel?> getDefaultMartVendor() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('vType', isEqualTo: 'mart')
          .where('isOpen', isEqualTo: true)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return MartVendorModel.fromJson({...doc.data(), 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error fetching default mart vendor: $e');
      return null;
    }
  }

  // Get mart vendors by zone
  static Future<List<MartVendorModel>> getMartVendorsByZone(
    String zoneId,
  ) async {
    try {
      print('🔍 [MART_VENDOR_SERVICE] Querying mart vendors for zone: $zoneId');
      print(
        '📊 [MART_VENDOR_SERVICE] Query: vType="mart" (filtering by zone in memory, regardless of isOpen status)',
      );
      final allMartVendors = await _firestore
          .collection(_collectionName)
          .where('vType', isEqualTo: 'mart')
          .get();
      print(
        '📊 [MART_VENDOR_SERVICE] Found ${allMartVendors.docs.length} total mart vendors in database',
      );
      // Filter by zone and isOpen in memory (more reliable than Firestore query)
      final filteredVendors = <MartVendorModel>[];
      for (var doc in allMartVendors.docs) {
        try {
          final data = doc.data();
          print(
            '🔍 [MART_VENDOR_SERVICE] Processing vendor document: ${doc.id}',
          );
          print('   Raw data keys: ${data.keys.toList()}');
          final vendor = MartVendorModel.fromJson({...data, 'id': doc.id});
          print('🔍 [MART_VENDOR_SERVICE] Checking vendor: ${vendor.title}');
          print('   Zone ID: ${vendor.zoneId} (target: $zoneId)');
          print('   Is Open: ${vendor.isOpen}');
          print('   vType: ${vendor.vType}');
          // Check if vendor matches our criteria (zone only, regardless of open/closed status)
          if (vendor.zoneId == zoneId) {
            print(
              '✅ [MART_VENDOR_SERVICE] Vendor matches zone criteria - adding to results',
            );
            print('   - Zone ID matches: ${vendor.zoneId}');
            print('   - Is Open: ${vendor.isOpen}');
            filteredVendors.add(vendor);
          } else {
            print(
              '❌ [MART_VENDOR_SERVICE] Vendor does not match zone criteria',
            );
            print('   - Zone ID mismatch: ${vendor.zoneId} != $zoneId');
          }
        } catch (e) {
          print(
            '❌ [MART_VENDOR_SERVICE] Error processing vendor document ${doc.id}: $e',
          );
          print('   Raw data: ${doc.data()}');
          // Continue with next vendor
        }
      }

      print(
        '📊 [MART_VENDOR_SERVICE] Final filtered results: ${filteredVendors.length} vendors',
      );

      // Return the filtered results
      return filteredVendors;
    } catch (e) {
      print(
        '❌ [MART_VENDOR_SERVICE] Error fetching mart vendors by zone $zoneId: $e',
      );
      return [];
    }
  }
}
