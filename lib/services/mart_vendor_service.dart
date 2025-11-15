import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/models/mart_vendor_model.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';

class MartVendorService {
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
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}mart-vendor/$vendorId'),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return MartVendorModel.fromJson(jsonResponse['data']);
        }
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
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}mart-vendor/default'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return MartVendorModel.fromJson(jsonResponse['data']);
        }
      }
      print('Error fetching default mart vendor: ${response.statusCode}');
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
      print('🌐 [MART_VENDOR_SERVICE] Using API endpoint for zone: $zoneId');
      // Make API call to your endpoint
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}mart-vendor/zone/$zoneId'),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        log(" getMartVendorsByZone ${response.body}");
        if (jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['data'];
          print(
            '📊 [MART_VENDOR_SERVICE] API returned ${data.length} mart vendors for zone: $zoneId',
          );

          // Convert API response to MartVendorModel objects
          final List<MartVendorModel> vendors = [];

          for (var vendorData in data) {
            try {
              print(
                '🔍 [MART_VENDOR_SERVICE] Processing vendor: ${vendorData['title']}',
              );
              print('   Zone ID: ${vendorData['zoneId']}');
              print('   Is Open: ${vendorData['isOpen']}');
              print('   vType: ${vendorData['vType']}');
              // Convert to MartVendorModel
              final vendor = MartVendorModel.fromJson({
                ...vendorData,
                'id': vendorData['id'],
              });
              vendors.add(vendor);
              print(
                '✅ [MART_VENDOR_SERVICE] Successfully added vendor: ${vendor.title}',
              );
            } catch (e) {
              print('❌ [MART_VENDOR_SERVICE] Error processing vendor data: $e');
              print('   Raw vendor data: $vendorData');
              // Continue with next vendor
            }
          }
          print(
            '📊 [MART_VENDOR_SERVICE] Final results: ${vendors.length} vendors',
          );
          return vendors;
        } else {
          print('❌ [MART_VENDOR_SERVICE] API returned success: false');
          print('   Response: $jsonResponse');
          return [];
        }
      } else {
        print(
          '❌ [MART_VENDOR_SERVICE] API request failed with status: ${response.statusCode}',
        );
        print('   Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print(
        '❌ [MART_VENDOR_SERVICE] Error fetching mart vendors by zone $zoneId: $e',
      );
      return [];
    }
  }
}
