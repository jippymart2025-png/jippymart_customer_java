import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippymart_customer/app/chat_screens/ChatVideoContainer.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/AttributesModel.dart';
import 'package:jippymart_customer/models/advertisement_model.dart';
import 'package:jippymart_customer/models/conversation_model.dart';
import 'package:jippymart_customer/models/email_template_model.dart';
import 'package:jippymart_customer/models/inbox_model.dart';
import 'package:jippymart_customer/models/notification_model.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/models/payment_model/cod_setting_model.dart';
import 'package:jippymart_customer/models/payment_model/razorpay_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/rating_model.dart';
import 'package:jippymart_customer/models/review_attribute_model.dart';
import 'package:jippymart_customer/models/tax_model.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import 'package:http/http.dart' as http;

class FireStoreUtils {
  // static FirebaseFirestore fireStore = FirebaseFirestore.instance;
  static final bool _isDatabaseHealthy = true;
  static String?
  backendUserId; // Set this from LoginController after OTP verification
  static bool get isDatabaseHealthy => _isDatabaseHealthy;

  // Add this method to your FireStoreUtils class
  static Future<Map<String, dynamic>> getChatMessages({
    required String orderId,
    required String chatType,
    required int page,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConst.baseUrl}chat/$orderId/messages?chat_type=$chatType&page=$page',
        ),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  static Future getPaymentSettingsData() async {
    try {
      // Get RazorPay settings from API
      final razorpayResponse = await http.get(
        Uri.parse('${AppConst.baseUrl}firestore/settings/razorpay'),
        headers: await getHeaders(),
      );

      print("getPaymentSettingsData ${razorpayResponse.body} ");
      if (razorpayResponse.statusCode == 200) {
        final responseData = jsonDecode(razorpayResponse.body);
        if (responseData['success'] == true) {
          final razorpayData = responseData['data']['fields'];
          RazorPayModel razorPayModel = RazorPayModel.fromJson(razorpayData);
          await Preferences.setString(
            Preferences.razorpaySettings,
            jsonEncode(razorPayModel.toJson()),
          );
        }
      }

      final codResponse = await http.get(
        Uri.parse('${AppConst.baseUrl}firestore/settings/cod'),
        headers: await getHeaders(),
      );

      if (codResponse.statusCode == 200) {
        final responseData = jsonDecode(codResponse.body);
        if (responseData['success'] == true) {
          final codData = responseData['data']['fields'];
          CodSettingModel codSettingModel = CodSettingModel.fromJson(codData);
          await Preferences.setString(
            Preferences.codSettings,
            jsonEncode(codSettingModel.toJson()),
          );
        }
      }
    } catch (e) {
      print('Error fetching payment settings: $e');
      // Handle error appropriately
    }
  }

