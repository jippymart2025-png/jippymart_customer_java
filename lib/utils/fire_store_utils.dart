import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/chat_screens/ChatVideoContainer.dart';
import 'package:jippymart_customer/app/favourite_screens/provider/favorite_provider.dart';
import 'package:jippymart_customer/constant/collection_name.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/AttributesModel.dart';
import 'package:jippymart_customer/models/admin_commission.dart';
import 'package:jippymart_customer/models/advertisement_model.dart';
import 'package:jippymart_customer/models/conversation_model.dart';
import 'package:jippymart_customer/models/coupon_model.dart';
import 'package:jippymart_customer/models/email_template_model.dart';
import 'package:jippymart_customer/models/favourite_item_model.dart';
import 'package:jippymart_customer/models/mart_banner_model.dart';
import 'package:jippymart_customer/models/inbox_model.dart';
import 'package:jippymart_customer/models/mail_setting.dart';
import 'package:jippymart_customer/models/notification_model.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/models/payment_model/cod_setting_model.dart';
import 'package:jippymart_customer/models/payment_model/flutter_wave_model.dart';
import 'package:jippymart_customer/models/payment_model/mercado_pago_model.dart';
import 'package:jippymart_customer/models/payment_model/mid_trans.dart';
import 'package:jippymart_customer/models/payment_model/orange_money.dart';
import 'package:jippymart_customer/models/payment_model/pay_fast_model.dart';
import 'package:jippymart_customer/models/payment_model/pay_stack_model.dart';
import 'package:jippymart_customer/models/payment_model/paypal_model.dart';
import 'package:jippymart_customer/models/payment_model/paytm_model.dart';
import 'package:jippymart_customer/models/payment_model/razorpay_model.dart';
import 'package:jippymart_customer/models/payment_model/stripe_model.dart';
import 'package:jippymart_customer/models/payment_model/wallet_setting_model.dart';
import 'package:jippymart_customer/models/payment_model/xendit.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/rating_model.dart';
import 'package:jippymart_customer/models/review_attribute_model.dart';
import 'package:jippymart_customer/models/tax_model.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/models/wallet_transaction_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:jippymart_customer/widget/geoflutterfire/src/models/point.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';

class FireStoreUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;

  // **CRITICAL: Database corruption prevention**
  static bool _isDatabaseHealthy = true;
  static int _consecutiveErrors = 0;
  static const int _maxConsecutiveErrors = 5;
  static const Duration _errorResetTime = Duration(minutes: 5);
  static DateTime? _lastErrorTime;

  static String?
  backendUserId; // Set this from LoginController after OTP verification

  // **CRITICAL: Database health check**
  static bool get isDatabaseHealthy => _isDatabaseHealthy;

  static void _recordError() {
    _consecutiveErrors++;
    _lastErrorTime = DateTime.now();

    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      _isDatabaseHealthy = false;
      if (kDebugMode) {
        print(
          'CRITICAL: Database marked as unhealthy due to $_consecutiveErrors consecutive errors',
        );
      }
    }
  }

  static void _resetErrorCount() {
    if (_lastErrorTime != null &&
        DateTime.now().difference(_lastErrorTime!) > _errorResetTime) {
      _consecutiveErrors = 0;
      _isDatabaseHealthy = true;
    }
  }

  // **CRITICAL: Safe Firestore operation wrapper with retry mechanism**
  static Future<T> _safeFirestoreOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
  }) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        _resetErrorCount();

        if (!_isDatabaseHealthy) {
          throw Exception('Database is in unhealthy state');
        }

        final result = await operation().timeout(
          const Duration(seconds: 5), // **ANR FIX: Reduced from 10s to 5s**
          onTimeout: () {
            _recordError();
            throw TimeoutException(
              'Firestore operation timed out',
              const Duration(seconds: 5),
            );
          },
        );

        // Reset error count on success
        _consecutiveErrors = 0;
        return result;
      } catch (e) {
        retryCount++;
        _recordError();

        if (kDebugMode) {
          print(
            'ERROR: Firestore operation failed (attempt $retryCount/$maxRetries): $e',
          );
        }

        // Log to Crashlytics for production monitoring
        FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason:
              'Firestore operation failed - attempt $retryCount/$maxRetries',
        );

        // Don't retry on certain errors
        if (e.toString().contains('PERMISSION_DENIED') ||
            e.toString().contains('NOT_FOUND') ||
            e.toString().contains('INVALID_ARGUMENT')) {
          break;
        }

        // Wait before retry with exponential backoff
        if (retryCount < maxRetries) {
          final delay = Duration(milliseconds: 1000 * retryCount);
          await Future.delayed(delay);
        }
      }
    }

    // If all retries failed, throw the last error
    throw Exception('Firestore operation failed after $maxRetries attempts');
  }

  static Future<bool?> updateUserWallet({
    required String amount,
    required String userId,
  }) async {
    bool isAdded = false;
    await AddressListProvider.getUserProfile(userId).then((value) async {
      if (value != null) {
        UserModel userModel = value;
        userModel.walletAmount =
            (double.parse(userModel.walletAmount.toString()) +
                    double.parse(amount))
                as int?;
        await FireStoreUtils.updateUser(userModel).then((value) {
          isAdded = value;
        });
      }
    });
    return isAdded;
  }

  static Future<bool> updateUser(UserModel userModel) async {
    final userId = await SqlStorageConst.getFirebaseId();
    bool isUpdate = false;
    String? uid = userModel.id ?? userId ?? '';
    if (uid.isEmpty) {
      log('updateUser: No UID available for user document!');
      return false;
    }
    userModel.id = uid;
    await fireStore
        .collection(CollectionName.users)
        .doc(uid)
        .set(userModel.toJson())
        .whenComplete(() {
          Constant.userModel = userModel;
          isUpdate = true;
        })
        .catchError((error) {
          log("Failed to update user: $error");
          isUpdate = false;
        });
    return isUpdate;
  }

  static Future<bool?> setWalletTransaction(
    WalletTransactionModel walletTransactionModel,
  ) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.wallet)
        .doc(walletTransactionModel.id)
        .set(walletTransactionModel.toJson())
        .then((value) {
          isAdded = true;
        })
        .catchError((error) {
          log("Failed to update user: $error");
          isAdded = false;
        });
    return isAdded;
  }

  getSettings(BuildContext context) async {
    try {
      FirebaseFirestore.instance
          .collection(CollectionName.settings)
          .doc('restaurant')
          .get()
          .then((value) {
            Constant.isSubscriptionModelApplied = value
                .data()!['subscription_model'];
          });

      fireStore
          .collection(CollectionName.settings)
          .doc("RestaurantNearBy")
          .snapshots()
          .listen((event) {
            if (event.exists) {
              Constant.radius = event.data()!["radios"];
              Constant.driverRadios = event.data()!["driverRadios"];
              Constant.distanceType = event.data()!["distanceType"];
            }
          });

      await FirebaseFirestore.instance
          .collection(CollectionName.settings)
          .doc("globalSettings")
          .get()
          .then((value) {
            Constant.isEnableAdsFeature =
                value.data()?['isEnableAdsFeature'] ?? false;
            Constant.isSelfDeliveryFeature =
                value.data()!['isSelfDelivery'] ?? false;
            AppThemeData.primary300 = Color(
              int.parse(
                value.data()!['app_customer_color'].replaceFirst("#", "0xff"),
              ),
            );
          });

      fireStore
          .collection(CollectionName.settings)
          .doc("googleMapKey")
          .snapshots()
          .listen((event) {
            if (event.exists) {
              Constant.mapAPIKey = event.data()!["key"];
              Constant.placeHolderImage = event.data()!["placeHolderImage"];
            }
          });

      fireStore
          .collection(CollectionName.settings)
          .doc("notification_setting")
          .get()
          .then((event) {
            if (event.exists) {
              Constant.senderId = event.data()?["projectId"];
              Constant.jsonNotificationFileURL = event.data()?["serviceJson"];
            }
          });

      fireStore
          .collection(CollectionName.settings)
          .doc("DriverNearBy")
          .get()
          .then((event) {
            if (event.exists) {
              Constant.selectedMapType = event.data()!["selectedMapType"];
              Constant.mapType = event.data()!["mapType"];
            }
          });

      fireStore
          .collection(CollectionName.settings)
          .doc("privacyPolicy")
          .snapshots()
          .listen((event) {
            if (event.exists) {
              Constant.privacyPolicy = event.data()!["privacy_policy"];
            }
          });

      fireStore
          .collection(CollectionName.settings)
          .doc("termsAndConditions")
          .snapshots()
          .listen((event) {
            if (event.exists) {
              Constant.termsAndConditions = event.data()!["termsAndConditions"];
            }
          });

      fireStore
          .collection(CollectionName.settings)
          .doc("walletSettings")
          .snapshots()
          .listen((event) {
            if (event.exists) {
              Constant.walletSetting = event.data()!["isEnabled"];
            }
          });

      fireStore
          .collection(CollectionName.settings)
          .doc("Version")
          .snapshots()
          .listen((event) {
            if (event.exists) {
              Constant.googlePlayLink = event.data()!["googlePlayLink"] ?? '';
              Constant.appStoreLink = event.data()!["appStoreLink"] ?? '';
              Constant.appVersion = event.data()!["app_version"] ?? '';
              Constant.websiteUrl = event.data()!["websiteUrl"] ?? '';
            }
          });

      fireStore
          .collection(CollectionName.settings)
          .doc('story')
          .get()
          .then((value) {
            if (value.exists && value.data() != null) {
              Constant.storyEnable = value.data()!['isEnabled'];
              print(
                '[DEBUG] Story enable setting loaded: ${Constant.storyEnable}',
              );
            } else {
              print('[DEBUG] Story settings document not found or empty');
              Constant.storyEnable = false; // Default to false if not found
            }
          })
          .catchError((error) {
            print('[DEBUG] Error loading story settings: $error');
            Constant.storyEnable = false; // Default to false on error
          });

      fireStore
          .collection(CollectionName.settings)
          .doc('referral_amount')
          .get()
          .then((value) {
            Constant.referralAmount = value.data()!['referralAmount'];
          });

      fireStore
          .collection(CollectionName.settings)
          .doc('placeHolderImage')
          .get()
          .then((value) {
            Constant.placeholderImage = value.data()!['image'];
          });

      fireStore
          .collection(CollectionName.settings)
          .doc("emailSetting")
          .get()
          .then((value) {
            if (value.exists) {
              Constant.mailSettings = MailSettings.fromJson(value.data()!);
            }
          });

      fireStore
          .collection(CollectionName.settings)
          .doc("specialDiscountOffer")
          .get()
          .then((dineinresult) {
            if (dineinresult.exists) {
              Constant.specialDiscountOffer = dineinresult.data()!["isEnable"];
            }
          });

      await FirebaseFirestore.instance
          .collection(CollectionName.settings)
          .doc("DineinForRestaurant")
          .get()
          .then((value) {
            Constant.isEnabledForCustomer =
                value['isEnabledForCustomer'] ?? false;
          });

      await fireStore
          .collection(CollectionName.settings)
          .doc("AdminCommission")
          .get()
          .then((value) {
            if (value.data() != null) {
              Constant.adminCommission = AdminCommission.fromJson(
                value.data()!,
              );
            }
          });
    } catch (e) {
      log(e.toString());
    }
  }

  static Future<bool?> checkReferralCodeValidOrNot(String referralCode) async {
    bool? isExit;
    try {
      await fireStore
          .collection(CollectionName.referral)
          .where("referralCode", isEqualTo: referralCode)
          .get()
          .then((value) {
            if (value.size > 0) {
              isExit = true;
            } else {
              isExit = false;
            }
          });
    } catch (e, s) {
      print('FireStoreUtils.firebaseCreateNewUser $e $s');
      return false;
    }
    return isExit;
  }

  static Future<List<WalletTransactionModel>?> getWalletTransaction() async {
    final userId = await SqlStorageConst.getFirebaseId();
    List<WalletTransactionModel> walletTransactionList = [];
    log("FireStoreUtils.getCurrentUid() :: ${userId}");
    await fireStore
        .collection(CollectionName.wallet)
        .where('user_id', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get()
        .then((value) {
          for (var element in value.docs) {
            WalletTransactionModel walletTransactionModel =
                WalletTransactionModel.fromJson(element.data());
            walletTransactionList.add(walletTransactionModel);
          }
        })
        .catchError((error) {
          log(error.toString());
        });
    return walletTransactionList;
  }

  static Future getPaymentSettingsData() async {
    await fireStore
        .collection(CollectionName.settings)
        .doc("payFastSettings")
        .get()
        .then((value) async {
          if (value.exists) {
            PayFastModel payFastModel = PayFastModel.fromJson(value.data()!);
            await Preferences.setString(
              Preferences.payFastSettings,
              jsonEncode(payFastModel.toJson()),
            );
          }
        });
    await fireStore
        .collection(CollectionName.settings)
        .doc("MercadoPago")
        .get()
        .then((value) async {
          if (value.exists) {
            MercadoPagoModel mercadoPagoModel = MercadoPagoModel.fromJson(
              value.data()!,
            );
            await Preferences.setString(
              Preferences.mercadoPago,
              jsonEncode(mercadoPagoModel.toJson()),
            );
          }
        });
    await fireStore
        .collection(CollectionName.settings)
        .doc("paypalSettings")
        .get()
        .then((value) async {
          if (value.exists) {
            PayPalModel payPalModel = PayPalModel.fromJson(value.data()!);
            await Preferences.setString(
              Preferences.paypalSettings,
              jsonEncode(payPalModel.toJson()),
            );
          }
        });
    await fireStore
        .collection(CollectionName.settings)
        .doc("stripeSettings")
        .get()
        .then((value) async {
          if (value.exists) {
            StripeModel stripeModel = StripeModel.fromJson(value.data()!);
            await Preferences.setString(
              Preferences.stripeSettings,
              jsonEncode(stripeModel.toJson()),
            );
          }
        });
    await fireStore
        .collection(CollectionName.settings)
        .doc("flutterWave")
        .get()
        .then((value) async {
          if (value.exists) {
            FlutterWaveModel flutterWaveModel = FlutterWaveModel.fromJson(
              value.data()!,
            );
            await Preferences.setString(
              Preferences.flutterWave,
              jsonEncode(flutterWaveModel.toJson()),
            );
          }
        });
    await fireStore
        .collection(CollectionName.settings)
        .doc("payStack")
        .get()
        .then((value) async {
          if (value.exists) {
            PayStackModel payStackModel = PayStackModel.fromJson(value.data()!);
            await Preferences.setString(
              Preferences.payStack,
              jsonEncode(payStackModel.toJson()),
            );
          }
        });
    await fireStore
        .collection(CollectionName.settings)
        .doc("PaytmSettings")
        .get()
        .then((value) async {
          if (value.exists) {
            PaytmModel paytmModel = PaytmModel.fromJson(value.data()!);
            await Preferences.setString(
              Preferences.paytmSettings,
              jsonEncode(paytmModel.toJson()),
            );
          }
        });
    await fireStore
        .collection(CollectionName.settings)
        .doc("walletSettings")
        .get()
        .then((value) async {
          if (value.exists) {
            WalletSettingModel walletSettingModel = WalletSettingModel.fromJson(
              value.data()!,
            );
            await Preferences.setString(
              Preferences.walletSettings,
              jsonEncode(walletSettingModel.toJson()),
            );
          }
        });
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

    await fireStore
        .collection(CollectionName.settings)
        .doc("midtrans_settings")
        .get()
        .then((value) async {
          if (value.exists) {
            MidTrans midTrans = MidTrans.fromJson(value.data()!);
            await Preferences.setString(
              Preferences.midTransSettings,
              jsonEncode(midTrans.toJson()),
            );
          }
        });

    await fireStore
        .collection(CollectionName.settings)
        .doc("orange_money_settings")
        .get()
        .then((value) async {
          if (value.exists) {
            OrangeMoney orangeMoney = OrangeMoney.fromJson(value.data()!);
            await Preferences.setString(
              Preferences.orangeMoneySettings,
              jsonEncode(orangeMoney.toJson()),
            );
          }
        });

    await fireStore
        .collection(CollectionName.settings)
        .doc("xendit_settings")
        .get()
        .then((value) async {
          if (value.exists) {
            Xendit xendit = Xendit.fromJson(value.data()!);
            await Preferences.setString(
              Preferences.xenditSettings,
              jsonEncode(xendit.toJson()),
            );
          }
        });
  }

  static Future<VendorModel?> getVendorById(String vendorId) async {
    VendorModel? vendorModel;
    try {
      await fireStore
          .collection(CollectionName.vendors)
          .doc(vendorId)
          .get()
          .then((value) {
            if (value.exists) {
              vendorModel = VendorModel.fromJson(value.data()!);
            }
          });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return vendorModel;
  }

  static StreamController<List<VendorModel>>? getNearestVendorController;

  static Stream<List<VendorModel>> getAllNearestRestaurant({
    bool? isDining,
  }) async* {
    try {
      getNearestVendorController =
          StreamController<List<VendorModel>>.broadcast();
      List<VendorModel> vendorList = [];
      // **DEBUG: Check zone availability**
      if (Constant.selectedZone == null) {
        print(
          '[DEBUG] getAllNearestRestaurant: No zone selected, cannot load restaurants',
        );
        getNearestVendorController!.sink.add([]);
        yield* getNearestVendorController!.stream;
        return;
      }

      print(
        '[DEBUG] getAllNearestRestaurant: Loading restaurants for zone: ${Constant.selectedZone!.name} (${Constant.selectedZone!.id})',
      );
      print(
        '[DEBUG] getAllNearestRestaurant: User location: ${Constant.selectedLocation.location?.latitude}, ${Constant.selectedLocation.location?.longitude}',
      );
      print(
        '[DEBUG] getAllNearestRestaurant: Search radius: ${Constant.radius}km',
      );

      Query<Map<String, dynamic>> query = isDining == true
          ? fireStore
                .collection(CollectionName.vendors)
                .where(
                  'zoneId',
                  isEqualTo: Constant.selectedZone!.id.toString(),
                )
                .where("enabledDiveInFuture", isEqualTo: true)
          : fireStore
                .collection(CollectionName.vendors)
                .where(
                  'zoneId',
                  isEqualTo: Constant.selectedZone!.id.toString(),
                );

      GeoFirePoint center = Geoflutterfire().point(
        latitude: Constant.selectedLocation.location!.latitude ?? 0.0,
        longitude: Constant.selectedLocation.location!.longitude ?? 0.0,
      );
      String field = 'g';

      Stream<List<DocumentSnapshot>> stream = Geoflutterfire()
          .collection(collectionRef: query)
          .within(
            center: center,
            radius: double.parse(Constant.radius),
            field: field,
            strictMode: true,
          );

      stream.listen(
        (List<DocumentSnapshot> documentList) async {
          vendorList.clear();
          print(
            '[DEBUG] getAllNearestRestaurant: Found ${documentList.length} restaurants in Firestore query',
          );

          for (var document in documentList) {
            try {
              final data = document.data() as Map<String, dynamic>;
              VendorModel vendorModel = VendorModel.fromJson(data);

              // **DEBUG: Log restaurant details**
              print(
                '[DEBUG] Restaurant: ${vendorModel.title} (ID: ${vendorModel.id}) - Zone: ${vendorModel.zoneId}',
              );

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
                          vendorModel.subscriptionExpiryDate!.toDate().isBefore(
                                DateTime.now(),
                              ) ==
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
            } catch (e) {
              print('[DEBUG] Error parsing restaurant data: $e');
            }
          }
          print(
            '[DEBUG] getAllNearestRestaurant: Final result: ${vendorList.length} restaurants after filtering',
          );
          getNearestVendorController!.sink.add(vendorList);
        },
        onError: (error) {
          print('[DEBUG] getAllNearestRestaurant: Stream error: $error');
          getNearestVendorController!.sink.add([]);
        },
      );

      yield* getNearestVendorController!.stream;
    } catch (e) {
      print('[DEBUG] getAllNearestRestaurant: Error in main try block: $e');

      // **FALLBACK: Try to load restaurants without zone filtering if main query fails**
      try {
        print(
          '[DEBUG] getAllNearestRestaurant: Attempting fallback query without zone filtering',
        );
        List<VendorModel> fallbackVendorList = [];

        final fallbackQuery = fireStore
            .collection(CollectionName.vendors)
            .limit(50); // Limit to prevent huge queries

        final fallbackSnapshot = await fallbackQuery.get();
        print(
          '[DEBUG] getAllNearestRestaurant: Fallback query found ${fallbackSnapshot.docs.length} restaurants',
        );

        for (var document in fallbackSnapshot.docs) {
          try {
            final data = document.data();
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
      } catch (fallbackError) {
        print(
          '[DEBUG] getAllNearestRestaurant: Fallback query also failed: $fallbackError',
        );
        getNearestVendorController!.sink.add([]);
        yield* getNearestVendorController!.stream;
      }
    }
  }

  static StreamController<List<VendorModel>>?
  getNearestVendorByCategoryController;

  static Stream<List<VendorModel>> getAllNearestRestaurantByCategoryId({
    bool? isDining,
    required String categoryId,
  }) async* {
    try {
      getNearestVendorByCategoryController =
          StreamController<List<VendorModel>>.broadcast();
      List<VendorModel> vendorList = [];

      // Debug log the category ID we're searching for
      print("Searching for category ID: $categoryId");

      Query<Map<String, dynamic>> query = isDining == true
          ? fireStore
                .collection(CollectionName.vendors)
                .where(
                  'zoneId',
                  isEqualTo: Constant.selectedZone!.id.toString(),
                )
                .where("enabledDiveInFuture", isEqualTo: true)
          : fireStore
                .collection(CollectionName.vendors)
                .where(
                  'zoneId',
                  isEqualTo: Constant.selectedZone!.id.toString(),
                );

      GeoFirePoint center = Geoflutterfire().point(
        latitude: Constant.selectedLocation.location!.latitude ?? 0.0,
        longitude: Constant.selectedLocation.location!.longitude ?? 0.0,
      );
      String field = 'g';

      Stream<List<DocumentSnapshot>> stream = Geoflutterfire()
          .collection(collectionRef: query)
          .within(
            center: center,
            radius: double.parse(Constant.radius),
            field: field,
            strictMode: true,
          );

      stream.listen((List<DocumentSnapshot> documentList) async {
        vendorList.clear();
        for (var document in documentList) {
          final data = document.data() as Map<String, dynamic>;
          VendorModel vendorModel = VendorModel.fromJson(data);

          // Debug logging
          print("Vendor ID: ${vendorModel.id}");
          print("Vendor Categories: ${vendorModel.categoryID}");
          print(
            "Raw vendor data: ${data['categoryID']}",
          ); // Add this to see raw data

          // Check if the vendor has the category ID in its categoryID list
          bool hasCategory = false;

          // First check if categoryID exists in raw data
          if (data.containsKey('categoryID')) {
            var rawCategoryId = data['categoryID'];
            print("Raw category ID type: ${rawCategoryId.runtimeType}");

            // Handle different possible data types
            if (rawCategoryId is List) {
              hasCategory = rawCategoryId.any(
                (catId) =>
                    catId.toString() == categoryId ||
                    catId.toString().trim() == categoryId.trim(),
              );
            } else if (rawCategoryId is String) {
              hasCategory =
                  rawCategoryId == categoryId ||
                  rawCategoryId.trim() == categoryId.trim();
            }
          }

          // If no category found in raw data, check the model
          if (!hasCategory && vendorModel.categoryID != null) {
            hasCategory = vendorModel.categoryID!.any(
              (catId) =>
                  catId.toString() == categoryId ||
                  catId.toString().trim() == categoryId.trim(),
            );
          }
          print("Has category: $hasCategory");
          if (hasCategory) {
            if ((Constant.isSubscriptionModelApplied == true ||
                    Constant.adminCommission?.isEnabled == true) &&
                vendorModel.subscriptionPlan != null) {
              if (vendorModel.subscriptionTotalOrders == "-1") {
                // **FOOD CATEGORY FILTERING: Exclude mart vendors**
                if (vendorModel.vType == null ||
                    vendorModel.vType!.toLowerCase() != 'mart') {
                  vendorList.add(vendorModel);
                } else {
                  print(
                    '[DEBUG] Mart vendor excluded from FOOD category (unlimited subscription): ${vendorModel.title}',
                  );
                }
              } else {
                if ((vendorModel.subscriptionExpiryDate != null &&
                        vendorModel.subscriptionExpiryDate!.toDate().isBefore(
                              DateTime.now(),
                            ) ==
                            false) ||
                    vendorModel.subscriptionPlan?.expiryDay == '-1') {
                  if (vendorModel.subscriptionTotalOrders != '0') {
                    // **FOOD CATEGORY FILTERING: Exclude mart vendors**
                    if (vendorModel.vType == null ||
                        vendorModel.vType!.toLowerCase() != 'mart') {
                      vendorList.add(vendorModel);
                    } else {
                      print(
                        '[DEBUG] Mart vendor excluded from FOOD category (valid subscription): ${vendorModel.title}',
                      );
                    }
                  }
                }
              }
            } else {
              // **FOOD CATEGORY FILTERING: Exclude mart vendors**
              if (vendorModel.vType == null ||
                  vendorModel.vType!.toLowerCase() != 'mart') {
                vendorList.add(vendorModel);
              } else {
                print(
                  '[DEBUG] Mart vendor excluded from FOOD category (no subscription filter): ${vendorModel.title}',
                );
              }
            }
          }
        }
        print("Total vendors found: ${vendorList.length}");
        getNearestVendorByCategoryController!.sink.add(vendorList);
      });

      yield* getNearestVendorByCategoryController!.stream;
    } catch (e) {
      print("Error in getAllNearestRestaurantByCategoryId: $e");
    }
  }

  // static Future<List<CouponModel>> getHomeCoupon() async {
  //   List<CouponModel> list = [];
  //   await fireStore
  //       .collection(CollectionName.coupons)
  //       .where('expiresAt', isGreaterThanOrEqualTo: Timestamp.now())
  //       .where("isEnabled", isEqualTo: true)
  //       .where("isPublic", isEqualTo: true)
  //       .get()
  //       .then((value) {
  //         for (var element in value.docs) {
  //           CouponModel walletTransactionModel = CouponModel.fromJson(
  //             element.data(),
  //           );
  //           list.add(walletTransactionModel);
  //         }
  //       })
  //       .catchError((error) {
  //         log(error.toString());
  //       });
  //   return list;
  // }

  static Future<List<VendorCategoryModel>> getVendorCategory() async {
    List<VendorCategoryModel> list = [];
    await fireStore
        .collection(CollectionName.vendorCategories)
        .where('publish', isEqualTo: true)
        .get()
        .then((value) {
          for (var element in value.docs) {
            VendorCategoryModel walletTransactionModel =
                VendorCategoryModel.fromJson(element.data());
            list.add(walletTransactionModel);
          }
        })
        .catchError((error) {
          log(error.toString());
        });
    return list;
  }

  /// Stream method to get all mart banners without filtering
  static Stream<List<MartBannerModel>> getAllMartBannersStream() {
    log('[MART_BANNER_STREAM] Starting stream for all mart banners...');

    return fireStore
        .collection('mart_banners')
        .snapshots()
        .map((querySnapshot) {
          List<MartBannerModel> bannerList = [];

          log(
            '[MART_BANNER_STREAM] Stream update - Total banners in database: ${querySnapshot.docs.length}',
          );

          for (var element in querySnapshot.docs) {
            log('[MART_BANNER_STREAM] Raw banner data: ${element.data()}');
            MartBannerModel banner = MartBannerModel.fromJson({
              ...element.data(),
              'id': element.id,
            });
            log(
              '[MART_BANNER_STREAM] Parsed banner: title=${banner.title}, photo=${banner.photo}, position=${banner.position}, isPublish=${banner.isPublish}',
            );
            bannerList.add(banner);
          }

          log(
            '[MART_BANNER_STREAM] Stream update - Successfully loaded ${bannerList.length} banners',
          );
          return bannerList;
        })
        .handleError((error) {
          log('[MART_BANNER_STREAM] Stream error: $error');
          return <MartBannerModel>[];
        });
  }

  /// Stream method to get mart top banners (position: "top") - Lazy loading
  static Stream<List<MartBannerModel>> getMartTopBannersStream() {
    log(
      '[MART_BANNER_STREAM] Starting lazy loading stream for mart top banners...',
    );

    return fireStore
        .collection('mart_banners')
        .where("is_publish", isEqualTo: true)
        .where("position", isEqualTo: "top")
        .snapshots()
        .map((querySnapshot) {
          List<MartBannerModel> bannerList = [];
          List<MartBannerModel> filteredBannerList = [];

          // Get customer's current zone
          String? customerZoneId = Constant.selectedZone?.id;
          String? customerZoneTitle = Constant.selectedZone?.name;

          log(
            '[MART_BANNER_STREAM] Customer zone for mart top banners - ID: $customerZoneId, Title: $customerZoneTitle',
          );
          log(
            '[MART_BANNER_STREAM] Total mart top banners in database: ${querySnapshot.docs.length}',
          );

          for (var element in querySnapshot.docs) {
            log('[MART_BANNER_STREAM] Raw banner data: ${element.data()}');
            MartBannerModel banner = MartBannerModel.fromJson({
              ...element.data(),
              'id': element.id,
            });
            log(
              '[MART_BANNER_STREAM] Parsed banner: title=${banner.title}, photo=${banner.photo}, position=${banner.position}',
            );
            bannerList.add(banner);

            // Filter banners by zone
            bool shouldShowBanner = false;

            // If banner has no zone specified, show it to all zones
            if (banner.zoneId == null || banner.zoneId!.isEmpty) {
              shouldShowBanner = true;
              log(
                '[MART_BANNER_STREAM] Mart Top Banner "${banner.title}" - No zone specified, showing to all zones',
              );
            }
            // If customer zone is null/not set, show all banners (fallback behavior)
            else if (customerZoneId == null || customerZoneId.isEmpty) {
              shouldShowBanner = true;
              log(
                '[MART_BANNER_STREAM] Mart Top Banner "${banner.title}" - Customer zone not set, showing all banners (fallback)',
              );
            }
            // If banner zone matches customer zone
            else if (banner.zoneId == customerZoneId) {
              shouldShowBanner = true;
              log(
                '[MART_BANNER_STREAM] Mart Top Banner "${banner.title}" - Zone matches customer zone ($customerZoneId)',
              );
            }
            // If banner zone doesn't match
            else {
              log(
                '[MART_BANNER_STREAM] Mart Top Banner "${banner.title}" - Zone ${banner.zoneId} does not match customer zone $customerZoneId',
              );
            }

            if (shouldShowBanner) {
              filteredBannerList.add(banner);
            }
          }

          // Sort by set_order in memory
          filteredBannerList.sort((a, b) {
            int orderA = a.setOrder ?? 0;
            int orderB = b.setOrder ?? 0;
            return orderA.compareTo(orderB);
          });

          log(
            '[MART_BANNER_STREAM] Mart top banners matching customer zone: ${filteredBannerList.length}',
          );
          return filteredBannerList;
        })
        .handleError((error) {
          log('[MART_BANNER_STREAM] Stream error for top banners: $error');
          return <MartBannerModel>[];
        });
  }

  /// Stream method to get mart bottom banners (position: "bottom") - Lazy loading
  static Stream<List<MartBannerModel>> getMartBottomBannersStream() {
    log(
      '[MART_BANNER_STREAM] Starting lazy loading stream for mart bottom banners...',
    );

    return fireStore
        .collection('mart_banners')
        .where("is_publish", isEqualTo: true)
        .where("position", isEqualTo: "bottom")
        .snapshots()
        .map((querySnapshot) {
          List<MartBannerModel> bannerList = [];
          List<MartBannerModel> filteredBannerList = [];

          // Get customer's current zone
          String? customerZoneId = Constant.selectedZone?.id;
          String? customerZoneTitle = Constant.selectedZone?.name;

          log(
            '[MART_BANNER_STREAM] Customer zone for mart bottom banners - ID: $customerZoneId, Title: $customerZoneTitle',
          );
          log(
            '[MART_BANNER_STREAM] Total mart bottom banners in database: ${querySnapshot.docs.length}',
          );

          for (var element in querySnapshot.docs) {
            log('[MART_BANNER_STREAM] Raw banner data: ${element.data()}');
            MartBannerModel banner = MartBannerModel.fromJson({
              ...element.data(),
              'id': element.id,
            });
            log(
              '[MART_BANNER_STREAM] Parsed banner: title=${banner.title}, photo=${banner.photo}, position=${banner.position}',
            );
            bannerList.add(banner);

            // Filter banners by zone
            bool shouldShowBanner = false;

            // If banner has no zone specified, show it to all zones
            if (banner.zoneId == null || banner.zoneId!.isEmpty) {
              shouldShowBanner = true;
              log(
                '[MART_BANNER_STREAM] Mart Bottom Banner "${banner.title}" - No zone specified, showing to all zones',
              );
            }
            // If customer zone is null/not set, show all banners (fallback behavior)
            else if (customerZoneId == null || customerZoneId.isEmpty) {
              shouldShowBanner = true;
              log(
                '[MART_BANNER_STREAM] Mart Bottom Banner "${banner.title}" - Customer zone not set, showing all banners (fallback)',
              );
            }
            // If banner zone matches customer zone
            else if (banner.zoneId == customerZoneId) {
              shouldShowBanner = true;
              log(
                '[MART_BANNER_STREAM] Mart Bottom Banner "${banner.title}" - Zone matches customer zone ($customerZoneId)',
              );
            }
            // If banner zone doesn't match
            else {
              log(
                '[MART_BANNER_STREAM] Mart Bottom Banner "${banner.title}" - Zone ${banner.zoneId} does not match customer zone $customerZoneId',
              );
            }

            if (shouldShowBanner) {
              filteredBannerList.add(banner);
            }
          }

          // Sort by set_order in memory
          filteredBannerList.sort((a, b) {
            int orderA = a.setOrder ?? 0;
            int orderB = b.setOrder ?? 0;
            return orderA.compareTo(orderB);
          });

          log(
            '[MART_BANNER_STREAM] Mart bottom banners matching customer zone: ${filteredBannerList.length}',
          );
          return filteredBannerList;
        })
        .handleError((error) {
          log('[MART_BANNER_STREAM] Stream error for bottom banners: $error');
          return <MartBannerModel>[];
        });
  }

  //
  // static Future<List<FavouriteModel>> getFavouriteRestaurant() async {
  //   final userId = await SqlStorageConst.getFirebaseId();
  //   List<FavouriteModel> favouriteList = [];
  //   await fireStore
  //       .collection(CollectionName.favoriteRestaurant)
  //       .where('user_id', isEqualTo: userId)
  //       .get()
  //       .then((value) {
  //         for (var element in value.docs) {
  //           FavouriteModel favouriteModel = FavouriteModel.fromJson(
  //             element.data(),
  //           );
  //           favouriteList.add(favouriteModel);
  //         }
  //       });
  //   return favouriteList;
  // }

  // static Future<List<FavouriteItemModel>> getFavouriteItem() async {
  //   final userId = await SqlStorageConst.getFirebaseId();
  //   List<FavouriteItemModel> favouriteList = [];
  //   await fireStore
  //       .collection(CollectionName.favoriteItem)
  //       .where('user_id', isEqualTo: userId)
  //       .get()
  //       .then((value) {
  //         for (var element in value.docs) {
  //           FavouriteItemModel favouriteModel = FavouriteItemModel.fromJson(
  //             element.data(),
  //           );
  //           favouriteList.add(favouriteModel);
  //         }
  //       });
  //   return favouriteList;
  // }

  // Get user's favorite restaurants (returns VendorModel list)
  static Future<List<VendorModel>> getFavouriteRestaurants() async {
    try {
      return await FavouriteProvider.getFavouriteRestaurants();
    } catch (e) {
      print('Error fetching favorites: $e');
      rethrow;
    }
  }

  // static Future<void> removeFavouriteItem(
  //   FavouriteItemModel favouriteModel,
  // ) async {
  //   try {
  //     final favoriteCollection = fireStore.collection(
  //       CollectionName.favoriteItem,
  //     );
  //     final querySnapshot = await favoriteCollection
  //         .where("product_id", isEqualTo: favouriteModel.productId)
  //         .get();
  //     for (final doc in querySnapshot.docs) {
  //       await favoriteCollection.doc(doc.id).delete();
  //     }
  //   } catch (e) {
  //     print("Error removing favourite item: $e");
  //   }
  // }

  // static Future<void> setFavouriteItem(
  //   FavouriteItemModel favouriteModel,
  // ) async {
  //   await fireStore
  //       .collection(CollectionName.favoriteItem)
  //       .add(favouriteModel.toJson());
  // }

  static Future<List<ProductModel>> getProductByVendorId(
    String vendorId,
  ) async {
    try {
      return await _safeFirestoreOperation(() async {
        String selectedFoodType = Preferences.getString(
          Preferences.foodDeliveryType,
          defaultValue: "Delivery".tr,
        );
        List<ProductModel> list = [];
        // **PERFORMANCE OPTIMIZATION: Add timeout and limit**
        final queryTimeout = const Duration(seconds: 15); // Increased timeout
        const int maxProducts =
            400; // Increased limit to prevent product filtering issues
        if (selectedFoodType == "TakeAway") {
          final value = await fireStore
              .collection(CollectionName.vendorProducts)
              .where("vendorID", isEqualTo: vendorId)
              .where('publish', isEqualTo: true)
              .orderBy("createdAt", descending: false)
              .limit(maxProducts)
              .get()
              .timeout(queryTimeout);
          for (var element in value.docs) {
            try {
              ProductModel productModel = ProductModel.fromJson(element.data());
              list.add(productModel);
            } catch (e) {
              if (kDebugMode) {
                print('ERROR: Failed to parse product data: $e');
              }
            }
          }
        } else {
          final value = await fireStore
              .collection(CollectionName.vendorProducts)
              .where("vendorID", isEqualTo: vendorId)
              .where("takeawayOption", isEqualTo: false)
              .where('publish', isEqualTo: true)
              .orderBy("createdAt", descending: false)
              .limit(maxProducts) // **PERFORMANCE: Limit results**
              .get()
              .timeout(queryTimeout); // **PERFORMANCE: Add timeout**

          for (var element in value.docs) {
            try {
              ProductModel productModel = ProductModel.fromJson(element.data());
              list.add(productModel);
            } catch (e) {
              if (kDebugMode) {
                print('ERROR: Failed to parse product data: $e');
              }
            }
          }
        }
        if (kDebugMode) {
          print(
            'DEBUG: getProductByVendorId loaded ${list.length} products for vendor $vendorId',
          );
          print('DEBUG: Food delivery type: $selectedFoodType');
          print('DEBUG: Max products limit: $maxProducts');
          // Check if specific product is in the list
          bool foundSpecificProduct = list.any(
            (product) => product.id == "E5uQMHSJY9hj9yD5NTp3",
          );
          print(
            'DEBUG: Rayalaseema Biryani (E5uQMHSJY9hj9yD5NTp3) found in product list: $foundSpecificProduct',
          );

          if (!foundSpecificProduct) {
            print(
              'DEBUG: ⚠️ Rayalaseema Biryani NOT found in product list - checking filters...',
            );
            print('DEBUG: This could be due to:');
            print('DEBUG: 1. Product not published (publish: false)');
            print(
              'DEBUG: 2. Product is takeaway only (takeawayOption: true) but app in delivery mode',
            );
            print(
              'DEBUG: 3. Product limit exceeded (more than $maxProducts products)',
            );
            print('DEBUG: 4. Wrong vendorID in product document');
          }
        }

        return list;
      });
    } catch (e) {
      if (kDebugMode) {
        print('ERROR: getProductByVendorId failed for vendor $vendorId: $e');
      }
      return []; // Return empty list instead of crashing
    }
  }

  static Future<ProductModel?> getProductById(String productId) async {
    ProductModel? vendorCategoryModel;
    try {
      await fireStore
          .collection(CollectionName.vendorProducts)
          .doc(productId)
          .get()
          .then((value) {
            if (value.exists) {
              vendorCategoryModel = ProductModel.fromJson(value.data()!);
            }
          });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return vendorCategoryModel;
  }

  static Future<List<AttributesModel>?> getAttributes() async {
    List<AttributesModel> attributeList = [];
    await fireStore.collection(CollectionName.vendorAttributes).get().then((
      value,
    ) {
      for (var element in value.docs) {
        AttributesModel favouriteModel = AttributesModel.fromJson(
          element.data(),
        );
        attributeList.add(favouriteModel);
      }
    });
    return attributeList;
  }

  static Future<DeliveryCharge?> getDeliveryCharge() async {
    DeliveryCharge? deliveryCharge;
    try {
      await fireStore
          .collection(CollectionName.settings)
          .doc("DeliveryCharge")
          .get()
          .then((value) {
            if (value.exists) {
              deliveryCharge = DeliveryCharge.fromJson(value.data()!);
            }
          });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return deliveryCharge;
  }

  static Future<List<TaxModel>?> getTaxList() async {
    List<TaxModel> taxList = [];
    // Check if location is available
    if (Constant.selectedLocation.location?.latitude == null ||
        Constant.selectedLocation.location?.longitude == null) {
      print('[FIRE_STORE_UTILS] Location not available for tax calculation');
      return taxList;
    }

    try {
      List<Placemark> placeMarks = await placemarkFromCoordinates(
        Constant.selectedLocation.location!.latitude!,
        Constant.selectedLocation.location!.longitude!,
      );

      if (placeMarks.isEmpty) {
        print('[FIRE_STORE_UTILS] No placemarks found for coordinates');
        return taxList;
      }

      await fireStore
          .collection(CollectionName.tax)
          .where('country', isEqualTo: placeMarks.first.country)
          .where('enable', isEqualTo: true)
          .get()
          .then((value) {
            for (var element in value.docs) {
              TaxModel taxModel = TaxModel.fromJson(element.data());
              taxList.add(taxModel);
            }
          })
          .catchError((error) {
            log(error.toString());
          });
    } catch (e) {
      print('[FIRE_STORE_UTILS] Error getting tax list: $e');
    }

    return taxList;
  }

  static Future<List<CouponModel>> getAllVendorPublicCoupons(
    String vendorId,
  ) async {
    List<CouponModel> coupon = [];

    await fireStore
        .collection(CollectionName.coupons)
        .where("resturant_id", isEqualTo: vendorId)
        .where('expiresAt', isGreaterThanOrEqualTo: Timestamp.now())
        .where("isEnabled", isEqualTo: true)
        .where("isPublic", isEqualTo: true)
        .get()
        .then((value) {
          for (var element in value.docs) {
            CouponModel taxModel = CouponModel.fromJson(element.data());
            coupon.add(taxModel);
          }
        })
        .catchError((error) {
          log(error.toString());
        });
    return coupon;
  }

  static Future<List<CouponModel>> getAllVendorCoupons(String vendorId) async {
    List<CouponModel> coupon = [];

    await fireStore
        .collection(CollectionName.coupons)
        .where("resturant_id", isEqualTo: vendorId)
        .where('expiresAt', isGreaterThanOrEqualTo: Timestamp.now())
        .where("isEnabled", isEqualTo: true)
        .get()
        .then((value) {
          for (var element in value.docs) {
            CouponModel taxModel = CouponModel.fromJson(element.data());
            coupon.add(taxModel);
          }
        })
        .catchError((error) {
          log(error.toString());
        });
    return coupon;
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
          log("Failed to update user: $error");
          isAdded = false;
        });
    return isAdded;
  }

  static Future<List<OrderModel>> getAllOrder() async {
    List<OrderModel> list = [];
    final currentUid = await SqlStorageConst.getFirebaseId();
    if (kDebugMode) {
      log('[FireStoreUtils] getAllOrder called');
      log('[FireStoreUtils] Current UID: $currentUid');
      log('[FireStoreUtils] Constant.userModel?.id: ${Constant.userModel?.id}');
    }
    if (currentUid == null) {
      if (kDebugMode) {
        log(
          '[FireStoreUtils] ERROR: Current UID is empty, cannot fetch orders',
        );
      }
      return list;
    }

    try {
      final querySnapshot = await fireStore
          .collection(CollectionName.restaurantOrders)
          .where("authorID", isEqualTo: currentUid)
          .orderBy("createdAt", descending: true)
          .get();

      if (kDebugMode) {
        log(
          '[FireStoreUtils] Query completed, found ${querySnapshot.docs.length} orders',
        );
      }

      for (var element in querySnapshot.docs) {
        try {
          OrderModel orderModel = OrderModel.fromJson(element.data());
          list.add(orderModel);
          if (kDebugMode) {
            log('[FireStoreUtils] Added order: ${orderModel.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            log('[FireStoreUtils] Error parsing order: $e');
          }
        }
      }
    } catch (error) {
      if (kDebugMode) {
        log('[FireStoreUtils] Error fetching orders: $error');
      }
    }

    if (kDebugMode) {
      log('[FireStoreUtils] Returning ${list.length} orders');
    }
    return list;
  }

  static Future<OrderModel?> getOrderByOrderId(String orderId) async {
    OrderModel? orderModel;
    try {
      await fireStore
          .collection(CollectionName.restaurantOrders)
          .doc(orderId)
          .get()
          .then((value) {
            if (value.data() != null) {
              orderModel = OrderModel.fromJson(value.data()!);
            }
          });
    } catch (e, s) {
      print('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return orderModel;
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
    List<RatingModel> ratingList = [];
    await fireStore
        .collection(CollectionName.foodsReview)
        .where('VendorId', isEqualTo: vendorId)
        .get()
        .then((value) {
          for (var element in value.docs) {
            RatingModel giftCardsOrderModel = RatingModel.fromJson(
              element.data(),
            );
            ratingList.add(giftCardsOrderModel);
          }
        });
    return ratingList;
  }

  static Future<RatingModel?> getOrderReviewsByID(
    String orderId,
    String productID,
  ) async {
    RatingModel? ratingModel;

    await fireStore
        .collection(CollectionName.foodsReview)
        .where('orderid', isEqualTo: orderId)
        .where('productId', isEqualTo: productID)
        .get()
        .then((value) {
          if (value.docs.isNotEmpty) {
            ratingModel = RatingModel.fromJson(value.docs.first.data());
          }
        })
        .catchError((error) {
          log(error.toString());
        });
    return ratingModel;
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
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return vendorCategoryModel;
  }

  static Future<ReviewAttributeModel?> getVendorReviewAttribute(
    String attributeId,
  ) async {
    ReviewAttributeModel? vendorCategoryModel;
    try {
      await fireStore
          .collection(CollectionName.reviewAttributes)
          .doc(attributeId)
          .get()
          .then((value) {
            if (value.exists) {
              vendorCategoryModel = ReviewAttributeModel.fromJson(
                value.data()!,
              );
            }
          });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return vendorCategoryModel;
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
          log("Failed to update user: $error");
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
        .catchError((error) {
          log(error.toString());
        });
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
    print('[DEBUG] ===== PROMOTION CHECK START (OPTIMIZED) =====');
    print(
      '[DEBUG] getActivePromotionForProduct called for productId=$productId, restaurantId=$restaurantId',
    );

    // **CRITICAL PERFORMANCE FIX: Filter by restaurant to reduce query size**
    final promos = await fetchActivePromotions(restaurantId: restaurantId);
    print(
      '[DEBUG] Total active promotions found for restaurant: ${promos.length}',
    );

    // **PERFORMANCE FIX: Direct match instead of looping through all**
    final promo = promos.firstWhere(
      (p) =>
          p['product_id'] == productId &&
          p['restaurant_id'] == restaurantId &&
          p['isAvailable'] == true,
      orElse: () => <String, dynamic>{},
    );

    print('[DEBUG] Final matched promo: ${promo.toString()}');
    print('[DEBUG] ===== PROMOTION CHECK END =====');

    if (promo.isNotEmpty) {
      print('[DEBUG] Found promotional data:');
      print('[DEBUG] - item_limit: ${promo['item_limit']}');
      print('[DEBUG] - special_price: ${promo['special_price']}');
      print('[DEBUG] - free_delivery_km: ${promo['free_delivery_km']}');
      print('[DEBUG] - extra_km_charge: ${promo['extra_km_charge']}');
      print('[DEBUG] - start_time: ${promo['start_time']}');
      print('[DEBUG] - end_time: ${promo['end_time']}');
    } else {
      print(
        '[DEBUG] ✗ No promotional data found for this product/restaurant combination',
      );
    }

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

      // ✅ STEP 2: Query products (only published)
      Query query = FirebaseFirestore.instance
          .collection(CollectionName.vendorProducts)
          // .where('publish', isEqualTo: true)
          .limit(safeLimit);

      QuerySnapshot querySnapshot = await query.get();

      print(
        '📊 Loaded ${querySnapshot.docs.length} published products (before zone filter)',
      );

      for (var document in querySnapshot.docs) {
        try {
          final data = document.data() as Map<String, dynamic>;
          ProductModel product = ProductModel.fromJson(data);

          // ✅ STEP 3: Keep only products whose vendor is in selected zone
          if (Constant.selectedZone != null) {
            if (allowedVendorIds.contains(product.vendorID)) {
              productList.add(product);
            }
          } else {
            // No zone selected → include all
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

      // **MEMORY SAFETY: Always use a limit to prevent OutOfMemoryError**
      int safeLimit =
          limit ?? 500; // Increased to 500 to match admin panel results

      // **ZONE FILTERING: Only load vendors from current zone**
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
        // Fallback: load all vendors if no zone selected
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

      // **MEMORY SAFETY: Always use a limit to prevent OutOfMemoryError**
      int safeLimit =
          limit ?? 800; // Increased to 800 to match admin panel results

      // **OPTIMIZED: Single query for published products only**
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
