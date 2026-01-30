import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
import 'dart:io';
import 'package:provider/provider.dart';

// class AddressListProvider extends ChangeNotifier {
//   UserModel userModel = UserModel();
//   List<ShippingAddress> shippingAddressList = <ShippingAddress>[];
//   List saveAsList = ['Home', 'Work', 'Hotel', 'other'];
//   String selectedSaveAs = "Home";
//   TextEditingController houseBuildingTextEditingController =
//       TextEditingController();
//   TextEditingController localityEditingController = TextEditingController();
//   TextEditingController landmarkEditingController = TextEditingController();
//   String localityText = "";
//   UserLocation location = UserLocation();
//   ShippingAddress shippingModel = ShippingAddress();
//   bool isLoading = false;
//   bool _addressesInitialized =
//       false; // Tracks if addresses have been loaded (for internal tracking)
//   String? _lastLoadedUserId; // Tracks which user's addresses were last loaded
//   late HomeProvider homeProvider;
//
//   void setLoading(bool value) {
//     isLoading = value;
//     notifyListeners();
//   }
//
//   /// Reset initialization state - call this when page opens to force refresh
//   void resetInitialization() {
//     _addressesInitialized = false;
//     _lastLoadedUserId = null;
//   }
//
//   Future<void> initFunction({
//     required BuildContext context,
//     bool forceRefresh = false,
//   }) async {
//     try {
//       final userId = await SqlStorageConst.getFirebaseId();
//
//       // Check if user has changed - if so, reset and reload
//       if (_lastLoadedUserId != null && _lastLoadedUserId != userId) {
//         print('[ADDRESS_LIST_PROVIDER] User changed, resetting addresses');
//         resetInitialization();
//         shippingAddressList.clear();
//       }
//
//       // Force refresh if requested or if not initialized
//       if (forceRefresh) {
//         resetInitialization();
//       }
//
//       // Always refresh from API to get latest addresses
//       homeProvider = Provider.of<HomeProvider>(context, listen: false);
//
//       // Fetch fresh user profile from API
//       if (userId != null && userId.isNotEmpty) {
//         final userModel = await getUserProfile(userId);
//         if (userModel != null) {
//           Constant.userModel = userModel;
//
//           // Update addresses list from fresh data
//           if (userModel.shippingAddress != null) {
//             shippingAddressList = List<ShippingAddress>.from(
//               userModel.shippingAddress ?? [],
//             );
//             print(
//               '[ADDRESS_LIST_PROVIDER] Loaded ${shippingAddressList.length} addresses from API',
//             );
//
//             // Also update the local userModel
//             this.userModel = userModel;
//           } else {
//             shippingAddressList.clear();
//             print('[ADDRESS_LIST_PROVIDER] No shipping addresses found');
//           }
//
//           _lastLoadedUserId = userId;
//           _addressesInitialized = true;
//           notifyListeners();
//         } else {
//           print('[ADDRESS_LIST_PROVIDER] Failed to load user profile');
//           shippingAddressList.clear();
//           notifyListeners();
//         }
//       } else {
//         print('[ADDRESS_LIST_PROVIDER] No user ID available');
//         shippingAddressList.clear();
//         notifyListeners();
//       }
//     } catch (e) {
//       print('[ADDRESS_LIST_PROVIDER] Error loading addresses: $e');
//       shippingAddressList.clear();
//       notifyListeners();
//     }
//   }
//
//   void useMyCurrentLocation() async {
//     try {
//       ShippingAddress? addressModel =
//           await LocationService.createShippingAddressFromLocation(
//             showLoader: true,
//             showError: true,
//           );
//       if (addressModel != null) {
//         Get.back(result: addressModel);
//       }
//     } catch (e) {
//       ShowToastDialog.showToast(
//         "Failed to get current location. Please try again.".tr,
//       );
//     }
//     notifyListeners();
//   }
//
//   clearData() {
//     shippingModel = ShippingAddress();
//     houseBuildingTextEditingController.clear();
//     localityEditingController.clear();
//     landmarkEditingController.clear();
//     localityText = "";
//     location = UserLocation();
//     selectedSaveAs = "Home";
//     notifyListeners();
//   }
//
//   setData(ShippingAddress shippingAddress) {
//     shippingModel = shippingAddress;
//     houseBuildingTextEditingController.text = shippingAddress.address
//         .toString();
//     localityEditingController.text = shippingAddress.locality.toString();
//     localityText = shippingAddress.locality.toString();
//     landmarkEditingController.text = shippingAddress.landmark.toString();
//     selectedSaveAs = shippingAddress.addressAs.toString();
//     location = shippingAddress.location ?? UserLocation();
//     notifyListeners();
//   }
//
//   // getUser() async {
//   //   setLoading(true);
//   //   // final userId = await SqlStorageConst.getFirebaseId();
//   //   // if (userId == null || userId.isEmpty) {
//   //   //   setLoading(false);
//   //   //   return;
//   //   // }
//   //   // await getUserProfile(userId).then((value) {
//   //   //   if (value != null) {
//   //   //     userModel = value;
//   //   //     if (userModel.shippingAddress != null) {
//   //   //       shippingAddressList = userModel.shippingAddress!;
//   //   //       notifyListeners();
//   //   //     }
//   //   //   }
//   //   // });
//   //   setLoading(false);
//   // }
//
//   static const Duration timeout = Duration(seconds: 30);
//
//   static Future<UserModel?> getUserProfile(String userId) async {
//     try {
//       final headers = await getHeaders();
//       final response = await http
//           .get(
//             Uri.parse('${AppConst.baseUrl}users/profile/$userId'),
//             headers: headers,
//           )
//           .timeout(timeout);
//       log("getUserProfile ${response.body}");
//       print("getUserProfile '${AppConst.baseUrl}users/profile/$userId'");
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         if (responseData['success'] == true) {
//           final Map<String, dynamic> userData = responseData['data'];
//           final processedData = _processApiUserData(userData);
//           return UserModel.fromJson(processedData);
//         } else {
//           return null;
//         }
//       } else {
//         return null;
//       }
//     } catch (e) {
//       print("getUserProfile $e");
//       return null;
//     }
//   }
//
//   Future<bool> deleteShippingAddress(String addressId) async {
//     try {
//       final userId = await SqlStorageConst.getFirebaseId();
//       if (userId == null || userId.isEmpty) {
//         log("❌ No user ID found");
//         return false;
//       }
//
//       final headers = await getHeaders();
//       headers['Content-Type'] = 'application/json';
//       headers['Accept'] = 'application/json';
//       // Use the specific address endpoint for deletion
//       final url =
//           '${AppConst.baseUrl}users/$userId/shipping-address/$addressId';
//
//       log("🟢 DELETE URL: $url");
//
//       final response = await http
//           .delete(Uri.parse(url), headers: headers)
//           .timeout(const Duration(seconds: 30));
//       log("🔵 STATUS: ${response.statusCode}");
//       log("🔵 BODY: ${response.body}");
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         if (responseData['success'] == true) {
//           print('✅ [API] Shipping address deleted successfully');
//           return true;
//         } else {
//           log("❌ API responded but success=false");
//           return false;
//         }
//       } else {
//         log("❌ Server responded with status: ${response.statusCode}");
//         return false;
//       }
//     } catch (e, st) {
//       log("❌ Exception during deleteShippingAddress: $e\n$st");
//       return false;
//     }
//   }
//
//   static Map<String, dynamic> _processApiUserData(
//     Map<String, dynamic> apiData,
//   ) {
//     return {
//       'id': apiData['id']?.toString(),
//       'firstName': apiData['firstName'],
//       'lastName': apiData['lastName'],
//       'email': apiData['email'],
//       'profilePictureURL': apiData['profilePictureURL'] ?? '',
//       'fcmToken': apiData['fcmToken'] ?? '',
//       'countryCode': apiData['countryCode'] ?? '+91',
//       'phoneNumber': apiData['phoneNumber'] ?? '',
//       'wallet_amount': apiData['wallet_amount'] ?? 0,
//       'active': apiData['active'] ?? false,
//       'isActive': apiData['isActive'] ?? false,
//       'isDocumentVerify': apiData['isDocumentVerify'] ?? false,
//       'createdAt': _convertToTimestamp(apiData['createdAt']),
//       'role': apiData['role'] ?? 'customer',
//       'location': apiData['location'],
//       'userBankDetails': apiData['userBankDetails'],
//       'shippingAddress': _processShippingAddresses(apiData['shippingAddress']),
//       'carName': apiData['carName'],
//       'carNumber': apiData['carNumber'],
//       'carPictureURL': apiData['carPictureURL'],
//       'inProgressOrderID': apiData['inProgressOrderID'] ?? [],
//       'orderRequestData': apiData['orderRequestData'] ?? [],
//       'vendorID': apiData['vendorID'],
//       'zoneId': apiData['zoneId'],
//       'rotation': apiData['rotation'] ?? 0,
//       'appIdentifier': apiData['appIdentifier'] ?? 'android',
//       'provider': apiData['provider'] ?? 'email',
//       'subscriptionPlanId': apiData['subscriptionPlanId'],
//       'subscriptionExpiryDate': _convertToTimestamp(
//         apiData['subscriptionExpiryDate'],
//       ),
//       'subscriptionPlan': apiData['subscriptionPlan'],
//     };
//   }
//
//   static List<dynamic> _processShippingAddresses(List<dynamic>? apiAddresses) {
//     if (apiAddresses == null) return [];
//     return apiAddresses.map((address) {
//       if (address is Map<String, dynamic>) {
//         return {
//           'id': address['id'],
//           'address': address['address'],
//           'addressAs': address['addressAs'],
//           'landmark': address['landmark'],
//           'locality': address['locality'],
//           'location': address['location'],
//           'isDefault': address['isDefault'] ?? false,
//           'zoneId': address['zoneId'],
//         };
//       }
//       return address;
//     }).toList();
//   }
//
//   static Timestamp? _convertToTimestamp(dynamic dateString) {
//     if (dateString == null) return null;
//
//     try {
//       if (dateString is String) {
//         final dateTime = DateTime.parse(dateString);
//         return Timestamp.fromDate(dateTime);
//       }
//       return null;
//     } catch (e) {
//       print('Error converting timestamp: $e');
//       return null;
//     }
//   }
//
//   Future<bool> updateUser(UserModel userModel) async {
//     try {
//       final userId = await SqlStorageConst.getFirebaseId();
//       if (userId == null || userId.isEmpty) {
//         log("❌ No user ID found");
//         return false;
//       }
//       final headers = await getHeaders();
//       headers['Content-Type'] = 'application/json';
//       headers['Accept'] = 'application/json';
//       final url =
//           '${AppConst.baseUrl}users/$userId/shipping-address?merge=true';
//       final shippingAddresses =
//           userModel.shippingAddress?.map((address) {
//             return {
//               'id': address.id,
//               'label': address.addressAs, // ✅ Matches your JSON
//               'address': address.address,
//               'addressAs': address.addressAs,
//               'landmark': address.landmark ?? '',
//               'city': '',
//               'pincode': '',
//               'locality': address.locality ?? '',
//               'latitude': address.location?.latitude,
//               'longitude': address.location?.longitude,
//               "location": {
//                 "latitude": address.location?.latitude,
//                 "longitude": address.location?.longitude,
//               },
//               'isDefault': address.isDefault ?? false,
//               'zoneId': address.zoneId, // Optional
//             };
//           }).toList() ??
//           [];
//
//       log("🟢 PUT URL: $url");
//       log("🟢 REQUEST BODY: ${jsonEncode(shippingAddresses)}");
//
//       final response = await http
//           .put(
//             Uri.parse(url),
//             headers: headers,
//             body: jsonEncode(shippingAddresses), // ✅ Array directly
//           )
//           .timeout(const Duration(seconds: 30));
//       log("🔵 STATUS: ${response.statusCode}");
//       log("🔵 BODY: ${response.body}");
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         if (responseData['success'] == true) {
//           print('✅ [API] User shipping address updated successfully');
//           Constant.userModel = userModel;
//           notifyListeners();
//           return true;
//         } else {
//           log("❌ API responded but success=false");
//           return false;
//         }
//       } else {
//         log("❌ Server responded with status: ${response.statusCode}");
//         return false;
//       }
//     } catch (e, st) {
//       log("❌ Exception during updateUser: $e\n$st");
//       return false;
//     }
//   }
//
//   void saveAddressFunction(
//     int index,
//     BuildContext context,
//     AddressListProvider addressListProvider,
//   ) async {
//     if (location.latitude == null || location.longitude == null) {
//       ShowToastDialog.showToast("Please select Location".tr);
//     } else if (houseBuildingTextEditingController.value.text.isEmpty) {
//       ShowToastDialog.showToast(
//         "Please Enter Flat / House / Flore / Building".tr,
//       );
//     } else if (localityEditingController.value.text.isEmpty) {
//       ShowToastDialog.showToast("Please Enter Area / Sector / locality".tr);
//     } else {
//       setLoading(true);
//       ShowToastDialog.showLoader("Please wait".tr);
//       try {
//         // Prepare the shipping address model
//         final shippingModels = ShippingAddress(
//           id: shippingModel.id ?? Constant.getUuid(),
//           location: location,
//           addressAs: selectedSaveAs,
//           address: houseBuildingTextEditingController.value.text,
//           locality: localityEditingController.value.text,
//           landmark: landmarkEditingController.value.text,
//           isDefault: shippingAddressList.isEmpty ? true : false,
//         );
//         print("saveAddressFunction ${jsonEncode(shippingModels.toJson())}");
//         if (location.latitude != null && location.longitude != null) {
//           try {
//             final zoneId = await MartZoneUtils.getZoneIdForCoordinates(
//               location.latitude ?? 0.0,
//               location.longitude ?? 0.0,
//               context,
//             );
//             if (zoneId.isNotEmpty) {
//               shippingModels.zoneId = zoneId;
//             }
//           } catch (e) {}
//         }
//         List<ShippingAddress> updatedAddressList;
//         if (shippingModel.id != null) {
//           updatedAddressList = List<ShippingAddress>.from(shippingAddressList);
//           updatedAddressList[index] = shippingModels; // ✅ use shippingModels
//           notifyListeners();
//         } else {
//           // Adding new address
//           updatedAddressList = List<ShippingAddress>.from(shippingAddressList);
//           updatedAddressList.add(shippingModels); // ✅ use shippingModels
//           notifyListeners();
//         }
//         // Update user model
//         userModel.shippingAddress = updatedAddressList;
//         final success = await addressListProvider.updateUser(userModel);
//         if (success) {
//           shippingAddressList = updatedAddressList;
//           homeProvider.ensureUserModelIsLoaded();
//           ShowToastDialog.closeLoader();
//           Get.back();
//           ShowToastDialog.showToast("Address saved successfully".tr);
//         } else {
//           ShowToastDialog.closeLoader();
//           ShowToastDialog.showToast("Failed to save address".tr);
//         }
//       } catch (e) {
//         print(" saveAddressFunction  ${e.toString()} ");
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast("Error saving address".tr);
//       } finally {
//         setLoading(false);
//       }
//     }
//   }
//
//   Future<void> deleteAddressFunction({required int index}) async {
//     ShowToastDialog.showLoader("Please wait".tr);
//     try {
//       final addressId = shippingAddressList[index].id;
//       final success = await deleteShippingAddress(addressId.toString());
//       if (success) {
//         shippingAddressList.removeAt(index);
//         userModel.shippingAddress = shippingAddressList;
//         homeProvider.ensureUserModelIsLoaded();
//         ShowToastDialog.closeLoader();
//         Get.back();
//         ShowToastDialog.showToast("Address deleted".tr);
//         notifyListeners();
//       } else {
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast("Failed to delete address".tr);
//       }
//     } catch (e) {
//       ShowToastDialog.closeLoader();
//     }
//   }
// }

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

  // Cache management
  static final Map<String, UserModel> _userCache = {};
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);
  static const Duration _debounceDuration = Duration(milliseconds: 500);
  Timer? _debounceTimer;
  String? _currentUserId;

  // Add this for better state management
  bool _isInitializing = false;

  bool get isInitializing => _isInitializing;

  // Add HomeProvider reference
  HomeProvider? _homeProvider;

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> initFunction({
    required BuildContext context,
    bool forceRefresh = false,
  }) async {
    // Prevent multiple simultaneous initializations
    if (_isInitializing) return;

    try {
      _isInitializing = true;
      final userId = await SqlStorageConst.getFirebaseId();

      if (userId == null || userId.isEmpty) {
        shippingAddressList.clear();
        _isInitializing = false;
        notifyListeners();
        return;
      }

      _currentUserId = userId;

      // Initialize HomeProvider
      _homeProvider = Provider.of<HomeProvider>(context, listen: false);

      // Check cache first (unless forced refresh)
      final now = DateTime.now();
      if (!forceRefresh &&
          _userCache.containsKey(userId) &&
          _lastFetchTime != null &&
          now.difference(_lastFetchTime!) < _cacheDuration) {
        _loadFromCache(userId);
        _isInitializing = false;
        notifyListeners();
        return;
      }

      // Fetch from API with debouncing
      await _debouncedApiCall(userId);
    } catch (e) {
      print('[ADDRESS_LIST_PROVIDER] Error loading addresses: $e');
      shippingAddressList.clear();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _debouncedApiCall(String userId) async {
    // Cancel previous timer if exists
    _debounceTimer?.cancel();

    // Create new debounced call
    _debounceTimer = Timer(_debounceDuration, () async {
      try {
        final userModel = await getUserProfile(userId);
        if (userModel != null) {
          _updateFromApiResponse(userModel);
          _lastFetchTime = DateTime.now();
        }
      } catch (e) {
        print('[ADDRESS_LIST_PROVIDER] API call error: $e');
        // Fallback to cache if available
        if (_userCache.containsKey(userId)) {
          _loadFromCache(userId);
        }
      }
    });
  }

  void _updateFromApiResponse(UserModel userModel) {
    Constant.userModel = userModel;
    this.userModel = userModel;

    // Update addresses list
    if (userModel.shippingAddress != null) {
      shippingAddressList = List<ShippingAddress>.from(
        userModel.shippingAddress ?? [],
      );

      // Cache the user data
      _userCache[_currentUserId!] = UserModel.fromJson(
        userModel.toJson(),
      ); // Create a deep copy

      print(
        '[ADDRESS_LIST_PROVIDER] Loaded ${shippingAddressList.length} addresses',
      );
    } else {
      shippingAddressList.clear();
    }

    notifyListeners();
  }

  void _loadFromCache(String userId) {
    final cachedUser = _userCache[userId];
    if (cachedUser != null) {
      userModel = UserModel.fromJson(cachedUser.toJson()); // Deep copy
      shippingAddressList = List<ShippingAddress>.from(
        cachedUser.shippingAddress ?? [],
      );
      print(
        '[ADDRESS_LIST_PROVIDER] Loaded ${shippingAddressList.length} addresses from cache',
      );
    }
  }

  // Clear cache for specific user
  void clearCache() {
    if (_currentUserId != null) {
      _userCache.remove(_currentUserId);
    }
    _lastFetchTime = null;
  }

  // Optimized useMyCurrentLocation with error handling
  Future<void> useMyCurrentLocation() async {
    try {
      ShowToastDialog.showLoader("Getting your location...".tr);

      final addressModel =
          await LocationService.createShippingAddressFromLocation(
            showLoader: false, // We're showing loader above
            showError: true,
          ).timeout(const Duration(seconds: 10));

      ShowToastDialog.closeLoader();

      if (addressModel != null) {
        Get.back(result: addressModel);
      } else {
        ShowToastDialog.showToast(
          "Could not get location. Please try again.".tr,
        );
      }
    } on TimeoutException {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Location request timed out".tr);
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Failed to get location".tr);
    }
  }

  // Optimized clearData method
  void clearData() {
    // Clear controllers efficiently
    houseBuildingTextEditingController.clear();
    localityEditingController.clear();
    landmarkEditingController.clear();

    // Reset other values
    shippingModel = ShippingAddress();
    localityText = "";
    location = UserLocation();
    selectedSaveAs = "Home";

    // Only notify if actually changed
    notifyListeners();
  }

  // Optimized setData method
  void setData(ShippingAddress shippingAddress) {
    shippingModel = shippingAddress;

    // Batch controller updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      houseBuildingTextEditingController.text =
          shippingAddress.address?.toString() ?? '';
      localityEditingController.text =
          shippingAddress.locality?.toString() ?? '';
      landmarkEditingController.text =
          shippingAddress.landmark?.toString() ?? '';

      localityText = shippingAddress.locality?.toString() ?? '';
      selectedSaveAs = shippingAddress.addressAs?.toString() ?? 'Home';
      location = shippingAddress.location ?? UserLocation();

      notifyListeners();
    });
  }

  // Add this static helper method to check internet connection
  static Future<bool> checkInternet() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // Optimized API call with connection check
  static Future<UserModel?> getUserProfile(String userId) async {
    try {
      final hasConnection = await checkInternet();
      if (!hasConnection) {
        print('[API] No internet connection');
        return null;
      }

      final headers = await getHeaders();
      final response = await http
          .get(
            Uri.parse('${AppConst.baseUrl}users/profile/$userId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15)); // Reduced timeout

      print("[API] Profile response: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final Map<String, dynamic> userData = responseData['data'];
          final processedData = _processApiUserData(userData);
          return UserModel.fromJson(processedData);
        }
      } else if (response.statusCode == 304) {
        // Not Modified - use cache
        print('[API] Using cached data (304)');
      }

      return null;
    } catch (e) {
      print("getUserProfile error: $e");
      return null;
    }
  }

  // Add this static method to process API data
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

  // Add this helper method
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

  // Add this helper method
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

  // Optimized delete address
  Future<bool> deleteAddressFunction({required int index}) async {
    if (index < 0 || index >= shippingAddressList.length) {
      ShowToastDialog.showToast("Invalid address".tr);
      return false;
    }

    ShowToastDialog.showLoader("Please wait".tr);

    try {
      final addressId = shippingAddressList[index].id;
      final success = await deleteShippingAddress(addressId.toString());

      if (success) {
        // Update UI immediately for better UX
        shippingAddressList.removeAt(index);

        // Update user model
        userModel.shippingAddress = shippingAddressList;

        // Invalidate cache
        clearCache();

        // Notify home provider
        if (_homeProvider != null) {
          _homeProvider!.ensureUserModelIsLoaded();
        }

        ShowToastDialog.closeLoader();
        Get.back();
        ShowToastDialog.showToast("Address deleted".tr);

        return true;
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Failed to delete address".tr);
        return false;
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("An error occurred".tr);
      return false;
    }
  }

  // Optimized save address
  Future<void> saveAddressFunction(
    int index,
    BuildContext context,
    AddressListProvider addressListProvider,
  ) async {
    // Validate required fields
    if (location.latitude == null || location.longitude == null) {
      ShowToastDialog.showToast("Please select Location".tr);
      return;
    }

    if (houseBuildingTextEditingController.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter House/Flat/Floor number".tr);
      return;
    }

    if (localityEditingController.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter Area/Sector/Locality".tr);
      return;
    }

    setLoading(true);
    ShowToastDialog.showLoader("Saving address...".tr);

    try {
      // Prepare address model
      final shippingModels = ShippingAddress(
        id: shippingModel.id ?? Constant.getUuid(),
        location: location,
        addressAs: selectedSaveAs,
        address: houseBuildingTextEditingController.text.trim(),
        locality: localityEditingController.text.trim(),
        landmark: landmarkEditingController.text.trim(),
        isDefault: shippingAddressList.isEmpty ? true : false,
      );

      // Get zone ID only if needed
      if (location.latitude != null && location.longitude != null) {
        final zoneId = await MartZoneUtils.getZoneIdForCoordinates(
          location.latitude!,
          location.longitude!,
          context,
        ).catchError((e) => '');

        if (zoneId.isNotEmpty) {
          shippingModels.zoneId = zoneId;
        }
      }

      // Update address list
      List<ShippingAddress> updatedAddressList;
      if (shippingModel.id != null && index >= 0) {
        updatedAddressList = List<ShippingAddress>.from(shippingAddressList);
        updatedAddressList[index] = shippingModels;
      } else {
        updatedAddressList = List<ShippingAddress>.from(shippingAddressList);
        updatedAddressList.add(shippingModels);
      }

      // Update user model and save
      userModel.shippingAddress = updatedAddressList;
      final success = await addressListProvider.updateUser(userModel);

      if (success) {
        shippingAddressList = updatedAddressList;
        clearCache(); // Invalidate cache

        // Refresh home provider data
        if (_homeProvider != null) {
          _homeProvider!.ensureUserModelIsLoaded();
        }

        ShowToastDialog.closeLoader();
        Get.back();
        ShowToastDialog.showToast("Address saved successfully".tr);
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Failed to save address".tr);
      }
    } catch (e) {
      print("saveAddressFunction error: $e");
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error saving address".tr);
    } finally {
      setLoading(false);
    }
  }

  // Add this copy method to UserModel (or create a copyWith method in UserModel)
  // If UserModel doesn't have copyWith, add this method to AddressListProvider:
  UserModel _copyUserModel(UserModel original) {
    return UserModel.fromJson(original.toJson());
  }

  // Add copyWith method to ShippingAddress if needed
  ShippingAddress _copyShippingAddress(ShippingAddress original) {
    return ShippingAddress(
      id: original.id,
      address: original.address,
      addressAs: original.addressAs,
      landmark: original.landmark,
      locality: original.locality,
      location: original.location != null
          ? UserLocation(
              latitude: original.location!.latitude,
              longitude: original.location!.longitude,
            )
          : null,
      isDefault: original.isDefault,
      zoneId: original.zoneId,
    );
  }

  void dispose() {
    _debounceTimer?.cancel();
    houseBuildingTextEditingController.dispose();
    localityEditingController.dispose();
    landmarkEditingController.dispose();
    super.dispose();
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
              "location": {
                "latitude": address.location?.latitude,
                "longitude": address.location?.longitude,
              },
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

  // ... rest of your existing methods (updateUser, deleteShippingAddress, etc.)
}
