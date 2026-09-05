import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/address_screens/provider/getCustomerDeliveryAddresses.dart';
import 'package:jippymart_customer/app/address_screens/provider/saveCustomerDeliveryAddress.dart';
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
      _homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final userId = await SqlStorageConst.getFirebaseId();
      final customerId = await SqlStorageConst.getUserId();

      if ((userId == null || userId.isEmpty) &&
          (customerId == null || customerId.isEmpty)) {
        shippingAddressList.clear();
        _isInitializing = false;
        notifyListeners();
        return;
      }

      _currentUserId = userId ?? customerId;

      // Check cache first (unless forced refresh)
      final now = DateTime.now();
      if (!forceRefresh &&
          _userCache.containsKey(_currentUserId) &&
          _lastFetchTime != null &&
          now.difference(_lastFetchTime!) < _cacheDuration) {
        _loadFromCache(_currentUserId!);
        _isInitializing = false;
        notifyListeners();
        return;
      }

      // Fetch from API with debouncing
      await _debouncedApiCall(_currentUserId!);
    } catch (e) {
      debugPrint('[ADDRESS_LIST_PROVIDER] Error loading addresses: $e');
      shippingAddressList.clear();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _debouncedApiCall(String userId) async {
    _debounceTimer?.cancel();

    final completer = Completer<void>();

    _debounceTimer = Timer(_debounceDuration, () async {
      try {
        final customerId =
            int.tryParse(await SqlStorageConst.getUserId() ?? '') ?? 0;
        if (customerId == 0) {
          if (_userCache.containsKey(userId)) {
            _loadFromCache(userId);
          }
          return;
        }

        final addresses = await getCustomerDeliveryAddresses(
          customerId: customerId,
        );
        _updateFromDeliveryAddresses(addresses);
        _lastFetchTime = DateTime.now();
      } catch (e) {
        debugPrint('[ADDRESS_LIST_PROVIDER] API call error: $e');
        if (_userCache.containsKey(userId)) {
          _loadFromCache(userId);
        }
      } finally {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    await completer.future;
  }

  void _updateFromDeliveryAddresses(List<ShippingAddress> addresses) {
    shippingAddressList = List<ShippingAddress>.from(addresses);
    userModel.shippingAddress = shippingAddressList;
    Constant.userModel ??= UserModel();
    Constant.userModel!.shippingAddress = shippingAddressList;

    if (_currentUserId != null) {
      _userCache[_currentUserId!] = UserModel.fromJson(userModel.toJson());
    }

    debugPrint(
      '[ADDRESS_LIST_PROVIDER] Loaded ${shippingAddressList.length} addresses',
    );

    notifyListeners();
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

      debugPrint(
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
      debugPrint(
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
  Future<ShippingAddress?> useMyCurrentLocation() async {
    try {
      ShowToastDialog.showLoader("Getting your location...".tr);

      final addressModel =
          await LocationService.createShippingAddressFromLocation(
            showLoader: false, // We're showing loader above
            showError: true,
          ).timeout(const Duration(seconds: 10));

      ShowToastDialog.closeLoader();

      if (addressModel != null) {
        return addressModel;
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
    return null;
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
    houseBuildingTextEditingController.text =
        shippingAddress.address?.toString() ?? '';
    localityEditingController.text = shippingAddress.locality?.toString() ?? '';
    landmarkEditingController.text = shippingAddress.landmark?.toString() ?? '';

    localityText = shippingAddress.locality?.toString() ?? '';
    selectedSaveAs = shippingAddress.addressAs?.toString() ?? 'Home';
    location = shippingAddress.location ?? UserLocation();

    notifyListeners();
  }

  // Add this static helper method to check internet connection
  static Future<bool> checkInternet() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult is List<ConnectivityResult>) {
        return !connectivityResult.contains(ConnectivityResult.none);
      }
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // In-memory profile cache so the co/customers/{id} API is not hit
  // again and again by multiple providers (home/profile/cart/chat...).
  static UserModel? _cachedProfile;
  static String? _cachedProfileKey;
  static DateTime? _cachedProfileAt;
  static const Duration _profileCacheLifetime = Duration(seconds: 20);

  // Optimized API call with connection check
  static Future<UserModel?> getUserProfile(String userId) async {
    final effectiveId = await _resolveCustomerId(userId);
    if (effectiveId == null) {
      debugPrint('[API] No usable customer id for profile fetch');
      return null;
    }

    // Serve from in-memory cache when the same customer was fetched recently.
    if (_cachedProfile != null &&
        _cachedProfileKey == effectiveId &&
        _cachedProfileAt != null &&
        DateTime.now().difference(_cachedProfileAt!) < _profileCacheLifetime) {
      return _cachedProfile;
    }

    try {
      final hasConnection = await checkInternet();
      if (!hasConnection) {
        debugPrint('[API] No internet connection');
        return null;
      }

      final headers = await getHeaders();
      final response = await http
          .get(
            Uri.parse('${AppConst.outletBaseUrl}co/customers/$effectiveId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15)); // Reduced timeout

      debugPrint("[API] Profile response: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final dynamic raw = responseData['data'];
          final Map<String, dynamic> userData = raw is Map
              ? Map<String, dynamic>.from(raw)
              : <String, dynamic>{};
          if (userData.isEmpty) {
            userData.addAll(<String, dynamic>{
              for (final entry in responseData.entries)
                if (entry.key != 'success' && entry.key != 'message')
                  entry.key: entry.value,
            });
          }
          final processedData = _processApiUserData(userData);
          final model = UserModel.fromJson(processedData);

          // Persist (name/email/phone/id) + cache so the API isn't re-hammered.
          _cachedProfile = model;
          _cachedProfileKey = effectiveId;
          _cachedProfileAt = DateTime.now();
          await SqlStorageConst.storeUserData(model);
          return model;
        }
      } else if (response.statusCode == 304) {
        // Not Modified - use cache
        debugPrint('[API] Using cached data (304)');
      }

      return null;
    } catch (e) {
      debugPrint("getUserProfile error: $e");
      return null;
    }
  }

  /// Resolves the numeric backend customer id used by `co/customers/{id}`.
  /// Prefers an already-numeric value, then the saved `user_id` from storage,
  /// and finally falls back to whatever was passed in.
  static Future<String?> _resolveCustomerId(String userId) async {
    final passed = userId.trim();
    if (passed.isNotEmpty && int.tryParse(passed) != null) {
      return passed;
    }
    try {
      final stored = await SqlStorageConst.getUserId();
      if (stored != null && stored.isNotEmpty && int.tryParse(stored) != null) {
        return stored;
      }
    } catch (_) {}
    if (passed.isNotEmpty) return passed;
    try {
      return await SqlStorageConst.getFirebaseId();
    } catch (_) {
      return null;
    }
  }

  // Add this static method to process API data
  static Map<String, dynamic> _processApiUserData(
    Map<String, dynamic> apiData,
  ) {
    final id = apiData['id'] ??
        apiData['customerId'] ??
        apiData['customer_id'] ??
        apiData['userId'];
    final firstName =
        apiData['firstName'] ?? apiData['firstname'] ?? apiData['name'];
    final phoneNumber = apiData['phoneNumber'] ??
        apiData['phonenumber'] ??
        apiData['mobile'] ??
        apiData['phone'];
    final email = apiData['email'] ?? apiData['mail'];
    final profilePic = apiData['profilePictureURL'] ??
        apiData['profilePicUrl'] ??
        apiData['profile_picture_url'] ??
        apiData['profilePicture'];

    return {
      'id': id?.toString(),
      'firstName': firstName,
      'lastName': apiData['lastName'],
      'email': email,
      'profilePictureURL': profilePic ?? '',
      'fcmToken': apiData['fcmToken'] ?? '',
      'countryCode': apiData['countryCode'] ?? '+91',
      'phoneNumber': phoneNumber ?? '',
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
      debugPrint('Error converting timestamp: $e');
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
        isDefault: shippingAddressList.isEmpty,
      );

      // Get zone ID
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

      // Update local address list
      List<ShippingAddress> updatedAddressList = List<ShippingAddress>.from(
        shippingAddressList,
      );

      if (shippingModel.id != null && index >= 0) {
        updatedAddressList[index] = shippingModels;
      } else {
        updatedAddressList.add(shippingModels);
      }

      userModel.shippingAddress = updatedAddressList;

      final customerId =
          int.tryParse(await SqlStorageConst.getUserId() ?? '') ?? 0;

      final deliveryAddressId = await saveCustomerDeliveryAddress(
        customerId: customerId,
        latitude: location.latitude ?? 0.0,
        longitude: location.longitude ?? 0.0,
        doorNo: houseBuildingTextEditingController.text.trim(),
        buildingName: localityEditingController.text.trim(),
        laneNo: landmarkEditingController.text.trim(),
        createdBy: customerId,
      );

      if (deliveryAddressId != null) {
        shippingModels.id = deliveryAddressId.toString();
        if (shippingModel.id != null && index >= 0) {
          updatedAddressList[index] = shippingModels;
        } else if (updatedAddressList.isNotEmpty) {
          updatedAddressList[updatedAddressList.length - 1] = shippingModels;
        }
        userModel.shippingAddress = updatedAddressList;
        shippingAddressList = updatedAddressList;

        clearCache();

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
    } catch (e, stackTrace) {
      debugPrint("saveAddressFunction Error: $e");
      print(stackTrace);

      ShowToastDialog.closeLoader();

      ShowToastDialog.showToast("Error saving address".tr);
    } finally {
      setLoading(false);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    houseBuildingTextEditingController.dispose();
    localityEditingController.dispose();
    landmarkEditingController.dispose();
    super.dispose();
  }

  Future<bool> deleteShippingAddress(String addressId) async {
    try {
      debugPrint("========== DELETE START ==========");

      debugPrint("Address ID: $addressId");

      final userId = await SqlStorageConst.getFirebaseId();
      debugPrint("Firebase User ID: $userId");

      if (userId == null || userId.isEmpty) {
        debugPrint("❌ No user found");
        return false;
      }

      final headers = await getHeaders();
      debugPrint("Headers: $headers");

      final url =
          '${AppConst.outletBaseUrl}co/customers/deleteCustomerDeliveryAddress?customerAddressId=$addressId';

      debugPrint("DELETE URL: $url");

      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Your API format
        if (jsonData["statusCode"].toString() == "200") {
          debugPrint("✅ Address deleted successfully");
          return true;
        }

        debugPrint("❌ Delete failed: ${jsonData["statusMsg"]}");
        return false;
      }

      debugPrint("❌ HTTP Error: ${response.statusCode}");
      return false;
    } catch (e, st) {
      debugPrint("❌ DELETE ERROR: $e");
      debugPrintStack(stackTrace: st);
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
          debugPrint('✅ [API] User shipping address updated successfully');
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
