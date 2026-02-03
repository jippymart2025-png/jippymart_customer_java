// import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/widgets/banner_view_widget.dart';
// import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
// import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/constant/show_toast_dialog.dart';
// import 'package:jippymart_customer/utils/utils/app_constant.dart';
// import 'package:jippymart_customer/models/cart_product_model.dart';
// import 'package:jippymart_customer/models/product_model.dart';
// import 'package:jippymart_customer/models/vendor_model.dart';
// import 'package:jippymart_customer/models/promotion_model.dart';
// import 'package:jippymart_customer/models/BannerModel.dart';
// import 'package:jippymart_customer/services/cart_provider.dart';
// import 'package:jippymart_customer/services/location_service.dart';
// import 'package:jippymart_customer/themes/app_them_data.dart';
// import 'package:jippymart_customer/themes/responsive.dart';
// import 'package:jippymart_customer/utils/fire_store_utils.dart';
// import 'package:jippymart_customer/utils/network_image_widget.dart';
// import 'package:jippymart_customer/utils/color_utils.dart';
// import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
// import 'package:jippymart_customer/utils/utils/common.dart';
// import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
// import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
// import 'package:jippymart_customer/themes/custom_dialog_box.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:convert';
// import 'dart:async';
// import 'dart:ui' as ui;
//
// import '../../models/user_model.dart';
// import 'bannerdeals.dart';
//
// class DealsScreen extends StatefulWidget {
//   const DealsScreen({super.key});
//
//   @override
//   State<DealsScreen> createState() => _DealsScreenState();
// }
//
// class _DealsScreenState extends State<DealsScreen> with WidgetsBindingObserver {
//   bool isLoading = true;
//   List<PromotionModel> promotionsList = [];
//   List<BannerModel> dealsBanners = [];
//   static const Duration _networkTimeout = Duration(seconds: 12);
//   String? _currentZoneId;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _currentZoneId = Constant.selectedZone?.id;
//     // Load both promotions and banners simultaneously
//     _loadAllData();
//
//     // Fallback: Ensure banners load when screen becomes visible
//     // This handles cases where zone might not be ready on first load
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Future.delayed(const Duration(milliseconds: 800), () {
//         if (mounted && dealsBanners.isEmpty) {
//           print('[DEALS_SCREEN] Banners empty, retrying load...');
//           _ensureBannersLoaded();
//         }
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       _checkAndReloadIfZoneChanged();
//     }
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     // Check if zone changed when screen becomes visible
//     _checkAndReloadIfZoneChanged();
//   }
//
//   void _checkAndReloadIfZoneChanged() {
//     final newZoneId = Constant.selectedZone?.id;
//     if (newZoneId != null &&
//         newZoneId.isNotEmpty &&
//         newZoneId != _currentZoneId) {
//       print(
//         '[DEALS_SCREEN] Zone changed from $_currentZoneId to $newZoneId, reloading data...',
//       );
//       _currentZoneId = newZoneId;
//       _loadAllData();
//     }
//   }
//
//   /// Fetch current location and detect zone ID
//   Future<String?> _fetchLocationAndDetectZone() async {
//     try {
//       print('[DEALS_SCREEN] Fetching current location...');
//
//       // Get current location
//       final position = await LocationService.getCurrentLocation(
//         showLoader: false,
//         showError: false,
//       );
//
//       if (position == null) {
//         print('[DEALS_SCREEN] Failed to get current location');
//         return null;
//       }
//
//       print(
//         '[DEALS_SCREEN] Location obtained: ${position.latitude}, ${position.longitude}',
//       );
//
//       // Detect zone ID from coordinates
//       final zoneId = await HomeProvider.detectZoneId(
//         position.latitude,
//         position.longitude,
//       );
//
//       if (zoneId != null && zoneId.isNotEmpty) {
//         print('[DEALS_SCREEN] Zone ID detected: $zoneId');
//
//         // Update Constant.selectedLocation with zoneId and location
//         Constant.selectedLocation.location = UserLocation(
//           latitude: position.latitude,
//           longitude: position.longitude,
//         );
//         Constant.selectedLocation.zoneId = zoneId;
//
//         // Try to get full zone info and set Constant.selectedZone
//         // Use getCurrentZone to get full zone model and set it
//         try {
//           final zoneModel = await HomeProvider.getCurrentZone(
//             position.latitude,
//             position.longitude,
//           );
//           if (zoneModel != null &&
//               zoneModel.success == true &&
//               zoneModel.zone != null) {
//             final detectedZone = HomeProvider.convertToOldZoneModel(zoneModel);
//             if (detectedZone != null) {
//               Constant.selectedZone = detectedZone;
//               Constant.isZoneAvailable = zoneModel.isZoneAvailable == true;
//               print(
//                 '[DEALS_SCREEN] Zone set: ${detectedZone.name} (${detectedZone.id})',
//               );
//             }
//           }
//         } catch (e) {
//           print('[DEALS_SCREEN] Error getting full zone info: $e');
//           // Continue with just zoneId
//         }
//
//         return zoneId;
//       } else {
//         print('[DEALS_SCREEN] No zone detected for coordinates');
//         return null;
//       }
//     } catch (e) {
//       print('[DEALS_SCREEN] Error fetching location and detecting zone: $e');
//       return null;
//     }
//   }
//
//   Future<void> _loadAllData() async {
//     setState(() {
//       isLoading = true;
//     });
//
//     try {
//       // Load both promotions and banners in parallel
//       await Future.wait([_loadPromotionsData(), _ensureBannersLoaded()]);
//     } catch (e) {
//       print('Error loading data: $e');
//     } finally {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }
//
//   Future<void> _ensureBannersLoaded() async {
//     try {
//       // Get zoneId from Constant - wait for it with multiple retries
//       String? customerZoneId = Constant.selectedZone?.id;
//
//       // If zoneId is not available, fetch location and detect zone
//       if (customerZoneId == null || customerZoneId.isEmpty) {
//         print(
//           '[DEALS_SCREEN] ZoneId not available, fetching location and detecting zone...',
//         );
//
//         // Try to fetch location and detect zone
//         final zoneIdFromLocation = await _fetchLocationAndDetectZone();
//         if (zoneIdFromLocation != null && zoneIdFromLocation.isNotEmpty) {
//           customerZoneId = zoneIdFromLocation;
//           print(
//             '[DEALS_SCREEN] ZoneId detected from location: $customerZoneId',
//           );
//         } else {
//           // Retry up to 5 times with increasing delays
//           for (int attempt = 1; attempt <= 5; attempt++) {
//             await Future.delayed(Duration(milliseconds: 300 * attempt));
//             customerZoneId = Constant.selectedZone?.id;
//
//             if (customerZoneId != null && customerZoneId.isNotEmpty) {
//               print(
//                 '[DEALS_SCREEN] ZoneId available after $attempt attempt(s)',
//               );
//               break;
//             }
//
//             if (attempt == 5) {
//               print(
//                 '[DEALS_SCREEN] ZoneId still not available after 5 retries',
//               );
//               if (mounted) {
//                 setState(() {
//                   dealsBanners = [];
//                 });
//               }
//               return;
//             }
//           }
//         }
//       }
//
//       // Build URL with zone_id parameter
//       // API: {{baseURL}}menu-items/banners/deals?zone_id={zoneId}
//       String url =
//           '${AppConst.baseUrl}menu-items/banners/deals?zone_id=$customerZoneId';
//       print(
//         '[DEALS_SCREEN] Loading deals banners with zoneId: $customerZoneId',
//       );
//       print('[DEALS_SCREEN] API URL: $url');
//
//       final headers = await getHeaders();
//       final response = await http
//           .get(Uri.parse(url), headers: headers)
//           .timeout(_networkTimeout);
//
//       if (response.statusCode == 200) {
//         final jsonResponse = json.decode(response.body);
//         print('[DEALS_SCREEN] API Response: ${response.body}');
//
//         if (jsonResponse['success'] == true) {
//           List<dynamic> data = jsonResponse['data'];
//           List<BannerModel> banners = data
//               .map((item) => BannerModel.fromJson(item))
//               .toList();
//
//           if (mounted) {
//             setState(() {
//               dealsBanners = banners;
//             });
//             print(
//               '[DEALS_SCREEN] Deals banners loaded successfully: ${banners.length}',
//             );
//           }
//         } else {
//           print('[DEALS_SCREEN] API returned success: false');
//           if (mounted) {
//             setState(() {
//               dealsBanners = [];
//             });
//           }
//         }
//       } else {
//         print('[DEALS_SCREEN] HTTP error: ${response.statusCode}');
//         if (mounted) {
//           setState(() {
//             dealsBanners = [];
//           });
//         }
//       }
//     } on TimeoutException catch (e) {
//       print('[DEALS_SCREEN] Timeout loading deals banners: $e');
//       if (mounted) {
//         setState(() {
//           dealsBanners = [];
//         });
//       }
//     } catch (e) {
//       print('[DEALS_SCREEN] Error loading deals banners: $e');
//       if (mounted) {
//         setState(() {
//           dealsBanners = [];
//         });
//       }
//     }
//   }
//
//   Future<List<PromotionModel>> _sortPromotionsByRestaurantStatus(
//     List<PromotionModel> promotions,
//   ) async {
//     try {
//       // Fetch restaurant statuses in parallel for all promotions
//       final List<MapEntry<PromotionModel, bool>> promotionStatuses =
//           await Future.wait(
//             promotions.map((promo) async {
//               try {
//                 final vendor = await FireStoreUtils.getVendorById(
//                   promo.restaurantId,
//                 );
//                 final isOpen =
//                     vendor != null &&
//                     RestaurantStatusUtils.canAcceptOrders(vendor);
//                 return MapEntry(promo, isOpen);
//               } catch (e) {
//                 // If error loading restaurant, treat as closed
//                 return MapEntry(promo, false);
//               }
//             }),
//           );
//
//       // Sort: open restaurants first (true comes before false when sorting descending)
//       promotionStatuses.sort((a, b) {
//         if (a.value == b.value) return 0;
//         return a.value ? -1 : 1; // true (open) comes before false (closed)
//       });
//
//       // Extract sorted promotions
//       return promotionStatuses.map((entry) => entry.key).toList();
//     } catch (e) {
//       print('[DEALS_SCREEN] Error sorting promotions: $e');
//       // Return unsorted list if sorting fails
//       return promotions;
//     }
//   }
//
//   Future<void> _loadPromotionsData() async {
//     try {
//       // Get zoneId from Constant - wait for it with multiple retries
//       String? selectedZoneId = Constant.selectedZone?.id;
//
//       // If zoneId is not available, fetch location and detect zone
//       if (selectedZoneId == null || selectedZoneId.isEmpty) {
//         print(
//           '[DEALS_SCREEN] ZoneId not available for promotions, fetching location and detecting zone...',
//         );
//
//         // Try to fetch location and detect zone
//         final zoneIdFromLocation = await _fetchLocationAndDetectZone();
//         if (zoneIdFromLocation != null && zoneIdFromLocation.isNotEmpty) {
//           selectedZoneId = zoneIdFromLocation;
//           print(
//             '[DEALS_SCREEN] ZoneId detected from location for promotions: $selectedZoneId',
//           );
//         } else {
//           // Retry up to 5 times with increasing delays
//           for (int attempt = 1; attempt <= 5; attempt++) {
//             await Future.delayed(Duration(milliseconds: 300 * attempt));
//             selectedZoneId = Constant.selectedZone?.id;
//
//             if (selectedZoneId != null && selectedZoneId.isNotEmpty) {
//               print(
//                 '[DEALS_SCREEN] ZoneId available for promotions after $attempt attempt(s)',
//               );
//               break;
//             }
//
//             if (attempt == 5) {
//               print(
//                 '[DEALS_SCREEN] ZoneId still not available after 5 retries for promotions',
//               );
//               if (mounted) {
//                 setState(() {
//                   promotionsList = [];
//                 });
//               }
//               return;
//             }
//           }
//         }
//       }
//
//       // Load promotions with zoneId
//       final promotionsData = await FireStoreUtils.getAllActivePromotions(
//         zoneId: selectedZoneId.toString(),
//       );
//
//       if (mounted) {
//         final unsortedPromotions = promotionsData
//             .map((promo) => PromotionModel.fromJson(promo))
//             .toList();
//
//         // Sort promotions: open restaurants first
//         final sortedPromotions = await _sortPromotionsByRestaurantStatus(
//           unsortedPromotions,
//         );
//
//         setState(() {
//           promotionsList = sortedPromotions;
//         });
//         print(
//           '[DEALS_SCREEN] Promotions loaded successfully: ${promotionsList.length}',
//         );
//       }
//     } catch (e) {
//       print('[DEALS_SCREEN] Error loading promotions: $e');
//       if (mounted) {
//         setState(() {
//           promotionsList = [];
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Listen to HomeProvider changes to detect zone updates
//     final homeProvider = Provider.of<HomeProvider>(context, listen: true);
//
//     // Check if zone changed and reload data
//     final currentZoneId = Constant.selectedZone?.id;
//     if (currentZoneId != null &&
//         currentZoneId.isNotEmpty &&
//         currentZoneId != _currentZoneId) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (mounted) {
//           print(
//             '[DEALS_SCREEN] Zone changed in build: $_currentZoneId -> $currentZoneId, reloading...',
//           );
//           _currentZoneId = currentZoneId;
//           _loadAllData();
//         }
//       });
//     }
//
//     return Scaffold(
//       body: Container(
//         // decoration: BoxDecoration(
//         //   gradient: LinearGradient(
//         //     begin: Alignment.topLeft,
//         //     end: Alignment.bottomRight,
//         //     colors: [
//         //       // Primary color for top half
//         //       Color.fromRGBO(209, 36, 119, 1.0),
//         //       Color.fromRGBO(209, 36, 119, 1.0),
//         //       Color.fromRGBO(209, 36, 119, 1.0),
//         //       // Smooth transition
//         //       Color.fromRGBO(209, 36, 119, 1.0),
//         //       Color.fromRGBO(209, 36, 119, 1.0),
//         //       // Light color for bottom half
//         //       Color.fromRGBO(209, 36, 119, 1.0),
//         //     ],
//         //     stops: const [0.0, 0.2, 0.35, 0.5, 0.7, 1.0],
//         //   ),
//         // ),
//         child: Stack(
//           children: [
//             // Decorative circles in background
//             Positioned(
//               top: -100,
//               right: -100,
//               child: Container(
//                 width: 300,
//                 height: 300,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   gradient: RadialGradient(
//                     colors: [
//                       AppThemeData.primary300.withOpacity(0.15),
//                       Colors.transparent,
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             Positioned(
//               top: 150,
//               left: -80,
//               child: Container(
//                 width: 200,
//                 height: 200,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   gradient: RadialGradient(
//                     colors: [
//                       AppThemeData.primary200.withOpacity(0.1),
//                       Colors.transparent,
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             // Main content
//             isLoading
//                 ? Constant.loader()
//                 : promotionsList.isEmpty
//                 ? Constant.showEmptyView(
//                     message: "No deals available at the moment.",
//                   )
//                 : RefreshIndicator(
//                     onRefresh: _loadAllData,
//                     child: CustomScrollView(
//                       physics: const AlwaysScrollableScrollPhysics(),
//                       slivers: [
//                         // Banner Section - Deals Banners
//                         SliverToBoxAdapter(
//                           child: dealsBanners.isEmpty
//                               ? const SizedBox.shrink()
//                               : Padding(
//                                   padding: const EdgeInsets.fromLTRB(
//                                     16,
//                                     16,
//                                     16,
//                                     20,
//                                   ),
//                                   child: DealsBannerView(banners: dealsBanners),
//                                 ),
//                         ),
//                         // Header with count
//                         // SliverToBoxAdapter(
//                         //   child: Padding(
//                         //     padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                         //     child: Row(
//                         //       children: [
//                         //         // Text(
//                         //         //   "All Deals".tr,
//                         //         //   style: TextStyle(
//                         //         //     fontSize: 24,
//                         //         //     fontWeight: FontWeight.bold,
//                         //         //     fontFamily: AppThemeData.bold,
//                         //         //     color: AppThemeData.primary300,
//                         //         //     shadows: [
//                         //         //       Shadow(
//                         //         //         color: Colors.black.withOpacity(0.3),
//                         //         //         blurRadius: 4,
//                         //         //         offset: const Offset(0, 2),
//                         //         //       ),
//                         //         //     ],
//                         //         //   ),
//                         //         // ),
//                         //         const SizedBox(width: 8),
//                         //         Container(
//                         //           padding: const EdgeInsets.symmetric(
//                         //             horizontal: 10,
//                         //             vertical: 4,
//                         //           ),
//                         //           decoration: BoxDecoration(
//                         //             gradient: LinearGradient(
//                         //               colors: [
//                         //                 AppThemeData.primary300,
//                         //                 AppThemeData.primary400,
//                         //               ],
//                         //             ),
//                         //             borderRadius: BorderRadius.circular(12),
//                         //             boxShadow: [
//                         //               BoxShadow(
//                         //                 color: AppThemeData.primary300
//                         //                     .withOpacity(0.4),
//                         //                 blurRadius: 8,
//                         //                 offset: const Offset(0, 2),
//                         //               ),
//                         //             ],
//                         //           ),
//                         //           child: Text(
//                         //             promotionsList.length.toString(),
//                         //             style: TextStyle(
//                         //               fontSize: 14,
//                         //               fontWeight: FontWeight.w600,
//                         //               color: Colors.white,
//                         //               fontFamily: AppThemeData.semiBold,
//                         //             ),
//                         //           ),
//                         //         ),
//                         //       ],
//                         //     ),
//                         //   ),
//                         // ),
//                         // Grid Section - Using fixed height grid items
//                         SliverPadding(
//                           padding: const EdgeInsets.symmetric(horizontal: 12),
//                           sliver: SliverGrid(
//                             gridDelegate:
//                                 const SliverGridDelegateWithFixedCrossAxisCount(
//                                   crossAxisCount: 2,
//                                   crossAxisSpacing: 8,
//                                   mainAxisSpacing: 8,
//                                   childAspectRatio: 0.73, // Reduced even more
//                                 ),
//                             delegate: SliverChildBuilderDelegate((
//                               context,
//                               index,
//                             ) {
//                               return _PromotionCard(
//                                 promotion: promotionsList[index],
//                               );
//                             }, childCount: promotionsList.length),
//                           ),
//                         ),
//                         const SliverToBoxAdapter(child: SizedBox(height: 20)),
//                       ],
//                     ),
//                   ),
//           ],
//         ),
//       ),
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(80),
//         child: _AnimatedAppBar(),
//       ),
//     );
//   }
// }
//
// class _PromotionCard extends StatefulWidget {
//   final PromotionModel promotion;
//
//   const _PromotionCard({required this.promotion});
//
//   @override
//   State<_PromotionCard> createState() => _PromotionCardState();
// }
//
// class _PromotionCardState extends State<_PromotionCard> {
//   ProductModel? _productModel;
//   VendorModel? _vendorModel;
//   bool _isLoadingProduct = true;
//   bool _isLoadingRestaurant = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadProductAndRestaurant();
//   }
//
//   Future<void> _loadProductAndRestaurant() async {
//     // Load both product and restaurant in parallel for better performance
//     await Future.wait([_loadProduct(), _loadRestaurant()]);
//   }
//
//   Future<void> _loadProduct() async {
//     final productId = widget.promotion.productId;
//     if (productId.isNotEmpty) {
//       try {
//         final product = await FireStoreUtils.getProductById(productId);
//         if (mounted) {
//           setState(() {
//             _productModel = product;
//             _isLoadingProduct = false;
//           });
//         }
//       } catch (e) {
//         if (mounted) {
//           setState(() {
//             _isLoadingProduct = false;
//           });
//         }
//       }
//     } else {
//       setState(() {
//         _isLoadingProduct = false;
//       });
//     }
//   }
//
//   Future<void> _loadRestaurant() async {
//     final restaurantId = widget.promotion.restaurantId;
//     if (restaurantId.isNotEmpty) {
//       try {
//         final vendor = await FireStoreUtils.getVendorById(restaurantId);
//         if (mounted) {
//           setState(() {
//             _vendorModel = vendor;
//             _isLoadingRestaurant = false;
//           });
//         }
//       } catch (e) {
//         if (mounted) {
//           setState(() {
//             _isLoadingRestaurant = false;
//           });
//         }
//       }
//     } else {
//       setState(() {
//         _isLoadingRestaurant = false;
//       });
//     }
//   }
//
//   bool get _isRestaurantOpen {
//     if (_vendorModel == null) return true; // Default to open if not loaded yet
//     return RestaurantStatusUtils.canAcceptOrders(_vendorModel!);
//   }
//
//   int _findCartItemQuantity(String productId) {
//     if (productId.isEmpty) return 0;
//
//     final matchingItems = HomeProvider.cartItem.where((cartItem) {
//       if (cartItem.id == null || cartItem.id!.isEmpty) return false;
//       return cartItem.id == productId || cartItem.id!.startsWith('$productId~');
//     }).toList();
//
//     if (matchingItems.isEmpty) return 0;
//
//     return matchingItems.fold<int>(
//       0,
//       (sum, item) => sum + (item.quantity ?? 0),
//     );
//   }
//
//   double _getAverageRating() {
//     if (_productModel == null) return 0.0;
//     if (_productModel!.reviewsCount == null ||
//         _productModel!.reviewsCount! <= 0) {
//       return 0.0;
//     }
//     if (_productModel!.reviewsSum == null) return 0.0;
//     try {
//       final sum = _productModel!.reviewsSum is num
//           ? _productModel!.reviewsSum!.toDouble()
//           : double.tryParse(_productModel!.reviewsSum.toString()) ?? 0.0;
//       final count = _productModel!.reviewsCount!.toDouble();
//       if (count == 0) return 0.0;
//       return sum / count;
//     } catch (e) {
//       return 0.0;
//     }
//   }
//
//   String _formatRoundedPrice(dynamic price) {
//     try {
//       final priceValue = price is num
//           ? price.toDouble()
//           : double.tryParse(price.toString()) ?? 0.0;
//       final roundedPrice = priceValue.round();
//       final symbol = Constant.currencyModel?.symbol ?? '₹';
//       final symbolAtRight = Constant.currencyModel?.symbolAtRight ?? false;
//
//       if (symbolAtRight == true) {
//         return "$roundedPrice $symbol";
//       } else {
//         return "$symbol $roundedPrice";
//       }
//     } catch (e) {
//       return Constant.amountShow(amount: price.toString());
//     }
//   }
//
//   Future<void> _addToCart({required bool isIncrement}) async {
//     // Check if restaurant is open
//     if (!_isRestaurantOpen) {
//       ShowToastDialog.showToast("Restaurant is currently closed".tr);
//       return;
//     }
//
//     final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
//     if (!isLoggedIn) {
//       _showLoginRequiredDialog(context);
//       return;
//     }
//
//     if (_productModel == null) {
//       ShowToastDialog.showToast("Product not available".tr);
//       return;
//     }
//
//     final productId = widget.promotion.productId;
//     final restaurantId = widget.promotion.restaurantId;
//     final specialPrice = widget.promotion.specialPrice;
//     final itemLimit = widget.promotion.itemLimit;
//
//     final currentQty = _findCartItemQuantity(productId);
//
//     if (isIncrement) {
//       // Check limit
//       if (itemLimit > 0 && currentQty >= itemLimit) {
//         ShowToastDialog.showToast(
//           "Maximum $itemLimit items allowed for this promotional offer".tr,
//         );
//         return;
//       }
//
//       // Check stock
//       if ((_productModel!.quantity ?? 0) != -1 &&
//           currentQty >= (_productModel!.quantity ?? 0)) {
//         ShowToastDialog.showToast("Out of stock".tr);
//         return;
//       }
//     }
//
//     // Get vendor model
//     VendorModel? vendorModel;
//     try {
//       vendorModel = await FireStoreUtils.getVendorById(restaurantId);
//       if (vendorModel == null) {
//         ShowToastDialog.showToast("Restaurant not found".tr);
//         return;
//       }
//     } catch (e) {
//       ShowToastDialog.showToast("Error loading restaurant".tr);
//       return;
//     }
//
//     // Calculate price
//     final price = Constant.productCommissionPrice(
//       vendorModel,
//       specialPrice.toString(),
//     );
//     final discountPrice = Constant.productCommissionPrice(
//       vendorModel,
//       _productModel!.price.toString(),
//     );
//
//     final newQuantity = isIncrement ? currentQty + 1 : currentQty - 1;
//
//     // Create cart product
//     final productTitle = widget.promotion.productTitle;
//     final cartProduct = CartProductModel(
//       id: productId,
//       name: _productModel?.name ?? productTitle,
//       photo: _productModel?.photo ?? '',
//       price: price,
//       discountPrice: discountPrice,
//       vendorID: restaurantId,
//       vendorName: vendorModel.title ?? '',
//       categoryId: _productModel?.categoryID ?? '',
//       quantity: newQuantity,
//       extrasPrice: '0',
//       extras: [],
//       variantInfo: null,
//       promoId: productId,
//     );
//
//     // Add/Remove from cart
//     try {
//       final cartProvider = Provider.of<CartProvider>(context, listen: false);
//       if (isIncrement) {
//         final success = await cartProvider.addToCart(
//           context,
//           cartProduct,
//           newQuantity,
//         );
//         if (!success) {
//           ShowToastDialog.showToast("Failed to add to cart".tr);
//         }
//       } else {
//         // For decrement, find the actual cart item (may have variant suffix)
//         final matchingItems = HomeProvider.cartItem.where((item) {
//           if (item.id == null || item.id!.isEmpty) return false;
//           return item.id == productId || item.id!.startsWith('$productId~');
//         }).toList();
//
//         if (matchingItems.isNotEmpty) {
//           final cartItemId = matchingItems.first.id!;
//           if (newQuantity > 0) {
//             // Update quantity - use addToCart to ensure proper update with all fields
//             final updateProduct = CartProductModel(
//               id: cartItemId,
//               name: cartProduct.name,
//               photo: cartProduct.photo,
//               price: cartProduct.price,
//               discountPrice: cartProduct.discountPrice,
//               vendorID: cartProduct.vendorID,
//               vendorName: cartProduct.vendorName,
//               categoryId: cartProduct.categoryId,
//               quantity: newQuantity,
//               extrasPrice: cartProduct.extrasPrice,
//               extras: cartProduct.extras,
//               variantInfo: cartProduct.variantInfo,
//               promoId: cartProduct.promoId,
//             );
//             await cartProvider.addToCart(context, updateProduct, newQuantity);
//           } else {
//             // Remove item completely if quantity reaches 0
//             await cartProvider.updateCartItemQuantity(cartItemId, 0);
//           }
//         } else {
//           ShowToastDialog.showToast("Item not found in cart".tr);
//         }
//       }
//     } catch (e) {
//       print('Error in addToCart: $e');
//       ShowToastDialog.showToast(
//         isIncrement ? "Failed to add to cart".tr : "Failed to update cart".tr,
//       );
//     }
//   }
//
//   void _showLoginRequiredDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return CustomDialogBox(
//           title: "Login Required".tr,
//           descriptions:
//               "Please login to add items to your cart and continue shopping."
//                   .tr,
//           positiveString: "Login".tr,
//           negativeString: "Cancel".tr,
//           positiveClick: () {
//             Get.back();
//             Get.to(() => PhoneNumberScreen());
//           },
//           negativeClick: () {
//             Get.back();
//           },
//           img: Image.asset(
//             'assets/images/ic_launcher.png',
//             height: 50,
//             width: 50,
//           ),
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer3<RestaurantDetailsProvider, HomeProvider, CartProvider>(
//       builder: (context, restaurantDetailsProvider, homeProvider, cartProvider, _) {
//         final productId = widget.promotion.productId;
//         final restaurantId = widget.promotion.restaurantId;
//         final productTitle = widget.promotion.productTitle;
//         final restaurantTitle = widget.promotion.restaurantTitle;
//         final specialPrice = widget.promotion.specialPrice;
//         final itemLimit = widget.promotion.itemLimit;
//
//         final isInCart = _findCartItemQuantity(productId) > 0;
//         final cartQuantity = _findCartItemQuantity(productId);
//
//         String? imageUrl;
//         if (_productModel != null && _productModel!.photo != null) {
//           final photo = _productModel!.photo!.trim();
//           if (photo.isNotEmpty &&
//               photo != 'null' &&
//               photo != 'Null' &&
//               photo != 'NULL' &&
//               (photo.startsWith('http://') || photo.startsWith('https://'))) {
//             try {
//               final uri = Uri.parse(photo);
//               if (uri.hasScheme && uri.hasAuthority) {
//                 imageUrl = photo;
//               }
//             } catch (e) {
//               imageUrl = null;
//             }
//           }
//         }
//
//         final isRestaurantClosed = !_isRestaurantOpen;
//
//         return Opacity(
//           opacity: isRestaurantClosed ? 0.5 : 1.0,
//           child: Container(
//             decoration: BoxDecoration(
//               color: AppThemeData.surface,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: ColorUtils.withOpacity(Colors.black, 0.08),
//                   blurRadius: 8,
//                   spreadRadius: 1,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Stack(
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Product Image Section - Smaller fixed height
//                     Container(
//                       height: 110, // Reduced to 110px
//                       width: double.infinity,
//                       child: Stack(
//                         children: [
//                           ClipRRect(
//                             borderRadius: const BorderRadius.only(
//                               topLeft: Radius.circular(16),
//                               topRight: Radius.circular(16),
//                             ),
//                             child: Container(
//                               width: double.infinity,
//                               height: double.infinity,
//                               color: AppThemeData.grey100,
//                               child: _isLoadingProduct
//                                   ? Container(
//                                       color: AppThemeData.grey100,
//                                       child: Center(
//                                         child: CircularProgressIndicator(
//                                           strokeWidth: 2,
//                                           color: AppThemeData.primary300,
//                                         ),
//                                       ),
//                                     )
//                                   : imageUrl != null && imageUrl.isNotEmpty
//                                   ? NetworkImageWidget(
//                                       imageUrl: imageUrl,
//                                       width: double.infinity,
//                                       height: double.infinity,
//                                       fit: BoxFit.cover,
//                                     )
//                                   : Container(
//                                       color: AppThemeData.primary50,
//                                       child: Center(
//                                         child: Icon(
//                                           Icons.local_offer,
//                                           size: 30,
//                                           color: AppThemeData.primary300,
//                                         ),
//                                       ),
//                                     ),
//                             ),
//                           ),
//                           // Vegetarian/Non-Vegetarian Indicator
//                           if (_productModel != null)
//                             Positioned(
//                               top: 6,
//                               left: 6,
//                               child: Container(
//                                 width: 14,
//                                 height: 14,
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(3),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.black.withOpacity(0.1),
//                                       blurRadius: 3,
//                                     ),
//                                   ],
//                                 ),
//                                 child: Center(
//                                   child: (_productModel!.veg == true)
//                                       ? Container(
//                                           width: 9,
//                                           height: 9,
//                                           decoration: BoxDecoration(
//                                             color: Colors.green,
//                                             borderRadius: BorderRadius.circular(
//                                               2,
//                                             ),
//                                           ),
//                                         )
//                                       : Container(
//                                           width: 9,
//                                           height: 9,
//                                           decoration: BoxDecoration(
//                                             color: Colors.red,
//                                             borderRadius: BorderRadius.circular(
//                                               2,
//                                             ),
//                                           ),
//                                         ),
//                                 ),
//                               ),
//                             ),
//                           // Item Limit Badge
//                           if (itemLimit > 0)
//                             Positioned(
//                               top: 6,
//                               right: 6,
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 5,
//                                   vertical: 2,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Colors.red,
//                                   borderRadius: BorderRadius.circular(6),
//                                 ),
//                                 child: Text(
//                                   "Limit $itemLimit".tr,
//                                   style: TextStyle(
//                                     fontSize: 8,
//                                     color: Colors.white,
//                                     fontFamily: AppThemeData.semiBold,
//                                     fontWeight: FontWeight.w700,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                     // Content Section - Use constrained box with limited height
//                     Container(
//                       height: 110,
//                       // Increased height to accommodate restaurant title
//                       padding: const EdgeInsets.all(8),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           // Product Title - Single line with ellipsis
//                           Text(
//                             productTitle,
//                             style: TextStyle(
//                               color: AppThemeData.grey900,
//                               fontSize: 13,
//                               fontWeight: FontWeight.w700,
//                               fontFamily: AppThemeData.bold,
//                               height: 1.2,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//
//                           const SizedBox(height: 3),
//
//                           // Restaurant Title - Single line with ellipsis
//                           if (restaurantTitle.isNotEmpty)
//                             Text(
//                               restaurantTitle,
//                               style: TextStyle(
//                                 color: AppThemeData.grey600,
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.w500,
//                                 fontFamily: AppThemeData.regular,
//                                 height: 1.2,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//
//                           const SizedBox(height: 6),
//
//                           // Delivery Time - Always visible on all cards
//                           Text(
//                             "20-30 mins".tr,
//                             style: TextStyle(
//                               fontSize: 9,
//                               color: AppThemeData.grey500,
//                               fontFamily: AppThemeData.regular,
//                             ),
//                           ),
//
//                           // Spacer to push price to bottom
//                           // const Spacer(),
//
//                           // Price and Add Button Row - ALWAYS VISIBLE
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             crossAxisAlignment: CrossAxisAlignment.end,
//                             children: [
//                               // Price Section
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Row(
//                                       children: [
//                                         if (_productModel != null &&
//                                             _productModel!.price != null &&
//                                             _productModel!.price!.isNotEmpty)
//                                           Text(
//                                             _formatRoundedPrice(
//                                               _productModel!.price,
//                                             ),
//                                             style: TextStyle(
//                                               fontSize: 10,
//                                               color: AppThemeData.grey500,
//                                               fontFamily: AppThemeData.regular,
//                                               decoration:
//                                                   TextDecoration.lineThrough,
//                                             ),
//                                           ),
//                                         if (_productModel != null &&
//                                             _productModel!.price != null &&
//                                             _productModel!.price!.isNotEmpty)
//                                           const SizedBox(width: 4),
//                                         Text(
//                                           _formatRoundedPrice(specialPrice),
//                                           style: TextStyle(
//                                             fontSize: 14,
//                                             color: AppThemeData.grey900,
//                                             fontFamily: AppThemeData.bold,
//                                             fontWeight: FontWeight.w800,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     // Discount Percentage - Only if original price exists
//                                     if (_productModel != null &&
//                                         _productModel!.price != null &&
//                                         _productModel!.price!.isNotEmpty &&
//                                         _productModel!.price!
//                                             .toString()
//                                             .isNotEmpty)
//                                       Padding(
//                                         padding: const EdgeInsets.only(top: 1),
//                                         child: Container(
//                                           padding: const EdgeInsets.symmetric(
//                                             horizontal: 4,
//                                             vertical: 1,
//                                           ),
//                                           decoration: BoxDecoration(
//                                             color: Colors.green.shade50,
//                                             borderRadius: BorderRadius.circular(
//                                               3,
//                                             ),
//                                           ),
//                                           child: Text(
//                                             _calculateDiscountPercentage(
//                                               _productModel!.price,
//                                               specialPrice,
//                                             ),
//                                             style: TextStyle(
//                                               fontSize: 8,
//                                               color: Colors.green.shade700,
//                                               fontFamily: AppThemeData.semiBold,
//                                               fontWeight: FontWeight.w600,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(width: 4),
//
//                               // Add/Remove Button - Shows + and - when item is in cart
//                               isInCart
//                                   ? Container(
//                                       height: 28,
//                                       decoration: BoxDecoration(
//                                         color: isRestaurantClosed
//                                             ? AppThemeData.grey400
//                                             : AppThemeData.primary300,
//                                         borderRadius: BorderRadius.circular(8),
//                                         boxShadow: [
//                                           BoxShadow(
//                                             color:
//                                                 (isRestaurantClosed
//                                                         ? AppThemeData.grey400
//                                                         : AppThemeData
//                                                               .primary300)
//                                                     .withOpacity(0.3),
//                                             blurRadius: 3,
//                                             offset: const Offset(0, 1),
//                                           ),
//                                         ],
//                                       ),
//                                       child: Row(
//                                         mainAxisSize: MainAxisSize.min,
//                                         children: [
//                                           // Minus button
//                                           Material(
//                                             color: Colors.transparent,
//                                             child: InkWell(
//                                               onTap: isRestaurantClosed
//                                                   ? null
//                                                   : () => _addToCart(
//                                                       isIncrement: false,
//                                                     ),
//                                               borderRadius:
//                                                   const BorderRadius.only(
//                                                     topLeft: Radius.circular(8),
//                                                     bottomLeft: Radius.circular(
//                                                       8,
//                                                     ),
//                                                   ),
//                                               child: Container(
//                                                 width: 28,
//                                                 height: 28,
//                                                 alignment: Alignment.center,
//                                                 child: Icon(
//                                                   Icons.remove,
//                                                   size: 16,
//                                                   color: Colors.white,
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                           // Quantity display
//                                           Container(
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal: 8,
//                                             ),
//                                             child: Text(
//                                               cartQuantity.toString(),
//                                               style: TextStyle(
//                                                 fontSize: 13,
//                                                 fontFamily: AppThemeData.bold,
//                                                 fontWeight: FontWeight.w800,
//                                                 color: Colors.white,
//                                               ),
//                                             ),
//                                           ),
//                                           // Plus button
//                                           Material(
//                                             color: Colors.transparent,
//                                             child: InkWell(
//                                               onTap: isRestaurantClosed
//                                                   ? null
//                                                   : () => _addToCart(
//                                                       isIncrement: true,
//                                                     ),
//                                               borderRadius:
//                                                   const BorderRadius.only(
//                                                     topRight: Radius.circular(
//                                                       8,
//                                                     ),
//                                                     bottomRight:
//                                                         Radius.circular(8),
//                                                   ),
//                                               child: Container(
//                                                 width: 28,
//                                                 height: 28,
//                                                 alignment: Alignment.center,
//                                                 child: Icon(
//                                                   Icons.add,
//                                                   size: 16,
//                                                   color: Colors.white,
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     )
//                                   : Container(
//                                       height: 28,
//                                       width: 28,
//                                       decoration: BoxDecoration(
//                                         color: isRestaurantClosed
//                                             ? AppThemeData.grey400
//                                             : AppThemeData.primary300,
//                                         borderRadius: BorderRadius.circular(8),
//                                         boxShadow: [
//                                           BoxShadow(
//                                             color:
//                                                 (isRestaurantClosed
//                                                         ? AppThemeData.grey400
//                                                         : AppThemeData
//                                                               .primary300)
//                                                     .withOpacity(0.3),
//                                             blurRadius: 3,
//                                             offset: const Offset(0, 1),
//                                           ),
//                                         ],
//                                       ),
//                                       child: Material(
//                                         color: Colors.transparent,
//                                         child: InkWell(
//                                           onTap: isRestaurantClosed
//                                               ? null
//                                               : () => _addToCart(
//                                                   isIncrement: true,
//                                                 ),
//                                           borderRadius: BorderRadius.circular(
//                                             8,
//                                           ),
//                                           child: Center(
//                                             child: Icon(
//                                               Icons.add,
//                                               size: 16,
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 // Gray overlay when restaurant is closed
//                 if (isRestaurantClosed)
//                   Positioned.fill(
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: Colors.grey.withOpacity(0.3),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Center(
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.black.withOpacity(0.7),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Text(
//                             "Restaurant Closed".tr,
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 11,
//                               fontWeight: FontWeight.bold,
//                               fontFamily: AppThemeData.bold,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   String _calculateDiscountPercentage(
//     dynamic originalPrice,
//     dynamic specialPrice,
//   ) {
//     try {
//       final original = originalPrice is num
//           ? originalPrice.toDouble()
//           : double.tryParse(originalPrice.toString()) ?? 0.0;
//       final special = specialPrice is num
//           ? specialPrice.toDouble()
//           : double.tryParse(specialPrice.toString()) ?? 0.0;
//
//       if (original <= 0 || original <= special) return '';
//
//       final discountPercent = ((original - special) / original * 100).round();
//       return discountPercent > 0 ? '$discountPercent% OFF' : '';
//     } catch (e) {
//       return '';
//     }
//   }
// }
//
// // Animated AppBar with gradient and animations
// class _AnimatedAppBar extends StatefulWidget {
//   const _AnimatedAppBar();
//
//   @override
//   State<_AnimatedAppBar> createState() => _AnimatedAppBarState();
// }
//
// class _AnimatedAppBarState extends State<_AnimatedAppBar>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _slideAnimation;
//   late Animation<double> _scaleAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     );
//
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
//       ),
//     );
//
//     _slideAnimation = Tween<double>(begin: -30.0, end: 0.0).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
//       ),
//     );
//
//     _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
//       ),
//     );
//
//     _controller.forward();
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             Color.fromRGBO(209, 36, 119, 1.0),
//             Color.fromRGBO(209, 36, 119, 0.95),
//             Color.fromRGBO(209, 36, 119, 0.9),
//           ],
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Color.fromRGBO(209, 36, 119, 0.3),
//             blurRadius: 20,
//             spreadRadius: 2,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           child: Row(
//             children: [
//               // Animated back button
//               AnimatedBuilder(
//                 animation: _scaleAnimation,
//                 builder: (context, child) {
//                   return Transform.scale(
//                     scale: _scaleAnimation.value,
//                     // child: Container(
//                     //   width: 40,
//                     //   height: 40,
//                     //   decoration: BoxDecoration(
//                     //     color: Colors.white.withOpacity(0.2),
//                     //     shape: BoxShape.circle,
//                     //     border: Border.all(
//                     //       color: Colors.white.withOpacity(0.3),
//                     //       width: 1.5,
//                     //     ),
//                     //   ),
//                     //   // child: IconButton(
//                     //   //   icon: const Icon(Icons.arrow_back_ios_new),
//                     //   //   color: Colors.white,
//                     //   //   iconSize: 18,
//                     //   //   onPressed: () => Navigator.of(context).pop(),
//                     //   //   padding: EdgeInsets.zero,
//                     //   // ),
//                     // ),
//                   );
//                 },
//               ),
//               const SizedBox(width: 12),
//               // Animated title
//               Expanded(
//                 child: AnimatedBuilder(
//                   animation: _fadeAnimation,
//                   builder: (context, child) {
//                     return Opacity(
//                       opacity: _fadeAnimation.value,
//                       child: Transform.translate(
//                         offset: Offset(0, _slideAnimation.value),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Text(
//                               "Deals Zone".tr,
//                               style: TextStyle(
//                                 fontFamily: AppThemeData.bold,
//                                 fontSize: 22,
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w700,
//                                 letterSpacing: 0.5,
//                                 shadows: [
//                                   Shadow(
//                                     color: Colors.black.withOpacity(0.3),
//                                     blurRadius: 8,
//                                     offset: const Offset(0, 2),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 2),
//                             Container(
//                               height: 3,
//                               width: 60,
//                               decoration: BoxDecoration(
//                                 gradient: LinearGradient(
//                                   colors: [
//                                     Colors.white,
//                                     Colors.white.withOpacity(0.5),
//                                   ],
//                                 ),
//                                 borderRadius: BorderRadius.circular(2),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.white.withOpacity(0.5),
//                                     blurRadius: 4,
//                                     spreadRadius: 1,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               // Animated icon badge
//               // AnimatedBuilder(
//               //   animation: _scaleAnimation,
//               //   builder: (context, child) {
//               //     return Transform.scale(
//               //       scale: _scaleAnimation.value,
//               //       child: Container(
//               //         width: 40,
//               //         height: 40,
//               //         decoration: BoxDecoration(
//               //           gradient: LinearGradient(
//               //             begin: Alignment.topLeft,
//               //             end: Alignment.bottomRight,
//               //             colors: [
//               //               Colors.white.withOpacity(0.3),
//               //               Colors.white.withOpacity(0.1),
//               //             ],
//               //           ),
//               //           shape: BoxShape.circle,
//               //           border: Border.all(
//               //             color: Colors.white.withOpacity(0.3),
//               //             width: 1.5,
//               //           ),
//               //           boxShadow: [
//               //             BoxShadow(
//               //               color: Colors.white.withOpacity(0.2),
//               //               blurRadius: 8,
//               //               spreadRadius: 1,
//               //             ),
//               //           ],
//               //         ),
//               //         child: Icon(
//               //           Icons.local_offer_rounded,
//               //           color: Colors.white,
//               //           size: 20,
//               //         ),
//               //       ),
//               //     );
//               //   },
//               // ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // Custom banner view for deals screen

import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/models/promotion_model.dart';
import 'package:jippymart_customer/models/BannerModel.dart';
import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:jippymart_customer/services/location_service.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/color_utils.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/themes/custom_dialog_box.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:async';

import '../../models/user_model.dart';
import 'bannerdeals.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  List<PromotionModel> _promotionsList = [];
  List<BannerModel> _dealsBanners = [];
  String? _currentZoneId;

  // Performance optimizations
  static const Duration _networkTimeout = Duration(seconds: 10);
  static const Duration _cacheDuration = Duration(minutes: 3);
  final Map<String, ProductModel> _productCache = {};
  final Map<String, VendorModel> _vendorCache = {};
  final Map<String, bool> _restaurantStatusCache = {};
  DateTime? _lastLoadTime;
  int _retryCount = 0;
  static const int _maxRetries = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentZoneId = Constant.selectedZone?.id;

    // Use cache-first approach
    _loadAllDataWithCache();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check zone when screen becomes visible (e.g. switching tabs, zone changed elsewhere)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndReloadIfZoneChanged();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndReloadIfZoneChanged();
    }
  }

  void _checkAndReloadIfZoneChanged() {
    final newZoneId = Constant.selectedZone?.id;
    if (newZoneId != null &&
        newZoneId.isNotEmpty &&
        newZoneId != _currentZoneId) {
      _currentZoneId = newZoneId;
      _productCache.clear();
      _vendorCache.clear();
      _restaurantStatusCache.clear();
      _loadAllData();
    }
  }

  Future<void> _loadAllDataWithCache() async {
    final now = DateTime.now();
    if (_lastLoadTime != null &&
        now.difference(_lastLoadTime!) < _cacheDuration) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    await _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (_isLoading && _retryCount > 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load banners first (fastest)
      await _loadDealsBanners();

      // Then load promotions
      await _loadPromotionsData();

      _lastLoadTime = DateTime.now();
      _retryCount = 0;
    } catch (e) {
      print('Error loading data: $e');
      if (_retryCount < _maxRetries) {
        _retryCount++;
        await Future.delayed(Duration(seconds: _retryCount));
        if (mounted) {
          await _loadAllData();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDealsBanners() async {
    try {
      String? zoneId = _currentZoneId;

      if (zoneId == null || zoneId.isEmpty) {
        zoneId = await _getCurrentZoneIdWithRetry();
      }

      if (zoneId == null || zoneId.isEmpty) {
        setState(() {
          _dealsBanners = [];
        });
        return;
      }

      final url = '${AppConst.baseUrl}menu-items/banners/deals?zone_id=$zoneId';
      final headers = await _getHeaders();

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(_networkTimeout);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'] as List;
          final banners = data
              .take(15) // Limit to 15 banners for performance
              .map((item) => BannerModel.fromJson(item))
              .toList();

          setState(() {
            _dealsBanners = banners;
          });
        } else {
          setState(() {
            _dealsBanners = [];
          });
        }
      } else {
        setState(() {
          _dealsBanners = [];
        });
      }
    } on TimeoutException {
      print('[DEALS_SCREEN] Banner load timeout');
      setState(() {
        _dealsBanners = [];
      });
    } catch (e) {
      print('[DEALS_SCREEN] Error loading banners: $e');
      setState(() {
        _dealsBanners = [];
      });
    }
  }

  Future<void> _loadPromotionsData() async {
    try {
      String? zoneId = _currentZoneId;

      if (zoneId == null || zoneId.isEmpty) {
        zoneId = await _getCurrentZoneIdWithRetry();
      }

      if (zoneId == null || zoneId.isEmpty) {
        setState(() {
          _promotionsList = [];
        });
        return;
      }

      final promotionsData = await FireStoreUtils.getAllActivePromotions(
        zoneId: zoneId,
      );

      if (promotionsData.isNotEmpty) {
        final promotions = promotionsData
            .take(100) // Client-side limit for performance
            .map((promo) => PromotionModel.fromJson(promo))
            .toList();

        // Pre-cache vendor IDs
        final vendorIds = promotions
            .map((p) => p.restaurantId)
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();

        await _preCacheVendors(vendorIds);

        final sortedPromotions = await _sortPromotionsByRestaurantStatus(
          promotions,
        );
        setState(() {
          _promotionsList = sortedPromotions;
        });
      } else {
        setState(() {
          _promotionsList = [];
        });
      }
    } catch (e) {
      print('[DEALS_SCREEN] Error loading promotions: $e');
      setState(() {
        _promotionsList = [];
      });
    }
  }

  Future<void> _preCacheVendors(List<String> vendorIds) async {
    if (vendorIds.isEmpty) return;

    for (final vendorId in vendorIds) {
      if (!_vendorCache.containsKey(vendorId)) {
        try {
          final vendor = await FireStoreUtils.getVendorById(vendorId);
          if (vendor != null) {
            _vendorCache[vendorId] = vendor;
            _restaurantStatusCache[vendorId] =
                RestaurantStatusUtils.canAcceptOrders(vendor);
          }
        } catch (e) {
          // Silently continue
        }
      }
    }
  }

  Future<List<PromotionModel>> _sortPromotionsByRestaurantStatus(
    List<PromotionModel> promotions,
  ) async {
    if (promotions.isEmpty) return promotions;

    try {
      final List<MapEntry<PromotionModel, bool>> statuses = [];

      for (final promo in promotions) {
        final restaurantId = promo.restaurantId;
        bool isOpen = true;

        if (_restaurantStatusCache.containsKey(restaurantId)) {
          isOpen = _restaurantStatusCache[restaurantId]!;
        } else if (_vendorCache.containsKey(restaurantId)) {
          final vendor = _vendorCache[restaurantId]!;
          isOpen = RestaurantStatusUtils.canAcceptOrders(vendor);
          _restaurantStatusCache[restaurantId] = isOpen;
        }

        statuses.add(MapEntry(promo, isOpen));
      }

      statuses.sort((a, b) => b.value ? 1 : -1);
      return statuses.map((e) => e.key).toList();
    } catch (e) {
      return promotions;
    }
  }

  Future<String?> _getCurrentZoneIdWithRetry() async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final zoneId = await _getCurrentZoneId();
        if (zoneId != null && zoneId.isNotEmpty) {
          return zoneId;
        }
      } catch (e) {
        if (attempt == 1) {
          print('[DEALS_SCREEN] Failed to get zone after 2 attempts');
        }
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return Constant.selectedZone?.id;
  }

  Future<String?> _getCurrentZoneId() async {
    try {
      final position = await LocationService.getCurrentLocation(
        showLoader: false,
        showError: false,
      );

      if (position != null) {
        final zoneId = await HomeProvider.detectZoneId(
          position.latitude,
          position.longitude,
        );

        if (zoneId != null && zoneId.isNotEmpty) {
          Constant.selectedLocation.location = UserLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          );
          Constant.selectedLocation.zoneId = zoneId;

          try {
            final zoneModel = await HomeProvider.getCurrentZone(
              position.latitude,
              position.longitude,
            );
            if (zoneModel != null &&
                zoneModel.success == true &&
                zoneModel.zone != null) {
              final detectedZone = HomeProvider.convertToOldZoneModel(
                zoneModel,
              );
              if (detectedZone != null) {
                Constant.selectedZone = detectedZone;
                Constant.isZoneAvailable = zoneModel.isZoneAvailable == true;
              }
            }
          } catch (e) {
            // Continue with just zoneId
          }

          return zoneId;
        }
      }
    } catch (e) {
      print('[DEALS_SCREEN] Error getting zone: $e');
    }

    return Constant.selectedZone?.id;
  }

  Future<Map<String, String>> _getHeaders() async {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }

  @override
  Widget build(BuildContext context) {
    // Listen to HomeProvider so we rebuild when zone changes (e.g. address selection)
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _checkAndReloadIfZoneChanged();
          }
        });
        return Scaffold(
          body: Container(
            child: Stack(
          children: [
            // Decorative circles in background - KEPT AS IS
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppThemeData.primary300.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 150,
              left: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppThemeData.primary200.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main content - KEPT AS IS
            _isLoading
                ? Constant.loader()
                : _promotionsList.isEmpty
                ? Constant.showEmptyView(
                    message: "No deals available at the moment.",
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await _loadAllData();
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _dealsBanners.isEmpty
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    20,
                                  ),
                                  child: DealsBannerView(
                                    banners: _dealsBanners,
                                  ),
                                ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 0.73,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              return _PromotionCard(
                                promotion: _promotionsList[index],
                                productCache: _productCache,
                                vendorCache: _vendorCache,
                                restaurantStatusCache: _restaurantStatusCache,
                              );
                            }, childCount: _promotionsList.length),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],
                    ),
                  ),
            ],
            ),
          ),
          appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: _AnimatedAppBar(),
      ),
        );
      },
    );
  }
}

