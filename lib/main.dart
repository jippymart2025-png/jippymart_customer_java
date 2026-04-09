import 'dart:convert';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:jippymart_customer/app/auth_screen/screens/signup_screen/provider/signup_provider.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/restaurant_list_screen/provider/restaurant_list_provider.dart';
import 'package:jippymart_customer/config/smartlook_config.dart';
import 'package:jippymart_customer/firebase_options.dart';
import 'package:jippymart_customer/models/language_model.dart';
import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:jippymart_customer/services/final_deep_link_service.dart';
import 'package:jippymart_customer/services/global_deeplink_handler.dart';
import 'package:jippymart_customer/services/facebook_app_events_service.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/facebook_app_events_test.dart';
import 'package:jippymart_customer/services/mart_firestore_service.dart';
import 'package:jippymart_customer/services/mobile_deep_link_service.dart';
import 'package:jippymart_customer/services/pending_deep_link_handler.dart';
import 'package:jippymart_customer/services/smartlook_service.dart';
import 'package:jippymart_customer/services/remote_config_service.dart';
import 'package:jippymart_customer/utils/anr_monitor.dart';
import 'package:jippymart_customer/utils/app_lifecycle_logger.dart';
import 'package:jippymart_customer/utils/cache_manager.dart';
import 'package:jippymart_customer/utils/crash_prevention.dart';
import 'package:jippymart_customer/utils/delivery_charge_cache.dart';
import 'package:jippymart_customer/utils/native_lock_prevention.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:jippymart_customer/utils/production_logger.dart';
import 'package:jippymart_customer/utils/smartlook_anr_fix.dart';
import 'package:jippymart_customer/utils/system_call_optimizer.dart';
import 'package:jippymart_customer/utils/text_processing_anr_fix.dart';
import 'package:jippymart_customer/services/network_connectivity_service.dart';
import 'package:jippymart_customer/services/wallet_config_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart' as prv;
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
import 'app/wallet_screen/provider/wallet_provider.dart';
import 'app/rate_us_screen/provider/rate_product_provider.dart';
import 'app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'app/review_list_screen/provider/review_list_provider.dart';
import 'app/search_screen/provider/search_provider.dart';
import 'app/splash_screen/provider/splash_provider.dart';
import 'app/swiggy_search_screen/provider/swiggy_search_provider.dart';
import 'app/splash_screen/splash_home.dart';
import 'dart:io';
import 'package:flutter/services.dart';

// Note: Provider package (v6.1.5) doesn't support true lazy loading.
// All providers in MultiProvider are created eagerly when the widget tree builds.
// However, provider constructors are lightweight (just ChangeNotifier instances),
// and heavy initialization happens later in initFunction() methods.
//
// For true lazy loading, consider:
// 1. Moving screen-specific providers to screen-level Provider widgets
// 2. Using a different state management solution that supports lazy loading
// 3. Creating providers on-demand in screen build methods

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Light status bar by default (matches white home / dashboard). Screens with
  // colored AppBars set their own [systemOverlayStyle] to override (e.g. cart).
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      // Transparent baseline — each screen's AnnotatedRegion overrides this.
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  GlobalDeeplinkHandler.init();
  Get.put(GlobalDeeplinkHandler.instance, permanent: true);
  CrashPrevention();

  // Firebase only; Remote Config runs after first frame (AppConst.baseUrl stays defaultBaseUrl until then)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 3));
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Firebase initialization error: $e');
    }
  }
  await GetStorage.init();
  await Preferences.initPref();

  // MartFirestoreService: register here (cheap); heavy init is in _initializeHeavyServicesInBackground
  try {
    Get.put(MartFirestoreService(), permanent: true);
  } catch (e) {
    if (kDebugMode) {
      print('❌ Failed to register MartFirestoreService: $e');
    }
  }

  PaintingBinding.instance.imageCache.maximumSizeBytes =
      1024 * 1024 * 80; // 80 MB
  PaintingBinding.instance.imageCache.maximumSize = 200;

  runApp(const ProviderScope(child: MyApp()));
}

