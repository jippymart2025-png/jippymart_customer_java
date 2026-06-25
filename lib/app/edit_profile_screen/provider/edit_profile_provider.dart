import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';

class EditProfileProvider extends ChangeNotifier {
  bool _isSaving = false;

  // State variables
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  UserModel _userModel = UserModel();

  UserModel get userModel => _userModel;

  // Controllers
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneNumberController;
  late TextEditingController countryCodeController;

  // Image
  String _profileImage = "";

  String get profileImage => _profileImage;
  bool _hasProfileImageChanged = false;
  int _customerStatusId = 1;
  String? _referralCode;

  // Cache user ID to avoid repeated calls
  String? _cachedUserId;
  static bool _isUserModelInitialized = false;

  // Debouncing for save operation
  DateTime? _lastSaveTime;
  static const int _saveDebounceMs = 2000; // 2 seconds debounce

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  EditProfileProvider() {
    _initControllers();
  }

  void _initControllers() {
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    phoneNumberController = TextEditingController();
    countryCodeController = TextEditingController(text: "+91");
  }

  // Initialize with existing user data (no API call if already loaded)
  Future<void> initFunction({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _isUserModelInitialized &&
        Constant.userModel != null) {
      _loadFromCache();
      return;
    }

    await _loadUserData(forceRefresh: forceRefresh);
  }

  void _loadFromCache() {
    if (Constant.userModel != null) {
      _userModel = Constant.userModel!;
      _populateFormFields();
      _profileImage = _userModel.profilePictureURL ?? "";
      _isUserModelInitialized = true;
    }
  }

