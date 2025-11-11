import 'dart:async';
import 'dart:developer';
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
import 'package:jippymart_customer/utils/cache_manager.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/performance_monitor.dart';
import 'package:jippymart_customer/utils/restaurant_status_utils.dart'; // Add this import
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RestaurantDetailsProvider extends ChangeNotifier {
  final String? scrollToProductId;

  RestaurantDetailsProvider({this.scrollToProductId});

  RxInt selectedCategoryIndex = 0.obs;

  // New Logic
  RxList<ProductModel> filteredProductList = <ProductModel>[].obs;

  bool productsLoading = false;

  void productLoadingFunction(bool value) {
    productsLoading = value;
    notifyListeners();
  }

  final ScrollController scrollControllerProduct = ScrollController();

  // In RestaurantDetailsController
  final Map<String, GlobalKey> categoryKeys = {};

  String getCategoryKey(int index) {
    return 'category_$index';
  }

  // Improved scrollToCategory method
  void scrollToCategory(int index) {
    if (!scrollControllerProduct.hasClients) {
      return;
    }

    // Wait for the next frame to ensure UI is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final categoryKey = getCategoryKey(index);

        if (categoryKeys.containsKey(categoryKey)) {
          final key = categoryKeys[categoryKey]!;
          final context = key.currentContext;

          if (context != null) {
            // Use Scrollable.ensureVisible for precise scrolling
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              alignment: 0.1, // Scroll to 10% from top for better visibility
            );
          } else {
            // Fallback to manual scrolling
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

  // Fallback method for manual scrolling
  void _fallbackScrollToCategory(int index) {
    try {
      double estimatedPosition = 0.0;

      // Estimate position based on previous categories
      for (int i = 0; i < index; i++) {
        if (i < vendorCategoryList.length) {
          final categoryId = vendorCategoryList[i].id.toString();
          final productCount = getProductsByCategory(categoryId).length;
          // More accurate estimation
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

  List<ProductModel> getProductsByCategory(String categoryId) {
    return categoryProductsMap[categoryId] ?? [];
  }

  Map<String, List<ProductModel>> categoryProductsMap = {};

  // Also update the getProductList method to ensure categories are properly loaded
  Future<void> getProductList() async {
    try {
      print(" getProductList called, total products: ${productList.length}");
      // Clear existing data
      vendorCategoryList.clear();
      categoryProductsMap.clear();
      categoryKeys.clear();
      for (var product in productList) {
        // Skip if product has no category
        if (product.categoryID == null || product.categoryID!.isEmpty) continue;

        // Check if we already have the category
        bool alreadyExists = vendorCategoryList.any(
          (cat) => cat.id.toString() == product.categoryID.toString(),
        );

        if (!alreadyExists) {
          // Fetch category from Firebase
          var category = await FireStoreUtils.getVendorCategoryByCategoryId(
            product.categoryID.toString(),
          );

          if (category != null) {
            vendorCategoryList.add(category);
            // Initialize key for this category
            final categoryKey = getCategoryKey(vendorCategoryList.length - 1);
            categoryKeys[categoryKey] = GlobalKey();
          }
        }

        // Group products under the categoryID
        if (!categoryProductsMap.containsKey(product.categoryID)) {
          categoryProductsMap[product.categoryID.toString()] = [];
        }
        categoryProductsMap[product.categoryID.toString()]!.add(product);
      }

      productLoadingFunction(false);
      notifyListeners();
    } catch (e) {
      productLoadingFunction(false);
      log("Error in getProductList: $e");
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Failed to load products");
    }
  }

  /// Get restaurant by ID for deep linking
  Future<VendorModel?> getRestaurantById(String restaurantId) async {
    try {
      // Query Firestore for restaurant by ID
      final doc = await FireStoreUtils.getVendorById(restaurantId);
      return doc;
    } catch (e) {
      print('[RESTAURANT CONTROLLER] ❌ Error fetching restaurant by ID: $e');
      return null;
    }
  }

  TextEditingController searchEditingController = TextEditingController();

  bool isLoading = true;
  PageController pageController = PageController();
  int currentPage = 0;

  bool isVag = false;
  bool isNonVag = false;
  bool isOfferFilter = false;
  bool isMenuOpen = false;

  // Scroll controller for scrolling to specific product
  ScrollController scrollController = ScrollController();
  bool shouldScrollToProduct = false;

  List<VendorModel> favouriteList = <VendorModel>[];
  List<FavouriteItemModel> favouriteItemList = <FavouriteItemModel>[];
  List<ProductModel> allProductList = <ProductModel>[];
  List<ProductModel> productList = <ProductModel>[];
  List<VendorCategoryModel> vendorCategoryList = <VendorCategoryModel>[];

  List<CouponModel> couponList = <CouponModel>[];

  // **ENHANCED CACHE FOR FASTER FILTERING**
  Map<String, List<ProductModel>> _productsByCategory = {};

  void initFunction({required VendorModel vendorModels}) {
    getArgument(vendorModels: vendorModels);
    if (scrollToProductId != null) {
      shouldScrollToProduct = true;
    }
  }

  /// **DEEP LINK UPDATE METHOD**
  void updateRestaurant(VendorModel newRestaurant) {
    print(
      '[RESTAURANT CONTROLLER] 🔄 Updating with new restaurant: ${newRestaurant.title}',
    );

    // Update the vendor model directly
    vendorModel = newRestaurant;

    // **CRITICAL FIX: Clear promotional cache for new restaurant**
    PromotionalCacheService.clearRestaurantCache(vendorModel.id ?? '');
    _promotionalCacheLoaded = false;

    // Reset loading state
    isLoading = true;

    // Reload all data for the new restaurant
    _loadCriticalDataInParallel()
        .then((_) async {
          await _loadPromotionalCache();
          isLoading = false;
          notifyListeners();
        })
        .catchError((error) {
          print('[RESTAURANT CONTROLLER] ❌ Error updating restaurant: $error');
          isLoading = false;
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

        // Only animate if attached
        try {
          if (pageController.hasClients) {
            pageController.animateToPage(
              currentPage,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn,
            );
          }
        } catch (e) {
          // If any error occurs, cancel the timer
          timer.cancel();
        }
      });
    }
  }

  VendorModel vendorModel = VendorModel();
  final CartProvider cartProvider = CartProvider();
  bool _promotionalCacheLoaded = false;

  // **SIMPLE CONSISTENT STATUS CHECKING**
  bool canAcceptOrders() {
    return RestaurantStatusUtils.canAcceptOrders(vendorModel);
  }

  // **GET SIMPLE RESTAURANT STATUS INFO**
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

  // **ULTRA-FAST METHOD TO LOAD AND PRE-CALCULATE ALL PROMOTIONAL DATA (OPTIMIZED)**
  Future<void> _loadPromotionalCache() async {
    if (_promotionalCacheLoaded) return;

    try {
      await PromotionalCacheService.loadRestaurantPromotions(
        vendorModel.id ?? '',
      );
      _promotionalCacheLoaded = true;
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error loading promotional cache: $e');
      _promotionalCacheLoaded = false;
    }
  }

  // **INSTANT METHOD TO GET CACHED PROMOTIONAL DATA (ZERO ASYNC)**
  Map<String, dynamic>? _getCachedPromotionalData(
    String productId,
    String restaurantId,
  ) {
    return PromotionalCacheService.getCachedPromotionalData(
      productId,
      restaurantId,
    );
  }

  // **INSTANT METHOD TO CHECK PROMOTIONAL AVAILABILITY (ZERO ASYNC)**
  bool _isPromotionalAvailable(String productId, String restaurantId) {
    return PromotionalCacheService.isPromotionalAvailable(
      productId,
      restaurantId,
    );
  }

  // **INSTANT METHOD TO GET PROMOTIONAL LIMIT (ZERO ASYNC)**
  int _getPromotionalLimit(String productId, String restaurantId) {
    return PromotionalCacheService.getPromotionalLimit(productId, restaurantId);
  }

  // **METHOD TO CHECK IF CART HAS PROMOTIONAL ITEMS**
  bool hasPromotionalItems() {
    return cartItem.any(
      (item) => item.promoId != null && item.promoId!.isNotEmpty,
    );
  }

  // **ULTRA-FAST METHOD TO GET PROMOTIONAL ITEM LIMIT (ZERO ASYNC)**
  int? getPromotionalItemLimit(String productId, String restaurantId) {
    if (!_isPromotionalAvailable(productId, restaurantId)) {
      return null;
    }
    final limit = _getPromotionalLimit(productId, restaurantId);
    return limit > 0 ? limit : null;
  }

  // **ULTRA-FAST METHOD TO CHECK IF PROMOTIONAL ITEM QUANTITY IS WITHIN LIMIT (ZERO ASYNC)**
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

  bool isLoadingAddButton = false;

  // **ULTRA-FAST METHOD TO GET ACTIVE PROMOTION WITH LAZY LOADING**
  Map<String, dynamic>? getActivePromotionForProduct({
    required String productId,
    required String restaurantId,
  }) {
    // **LAZY LOADING: Check if cache is loaded, if not trigger background load**
    if (!_promotionalCacheLoaded) {
      _loadPromotionalCache(); // **BACKGROUND LOADING: Non-blocking**
    }

    // Use cached data instead of Firebase query - INSTANT RESPONSE
    return _getCachedPromotionalData(productId, restaurantId);
  }

  /// **OPTIMIZED PARALLEL DATA LOADING ARCHITECTURE**
  Future<void> getArgument({required VendorModel vendorModels}) async {
    cartProvider.cartStream.listen((event) async {
      cartItem.clear();
      cartItem.addAll(event);
    });
    vendorModel = vendorModels;
    notifyListeners();
    animateSlider();
    await _loadCriticalDataInParallel();
    // **STEP 2: Mark screen as ready immediately**
    isLoading = false;
    notifyListeners();

    // **STEP 3: Load secondary data in parallel (non-blocking)**
    _loadSecondaryDataInParallel();

    // **STEP 4: Load promotional cache in parallel with secondary data (non-blocking)**
    _loadPromotionalCache();
  }

  /// **PARALLEL CRITICAL DATA LOADING**
  Future<void> _loadCriticalDataInParallel() async {
    return await PerformanceMonitor.monitorOperation(
      'loadCriticalDataInParallel',
      () async {
        print("DEBUG: Starting parallel critical data loading");
        // Load products, categories, and favorites in parallel
        productLoadingFunction(true);
        await Future.wait([_loadProducts(), _loadFavorites()]);
        getProductList();
        // Build product cache after both products and categories are loaded
        _buildProductCache();
        print("DEBUG: Parallel critical data loading completed");
      },
    );
  }

  /// **PARALLEL SECONDARY DATA LOADING**
  void _loadSecondaryDataInParallel() async {
    try {
      await PerformanceMonitor.monitorOperation(
        'loadSecondaryDataInParallel',
        () async {
          print("DEBUG: Starting parallel secondary data loading");

          if (Constant.userModel != null) {
            // Load coupons and attributes in parallel
            await Future.wait([_loadCoupons(), _loadAttributes()]);
          } else {
            // Load only attributes if user not logged in
            await _loadAttributes();
          }
        },
      );
    } catch (e) {
      print("DEBUG: Secondary data loading failed (non-critical): $e");
    }
  }

  /// **OPTIMIZED PRODUCT LOADING**
  Future<void> _loadProducts() async {
    return await PerformanceMonitor.monitorOperation('loadProducts', () async {
      print("DEBUG: Loading products for vendor: ${vendorModel.id}");
      final cacheKey = 'products_${vendorModel.id}';
      final cachedProducts = await CacheManager.get<List<ProductModel>>(
        cacheKey,
      );
      if (cachedProducts != null && cachedProducts.isNotEmpty) {
        allProductList = cachedProducts;
        productList = cachedProducts;
        _applySmartSorting();
        print("DEBUG: Using cached products: ${cachedProducts.length} items");
      } else {
        if (cachedProducts != null && cachedProducts.isEmpty) {
          CacheManager.clear(cacheKey);
        }
        final products = await FireStoreUtils.getProductByVendorId(
          vendorModel.id.toString(),
        );
        print("DEBUG: Loaded ${products.length} products");

        if ((Constant.isSubscriptionModelApplied == true ||
                Constant.adminCommission?.isEnabled == true) &&
            vendorModel.subscriptionPlan != null) {
          if (vendorModel.subscriptionPlan?.itemLimit == '-1') {
            allProductList = products;
            productList = products;
          } else {
            int selectedProduct =
                products.length <
                    int.parse(vendorModel.subscriptionPlan?.itemLimit ?? '0')
                ? (products.isEmpty ? 0 : (products.length))
                : int.parse(vendorModel.subscriptionPlan?.itemLimit ?? '0');
            allProductList = products.sublist(0, selectedProduct);
            productList = products.sublist(0, selectedProduct);
          }
        } else {
          allProductList = products;
          productList = products;
        }

        _applySmartSorting();
        await CacheManager.setProductData(cacheKey, productList);
        print("DEBUG: Cached ${productList.length} products");
      }

      print("DEBUG: Final product list has ${productList.length} items");

      // Scroll to specific product if needed
      if (scrollToProductId != null) {
        scrollToProductAfterLoad();
      }
    });
  }

  /// **OPTIMIZED FAVORITES LOADING**
  Future<void> _loadFavorites() async {
    return await PerformanceMonitor.monitorOperation('loadFavorites', () async {
      if (Constant.userModel != null) {
        print("DEBUG: Loading favorites for user");

        // Load favorite restaurants and items in parallel
        await Future.wait([
          FireStoreUtils.getFavouriteRestaurants().then((value) {
            favouriteList = value;
          }),
          FireStoreUtils.getFavouriteItem().then((value) {
            favouriteItemList = value;
          }),
        ]);
      }
    });
  }

  /// **OPTIMIZED COUPONS LOADING**
  Future<void> _loadCoupons() async {
    return await PerformanceMonitor.monitorOperation('loadCoupons', () async {
      print("DEBUG: Loading coupons");

      // Load vendor-specific and global coupons in parallel
      await Future.wait([
        FireStoreUtils.getOfferByVendorId(vendorModel.id.toString()).then((
          value,
        ) {
          couponList = value;
        }),
        FireStoreUtils.getHomeCoupon().then((globalCoupons) {
          final filteredGlobalCoupons = globalCoupons
              .where(
                (c) =>
                    c.resturantId == null ||
                    c.resturantId == '' ||
                    c.resturantId?.toUpperCase() == 'ALL',
              )
              .toList();
          couponList.addAll(
            filteredGlobalCoupons.where(
              (g) => !couponList.any((c) => c.id == g.id),
            ),
          );
        }),
      ]);
    });
  }

  /// **OPTIMIZED ATTRIBUTES LOADING**
  Future<void> _loadAttributes() async {
    return await PerformanceMonitor.monitorOperation(
      'loadAttributes',
      () async {
        print("DEBUG: Loading attributes");
        await FireStoreUtils.getAttributes().then((value) {
          if (value != null) {
            attributesList.value = value;
          }
        });
      },
    );
  }

  /// **SMART PRODUCT CACHING SYSTEM**
  void _buildProductCache() {
    _productsByCategory.clear();
    for (var product in productList) {
      final categoryId = product.categoryID.toString();
      if (!_productsByCategory.containsKey(categoryId)) {
        _productsByCategory[categoryId] = [];
      }
      _productsByCategory[categoryId]!.add(product);
    }
  }

  searchProduct(String name) {
    if (name.isEmpty) {
      productList.clear();
      productList.addAll(allProductList);
      _applySmartSorting();
    } else {
      isVag = false;
      isNonVag = false;
      isOfferFilter = false;
      productList = allProductList
          .where((p0) => p0.name!.toLowerCase().contains(name.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  filterRecord() {
    List<ProductModel> filteredList = [];

    if (isVag == true && isNonVag == true) {
      filteredList = allProductList
          .where((p0) => p0.nonveg == true || p0.nonveg == false)
          .toList();
    } else if (isVag == true && isNonVag == false) {
      filteredList = allProductList.where((p0) => p0.nonveg == false).toList();
    } else if (isVag == false && isNonVag == true) {
      filteredList = allProductList.where((p0) => p0.nonveg == true).toList();
    } else if (isVag == false && isNonVag == false) {
      filteredList = allProductList
          .where((p0) => p0.nonveg == true || p0.nonveg == false)
          .toList();
    }

    // Apply offer filter if enabled
    if (isOfferFilter) {
      filteredList = filteredList
          .where((product) => _isPromotionalItem(product))
          .toList();
    }

    productList = filteredList;
    _applySmartSorting();
  }

  Future<List<ProductModel>> getProductByCategory(
    VendorCategoryModel vendorCategoryModel,
  ) async {
    return productList
        .where((p0) => p0.categoryID == vendorCategoryModel.id)
        .toList();
  }

  /// **ULTRA-FAST PROMOTIONAL ITEM DETECTION**
  bool _isPromotionalItem(ProductModel product) {
    final productId = product.id ?? '';
    final restaurantId = vendorModel.id ?? '';

    // **PERFORMANCE FIX: Use cached promotional data (instant)**
    final hasPromotion = _isPromotionalAvailable(productId, restaurantId);

    if (hasPromotion) {
      return true;
    }

    // **FALLBACK: Check for price-based promotional items**
    final priceValue = double.tryParse(product.price ?? '0') ?? 0.0;
    final discountPriceValue = double.tryParse(product.disPrice ?? '0') ?? 0.0;

    // Consider it promotional if there's a discount price lower than regular price
    return priceValue > 0 &&
        discountPriceValue > 0 &&
        priceValue < discountPriceValue;
  }

  /// **SMART SORTING SYSTEM**
  void _applySmartSorting() {
    if (isOfferFilter) {
      // When offer filter is active, show only promotional items
      return;
    }

    // Sort products for better user experience
    productList.sort((a, b) {
      // 1. Check promotional status
      final aIsPromotional = _isPromotionalItem(a);
      final bIsPromotional = _isPromotionalItem(b);

      if (aIsPromotional && !bIsPromotional) return -1; // a comes first
      if (!aIsPromotional && bIsPromotional) return 1; // b comes first

      // 2. If both have same promotional status, check availability
      final aIsAvailable = a.isAvailable ?? true;
      final bIsAvailable = b.isAvailable ?? true;

      if (aIsAvailable && !bIsAvailable) return -1; // a comes first
      if (!aIsAvailable && bIsAvailable) return 1; // b comes first

      // 3. If both have same promotional status and availability, sort by name
      return (a.name ?? '').compareTo(b.name ?? '');
    });
  }

  /// **OFFER FILTER TOGGLE METHOD**
  void toggleOfferFilter() {
    isOfferFilter = !isOfferFilter;

    // Reset other filters when offer filter is activated
    if (isOfferFilter) {
      isVag = false;
      isNonVag = false;
    }

    filterRecord();
  }

  /// **CLEAR ALL FILTERS METHOD**
  void clearAllFilters() {
    try {
      // Reset all filter states
      isVag = false;
      isNonVag = false;
      isOfferFilter = false;

      // Clear search text
      searchEditingController.clear();

      // Reset product list to show all products
      productList.clear();
      productList.addAll(allProductList);

      // Apply smart sorting
      _applySmartSorting();

      // Update UI
      notifyListeners();
    } catch (e) {
      print('Error in clearAllFilters: $e');
    }
  }

  // **BACKWARD COMPATIBILITY METHODS**
  getProduct() async {
    await _loadCriticalDataInParallel();
  }

  getFavouriteList() async {
    _loadSecondaryDataInParallel();
  }

  // **REMOVED COMPLEX STATUS CHECKING - USING SIMPLE LOGIC INSTEAD**
  bool isCurrentDateInRange(DateTime startDate, DateTime endDate) {
    final currentDate = DateTime.now();
    return currentDate.isAfter(startDate) && currentDate.isBefore(endDate);
  }

  RxList<AttributesModel> attributesList = <AttributesModel>[].obs;
  RxList selectedVariants = [].obs;
  RxList selectedIndexVariants = [].obs;
  RxList selectedIndexArray = [].obs;

  RxList selectedAddOns = [].obs;

  RxInt quantity = 1.obs;

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
    adOnsPrice = (quantity.value * double.parse(adOnsPrice)).toString();
    mainPrice =
        ((double.parse(variantPrice.toString()) *
                    double.parse(quantity.value.toString())) +
                double.parse(adOnsPrice.toString()))
            .toString();
    return mainPrice;
  }

  getAttributeData() async {
    await FireStoreUtils.getAttributes().then((value) {
      if (value != null) {
        attributesList.value = value;
      }
    });
  }

  addToCart({
    required ProductModel productModel,
    required String price,
    required String discountPrice,
    required bool isIncrement,
    required int quantity,
    VariantInfo? variantInfo,
  }) async {
    // **CHECK PROMOTIONAL ITEM LIMIT BEFORE ADDING TO CART (OPTIMIZED)**
    if (isIncrement) {
      final promo = _getCachedPromotionalData(
        productModel.id ?? '',
        vendorModel.id ?? '',
      );

      if (promo != null) {
        final isAllowed = isPromotionalItemQuantityAllowed(
          productModel.id ?? '',
          vendorModel.id ?? '',
          quantity,
        );

        if (!isAllowed) {
          final limit = getPromotionalItemLimit(
            productModel.id ?? '',
            vendorModel.id ?? '',
          );
          ShowToastDialog.showToast(
            "Maximum $limit items allowed for this promotional offer".tr,
          );
          return;
        }
      }
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

      // Set promoId for promotional items (OPTIMIZED)
      if (isIncrement) {
        final promo = _getCachedPromotionalData(
          productModel.id ?? '',
          vendorModel.id ?? '',
        );
        if (promo != null) {
          cartProductModel.promoId = promo['product_id'] ?? '';
        }
      }
    } else {
      cartProductModel.id = productModel.id!;
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

      // Set promoId for promotional items
      if (isIncrement) {
        final promo = await FireStoreUtils.getActivePromotionForProduct(
          productId: productModel.id ?? '',
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
  }

  // Method to scroll to a specific product
  void scrollToProduct(String productId) {
    if (scrollController.hasClients) {
      // Find the index of the product in the product list
      int productIndex = -1;
      for (int i = 0; i < productList.length; i++) {
        if (productList[i].id == productId) {
          productIndex = i;
          break;
        }
      }

      if (productIndex != -1) {
        // Calculate approximate position (each product card is roughly 120px height)
        double scrollPosition = productIndex * 120.0;

        // Add some offset for better visibility
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

  // Method to scroll to product after data is loaded
  void scrollToProductAfterLoad() {
    if (scrollToProductId != null && shouldScrollToProduct) {
      // Wait a bit for the UI to be ready
      Future.delayed(const Duration(milliseconds: 500), () {
        scrollToProduct(scrollToProductId!);
        shouldScrollToProduct = false;
      });
    }
  }
}
