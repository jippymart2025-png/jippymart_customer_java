import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:jippymart_customer/app/favourite_screens/provider/favorite_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/AttributesModel.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/coupon_model.dart';
import 'package:jippymart_customer/models/favourite_item_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:jippymart_customer/services/promotional_cache_service.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/performance_monitor.dart';
import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:http/http.dart' as http;

class RestaurantDetailsProvider extends ChangeNotifier {
  final String? scrollToProductId;

  RestaurantDetailsProvider({this.scrollToProductId});

  static Future<List<CouponModel>> getRestaurantCoupons({
    required String restaurantId,
  }) async {
    try {
      String url =
          "${AppConst.baseUrl}coupons/restaurant${restaurantId == "" ? "" : "?resturant_id=$restaurantId"}";
      final response = await http.get(
        Uri.parse(url),
        headers: await getHeaders(),
      );
      print("getRestaurantCoupons ${url}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          List<dynamic> data = responseData['data'];
          return data.map((json) => CouponModel.fromJson(json)).toList();
        } else {
          throw Exception('Failed to load coupons: ${responseData['message']}');
        }
      } else {
        throw Exception(
          'Failed to load coupons. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching coupons: $e');
      rethrow;
    }
  }

  static Future<List<CouponModel>> getCouponsByVendorId(String vendorId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}coupons/restaurant?vendorId=$vendorId'),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          List<dynamic> data = responseData['data'];
          List<CouponModel> allCoupons = data
              .map((json) => CouponModel.fromJson(json))
              .toList();
          return allCoupons
              .where(
                (coupon) =>
                    coupon.resturantId == vendorId ||
                    coupon.resturantId == 'ALL',
              )
              .toList();
        } else {
          throw Exception('Failed to load coupons: ${responseData['message']}');
        }
      } else {
        throw Exception(
          'Failed to load coupons. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching vendor coupons: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getRestaurantProducts({
    required String restaurantId,
    String? search,
    bool? isVeg,
    bool? isNonVeg,
    bool? offerOnly,
  }) async {
    try {
      // Add timeout to prevent hanging
      final Map<String, String> queryParams = {};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (isVeg == true) {
        queryParams['is_veg'] = 'true';
      }
      if (isNonVeg == true) {
        queryParams['is_nonveg'] = 'true';
      }
      if (offerOnly == true) {
        queryParams['offer_only'] = 'true';
      }

      final uri = Uri.parse(
        '${AppConst.baseUrl}restaurants/$restaurantId/product-feed',
      ).replace(queryParameters: queryParams);

      print('🔍 API Call: $uri');

      // Add timeout
      final response = await http
          .get(uri, headers: await getHeaders())
          .timeout(Duration(seconds: 10));

      log(
        'getRestaurantProducts Response for $restaurantId: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          print('✅ Successfully loaded products for restaurant $restaurantId');
          return data['data'];
        } else {
          print('❌ API Error for $restaurantId: ${data['message']}');
          throw Exception('API returned error: ${data['message']}');
        }
      } else {
        print('❌ HTTP Error for $restaurantId: ${response.statusCode}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ API Error for restaurant $restaurantId: $e');
      rethrow;
    }
  }

  // static Future<Map<String, dynamic>> getRestaurantProducts({
  //   required String restaurantId,
  //   String? search,
  //   bool? isVeg,
  //   bool? isNonVeg,
  //   bool? offerOnly,
  // }) async {
  //   try {
  //     // Build query parameters
  //     final Map<String, String> queryParams = {};
  //
  //     if (search != null && search.isNotEmpty) {
  //       queryParams['search'] = search;
  //     }
  //     if (isVeg == true) {
  //       queryParams['is_veg'] = 'true';
  //     }
  //     if (isNonVeg == true) {
  //       queryParams['is_nonveg'] = 'true';
  //     }
  //     if (offerOnly == true) {
  //       queryParams['offer_only'] = 'true';
  //     }
  //
  //     final uri = Uri.parse(
  //       '${AppConst.baseUrl}restaurants/$restaurantId/product-feed',
  //     ).replace(queryParameters: queryParams);
  //
  //     print('🔍 API Call: $uri');
  //     final response = await http.get(uri, headers: await getHeaders());
  //     log('getRestaurantProducts getRestaurantProducts ${response.body}');
  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> data = json.decode(response.body);
  //
  //       if (data['success'] == true) {
  //         return data['data'];
  //       } else {
  //         throw Exception('API returned error: ${data['message']}');
  //       }
  //     } else {
  //       throw Exception('HTTP ${response.statusCode}: ${response.body}');
  //     }
  //   } catch (e) {
  //     print('❌ API Error: $e');
  //     rethrow;
  //   }
  // }

  // Parse categories from API response
  List<VendorCategoryModel> parseCategories(dynamic categoriesData) {
    try {
      print('🔍 Parsing categories data type: ${categoriesData.runtimeType}');

      if (categoriesData is List) {
        return categoriesData.map((categoryJson) {
          try {
            // Handle both Map and other types
            if (categoryJson is Map<String, dynamic>) {
              return VendorCategoryModel.fromJson(categoryJson);
            } else {
              print(
                '⚠️ Unexpected category data type: ${categoryJson.runtimeType}',
              );
              print('⚠️ Category data: $categoryJson');
              return VendorCategoryModel(); // Return empty category
            }
          } catch (e) {
            print('❌ Error parsing category: $e');
            print('❌ Problematic category data: $categoryJson');
            return VendorCategoryModel(); // Return empty category on error
          }
        }).toList();
      } else {
        print('❌ Categories data is not a List: ${categoriesData.runtimeType}');
        return [];
      }
    } catch (e) {
      print('❌ Error in parseCategories: $e');
      return [];
    }
  }

  List<ProductModel> parseProducts(dynamic productsData) {
    try {
      print('🔍 Parsing products data type: ${productsData.runtimeType}');

      if (productsData is List) {
        return productsData.map((productJson) {
          try {
            if (productJson is Map<String, dynamic>) {
              return ProductModel.fromApiJson(productJson);
            } else {
              print(
                '⚠️ Unexpected product data type: ${productJson.runtimeType}',
              );
              print('⚠️ Product data: $productJson');
              return ProductModel(); // Return empty product
            }
          } catch (e) {
            print('❌ Error parsing product: $e');
            print('❌ Problematic product data: $productJson');
            return ProductModel(); // Return empty product on error
          }
        }).toList();
      } else {
        print('❌ Products data is not a List: ${productsData.runtimeType}');
        return [];
      }
    } catch (e) {
      print('❌ Error in parseProducts: $e');
      return [];
    }
  }

  // Filter states
  bool isVag = false;
  bool isNonVag = false;
  bool isOfferFilter = false;
  TextEditingController searchEditingController = TextEditingController();

  // UI states
  bool isLoading = true;
  bool productsLoading = false;
  PageController pageController = PageController();
  int currentPage = 0;

  // Data
  VendorModel vendorModel = VendorModel();
  List<ProductModel> allProductList = [];
  List<ProductModel> productList = [];
  List<VendorCategoryModel> vendorCategoryList = [];
  List<CouponModel> couponList = [];
  List<VendorModel> favouriteList = [];
  List<FavouriteItemModel> favouriteItemList = [];

  // Controllers
  final ScrollController scrollControllerProduct = ScrollController();
  final ScrollController scrollController = ScrollController();
  final CartProvider cartProvider = CartProvider();

  // Category management
  int selectedCategoryIndex = 0;
  final Map<String, GlobalKey> categoryKeys = {};
  Map<String, List<ProductModel>> categoryProductsMap = {};

  // Promotional cache
  bool _promotionalCacheLoaded = false;

  // Favorites management
  List<String> favoriteProductIds = [];
  bool isRestaurantFavorite = false;

  String getCategoryKey(int index) => 'category_$index';

  // Initialize provider
  Future<void> initFunction({required VendorModel vendorModels}) async {
    vendorModel = vendorModels;
    getArgument(vendorModels: vendorModels);
    if (scrollToProductId != null) {
      shouldScrollToProduct = true;
    }
  }

  bool shouldScrollToProduct = false;

  /// Load favorites data
  Future<void> loadFavorites() async {
    try {
      if (Constant.userModel != null) {
        final favoriteRestaurants =
            await FavouriteProvider.getFavouriteRestaurants();
        isRestaurantFavorite = favoriteRestaurants.any(
          (restaurant) => restaurant.id == vendorModel.id,
        );
        // Load favorite items
        final favoriteItems = await FavouriteProvider.getFavouriteFoods();
        favoriteProductIds = favoriteItems
            .map((item) => item.id.toString())
            .toList();

        notifyListeners();
      }
    } catch (e) {
      print('❌ Error loading favorites: $e');
    }
  }

  /// Toggle restaurant favorite
  Future<void> toggleRestaurantFavorite() async {
    try {
      if (Constant.userModel == null) return;

      if (isRestaurantFavorite) {
        // Remove from favorites

        await FavouriteProvider.removeFavouriteRestaurant(
          vendorModel.id.toString(),
        );
        isRestaurantFavorite = false;
      } else {
        await FavouriteProvider.addFavouriteRestaurant(
          vendorModel.id.toString(),
        );
        isRestaurantFavorite = true;
      }
      notifyListeners();
    } catch (e) {
      print('❌ Error toggling restaurant favorite: $e');
      ShowToastDialog.showToast("Failed to update favorites");
    }
  }

  // In restaurant_details_provider.dart - Fix the toggle method
  Future<void> toggleProductFavorite(String productId) async {
    try {
      if (Constant.userModel == null) {
        ShowToastDialog.showToast("Please login to add favorites");
        return;
      }

      // Validate product ID
      if (productId.isEmpty) {
        ShowToastDialog.showToast("Invalid product");
        return;
      }

      if (favoriteProductIds.contains(productId)) {
        // Remove from favorites
        await FavouriteProvider.removeFavouriteFood(
          productId,
        ); // FIXED: was using vendorModel.id instead of productId
        favoriteProductIds.remove(productId);
        ShowToastDialog.showToast("Removed from favorites");
      } else {
        // Add to favorites
        await FavouriteProvider.addFavouriteFood(
          productId,
        ); // FIXED: was using vendorModel.id instead of productId
        favoriteProductIds.add(productId);
        ShowToastDialog.showToast("Added to favorites");
      }
      notifyListeners();
    } catch (e) {
      print('❌ Error toggling product favorite: $e');
      ShowToastDialog.showToast("Failed to update favorites: ${e.toString()}");
    }
  }

  /// Check if product is favorite
  bool isProductFavorite(String productId) {
    return favoriteProductIds.contains(productId);
  }

  /// MAIN METHOD: Get restaurant data with API calls
  Future<void> getArgument({required VendorModel vendorModels}) async {
    try {
      vendorModel = vendorModels;
      isLoading = true;
      notifyListeners();
      cartProvider.cartStream.listen((event) {
        cartItem.clear();
        cartItem.addAll(event);
      });
      animateSlider();
      await _loadCriticalDataInParallel(
        restaurantId: vendorModel.id.toString(),
      );
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      ShowToastDialog.showToast("Failed to load restaurant data");
      notifyListeners();
    }
  }

  /// LOAD PRODUCTS VIA API - COMPLETELY REPLACES FIREBASE
  Future<void> loadProductsViaAPI() async {
    return await PerformanceMonitor.monitorOperation(
      'loadProductsViaAPI',
      () async {
        productsLoading = true;
        notifyListeners();
        try {
          final apiData = await getRestaurantProducts(
            restaurantId: vendorModel.id!,
            search: searchEditingController.text.isNotEmpty
                ? searchEditingController.text
                : null,
            isVeg: isVag,
            isNonVeg: isNonVag,
            offerOnly: isOfferFilter,
          );
          vendorCategoryList = parseCategories(apiData['categories'] ?? []);
          allProductList = parseProducts(apiData['products'] ?? []);
          productList = List.from(allProductList);
          notifyListeners();
          _buildCategoryProductMapping();
        } catch (e) {
          log("loadProductsViaAPI ${e.toString()}");
          allProductList = [];
          productList = [];
          vendorCategoryList = [];
          _buildCategoryProductMapping();
        } finally {
          productsLoading = false;
          notifyListeners();
        }
      },
    );
  }

  /// BUILD CATEGORY-PRODUCT MAPPING
  void _buildCategoryProductMapping() {
    categoryProductsMap.clear();
    categoryKeys.clear();

    for (var product in productList) {
      if (product.categoryID == null || product.categoryID!.isEmpty) continue;

      final categoryId = product.categoryID!;
      if (!categoryProductsMap.containsKey(categoryId)) {
        categoryProductsMap[categoryId] = [];
      }
      categoryProductsMap[categoryId]!.add(product);
    }

    // Create keys for categories
    for (int i = 0; i < vendorCategoryList.length; i++) {
      final categoryKey = getCategoryKey(i);
      categoryKeys[categoryKey] = GlobalKey();
    }
  }

  /// GET PRODUCTS BY CATEGORY
  List<ProductModel> getProductsByCategory(String categoryId) {
    return categoryProductsMap[categoryId] ?? [];
  }

  /// SCROLL TO CATEGORY
  void scrollToCategory(int index) {
    if (!scrollControllerProduct.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final categoryKey = getCategoryKey(index);
        if (categoryKeys.containsKey(categoryKey)) {
          final key = categoryKeys[categoryKey]!;
          final context = key.currentContext;

          if (context != null) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              alignment: 0.1,
            );
          } else {
            _fallbackScrollToCategory(index);
          }
        } else {
          _fallbackScrollToCategory(index);
        }
      } catch (e) {
        _fallbackScrollToCategory(index);
      }
    });
  }

  void _fallbackScrollToCategory(int index) {
    try {
      double estimatedPosition = 0.0;
      for (int i = 0; i < index; i++) {
        if (i < vendorCategoryList.length) {
          final categoryId = vendorCategoryList[i].id.toString();
          final productCount = getProductsByCategory(categoryId).length;
          estimatedPosition += 80.0 + (productCount * 140.0) + 20.0;
        }
      }

      scrollControllerProduct.animateTo(
        estimatedPosition,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      print("DEBUG: Error in fallback scroll: $e");
    }
  }

  /// FILTER METHODS - NOW CALL API DIRECTLY
  void searchProduct(String name) async {
    // Update search controller
    if (name.isEmpty) {
      searchEditingController.clear();
    }

    await loadProductsViaAPI();
  }

  void filterRecord() async {
    // Call API with current filter states
    await loadProductsViaAPI();
  }

  void toggleOfferFilter() {
    isOfferFilter = !isOfferFilter;

    // Reset other filters when offer filter is activated
    if (isOfferFilter) {
      isVag = false;
      isNonVag = false;
    }

    // Call API with updated filters
    filterRecord();
  }

  void clearAllFilters() {
    try {
      // Reset all filter states
      isVag = false;
      isNonVag = false;
      isOfferFilter = false;
      searchEditingController.clear();
      // Call API without filters
      loadProductsViaAPI();
    } catch (e) {
      print('Error in clearAllFilters: $e');
    }
  }

  /// PROMOTIONAL METHODS
  Future<void> _loadPromotionalCache({
    required String productId,
    required String restaurantId,
  }) async {
    if (_promotionalCacheLoaded) return;

    try {
      await PromotionalCacheService.loadRestaurantPromotions(
        restaurantId: vendorModel.id ?? '',
        productId: productId,
      );
      _promotionalCacheLoaded = true;
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error loading promotional cache: $e');
      _promotionalCacheLoaded = false;
    }
  }

  Map<String, dynamic>? _getCachedPromotionalData(
    String productId,
    String restaurantId,
  ) {
    return PromotionalCacheService.getCachedPromotionalData(
      productId,
      restaurantId,
    );
  }

  bool _isPromotionalAvailable(String productId, String restaurantId) {
    return PromotionalCacheService.isPromotionalAvailable(
      productId,
      restaurantId,
    );
  }

  int _getPromotionalLimit(String productId, String restaurantId) {
    return PromotionalCacheService.getPromotionalLimit(productId, restaurantId);
  }

  // **ADD THE MISSING METHODS THAT ARE CAUSING ERRORS**
  int? getPromotionalItemLimit(String productId, String restaurantId) {
    if (!_isPromotionalAvailable(productId, restaurantId)) {
      return null;
    }
    final limit = _getPromotionalLimit(productId, restaurantId);
    return limit > 0 ? limit : null;
  }

  bool isPromotionalItemQuantityAllowed(
    String productId,
    String restaurantId,
    int currentQuantity,
  ) {
    if (currentQuantity <= 0) {
      return true; // Allow decrement
    }

    if (!_isPromotionalAvailable(productId, restaurantId)) {
      return false;
    }

    final limit = _getPromotionalLimit(productId, restaurantId);
    return currentQuantity <= limit;
  }

  Map<String, dynamic>? getActivePromotionForProduct({
    required String productId,
    required String restaurantId,
  }) {
    if (!_promotionalCacheLoaded) {
      _loadPromotionalCache(
        productId: productId,
        restaurantId: restaurantId,
      ); // **BACKGROUND LOADING: Non-blocking**
    }
    // Use cached data instead of Firebase query - INSTANT RESPONSE
    return _getCachedPromotionalData(productId, restaurantId);
  }

  /// PARALLEL DATA LOADING
  Future<void> _loadCriticalDataInParallel({
    required String restaurantId,
  }) async {
    await Future.wait([loadProductsViaAPI(), loadFavorites()]);
    if (Constant.userModel != null) {
      await Future.wait([
        _loadCoupons(restaurantId: restaurantId),
        _loadAttributes(),
      ]);
      notifyListeners();
    } else {
      await _loadAttributes();
    }
  }

  Future<void> _loadCoupons({required String restaurantId}) async {
    try {
      List<CouponModel> apiCoupons = await getRestaurantCoupons(
        restaurantId: restaurantId,
      );
      couponList = apiCoupons.where((coupon) {
        return coupon.isEnabled == true && _isCouponValid(coupon);
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading coupons: $e');
      ShowToastDialog.showToast("Failed to load coupons");
    }
  }

  bool _isCouponValid(CouponModel coupon) {
    if (coupon.expiresAt == null) return true;

    try {
      DateTime expiryDate;
      if (coupon.expiresAt is String) {
        expiryDate = DateTime.parse(coupon.expiresAt);
      } else {
        return true; // If format is unknown, assume valid
      }
      return expiryDate.isAfter(DateTime.now());
    } catch (e) {
      print('Error parsing expiry date: $e');
      return true;
    }
  }

  Future<void> _loadAttributes() async {
    await FireStoreUtils.getAttributes().then((value) {
      attributesList = value;
      notifyListeners();
    });
  }

  void animateSlider() {
    if (vendorModel.photos != null && vendorModel.photos!.isNotEmpty) {
      Timer.periodic(const Duration(seconds: 2), (Timer timer) {
        if (!pageController.hasClients) {
          timer.cancel();
          return;
        }

        if (currentPage < vendorModel.photos!.length - 1) {
          currentPage++;
        } else {
          currentPage = 0;
        }

        try {
          if (pageController.hasClients) {
            pageController.animateToPage(
              currentPage,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn,
            );
          }
        } catch (e) {
          timer.cancel();
        }
      });
    }
  }

  // Restaurant status methods
  bool canAcceptOrders() => RestaurantStatusUtils.canAcceptOrders(vendorModel);

  Map<String, dynamic> getRestaurantStatusInfo() {
    final isOpen = canAcceptOrders();
    return {
      'isOpen': isOpen,
      'statusText': isOpen ? 'OPEN' : 'CLOSED',
      'statusColor': isOpen ? Colors.green : Colors.red,
      'statusIcon': isOpen ? Icons.check_circle : Icons.lock,
      'reason': isOpen ? 'Restaurant is open' : 'Restaurant is closed',
      'withinWorkingHours': isOpen,
      'hasWorkingHours':
          vendorModel.workingHours != null &&
          vendorModel.workingHours!.isNotEmpty,
    };
  }

  // Scroll to product
  void scrollToProductAfterLoad() {
    if (scrollToProductId != null && shouldScrollToProduct) {
      Future.delayed(const Duration(milliseconds: 500), () {
        scrollToProduct(scrollToProductId!);
        shouldScrollToProduct = false;
      });
    }
  }

  void scrollToProduct(String productId) {
    if (scrollController.hasClients) {
      int productIndex = -1;
      for (int i = 0; i < productList.length; i++) {
        if (productList[i].id == productId) {
          productIndex = i;
          break;
        }
      }

      if (productIndex != -1) {
        double scrollPosition = productIndex * 120.0;
        scrollPosition = scrollPosition - 100.0;
        if (scrollPosition < 0) scrollPosition = 0;

        scrollController.animateTo(
          scrollPosition,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  // Cart and product management
  List<AttributesModel> attributesList = <AttributesModel>[];
  List selectedVariants = [];
  List selectedIndexVariants = [];
  List selectedIndexArray = [];
  List selectedAddOns = [];
  int quantity = 1;

  calculatePrice(ProductModel productModel) {
    String mainPrice = "0";
    String variantPrice = "0";
    String adOnsPrice = "0";

    if (productModel.itemAttribute != null) {
      if (productModel.itemAttribute!.variants!
          .where((element) => element.variantSku == selectedVariants.join('-'))
          .isNotEmpty) {
        variantPrice = Constant.productCommissionPrice(
          vendorModel,
          productModel.itemAttribute!.variants!
                  .where(
                    (element) =>
                        element.variantSku == selectedVariants.join('-'),
                  )
                  .first
                  .variantPrice ??
              '0',
        );
      }
    } else {
      String price = Constant.productCommissionPrice(
        vendorModel,
        productModel.price.toString(),
      );
      String disPrice = double.parse(productModel.disPrice.toString()) <= 0
          ? "0"
          : Constant.productCommissionPrice(
              vendorModel,
              productModel.disPrice.toString(),
            );
      if (double.parse(disPrice) <= 0) {
        variantPrice = price;
      } else {
        variantPrice = disPrice;
      }
    }

    for (int i = 0; i < productModel.addOnsPrice!.length; i++) {
      if (selectedAddOns.contains(productModel.addOnsTitle![i]) == true) {
        adOnsPrice =
            (double.parse(adOnsPrice.toString()) +
                    double.parse(
                      Constant.productCommissionPrice(
                        vendorModel,
                        productModel.addOnsPrice![i].toString(),
                      ),
                    ))
                .toString();
      }
    }
    adOnsPrice = (quantity * double.parse(adOnsPrice)).toString();
    mainPrice =
        ((double.parse(variantPrice.toString()) *
                    double.parse(quantity.toString())) +
                double.parse(adOnsPrice.toString()))
            .toString();
    return mainPrice;
  }

  //finded
  addToCart({
    required ProductModel productModel,
    required String price,
    required String discountPrice,
    required bool isIncrement,
    required int quantity,
    VariantInfo? variantInfo,
  }) async {
    if (isIncrement) {
      final promo = _getCachedPromotionalData(
        productModel.id.toString(),
        vendorModel.id.toString(),
      );

      if (promo != null) {
        final isAllowed = isPromotionalItemQuantityAllowed(
          productModel.id.toString() ?? '',
          vendorModel.id.toString() ?? '',
          quantity,
        );

        if (!isAllowed) {
          final limit = getPromotionalItemLimit(
            productModel.id.toString() ?? '',
            vendorModel.id.toString() ?? '',
          );
          ShowToastDialog.showToast(
            "Maximum $limit items allowed for this promotional offer".tr,
          );
          return;
        }
      }
      notifyListeners();
    }
    CartProductModel cartProductModel = CartProductModel();
    String adOnsPrice = "0";
    for (int i = 0; i < productModel.addOnsPrice!.length; i++) {
      if (selectedAddOns.contains(productModel.addOnsTitle![i]) == true &&
          productModel.addOnsPrice![i] != '0') {
        adOnsPrice =
            (double.parse(adOnsPrice.toString()) +
                    double.parse(
                      Constant.productCommissionPrice(
                        vendorModel,
                        productModel.addOnsPrice![i].toString(),
                      ),
                    ))
                .toString();
      }
    }
    notifyListeners();
    if (variantInfo != null) {
      cartProductModel.id =
          "${productModel.id!}~${variantInfo.variantId.toString()}";
      cartProductModel.name = productModel.name!;
      cartProductModel.photo = productModel.photo!;
      cartProductModel.categoryId = productModel.categoryID!;
      cartProductModel.price = price;
      cartProductModel.discountPrice = discountPrice;
      cartProductModel.vendorID = vendorModel.id;
      cartProductModel.vendorName = vendorModel.title;
      cartProductModel.quantity = quantity;
      cartProductModel.variantInfo = variantInfo;
      cartProductModel.extrasPrice = adOnsPrice;
      cartProductModel.extras = selectedAddOns.isEmpty ? [] : selectedAddOns;
      if (isIncrement) {
        final promo = _getCachedPromotionalData(
          productModel.id.toString() ?? '',
          vendorModel.id ?? '',
        );
        if (promo != null) {
          cartProductModel.promoId = promo['product_id'] ?? '';
        }
      }
    } else {
      cartProductModel.id = productModel.id.toString();
      cartProductModel.name = productModel.name!;
      cartProductModel.photo = productModel.photo!;
      cartProductModel.categoryId = productModel.categoryID!;
      cartProductModel.price = price;
      cartProductModel.discountPrice = discountPrice;
      cartProductModel.vendorID = vendorModel.id;
      cartProductModel.vendorName = vendorModel.title;
      cartProductModel.quantity = quantity;
      cartProductModel.variantInfo = VariantInfo();
      cartProductModel.extrasPrice = adOnsPrice;
      cartProductModel.extras = selectedAddOns.isEmpty ? [] : selectedAddOns;
      if (isIncrement) {
        final promo = await FireStoreUtils.getActivePromotionForProduct(
          productId: productModel.id.toString() ?? '',
          restaurantId: vendorModel.id ?? '',
        );
        if (promo != null) {
          cartProductModel.promoId = promo['product_id'] ?? '';
        }
      }
    }
    if (isIncrement) {
      await cartProvider.addToCart(Get.context!, cartProductModel, quantity);
    } else {
      await cartProvider.removeFromCart(cartProductModel, quantity);
    }
    notifyListeners();
    notifyListeners();
  }

  void addProductAndRemoveProductFunction({
    required ProductModel productModel,
    required String price,
    required String disPrice,
  }) {
    if (1 <= (productModel.quantity ?? 0) ||
        (productModel.quantity ?? 0) == -1) {
      final promo = getActivePromotionForProduct(
        productId: productModel.id.toString() ?? '',
        restaurantId: productModel.vendorID ?? '',
      );
      // Check promotional item limit
      if (promo != null) {
        final isAllowed = isPromotionalItemQuantityAllowed(
          productModel.id.toString() ?? '',
          productModel.vendorID ?? '',
          1,
        );
        if (!isAllowed) {
          final limit = getPromotionalItemLimit(
            productModel.id.toString() ?? '',
            productModel.vendorID ?? '',
          );
          ShowToastDialog.showToast(
            "Maximum $limit items allowed for this promotional offer".tr,
          );
          return;
        }
      }
      String finalPrice = price;
      String finalDiscountPrice = disPrice;
      notifyListeners();
      if (promo != null) {
        finalPrice = (promo['special_price'] as num).toString();
        finalDiscountPrice = Constant.productCommissionPrice(
          vendorModel,
          productModel.price.toString(),
        );
      }
      addToCart(
        productModel: productModel,
        price: finalPrice,
        discountPrice: finalDiscountPrice,
        isIncrement: true,
        quantity: 1,
      );
    } else {
      ShowToastDialog.showToast("Out of stock".tr);
    }
  }
}
