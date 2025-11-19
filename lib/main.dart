import 'dart:convert';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:jippymart_customer/app/auth_screen/screens/signup_screen/provider/signup_provider.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
import 'package:jippymart_customer/app/home_screen/provider/global_settings_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/restaurant_list_screen/provider/restaurant_list_provider.dart';
import 'package:jippymart_customer/config/smartlook_config.dart';
import 'package:jippymart_customer/firebase_options.dart';
import 'package:jippymart_customer/models/language_model.dart';
import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:jippymart_customer/services/database_helper.dart';
import 'package:jippymart_customer/services/final_deep_link_service.dart';
import 'package:jippymart_customer/services/global_deeplink_handler.dart';
import 'package:jippymart_customer/services/mart_firestore_service.dart';
import 'package:jippymart_customer/services/mobile_deep_link_service.dart';
import 'package:jippymart_customer/services/pending_deep_link_handler.dart';
import 'package:jippymart_customer/services/smartlook_service.dart';
import 'package:jippymart_customer/utils/anr_monitor.dart';
import 'package:jippymart_customer/utils/app_lifecycle_logger.dart';
import 'package:jippymart_customer/utils/cache_manager.dart';
import 'package:jippymart_customer/utils/crash_prevention.dart';
import 'package:jippymart_customer/utils/native_lock_prevention.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:jippymart_customer/utils/production_logger.dart';
import 'package:jippymart_customer/utils/smartlook_anr_fix.dart';
import 'package:jippymart_customer/utils/system_call_optimizer.dart';
import 'package:jippymart_customer/utils/text_processing_anr_fix.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'app/address_screens/provider/address_list_provider.dart'
    show AddressListProvider;
import 'app/advertisement_screens/provider/all_advertisement_provider.dart';
import 'app/auth_screen/provider/login_provider.dart';
import 'app/cart_screen/screens/order_placing_screen/provider/order_placing_provider.dart';
import 'app/category_service/provider/category_sevice_provider.dart';
import 'app/chat_screens/provider/chat_provider.dart' show ChatProvider;
import 'app/edit_profile_screen/provider/edit_profile_provider.dart'
    show EditProfileProvider;
import 'app/favourite_screens/provider/favorite_provider.dart';
import 'app/home_screen/provider/map_view_provider.dart';
import 'app/home_screen/screen/category_restaurant_screen/provider/category_resaurant_provider.dart';
import 'app/home_screen/screen/discount_restaurant_list_screen/provider/discount_resaurant_list_provider.dart';
import 'app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart';
import 'app/home_screen/screen/home_screen/provider/category_view_provider.dart';
import 'app/home_screen/screen/story_view_screen/provider/story_provider.dart';
import 'app/home_screen/screen/view_all_category_screen/provider/view_all_categroy_provider.dart';
import 'app/location_permission_screen/provider/location_permission_provider.dart';
import 'app/mart/mart_home_screen/provider/mart_provider.dart';
import 'app/mart/screens/mart_categories_screen/provider/mart_category_controller.dart';
import 'app/mart/provider/category_details_provider.dart';
import 'app/mart/provider/mart_search_provider.dart';
import 'app/mart/screens/mart_edit_profile_screen/provider/mart_edit_profile_provider.dart';
import 'app/mart/screens/mart_navigation_screen/provider/mart_navigation_provider.dart';
import 'app/order_list_screen/screens/live_tracking_screen/provider/live_tracking_provider.dart'
    show LiveTrackingProvider;
import 'app/order_list_screen/screens/order_deatils_screen/provider/order_details_provider.dart';
import 'app/order_list_screen/screens/order_screen/provider/order_provider.dart';
import 'app/profile_screen/provider/my_profile_provider.dart';
import 'app/rate_us_screen/provider/rate_product_provider.dart';
import 'app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'app/review_list_screen/provider/review_list_provider.dart';
import 'app/search_screen/provider/search_provider.dart';
import 'app/splash_screen/provider/splash_provider.dart';
import 'app/swiggy_search_screen/provider/swiggy_search_provider.dart';
import 'app/splash_screen/video_splash_screen.dart';
import 'dart:io';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GlobalDeeplinkHandler.init();
  Get.put(GlobalDeeplinkHandler.instance, permanent: true);
  CrashPrevention();
  await SmartlookANRFix.configureSmartlook();
  await PlatformANRPrevention.preventMIUIANR();
  await PlatformANRPrevention.preventCiscoANR();
  try {
    // Initialize Firebase with timeout
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 3));
    // FirebaseFirestore.instance.settings = const Settings(
    //   persistenceEnabled: true,
    //   cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    //   sslEnabled: true,
    // );
    ANRMonitor.startMonitoring();
    MemoryMonitor.startMemoryMonitoring();
    NativeLockPrevention.startLockContentionMonitoring();
    TextProcessingANRFix.startTextProcessingMonitoring();
    ANRStatusLogger.logANRPreventionStatus();
  } catch (e) {}
  await GetStorage.init();
  await Preferences.initPref();
  DatabaseHelper.instance;
  Get.put(MartFirestoreService(), permanent: true);
  final cartProvider = CartProvider();
  await cartProvider.checkCartPersistence();
  runApp(MyApp());
}

