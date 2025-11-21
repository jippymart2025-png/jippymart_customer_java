import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/mart_banner_model.dart';
import 'package:jippymart_customer/models/mart_category_model.dart';
import 'package:jippymart_customer/models/mart_delivery_settings_model.dart';
import 'package:jippymart_customer/models/mart_item_model.dart';
import 'package:jippymart_customer/models/mart_subcategory_model.dart';
import 'package:jippymart_customer/models/mart_vendor_model.dart';
import 'package:jippymart_customer/services/mart_firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:http/http.dart' as http;

class MartProvider extends ChangeNotifier {
  //NEW SECTION
  Map<String, List<MartItemModel>> categoryProductsMap =
      <String, List<MartItemModel>>{};
  List<String> uniqueCategoryTitles = <String>[];

  Future<void> loadCategoryProductsForSections() async {
    try {
      final allProducts = await _firestoreService.getMartItems();
      final Map<String, List<MartItemModel>> categoryMap = {};
      for (final product in allProducts) {
        final categoryTitle = product.categoryTitle ?? 'Uncategorized';

        if (!categoryMap.containsKey(categoryTitle)) {
          categoryMap[categoryTitle] = [];
        }

        // Add product to the category list (limit to 10 products per category for horizontal scroll)
        if (categoryMap[categoryTitle]!.length < 10) {
          categoryMap[categoryTitle]!.add(product);
        }
      }

      // Update reactive variables
      categoryProductsMap.clear();
      categoryProductsMap.addAll(categoryMap);

      uniqueCategoryTitles.clear();
      uniqueCategoryTitles.addAll(categoryMap.keys.toList());

      // 🐾 Move "Pet Care" to the top if it exists
      if (uniqueCategoryTitles.contains('Pet Care')) {
        uniqueCategoryTitles.remove('Pet Care');
        uniqueCategoryTitles.insert(
          _safeInsertIndex(uniqueCategoryTitles.length, 7),
          'Pet Care',
        );
      }
      if (uniqueCategoryTitles.contains('Fruits & Vegetables')) {
        uniqueCategoryTitles.remove('Fruits & Vegetables');
        uniqueCategoryTitles.insert(
          _safeInsertIndex(uniqueCategoryTitles.length, 0),
          'Fruits & Vegetables',
        );
      }
      if (uniqueCategoryTitles.contains('Cooking Essentials')) {
        uniqueCategoryTitles.remove('Cooking Essentials');
        uniqueCategoryTitles.insert(
          _safeInsertIndex(uniqueCategoryTitles.length, 1),
          'Cooking Essentials',
        );
      }
      print(
        '[MART CONTROLLER] ✅ Loaded ${uniqueCategoryTitles.length} unique categories:',
      );
      for (final category in uniqueCategoryTitles) {
        print(
          '  - $category: ${categoryProductsMap[category]?.length ?? 0} products',
        );
      }

      notifyListeners();
    } catch (e) {
      print('[MART CONTROLLER] ❌ Error loading products by category: $e');
    }
  }

  int _safeInsertIndex(int currentLength, int desiredIndex) {
    if (desiredIndex <= 0) {
      return 0;
    }
    if (desiredIndex >= currentLength) {
      return currentLength;
    }
    return desiredIndex;
  }

  // Service injection
  final MartFirestoreService _firestoreService =
      Get.find<MartFirestoreService>();

  // Observable variables
  bool isLoading = true;
  bool isCategoryLoading = false;
  bool isProductLoading = false;
  bool isVendorLoading = false;
  bool isHomepageCategoriesLoaded = false;
  String selectedCategoryId = "";
  String selectedVendorId = "";
  String selectedVendorName = "";
  String searchQuery = "";
  String errorMessage = "";

  // Data lists
  List<MartVendorModel> martVendors = <MartVendorModel>[];
  List<MartCategoryModel> martCategories = <MartCategoryModel>[];
  Map<String, List<MartSubcategoryModel>> subcategoriesMap =
      <String, List<MartSubcategoryModel>>{};
  List<MartItemModel> martItems = <MartItemModel>[];
  List<MartItemModel> filteredItems = <MartItemModel>[];
  List<MartItemModel> featuredItems = <MartItemModel>[];
  List<MartItemModel> itemsOnSale = <MartItemModel>[];
  List<MartCategoryModel> featuredCategories = <MartCategoryModel>[];
  List<MartItemModel> cartItems = <MartItemModel>[];
  List<Map<String, dynamic>> spotlightItems = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> stealsItems = <Map<String, dynamic>>[];
  List<MartItemModel> trendingItems = <MartItemModel>[];
  bool isTrendingLoading = false;
  bool isSubcategoryLoading = false;

  // Sections data
  List<String> availableSections = <String>[];
  Map<String, List<MartItemModel>> sectionProducts =
      <String, List<MartItemModel>>{};
  bool isSectionsLoading = false;
  bool _sectionsLoadingTriggered =
      false; // Flag to prevent multiple loading attempts
  List<MartSubcategoryModel> subcategories = <MartSubcategoryModel>[];

  // Delivery settings
  MartDeliverySettingsModel? deliverySettings;

  // Banner functionality
  List<MartBannerModel> martTopBanners = <MartBannerModel>[];
  List<MartBannerModel> martBottomBanners = <MartBannerModel>[];
  PageController martTopBannerController = PageController(
    viewportFraction: 1.0,
  );
  PageController martBottomBannerController = PageController(
    viewportFraction: 1.0,
  );
  ValueNotifier<int> currentTopBannerPage = ValueNotifier<int>(0);
  int currentBottomBannerPage = 0;
  Timer? _martBannerTimer;

  // Current data
  MartVendorModel? currentVendor = MartVendorModel();
  MartCategoryModel? currentCategory = MartCategoryModel();

  // Pagination
  bool hasMoreItems = true;
  bool hasMoreVendors = true;
  int currentPage = 1;
  int currentVendorPage = 1;
  static const int itemsPerPage = 20;
  static const int vendorsPerPage = 10;

  // Search and filter
  Timer? _searchDebouncer;
  String selectedSortBy = "name";
  bool sortAscending = true;
  bool filterVegOnly = false;
  bool filterNonVegOnly = false;
  bool filterAvailableOnly = true;

  void initFunction() async {
    loadMartBannersStream();
    loadFeaturedCategories();
    loadCategoryProductsForSections();

    ///
    // _preloadSections();
    // _initializeServices();
    // setupSearchListener();
    if (martTopBanners.isNotEmpty) {
      startMartBannerTimer();
    }
    notifyListeners();
  }

