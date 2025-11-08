import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/services/location_service.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:http/http.dart' as http;

class AddressListProvider extends ChangeNotifier {
  UserModel userModel = UserModel();
  List<ShippingAddress> shippingAddressList = <ShippingAddress>[];
  List saveAsList = ['Home', 'Work', 'Hotel', 'other'];
  String selectedSaveAs = "Home";
  TextEditingController houseBuildingTextEditingController =
      TextEditingController();
  TextEditingController localityEditingController = TextEditingController();
  TextEditingController landmarkEditingController = TextEditingController();
  String localityText = "";
  UserLocation location = UserLocation();
  ShippingAddress shippingModel = ShippingAddress();
  bool isLoading = false;

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void initFunction() {
    getUser();
  }

  void useMyCurrentLocation() async {
    try {
      ShippingAddress? addressModel =
          await LocationService.createShippingAddressFromLocation(
            showLoader: true,
            showError: true,
          );
      if (addressModel != null) {
        Get.back(result: addressModel);
      }
    } catch (e) {
      print('[ADDRESS_LIST] Error getting current location: $e');
      ShowToastDialog.showToast(
        "Failed to get current location. Please try again.".tr,
      );
    }
    notifyListeners();
  }

  clearData() {
    shippingModel = ShippingAddress();
    houseBuildingTextEditingController.clear();
    localityEditingController.clear();
    landmarkEditingController.clear();
    localityText = "";
    location = UserLocation();
    selectedSaveAs = "Home";
    notifyListeners();
  }

  setData(ShippingAddress shippingAddress) {
    shippingModel = shippingAddress;
    houseBuildingTextEditingController.text = shippingAddress.address
        .toString();
    localityEditingController.text = shippingAddress.locality.toString();
    localityText = shippingAddress.locality.toString();
    landmarkEditingController.text = shippingAddress.landmark.toString();
    selectedSaveAs = shippingAddress.addressAs.toString();
    location = shippingAddress.location ?? UserLocation();
    notifyListeners();
  }

  getUser() async {
    print(" getUser getUser ");
    setLoading(true);
    try {
      final userId = await SqlStorageConst.getFirebaseId();
      if (userId == null || userId.isEmpty) {
        print('User ID is null or empty');
        setLoading(false);
        return;
      }
      await getUserProfile(userId).then((value) {
        if (value != null) {
          userModel = value;
          if (userModel.shippingAddress != null) {
            shippingAddressList = userModel.shippingAddress!;
          }
          print(
            'Successfully loaded ${shippingAddressList.length} shipping addresses',
          );
        } else {
          print('Failed to load user profile');
        }
      });
    } catch (e) {
      print('Error in getUser: $e');
    } finally {
      setLoading(false);
    }
  }

  static const Duration timeout = Duration(seconds: 30);

  static Future<UserModel?> getUserProfile(String userId) async {
    try {
      final headers = await getHeaders();
      print('API Response - userId: ${AppConst.baseUrl}users/profile/$userId');
      final response = await http
          .get(
            Uri.parse('${AppConst.baseUrl}users/profile/$userId'),
            headers: headers,
          )
          .timeout(timeout);
      print('API Response - Status: ${response.statusCode}');
      print('API Response - Body: ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final Map<String, dynamic> userData = responseData['data'];
          final processedData = _processApiUserData(userData);
          return UserModel.fromJson(processedData);
        } else {
          print('API returned error: ${responseData['message']}');
          return null;
        }
      } else {
        print('API call failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error in getUserProfile API call: $e');
      return null;
    }
  }

