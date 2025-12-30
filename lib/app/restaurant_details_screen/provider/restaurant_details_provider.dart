import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:jippymart_customer/app/favourite_screens/provider/favorite_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
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
  String? returnKeyCategories({required int index}) {
    String categoryKey = getCategoryKey(index);
    if (!categoryKeys.containsKey(categoryKey)) {
      categoryKeys[categoryKey] = GlobalKey();
      notifyListeners();
    }
    return categoryKey;
  }

  final String? scrollToProductId;

  RestaurantDetailsProvider({this.scrollToProductId});

  StreamSubscription<List<CartProductModel>>? _cartSubscription;
  Timer? _sliderTimer;

  // FIXED: Better promotion tracking
  bool _promotionsLoaded = false;

  bool get promotionsLoaded => _promotionsLoaded;

  // Track ALL products with promotions
  final Set<String> _allProductsWithPromotions = {};
  final Map<String, Map<String, dynamic>> _promotionDataCache = {};
  final Map<String, int> _promotionLimitCache = {};
  final Map<String, bool> _promotionCheckedCache = {};

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
      print("getRestaurantCoupons ${response.body} ");
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

  static Future<List<CouponModel>> getMartCoupons({
    required String restaurantId,
  }) async {
    try {
      String url =
          "${AppConst.baseUrl}coupons/mart${restaurantId == "" ? "" : "?resturant_id=$restaurantId"}";
      print(" getMartCoupons ${url}");
      final response = await http.get(
        Uri.parse(url),
        headers: await getHeaders(),
      );
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
      print('Error fetching mart coupons: $e');
      rethrow;
    }
  }

  /// OPTIMIZED: Load ALL promotions for restaurant at once
  /// Uses parallel batch processing for faster loading (Android & iOS)
  Future<void> _loadAllPromotionsForRestaurant() async {
    if (_isPromotionalLoading) return;

    _isPromotionalLoading = true;

    final restaurantId = vendorModel.id ?? '';
    if (restaurantId.isEmpty) {
      _isPromotionalLoading = false;
      return;
    }

    print('📱 Loading promotions for restaurant: $restaurantId');

    try {
      // Get all product IDs
      final productIds = allProductList
          .where((p) => p.id != null && p.id!.isNotEmpty)
          .map((p) => p.id!)
          .toList();

      if (productIds.isEmpty) {
        print('📱 No products to check');
        _promotionsLoaded = true;
        _isPromotionalLoading = false;
        return;
      }

      print('📱 Checking ${productIds.length} products');

      // Use optimized bulk loading (parallel batches)
      await PromotionalCacheService.loadAllRestaurantPromotions(
        restaurantId: restaurantId,
        productIds: productIds,
      );

      // Get promotional products
      final promotionalProducts =
          PromotionalCacheService.getPromotionalProductsForRestaurant(
            restaurantId,
          );

      print('✅ Found ${promotionalProducts.length} promotional products');

      // Update cache
      _allProductsWithPromotions.clear();
      _allProductsWithPromotions.addAll(promotionalProducts);

      // Update promotion data cache from service
      for (final productId in promotionalProducts) {
        final cacheKey = '$productId-$restaurantId';
        final data = PromotionalCacheService.getCachedPromotionalData(
          productId,
          restaurantId,
        );
        if (data != null) {
          _promotionDataCache[cacheKey] = data;
          final limit = PromotionalCacheService.getPromotionalLimit(
            productId,
            restaurantId,
          );
          _promotionLimitCache[cacheKey] = limit;
        }
      }

      // Sort promotional items to top
      _sortProductsWithPromotionsFirst();

      _promotionsLoaded = true;

      print('🎯 Promotional items sorted to top');

      // Update UI
      notifyListeners();
    } catch (e) {
      print('❌ Error loading promotions: $e');
      _promotionsLoaded = true;
    } finally {
      _isPromotionalLoading = false;
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

  List<VendorCategoryModel> parseCategories(dynamic categoriesData) {
    try {
      print('🔍 Parsing categories data type: ${categoriesData.runtimeType}');
      if (categoriesData is List) {
        return categoriesData.map((categoryJson) {
          try {
            if (categoryJson is Map<String, dynamic>) {
              return VendorCategoryModel.fromJson(categoryJson);
            } else {
              print(
                '⚠️ Unexpected category data type: ${categoryJson.runtimeType}',
              );
              print('⚠️ Category data: $categoryJson');
              return VendorCategoryModel();
            }
          } catch (e) {
            print('❌ Error parsing category: $e');
            print('❌ Problematic category data: $categoryJson');
            return VendorCategoryModel();
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
              return ProductModel();
            }
          } catch (e) {
            print('❌ Error parsing product: $e');
            print('❌ Problematic product data: $productJson');
            return ProductModel();
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
  bool isSearching = false;
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

  // Search management
  String _lastSearchQuery = '';
  bool _hasInitialData = false;

  // Promotional cache
  bool _isPromotionalLoading = false;

  // Favorites management
  List<String> favoriteProductIds = [];
  bool isRestaurantFavorite = false;

  String getCategoryKey(int index) => 'category_$index';

  // Initialize provider
  Future<void> initFunction({required VendorModel vendorModels}) async {
    searchEditingController.clear();
    isVag = false;
    isNonVag = false;
    isOfferFilter = false;
    vendorModel = vendorModels;
    getArgument(vendorModels: vendorModels);
    if (scrollToProductId != null) {
      shouldScrollToProduct = true;
    }
  }

  /// Load favorites data
  Future<void> loadFavorites() async {
    try {
      if (Constant.userModel != null) {
        final favoriteRestaurants =
            await FavouriteProvider.getFavouriteRestaurants();
        isRestaurantFavorite = favoriteRestaurants.any(
          (restaurant) => restaurant.id == vendorModel.id,
        );
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

  Future<void> toggleProductFavorite(String productId) async {
    try {
      if (Constant.userModel == null) {
        ShowToastDialog.showToast("Please login to add favorites");
        return;
      }

      if (productId.isEmpty) {
        ShowToastDialog.showToast("Invalid product");
        return;
      }

      if (favoriteProductIds.contains(productId)) {
        await FavouriteProvider.removeFavouriteFood(productId);
        favoriteProductIds.remove(productId);
        ShowToastDialog.showToast("Removed from favorites");
      } else {
        await FavouriteProvider.addFavouriteFood(productId);
        favoriteProductIds.add(productId);
        ShowToastDialog.showToast("Added to favourites");
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

  bool shouldScrollToProduct = false;

  /// MAIN METHOD: Get restaurant data with API calls
  Future<void> getArgument({required VendorModel vendorModels}) async {
    try {
      vendorModel = vendorModels;
      isLoading = true;
      notifyListeners();
      _initializeCartStreamListener();
      animateSlider();

      // Clear previous promotion data
      _allProductsWithPromotions.clear();
      _promotionDataCache.clear();
      _promotionCheckedCache.clear();
      _promotionsLoaded = false;

      // Load all data
      await _loadCriticalDataInParallel(
        restaurantId: vendorModel.id.toString(),
      );

      _hasInitialData = true;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      ShowToastDialog.showToast("Failed to load restaurant data");
      notifyListeners();
    }
  }

  void _initializeCartStreamListener() {
    if (_cartSubscription != null) return;
    _cartSubscription = cartProvider.cartStream.listen((event) {
      HomeProvider.cartItem
        ..clear()
        ..addAll(event);
      notifyListeners();
    });
  }

  /// LOAD PRODUCTS VIA API - UPDATED TO SORT PROMOTIONAL ITEMS FIRST
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

          // Initialize product list (will be sorted after promotions load)
          productList = List.from(allProductList);

          // Load promotions immediately in parallel (non-blocking)
          // This starts loading promotions as soon as products are available
          if (vendorModel.id != null && allProductList.isNotEmpty) {
            // Don't await - let it load in background and update UI when done
            _loadAllPromotionsForRestaurant().then((_) {
              // Promotions loaded, UI will update via notifyListeners()
            }).catchError((e) {
              print('❌ Error in promotion loading: $e');
            });
          }

          _hasInitialData = true;
          notifyListeners();
          _buildCategoryProductMapping();

          print('✅ Products loaded: ${allProductList.length} items');
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

  /// FIXED: Load ALL promotions for products
  // Future<void> _loadAllPromotionsForProducts() async {
  //   if (_isPromotionalLoading) return;
  //
  //   _isPromotionalLoading = true;
  //
  //   print('🔄 Loading promotions for ${allProductList.length} products');
  //
  //   try {
  //     final restaurantId = vendorModel.id ?? '';
  //
  //     // Process in small batches for efficiency
  //     const batchSize = 5;
  //     final productBatches = [];
  //
  //     for (int i = 0; i < allProductList.length; i += batchSize) {
  //       final end = i + batchSize > allProductList.length
  //           ? allProductList.length
  //           : i + batchSize;
  //       productBatches.add(allProductList.sublist(i, end));
  //     }
  //
  //     // Process each batch
  //     for (final batch in productBatches) {
  //       await _processPromotionBatch(batch, restaurantId);
  //
  //       // Notify UI after each batch to show progress
  //       _sortProductsWithPromotionsFirst();
  //       notifyListeners();
  //     }
  //
  //     _promotionsLoaded = true;
  //     _promotionalCacheLoaded = true;
  //     _isPromotionalLoading = false;
  //
  //     print(
  //       '✅ ALL promotions loaded: ${_allProductsWithPromotions.length} promotional items',
  //     );
  //   } catch (e) {
  //     print('❌ Error loading promotions: $e');
  //     _isPromotionalLoading = false;
  //     _promotionsLoaded = true; // Mark as loaded even if some failed
  //   }
  // }

  /// FIXED: Sort products with promotions FIRST
  void _sortProductsWithPromotionsFirst() {
    if (allProductList.isEmpty) return;

    // Separate products with and without promotions
    final productsWithPromotions = <ProductModel>[];
    final productsWithoutPromotions = <ProductModel>[];

    for (final product in allProductList) {
      final productId = product.id ?? '';
      if (productId.isNotEmpty &&
          _allProductsWithPromotions.contains(productId)) {
        productsWithPromotions.add(product);
      } else {
        productsWithoutPromotions.add(product);
      }
    }

    // Combine with promotional items FIRST
    allProductList = [...productsWithPromotions, ...productsWithoutPromotions];
    productList = List.from(allProductList);

    print(
      '📊 Sorted: ${productsWithPromotions.length} promotional items on top',
    );
  }

  /// BUILD CATEGORY-PRODUCT MAPPING - UPDATED TO SORT PROMOTIONAL ITEMS FIRST
  void _buildCategoryProductMapping() {
    categoryProductsMap.clear();
    categoryKeys.clear();

    // First, sort all products within each category
    for (var product in productList) {
      if (product.categoryID == null || product.categoryID!.isEmpty) continue;

      final categoryId = product.categoryID!;
      if (!categoryProductsMap.containsKey(categoryId)) {
        categoryProductsMap[categoryId] = [];
      }
      categoryProductsMap[categoryId]!.add(product);
    }

    // Sort products within each category (promotional items first)
    for (final categoryId in categoryProductsMap.keys) {
      final products = categoryProductsMap[categoryId]!;
      products.sort((a, b) {
        final aHasPromo = _allProductsWithPromotions.contains(a.id ?? '');
        final bHasPromo = _allProductsWithPromotions.contains(b.id ?? '');

        if (aHasPromo && !bHasPromo) return -1; // a first
        if (!aHasPromo && bHasPromo) return 1; // b first
        return 0; // keep original order
      });
    }

    // Create keys for categories
    for (int i = 0; i < vendorCategoryList.length; i++) {
      final categoryKey = getCategoryKey(i);
      categoryKeys[categoryKey] = GlobalKey();
    }
    notifyListeners();
  }

  /// GET PRODUCTS BY CATEGORY - ALREADY SORTED
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

  Timer? _searchDebounceTimer;

  /// SEARCH PRODUCT
  void searchProduct(String query) async {
    _searchDebounceTimer?.cancel();
    if (query.isEmpty) {
      _lastSearchQuery = '';
      isSearching = false;
      searchEditingController.clear();
      _applyLocalFilters();
      notifyListeners();
      return;
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      _lastSearchQuery = query;
      isSearching = true;
      notifyListeners();
      try {
        final localResults = _performLocalSearch(query);
        if (localResults.isNotEmpty) {
          productList = localResults;
          _buildCategoryProductMapping();
          isSearching = false;
          notifyListeners();
          _performAPISearchInBackground(query);
        } else {
          await _performAPISearch(query);
        }
      } catch (e) {
        print('❌ Search error: $e');
        isSearching = false;
        notifyListeners();
      }
    });
  }

  void _performAPISearchInBackground(String query) async {
    try {
      final apiData = await getRestaurantProducts(
        restaurantId: vendorModel.id!,
        search: query,
        isVeg: isVag,
        isNonVeg: isNonVag,
        offerOnly: isOfferFilter,
      );

      final apiProducts = parseProducts(apiData['products'] ?? []);
      if (_lastSearchQuery == query && apiProducts.isNotEmpty) {
        productList = apiProducts;
        _buildCategoryProductMapping();
        notifyListeners();
        _updateLocalCacheWithSearchResults(apiProducts, query);
      }
    } catch (e) {
      print('❌ Background API search failed: $e');
    }
  }

  Future<void> _performAPISearch(String query) async {
    try {
      final apiData = await getRestaurantProducts(
        restaurantId: vendorModel.id!,
        search: query,
        isVeg: isVag,
        isNonVeg: isNonVag,
        offerOnly: isOfferFilter,
      );

      productList = parseProducts(apiData['products'] ?? []);
      _buildCategoryProductMapping();
      _updateLocalCacheWithSearchResults(productList, query);
    } catch (e) {
      print('❌ API search failed: $e');
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  void _updateLocalCacheWithSearchResults(
    List<ProductModel> newProducts,
    String query,
  ) {
    final existingIds = allProductList.map((p) => p.id).toSet();
    for (final newProduct in newProducts) {
      if (!existingIds.contains(newProduct.id)) {
        allProductList.add(newProduct);
      }
    }
  }

  /// FILTER METHODS
  void filterRecord() async {
    if (_hasInitialData && _lastSearchQuery.isEmpty) {
      _applyLocalFilters();
    } else {
      await loadProductsViaAPI();
    }
  }

  List<ProductModel> _performLocalSearch(String query) {
    if (allProductList.isEmpty || query.isEmpty) return [];

    final searchTerms = query.toLowerCase().split(' ');
    return allProductList.where((product) {
      final productName = product.name?.toLowerCase() ?? '';
      final productDescription = product.description?.toLowerCase() ?? '';
      final categoryTitle = product.categoryTitle?.toLowerCase() ?? '';

      return searchTerms.every(
        (term) =>
            productName.contains(term) ||
            productDescription.contains(term) ||
            categoryTitle.contains(term),
      );
    }).toList();
  }

  void _applyLocalFilters() {
    if (allProductList.isEmpty) {
      productList = [];
      _buildCategoryProductMapping();
      return;
    }
    List<ProductModel> filteredList = List.from(allProductList);

    if (isVag && !isNonVag) {
      filteredList = filteredList
          .where((product) => product.veg == true)
          .toList();
    }

    if (isNonVag && !isVag) {
      filteredList = filteredList
          .where((product) => product.nonveg == true)
          .toList();
    }

    if (isOfferFilter) {
      filteredList = filteredList.where((product) {
        final disPrice = double.tryParse(product.disPrice ?? '0') ?? 0;
        final price = double.tryParse(product.price ?? '0') ?? 0;
        return disPrice > 0 && disPrice < price;
      }).toList();
    }

    if (_lastSearchQuery.isNotEmpty) {
      filteredList = _performLocalSearch(
        _lastSearchQuery,
      ).where((product) => filteredList.contains(product)).toList();
    }

    productList = filteredList;
    _buildCategoryProductMapping();
    notifyListeners();
  }

  void toggleOfferFilter() {
    isOfferFilter = !isOfferFilter;

    if (isOfferFilter) {
      isVag = false;
      isNonVag = false;
    }

    if (_hasInitialData && _lastSearchQuery.isEmpty) {
      _applyLocalFilters();
    } else {
      filterRecord();
    }
  }

  void clearAllFilters() {
    try {
      isVag = false;
      isNonVag = false;
      isOfferFilter = false;
      _lastSearchQuery = '';
      searchEditingController.clear();
      isSearching = false;

      if (_hasInitialData) {
        productList = List.from(allProductList);
        _buildCategoryProductMapping();
        notifyListeners();
      } else {
        loadProductsViaAPI();
      }
    } catch (e) {
      print('Error in clearAllFilters: $e');
    }
  }

  /// PROMOTIONAL METHODS - FIXED
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

  // Get promotional item limit
  int? getPromotionalItemLimit(String productId, String restaurantId) {
    final cacheKey = '$productId-$restaurantId';

    // Check in-memory cache first
    if (_promotionLimitCache.containsKey(cacheKey)) {
      final cachedLimit = _promotionLimitCache[cacheKey]!;
      return cachedLimit > 0 ? cachedLimit : null;
    }

    // Check service
    if (!_isPromotionalAvailable(productId, restaurantId)) {
      return null;
    }

    final limit = _getPromotionalLimit(productId, restaurantId);
    _promotionLimitCache[cacheKey] = limit;
    return limit > 0 ? limit : null;
  }

  bool isPromotionalItemQuantityAllowed(
    String productId,
    String restaurantId,
    int currentQuantity,
  ) {
    if (currentQuantity <= 0) return true;

    if (!_isPromotionalAvailable(productId, restaurantId)) {
      return false;
    }

    final limit = _getPromotionalLimit(productId, restaurantId);
    return currentQuantity <= limit;
  }

  // Get active promotion for product
  Map<String, dynamic>? getActivePromotionForProduct({
    required String productId,
    required String restaurantId,
  }) {
    if (productId.isEmpty || restaurantId.isEmpty) return null;

    final cacheKey = '$productId-$restaurantId';

    // 1. Check in-memory cache
    if (_promotionDataCache.containsKey(cacheKey)) {
      return _promotionDataCache[cacheKey];
    }

    // 2. Check service cache
    final data = _getCachedPromotionalData(productId, restaurantId);
    if (data != null) {
      _promotionDataCache[cacheKey] = data;
      return data;
    }

    return null;
  }

  /// FIXED: Check if product has promotion - RELIABLE VERSION
  bool hasActivePromotion(String productId, String restaurantId) {
    if (productId.isEmpty || restaurantId.isEmpty) return false;

    // 1. Check our complete list of promotions (MOST RELIABLE)
    if (_allProductsWithPromotions.contains(productId)) {
      return true;
    }

    // 2. Check local cache
    if (_promotionCheckedCache.containsKey(productId)) {
      return _promotionCheckedCache[productId] == true;
    }

    // 3. Final fallback to service
    final hasPromo = _isPromotionalAvailable(productId, restaurantId);

    // Cache the result for future use
    _promotionCheckedCache[productId] = hasPromo;
    if (hasPromo) {
      _allProductsWithPromotions.add(productId);
    }

    return hasPromo;
  }

  /// PARALLEL DATA LOADING
  Future<void> _loadCriticalDataInParallel({
    required String restaurantId,
  }) async {
    // Load products first (this will also start promotion loading)
    await loadProductsViaAPI();

    // Load other data in parallel
    await Future.wait([
      loadFavorites(),
      if (Constant.userModel != null) _loadCoupons(restaurantId: restaurantId),
      _loadAttributes(),
    ]);

    notifyListeners();
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
        return true;
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
    _sliderTimer?.cancel();
    if (vendorModel.photos != null && vendorModel.photos!.isNotEmpty) {
      _sliderTimer = Timer.periodic(const Duration(seconds: 2), (Timer timer) {
        if (!pageController.hasClients) {
          timer.cancel();
          if (identical(_sliderTimer, timer)) {
            _sliderTimer = null;
          }
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
          if (identical(_sliderTimer, timer)) {
            _sliderTimer = null;
          }
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

  addToCart({
    required ProductModel productModel,
    required String price,
    required String discountPrice,
    required bool isIncrement,
    required int quantity,
    VariantInfo? variantInfo,
  }) async {
    final productId = productModel.id?.toString() ?? '';
    final vendorId = vendorModel.id?.toString() ?? '';

    if (isIncrement) {
      final cacheKey = '$productId-$vendorId';
      final promo =
          _promotionDataCache[cacheKey] ??
          _getCachedPromotionalData(productId, vendorId);

      if (promo != null) {
        final isAllowed = isPromotionalItemQuantityAllowed(
          productId,
          vendorId,
          quantity,
        );
        if (!isAllowed) {
          final limit = getPromotionalItemLimit(productId, vendorId);
          ShowToastDialog.showToast(
            "Maximum $limit items allowed for this promotional offer".tr,
          );
          return;
        }
      }
    }

    CartProductModel cartProductModel = CartProductModel();
    String adOnsPrice = "0";

    if (productModel.addOnsPrice != null &&
        productModel.addOnsPrice!.isNotEmpty &&
        selectedAddOns.isNotEmpty) {
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
    }

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
        final cacheKey = '$productId-$vendorId';
        final promo =
            _promotionDataCache[cacheKey] ??
            _getCachedPromotionalData(productId, vendorId);
        if (promo != null) {
          cartProductModel.promoId = promo['product_id'] ?? '';
        }
      }
    } else {
      cartProductModel.id = productModel.id.toString();
      cartProductModel.name = productModel.name ?? "";
      cartProductModel.photo = productModel.photo ?? '';
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
        final cacheKey = '$productId-$vendorId';
        final promo =
            _promotionDataCache[cacheKey] ??
            _getCachedPromotionalData(productId, vendorId);
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
  }

  void addProductAndRemoveProductFunction({
    required ProductModel productModel,
    required String price,
    required String disPrice,
  }) {
    final productId = productModel.id?.toString() ?? '';
    final vendorId = productModel.vendorID ?? '';

    if ((productModel.quantity ?? 0) != -1 &&
        (productModel.quantity ?? 0) < 1) {
      ShowToastDialog.showToast("Out of stock".tr);
      return;
    }

    final promo = getActivePromotionForProduct(
      productId: productId,
      restaurantId: vendorId,
    );

    if (promo != null) {
      final isAllowed = isPromotionalItemQuantityAllowed(
        productId,
        vendorId,
        1,
      );
      if (!isAllowed) {
        final limit = getPromotionalItemLimit(productId, vendorId);
        ShowToastDialog.showToast(
          "Maximum $limit items allowed for this promotional offer".tr,
        );
        return;
      }
    }

    String finalPrice = price;
    String finalDiscountPrice = disPrice;
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
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    _sliderTimer?.cancel();
    _searchDebounceTimer?.cancel();
    searchEditingController.dispose();
    scrollController.dispose();
    scrollControllerProduct.dispose();
    pageController.dispose();
    super.dispose();
  }
}