  Future<void> refreshData() async {
    try {
      print('[MART CONTROLLER] ==========================================');
      print('[MART CONTROLLER] 🔄 refreshData() called');
      print('[MART CONTROLLER] ==========================================');
      isLoading = true;
      errorMessage = "";
      // Reset homepage categories flag to allow reloading
      isHomepageCategoriesLoaded = false;
      await Future.wait([
        loadMartVendors(refresh: true),
        loadHomepageCategoriesStreaming(limit: 10),
        loadFeaturedItems(),
        loadItemsOnSale(),
        loadFeaturedCategories(),
        loadSpotlightItems(),
        loadStealsItems(),
      ]);
    } catch (e) {
      print('[MART] Error refreshing data: $e');
      errorMessage = "Failed to refresh data: $e";
    } finally {
      isLoading = false;
    }
  }

  //
  // void initFunction() {
  //   loadMartBannersStream();
  //   loadCategoryProductsForSections();
  //   _preloadSections();
  //   _initializeServices();
  //   setupSearchListener();
  //   if (martTopBanners.isNotEmpty) {
  //     startMartBannerTimer();
  //   }
  //   notifyListeners();
  // }

  void onClose() {
    _searchDebouncer?.cancel();
    _martBannerTimer?.cancel();
    try {
      if (martTopBannerController.hasClients) {
        martTopBannerController.dispose();
      }
      if (martBottomBannerController.hasClients) {
        martBottomBannerController.dispose();
      }
    } catch (e) {}
  }

  /// Start mart banner auto-scroll timer
  void startMartBannerTimer() {
    _martBannerTimer?.cancel();
    _martBannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (martTopBannerController.hasClients) {
        timer.cancel();
        return;
      }
      if (martTopBanners.isNotEmpty) {
        try {
          if (martTopBannerController.hasClients) {
            int currentPage = martTopBannerController.page?.round() ?? 0;
            int nextPage = currentPage + 1;

            // Update the current page indicator (modulo for actual banner index)
            currentTopBannerPage.value = nextPage % martTopBanners.length;

            martTopBannerController.animateToPage(
              nextPage,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        } catch (e) {
          // If any error occurs, cancel the timer
          timer.cancel();
        }
      }
    });
  }

  /// Stop mart banner auto-scroll timer
  void stopMartBannerTimer() {
    _martBannerTimer?.cancel();
  }

  /// Load mart banners using lazy loading streams
  void loadMartBannersStream() {
    _initializeBannerStreams();
  }

  static Stream<List<MartBannerModel>> getMartBottomBannersStream() {
    final StreamController<List<MartBannerModel>> controller =
        StreamController<List<MartBannerModel>>();
    String? customerZoneId = Constant.selectedZone?.id;

    Future<void> fetchBanners() async {
      try {
        final response = await http.get(
          Uri.parse('${AppConst.baseUrl}banners/top'),
          headers: await getHeaders(),
        );
        print("getMartBottomBannersStream ${response.body}");

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            List<MartBannerModel> bannerList = [];
            List<MartBannerModel> filteredBannerList = [];

            for (var bannerData in responseData['data']) {
              // Remove the redundant id conversion - just pass bannerData directly
              MartBannerModel banner = MartBannerModel.fromJson(bannerData);
              bannerList.add(banner);
              print(
                "getMartBottomBannersStream ${banner.id} ${banner.categoryId} ${banner.zoneId} ",
              );
              bool shouldShowBanner = false;
              if (banner.zoneId == null || banner.zoneId!.isEmpty) {
                shouldShowBanner = true;
              } else if (customerZoneId == null || customerZoneId.isEmpty) {
                shouldShowBanner = true;
              } else if (banner.zoneId == customerZoneId) {
                shouldShowBanner = true;
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

            controller.add(filteredBannerList);
          } else {
            controller.add(<MartBannerModel>[]);
          }
        } else {
          controller.add(<MartBannerModel>[]);
        }
      } catch (error) {
        print("Error fetching banners: $error");
        controller.add(<MartBannerModel>[]);
      }
    }

    // Initial fetch
    fetchBanners();

    return controller.stream;
  }

  //finded
  // static Stream<List<MartBannerModel>> getMartBottomBannersStream() {
  //   final StreamController<List<MartBannerModel>> controller =
  //       StreamController<List<MartBannerModel>>();
  //   String? customerZoneId = Constant.selectedZone?.id;
  //   Future<void> fetchBanners() async {
  //     try {
  //       final response = await http.get(
  //         Uri.parse('${AppConst.baseUrl}banners/top'),
  //         headers: await getHeaders(),
  //       );
  //       print("getMartBottomBannersStream ${response.body}");
  //       if (response.statusCode == 200) {
  //         final Map<String, dynamic> responseData = json.decode(response.body);
  //         if (responseData['success'] == true) {
  //           List<MartBannerModel> bannerList = [];
  //           List<MartBannerModel> filteredBannerList = [];
  //           for (var bannerData in responseData['data']) {
  //             MartBannerModel banner = MartBannerModel.fromJson({
  //               ...bannerData,
  //               'id': bannerData['id'].toString(),
  //             });
  //             bannerList.add(banner);
  //             print(
  //               "getMartBottomBannersStream ${banner.id} ${banner.categoryId} ${banner.zoneId} ",
  //             );
  //             bool shouldShowBanner = false;
  //             if (banner.zoneId == null || banner.zoneId!.isEmpty) {
  //               shouldShowBanner = true;
  //             } else if (customerZoneId == null || customerZoneId.isEmpty) {
  //               shouldShowBanner = true;
  //             } else if (banner.zoneId == customerZoneId) {
  //               shouldShowBanner = true;
  //             }
  //
  //             if (shouldShowBanner) {
  //               filteredBannerList.add(banner);
  //             }
  //           }
  //
  //           // Sort by set_order in memory
  //           filteredBannerList.sort((a, b) {
  //             int orderA = a.setOrder ?? 0;
  //             int orderB = b.setOrder ?? 0;
  //             return orderA.compareTo(orderB);
  //           });
  //
  //           controller.add(filteredBannerList);
  //         } else {
  //           controller.add(<MartBannerModel>[]);
  //         }
  //       } else {
  //         controller.add(<MartBannerModel>[]);
  //       }
  //     } catch (error) {
  //       controller.add(<MartBannerModel>[]);
  //     }
  //   }
  //
  //   // Initial fetch
  //   fetchBanners();
  //
  //   return controller.stream;
  // }

  /// Initialize banner streams with lazy loading
  void _initializeBannerStreams() {
    getMartBottomBannersStream().listen(
      (banners) {
        martTopBanners = banners;
        notifyListeners();
        if (banners.isNotEmpty) {
          _initializeBannerControllers();
        }
      },
      onError: (error) {
        martTopBanners.clear();
      },
    );
    notifyListeners();
  }

  void _initializeBannerControllers() {
    if (martTopBanners.isNotEmpty && martTopBanners.length > 1) {
      int middlePosition =
          (martTopBanners.length * 1000) ~/
          2; // Start at middle of infinite list
      martTopBannerController = PageController(initialPage: middlePosition);
      currentTopBannerPage.value = 0; // Set indicator to first banner
    } else {
      martTopBannerController = PageController(initialPage: 0);
      currentTopBannerPage.value = 0;
    }
    if (martBottomBanners.isNotEmpty && martBottomBanners.length > 1) {
      int middlePosition =
          (martBottomBanners.length * 1000) ~/
          2; // Start at middle of infinite list
      martBottomBannerController = PageController(initialPage: middlePosition);
      currentBottomBannerPage = 0; // Set indicator to first banner
    } else {
      martBottomBannerController = PageController(initialPage: 0);
      currentBottomBannerPage = 0;
    }
    notifyListeners();
  }