  static Map<String, dynamic> _processApiUserData(
    Map<String, dynamic> apiData,
  ) {
    return {
      'id': apiData['id']?.toString(),
      'firstName': apiData['firstName'],
      'lastName': apiData['lastName'],
      'email': apiData['email'],
      'profilePictureURL': apiData['profilePictureURL'] ?? '',
      'fcmToken': apiData['fcmToken'] ?? '',
      'countryCode': apiData['countryCode'] ?? '+91',
      'phoneNumber': apiData['phoneNumber'] ?? '',
      'wallet_amount': apiData['wallet_amount'] ?? 0,
      'active': apiData['active'] ?? false,
      'isActive': apiData['isActive'] ?? false,
      'isDocumentVerify': apiData['isDocumentVerify'] ?? false,
      'createdAt': _convertToTimestamp(apiData['createdAt']),
      'role': apiData['role'] ?? 'customer',
      'location': apiData['location'],
      'userBankDetails': apiData['userBankDetails'],
      'shippingAddress': _processShippingAddresses(apiData['shippingAddress']),
      'carName': apiData['carName'],
      'carNumber': apiData['carNumber'],
      'carPictureURL': apiData['carPictureURL'],
      'inProgressOrderID': apiData['inProgressOrderID'] ?? [],
      'orderRequestData': apiData['orderRequestData'] ?? [],
      'vendorID': apiData['vendorID'],
      'zoneId': apiData['zoneId'],
      'rotation': apiData['rotation'] ?? 0,
      'appIdentifier': apiData['appIdentifier'] ?? 'android',
      'provider': apiData['provider'] ?? 'email',
      'subscriptionPlanId': apiData['subscriptionPlanId'],
      'subscriptionExpiryDate': _convertToTimestamp(
        apiData['subscriptionExpiryDate'],
      ),
      'subscriptionPlan': apiData['subscriptionPlan'],
    };
  }

  static List<dynamic> _processShippingAddresses(List<dynamic>? apiAddresses) {
    if (apiAddresses == null) return [];
    return apiAddresses.map((address) {
      if (address is Map<String, dynamic>) {
        return {
          'id': address['id'],
          'address': address['address'],
          'addressAs': address['addressAs'],
          'landmark': address['landmark'],
          'locality': address['locality'],
          'location': address['location'],
          'isDefault': address['isDefault'] ?? false,
          'zoneId': address['zoneId'],
        };
      }
      return address;
    }).toList();
  }

  static Timestamp? _convertToTimestamp(dynamic dateString) {
    if (dateString == null) return null;

    try {
      if (dateString is String) {
        final dateTime = DateTime.parse(dateString);
        return Timestamp.fromDate(dateTime);
      }
      return null;
    } catch (e) {
      print('Error converting timestamp: $e');
      return null;
    }
  }

  Future<bool> updateUser(UserModel userModel) async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();
      if (userId == null || userId.isEmpty) {
        print('updateUser: No user ID available');
        return false;
      }
      final headers = await getHeaders();
      final url =
          '${AppConst.baseUrl}users/$userId/shipping-address?merge=true';
      print('🔄 [API] Updating user shipping address: $url');
      // Convert shipping addresses to API format
      final shippingAddresses =
          userModel.shippingAddress?.map((address) {
            return {
              'id': address.id,
              'label': address.addressAs,
              'address': address.address,
              'locality': address.locality,
              'landmark': address.landmark,
              'city': '', // Add if available in your model
              'pincode': '', // Add if available in your model
              'latitude': address.location?.latitude,
              'longitude': address.location?.longitude,
              'isDefault': address.isDefault ?? false,
              'zoneId': address.zoneId,
            };
          }).toList() ??
          [];

      final requestBody = {'shippingAddress': shippingAddresses};
      print('📦 [API] Request body: ${json.encode(requestBody)}');
      final response = await http
          .put(Uri.parse(url), headers: headers, body: json.encode(requestBody))
          .timeout(const Duration(seconds: 30));
      print('📡 [API] Response status: ${response.statusCode}');
      print('📡 [API] Response body: ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          print('✅ [API] User shipping address updated successfully');
          Constant.userModel = userModel;
          notifyListeners();
          return true;
        } else {
          print('❌ [API] Update failed: ${responseData['message']}');
          return false;
        }
      } else {
        print('❌ [API] HTTP error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ [API] Exception in updateUser: $e');
      return false;
    }
  }
}