class _PromotionCard extends StatefulWidget {
  final PromotionModel promotion;
  final Map<String, ProductModel> productCache;
  final Map<String, VendorModel> vendorCache;
  final Map<String, bool> restaurantStatusCache;

  const _PromotionCard({
    required this.promotion,
    required this.productCache,
    required this.vendorCache,
    required this.restaurantStatusCache,
  });

  @override
  State<_PromotionCard> createState() => _PromotionCardState();
}

class _PromotionCardState extends State<_PromotionCard> {
  ProductModel? _productModel;
  VendorModel? _vendorModel;
  bool _isRestaurantOpen = true;
  bool _isLoadingProduct = true;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  void _loadCachedData() {
    // Check caches first
    _productModel = widget.productCache[widget.promotion.productId];
    _vendorModel = widget.vendorCache[widget.promotion.restaurantId];

    final restaurantId = widget.promotion.restaurantId;
    if (widget.restaurantStatusCache.containsKey(restaurantId)) {
      _isRestaurantOpen = widget.restaurantStatusCache[restaurantId]!;
    } else if (_vendorModel != null) {
      _isRestaurantOpen = RestaurantStatusUtils.canAcceptOrders(_vendorModel!);
      widget.restaurantStatusCache[restaurantId] = _isRestaurantOpen;
    }

    // Load missing data
    if (_productModel == null && widget.promotion.productId.isNotEmpty) {
      _loadProduct();
    } else {
      _isLoadingProduct = false;
    }

    if (_vendorModel == null && widget.promotion.restaurantId.isNotEmpty) {
      _loadVendor();
    }
  }