/// Runs all initialization deferred from main() so first frame paints sooner.
/// Called once after first frame from _DeferredInitRunner (context has Provider).
void _runDeferredInits(BuildContext context) {
  Future.microtask(() async {
    try {
      // Remote Config: app uses AppConst.defaultBaseUrl until this completes
      await RemoteConfigService.instance.initialize();
    } catch (e) {
      if (kDebugMode) print('⚠️ RemoteConfig init error: $e');
    }
    try {
      await WalletConfigService.instance.initialize();
      if (kDebugMode) print('✅ Wallet config initialized');
    } catch (e) {
      if (kDebugMode) print('⚠️ Wallet config init error: $e');
    }
    try {
      final cartProvider = prv.Provider.of<CartProvider>(
        context,
        listen: false,
      );
      cartProvider.checkCartPersistence();
    } catch (e) {
      if (kDebugMode) print('⚠️ CartProvider checkCartPersistence error: $e');
    }
    try {
      await NetworkConnectivityService().initialize();
      if (kDebugMode) print('✅ Network connectivity service initialized');
    } catch (e) {
      if (kDebugMode) print('⚠️ Network connectivity init failed: $e');
    }
    try {
      await FacebookAppEventsService().initialize();
      if (kDebugMode) print('✅ Facebook App Events initialized');
    } catch (e) {
      if (kDebugMode) print('⚠️ Facebook App Events init failed: $e');
    }
    try {
      DeliveryChargeCache.instance.initializeOnAppLaunch();
      if (kDebugMode) print('✅ Delivery charge cache initialized');
    } catch (e) {
      if (kDebugMode) print('⚠️ Delivery charge cache init failed: $e');
    }
    // ANR / monitoring (non-blocking)
    try {
      ANRMonitor.startMonitoring();
      MemoryMonitor.startMemoryMonitoring();
      NativeLockPrevention.startLockContentionMonitoring();
      TextProcessingANRFix.startTextProcessingMonitoring();
      ANRStatusLogger.logANRPreventionStatus();
    } catch (e) {
      if (kDebugMode) print('⚠️ ANR/monitor init error: $e');
    }
    try {
      await SmartlookANRFix.configureSmartlook();
      await PlatformANRPrevention.preventMIUIANR();
      await PlatformANRPrevention.preventCiscoANR();
    } catch (e) {
      if (kDebugMode) print('⚠️ Smartlook/Platform ANR init error: $e');
    }
    if (kDebugMode) _runFacebookAppEventsTests();
  });
}

void _initializeHeavyServicesInBackground() {
  Future.microtask(() async {
    try {
      // Initialize the already registered MartFirestoreService instance
      final martService = Get.find<MartFirestoreService>();
      await Future.wait([
        martService.init().timeout(const Duration(seconds: 5)),
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
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Background service initialization error: $e');
      }
      // Log to production logger if available
      try {
        ProductionLogger.error('MAIN', 'Background services init failed', e);
      } catch (_) {
        // Logger might not be initialized yet
      }
    }
  });
}

// **NEW: Deep Link Services background initialization**
void _initializeDeepLinkServicesInBackground(BuildContext context) {
  Future.microtask(() async {
    try {
      await FinalDeepLinkService()
          .init(GlobalDeeplinkHandler.navigatorKey, context)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Deep link service initialization error: $e');
      }
    }
  });
}

