import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippymart_customer/app/chat_screens/ChatVideoContainer.dart';
import 'package:jippymart_customer/constant/collection_name.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/AttributesModel.dart';
import 'package:jippymart_customer/models/advertisement_model.dart';
import 'package:jippymart_customer/models/conversation_model.dart';
import 'package:jippymart_customer/models/coupon_model.dart';
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
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;
  static final bool _isDatabaseHealthy = true;
  static String?
  backendUserId; // Set this from LoginController after OTP verification
  static bool get isDatabaseHealthy => _isDatabaseHealthy;

  static Future getPaymentSettingsData() async {
    await fireStore
        .collection(CollectionName.settings)
        .doc("razorpaySettings")
        .get()
        .then((value) async {
          if (value.exists) {
            RazorPayModel razorPayModel = RazorPayModel.fromJson(value.data()!);
            await Preferences.setString(
              Preferences.razorpaySettings,
              jsonEncode(razorPayModel.toJson()),
            );
          }
        });
    await fireStore
        .collection(CollectionName.settings)
        .doc("CODSettings")
        .get()
        .then((value) async {
          if (value.exists) {
            CodSettingModel codSettingModel = CodSettingModel.fromJson(
              value.data()!,
            );
            await Preferences.setString(
              Preferences.codSettings,
              jsonEncode(codSettingModel.toJson()),
            );
          }
        });
  }

  static Future<VendorModel?> getVendorById(String vendorId) async {
    VendorModel? vendorModel;
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}restaurants/$vendorId'),
        headers: await getHeaders(),
      );

      print("getVendorById ${response.body}  ");

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          vendorModel = VendorModel.fromJson(jsonResponse['data']);
        }
      } else {
        return null;
      }
    } catch (e) {
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
          headers: {'Content-Type': 'application/json'},
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

  static Future<ProductModel?> getProductById(String productId) async {
    ProductModel? productModel;
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}products/$productId'),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          productModel = ProductModel.fromJson(jsonResponse['data']);
        }
      } else {
        print('API call failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e, s) {
      print('Error fetching product: $e');
      print('Stack trace: $s');
      return null;
    }
    return productModel;
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

      // Make API call instead of Firebase query
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

  static Future<List<CouponModel>> getAllVendorPublicCoupons() async {
    List<CouponModel> coupons = [];

    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}coupons/restaurant'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          for (var element in data) {
            // Filter coupons that are enabled, public, and not expired
            final bool isEnabled = element['isEnabled'] == true;
            final bool isPublic = element['isPublic'] == true;
            final bool isValid = _isCouponValid(element['expiresAt']);

            if (isEnabled && isPublic && isValid) {
              CouponModel couponModel = CouponModel.fromJson(element);
              coupons.add(couponModel);
            }
          }
        }
      } else {
        print('API call failed with status: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching coupons: $error');
    }

    return coupons;
  }

  // Helper method to check if coupon is still valid
  static bool _isCouponValid(dynamic expiresAt) {
    if (expiresAt == null) return true;

    try {
      if (expiresAt is String) {
        final expiryDate = DateTime.parse(expiresAt);
        return expiryDate.isAfter(DateTime.now());
      } else if (expiresAt is Map) {
        // Handle if it comes as a timestamp object
        final timestamp = expiresAt['_seconds'] as int;
        final expiryDate = DateTime.fromMillisecondsSinceEpoch(
          timestamp * 1000,
        );
        return expiryDate.isAfter(DateTime.now());
      }
      return true;
    } catch (e) {
      print('Error parsing expiry date: $e');
      return true; // If we can't parse, assume it's valid
    }
  }

  static Future<bool?> setProduct(ProductModel orderModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.vendorProducts)
        .doc(orderModel.id)
        .set(orderModel.toJson())
        .then((value) {
          isAdded = true;
        })
        .catchError((error) {
          isAdded = false;
        });
    return isAdded;
  }

  static Future<List<OrderModel>> getAllOrder() async {
    List<OrderModel> list = [];
    final currentUid = await SqlStorageConst.getFirebaseId();
    if (kDebugMode) {}
    if (currentUid == null) {
      if (kDebugMode) {}
      return list;
    }

    try {
      final querySnapshot = await fireStore
          .collection(CollectionName.restaurantOrders)
          .where("authorID", isEqualTo: currentUid)
          .orderBy("createdAt", descending: true)
          .get();

      if (kDebugMode) {}

      for (var element in querySnapshot.docs) {
        try {
          OrderModel orderModel = OrderModel.fromJson(element.data());
          list.add(orderModel);
          if (kDebugMode) {}
        } catch (e) {
          if (kDebugMode) {}
        }
      }
    } catch (error) {
      if (kDebugMode) {}
    }

    if (kDebugMode) {}
    return list;
  }

  static Future<EmailTemplateModel?> getEmailTemplates(String type) async {
    EmailTemplateModel? emailTemplateModel;
    await fireStore
        .collection(CollectionName.emailTemplates)
        .where('type', isEqualTo: type)
        .get()
        .then((value) {
          print("------>");
          if (value.docs.isNotEmpty) {
            print(value.docs.first.data());
            emailTemplateModel = EmailTemplateModel.fromJson(
              value.docs.first.data(),
            );
          }
        });
    return emailTemplateModel;
  }

  static Future<NotificationModel?> getNotificationContent(String type) async {
    NotificationModel? notificationModel;
    await fireStore
        .collection(CollectionName.dynamicNotification)
        .where('type', isEqualTo: type)
        .get()
        .then((value) {
          print("------>");
          if (value.docs.isNotEmpty) {
            print(value.docs.first.data());
            notificationModel = NotificationModel.fromJson(
              value.docs.first.data(),
            );
          } else {
            notificationModel = NotificationModel(
              id: "",
              message: "Notification setup is pending",
              subject: "setup notification",
              type: "",
            );
          }
        });
    return notificationModel;
  }

  static Future addDriverInbox(InboxModel inboxModel) async {
    return await fireStore
        .collection("chat_driver")
        .doc(inboxModel.orderId)
        .set(inboxModel.toJson())
        .then((document) {
          return inboxModel;
        });
  }

  static Future addDriverChat(ConversationModel conversationModel) async {
    return await fireStore
        .collection("chat_driver")
        .doc(conversationModel.orderId)
        .collection("thread")
        .doc(conversationModel.id)
        .set(conversationModel.toJson())
        .then((document) {
          return conversationModel;
        });
  }

  static Future addRestaurantInbox(InboxModel inboxModel) async {
    try {
      await fireStore
          .collection("chat_restaurant")
          .doc(inboxModel.orderId)
          .set(inboxModel.toJson());
      debugPrint(
        '[FIRESTORE] addRestaurantInbox SUCCESS: orderId=${inboxModel.orderId}',
      );
    } catch (e) {
      debugPrint('[FIRESTORE] addRestaurantInbox ERROR: $e');
    }
  }

  static Future addRestaurantChat(ConversationModel conversationModel) async {
    try {
      await fireStore
          .collection("chat_restaurant")
          .doc(conversationModel.orderId)
          .collection("thread")
          .doc(conversationModel.id)
          .set(conversationModel.toJson());
      debugPrint(
        '[FIRESTORE] addRestaurantChat SUCCESS: orderId=${conversationModel.orderId}, messageId=${conversationModel.id}',
      );
    } catch (e) {
      debugPrint('[FIRESTORE] addRestaurantChat ERROR: $e');
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
      await fireStore
          .collection(CollectionName.vendorCategories)
          .doc(categoryId)
          .get()
          .then((value) {
            if (value.exists) {
              vendorCategoryModel = VendorCategoryModel.fromJson(value.data()!);
            }
          });
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
    await fireStore
        .collection(CollectionName.foodsReview)
        .doc(ratingModel.id)
        .set(ratingModel.toJson())
        .then((value) {
          isAdded = true;
        })
        .catchError((error) {
          isAdded = false;
        });
    return isAdded;
  }

  static Future<VendorModel?> updateVendor(VendorModel vendor) async {
    return await fireStore
        .collection(CollectionName.vendors)
        .doc(vendor.id)
        .set(vendor.toJson())
        .then((document) {
          return vendor;
        });
  }

  static Future<List<AdvertisementModel>> getAllAdvertisement() async {
    List<AdvertisementModel> advertisementList = [];
    await fireStore
        .collection(CollectionName.advertisements)
        .where('status', isEqualTo: 'approved')
        .where('paymentStatus', isEqualTo: true)
        .where('startDate', isLessThanOrEqualTo: DateTime.now())
        .where('endDate', isGreaterThan: DateTime.now())
        .orderBy('priority', descending: false)
        .get()
        .then((value) {
          for (var element in value.docs) {
            AdvertisementModel advertisementModel = AdvertisementModel.fromJson(
              element.data(),
            );
            if (advertisementModel.isPaused == null ||
                advertisementModel.isPaused == false) {
              advertisementList.add(advertisementModel);
            }
          }
        })
        .catchError((error) {});
    return advertisementList;
  }

  /// **ULTRA-FAST PROMOTIONAL DATA FETCHING WITH LAZY LOADING**
  static Future<List<Map<String, dynamic>>> fetchActivePromotions({
    String? restaurantId,
  }) async {
    final now = Timestamp.now();
    print('[DEBUG] ===== ULTRA-FAST PROMOTIONAL FETCH =====');
    print('[DEBUG] Restaurant filter: $restaurantId');

    try {
      // **ULTRA-FAST: Minimal query with only essential fields**
      Query query = fireStore
          .collection(CollectionName.promotions)
          .where('isAvailable', isEqualTo: true)
          .where('restaurant_id', isEqualTo: restaurantId)
          .limit(
            100,
          ); // **INCREASED: Limit to 100 to show more promotional items**

      final querySnapshot = await query.get();
      print('[DEBUG] Found ${querySnapshot.docs.length} promotions instantly');

      final promotions = <Map<String, dynamic>>[];

      // **PARALLEL PROCESSING: Process all docs simultaneously**
      final futures = querySnapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;

        // **LAZY TIME CHECK: Only check time if needed**
        final startTime = data['start_time'] as Timestamp?;
        final endTime = data['end_time'] as Timestamp?;

        if (startTime != null && endTime != null) {
          final isActive =
              startTime.compareTo(now) <= 0 && endTime.compareTo(now) >= 0;
          return isActive ? data : null;
        }

        return data; // Include if no time constraints
      });

      // **PARALLEL EXECUTION: All time checks happen simultaneously**
      final results = await Future.wait(futures);
      promotions.addAll(
        results.where((item) => item != null).cast<Map<String, dynamic>>(),
      );

      print('[DEBUG] Final active promotions: ${promotions.length} items');
      print('[DEBUG] ===== ULTRA-FAST FETCH COMPLETE =====');

      return promotions;
    } catch (e) {
      print('[DEBUG] ERROR in ultra-fast fetch: $e');
      return [];
    }
  }

  /// Checks if a product is currently a promo item (OPTIMIZED)
  static Future<Map<String, dynamic>?> getActivePromotionForProduct({
    required String productId,
    required String restaurantId,
  }) async {
    final promos = await fetchActivePromotions(restaurantId: restaurantId);
    final promo = promos.firstWhere(
      (p) =>
          p['product_id'] == productId &&
          p['restaurant_id'] == restaurantId &&
          p['isAvailable'] == true,
      orElse: () => <String, dynamic>{},
    );
    return promo.isNotEmpty ? promo : null;
  }

  // **SEARCH UTILITY METHODS**
  static Future<List<ProductModel>> getAllProductsInZone({int? limit}) async {
    try {
      List<ProductModel> productList = [];
      int safeLimit = limit ?? 800;
      // ✅ STEP 1: Get vendors of selected zone
      List<String> allowedVendorIds = [];
      if (Constant.selectedZone != null) {
        print("🔍 Filtering products by zone: ${Constant.selectedZone!.name}");
        QuerySnapshot vendorSnapshot = await FirebaseFirestore.instance
            .collection(CollectionName.vendors)
            .where('zoneId', isEqualTo: Constant.selectedZone!.id.toString())
            .get();
        allowedVendorIds = vendorSnapshot.docs
            .map((e) => e.id.toString())
            .toList();
        print("✅ Found ${allowedVendorIds.length} vendors in this zone");
      }
      Query query = FirebaseFirestore.instance
          .collection(CollectionName.vendorProducts)
          .limit(safeLimit);
      QuerySnapshot querySnapshot = await query.get();
      for (var document in querySnapshot.docs) {
        try {
          final data = document.data() as Map<String, dynamic>;
          ProductModel product = ProductModel.fromJson(data);
          if (Constant.selectedZone != null) {
            if (allowedVendorIds.contains(product.vendorID)) {
              productList.add(product);
            }
          } else {
            productList.add(product);
          }
        } catch (e) {
          print('❌ Error parsing product ${document.id}: $e');
        }
      }

      print('✅ Loaded ${productList.length} zone-filtered products for search');
      return productList;
    } catch (e) {
      print('❌ Error loading all products: $e');
      if (e.toString().contains('OutOfMemoryError')) {
        print(
          '🚨 OutOfMemoryError detected! Returning empty list to prevent crash.',
        );
      }
      return [];
    }
  }

  /// Get all vendors for search indexing - MEMORY OPTIMIZED
  static Future<List<VendorModel>> getAllVendors({int? limit}) async {
    try {
      List<VendorModel> vendorList = [];
      int safeLimit =
          limit ?? 500; // Increased to 500 to match admin panel results
      Query query;
      if (Constant.selectedZone != null) {
        query = FirebaseFirestore.instance
            .collection(CollectionName.vendors)
            .where('zoneId', isEqualTo: Constant.selectedZone!.id.toString())
            .limit(safeLimit);
        print(
          '🔍 Loading vendors from zone: ${Constant.selectedZone!.name} (${Constant.selectedZone!.id})',
        );
      } else {
        query = FirebaseFirestore.instance
            .collection(CollectionName.vendors)
            .limit(safeLimit);
        print('🔍 No zone selected, loading all vendors');
      }
      QuerySnapshot querySnapshot = await query.get();
      print(
        '🔍 Found ${querySnapshot.docs.length} vendors in Firestore (limited to $safeLimit for memory safety)',
      );
      for (var document in querySnapshot.docs) {
        try {
          final data = document.data() as Map<String, dynamic>;
          VendorModel vendorModel = VendorModel.fromJson(data);
          // **FOOD CATEGORY FILTERING: Exclude mart vendors from search**
          if (vendorModel.vType == null ||
              vendorModel.vType!.toLowerCase() != 'mart') {
            vendorList.add(vendorModel);
          } else {
            print('🔍 Mart vendor excluded from search: ${vendorModel.title}');
          }
        } catch (e) {
          print('❌ Error parsing vendor ${document.id}: $e');
        }
      }

      print('✅ Loaded ${vendorList.length} vendors for search');
      return vendorList;
    } catch (e) {
      print('❌ Error loading all vendors: $e');
      if (e.toString().contains('OutOfMemoryError')) {
        print(
          '🚨 OutOfMemoryError detected! Returning empty list to prevent crash.',
        );
      }
      return [];
    }
  }

  /// Get all products for search indexing - MEMORY OPTIMIZED
  static Future<List<ProductModel>> getAllProducts({int? limit}) async {
    try {
      List<ProductModel> productList = [];
      int safeLimit =
          limit ?? 800; // Increased to 800 to match admin panel results
      Query query = FirebaseFirestore.instance
          .collection(CollectionName.vendorProducts)
          .where('publish', isEqualTo: true)
          .limit(safeLimit); // Always limit to prevent memory issues
      QuerySnapshot querySnapshot = await query.get();
      print(
        '📊 Loaded ${querySnapshot.docs.length} published products (limited to $safeLimit for memory safety)',
      );
      for (var document in querySnapshot.docs) {
        try {
          ProductModel productModel = ProductModel.fromJson(
            document.data() as Map<String, dynamic>,
          );
          productList.add(productModel);
        } catch (e) {
          print('❌ Error parsing product ${document.id}: $e');
        }
      }
      print('✅ Loaded ${productList.length} products for search');
      return productList;
    } catch (e) {
      print('❌ Error loading all products: $e');
      if (e.toString().contains('OutOfMemoryError')) {
        print(
          '🚨 OutOfMemoryError detected! Returning empty list to prevent crash.',
        );
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