  Future<void> _loadUserData({bool forceRefresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final customerId = await _getCustomerId();
      Map<String, dynamic>? profile;

      if (customerId != null) {
        profile = await fetchCustomerProfile(customerId);
      }

      if (profile != null) {
        _applyProfileMap(profile);
      } else if (!forceRefresh && Constant.userModel != null) {
        _userModel = Constant.userModel!;
        _populateFormFields();
        _profileImage = _userModel.profilePictureURL ?? "";
      } else {
        final userId = await _getUserId();
        if (userId.isNotEmpty) {
          final user = await AddressListProvider.getUserProfile(userId);
          if (user != null) {
            _userModel = user;
            Constant.userModel = user;
            _populateFormFields();
            _profileImage = _userModel.profilePictureURL ?? "";
          }
        }
      }

      _isUserModelInitialized = true;
    } catch (e) {
      print('[EDIT_PROFILE] Error loading user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyProfileMap(Map<String, dynamic> profile) {
    _userModel.id = profile['customerId']?.toString();
    _userModel.firstName = profile['firstName']?.toString();
    _userModel.lastName = profile['lastName']?.toString();
    _userModel.email = profile['email']?.toString();
    _userModel.phoneNumber = profile['phoneNumber']?.toString();
    _userModel.role = Constant.userRoleCustomer;
    _userModel.active = true;
    _customerStatusId = (profile['customerStatusId'] as num?)?.toInt() ?? 1;
    _referralCode = profile['referralCode']?.toString();

    Constant.userModel = _userModel;
    _populateFormFields();
    _profileImage = _userModel.profilePictureURL ?? "";
  }

  static Future<Map<String, dynamic>?> fetchCustomerProfile(
    int customerId,
  ) async {
    try {
      final uri = Uri.parse(
        '${AppConst.outletBaseUrl}co/customers/$customerId',
      );
      final response = await http
          .get(uri, headers: await getHeaders())
          .timeout(const Duration(seconds: 20));

      print('[EDIT_PROFILE] GET $uri -> ${response.statusCode}');
      print('[EDIT_PROFILE] response: ${response.body}');

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (e) {
      print('[EDIT_PROFILE] fetchCustomerProfile error: $e');
      return null;
    }
  }

  Future<String> _getUserId() async {
    if (_cachedUserId != null) return _cachedUserId!;

    _cachedUserId =
        await SqlStorageConst.getUserId() ??
        await SqlStorageConst.getFirebaseId() ??
        '';
    return _cachedUserId!;
  }

  Future<int?> _getCustomerId() async {
    final storedId = await SqlStorageConst.getUserId() ?? _userModel.id ?? '';
    return int.tryParse(storedId);
  }

  void _populateFormFields() {
    if (_userModel.id != null) {
      firstNameController.text = _userModel.firstName?.toString() ?? "";
      lastNameController.text = _userModel.lastName?.toString() ?? "";
      emailController.text = _userModel.email?.toString() ?? "";
      phoneNumberController.text = _userModel.phoneNumber?.toString() ?? "";
      countryCodeController.text = _userModel.countryCode?.toString() ?? "+91";
    }
  }

  // Image handling
  Future<void> pickFile({required ImageSource source}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70, // Reduce image quality for faster upload
        maxWidth: 800, // Limit image size
        maxHeight: 800, // Add maxHeight for consistency
      );

      if (image != null) {
        Get.back();
        _profileImage = image.path;
        _hasProfileImageChanged = true;
        notifyListeners();
      }
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("${"failed_to_pick".tr} : \n $e");
    }
  }

  // Validation
  bool _validateForm() {
    if (firstNameController.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter the first name".tr);
      return false;
    }

    if (lastNameController.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter the last name".tr);
      return false;
    }

    final email = emailController.text.trim();
    if (email.isEmpty) {
      ShowToastDialog.showToast("Please enter the email".tr);
      return false;
    }

    if (!isValidEmail(email)) {
      ShowToastDialog.showToast("Invalid email format".tr);
      return false;
    }

    return true;
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Debounced save to prevent rapid clicks
  Future<void> saveData(BuildContext context) async {
    if (_isSaving) return; // Prevent multiple saves

    // Debounce check
    final now = DateTime.now();
    if (_lastSaveTime != null &&
        now.difference(_lastSaveTime!).inMilliseconds < _saveDebounceMs) {
      ShowToastDialog.showToast("Please wait before saving again".tr);
      return;
    }

    if (!_validateForm()) return;

    // Check if any changes were made
    if (!_hasChanges()) {
      ShowToastDialog.showToast("No changes to save".tr);
      Get.back();
      return;
    }

    _lastSaveTime = now;

    ShowToastDialog.showLoader("Please wait".tr);

    _isSaving = true;
    notifyListeners();

    try {
      await _performSave();

      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Profile updated successfully".tr);

      // Return result to trigger refresh in parent
      Get.back(result: true);
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Failed to update profile".tr);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  bool _hasChanges() {
    // Check if any field has changed from original values
    if (_hasProfileImageChanged) return true;

    if (firstNameController.text != (_userModel.firstName ?? "")) return true;
    if (lastNameController.text != (_userModel.lastName ?? "")) return true;
    if (emailController.text != (_userModel.email ?? "")) return true;
    if (phoneNumberController.text != (_userModel.phoneNumber ?? ""))
      return true;

    return false;
  }

  Future<void> _performSave() async {
    // Update local model
    _userModel.firstName = firstNameController.text.trim();
    _userModel.lastName = lastNameController.text.trim();
    _userModel.email = emailController.text.trim();
    _userModel.phoneNumber = phoneNumberController.text.trim();
    _userModel.countryCode = countryCodeController.text.trim();

    // Handle image upload only if changed
    if (_hasProfileImageChanged && _profileImage.isNotEmpty) {
      if (!Constant().hasValidUrl(_profileImage)) {
        final customerId = await _getCustomerId();
        if (customerId == null) {
          throw Exception('Invalid customer id');
        }

        final uploadedUrl = await EditProfileProvider.uploadProfilePic(
          userId: customerId,
          imageFile: File(_profileImage),
          existingProfilePicUrl: _userModel.profilePictureURL,
        );
        if (uploadedUrl == null || uploadedUrl.isEmpty) {
          throw Exception('Profile picture upload failed');
        }
        _userModel.profilePictureURL = uploadedUrl;
        _profileImage = uploadedUrl;

        final picUpdated = await EditProfileProvider.updateCustomerProfilePic(
          userModel: _userModel,
        );
        if (!picUpdated) {
          throw Exception('Profile picture update failed');
        }
      } else {
        _userModel.profilePictureURL = _profileImage;
      }
      _hasProfileImageChanged = false;
    }

    final success = await EditProfileProvider.updateUserStatic(
      _userModel,
      customerStatusId: _customerStatusId,
      referralCode: _referralCode,
    );

    if (success) {
      Constant.userModel = _userModel;
      await SqlStorageConst.storeUserData(_userModel);
      notifyListeners();
    } else {
      throw Exception('Update failed');
    }
  }

  // Instance method for internal use
  Future<bool> updateUserInstance(UserModel userModel) async {
    return await EditProfileProvider.updateUserStatic(userModel);
  }

  static Future<String?> uploadProfilePic({
    required int userId,
    required File imageFile,
    String? existingProfilePicUrl,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConst.outletBaseUrl}driver/saveOrUpdateProfilePic'),
      );

      final authHeaders = await getHeaders();
      if (authHeaders['Authorization'] != null) {
        request.headers['Authorization'] = authHeaders['Authorization']!;
      }
      request.headers['accept'] = '*/*';

      request.fields['userId'] = userId.toString();
      request.fields['profilePicUrl'] = existingProfilePicUrl ?? '';
      request.fields['userType'] = 'customer';

      final multipartFile = await http.MultipartFile.fromPath(
        'profilePicFile',
        imageFile.path,
        filename: imageFile.path.split('/').last,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print(
        '[EDIT_PROFILE] uploadProfilePic: ${response.statusCode} ${response.body}',
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        return null;
      }

      return _extractProfilePicUrl(response.body);
    } catch (error) {
      print('[EDIT_PROFILE] uploadProfilePic error: $error');
      return null;
    }
  }

  static String? _extractProfilePicUrl(String responseBody) {
    try {
      final responseData = jsonDecode(responseBody);
      if (responseData is! Map<String, dynamic>) return null;

      final data = responseData['data'];
      if (data is Map<String, dynamic>) {
        return data['profilePicUrl']?.toString() ??
            data['profilePictureURL']?.toString();
      }
      if (data is String && data.isNotEmpty) {
        return data;
      }

      return responseData['profilePicUrl']?.toString() ??
          responseData['profilePictureURL']?.toString();
    } catch (e) {
      print('[EDIT_PROFILE] Failed to parse profile pic response: $e');
      return null;
    }
  }

  // Static method for external access (kept from original code)
  static Future<bool> updateUserStatic(
    UserModel userModel, {
    int customerStatusId = 1,
    String? referralCode,
  }) async {
    try {
      final storedId = await SqlStorageConst.getUserId() ?? userModel.id ?? '';
      final customerId = int.tryParse(storedId);
      if (customerId == null) {
        return false;
      }

      userModel.id = customerId.toString();

      final headers = await getHeaders();
      final body = <String, dynamic>{
        'customerId': customerId,
        'firstName': userModel.firstName ?? '',
        'lastName': userModel.lastName ?? '',
        'email': userModel.email ?? '',
        'phoneNumber': userModel.phoneNumber ?? '',
        'customerStatusId': customerStatusId,
        'referralCode': referralCode,
      };

      print('[EDIT_PROFILE] updateCustomerProfile body: $body');

      final response = await http.put(
        Uri.parse(
          '${AppConst.outletBaseUrl}co/customers/updateCustomerProfile',
        ),
        headers: headers,
        body: jsonEncode(body),
      );

      print(
        '[EDIT_PROFILE] updateCustomerProfile: ${response.statusCode} ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData is Map<String, dynamic> &&
              responseData.containsKey('success') &&
              responseData['success'] != true) {
            return false;
          }
        } catch (_) {
          // Non-JSON success response is acceptable.
        }

        Constant.userModel = userModel;
        await SqlStorageConst.storeUserData(userModel);
        return true;
      }

      return false;
    } catch (error) {
      print('[EDIT_PROFILE] updateUser error: $error');
      return false;
    }
  }