void _initializeHeavyServicesInBackground() {
  Future.microtask(() async {
    try {
      await Future.wait([
        Get.putAsync(
          () => MartFirestoreService().init(),
        ).timeout(const Duration(seconds: 5)),
        CacheManager.initialize().timeout(const Duration(seconds: 3)),
        ProductionLogger.initialize().timeout(const Duration(seconds: 2)),
        AppLifecycleLogger.initialize().timeout(const Duration(seconds: 2)),
      ]);
      await Future.wait([
        PendingDeepLinkHandler.checkPendingDeepLinks().timeout(
          const Duration(seconds: 3),
        ),
        MobileDeepLinkService().initialize().timeout(
          const Duration(seconds: 3),
        ),
      ]);
    } catch (e) {}
  });
}

// **NEW: Deep Link Services background initialization**
void _initializeDeepLinkServicesInBackground(BuildContext context) {
  Future.microtask(() async {
    try {
      await FinalDeepLinkService()
          .init(GlobalDeeplinkHandler.navigatorKey, context)
          .timeout(const Duration(seconds: 5));
    } catch (e) {}
  });
}

void _initializeSmartLookInBackground() {
  Future.microtask(() async {
    final smartlookService = SmartlookService();
    try {
      await smartlookService.preventSessionRecordingStorageCrash();
      await smartlookService
          .initialize(
            SmartlookConfig.projectKey,
            region: SmartlookConfig.region,
          )
          .timeout(const Duration(seconds: 3));
      if (smartlookService.isInitialized) {
        if (SmartlookConfig.enableSensitiveDataMasking) {
          smartlookService.setSensitiveDataMasking(true);
        }
        smartlookService.setRecordingQuality(SmartlookConfig.recordingQuality);
      }
    } catch (e) {
      try {
        await smartlookService.preventSessionRecordingStorageCrash();
        await smartlookService.forceReinitialize(
          SmartlookConfig.projectKey,
          region: SmartlookConfig.region,
        );
        if (smartlookService.isInitialized) {}
      } catch (e2) {}
    }
  });
}

Future<bool> onWillPop(BuildContext context) async {
  bool? shouldExit = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Exit App'),
      content: const Text('Are you sure you want to exit the app?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () {
            if (Platform.isAndroid) {
              SystemNavigator.pop();
            } else if (Platform.isIOS) {
              exit(0);
            } else {
              SystemNavigator.pop();
            }
          },
          child: const Text('Yes'),
        ),
      ],
    ),
  );
  return shouldExit ?? false;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    _initializeHeavyServicesInBackground();
    _initializeDeepLinkServicesInBackground(context);
    _initializeSmartLookInBackground();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LanguageModel languageModel = LanguageModel(
        slug: "en",
        isRtl: false,
        title: "English",
      );
      Preferences.setString(
        Preferences.languageCodeKey,
        jsonEncode(languageModel.toJson()),
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => CategoryRestaurantProvider()),
        ChangeNotifierProvider(create: (_) => DiscountRestaurantListProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantListProvider()),
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        ChangeNotifierProvider(create: (_) => AddressListProvider()),
        ChangeNotifierProvider(create: (_) => AllAdvertisementProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => CartControllerProvider()),
        ChangeNotifierProvider(create: (_) => CategoryServiceProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => DashBoardProvider()),
        ChangeNotifierProvider(create: (_) => EditProfileProvider()),
        ChangeNotifierProvider(create: (_) => FavouriteProvider()),
        ChangeNotifierProvider(create: (_) => LocationPermissionProvider()),
        ChangeNotifierProvider(create: (_) => MartProvider()),
        ChangeNotifierProvider(create: (_) => MartCategoryProvider()),
        ChangeNotifierProvider(create: (_) => MartEditProfileProvider()),
        ChangeNotifierProvider(create: (_) => MartNavigationProvider()),
        ChangeNotifierProvider(create: (_) => LiveTrackingProvider()),
        ChangeNotifierProvider(create: (_) => OrderDetailsProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => MyProfileProvider()),
        ChangeNotifierProvider(create: (_) => RateProductProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantDetailsProvider()),
        ChangeNotifierProvider(create: (_) => ReviewListProvider()),
        ChangeNotifierProvider(create: (_) => SearchScreenProvider()),
        ChangeNotifierProvider(create: (_) => CategoryDetailsProvider()),
        ChangeNotifierProvider(create: (_) => MapViewProvider()),
        ChangeNotifierProvider(create: (_) => GlobalSettingsProvider()),
        ChangeNotifierProvider(create: (_) => SwiggySearchProvider()),
        ChangeNotifierProvider(create: (_) => MartSearchProvider()),
        ChangeNotifierProvider(create: (_) => OrderPlacingProvider()),
        ChangeNotifierProvider(create: (_) => SignupProvider()),
        ChangeNotifierProvider(create: (_) => SplashProvider()),
        ChangeNotifierProvider(create: (_) => CategoryViewProvider()),
        ChangeNotifierProvider(create: (_) => BestRestaurantProvider()),
        ChangeNotifierProvider(create: (_) => ViewAllCategoryProvider()),
      ],
      child: GetMaterialApp(
        navigatorKey: GlobalDeeplinkHandler.navigatorKey,
        title: 'JippyMart Customer'.tr,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [CountryLocalizations.delegate],
        builder: EasyLoading.init(),
        home: Consumer<GlobalSettingsProvider>(
          builder: (context, controller, _) {
            return const VideoSplashScreen();
          },
        ),
      ),
    );
  }
}
