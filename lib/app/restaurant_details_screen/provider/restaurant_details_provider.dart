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

/// STATIC HELPER METHODS - Moved outside the class
class RestaurantApiHelper {
  static Future<List<CouponModel>> getRestaurantCoupons({
    required String restaurantId,
    required String zoneId,
  }) async {
    try {
      String baseUrl = "${AppConst.baseUrl}coupons/restaurant";

      Map<String, String> queryParams = {'zone_id': zoneId};

      if (restaurantId.isNotEmpty) {
        queryParams['resturant_id'] = restaurantId;
      }

      String url = Uri.parse(
        baseUrl,
      ).replace(queryParameters: queryParams).toString();

      final response = await http.get(
        Uri.parse(url),
        headers: await getHeaders(),
      );

      print("getRestaurantCoupons $url");
      print("getRestaurantCoupons ${response.body}");

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

  // static Future<List<CouponModel>> getRestaurantCoupons({
  //   required String restaurantId,
  // }) async {
  //   try {
  //     String url =
  //         "${AppConst.baseUrl}coupons/restaurant${restaurantId == "" ? "" : "?resturant_id=$restaurantId"}";
  //     final response = await http.get(
  //       Uri.parse(url),
  //       headers: await getHeaders(),
  //     );
  //     print("getRestaurantCoupons ${url}");
  //     print("getRestaurantCoupons ${response.body} ");
  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> responseData = json.decode(response.body);
  //       if (responseData['success'] == true) {
  //         List<dynamic> data = responseData['data'];
  //         return data.map((json) => CouponModel.fromJson(json)).toList();
  //       } else {
  //         throw Exception('Failed to load coupons: ${responseData['message']}');
  //       }
  //     } else {
  //       throw Exception(
  //         'Failed to load coupons. Status code: ${response.statusCode}',
  //       );
  //     }
  //   } catch (e) {
  //     print('Error fetching coupons: $e');
  //     rethrow;
  //   }
  // }

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
}

/// SMART CACHE SYSTEM
class RestaurantCache {
  static final Map<String, RestaurantCacheData> _cache = {};
  static final Duration _cacheDuration = Duration(minutes: 10);

  static RestaurantCacheData? get(String restaurantId) {
    final data = _cache[restaurantId];
    if (data == null) return null;

    if (DateTime.now().difference(data.timestamp) > _cacheDuration) {
      _cache.remove(restaurantId);
      return null;
    }

    return data;
  }

  static void set(String restaurantId, RestaurantCacheData data) {
    _cache[restaurantId] = data.copyWith(timestamp: DateTime.now());
  }

  static void clear(String restaurantId) {
    _cache.remove(restaurantId);
  }

  static void clearAll() {
    _cache.clear();
  }
}

class RestaurantCacheData {
  final String restaurantId;
  final List<ProductModel> products;
  final List<VendorCategoryModel> categories;
  final List<CouponModel> coupons;
  final DateTime timestamp;

  RestaurantCacheData({
    required this.restaurantId,
    required this.products,
    required this.categories,
    required this.coupons,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  RestaurantCacheData copyWith({
    String? restaurantId,
    List<ProductModel>? products,
    List<VendorCategoryModel>? categories,
    List<CouponModel>? coupons,
    DateTime? timestamp,
  }) {
    return RestaurantCacheData(
      restaurantId: restaurantId ?? this.restaurantId,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      coupons: coupons ?? this.coupons,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// OPTIMIZED RESTAURANT DETAILS PROVIDER
class RestaurantDetailsProvider extends ChangeNotifier {
  // Pre-initialize controllers to avoid null checks
  final TextEditingController searchEditingController = TextEditingController();
  final ScrollController scrollControllerProduct = ScrollController();
  final ScrollController scrollController = ScrollController();
  final PageController pageController = PageController();
  final CartProvider cartProvider = CartProvider();

  // State variables with initial values
  bool isLoading = false;
  bool productsLoading = false;
  bool isSearching = false;
  bool isVag = false;
  bool isNonVag = false;
  bool isOfferFilter = false;
  int currentPage = 0;
  int selectedCategoryIndex = 0;
  int quantity = 1;

  // Data collections with initial empty lists
  VendorModel vendorModel = VendorModel();
  List<ProductModel> allProductList = [];
  List<ProductModel> productList = [];
  List<VendorCategoryModel> vendorCategoryList = [];
  List<CouponModel> couponList = [];
  List<AttributesModel> attributesList = [];
  List<FavouriteItemModel> favouriteItemList = [];
  List<String> favoriteProductIds = [];

  // Selection lists
  List<dynamic> selectedVariants = [];
  List<dynamic> selectedIndexVariants = [];
  List<dynamic> selectedIndexArray = [];
  List<dynamic> selectedAddOns = [];

  // Internal state
  bool _hasInitialData = false;
  bool _isRestaurantFavorite = false;
  bool _promotionsLoaded = false;
  bool _isPromotionalLoading = false;
  String _lastSearchQuery = '';
  String? _scrollToProductId;
  bool _shouldScrollToProduct = false;

  // Cache maps
  final Map<String, GlobalKey> categoryKeys =
      {}; // Made public for external access
  final Map<String, List<ProductModel>> _categoryProductsMap = {};
  final Set<String> _allProductsWithPromotions = {};
  final Map<String, Map<String, dynamic>> _promotionDataCache = {};
  final Map<String, int> _promotionLimitCache = {};
  final Map<String, bool> _promotionCheckedCache = {};

  // Controllers
  StreamSubscription<List<CartProductModel>>? _cartSubscription;
  Timer? _sliderTimer;
  Timer? _searchDebounceTimer;

  RestaurantDetailsProvider({String? scrollToProductId})
    : _scrollToProductId = scrollToProductId {
    _shouldScrollToProduct = scrollToProductId != null;
  }

  // Getters
  bool get promotionsLoaded => _promotionsLoaded;

  bool get isRestaurantFavorite => _isRestaurantFavorite;

  /// Getter for public access to categoryKeys
  Map<String, GlobalKey> getCategoryKeys() => Map.from(categoryKeys);

  /// INITIALIZATION - OPTIMIZED WITH CACHE
  /// Keep both methods for compatibility
  Future<void> initFunction({required VendorModel vendorModels}) async {
    await getArgument(vendorModels: vendorModels);
  }

  Future<void> getArgument({required VendorModel vendorModels}) async {
    // Clear previous state and immediately mark as loading so UI shows shimmer
    _clearState();
    isLoading = true;
    notifyListeners();

    vendorModel = vendorModels;

    // Try to load from cache first
    final cachedData = RestaurantCache.get(vendorModel.id ?? '');
    if (cachedData != null) {
      await _loadFromCache(cachedData);
      return;
    }

    // If no cache, load fresh data
    await _loadFreshData();
  }

  void _clearState() {
    searchEditingController.clear();
    isVag = false;
    isNonVag = false;
    isOfferFilter = false;
    _lastSearchQuery = '';
    _allProductsWithPromotions.clear();
    _promotionDataCache.clear();
    _promotionCheckedCache.clear();
    _promotionsLoaded = false;
    _categoryProductsMap.clear();
    categoryKeys.clear();
    allProductList = [];
    productList = [];
    vendorCategoryList = [];
    couponList = [];
    favoriteProductIds = [];
    selectedVariants.clear();
    selectedIndexVariants.clear();
    selectedIndexArray.clear();
    selectedAddOns.clear();
    quantity = 1;
  }

  Future<void> _loadFromCache(RestaurantCacheData cachedData) async {
    isLoading = true;
    notifyListeners();

    try {
      // Load cached data
      vendorCategoryList = cachedData.categories;
      allProductList = cachedData.products;
      productList = List.from(allProductList);
      couponList = cachedData.coupons;

      // Load favorites
      await loadFavorites();

      // Load promotions in background
      _loadAllPromotionsForRestaurant();

      // Initialize UI
      _buildCategoryProductMapping();
      _initializeCartStreamListener();
      animateSlider();

      _hasInitialData = true;
      isLoading = false;
      notifyListeners();

      // Load fresh data in background for updates
      _refreshDataInBackground();
    } catch (e) {
      // If cache fails, load fresh data
      await _loadFreshData();
    }
  }

  Future<void> _loadFreshData() async {
    isLoading = true;
    notifyListeners();

    try {
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
      rethrow;
    }
  }

  Future<void> _refreshDataInBackground() async {
    try {
      final freshData = await _fetchAllRestaurantData(vendorModel.id!);

      // Update cache with fresh data
      RestaurantCache.set(
        vendorModel.id!,
        RestaurantCacheData(
          restaurantId: vendorModel.id!,
          products: freshData.products,
          categories: freshData.categories,
          coupons: freshData.coupons,
        ),
      );

      // Update UI if there are significant changes
      if (_hasSignificantChanges(freshData)) {
        allProductList = freshData.products;
        productList = List.from(allProductList);
        vendorCategoryList = freshData.categories;
        couponList = freshData.coupons;

        _buildCategoryProductMapping();
        notifyListeners();
      }
    } catch (e) {
      print('Background refresh failed: $e');
    }
  }

  bool _hasSignificantChanges(RestaurantCacheData freshData) {
    return allProductList.length != freshData.products.length ||
        vendorCategoryList.length != freshData.categories.length;
  }

  /// PARALLEL DATA LOADING - OPTIMIZED
  Future<void> _loadCriticalDataInParallel({
    required String restaurantId,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        _fetchAllRestaurantData(restaurantId),
        loadFavorites(),
        _loadAttributes(),
      ], eagerError: true);

      final restaurantData = results[0] as RestaurantCacheData;

      // Cache the data
      RestaurantCache.set(restaurantId, restaurantData);

      // Update state
      vendorCategoryList = restaurantData.categories;
      allProductList = restaurantData.products;
      productList = List.from(allProductList);
      couponList = restaurantData.coupons;

      // Load promotions in background (non-blocking)
      _loadAllPromotionsForRestaurant();

      // Initialize UI components
      _initializeCartStreamListener();
      animateSlider();
      _buildCategoryProductMapping();

      print('🚀 Data loaded in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('❌ Parallel loading failed: $e');
      rethrow;
    }
  }

  Future<RestaurantCacheData> _fetchAllRestaurantData(
    String restaurantId,
  ) async {
    try {
      // Use static API helper
      final apiData = await RestaurantApiHelper.getRestaurantProducts(
        restaurantId: restaurantId,
      );

      // Parse data
      final categories = _parseCategories(apiData['categories'] ?? []);
      final products = _parseProducts(apiData['products'] ?? []);

      // Fetch coupons using static helper
      final coupons = await _fetchCoupons(restaurantId);

      return RestaurantCacheData(
        restaurantId: restaurantId,
        products: products,
        categories: categories,
        coupons: coupons,
      );
    } catch (e) {
      print('❌ Error fetching restaurant data: $e');
      rethrow;
    }
  }

  /// OPTIMIZED DATA PARSING
  List<VendorCategoryModel> _parseCategories(dynamic categoriesData) {
    if (categoriesData is! List) return [];

    final categories = <VendorCategoryModel>[];
    for (final item in categoriesData) {
      try {
        if (item is Map<String, dynamic>) {
          categories.add(VendorCategoryModel.fromJson(item));
        }
      } catch (e) {
        print('⚠️ Skipping invalid category: $e');
      }
    }
    return categories;
  }

  List<ProductModel> _parseProducts(dynamic productsData) {
    if (productsData is! List) return [];

    final products = <ProductModel>[];
    for (final item in productsData) {
      try {
        if (item is Map<String, dynamic>) {
          products.add(ProductModel.fromApiJson(item));
        }
      } catch (e) {
        print('⚠️ Skipping invalid product: $e');
      }
    }
    return products;
  }

  Future<List<CouponModel>> _fetchCoupons(String restaurantId) async {
    try {
      final coupons = await RestaurantApiHelper.getRestaurantCoupons(
        restaurantId: restaurantId,
        zoneId: Constant.selectedZone!.id.toString(),
      );

      return coupons
          .where((coupon) => coupon.isEnabled == true && _isCouponValid(coupon))
          .toList();
    } catch (e) {
      print('❌ Error loading coupons: $e');
      return [];
    }
  }

  bool _isCouponValid(CouponModel coupon) {
    if (coupon.expiresAt == null) return true;
    try {
      return DateTime.parse(coupon.expiresAt!).isAfter(DateTime.now());
    } catch (e) {
      return true;
    }
  }

  /// PROMOTION LOADING - OPTIMIZED WITH BATCHING
  Future<void> _loadAllPromotionsForRestaurant() async {
    if (_isPromotionalLoading || _promotionsLoaded) return;

    _isPromotionalLoading = true;

    final restaurantId = vendorModel.id ?? '';
    if (restaurantId.isEmpty || allProductList.isEmpty) {
      _isPromotionalLoading = false;
      _promotionsLoaded = true;
      return;
    }

    try {
      // Get all product IDs
      final productIds = allProductList
          .where((p) => p.id != null && p.id!.isNotEmpty)
          .map((p) => p.id!)
          .toList();

      if (productIds.isEmpty) {
        _promotionsLoaded = true;
        _isPromotionalLoading = false;
        return;
      }

      // Use optimized bulk loading
      await PromotionalCacheService.loadAllRestaurantPromotions(
        restaurantId: restaurantId,
        productIds: productIds,
      );

      // Get promotional products
      final promotionalProducts =
          PromotionalCacheService.getPromotionalProductsForRestaurant(
            restaurantId,
          );

      // Update cache
      _allProductsWithPromotions.clear();
      _allProductsWithPromotions.addAll(promotionalProducts);

      // Pre-cache promotion data
      for (final productId in promotionalProducts) {
        final data = PromotionalCacheService.getCachedPromotionalData(
          productId,
          restaurantId,
        );
        if (data != null) {
          final cacheKey = '$productId-$restaurantId';
          _promotionDataCache[cacheKey] = data;
          final limit = PromotionalCacheService.getPromotionalLimit(
            productId,
            restaurantId,
          );
          _promotionLimitCache[cacheKey] = limit;
        }
      }

      _promotionsLoaded = true;

      // Sort promotional items to top
      _sortProductsWithPromotionsFirst();

      // Update UI
      notifyListeners();
    } catch (e) {
      print('❌ Error loading promotions: $e');
      _promotionsLoaded = true; // Mark as loaded even if failed
    } finally {
      _isPromotionalLoading = false;
    }
  }

  void _sortProductsWithPromotionsFirst() {
    if (allProductList.isEmpty) return;

    // Use single pass partitioning
    final promotionalProducts = <ProductModel>[];
    final regularProducts = <ProductModel>[];

    for (final product in allProductList) {
      if (_allProductsWithPromotions.contains(product.id ?? '')) {
        promotionalProducts.add(product);
      } else {
        regularProducts.add(product);
      }
    }

    // Update lists
    allProductList = [...promotionalProducts, ...regularProducts];
    productList = List.from(allProductList);
  }

  /// CATEGORY-PRODUCT MAPPING - OPTIMIZED
  void _buildCategoryProductMapping() {
    _categoryProductsMap.clear();
    // Do NOT clear categoryKeys - replacing GlobalKeys causes duplicate key
    // errors and detached ExpansionTile paint (referenceBox.attached). Only
    // add keys for new indices and remove keys for indices no longer in list.
    final maxIndex = vendorCategoryList.length - 1;
    categoryKeys.removeWhere((key, _) {
      final match = RegExp(r'category_(\d+)').firstMatch(key);
      if (match == null) return false;
      final i = int.tryParse(match.group(1)!);
      return i != null && i > maxIndex;
    });

    // Build map in single pass
    for (var product in productList) {
      if (product.categoryID == null || product.categoryID!.isEmpty) continue;

      final categoryId = product.categoryID!;
      _categoryProductsMap.putIfAbsent(categoryId, () => []).add(product);
    }

    // Sort products within each category (promotional items first)
    for (final categoryId in _categoryProductsMap.keys) {
      final products = _categoryProductsMap[categoryId]!;
      products.sort((a, b) {
        final aHasPromo = _allProductsWithPromotions.contains(a.id ?? '');
        final bHasPromo = _allProductsWithPromotions.contains(b.id ?? '');
        if (aHasPromo && !bHasPromo) return -1;
        if (!aHasPromo && bHasPromo) return 1;
        return 0;
      });
    }

    // Create keys only for indices that don't have one (stable keys avoid
    // reparenting and InkFeature/referenceBox.attached crashes)
    for (int i = 0; i < vendorCategoryList.length; i++) {
      final categoryKey = _getCategoryKey(i);
      if (!categoryKeys.containsKey(categoryKey)) {
        categoryKeys[categoryKey] = GlobalKey();
      }
    }
  }

  String _getCategoryKey(int index) => 'category_$index';

  String? returnKeyCategories({required int index}) {
    String categoryKey = _getCategoryKey(index);
    if (!categoryKeys.containsKey(categoryKey)) {
      categoryKeys[categoryKey] = GlobalKey();
    }
    return categoryKey;
  }

  List<ProductModel> getProductsByCategory(String categoryId) {
    return _categoryProductsMap[categoryId] ?? [];
  }

  /// SEARCH - OPTIMIZED WITH DEBOUNCE AND CACHE
  void searchProduct(String query) {
    _searchDebounceTimer?.cancel();

    if (query.isEmpty) {
      _lastSearchQuery = '';
      isSearching = false;
      _applyLocalFilters();
      return;
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;

    _lastSearchQuery = query;
    isSearching = true;
    notifyListeners();

    // Try local search first
    final localResults = _performLocalSearch(query);
    if (localResults.isNotEmpty) {
      productList = localResults;
      _buildCategoryProductMapping();
      isSearching = false;
      notifyListeners();

      // Do API search in background
      _performAPISearchInBackground(query);
    } else {
      // Fall back to API
      _performAPISearch(query);
    }
  }

  List<ProductModel> _performLocalSearch(String query) {
    if (allProductList.isEmpty) return [];

    final terms = query.toLowerCase().split(' ');
    return allProductList.where((product) {
      final name = product.name?.toLowerCase() ?? '';
      final description = product.description?.toLowerCase() ?? '';
      final category = product.categoryTitle?.toLowerCase() ?? '';

      return terms.every(
        (term) =>
            name.contains(term) ||
            description.contains(term) ||
            category.contains(term),
      );
    }).toList();
  }

  Future<void> _performAPISearch(String query) async {
    try {
      final apiData = await RestaurantApiHelper.getRestaurantProducts(
        restaurantId: vendorModel.id!,
        search: query,
        isVeg: isVag,
        isNonVeg: isNonVag,
        offerOnly: isOfferFilter,
      );

      productList = _parseProducts(apiData['products'] ?? []);
      _buildCategoryProductMapping();
    } catch (e) {
      print('❌ API search failed: $e');
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  Future<void> _performAPISearchInBackground(String query) async {
    try {
      final apiData = await RestaurantApiHelper.getRestaurantProducts(
        restaurantId: vendorModel.id!,
        search: query,
        isVeg: isVag,
        isNonVeg: isNonVag,
        offerOnly: isOfferFilter,
      );

      final apiProducts = _parseProducts(apiData['products'] ?? []);
      if (_lastSearchQuery == query && apiProducts.isNotEmpty) {
        productList = apiProducts;
        _buildCategoryProductMapping();
        notifyListeners();
      }
    } catch (e) {
      print('❌ Background API search failed: $e');
    }
  }

  /// FILTERING - OPTIMIZED
  void _applyLocalFilters() {
    if (allProductList.isEmpty) {
      productList = [];
      _buildCategoryProductMapping();
      return;
    }

    List<ProductModel> filteredList = List.from(allProductList);

    // Apply filters
    if (isVag && !isNonVag) {
      filteredList = filteredList.where((p) => p.veg == true).toList();
    } else if (isNonVag && !isVag) {
      filteredList = filteredList.where((p) => p.nonveg == true).toList();
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
  }

  void filterRecord() async {
    if (_hasInitialData && _lastSearchQuery.isEmpty) {
      _applyLocalFilters();
      notifyListeners();
    } else {
      await loadProductsViaAPI();
    }
  }

  void toggleOfferFilter() {
    isOfferFilter = !isOfferFilter;

    if (isOfferFilter) {
      isVag = false;
      isNonVag = false;
    }

    filterRecord();
  }

  void clearAllFilters() {
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
  }

  /// FAVORITES MANAGEMENT
  Future<void> loadFavorites() async {
    try {
      if (Constant.userModel == null) return;

      final favoriteRestaurants =
          await FavouriteProvider.getFavouriteRestaurants();
      _isRestaurantFavorite = favoriteRestaurants.any(
        (r) => r.id == vendorModel.id,
      );

      final favoriteItems = await FavouriteProvider.getFavouriteFoods();
      favoriteProductIds = favoriteItems
          .where((item) => item.id != null)
          .map((item) => item.id.toString())
          .toList();
    } catch (e) {
      print('❌ Error loading favorites: $e');
    }
  }

  Future<void> toggleRestaurantFavorite() async {
    try {
      if (Constant.userModel == null) return;

      if (_isRestaurantFavorite) {
        await FavouriteProvider.removeFavouriteRestaurant(
          vendorModel.id.toString(),
        );
        _isRestaurantFavorite = false;
      } else {
        await FavouriteProvider.addFavouriteRestaurant(
          vendorModel.id.toString(),
        );
        _isRestaurantFavorite = true;
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

      if (productId.isEmpty) return;

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
      ShowToastDialog.showToast("Failed to update favorites");
    }
  }

  bool isProductFavorite(String productId) {
    return favoriteProductIds.contains(productId);
  }

  /// PROMOTION METHODS - OPTIMIZED
  bool hasActivePromotion(String productId, String restaurantId) {
    if (productId.isEmpty || restaurantId.isEmpty) return false;

    // Check memory cache first
    if (_allProductsWithPromotions.contains(productId)) return true;
    if (_promotionCheckedCache[productId] == true) return true;

    // Check service
    final hasPromo = PromotionalCacheService.isPromotionalAvailable(
      productId,
      restaurantId,
    );

    // Cache result
    _promotionCheckedCache[productId] = hasPromo;
    if (hasPromo) _allProductsWithPromotions.add(productId);

    return hasPromo;
  }

  Map<String, dynamic>? getActivePromotionForProduct({
    required String productId,
    required String restaurantId,
  }) {
    if (productId.isEmpty || restaurantId.isEmpty) return null;

    final cacheKey = '$productId-$restaurantId';

    // Check memory cache
    if (_promotionDataCache.containsKey(cacheKey)) {
      return _promotionDataCache[cacheKey];
    }

    // Check service
    final data = PromotionalCacheService.getCachedPromotionalData(
      productId,
      restaurantId,
    );

    if (data != null) {
      _promotionDataCache[cacheKey] = data;
      return data;
    }

    return null;
  }

  int? getPromotionalItemLimit(String productId, String restaurantId) {
    final cacheKey = '$productId-$restaurantId';

    if (_promotionLimitCache.containsKey(cacheKey)) {
      final limit = _promotionLimitCache[cacheKey]!;
      return limit > 0 ? limit : null;
    }

    final limit = PromotionalCacheService.getPromotionalLimit(
      productId,
      restaurantId,
    );

    _promotionLimitCache[cacheKey] = limit;
    return limit > 0 ? limit : null;
  }

  bool isPromotionalItemQuantityAllowed(
    String productId,
    String restaurantId,
    int currentQuantity,
  ) {
    if (currentQuantity <= 0) return true;

    final limit = getPromotionalItemLimit(productId, restaurantId);
    if (limit == null) return true;

    return currentQuantity <= limit;
  }

  /// CART MANAGEMENT
  void _initializeCartStreamListener() {
    if (_cartSubscription != null) return;

    _cartSubscription = cartProvider.cartStream.listen((event) {
      HomeProvider.cartItem.clear();
      HomeProvider.cartItem.addAll(event);
      notifyListeners();
    });
  }

  /// FIXED: calculatePrice method - No VariantInfo type issues
  String calculatePrice(ProductModel productModel) {
    double variantPrice = 0;
    double adOnsPrice = 0;

    // Calculate variant price
    if (productModel.itemAttribute != null &&
        productModel.itemAttribute!.variants != null &&
        productModel.itemAttribute!.variants!.isNotEmpty) {
      // Find matching variant
      final matchedVariants = productModel.itemAttribute!.variants!
          .where((v) => v.variantSku == selectedVariants.join('-'))
          .toList();

      if (matchedVariants.isNotEmpty) {
        final variant = matchedVariants.first;
        // Assuming variant has a variantPrice property
        final priceStr = variant.variantPrice ?? '0';
        variantPrice = double.parse(
          Constant.productCommissionPrice(vendorModel, priceStr),
        );
      } else {
        // Default to first variant if no match
        final firstVariant = productModel.itemAttribute!.variants!.first;
        final priceStr = firstVariant.variantPrice ?? '0';
        variantPrice = double.parse(
          Constant.productCommissionPrice(vendorModel, priceStr),
        );
      }
    } else {
      // No variants, use product price
      final price = double.parse(
        Constant.productCommissionPrice(
          vendorModel,
          productModel.price.toString(),
        ),
      );

      final disPrice = double.tryParse(productModel.disPrice ?? '0') ?? 0;
      variantPrice = disPrice > 0 && disPrice < price ? disPrice : price;
    }

    // Calculate add-ons price
    if (productModel.addOnsPrice != null &&
        productModel.addOnsTitle != null &&
        selectedAddOns.isNotEmpty) {
      for (int i = 0; i < productModel.addOnsTitle!.length; i++) {
        if (i < productModel.addOnsPrice!.length &&
            selectedAddOns.contains(productModel.addOnsTitle![i])) {
          final addonPrice =
              double.tryParse(
                Constant.productCommissionPrice(
                  vendorModel,
                  productModel.addOnsPrice![i].toString(),
                ),
              ) ??
              0;
          adOnsPrice += addonPrice;
        }
      }
    }

    final total = (variantPrice * quantity) + adOnsPrice;
    return total.toStringAsFixed(2);
  }

  /// ADD TO CART METHOD - Fixed variant handling
  Future<void> addToCart({
    required ProductModel productModel,
    required String price,
    required String discountPrice,
    required bool isIncrement,
    required int quantity,
    VariantInfo? variantInfo,
  }) async {
    final productId = productModel.id?.toString() ?? '';
    final vendorId = vendorModel.id?.toString() ?? '';

    // Check promotion limits for increment
    if (isIncrement) {
      final cacheKey = '$productId-$vendorId';
      final promo =
          _promotionDataCache[cacheKey] ??
          PromotionalCacheService.getCachedPromotionalData(productId, vendorId);

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

    // Calculate add-ons price
    if (productModel.addOnsPrice != null &&
        productModel.addOnsTitle != null &&
        selectedAddOns.isNotEmpty) {
      for (int i = 0; i < productModel.addOnsTitle!.length; i++) {
        if (i < productModel.addOnsPrice!.length &&
            selectedAddOns.contains(productModel.addOnsTitle![i]) &&
            productModel.addOnsPrice![i] != '0') {
          final addonPrice =
              double.tryParse(
                Constant.productCommissionPrice(
                  vendorModel,
                  productModel.addOnsPrice![i].toString(),
                ),
              ) ??
              0;
          adOnsPrice = (double.parse(adOnsPrice) + addonPrice).toString();
        }
      }
    }

    // Build cart product model
    cartProductModel.id = variantInfo != null
        ? "${productModel.id!}~${variantInfo.variantId ?? ''}"
        : productModel.id.toString();
    cartProductModel.name = productModel.name ?? "";
    cartProductModel.photo = productModel.photo ?? '';
    cartProductModel.categoryId = productModel.categoryID ?? '';
    cartProductModel.price = price;
    cartProductModel.discountPrice = discountPrice;
    // Merchant/base price (without commission) for backend
    if (variantInfo != null &&
        variantInfo.variantOptions is Map &&
        (variantInfo.variantOptions as Map).containsKey('merchant_price')) {
      cartProductModel.merchantPrice =
          (variantInfo.variantOptions as Map)['merchant_price']?.toString();
    } else {
      cartProductModel.merchantPrice =
          productModel.merchantPrice ?? productModel.price;
    }
    cartProductModel.vendorID = vendorModel.id;
    cartProductModel.vendorName = vendorModel.title ?? '';
    cartProductModel.quantity = quantity;
    cartProductModel.variantInfo = variantInfo;
    cartProductModel.extrasPrice = adOnsPrice;
    cartProductModel.extras = List.from(selectedAddOns);

    // Add promotion ID if applicable
    if (isIncrement) {
      final cacheKey = '$productId-$vendorId';
      final promo =
          _promotionDataCache[cacheKey] ??
          PromotionalCacheService.getCachedPromotionalData(productId, vendorId);
      if (promo != null) {
        cartProductModel.promoId = promo['product_id']?.toString() ?? '';
      }
    }

    // Add or remove from cart
    if (isIncrement) {
      await cartProvider.addToCart(Get.context!, cartProductModel, quantity);
    } else {
      await cartProvider.removeFromCart(cartProductModel, quantity);
    }

    notifyListeners();
  }

  /// ADD/REMOVE PRODUCT FUNCTION
  void addProductAndRemoveProductFunction({
    required ProductModel productModel,
    required String price,
    required String disPrice,
  }) {
    final productId = productModel.id?.toString() ?? '';
    final vendorId = productModel.vendorID ?? '';

    // Check stock
    if ((productModel.quantity ?? 0) != -1 &&
        (productModel.quantity ?? 0) < 1) {
      ShowToastDialog.showToast("Out of stock".tr);
      return;
    }

    // Check promotion limits
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

    // Calculate final prices
    String finalPrice = price;
    String finalDiscountPrice = disPrice;
    if (promo != null) {
      finalPrice = (promo['special_price'] as num).toString();
      finalDiscountPrice = Constant.productCommissionPrice(
        vendorModel,
        productModel.price.toString(),
      );
    }

    // Add to cart
    addToCart(
      productModel: productModel,
      price: finalPrice,
      discountPrice: finalDiscountPrice,
      isIncrement: true,
      quantity: 1,
    );
  }

  /// SCROLL METHODS
  void scrollToCategory(int index) {
    if (!scrollControllerProduct.hasClients) return;

    final categoryKey = _getCategoryKey(index);
    if (categoryKeys.containsKey(categoryKey)) {
      final context = categoryKeys[categoryKey]!.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        return;
      }
    }

    // Fallback calculation
    double position = 0;
    for (int i = 0; i < index && i < vendorCategoryList.length; i++) {
      final products = getProductsByCategory(
        vendorCategoryList[i].id.toString(),
      );
      position += 60.0 + (products.length * 100.0);
    }

    scrollControllerProduct.animateTo(
      position,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void scrollToProductAfterLoad() {
    if (_scrollToProductId != null && _shouldScrollToProduct) {
      Future.delayed(const Duration(milliseconds: 300), () {
        scrollToProduct(_scrollToProductId!);
        _shouldScrollToProduct = false;
      });
    }
  }

  void scrollToProduct(String productId) {
    if (!scrollController.hasClients) return;

    final index = productList.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final position = (index * 120.0).clamp(0.0, double.infinity);
      scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  /// SLIDER ANIMATION
  void animateSlider() {
    _sliderTimer?.cancel();

    if (vendorModel.photos == null || vendorModel.photos!.isEmpty) return;

    _sliderTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!pageController.hasClients) {
        timer.cancel();
        _sliderTimer = null;
        return;
      }

      if (currentPage < vendorModel.photos!.length - 1) {
        currentPage++;
      } else {
        currentPage = 0;
      }

      try {
        pageController.animateToPage(
          currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      } catch (e) {
        timer.cancel();
        _sliderTimer = null;
      }
    });
  }

  /// UTILITY METHODS
  Future<void> loadProductsViaAPI() async {
    return await PerformanceMonitor.monitorOperation(
      'loadProductsViaAPI',
      () async {
        productsLoading = true;
        notifyListeners();

        try {
          final apiData = await RestaurantApiHelper.getRestaurantProducts(
            restaurantId: vendorModel.id!,
            search: searchEditingController.text.isNotEmpty
                ? searchEditingController.text
                : null,
            isVeg: isVag,
            isNonVeg: isNonVag,
            offerOnly: isOfferFilter,
          );

          vendorCategoryList = _parseCategories(apiData['categories'] ?? []);
          allProductList = _parseProducts(apiData['products'] ?? []);
          productList = List.from(allProductList);

          // Load promotions in background
          _loadAllPromotionsForRestaurant();

          _hasInitialData = true;
          _buildCategoryProductMapping();
        } catch (e) {
          print('❌ Error loading products: $e');
          allProductList = [];
          productList = [];
          vendorCategoryList = [];
        } finally {
          productsLoading = false;
          notifyListeners();
        }
      },
    );
  }

  Future<void> _loadAttributes() async {
    try {
      final result = await FireStoreUtils.getAttributes();
      if (result != null) {
        attributesList = result;
      } else {
        attributesList = [];
      }
    } catch (e) {
      print('❌ Error loading attributes: $e');
      attributesList = [];
    }
  }

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
      'hasWorkingHours': vendorModel.workingHours?.isNotEmpty ?? false,
    };
  }

  /// DISPOSE
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