  static Future<bool> updateCustomerProfilePic({
    required UserModel userModel,
  }) async {
    try {
      final storedId = await SqlStorageConst.getUserId() ?? userModel.id ?? '';
      final customerId = int.tryParse(storedId);
      if (customerId == null) {
        return false;
      }

      final headers = await getHeaders();
      final body = <String, dynamic>{
        'firstName': userModel.firstName ?? '',
        'lastName': userModel.lastName ?? '',
        'email': userModel.email ?? '',
        'phoneNumber': userModel.phoneNumber ?? '',
        'customerId': customerId,
        'profilePicUrl': userModel.profilePictureURL ?? '',
      };

      final response = await http.put(
        Uri.parse(
          '${AppConst.outletBaseUrl}co/customers/updateCustomerProfilePic',
        ),
        headers: headers,
        body: jsonEncode(body),
      );

      print(
        '[EDIT_PROFILE] updateCustomerProfilePic: ${response.statusCode} ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isNotEmpty) {
          final updatedUrl = _extractProfilePicUrl(response.body);
          if (updatedUrl != null && updatedUrl.isNotEmpty) {
            userModel.profilePictureURL = updatedUrl;
          }
        }
        Constant.userModel = userModel;
        return true;
      }

      return false;
    } catch (error) {
      print('[EDIT_PROFILE] updateCustomerProfilePic error: $error');
      return false;
    }
  }

  // Clean up controllers
  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    countryCodeController.dispose();
    super.dispose();
  }
}