  // Setup search debouncer
  void setupSearchListener() {
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 500), () {
      if (searchQuery.isNotEmpty) {
        performSearch();
      } else {
        clearSearch();
      }
    });
  }

  /// Load mart vendors
  Future<void> loadMartVendors({bool refresh = false}) async {
    try {
      if (refresh) {
        martVendors.clear();
      }
      // Set loading state with timeout
      isVendorLoading = true;
      errorMessage = "";
      // Add timeout to prevent infinite loading
      bool timeoutReached = false;
      Timer? timeoutTimer;

      timeoutTimer = Timer(const Duration(seconds: 15), () {
        timeoutReached = true;
        isVendorLoading = false;
        errorMessage = "Vendor loading timed out. Please try again.";
      });

      try {
        if (timeoutReached) return;

        final vendors = await _firestoreService.getMartVendors();
        if (timeoutReached) return;
        print(
          '[MART CONTROLLER] ✅ Vendors loaded successfully: ${vendors.length} vendors',
        );

        if (refresh) {
          martVendors.clear();
        }
        martVendors.addAll(vendors);

        if (selectedVendorId.isEmpty && vendors.isNotEmpty) {
          final firstVendor = vendors.first;
          selectedVendorId = firstVendor.id!;
          print(
            '[MART CONTROLLER] 🎯 Auto-selected first vendor: ${firstVendor.name} (${firstVendor.id})',
          );
        }

        print('[MART CONTROLLER] ✅ Vendor loading completed successfully');
      } catch (e) {
        if (timeoutReached) return;

        print('[MART CONTROLLER] ❌ Error loading vendors: $e');
        errorMessage =
            "Unable to load stores. Please check your connection and try again.";

        // If no vendors loaded, try to continue with empty state
        if (martVendors.isEmpty) {
          print(
            '[MART CONTROLLER] ⚠️ No vendors available, continuing with empty state',
          );
        }
      } finally {
        timeoutTimer.cancel();
        if (!timeoutReached) {
          isVendorLoading = false;
        }
      }
    } catch (e) {
      print('[MART CONTROLLER] ❌ Unexpected error in loadMartVendors: $e');
      isVendorLoading = false;
      errorMessage = "Something went wrong. Please try again later.";
    }
  }

  /// Load more vendors (pagination)

  /// Select a vendor
  void selectVendor(String vendorId) {
    selectedVendorId = vendorId;
    final vendor = martVendors.firstWhereOrNull((v) => v.id == vendorId);
    currentVendor = vendor;
    selectedVendorName = vendor?.name ?? "Unknown Vendor";

    // Load vendor-specific data
    loadVendorCategories(vendorId: vendorId);
    loadVendorItems(vendorId);
  }

  // ==================== MART CATEGORIES ====================

  /// Load mart categories (Firebase only)

  /// Load all homepage subcategories directly from Firestore
  Future<void> loadAllHomepageSubcategories() async {
    print('loadAllHomepageSubcategories');
    try {
      print(
        '[MART CONTROLLER] 🔄 Loading all homepage subcategories directly from Firestore...',
      );
      isSubcategoryLoading = true;

      // Clear existing subcategories
      subcategoriesMap.clear();

      // Get all homepage subcategories directly
      final allSubcategories = await _firestoreService
          .getAllHomepageSubcategories();

      if (allSubcategories.isNotEmpty) {
        // Group subcategories by parent category for the map
        final Map<String, List<MartSubcategoryModel>> groupedSubcategories = {};

        for (final subcategory in allSubcategories) {
          final parentId = subcategory.parentCategoryId ?? 'unknown';
          if (!groupedSubcategories.containsKey(parentId)) {
            groupedSubcategories[parentId] = [];
          }
          groupedSubcategories[parentId]!.add(subcategory);
        }

        // Update the subcategories map
        subcategoriesMap.addAll(groupedSubcategories);

        print(
          '[MART CONTROLLER] ✅ Loaded ${allSubcategories.length} homepage subcategories from ${groupedSubcategories.length} parent categories',
        );
        print(
          '[MART CONTROLLER] 📊 Subcategories map contains: ${subcategoriesMap.length} category entries',
        );
        subcategoriesMap.forEach((categoryId, subcategoryList) {
          print(
            '[MART CONTROLLER] 📊 Category $categoryId: ${subcategoryList.length} subcategories',
          );
        });

        notifyListeners();
      } else {
        print('[MART CONTROLLER] ⚠️ No homepage subcategories found');
      }
    } catch (e) {
      print('[MART CONTROLLER] ❌ Error loading homepage subcategories: $e');
    } finally {
      isSubcategoryLoading = false;
    }
  }

  /// Debug method to load ALL subcategories (no filters)

  /// Load sub-categories for a specific category
  Future<void> loadSubcategoriesForCategory(String categoryId) async {
    try {
      print(
        '[MART CONTROLLER] 🔄 Loading sub-categories for category: $categoryId',
      );

      final subcategories = await _firestoreService.getSubcategoriesByParent(
        parentCategoryId: categoryId,
        publish: true,
        sortBy: 'subcategory_order',
        sortOrder: 'asc',
      );

      subcategoriesMap[categoryId] = subcategories;
      print(
        '[MART CONTROLLER] ✅ Loaded ${subcategories.length} sub-categories for category: $categoryId',
      );
    } catch (e) {
      print(
        '[MART CONTROLLER] ❌ Error loading sub-categories for category $categoryId: $e',
      );
      subcategoriesMap[categoryId] = [];
    }
  }

  /// Load vendor-specific categories
  Future<void> loadVendorCategories({String? vendorId}) async {
    try {
      isCategoryLoading = true;
      errorMessage = "";
      final categories = await _firestoreService.getFeaturedCategories(
        martId: vendorId,
      );
      martCategories.clear();
      martCategories.addAll(categories);
      if (categories.isNotEmpty) {
        final firstCategory = categories.first;
        if (firstCategory.id != null) {
          selectCategory(firstCategory.id!);
        }
      } else {
        selectedCategoryId = "";
        currentCategory = null;
      }
    } catch (e) {
      print('[MART] Error loading vendor categories: $e');
      errorMessage = "Failed to load vendor categories: $e";
    } finally {
      isCategoryLoading = false;
      notifyListeners();
    }
  }

  /// Select a category
  void selectCategory(String categoryId) {
    selectedCategoryId = categoryId;
    currentCategory = martCategories.firstWhereOrNull(
      (c) => c.id == categoryId,
    );

    // Load category items
    loadCategoryItems(categoryId);
  }

  /// Load featured categories
  Future<void> loadFeaturedCategories() async {
    try {
      final categories = await _firestoreService.getFeaturedCategories(
        martId: selectedVendorId.isNotEmpty ? selectedVendorId : "",
      );
      featuredCategories.clear();
      featuredCategories.addAll(categories);
    } catch (e) {
      print('[MART] Error loading featured categories: $e');
    }
  }

  // ==================== MART ITEMS ====================

  /// Load mart items
  Future<void> loadMartItems({bool refresh = false}) async {
    try {
      isProductLoading = true;
      errorMessage = "";

      if (refresh) {
        martItems.clear();
        filteredItems.clear();
        currentPage = 1;
        hasMoreItems = true;
      }

      print('[MART] Loading mart items...');

      if (selectedVendorId.isEmpty) {
        print('[MART] No vendor selected, skipping item load');
        return;
      }

      final items = await _firestoreService.getMartItems();

      if (refresh) {
        martItems.clear();
        filteredItems.clear();
      }

      martItems.addAll(items);
      filteredItems.addAll(items);
      hasMoreItems = items.length == itemsPerPage;

      print('[MART] Loaded ${items.length} items');
    } catch (e) {
      print('[MART] Error loading items: $e');
      errorMessage = "Failed to load items: $e";
    } finally {
      isProductLoading = false;
    }
  }

  /// Load vendor-specific items
  Future<void> loadVendorItems(String vendorId) async {
    try {
      isProductLoading = true;
      errorMessage = "";

      final items = await _firestoreService.getItemsByVendor(
        vendorId: vendorId,
        categoryId: selectedCategoryId.isNotEmpty ? selectedCategoryId : null,
        limit: itemsPerPage,
      );

      martItems.clear();
      filteredItems.clear();
      martItems.addAll(items);
      filteredItems.addAll(items);
      hasMoreItems = items.length == itemsPerPage;
      currentPage = 1;
    } catch (e) {
      print('[MART] Error loading vendor items: $e');
      errorMessage = "Failed to load vendor items: $e";
    } finally {
      isProductLoading = false;
    }
  }

  /// Load category-specific items
  Future<void> loadCategoryItems(String categoryId) async {
    try {
      isProductLoading = true;
      errorMessage = "";

      print(
        '[MART CONTROLLER] 📂 loadCategoryItems() called for category: $categoryId',
      );

      // Load items for the category without requiring a specific vendor
      final items = await _firestoreService.getItemsByCategoryOnly(
        categoryId: categoryId,
        isAvailable: true,
        limit: 50,
      );

      print(
        '[MART CONTROLLER] ✅ Loaded ${items.length} items for category $categoryId',
      );

      // Clear existing items and add new ones
      martItems.clear();
      filteredItems.clear();
      martItems.addAll(items);
      filteredItems.addAll(items);

      // Update selected category
      selectedCategoryId = categoryId;
      currentCategory = martCategories.firstWhereOrNull(
        (c) => c.id == categoryId,
      );

      print(
        '[MART CONTROLLER] ✅ Category items loading completed successfully',
      );
    } catch (e) {
      print('[MART CONTROLLER] ❌ Error loading category items: $e');
      errorMessage = "Unable to load products. Please try again later.";
    } finally {
      isProductLoading = false;
    }
  }

  /// Load more items (pagination)
  Future<void> loadMoreItems() async {
    if (!hasMoreItems || isProductLoading) return;

    currentPage++;
    await loadMartItems();
  }

  /// Load featured items
  Future<void> loadFeaturedItems() async {
    try {
      if (selectedVendorId.isEmpty) {
        print('[MART] No vendor selected, skipping featured items load');
        return;
      }

      final items = await _firestoreService.getFeaturedItems(limit: 20);
      featuredItems.clear();
      featuredItems.addAll(items);
    } catch (e) {
      print('[MART] Error loading featured items: $e');
    }
  }

  /// Load items on sale
  Future<void> loadItemsOnSale() async {
    try {
      if (selectedVendorId.isEmpty) {
        print('[MART] No vendor selected, skipping items on sale load');
        return;
      }

      final items = await _firestoreService.getItemsOnSale(limit: 20);
      itemsOnSale.clear();
      itemsOnSale.addAll(items);
    } catch (e) {
      print('[MART] Error loading items on sale: $e');
    }
  }

  // ==================== LEGACY METHODS (for backward compatibility) ====================

  /// Load products by category (legacy method)
  Future<void> loadProductsByCategory(
    String categoryId, {
    bool refresh = false,
  }) async {
    selectCategory(categoryId);
  }

  /// Load spotlight items (legacy method)
  Future<void> loadSpotlightItems() async {
    try {
      // For now, we'll use featured items as spotlight items
      await loadFeaturedItems();
      spotlightItems.clear();
      spotlightItems.addAll(
        featuredItems
            .map(
              (item) => {
                'id': item.id,
                'name': item.displayName,
                'image': item.mainImage,
                'price': item.currentPrice,
                'description': item.displayDescription,
              },
            )
            .toList(),
      );
    } catch (e) {
      print('[MART] Error loading spotlight items: $e');
    }
  }

  /// Load steals items (legacy method)
  Future<void> loadStealsItems() async {
    try {
      // For now, we'll use items on sale as steals items
      await loadItemsOnSale();
      stealsItems.clear();
      stealsItems.addAll(
        itemsOnSale
            .map(
              (item) => {
                'id': item.id,
                'name': item.displayName,
                'image': item.mainImage,
                'price': item.currentPrice,
                'originalPrice': item.originalPrice,
                'discount': item.calculatedDiscountPercentage,
                'description': item.displayDescription,
              },
            )
            .toList(),
      );
    } catch (e) {
      print('[MART] Error loading steals items: $e');
    }
  }

  // ==================== SEARCH AND FILTERS ====================

  /// Perform search
  Future<void> performSearch() async {
    if (searchQuery.isEmpty) return;

    try {
      isProductLoading = true;
      errorMessage = "";

      if (selectedVendorId.isEmpty) {
        print('[MART] No vendor selected, cannot search items');
        errorMessage = "Please select a vendor first";
        return;
      }

      final items = await _firestoreService.searchItems(
        searchQuery: searchQuery,
        limit: itemsPerPage,
      );

      filteredItems.clear();
      filteredItems.addAll(items);
    } catch (e) {
      print('[MART] Error searching items: $e');
      errorMessage = "Failed to search items: $e";
    } finally {
      isProductLoading = false;
    }
  }

  /// Clear search
  void clearSearch() {
    searchQuery = "";
    filteredItems.clear();
    filteredItems.addAll(martItems);
  }

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery = query;
    _searchDebouncer?.cancel();
    setupSearchListener();
  }

  /// Apply filters
  void applyFilters({
    bool? vegOnly,
    bool? nonVegOnly,
    bool? availableOnly,
    String? sortBy,
    bool? sortAscending,
  }) {
    if (vegOnly != null) filterVegOnly = vegOnly;
    if (nonVegOnly != null) filterNonVegOnly = nonVegOnly;
    if (availableOnly != null) filterAvailableOnly = availableOnly;
    if (sortBy != null) selectedSortBy = sortBy;
    if (sortAscending != null) this.sortAscending = sortAscending;

    // Reload items with new filters
    loadMartItems(refresh: true);
  }

  /// Clear all filters
  void clearFilters() {
    filterVegOnly = false;
    filterNonVegOnly = false;
    filterAvailableOnly = true;
    selectedSortBy = "name";
    sortAscending = true;
    loadMartItems(refresh: true);
  }

  // ==================== UTILITY METHODS ====================

  /// Refresh all data

  /// Get item by ID
  Future<MartItemModel?> getItemById(String itemId) async {
    try {
      return await _firestoreService.getItemById(itemId);
    } catch (e) {
      print('[MART] Error getting item by ID: $e');
      return null;
    }
  }

  /// Get vendor details

  // ==================== LEGACY COMPATIBILITY METHODS ====================

  /// Add to cart (legacy method)

  /// Remove from cart (legacy method)
  void removeFromCart(String itemId) {
    cartItems.removeWhere((item) => item.id == itemId);
    print(
      '[MART] Removed item $itemId from cart. Total items: ${cartItems.length}',
    );
  }

  // ==================== GETTERS ====================

  /// Get current vendor name
  String get currentVendorName => currentVendor?.displayName ?? 'All Marts';

  /// Get current category name
  String get currentCategoryName =>
      currentCategory?.displayName ?? 'All Categories';

  /// Get total items count
  int get totalItemsCount => filteredItems.length;

  /// Get total vendors count
  int get totalVendorsCount => martVendors.length;

  /// Get total categories count
  int get totalCategoriesCount => martCategories.length;

  // ==================== LEGACY COMPATIBILITY GETTERS ====================

  /// Legacy: filteredProducts (maps to filteredItems)
  List<MartItemModel> get filteredProducts => filteredItems;

  /// Legacy: hasMoreProducts (maps to hasMoreItems)
  bool get hasMoreProducts => hasMoreItems;

  /// Legacy: loadMoreProducts (maps to loadMoreItems)
  Future<void> loadMoreProducts() => loadMoreItems();

  /// Legacy: cartItemCount
  int get cartItemCount => cartItems.length;

  /// Legacy: cartTotal
  double get cartTotal {
    return cartItems.fold(0.0, (total, item) {
      return total + item.currentPrice;
    });
  }

  /// Legacy: getProductById (maps to getItemById)
  Future<MartItemModel?> getProductById(String productId) async {
    return await getItemById(productId);
  }

  /// Load trending items from API

  /// Comprehensive search across categories, items, and subcategories

  /// Search categories with debouncing

  // ==================== STREAMING DATA LOADING METHODS ====================
  Future<void> loadHomepageCategoriesStreaming({int limit = 10}) async {
    try {
      print(
        '[MART CONTROLLER] 🏠 Streaming: Loading homepage categories from Firestore...',
      );
      isCategoryLoading = true;
      // Try Firestore first (fastest path)
      try {
        print(
          '[MART CONTROLLER] 🔥 Calling Firestore service for homepage categories...',
        );
        final categories = await _firestoreService.getHomepageCategories(
          limit: limit,
        );
        if (categories.isNotEmpty) {
          // Stream the data as it becomes available
          featuredCategories.clear();
          featuredCategories.addAll(categories);

          // Clear any previous error messages
          errorMessage = '';
          print(
            '[MART CONTROLLER] ✅ Streaming: Homepage categories loaded from Firestore (${categories.length})',
          );
          isCategoryLoading = false;
          isHomepageCategoriesLoaded = true;
          return;
        } else {
          print('[MART CONTROLLER] ⚠️ No homepage categories from Firestore');
        }
      } catch (e) {
        print(
          '[MART CONTROLLER] ❌ Firestore failed: $e, trying API fallback...',
        );
      }

      // No API fallback - Firestore only
      print('[MART CONTROLLER] ❌ Firestore failed, no API fallback available');
      errorMessage =
          'Unable to load categories from Firestore. Please check your connection.';
      isCategoryLoading = false;
      isHomepageCategoriesLoaded = false;
    } catch (e) {
      print(
        '[MART CONTROLLER] ❌ Streaming: Error loading homepage categories: $e',
      );
      isCategoryLoading = false;
    }
  }

  /// Load trending items with streaming updates using Firestore
  Future<void> loadTrendingItemsStreaming() async {
    try {
      print(
        '[MART CONTROLLER] 🔥 Streaming: Loading trending items from Firestore...',
      );
      isTrendingLoading = true;

      // Try to get trending items from existing data first (fastest)
      if (martItems.isNotEmpty) {
        print(
          '[MART CONTROLLER] 🚀 Fast path: Filtering trending items from existing data',
        );
        final trendingFromExisting = martItems
            .where((item) => item.isTrending == true)
            .toList();
        if (trendingFromExisting.isNotEmpty) {
          trendingItems.clear();
          trendingItems.addAll(trendingFromExisting);
          print(
            '[MART CONTROLLER] ✅ Fast path: Found ${trendingFromExisting.length} trending items from existing data',
          );
          isTrendingLoading = false;
          return;
        }
      }

      // Load trending items from Firestore (primary method)
      print('[MART CONTROLLER] 🔥 Firestore: Fetching trending items...');
      try {
        final items = await _firestoreService.getTrendingItems(limit: 20);
        if (items.isNotEmpty) {
          // Stream the data as it becomes available
          trendingItems.clear();
          trendingItems.addAll(items);
          print(
            '[MART CONTROLLER] ✅ Firestore: Trending items loaded (${items.length})',
          );
        } else {
          // Fallback: Load all items and filter for trending
          print(
            '[MART CONTROLLER] 🔄 Fallback: Loading all items and filtering for trending...',
          );
          await _loadAllItemsAndFilterTrending();
        }
      } catch (e) {
        print('[MART CONTROLLER] ❌ Firestore failed: $e');
        // No API fallback - Firestore only
        print(
          '[MART CONTROLLER] ❌ No API fallback available for trending items',
        );
        trendingItems.clear();
      }

      isTrendingLoading = false;
    } catch (e) {
      print('[MART CONTROLLER] ❌ Streaming: Error loading trending items: $e');
      // No API fallback - Firestore only
      print('[MART CONTROLLER] ❌ No API fallback available for trending items');
      trendingItems.clear();
      isTrendingLoading = false;
    }
  }

  /// Fast fallback: Load all items and filter for trending
  Future<void> _loadAllItemsAndFilterTrending() async {
    try {
      print('[MART CONTROLLER] 🔄 Fallback: Loading all items...');

      // Load items with API-compliant limit to avoid validation errors
      final allItems = await _firestoreService.getMartItems();

      // Filter for trending items
      final trendingFromAll = allItems
          .where((item) => item.isTrending == true)
          .toList();

      // Update trending items
      trendingItems.clear();
      trendingItems.addAll(trendingFromAll);

      print(
        '[MART CONTROLLER] ✅ Fallback: Found ${trendingFromAll.length} trending items from all items',
      );
    } catch (e) {
      print('[MART CONTROLLER] ❌ Fallback: Error loading all items: $e');
      trendingItems.clear();
    }
  }

  /// Load featured items with streaming updates using Firestore
  Future<void> loadFeaturedItemsStreaming() async {
    try {
      print(
        '[MART CONTROLLER] ⭐ Streaming: Loading featured items from Firestore...',
      );
      isProductLoading = true;

      // Load featured items from Firestore
      final items = await _firestoreService.getFeaturedItems(limit: 20);

      // Stream the data as it becomes available
      featuredItems.clear();
      featuredItems.addAll(items);

      print(
        '[MART CONTROLLER] ✅ Streaming: Featured items loaded from Firestore (${items.length})',
      );
      isProductLoading = false;
    } catch (e) {
      print(
        '[MART CONTROLLER] ❌ Streaming: Error loading featured items from Firestore: $e',
      );
      // No API fallback - Firestore only
      print('[MART CONTROLLER] ❌ No API fallback available for featured items');
      featuredItems.clear();
      isProductLoading = false;
    }
  }

  /// Load categories with streaming updates using Firestore
  Future<void> loadCategoriesStreaming() async {
    try {
      print(
        '[MART CONTROLLER] 📂 Streaming: Loading all categories from Firestore...',
      );
      // Try Firestore first (fastest path)
      try {
        final categories = await _firestoreService.getCategories(limit: 100);
        if (categories.isNotEmpty) {
          // Stream the data as it becomes available
          martCategories.clear();
          martCategories.addAll(categories);

          print(
            '[MART CONTROLLER] ✅ Streaming: All categories loaded from Firestore (${categories.length})',
          );
          // Load subcategories for categories that have them
          // await _loadSubcategoriesStreaming();
          // await loadAllHomepageSubcategories();
          await loadFirstPageHomepageSubcategories();
          return;
        } else {
          print(
            '[MART CONTROLLER] ⚠️ No categories from Firestore, trying API fallback...',
          );
        }
      } catch (e) {
        print(
          '[MART CONTROLLER] ❌ Firestore failed: $e, trying API fallback...',
        );
      }

      // No API fallback - Firestore only
      print('[MART CONTROLLER] ❌ Firestore failed, no API fallback available');
      errorMessage =
          'Unable to load categories from Firestore. Please check your connection.';
    } catch (e) {
      print('[MART CONTROLLER] ❌ Streaming: Error loading categories: $e');
    }
  }

  //changed here _loadSubcategoriesStreaming
  /// Load subcategories with streaming updates

  /// Load subcategories for a specific category with streaming
  Future<void> loadSubcategoriesStreaming(String categoryId) async {
    try {
      print(
        '[MART CONTROLLER] 📋 Loading subcategories for category: $categoryId',
      );
      isSubcategoryLoading = true;

      final subcategories = await _firestoreService.getSubcategoriesByParent(
        parentCategoryId: categoryId,
        publish: true,
        sortBy: 'subcategory_order',
        sortOrder: 'asc',
      );

      this.subcategories = subcategories;
      print(
        '[MART CONTROLLER] ✅ Loaded ${subcategories.length} subcategories for category: $categoryId',
      );
    } catch (e) {
      print('[MART CONTROLLER] ❌ Error loading subcategories: $e');
      errorMessage = 'Unable to load subcategories. Please try again later.';
    } finally {
      isSubcategoryLoading = false;
    }
  }

  /// Load vendors with streaming updates
  Future<void> _loadVendorsStreaming() async {
    try {
      print('[MART CONTROLLER] 🏪 Streaming: Loading vendors...');
      // Load vendors
      final vendors = await _firestoreService.getMartVendors();
      if (vendors.isNotEmpty) {
        martVendors.clear();
        martVendors.addAll(vendors);
        if (selectedVendorId.isEmpty) {
          selectVendor(vendors.first.id!);
          print(
            '[MART CONTROLLER] 🎯 Streaming: Auto-selected first vendor: ${vendors.first.name}',
          );

          // Load additional data now that we have a vendor
          await _loadAdditionalDataStreaming();
        }

        print(
          '[MART CONTROLLER] ✅ Streaming: Vendors loaded (${vendors.length})',
        );
      } else {
        print('[MART CONTROLLER] ⚠️ Streaming: No vendors found');
        // Still try to load additional data with dummy vendor
        await _loadAdditionalDataStreaming();
      }
    } catch (e) {
      print('[MART CONTROLLER] ❌ Streaming: Error loading vendors: $e');
      // Still try to load additional data
      await _loadAdditionalDataStreaming();
    }
  }

  /// Load additional data with streaming updates
  Future<void> _loadAdditionalDataStreaming() async {
    try {
      print('[MART CONTROLLER] 📦 Streaming: Loading additional data...');

      // Load items on sale if we have a vendor
      if (selectedVendorId.isNotEmpty) {
        await _loadItemsOnSaleStreaming();
      }

      print('[MART CONTROLLER] ✅ Streaming: Additional data loaded');
    } catch (e) {
      print(
        '[MART CONTROLLER] ⚠️ Streaming: Error loading additional data: $e',
      );
    }
  }

  /// Load items on sale with streaming updates
  Future<void> _loadItemsOnSaleStreaming() async {
    try {
      print('[MART CONTROLLER] 🏷️ Streaming: Loading items on sale...');

      final items = await _firestoreService.getMartItems();

      final saleItems = items.where((item) => item.isOnSale == true).toList();

      // Stream the data as it becomes available
      itemsOnSale.clear();
      itemsOnSale.addAll(saleItems);
      print(
        '[MART CONTROLLER] ✅ Streaming: Items on sale loaded (${saleItems.length})',
      );
    } catch (e) {
      print('[MART CONTROLLER] ❌ Streaming: Error loading items on sale: $e');
    }
  }

  /// Manually trigger streaming data refresh
  Future<void> refreshStreamingData() async {
    try {
      print('[MART CONTROLLER] 🔄 Manual streaming refresh triggered...');
      await Future.wait([
        loadHomepageCategoriesStreaming(limit: 10),
        loadTrendingItemsStreaming(),
        loadFeaturedItemsStreaming(),
        loadCategoriesStreaming(),
        _loadVendorsStreaming(),
      ]);

      print('[MART CONTROLLER] ✅ Manual streaming refresh completed');
    } catch (e) {
      print('[MART CONTROLLER] ❌ Error in manual streaming refresh: $e');
    }
  }

  // ==================== SIMILAR PRODUCTS STREAM ====================

  /// Stream all products from mart_items collection
  Stream<List<MartItemModel>> streamAllProducts({
    String? excludeProductId,
    bool? isAvailable,
    int limit = 10,
  }) {
    try {
      print('[MART CONTROLLER] 📡 Starting all products stream');
      if (excludeProductId != null) {
        print('[MART CONTROLLER] 📡 Excluding product: $excludeProductId');
      }

      // Use the Firestore service stream method for all products
      return _firestoreService.streamAllProducts(
        excludeProductId: excludeProductId,
        isAvailable: isAvailable,
        limit: limit,
      );
    } catch (e) {
      print('[MART CONTROLLER] ❌ Error creating all products stream: $e');
      return Stream<List<MartItemModel>>.empty();
    }
  }

  // ==================== SECTION-SPECIFIC PRODUCT STREAMS ====================

  // ==================== BANNER METHODS ====================

  /// Handle banner tap based on redirect type

  /// Fetch delivery settings from Firestore (DEPRECATED - Use settings/martDeliveryCharge instead)
  Future<void> fetchDeliverySettings() async {
    try {
      print('[MART CONTROLLER] 🚚 Fetching delivery settings from API');
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}mobile/settings/mart-delivery-charge'),
        headers: await getHeaders(),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'];
          deliverySettings = MartDeliverySettingsModel(
            freeDeliveryThreshold:
                (data['item_total_threshold'] as num?)?.toDouble() ?? 199.0,
            deliveryPromotionText: data['delivery_promotion_text'] ?? 'Daily',
            isActive: data['is_active'] ?? true,
            minOrderValue:
                (data['min_order_value'] as num?)?.toDouble() ?? 99.0,
            minOrderMessage:
                data['min_order_message'] ?? 'Min Item value is ₹99',
          );

          print('[MART CONTROLLER] ✅ Delivery settings fetched successfully');
        } else {
          throw Exception("API returned unsuccessful response");
        }
      } else {
        throw Exception(
          "Failed to fetch delivery settings: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('[MART CONTROLLER] ❌ Error fetching delivery settings: $e');

      // Fallback to default values
      deliverySettings = MartDeliverySettingsModel(
        freeDeliveryThreshold: 199.0,
        deliveryPromotionText: 'Daily',
        isActive: true,
        minOrderValue: 99.0,
        minOrderMessage: 'Min Item value is ₹99',
      );
    }
  }

  /// Get formatted delivery message
  String get deliveryMessage {
    final threshold = deliverySettings?.freeDeliveryThreshold ?? 199.0;
    return 'Spend ₹${threshold.toInt()} to unlock FREE delivery';
  }

  /// Get delivery promotion text
  String get deliveryPromotionText {
    return deliverySettings?.deliveryPromotionText ?? 'daily';
  }

  /// Check if delivery settings are active
  bool get isDeliverySettingsActive {
    return deliverySettings?.isActive ?? true;
  }

  /// Get minimum order value for mart items
  double get minOrderValue {
    return deliverySettings?.minOrderValue ?? 99.0;
  }

  /// Check if minimum order is enabled
  bool get isMinOrderEnabled {
    return deliverySettings?.minOrderEnabled ?? true;
  }

  /// Get minimum order message
  String get minOrderMessage {
    return deliverySettings?.minOrderMessage ??
        'Minimum order value is ₹99. Please add more items to your cart.';
  }

  /// Check if app is in maintenance mode
  bool get isMaintenanceMode {
    return deliverySettings?.maintenanceMode ?? false;
  }

  /// Get maintenance message
  String get maintenanceMessage {
    return deliverySettings?.maintenanceMessage ??
        'App is under maintenance. Please try again later.';
  }

  // ==================== SECTIONS LOADING ====================

  /// Load sections in true parallel (immediate and fast)
  Future<void> _loadSectionsInParallel() async {
    try {
      print('[MART CONTROLLER] ==========================================');
      print(
        '[MART CONTROLLER] 📂 _loadSectionsInParallel() called - TRUE PARALLEL LOADING',
      );
      print('[MART CONTROLLER] ==========================================');

      // Start loading sections and products in parallel immediately
      final sectionsFuture = _firestoreService.getUniqueSections();
      // Get sections first
      final sections = await sectionsFuture;
      print(
        '[MART CONTROLLER] 📂 Found ${sections.length} unique sections: $sections',
      );
      if (sections.isNotEmpty) {
        // Clear and add sections immediately
        availableSections.clear();
        availableSections.addAll(sections);

        // Safely trigger UI update
        Future.microtask(() {
          notifyListeners();
        });

        // Load products for ALL sections in parallel simultaneously
        final productFutures = sections.map(
          (section) => _loadProductsForSectionAsync(section),
        );

        // Don't wait for all products - let them load in background
        Future.wait(productFutures)
            .then((_) {
              print(
                '[MART CONTROLLER] ✅ All section products loaded in parallel: ${sections.length} sections',
              );
              // Trigger UI update when products are loaded
              Future.microtask(() {
                notifyListeners();
              });
            })
            .catchError((e) {
              print(
                '[MART CONTROLLER] ❌ Error loading some section products: $e',
              );
            });

        print(
          '[MART CONTROLLER] ✅ Sections loaded immediately: ${sections.length} sections',
        );
      } else {
        print('[MART CONTROLLER] ⚠️ No sections found');
      }
    } catch (e) {
      print('[MART CONTROLLER] ❌ Error loading sections in parallel: $e');
    }
  }

  /// Load sections progressively (silent streaming - no loading state)
  Future<void> _loadSectionsProgressively() async {
    try {
      print('[MART CONTROLLER] ==========================================');
      print(
        '[MART CONTROLLER] 📂 _loadSectionsProgressively() called - SILENT STREAMING',
      );
      print('[MART CONTROLLER] ==========================================');

      // Get all unique sections from mart_items collection
      final sections = await _firestoreService.getUniqueSections();
      print(
        '[MART CONTROLLER] 📂 Found ${sections.length} unique sections: $sections',
      );

      if (sections.isNotEmpty) {
        availableSections.clear();
        availableSections.addAll(sections);

        // Load products for each section in parallel (silent streaming)
        final futures = sections.map(
          (section) => _loadProductsForSectionAsync(section),
        );
        await Future.wait(futures);

        print(
          '[MART CONTROLLER] ✅ Sections loaded silently: ${sections.length} sections',
        );
      } else {
        print('[MART CONTROLLER] ⚠️ No sections found');
      }
    } catch (e) {
      print('[MART CONTROLLER] ❌ Error loading sections silently: $e');
    }
  }

  /// Load products for a specific section (async, non-blocking)
  Future<void> _loadProductsForSectionAsync(String section) async {
    try {
      print('[MART CONTROLLER] 📂 Loading products for section: $section');

      final products = await _firestoreService.getItemsBySection(
        section: section,
      );

      sectionProducts[section] = products;
      print(
        '[MART CONTROLLER] ✅ Loaded ${products.length} products for section: $section',
      );
    } catch (e) {
      print(
        '[MART CONTROLLER] ❌ Error loading products for section $section: $e',
      );
      sectionProducts[section] = [];
    }
  }

  /// Get products for a specific section
  List<MartItemModel> getProductsForSection(String section) {
    return sectionProducts[section] ?? [];
  }

  /// Stream products by brand ID
  Stream<List<MartItemModel>> streamProductsByBrand(String brandID) {
    try {
      print('[MART CONTROLLER] 🔍 Streaming products for brand: $brandID');

      return _firestoreService.streamItemsByBrand(brandID).map((products) {
        print(
          '[MART CONTROLLER] 📦 Received ${products.length} products for brand: $brandID',
        );
        return products;
      });
    } catch (e) {
      print('[MART CONTROLLER] ❌ Error streaming products by brand: $e');
      return Stream<List<MartItemModel>>.empty();
    }
  }

  /// Load sections from Firebase (public method for manual refresh)
  Future<void> loadSectionsFromFirebase() async {
    await _loadSectionsProgressively();
  }

  /// Load sections immediately (true parallel loading - no loading state)
  Future<void> loadSectionsImmediately() async {
    try {
      // Prevent multiple loading attempts
      if (_sectionsLoadingTriggered) {
        print(
          '[MART CONTROLLER] ⚠️ Sections loading already triggered, skipping...',
        );
        return;
      }

      _sectionsLoadingTriggered = true;
      print('[MART CONTROLLER] 🚀 Loading sections in true parallel...');

      // Use the new parallel loading method
      await _loadSectionsInParallel();
    } catch (e) {
      print('[MART CONTROLLER] ❌ Error loading sections in parallel: $e');
      _sectionsLoadingTriggered = false; // Reset flag on error
    }
  }

  /// Force load sections (silent fallback method)
  Future<void> forceLoadSections() async {
    try {
      print('[MART CONTROLLER] 🔄 Force loading sections silently...');
      availableSections.clear();
      sectionProducts.clear();

      await loadSectionsImmediately();
    } catch (e) {
      print('[MART CONTROLLER] ❌ Error force loading sections: $e');
    }
  }

  /// Test method to manually add some sections for debugging
  void addTestSections() {
    // Only add test sections if no sections are loaded yet
    if (availableSections.isNotEmpty) {
      print(
        '[MART CONTROLLER] 🧪 Sections already loaded, skipping test sections',
      );
      return;
    }

    print('[MART CONTROLLER] 🧪 Adding test sections for debugging...');
    availableSections.clear();
    availableSections.addAll([
      'Pet Care',
      'General',
      'Essentials & Daily Needs',
    ]);
    print(
      '[MART CONTROLLER] 🧪 Test sections added: ${availableSections.length} sections',
    );

    // Use Future.microtask to safely trigger UI update
    Future.microtask(() {
      notifyListeners();
    });
  }

  //////[MART SUB CATEGORY CONTROLLER]
  // New pagination properties
  final List<DocumentSnapshot> _lastDocuments = <DocumentSnapshot>[];
  bool _hasMoreSubcategories = true;
  int _currentPage = 0;

  bool get hasMoreSubcategories => _hasMoreSubcategories;

  int get currentPageAll => _currentPage;

  int get loadedSubcategoriesCount {
    int total = 0;
    subcategoriesMap.forEach((key, value) {
      total += value.length;
    });
    return total;
  }

  /// Load first page of homepage subcategories
  Future<void> loadFirstPageHomepageSubcategories() async {
    try {
      print('[MART] 🔄 Loading first page of subcategories...');
      _lastDocuments.clear();
      _currentPage = 0;
      _hasMoreSubcategories = true;
      final result = await _firestoreService.getHomepageSubcategoriesPaginated(
        limit: 10,
      );
      final subcategories =
          result['subcategories'] as List<MartSubcategoryModel>;
      final lastDoc = result['lastDocument'] as DocumentSnapshot?;

      if (subcategories.isNotEmpty) {
        _groupAndAddSubcategories(subcategories);

        // 🔧 Store last document for pagination
        if (lastDoc != null) _lastDocuments.add(lastDoc);

        _currentPage = 1;
        _hasMoreSubcategories = (subcategories.length == 10);

        print('[MART] ✅ Loaded first ${subcategories.length} subcategories.');
      } else {
        _hasMoreSubcategories = false;
        print('[MART] ⚠️ No subcategories found.');
      }
    } catch (e) {
      print('[MART] ❌ Error loading first page: $e');
    }
  }

  /// Load next page
  Future<void> loadMoreHomepageSubcategories() async {
    if (!_hasMoreSubcategories) {
      print('[MART] ⚠️ No more pages left.');
      return;
    }

    try {
      print('[MART] 🔄 Loading page ${_currentPage + 1}...');

      final result = await _firestoreService.getHomepageSubcategoriesPaginated(
        limit: 10,
      );

      final nextPageSubcategories =
          result['subcategories'] as List<MartSubcategoryModel>;
      final lastDoc = result['lastDocument'] as DocumentSnapshot?;

      if (nextPageSubcategories.isNotEmpty) {
        _groupAndAddSubcategories(nextPageSubcategories);

        // 🔧 Update last document for next page
        if (lastDoc != null) _lastDocuments.add(lastDoc);

        _currentPage += 1;
        _hasMoreSubcategories = (nextPageSubcategories.length == 10);

        print('[MART] ✅ Page ${_currentPage} loaded.');
      } else {
        _hasMoreSubcategories = false;
        print('[MART] ⚠️ No more subcategories to load.');
      }
    } catch (e) {
      print('[MART] ❌ Error loading next page: $e');
    }
  }

  /// Grouping function (example)
  void _groupAndAddSubcategories(List<MartSubcategoryModel> subcategories) {
    for (final subcategory in subcategories) {
      // Use the correct field from your model:
      final parentId = subcategory.parentCategoryId ?? 'unknown';

      // Ensure list exists for this parent
      subcategoriesMap.putIfAbsent(parentId, () => <MartSubcategoryModel>[]);
      // Avoid duplicates (by id)
      final exists = subcategoriesMap[parentId]!.any(
        (existing) => existing.id == subcategory.id,
      );
      if (!exists) {
        subcategoriesMap[parentId]!.add(subcategory);
      }
    }
    // If subcategoriesMap is an RxMap, force update
    notifyListeners();
  }

  /// Get all homepage subcategories from the map (for UI display)
  List<MartSubcategoryModel> get allHomepageSubcategories {
    final allSubcategories = <MartSubcategoryModel>[];
    subcategoriesMap.forEach((parentId, subcategoryList) {
      allSubcategories.addAll(subcategoryList);
    });

    // Sort by order to maintain consistency
    allSubcategories.sort(
      (a, b) => (a.subcategoryOrder ?? 0).compareTo(b.subcategoryOrder ?? 0),
    );

    return allSubcategories;
  }

  /// Get homepage subcategories filtered by show_in_homepage flag
  List<MartSubcategoryModel> get homepageSubcategories {
    return allHomepageSubcategories
        .where((subcategory) => subcategory.showInHomepage == true)
        .toList();
  }

  // Keep your existing method for backward compatibility, but mark as deprecated
}