  static Future<VendorModel?> getVendorById(String vendorId) async {
    VendorModel? vendorModel;
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}restaurants/$vendorId'),
        headers: await getHeaders(),
      );
      dev.log("getVendorById ${response.body}  ");
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          vendorModel = VendorModel.fromJson(jsonResponse['data']);
        }
      } else {
        return null;
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      return null;
    }
    return vendorModel;
  }

  StreamController<List<VendorModel>>? getNearestVendorController;

  Stream<List<VendorModel>> getAllNearestRestaurant({bool? isDining}) async* {
    try {
      getNearestVendorController =
          StreamController<List<VendorModel>>.broadcast();
      List<VendorModel> vendorList = [];
      if (Constant.selectedZone == null) {
        getNearestVendorController!.sink.add([]);
        yield* getNearestVendorController!.stream;
        return;
      }
      // **REPLACED FIREBASE WITH API CALL**
      try {
        final response = await http.get(
          Uri.parse(
            '${AppConst.baseUrl}restaurants/by-zone/${Constant.selectedZone!.id}',
          ),
          headers: await getHeaders(),
        );
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);

          if (responseData['success'] == true) {
            final List<dynamic> restaurantData = responseData['data'];

            // Filter restaurants based on distance from user location
            for (var restaurant in restaurantData) {
              try {
                VendorModel vendorModel = VendorModel.fromJson(restaurant);

                // Calculate distance between user and restaurant
                double distance = _calculateDistance(
                  Constant.selectedLocation.location!.latitude ?? 0.0,
                  Constant.selectedLocation.location!.longitude ?? 0.0,
                  vendorModel.latitude ?? 0.0,
                  vendorModel.longitude ?? 0.0,
                );

                // Filter by radius
                if (distance <= double.parse(Constant.radius)) {
                  // Apply subscription filtering logic
                  if ((Constant.isSubscriptionModelApplied == true ||
                          Constant.adminCommission?.isEnabled == true) &&
                      vendorModel.subscriptionPlan != null) {
                    if (vendorModel.subscriptionTotalOrders == "-1") {
                      vendorList.add(vendorModel);
                      print(
                        '[DEBUG] Restaurant added (unlimited subscription): ${vendorModel.title}',
                      );
                    } else {
                      if ((vendorModel.subscriptionExpiryDate != null &&
                              vendorModel.subscriptionExpiryDate!
                                      .toDate()
                                      .isBefore(DateTime.now()) ==
                                  false) ||
                          vendorModel.subscriptionPlan?.expiryDay == "-1") {
                        if (vendorModel.subscriptionTotalOrders != '0') {
                          // **FOOD CATEGORY FILTERING: Exclude mart vendors**
                          if (vendorModel.vType == null ||
                              vendorModel.vType!.toLowerCase() != 'mart') {
                            vendorList.add(vendorModel);
                            print(
                              '[DEBUG] Restaurant added (valid subscription): ${vendorModel.title}',
                            );
                          } else {
                            print(
                              '[DEBUG] Mart vendor excluded from FOOD category: ${vendorModel.title}',
                            );
                          }
                        } else {
                          print(
                            '[DEBUG] Restaurant filtered out (subscription orders exhausted): ${vendorModel.title}',
                          );
                        }
                      } else {
                        print(
                          '[DEBUG] Restaurant filtered out (subscription expired): ${vendorModel.title}',
                        );
                      }
                    }
                  } else {
                    // **FOOD CATEGORY FILTERING: Exclude mart vendors**
                    if (vendorModel.vType == null ||
                        vendorModel.vType!.toLowerCase() != 'mart') {
                      vendorList.add(vendorModel);
                      print(
                        '[DEBUG] Restaurant added (no subscription filter): ${vendorModel.title}',
                      );
                    } else {
                      print(
                        '[DEBUG] Mart vendor excluded from FOOD category: ${vendorModel.title}',
                      );
                    }
                  }
                } else {
                  print(
                    '[DEBUG] Restaurant filtered out (distance $distance km > radius ${Constant.radius} km): ${vendorModel.title}',
                  );
                }
              } catch (e) {
                print('[DEBUG] Error parsing restaurant data: $e');
              }
            }

            print(
              '[DEBUG] getAllNearestRestaurant: Final result: ${vendorList.length} restaurants after filtering',
            );
            getNearestVendorController!.sink.add(vendorList);
          } else {
            print('[DEBUG] API returned success: false');
            getNearestVendorController!.sink.add([]);
          }
        } else {
          print('[DEBUG] API call failed with status: ${response.statusCode}');
          getNearestVendorController!.sink.add([]);
        }
      } catch (e) {
        print('[DEBUG] API call error: $e');
        getNearestVendorController!.sink.add([]);
      }

      yield* getNearestVendorController!.stream;
    } catch (e) {
      print('[DEBUG] getAllNearestRestaurant: Error in main try block: $e');

      // **FALLBACK: Try to load restaurants without zone filtering if main query fails**
      try {
        print(
          '[DEBUG] getAllNearestRestaurant: Attempting fallback query without zone filtering',
        );
        List<VendorModel> fallbackVendorList = [];

        // Fallback API call - you might need to adjust this endpoint
        final fallbackResponse = await http.get(
          Uri.parse('${AppConst.baseUrl}restaurants'),
          // Adjust endpoint as needed
          headers: await getHeaders(),
        );

        if (fallbackResponse.statusCode == 200) {
          final Map<String, dynamic> fallbackData = json.decode(
            fallbackResponse.body,
          );

          if (fallbackData['success'] == true) {
            final List<dynamic> fallbackRestaurants = fallbackData['data'];
            print(
              '[DEBUG] getAllNearestRestaurant: Fallback query found ${fallbackRestaurants.length} restaurants',
            );

            for (var restaurant in fallbackRestaurants) {
              try {
                final data = restaurant;
                VendorModel vendorModel = VendorModel.fromJson(data);

                // **FOOD CATEGORY FILTERING: Exclude mart vendors from fallback query too**
                if (vendorModel.vType == null ||
                    vendorModel.vType!.toLowerCase() != 'mart') {
                  fallbackVendorList.add(vendorModel);
                } else {
                  print(
                    '[DEBUG] Mart vendor excluded from fallback FOOD category: ${vendorModel.title}',
                  );
                }
              } catch (e) {
                print('[DEBUG] Error parsing fallback restaurant data: $e');
              }
            }

            print(
              '[DEBUG] getAllNearestRestaurant: Fallback result: ${fallbackVendorList.length} restaurants',
            );
            getNearestVendorController!.sink.add(fallbackVendorList);
            yield* getNearestVendorController!.stream;
          }
        }
      } catch (fallbackError) {
        print(
          '[DEBUG] getAllNearestRestaurant: Fallback query also failed: $fallbackError',
        );
        getNearestVendorController!.sink.add([]);
        yield* getNearestVendorController!.stream;
      }
    }
  }

  // Helper function to calculate distance between two coordinates
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Radius of the earth in km

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c; // Distance in km

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Stream method to get mart bottom banners (position: "bottom") - Lazy loading
  // Stream method to get mart bottom banners (position: "bottom") - Lazy loading

  static final Map<String, _CachedProduct> _productCache = {};
  static final Map<String, Future<ProductModel?>> _pendingProductRequests = {};
  static const Duration _productCacheDuration = Duration(minutes: 5);

  static ProductModel? _getCachedProduct(String productId) {
    final cachedEntry = _productCache[productId];
    if (cachedEntry == null) return null;

    final isExpired =
        DateTime.now().difference(cachedEntry.fetchedAt) >
        _productCacheDuration;
    if (isExpired) {
      _productCache.remove(productId);
      return null;
    }
    return cachedEntry.product;
  }

  static Future<ProductModel?> getProductById(
    String productId, {
    bool forceRefresh = false,
  }) async {
    if (productId.isEmpty || productId == 'null' || productId.trim().isEmpty) {
      print('[PRODUCT_API] Invalid product ID provided: "$productId"');
      return null;
    }
    if (!forceRefresh) {
      final cachedProduct = _getCachedProduct(productId);
      if (cachedProduct != null) {
        return cachedProduct;
      }
      final pendingRequest = _pendingProductRequests[productId];
      if (pendingRequest != null) {
        return pendingRequest;
      }
    }
    final request = _fetchProductFromApi(productId);
    _pendingProductRequests[productId] = request;
    try {
      final productModel = await request;
      if (productModel != null) {
        _productCache[productId] = _CachedProduct(product: productModel);
      }
      return productModel;
    } finally {
      _pendingProductRequests.remove(productId);
    }
  }

  static Future<ProductModel?> _fetchProductFromApi(String productId) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);
    const timeoutDuration = Duration(seconds: 10);
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .get(
              Uri.parse('${AppConst.baseUrl}products/$productId'),
              headers: await getHeaders(),
            )
            .timeout(timeoutDuration);
        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
            return ProductModel.fromJson(jsonResponse['data']);
          }
        } else if (response.statusCode == 429) {
          if (attempt < maxRetries) {
            print(
              '[PRODUCT_API] Rate limited (429), retrying in ${retryDelay.inSeconds}s (attempt $attempt/$maxRetries)',
            );
            await Future.delayed(retryDelay * attempt); // Exponential backoff
            continue;
          } else {
            print(
              '[PRODUCT_API] Rate limited (429) after $maxRetries attempts, productId=$productId',
            );
          }
        } else {
          print(
            '[PRODUCT_API] getProductById failed '
            'status=${response.statusCode} productId=$productId',
          );
          // Don't retry for non-429 errors
          return null;
        }
      } on TimeoutException {
        print(
          '[PRODUCT_API] Timeout fetching product $productId (attempt $attempt/$maxRetries)',
        );
        if (attempt < maxRetries) {
          await Future.delayed(retryDelay);
          continue;
        }
      } catch (e, s) {
        print('[PRODUCT_API] Error fetching product $productId: $e');
        if (attempt < maxRetries) {
          await Future.delayed(retryDelay);
          continue;
        }
        print(s);
      }
    }
    return null;
  }

  static Future<List<AttributesModel>> getAttributes() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}vendor/attributes'),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          List<AttributesModel> attributeList = [];

          for (var element in responseData['data']) {
            AttributesModel attributeModel = AttributesModel.fromJson(element);
            attributeList.add(attributeModel);
          }
          return attributeList;
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load attributes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching attributes: $e');
    }
  }

  static Future<DeliveryCharge?> getDeliveryCharge() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}settings/delivery-charge'),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return DeliveryCharge.fromJson(jsonResponse['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<TaxModel>?> getTaxList() async {
    print(" getTaxList ");
    List<TaxModel> taxList = [];
    if (Constant.selectedLocation.location?.latitude == null ||
        Constant.selectedLocation.location?.longitude == null) {
      print('[API_UTILS] Location not available for tax calculation');
      return taxList;
    }
    try {
      List<Placemark> placeMarks = await placemarkFromCoordinates(
        Constant.selectedLocation.location!.latitude!,
        Constant.selectedLocation.location!.longitude!,
      );

      if (placeMarks.isEmpty) {
        print('[API_UTILS] No placemarks found for coordinates');
        return taxList;
      }
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}settings/tax'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> taxData = responseData['data'];
          // Filter taxes by country and enable status
          for (var element in taxData) {
            TaxModel taxModel = TaxModel.fromJson(element);
            // Apply filters manually (previously done in Firebase query)
            if (taxModel.country == placeMarks.first.country &&
                taxModel.enable == true) {
              taxList.add(taxModel);
            }
          }
        } else {
          print('[API_UTILS] API returned unsuccessful response');
        }
      } else {
        print('[API_UTILS] HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('[API_UTILS] Error getting tax list: $e');
    }
    return taxList;
  }

  static Future<bool> setProduct(ProductModel orderModel) async {
    try {
      final url = "${AppConst.baseUrl}firestore/setProduct?id=${orderModel.id}";
      final body = jsonEncode(orderModel.toJson());
      final response = await http.post(
        Uri.parse(url),
        headers: await getHeaders(),
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("❌ Failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error: $e");
      return false;
    }
  }

  static Future<List<OrderModel>> getAllOrder() async {
    List<OrderModel> list = [];
    final currentUid = await SqlStorageConst.getFirebaseId();
    print(" userId   $currentUid  ");
    if (kDebugMode) {
      print('Current UID: $currentUid');
    }
    if (currentUid == null) {
      if (kDebugMode) {
        print('No current UID found, returning empty list');
      }
      return list;
    }
    // try {
    final Map<String, String> queryParams = {
      'author_id': currentUid,
      // 'filter': 'cancelled',
      // 'filter': 'rejected',
      // 'filter': 'pending',
      // 'filter': 'preparing',
      // 'filter': 'completed',
    };
    final uri = Uri.parse(
      '${AppConst.baseUrl}firestore/orders',
    ).replace(queryParameters: queryParams);
    if (kDebugMode) {
      print('API URL: $uri');
    }
    final response = await http.get(uri, headers: await getHeaders());
    if (kDebugMode) {
      print('API Response Status: ${response.statusCode}');
      dev.log('getAllOrder ${response.body}');
    }
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['success'] == true) {
        final List<dynamic> ordersData = responseData['data']['orders'];
        if (kDebugMode) {
          print('Found ${ordersData.length} orders in API response');
        }
        for (var orderData in ordersData) {
          OrderModel orderModel = OrderModel.fromJson(orderData);
          list.add(orderModel);
          if (kDebugMode) {
            print('Successfully parsed order: ${orderModel.id}');
          }
          // } catch (e) {
          //   if (kDebugMode) {
          //     print('Error parsing order data: $e');
          //     print('Problematic order data: $orderData');
          //   }
          // }
        }
        // Sort by createdAt in descending order (since API might not guarantee order)
        list = list.where((order) => order.createdAt != null).toList();
        list.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
      } else {
        if (kDebugMode) {
          print('API returned success: false');
        }
      }
    } else {
      if (kDebugMode) {
        print('API call failed with status: ${response.statusCode}');
      }
    }
    // } catch (error) {
    //   if (kDebugMode) {
    //     print('Error in getAllOrder API call: $error');
    //   }
    // }

    if (kDebugMode) {
      print('Returning ${list.length} orders');
    }

    return list;
  }

  static Future<EmailTemplateModel?> getEmailTemplates(String type) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}firestore/email-templates/$type'),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return EmailTemplateModel.fromJson(responseData['data']);
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception(
          'Failed to load email template: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching email template: $e');
      return null;
    }
  }

  static Future<NotificationModel?> getNotificationContent(String type) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}firestore/notifications/$type'),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return NotificationModel.fromJson(jsonResponse['data']);
        } else {
          return NotificationModel(
            id: "",
            message: "Notification setup is pending",
            subject: "setup notification",
            type: "",
          );
        }
      } else {
        // Handle HTTP error
        return NotificationModel(
          id: "",
          message: "Failed to fetch notification: ${response.statusCode}",
          subject: "Error",
          type: "",
        );
      }
    } catch (e) {
      // Handle network/parsing errors
      return NotificationModel(
        id: "",
        message: "Network error: $e",
        subject: "Error",
        type: "",
      );
    }
  }

  static Future<InboxModel> addDriverInbox(InboxModel inboxModel) async {
    try {
      // Your API base URL
      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        "order_id": inboxModel.orderId,
        "restaurant_id": inboxModel.restaurantId,
        "restaurant_name": inboxModel.restaurantName,
        "restaurant_profile_image": inboxModel.restaurantProfileImage,
        "customer_id": inboxModel.customerId,
        "customer_name": inboxModel.customerName,
        "customer_profile_image": inboxModel.customerProfileImage,
        "last_sender_id": inboxModel.lastSenderId,
        "last_message": inboxModel.lastMessage,
        "chat_type": inboxModel.chatType,
        "created_at": inboxModel.createdAt?.toString(),
      };
      // Remove null values from the request body
      requestBody.removeWhere((key, value) => value == null);
      // Make the POST request
      final response = await http.post(
        Uri.parse('${AppConst.baseUrl}mobile/chat/driver/inbox'),
        headers: await getHeaders(),
        body: json.encode(requestBody),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return inboxModel;
      } else {
        throw Exception(
          'Failed to add driver inbox: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      // Handle network errors or other exceptions
      throw Exception('Failed to add driver inbox: $e');
    }
  }

  static Future<ConversationModel> addDriverChat(
    ConversationModel conversationModel,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConst.baseUrl}mobile/chat/driver/messages'),
        headers: await getHeaders(),
        body: jsonEncode({
          "chat_id": conversationModel.id,
          "order_id": conversationModel.orderId,
          "sender_id": conversationModel.senderId,
          "receiver_id": conversationModel.receiverId,
          "message_type": conversationModel.messageType,
          "message": conversationModel.message,
          "created_at": conversationModel.createdAt?.toString(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(
          '[API] addDriverChat SUCCESS: orderId=${conversationModel.orderId}, messageId=${conversationModel.id}',
        );
        return conversationModel;
      } else {
        debugPrint(
          '[API] addDriverChat ERROR: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to send driver message: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[API] addDriverChat ERROR: $e');
      rethrow;
    }
  }

  static Future<void> addRestaurantInbox(InboxModel inboxModel) async {
    try {
      // Your API base URL

      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        "order_id": inboxModel.orderId,
        "restaurant_id": inboxModel.restaurantId,
        "restaurant_name": inboxModel.restaurantName,
        "restaurant_profile_image": inboxModel.restaurantProfileImage,
        "customer_id": inboxModel.customerId,
        "customer_name": inboxModel.customerName,
        "customer_profile_image": inboxModel.customerProfileImage,
        "last_sender_id": inboxModel.lastSenderId,
        "last_message": inboxModel.lastMessage,
        "chat_type": "restaurant", // Default to "restaurant" as per API spec
        "created_at": inboxModel.createdAt.toString(),
      };

      // Remove null values from the request body
      requestBody.removeWhere((key, value) => value == null);

      // Make the POST request
      final response = await http.post(
        Uri.parse('${AppConst.baseUrl}mobile/chat/restaurant/inbox'),
        headers: await getHeaders(),
        body: json.encode(requestBody),
      );

      // Check if the request was successful
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(
          '[API] addRestaurantInbox SUCCESS: orderId=${inboxModel.orderId}',
        );
      } else {
        // Handle error response
        debugPrint(
          '[API] addRestaurantInbox ERROR: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Failed to add restaurant inbox: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[API] addRestaurantInbox ERROR: $e');
      // Re-throw the exception to maintain the same error behavior
      throw e;
    }
  }

  static Future<void> addRestaurantChat(
    ConversationModel conversationModel,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConst.baseUrl}mobile/chat/restaurant/messages'),
        headers: await getHeaders(),
        body: jsonEncode({
          "chat_id": conversationModel.id,
          "order_id": conversationModel.orderId,
          "sender_id": conversationModel.senderId,
          "receiver_id": conversationModel.receiverId,
          "message_type": conversationModel.messageType,
          "message": conversationModel.message,
          "url": conversationModel.url,
          "video_thumbnail": conversationModel.videoThumbnail,
          "created_at": conversationModel.createdAt?.toString(),
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(
          '[API] addRestaurantChat SUCCESS: orderId=${conversationModel.orderId}, messageId=${conversationModel.id}',
        );
      } else {
        debugPrint(
          '[API] addRestaurantChat ERROR: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[API] addRestaurantChat ERROR: $e');
      rethrow; // Re-throw to handle the error in the calling function
    }
  }

  static Future<Url> uploadChatImageToFireStorage(
    File image,
    BuildContext context,
  ) async {
    ShowToastDialog.showLoader("Please wait".tr);
    var uniqueID = const Uuid().v4();
    Reference upload = FirebaseStorage.instance.ref().child(
      'images/$uniqueID.png',
    );
    UploadTask uploadTask = upload.putFile(image);
    var storageRef = (await uploadTask.whenComplete(() {})).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    var metaData = await storageRef.getMetadata();
    ShowToastDialog.closeLoader();
    return Url(
      mime: metaData.contentType ?? 'image',
      url: downloadUrl.toString(),
    );
  }

  static Future<ChatVideoContainer?> uploadChatVideoToFireStorage(
    BuildContext context,
    File video,
  ) async {
    try {
      ShowToastDialog.showLoader("Uploading video...");
      final String uniqueID = const Uuid().v4();
      final Reference videoRef = FirebaseStorage.instance.ref(
        'videos/$uniqueID.mp4',
      );
      final UploadTask uploadTask = videoRef.putFile(
        video,
        SettableMetadata(contentType: 'video/mp4'),
      );
      await uploadTask;
      final String videoUrl = await videoRef.getDownloadURL();
      ShowToastDialog.showLoader("Generating thumbnail...");
      File thumbnail = await VideoCompress.getFileThumbnail(
        video.path,
        quality: 75, // 0 - 100
        position: -1, // Get the first frame
      );

      final String thumbnailID = const Uuid().v4();
      final Reference thumbnailRef = FirebaseStorage.instance.ref(
        'thumbnails/$thumbnailID.jpg',
      );
      final UploadTask thumbnailUploadTask = thumbnailRef.putData(
        thumbnail.readAsBytesSync(),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      await thumbnailUploadTask;
      final String thumbnailUrl = await thumbnailRef.getDownloadURL();
      var metaData = await thumbnailRef.getMetadata();
      ShowToastDialog.closeLoader();
      return ChatVideoContainer(
        videoUrl: Url(
          url: videoUrl.toString(),
          mime: metaData.contentType ?? 'video',
          videoThumbnail: thumbnailUrl,
        ),
        thumbnailUrl: thumbnailUrl,
      );
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error: ${e.toString()}");
      return null;
    }
  }

  static Future<List<RatingModel>> getVendorReviews(String vendorId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}vendor/$vendorId/reviews'),
        headers: await getHeaders(),
      );
      print("getVendorReviews ${AppConst.baseUrl}vendor/$vendorId/reviews)}");
      print("getVendorReviews " + response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          List<RatingModel> ratingList = [];
          for (var element in data) {
            RatingModel ratingModel = RatingModel.fromJson(element);
            ratingList.add(ratingModel);
          }

          return ratingList;
        } else {
          throw Exception('Failed to load reviews: ${responseData['message']}');
        }
      } else {
        throw Exception(
          'Failed to load reviews. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching reviews: $e');
    }
  }

  static Future<RatingModel?> getOrderReviewsByID(
    String orderId,
    String productID,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConst.baseUrl}reviews/order?orderid=$orderId&productId=$productID',
        ),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return RatingModel.fromJson(responseData['data']);
        }
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      print('Error fetching reviews: $error');
    }
    return null;
  }

  static Future<VendorCategoryModel?> getVendorCategoryByCategoryId(
    String categoryId,
  ) async {
    VendorCategoryModel? vendorCategoryModel;
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}firestore/vendor-categories/$categoryId'),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          vendorCategoryModel = VendorCategoryModel.fromJson(
            jsonResponse['data'],
          );
        }
      }
    } catch (e) {
      return null;
    }
    return vendorCategoryModel;
  }

  static Future<ReviewAttributeModel?> getVendorReviewAttribute(
    String attributeId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}review-attributes/$attributeId'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return ReviewAttributeModel.fromJson(jsonResponse['data']);
        } else {
          return null;
        }
      } else {
        // Handle different status codes
        print('API Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching review attribute: $e');
      return null;
    }
  }

  static Future<bool?> setRatingModel(RatingModel ratingModel) async {
    bool isAdded = false;
    try {
      final response = await http.post(
        Uri.parse('${AppConst.baseUrl}firestore/ratings'),
        headers: await getHeaders(),
        body: jsonEncode(ratingModel.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        isAdded = true;
      } else {
        isAdded = false;
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      isAdded = false;
      print('Exception: $error');
    }

    return isAdded;
  }

  // static Future<VendorModel?> updateVendor(VendorModel vendor) async {
  //   return await fireStore
  //       .collection(CollectionName.vendors)
  //       .doc(vendor.id)
  //       .set(vendor.toJson())
  //       .then((document) {
  //         return vendor;
  //       });
  // }

  static Future<List<AdvertisementModel>> getAllAdvertisement() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}firestore/advertisements/active'),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> advertisementsData =
              responseData['data']['advertisements'];

          List<AdvertisementModel> advertisementList = [];

          for (var element in advertisementsData) {
            try {
              AdvertisementModel advertisementModel =
                  AdvertisementModel.fromJson(element);

              // Apply the same filtering logic
              if (advertisementModel.isPaused == null ||
                  advertisementModel.isPaused == false) {
                advertisementList.add(advertisementModel);
              }
            } catch (e) {
              // Handle individual advertisement parsing errors
              print('Error parsing advertisement: $e');
            }
          }

          return advertisementList;
        } else {
          throw Exception(
            'API returned unsuccessful response: ${responseData['message']}',
          );
        }
      } else {
        throw Exception(
          'HTTP error ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (error) {
      print('Error fetching advertisements: $error');
      return []; // Return empty list on error, similar to your catchError
    }
  }

  /// **ULTRA-FAST PROMOTIONAL DATA FETCHING WITH API**
  static Future<List<Map<String, dynamic>>> fetchActivePromotions({
    required String restaurantId,
    required String productId,
  }) async {
    try {
      // Build the API URL
      final String apiUrl =
          '${AppConst.baseUrl}firestore/promotions/by-product?'
          'product_id=$productId&'
          'restaurant_id=$restaurantId';
      print('[DEBUG] API Endpoint: $apiUrl');
      // Make API call
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final promotionData = responseData['data'] as Map<String, dynamic>;
          // Convert API response to match your existing data structure
          final Map<String, dynamic> processedPromotion = {
            ...promotionData,
            'isAvailable': promotionData['isAvailable'] == 1 ? true : false,
            'start_time': _parseTimestamp(promotionData['start_time']),
            'end_time': _parseTimestamp(promotionData['end_time']),
          };
          // Check if promotion is currently active based on time
          final startTime = processedPromotion['start_time'] as Timestamp?;
          final endTime = processedPromotion['end_time'] as Timestamp?;

          bool isActive = processedPromotion['isAvailable'] == true;

          if (startTime != null && endTime != null) {
            isActive =
                isActive &&
                startTime.compareTo(Timestamp.now()) <= 0 &&
                endTime.compareTo(Timestamp.now()) >= 0;
          }
          print('[DEBUG] Promotion active status: $isActive');
          print('[DEBUG] ===== ULTRA-FAST API FETCH COMPLETE =====');

          return isActive ? [processedPromotion] : [];
        } else {
          print('[DEBUG] API returned unsuccessful response');
          return [];
        }
      } else {
        print('[DEBUG] API Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[DEBUG] ERROR in ultra-fast API fetch: $e');
      return [];
    }
  }

  /// Helper method to parse timestamp strings to Firestore Timestamp
  static Timestamp? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;

    if (timestamp is String) {
      try {
        final dateTime = DateTime.parse(timestamp);
        return Timestamp.fromDate(dateTime);
      } catch (e) {
        print('[DEBUG] Error parsing timestamp: $e');
        return null;
      }
    }

    return null;
  }

  /// Checks if a product is currently a promo item (OPTIMIZED)
  static Future<Map<String, dynamic>?> getActivePromotionForProduct({
    required String productId,
    required String restaurantId,
  }) async {
    final promos = await fetchActivePromotions(
      restaurantId: restaurantId,
      productId: productId,
    );
    final promo = promos.firstWhere(
      (p) =>
          p['product_id'] == productId &&
          p['restaurant_id'] == restaurantId &&
          p['isAvailable'] == true,
      orElse: () => <String, dynamic>{},
    );
    return promo.isNotEmpty ? promo : null;
  }

  static Future<List<ProductModel>> getAllProductsInZone({int? limit}) async {
    try {
      print(
        "🔍 Fetching products from API for zone: ${Constant.selectedZone?.name}",
      );

      // Prepare API parameters
      final Map<String, String> queryParams = {};

      // Add zone_id if selected
      if (Constant.selectedZone != null) {
        queryParams['zone_id'] = Constant.selectedZone!.id.toString();
      }
      // Add limit if provided
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      // Make API call
      final response = await http.get(
        Uri.parse(
          '${AppConst.baseUrl}firestore/search/products',
        ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> productsData = responseData['data']['products'];
          final List<ProductModel> productList = [];

          for (var productData in productsData) {
            try {
              // Use the API JSON factory constructor
              ProductModel product = ProductModel.fromApiJson(productData);
              productList.add(product);
            } catch (e) {
              print('❌ Error parsing product ${productData['id']}: $e');
            }
          }

          print('✅ Loaded ${productList.length} products from API');
          return productList;
        } else {
          print('❌ API returned error: ${responseData['message']}');
          return [];
        }
      } else {
        print('❌ HTTP error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading products from API: $e');
      if (e.toString().contains('OutOfMemoryError')) {
        print(
          '🚨 OutOfMemoryError detected! Returning empty list to prevent crash.',
        );
      }
      return [];
    }
  }

  /// Get all vendors for search indexing - MEMORY OPTIMIZED
  // static Future<List<VendorModel>> getAllVendors({int? limit}) async {
  //   try {
  //     List<VendorModel> vendorList = [];
  //     int safeLimit =
  //         limit ?? 500; // Increased to 500 to match admin panel results
  //     Query query;
  //     if (Constant.selectedZone != null) {
  //       query = FirebaseFirestore.instance
  //           .collection(CollectionName.vendors)
  //           .where('zoneId', isEqualTo: Constant.selectedZone!.id.toString())
  //           .limit(safeLimit);
  //       print(
  //         '🔍 Loading vendors from zone: ${Constant.selectedZone!.name} (${Constant.selectedZone!.id})',
  //       );
  //     } else {
  //       query = FirebaseFirestore.instance
  //           .collection(CollectionName.vendors)
  //           .limit(safeLimit);
  //       print('🔍 No zone selected, loading all vendors');
  //     }
  //     QuerySnapshot querySnapshot = await query.get();
  //     print(
  //       '🔍 Found ${querySnapshot.docs.length} vendors in Firestore (limited to $safeLimit for memory safety)',
  //     );
  //     for (var document in querySnapshot.docs) {
  //       try {
  //         final data = document.data() as Map<String, dynamic>;
  //         VendorModel vendorModel = VendorModel.fromJson(data);
  //         // **FOOD CATEGORY FILTERING: Exclude mart vendors from search**
  //         if (vendorModel.vType == null ||
  //             vendorModel.vType!.toLowerCase() != 'mart') {
  //           vendorList.add(vendorModel);
  //         } else {
  //           print('🔍 Mart vendor excluded from search: ${vendorModel.title}');
  //         }
  //       } catch (e) {
  //         print('❌ Error parsing vendor ${document.id}: $e');
  //       }
  //     }
  //     print('✅ Loaded ${vendorList.length} vendors for search');
  //     return vendorList;
  //   } catch (e) {
  //     print('❌ Error loading all vendors: $e');
  //     if (e.toString().contains('OutOfMemoryError')) {
  //       print(
  //         '🚨 OutOfMemoryError detected! Returning empty list to prevent crash.',
  //       );
  //     }
  //     return [];
  //   }
  // }

  /// Get all products for search indexing - MEMORY OPTIMIZED

  static Future<List<ProductModel>> getAllProducts({
    int? limit,
    int page = 1,
  }) async {
    try {
      List<ProductModel> productList = [];

      final String baseUrl =
          '${AppConst.baseUrl}products'; // Replace with your actual base URL
      final Map<String, String> queryParams = {'page': page.toString()};
      final Uri uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      print('🌐 Fetching products from API: $uri');
      // Make API request
      final response = await http
          .get(uri, headers: await getHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> productsJson = responseData['data'];
          final Map<String, dynamic> meta = responseData['meta'];

          print(
            '📊 API Response: Loaded ${productsJson.length} products (Page $page of ${meta['last_page']}, Total: ${meta['total']})',
          );

          // Parse products
          for (var productJson in productsJson) {
            try {
              ProductModel productModel = ProductModel.fromJson(productJson);
              productList.add(productModel);
            } catch (e) {
              print('❌ Error parsing product ${productJson['id']}: $e');
            }
          }

          print(
            '✅ Successfully loaded ${productList.length} products from API',
          );
          return productList;
        } else {
          print('❌ API returned error: ${responseData['message']}');
          return [];
        }
      } else {
        print(
          '❌ HTTP Error: ${response.statusCode} - ${response.reasonPhrase}',
        );
        return [];
      }
    } catch (e) {
      print('❌ Error loading products from API: $e');

      if (e is http.ClientException) {
        print('🌐 Network error: ${e.message}');
      } else if (e is TimeoutException) {
        print('⏰ Request timeout');
      }

      return [];
    }
  }

  /// Get trending searches (can be customized based on your backend)
  static Future<List<String>> getTrendingSearches() async {
    try {
      return [
        "Pizza",
        "Biryani",
        "Burgers",
        "Coffee",
        "Ice Cream",
        "Chinese",
        "Italian",
        "South Indian",
        "Fast Food",
        "Desserts",
        "Chicken",
        "Vegetarian",
        "Spicy",
        "Sweet",
        "Healthy",
      ];
    } catch (e) {
      print('❌ Error loading trending searches: $e');
      return [];
    }
  }
}

class _CachedProduct {
  _CachedProduct({required this.product}) : fetchedAt = DateTime.now();

  final ProductModel product;
  final DateTime fetchedAt;
}