  Future<void> _loadProduct() async {
    final productId = widget.promotion.productId;
    if (productId.isEmpty) {
      _isLoadingProduct = false;
      return;
    }

    try {
      final product = await FireStoreUtils.getProductById(productId);
      if (mounted) {
        setState(() {
          _productModel = product;
          _isLoadingProduct = false;
        });
        widget.productCache[productId] = product!;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProduct = false;
        });
      }
    }
  }

  Future<void> _loadVendor() async {
    final restaurantId = widget.promotion.restaurantId;
    if (restaurantId.isEmpty) return;

    try {
      final vendor = await FireStoreUtils.getVendorById(restaurantId);
      if (mounted && vendor != null) {
        setState(() {
          _vendorModel = vendor;
        });
        widget.vendorCache[restaurantId] = vendor;
        widget.restaurantStatusCache[restaurantId] =
            RestaurantStatusUtils.canAcceptOrders(vendor);
      }
    } catch (e) {
      // Silently fail
    }
  }

  int _findCartItemQuantity() {
    final productId = widget.promotion.productId;
    if (productId.isEmpty) return 0;

    final matchingItems = HomeProvider.cartItem.where((cartItem) {
      if (cartItem.id == null || cartItem.id!.isEmpty) return false;
      return cartItem.id == productId || cartItem.id!.startsWith('$productId~');
    }).toList();

    if (matchingItems.isEmpty) return 0;

    return matchingItems.fold<int>(
      0,
      (sum, item) => sum + (item.quantity ?? 0),
    );
  }

  String _formatRoundedPrice(dynamic price) {
    try {
      final priceValue = price is num
          ? price.toDouble()
          : double.tryParse(price.toString()) ?? 0.0;
      final roundedPrice = priceValue.round();
      final symbol = Constant.currencyModel?.symbol ?? '₹';
      final symbolAtRight = Constant.currencyModel?.symbolAtRight ?? false;

      if (symbolAtRight == true) {
        return "$roundedPrice $symbol";
      } else {
        return "$symbol $roundedPrice";
      }
    } catch (e) {
      return Constant.amountShow(amount: price.toString());
    }
  }

  Future<void> _addToCart({required bool isIncrement}) async {
    if (!_isRestaurantOpen) {
      ShowToastDialog.showToast("Restaurant is currently closed".tr);
      return;
    }

    final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
    if (!isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }

    if (_productModel == null) {
      ShowToastDialog.showToast("Product not available".tr);
      return;
    }

    final productId = widget.promotion.productId;
    final restaurantId = widget.promotion.restaurantId;
    final specialPrice = widget.promotion.specialPrice;
    final itemLimit = widget.promotion.itemLimit;
    final currentQty = _findCartItemQuantity();

    if (isIncrement) {
      if (itemLimit > 0 && currentQty >= itemLimit) {
        ShowToastDialog.showToast(
          "Maximum $itemLimit items allowed for this promotional offer".tr,
        );
        return;
      }

      if ((_productModel!.quantity ?? 0) != -1 &&
          currentQty >= (_productModel!.quantity ?? 0)) {
        ShowToastDialog.showToast("Out of stock".tr);
        return;
      }
    }

    // Get vendor model from cache or load
    VendorModel? vendorModel = _vendorModel;
    if (vendorModel == null) {
      try {
        vendorModel = await FireStoreUtils.getVendorById(restaurantId);
        if (vendorModel == null) {
          ShowToastDialog.showToast("Restaurant not found".tr);
          return;
        }
        widget.vendorCache[restaurantId] = vendorModel;
      } catch (e) {
        ShowToastDialog.showToast("Error loading restaurant".tr);
        return;
      }
    }

    // Calculate price
    final price = Constant.productCommissionPrice(
      vendorModel,
      specialPrice.toString(),
    );
    final discountPrice = Constant.productCommissionPrice(
      vendorModel,
      _productModel!.price.toString(),
    );

    final newQuantity = isIncrement ? currentQty + 1 : currentQty - 1;

    // Create cart product
    final cartProduct = CartProductModel(
      id: productId,
      name: _productModel?.name ?? widget.promotion.productTitle,
      photo: _productModel?.photo ?? '',
      price: price,
      discountPrice: discountPrice,
      vendorID: restaurantId,
      vendorName: vendorModel.title ?? '',
      categoryId: _productModel?.categoryID ?? '',
      quantity: newQuantity,
      extrasPrice: '0',
      extras: [],
      variantInfo: null,
      promoId: productId,
    );

    // Add/Remove from cart
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      if (isIncrement) {
        final success = await cartProvider.addToCart(
          context,
          cartProduct,
          newQuantity,
        );
        if (!success) {
          ShowToastDialog.showToast("Failed to add to cart".tr);
        }
      } else {
        final matchingItems = HomeProvider.cartItem.where((item) {
          if (item.id == null || item.id!.isEmpty) return false;
          return item.id == productId || item.id!.startsWith('$productId~');
        }).toList();

        if (matchingItems.isNotEmpty) {
          final cartItemId = matchingItems.first.id!;
          if (newQuantity > 0) {
            final updateProduct = CartProductModel(
              id: cartItemId,
              name: cartProduct.name,
              photo: cartProduct.photo,
              price: cartProduct.price,
              discountPrice: cartProduct.discountPrice,
              vendorID: cartProduct.vendorID,
              vendorName: cartProduct.vendorName,
              categoryId: cartProduct.categoryId,
              quantity: newQuantity,
              extrasPrice: cartProduct.extrasPrice,
              extras: cartProduct.extras,
              variantInfo: cartProduct.variantInfo,
              promoId: cartProduct.promoId,
            );
            await cartProvider.addToCart(context, updateProduct, newQuantity);
          } else {
            await cartProvider.updateCartItemQuantity(cartItemId, 0);
          }
        } else {
          ShowToastDialog.showToast("Item not found in cart".tr);
        }
      }
    } catch (e) {
      ShowToastDialog.showToast(
        isIncrement ? "Failed to add to cart".tr : "Failed to update cart".tr,
      );
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialogBox(
          title: "Login Required".tr,
          descriptions:
              "Please login to add items to your cart and continue shopping."
                  .tr,
          positiveString: "Login".tr,
          negativeString: "Cancel".tr,
          positiveClick: () {
            Get.back();
            Get.to(() => PhoneNumberScreen());
          },
          negativeClick: () {
            Get.back();
          },
          img: Image.asset(
            'assets/images/ic_launcher.png',
            height: 50,
            width: 50,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer for CartProvider to rebuild when cart changes
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final isInCart = _findCartItemQuantity() > 0;
        final cartQuantity = _findCartItemQuantity();
        final isRestaurantClosed = !_isRestaurantOpen;

        return Consumer2<RestaurantDetailsProvider, HomeProvider>(
          builder: (context, restaurantDetailsProvider, homeProvider, _) {
            final specialPrice = widget.promotion.specialPrice;
            final itemLimit = widget.promotion.itemLimit;

            String? imageUrl;
            if (_productModel != null && _productModel!.photo != null) {
              final photo = _productModel!.photo!.trim();
              if (photo.isNotEmpty &&
                  photo != 'null' &&
                  photo != 'Null' &&
                  photo != 'NULL' &&
                  (photo.startsWith('http://') ||
                      photo.startsWith('https://'))) {
                try {
                  final uri = Uri.parse(photo);
                  if (uri.hasScheme && uri.hasAuthority) {
                    imageUrl = photo;
                  }
                } catch (e) {
                  imageUrl = null;
                }
              }
            }

            return Opacity(
              opacity: isRestaurantClosed ? 0.5 : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppThemeData.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: ColorUtils.withOpacity(Colors.black, 0.08),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Product Image Section
                        Container(
                          height: 110,
                          width: double.infinity,
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: AppThemeData.grey100,
                                  child: _isLoadingProduct
                                      ? Container(
                                          color: AppThemeData.grey100,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppThemeData.primary300,
                                            ),
                                          ),
                                        )
                                      : imageUrl != null && imageUrl.isNotEmpty
                                      ? NetworkImageWidget(
                                          imageUrl: imageUrl,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.fill,
                                        )
                                      : Container(
                                          color: AppThemeData.primary50,
                                          child: Center(
                                            child: Icon(
                                              Icons.local_offer,
                                              size: 30,
                                              color: AppThemeData.primary300,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              if (_productModel != null)
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: (_productModel!.veg == true)
                                          ? Container(
                                              width: 9,
                                              height: 9,
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            )
                                          : Container(
                                              width: 9,
                                              height: 9,
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              if (itemLimit > 0)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "Limit $itemLimit".tr,
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.white,
                                        fontFamily: AppThemeData.semiBold,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          height: 110,
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.promotion.productTitle,
                                style: TextStyle(
                                  color: AppThemeData.grey900,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: AppThemeData.bold,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 3),

                              if (widget.promotion.restaurantTitle.isNotEmpty)
                                Text(
                                  widget.promotion.restaurantTitle,
                                  style: TextStyle(
                                    color: AppThemeData.grey600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: AppThemeData.regular,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                              const SizedBox(height: 6),

                              Text(
                                "20-30 mins".tr,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppThemeData.grey500,
                                  fontFamily: AppThemeData.regular,
                                ),
                              ),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            if (_productModel != null &&
                                                _productModel!.price != null &&
                                                _productModel!
                                                    .price!
                                                    .isNotEmpty)
                                              Text(
                                                _formatRoundedPrice(
                                                  _productModel!.price,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: AppThemeData.grey500,
                                                  fontFamily:
                                                      AppThemeData.regular,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                ),
                                              ),
                                            if (_productModel != null &&
                                                _productModel!.price != null &&
                                                _productModel!
                                                    .price!
                                                    .isNotEmpty)
                                              const SizedBox(width: 4),
                                            Text(
                                              _formatRoundedPrice(specialPrice),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppThemeData.grey900,
                                                fontFamily: AppThemeData.bold,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_productModel != null &&
                                            _productModel!.price != null &&
                                            _productModel!.price!.isNotEmpty &&
                                            _productModel!.price!
                                                .toString()
                                                .isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 1,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 1,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                _calculateDiscountPercentage(
                                                  _productModel!.price,
                                                  specialPrice,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  color: Colors.green.shade700,
                                                  fontFamily:
                                                      AppThemeData.semiBold,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),

                                  isInCart
                                      ? Container(
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: isRestaurantClosed
                                                ? AppThemeData.grey400
                                                : AppThemeData.primary300,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    (isRestaurantClosed
                                                            ? AppThemeData
                                                                  .grey400
                                                            : AppThemeData
                                                                  .primary300)
                                                        .withOpacity(0.3),
                                                blurRadius: 3,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Minus button
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: isRestaurantClosed
                                                      ? null
                                                      : () => _addToCart(
                                                          isIncrement: false,
                                                        ),
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(8),
                                                        bottomLeft:
                                                            Radius.circular(8),
                                                      ),
                                                  child: Container(
                                                    width: 28,
                                                    height: 28,
                                                    alignment: Alignment.center,
                                                    child: Icon(
                                                      Icons.remove,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Quantity display
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                                child: Text(
                                                  cartQuantity.toString(),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontFamily:
                                                        AppThemeData.bold,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              // Plus button
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: isRestaurantClosed
                                                      ? null
                                                      : () => _addToCart(
                                                          isIncrement: true,
                                                        ),
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                        topRight:
                                                            Radius.circular(8),
                                                        bottomRight:
                                                            Radius.circular(8),
                                                      ),
                                                  child: Container(
                                                    width: 28,
                                                    height: 28,
                                                    alignment: Alignment.center,
                                                    child: Icon(
                                                      Icons.add,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Container(
                                          height: 28,
                                          width: 28,
                                          decoration: BoxDecoration(
                                            color: isRestaurantClosed
                                                ? AppThemeData.grey400
                                                : AppThemeData.primary300,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    (isRestaurantClosed
                                                            ? AppThemeData
                                                                  .grey400
                                                            : AppThemeData
                                                                  .primary300)
                                                        .withOpacity(0.3),
                                                blurRadius: 3,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: isRestaurantClosed
                                                  ? null
                                                  : () => _addToCart(
                                                      isIncrement: true,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Center(
                                                child: Icon(
                                                  Icons.add,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isRestaurantClosed)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Restaurant Closed".tr,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppThemeData.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _calculateDiscountPercentage(
    dynamic originalPrice,
    dynamic specialPrice,
  ) {
    try {
      final original = originalPrice is num
          ? originalPrice.toDouble()
          : double.tryParse(originalPrice.toString()) ?? 0.0;
      final special = specialPrice is num
          ? specialPrice.toDouble()
          : double.tryParse(specialPrice.toString()) ?? 0.0;

      if (original <= 0 || original <= special) return '';

      final discountPercent = ((original - special) / original * 100).round();
      return discountPercent > 0 ? '$discountPercent% OFF' : '';
    } catch (e) {
      return '';
    }
  }
}

class _AnimatedAppBar extends StatefulWidget {
  const _AnimatedAppBar();

  @override
  State<_AnimatedAppBar> createState() => _AnimatedAppBarState();
}

class _AnimatedAppBarState extends State<_AnimatedAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: -30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(209, 36, 119, 1.0),
            Color.fromRGBO(209, 36, 119, 0.95),
            Color.fromRGBO(209, 36, 119, 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(209, 36, 119, 0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // EXACT SAME as original
              // AnimatedBuilder(
              //   animation: _scaleAnimation,
              //   builder: (context, child) {
              //     return Transform.scale(
              //       scale: _scaleAnimation.value,
              //       child: Container(
              //         width: 40,
              //         height: 40,
              //         decoration: BoxDecoration(
              //           color: Colors.white.withOpacity(0.2),
              //           shape: BoxShape.circle,
              //           border: Border.all(
              //             color: Colors.white.withOpacity(0.3),
              //             width: 1.5,
              //           ),
              //         ),
              //       ),
              //     );
              //   },
              // ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Deals Zone".tr,
                              style: TextStyle(
                                fontFamily: AppThemeData.bold,
                                fontSize: 22,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              height: 3,
                              width: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.white.withOpacity(0.5),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
