import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippymart_customer/models/mart_vendor_model.dart';

class MartVendorService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'vendors';

  // Get all mart vendors
  static Future<List<MartVendorModel>> getAllMartVendors() async {
    try {
      print('🔍 [MART_VENDOR_SERVICE] Querying ALL mart vendors');
      print('📊 [MART_VENDOR_SERVICE] Query: vType="mart" AND isOpen=true');

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('vType', isEqualTo: 'mart')
          .where('isOpen', isEqualTo: true)
          .get();

      final vendors = <MartVendorModel>[];

      for (var doc in querySnapshot.docs) {
        try {
          final data = {...doc.data(), 'id': doc.id};
          print(
            '🔍 [MART_VENDOR_SERVICE] DEBUG: All mart vendors - Raw document data for ${doc.id}:',
          );
          print('   zoneId: ${data['zoneId']}');
          print('   vType: ${data['vType']}');
          print('   isOpen: ${data['isOpen']}');
          print('   title: ${data['title']}');

          final vendor = MartVendorModel.fromJson(data);
          vendors.add(vendor);
        } catch (e) {
          print(
            '❌ [MART_VENDOR_SERVICE] Error processing vendor document ${doc.id}: $e',
          );
          print('   Raw data: ${doc.data()}');
          // Continue with next vendor
        }
      }

      print(
        '📊 [MART_VENDOR_SERVICE] Found ${vendors.length} total mart vendors',
      );
      return vendors;
    } catch (e) {
      print('❌ [MART_VENDOR_SERVICE] Error fetching all mart vendors: $e');
      return [];
    }
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

  // Get mart vendors by category
  static Future<List<MartVendorModel>> getMartVendorsByCategory(
    String categoryId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('vType', isEqualTo: 'mart')
          .where('categoryID', arrayContains: categoryId)
          .where('isOpen', isEqualTo: true)
          .get();
      return querySnapshot.docs
          .map((doc) => MartVendorModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching mart vendors by category: $e');
      return [];
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