/// Run Facebook App Events tests in background (debug mode only)
void _runFacebookAppEventsTests() {
  Future.microtask(() async {
    try {
      // Wait a bit for app to fully initialize
      await Future.delayed(const Duration(seconds: 3));

      // Run SDK verification test
      await FacebookAppEventsTest.verifySDK();

      // Run all tests to verify events are working
      await Future.delayed(const Duration(seconds: 2));
      await FacebookAppEventsTest.runAllTests();
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FB TEST] Error running tests: $e');
      }
    }
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

/// Runs deferred inits after first frame so launch is not blocked.
/// Must be a descendant of MultiProvider so CartProvider is available.
class _DeferredInitRunner extends StatefulWidget {
  const _DeferredInitRunner({required this.child});

  final Widget child;

  @override
  State<_DeferredInitRunner> createState() => _DeferredInitRunnerState();
}

class _DeferredInitRunnerState extends State<_DeferredInitRunner> {
  static bool _didRun = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_didRun) {
        _didRun = true;
        _runDeferredInits(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
    super.initState();
    _initializeHeavyServicesInBackground();
    _initializeSmartLookInBackground();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDeepLinkServicesInBackground(context);
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
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Notify deep link service that app has resumed
      FinalDeepLinkService().onAppResumed();

      // 🔑 CRITICAL: Check for pending Razorpay payments and auto-place orders
      // This handles the case where user closes app immediately after payment
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final navigatorContext =
              GlobalDeeplinkHandler.navigatorKey.currentContext;
          if (navigatorContext != null) {
            final cartController = prv.Provider.of<CartControllerProvider>(
              navigatorContext,
              listen: false,
            );
            cartController.checkPendingPaymentAndPlaceOrder();
          }
        } catch (e) {
          print('⚠️ [APP_LIFECYCLE] Error checking pending payment: $e');
        }
      });
    } else if (state == AppLifecycleState.paused) {
      // Notify deep link service that app has paused
      FinalDeepLinkService().onAppPaused();
    }
  }

  @override
  Widget build(BuildContext context) {
    return prv.MultiProvider(
      providers: [
        // ============================================
        // EAGER PROVIDERS - Used immediately at startup
        // ============================================
        // GlobalSettingsProvider: Riverpod globalSettingsNotifierProvider
        prv.ChangeNotifierProvider(create: (_) => SplashProvider()),
        prv.ChangeNotifierProvider(create: (_) => CartProvider()),
        prv.ChangeNotifierProvider(create: (_) => HomeProvider()),
        prv.ChangeNotifierProvider(create: (_) => LoginProvider()),
        prv.ChangeNotifierProvider(create: (_) => LocationPermissionProvider()),
        prv.ChangeNotifierProvider(create: (_) => DashBoardProvider()),
        prv.ChangeNotifierProvider(create: (_) => AddressListProvider()),
        prv.ChangeNotifierProvider(create: (_) => CartControllerProvider()),

        // ============================================
        // EAGER PROVIDERS - Used early in app flow
        // ============================================
        prv.ChangeNotifierProvider(create: (_) => CategoryRestaurantProvider()),
        prv.ChangeNotifierProvider(
          create: (_) => DiscountRestaurantListProvider(),
        ),
        prv.ChangeNotifierProvider(create: (_) => RestaurantListProvider()),
        prv.ChangeNotifierProvider(create: (_) => StoryProvider()),
        prv.ChangeNotifierProvider(create: (_) => AllAdvertisementProvider()),
        prv.ChangeNotifierProvider(create: (_) => CategoryServiceProvider()),
        prv.ChangeNotifierProvider(create: (_) => FavouriteProvider()),
        prv.ChangeNotifierProvider(create: (_) => MartProvider()),
        prv.ChangeNotifierProvider(create: (_) => MartCategoryProvider()),
        prv.ChangeNotifierProvider(create: (_) => MartNavigationProvider()),
        prv.ChangeNotifierProvider(create: (_) => OrderProvider()),
        prv.ChangeNotifierProvider(create: (_) => SearchScreenProvider()),
        prv.ChangeNotifierProvider(create: (_) => CategoryDetailsProvider()),
        prv.ChangeNotifierProvider(create: (_) => MapViewProvider()),
        prv.ChangeNotifierProvider(create: (_) => CategoryViewProvider()),
        prv.ChangeNotifierProvider(create: (_) => BestRestaurantProvider()),
        prv.ChangeNotifierProvider(create: (_) => ViewAllCategoryProvider()),

        // ============================================
        // LAZY PROVIDERS - Screen-specific, only created when accessed
        // Note: Provider package creates these eagerly, but since constructors
        // are lightweight, the real optimization is deferring heavy initFunction() calls
        // ============================================
        prv.ChangeNotifierProvider(create: (_) => ChatProvider()),
        prv.ChangeNotifierProvider(create: (_) => EditProfileProvider()),
        prv.ChangeNotifierProvider(create: (_) => MartEditProfileProvider()),
        prv.ChangeNotifierProvider(create: (_) => LiveTrackingProvider()),
        prv.ChangeNotifierProvider(create: (_) => OrderDetailsProvider()),
        prv.ChangeNotifierProvider(create: (_) => MyProfileProvider()),
        prv.ChangeNotifierProvider(create: (_) => RateProductProvider()),
        prv.ChangeNotifierProvider(create: (_) => RestaurantDetailsProvider()),
        prv.ChangeNotifierProvider(create: (_) => ReviewListProvider()),
        prv.ChangeNotifierProvider(create: (_) => SwiggySearchProvider()),
        prv.ChangeNotifierProvider(create: (_) => MartSearchProvider()),
        prv.ChangeNotifierProvider(create: (_) => OrderPlacingProvider()),
        prv.ChangeNotifierProvider(create: (_) => SignupProvider()),
        prv.ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: _DeferredInitRunner(
        child: GetMaterialApp(
          navigatorKey: GlobalDeeplinkHandler.navigatorKey,
          title: 'JippyMart Customer'.tr,
          debugShowCheckedModeBanner: false,
          // Reduce GetX route/dialog log noise (CLOSE DIALOG, REPLACE ROUTE, NEW ROUTE)
          logWriterCallback: (String text, {bool isError = false}) {
            if (isError) {
              debugPrint(text);
              return;
            }
            final t = text.toUpperCase();
            if (t.contains('[GETX]') &&
                (t.contains('CLOSE DIALOG') ||
                    t.contains('REPLACE ROUTE') ||
                    t.contains('NEW ROUTE'))) {
              return; // skip verbose GetX nav logs
            }
            debugPrint(text);
          },
          localizationsDelegates: const [CountryLocalizations.delegate],
          // Global SafeArea: wraps the Navigator so all routes respect device safe areas
          // (notch, status bar, home indicator, rounded corners).
          builder: (context, child) {
            return EasyLoading.init()(
              context,
              SafeArea(
                // Let screens control top insets so immersive headers can
                // blend with status bar without a separate top strip.
                top: false,
                bottom: true,
                left: true,
                right: true,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          home: const SplashHome(),
        ),
      ),
    );
  }
}
