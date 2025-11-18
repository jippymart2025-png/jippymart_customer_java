import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:jippymart_customer/utils/mart_zone_utils.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

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
  bool _addressesInitialized = false;
  late HomeProvider homeProvider;

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> initFunction({required BuildContext context}) async {
    if (_addressesInitialized && shippingAddressList.isNotEmpty) {
      return; // Already initialized
    }
    homeProvider = Provider.of(context, listen: false);
    // Load addresses from userModel if available
    if (Constant.userModel != null &&
        Constant.userModel!.shippingAddress != null &&
        Constant.userModel!.shippingAddress!.isNotEmpty) {
      shippingAddressList = Constant.userModel!.shippingAddress!;
      _addressesInitialized = true;
      notifyListeners();
      return;
    }

    // If userModel is not loaded or addresses are empty, try to load it
    if (shippingAddressList.isEmpty) {
      try {
        final userId = await SqlStorageConst.getFirebaseId();
        if (userId != null && userId.isNotEmpty) {
          final userModel = await getUserProfile(userId);
          if (userModel != null) {
            Constant.userModel = userModel;
            if (userModel.shippingAddress != null &&
                userModel.shippingAddress!.isNotEmpty) {
              shippingAddressList = userModel.shippingAddress!;
              _addressesInitialized = true;
              notifyListeners();
            }
          }
        }
      } catch (e) {
        print('[ADDRESS_LIST_PROVIDER] Error loading addresses: $e');
      }
    }

    _addressesInitialized = true;
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

  // getUser() async {
  //   setLoading(true);
  //   // final userId = await SqlStorageConst.getFirebaseId();
  //   // if (userId == null || userId.isEmpty) {
  //   //   setLoading(false);
  //   //   return;
  //   // }
  //   // await getUserProfile(userId).then((value) {
  //   //   if (value != null) {
  //   //     userModel = value;
  //   //     if (userModel.shippingAddress != null) {
  //   //       shippingAddressList = userModel.shippingAddress!;
  //   //       notifyListeners();
  //   //     }
  //   //   }
  //   // });
  //   setLoading(false);
  // }

  static const Duration timeout = Duration(seconds: 30);

  static Future<UserModel?> getUserProfile(String userId) async {
    try {
      final headers = await getHeaders();
      final response = await http
          .get(
            Uri.parse('${AppConst.baseUrl}users/profile/$userId'),
            headers: headers,
          )
          .timeout(timeout);
      print("getUserProfile ${response.body}");
      print("getUserProfile '${AppConst.baseUrl}users/profile/$userId'");
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final Map<String, dynamic> userData = responseData['data'];
          final processedData = _processApiUserData(userData);
          return UserModel.fromJson(processedData);
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      print("getUserProfile $e");
      return null;
    }
  }

  Future<bool> deleteShippingAddress(String addressId) async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();
      if (userId == null || userId.isEmpty) {
        log("❌ No user ID found");
        return false;
      }

      final headers = await getHeaders();
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
      // Use the specific address endpoint for deletion
      final url =
          '${AppConst.baseUrl}users/$userId/shipping-address/$addressId';

      log("🟢 DELETE URL: $url");

      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));
      log("🔵 STATUS: ${response.statusCode}");
      log("🔵 BODY: ${response.body}");
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          print('✅ [API] Shipping address deleted successfully');
          return true;
        } else {
          log("❌ API responded but success=false");
          return false;
        }
      } else {
        log("❌ Server responded with status: ${response.statusCode}");
        return false;
      }
    } catch (e, st) {
      log("❌ Exception during deleteShippingAddress: $e\n$st");
      return false;
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
        log("❌ No user ID found");
        return false;
      }
      final headers = await getHeaders();
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
      final url =
          '${AppConst.baseUrl}users/$userId/shipping-address?merge=true';
      final shippingAddresses =
          userModel.shippingAddress?.map((address) {
            return {
              'id': address.id,
              'label': address.addressAs, // ✅ Matches your JSON
              'address': address.address,
              'addressAs': address.addressAs,
              'landmark': address.landmark ?? '',
              'city': '',
              'pincode': '',
              'locality': address.locality ?? '',
              'latitude': address.location?.latitude,
              'longitude': address.location?.longitude,
              'isDefault': address.isDefault ?? false,
              'zoneId': address.zoneId, // Optional
            };
          }).toList() ??
          [];

      log("🟢 PUT URL: $url");
      log("🟢 REQUEST BODY: ${jsonEncode(shippingAddresses)}");

      final response = await http
          .put(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(shippingAddresses), // ✅ Array directly
          )
          .timeout(const Duration(seconds: 30));
      log("🔵 STATUS: ${response.statusCode}");
      log("🔵 BODY: ${response.body}");
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          print('✅ [API] User shipping address updated successfully');
          Constant.userModel = userModel;
          notifyListeners();
          return true;
        } else {
          log("❌ API responded but success=false");
          return false;
        }
      } else {
        log("❌ Server responded with status: ${response.statusCode}");
        return false;
      }
    } catch (e, st) {
      log("❌ Exception during updateUser: $e\n$st");
      return false;
    }
  }

  void saveAddressFunction(
    int index,
    BuildContext context,
    AddressListProvider addressListProvider,
  ) async {
    if (location.latitude == null || location.longitude == null) {
      ShowToastDialog.showToast("Please select Location".tr);
    } else if (houseBuildingTextEditingController.value.text.isEmpty) {
      ShowToastDialog.showToast(
        "Please Enter Flat / House / Flore / Building".tr,
      );
    } else if (localityEditingController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please Enter Area / Sector / locality".tr);
    } else {
      setLoading(true);
      ShowToastDialog.showLoader("Please wait".tr);
      try {
        // Prepare the shipping address model
        final shippingModels = ShippingAddress(
          id: shippingModel.id ?? Constant.getUuid(),
          location: location,
          addressAs: selectedSaveAs,
          address: houseBuildingTextEditingController.value.text,
          locality: localityEditingController.value.text,
          landmark: landmarkEditingController.value.text,
          isDefault: shippingAddressList.isEmpty ? true : false,
        );
        print("saveAddressFunction ${jsonEncode(shippingModels.toJson())}");
        if (location.latitude != null && location.longitude != null) {
          try {
            final zoneId = await MartZoneUtils.getZoneIdForCoordinates(
              location.latitude ?? 0.0,
              location.longitude ?? 0.0,
              context,
            );
            if (zoneId.isNotEmpty) {
              shippingModels.zoneId = zoneId;
            }
          } catch (e) {}
        }
        List<ShippingAddress> updatedAddressList;
        if (shippingModel.id != null) {
          updatedAddressList = List<ShippingAddress>.from(shippingAddressList);
          updatedAddressList[index] = shippingModels; // ✅ use shippingModels
          notifyListeners();
        } else {
          // Adding new address
          updatedAddressList = List<ShippingAddress>.from(shippingAddressList);
          updatedAddressList.add(shippingModels); // ✅ use shippingModels
          notifyListeners();
        }
        // Update user model
        userModel.shippingAddress = updatedAddressList;
        final success = await addressListProvider.updateUser(userModel);
        if (success) {
          shippingAddressList = updatedAddressList;
          homeProvider.ensureUserModelIsLoaded();
          ShowToastDialog.closeLoader();
          Get.back();
          ShowToastDialog.showToast("Address saved successfully".tr);
        } else {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast("Failed to save address".tr);
        }
      } catch (e) {
        print(" saveAddressFunction  ${e.toString()} ");
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Error saving address".tr);
      } finally {
        setLoading(false);
      }
    }
  }

  Future<void> deleteAddressFunction({required int index}) async {
    ShowToastDialog.showLoader("Please wait".tr);
    try {
      final addressId = shippingAddressList[index].id;
      final success = await deleteShippingAddress(addressId.toString());
      if (success) {
        shippingAddressList.removeAt(index);
        userModel.shippingAddress = shippingAddressList;
        homeProvider.ensureUserModelIsLoaded();
        ShowToastDialog.closeLoader();
        Get.back();
        ShowToastDialog.showToast("Address deleted".tr);
        notifyListeners();
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Failed to delete address".tr);
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
    }
  }
}
