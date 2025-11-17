import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/trie_search.dart';
import 'package:jippymart_customer/constant/collection_name.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class SwiggySearchProvider extends ChangeNotifier {
  /// **CLEAR RECENT SEARCHES**
  void clearRecentSearches() {
    try {
      print("🗑️ Clearing recent searches...");

      // Clear the observable list
      recentSearches.clear();

      // Clear from shared preferences
      _clearRecentSearchesFromStorage();

      print("✅ Recent searches cleared successfully");
    } catch (e) {
      print("❌ Error clearing recent searches: $e");
    }
  }

  /// **CLEAR RECENT SEARCHES FROM STORAGE**
  Future<void> _clearRecentSearchesFromStorage() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_searches');
      print("✅ Recent searches cleared from storage");
    } catch (e) {
      print("❌ Error clearing recent searches from storage: $e");
    }
  }

  final TrieSearch trieSearch = TrieSearch();

  var recentSearches = <String>[];
  var trendingSearches = <String>[];
  var restaurantResults = <VendorModel>[];
  var productResults = <ProductModel>[];
  var categoryResults = <VendorCategoryModel>[];
  var searchSuggestions = <String>[];

  // **SEARCH STATE**
  var isSearching = false;
  var showSuggestions = false;
  var searchText = '';
  var hasSearched = false;

  // **LOADING STATE**
  bool isLoadingData = false;

  bool dataLoaded = false;

  // **PAGINATION STATE**
  var isLoadingMore = false;
  var hasMoreResults = true;
  var currentResultCount = 0;
  var totalAvailableResults = 0;

  // **REMAINING RESULTS FOR PAGINATION**
  List<ProductModel> _remainingProducts = [];
  List<VendorModel> _remainingRestaurants = [];
  List<VendorCategoryModel> _remainingCategories = [];

  // **FIRESTORE PAGINATION CURSORS**

  // **DEBOUNCE TIMER**
  Timer? _debounceTimer;
  Timer? _searchTimer;

  // **CONSTANTS - MEMORY SAFE LIMITS TO PREVENT CRASHES**
  static const int MAX_RECENT_SEARCHES = 10;
  static const int MAX_SUGGESTIONS = 8;
  static const int INITIAL_PRODUCTS =
      100; // Show only 8 products initially to ensure Load More button shows
  static const int INITIAL_RESTAURANTS =
      10; // Show only 5 restaurants initially to ensure Load More button shows
  static const int LOAD_MORE_RESULTS = 10; // Load 5 more at a time
  static const int MAX_TOTAL_RESULTS =
      1000; // Increased to match admin panel results
  static const Duration DEBOUNCE_DELAY = Duration(milliseconds: 300);

  // **MEMORY SAFE LIMITS - INCREASED TO MATCH ADMIN PANEL**
  static const int FAST_VENDOR_LIMIT = 500; // Increased to show more vendors
  static const int FAST_PRODUCT_LIMIT = 800; // Increased to show more products
  static const int MAX_VENDORS_PER_SEARCH =
      500; // Increased to show more vendors in search
  static const int MAX_PRODUCTS_PER_SEARCH =
      800; // Increased to show more products in search
  static const int SUGGESTION_LIMIT = 10; // Maximum suggestions to show

  // **ENHANCED MULTI-COLLECTION SEARCH LIMITS - INCREASED TO MATCH ADMIN PANEL**
  static const int RESTAURANT_SEARCH_LIMIT =
      500; // Restaurants per search (increased from 50)
  static const int PRODUCT_SEARCH_LIMIT =
      800; // Products per search (increased from 100)
  static const int CATEGORY_SEARCH_LIMIT =
      200; // Categories per search (increased from 20)

  void initFunction() {
    _initializeSearch();
  }

  void onClose() {
    _debounceTimer?.cancel();
    _searchTimer?.cancel();
  }

  /// **INITIALIZE SEARCH SYSTEM**
  Future<void> _initializeSearch() async {
    try {
      isLoadingData = true;
      notifyListeners();
      // Load recent searches from storage (fast)
      await _loadRecentSearches();

      // Load trending searches (fast)
      await _loadTrendingSearches();

      isLoadingData = false;
      notifyListeners();
      // Load and index data in background (slow)
      _loadAndIndexDataInBackground();

      print("✅ Swiggy Search initialized successfully");
    } catch (e) {
      print("❌ Search initialization failed: $e");
      isLoadingData = false;
      notifyListeners();
    }
  }

  /// **LOAD AND INDEX DATA IN BACKGROUND**
  Future<void> _loadAndIndexDataInBackground() async {
    try {
      print("🔄 Loading initial data in background...");
      await _loadAndIndexData();
      dataLoaded = true;
      notifyListeners();

      // Check if data was loaded successfully
      if (trieSearch.itemCount == 0) {
        print(
          "⚠️ No data loaded from database - search will use direct Firestore queries",
        );
      }

      // Test the Trie with a simple search
      _testTrieSearch();

      // Continue loading more data progressively
      _loadMoreDataProgressively();
    } catch (e) {
      print("❌ Background data loading failed: $e");
    }
  }

  /// **TEST TRIE SEARCH**
  void _testTrieSearch() {
    try {
      print("🧪 Testing Trie search...");

      // Test with common search terms
      var testQueries = ["pizza", "biryani", "chicken", "spicy", "restaurant"];

      for (var query in testQueries) {
        var results = trieSearch.search(query);
        notifyListeners();
        print("🧪 Test search '$query': ${results.length} results");
      }
    } catch (e) {
      print("❌ Trie test failed: $e");
    }
  }

  /// **LOAD MORE DATA PROGRESSIVELY IN BACKGROUND - MEMORY OPTIMIZED**
  Future<void> _loadMoreDataProgressively() async {
    try {
      print("🔄 Loading additional data progressively (memory optimized)...");

      // **MEMORY SAFE: Use smaller limits for progressive loading**
      // Load more vendors with strict limits
      // List<VendorModel> moreVendors = await FireStoreUtils.getAllVendors(
      //   limit: 10,
      // );
      final String? zoneId = Constant.selectedZone?.id;
      final double latitude =
          Constant.selectedLocation.location?.latitude ?? 0.0;
      final double longitude =
          Constant.selectedLocation.location?.longitude ?? 0.0;

      if (zoneId == null || zoneId.isEmpty) {
        print('[DEBUG] No zone ID available, skipping restaurant fetch');
        return;
      }
      // Fetch restaurants from API with optional filter
      List<VendorModel> moreVendors =
          await BestRestaurantProvider.getNearestRestaurants(
            zoneId: zoneId,
            latitude: latitude,
            longitude: longitude,
            radius: double.parse(Constant.radius),
            onFiltersReceived:
                (List<String> availableFilters, String? currentFilter) {},
          );

      // Reduced from 30 to 10
      for (var vendor in moreVendors) {
        if (vendor.title != null && vendor.title!.isNotEmpty) {
          trieSearch.insert(vendor.title!, vendor, relevanceScore: 1.5);
        }
      }

      // Load more products with strict limits
      List<ProductModel> moreProducts = await FireStoreUtils.getAllProducts(
        limit: 15,
      ); // Reduced from 50 to 15
      for (var product in moreProducts) {
        if (product.name != null && product.name!.isNotEmpty) {
          trieSearch.insert(product.name!, product, relevanceScore: 2.0);
        }
      }
      notifyListeners();
    } catch (e) {
      print("❌ Progressive data loading failed: $e");
      if (e.toString().contains('OutOfMemoryError')) {
        print(
          "🚨 OutOfMemoryError detected! Stopping progressive loading to prevent crash.",
        );
      }
    }
  }

  /// **LOAD VENDORS + PRODUCTS INTO TRIE (MEMORY EFFICIENT)**
  Future<void> _loadAndIndexData() async {
    try {
      print("🔄 Loading and indexing data (memory efficient)...");

      // Clear existing data
      trieSearch.clear();
      notifyListeners();
      // Load vendors in smaller batches to prevent memory issues
      await _loadVendorsInBatches();

      // Load products in smaller batches to prevent memory issues
      await _loadProductsInBatches();
      notifyListeners();
      print("✅ Data loading completed successfully");
    } catch (e) {
      print("❌ Error loading data: $e");
      // Don't rethrow to prevent app crash
    }
  }

  /// **LOAD VENDORS IN BATCHES - MEMORY OPTIMIZED**
  Future<void> _loadVendorsInBatches() async {
    try {
      print("🔄 Loading vendors in batches (memory optimized)...");

      // **MEMORY SAFETY: Use strict limits to prevent OutOfMemoryError**
      // List<VendorModel> vendors = await FireStoreUtils.getAllVendors(
      //   limit: FAST_VENDOR_LIMIT,
      // );
      final String? zoneId = Constant.selectedZone?.id;
      final double latitude =
          Constant.selectedLocation.location?.latitude ?? 0.0;
      final double longitude =
          Constant.selectedLocation.location?.longitude ?? 0.0;

      if (zoneId == null || zoneId.isEmpty) {
        print('[DEBUG] No zone ID available, skipping restaurant fetch');
        return;
      }
      // Fetch restaurants from API with optional filter
      List<VendorModel> vendors =
          await BestRestaurantProvider.getNearestRestaurants(
            zoneId: zoneId,
            latitude: latitude,
            longitude: longitude,
            radius: double.parse(Constant.radius),
            onFiltersReceived:
                (List<String> availableFilters, String? currentFilter) {},
          );

      print(
        "📊 Loaded ${vendors.length} vendors (memory safe limit: $FAST_VENDOR_LIMIT)",
      );

      // Debug: Print first few vendor names
      if (vendors.isNotEmpty) {
        print("  First few vendor names:");
        for (int i = 0; i < (vendors.length > 3 ? 3 : vendors.length); i++) {
          print("    - ${vendors[i].title} (ID: ${vendors[i].id})");
        }
      } else {
        print("  ⚠️ No vendors loaded!");
      }

      // **MEMORY EFFICIENT: Index only essential fields to reduce memory usage**
      for (var vendor in vendors) {
        if (vendor.title != null && vendor.title!.isNotEmpty) {
          // Lower relevance for restaurants (1.5) - products get priority
          trieSearch.insert(vendor.title!, vendor, relevanceScore: 1.5);

          // **OPTIMIZED: Only index location if it's not too long (memory safety)**
          if (vendor.location != null &&
              vendor.location!.isNotEmpty &&
              vendor.location!.length < 50) {
            trieSearch.insert(vendor.location!, vendor, relevanceScore: 1.5);
          }

          // **OPTIMIZED: Only index description if it's short (memory safety)**
          if (vendor.description != null &&
              vendor.description!.isNotEmpty &&
              vendor.description!.length < 100) {
            trieSearch.insert(vendor.description!, vendor, relevanceScore: 1.3);
          }

          // **OPTIMIZED: Limit category indexing to prevent memory bloat**
          if (vendor.categoryTitle != null &&
              vendor.categoryTitle!.isNotEmpty) {
            for (var category in vendor.categoryTitle!.take(3)) {
              // Limit to 3 categories
              if (category.toString().length < 30) {
                // Only short category names
                trieSearch.insert(
                  category.toString(),
                  vendor,
                  relevanceScore: 1.4,
                );
              }
            }
          }
        }
      }
      notifyListeners();
      print("✅ Indexed ${vendors.length} vendors (memory optimized)");
      print("🔍 Total Trie items after vendors: ${trieSearch.itemCount}");
    } catch (e) {
      print("❌ Error loading vendors: $e");
      if (e.toString().contains('OutOfMemoryError')) {
        print(
          "🚨 OutOfMemoryError detected! Skipping vendor indexing to prevent crash.",
        );
      }
    }
  }

  /// **LOAD PRODUCTS IN BATCHES - MEMORY OPTIMIZED**
  Future<void> _loadProductsInBatches() async {
    try {
      print("🔄 Loading products in batches (memory optimized)...");

      // **MEMORY SAFETY: Use strict limits to prevent OutOfMemoryError**
      List<ProductModel> products = await FireStoreUtils.getAllProducts(
        limit: FAST_PRODUCT_LIMIT,
      );
      notifyListeners();
      print(
        "📊 Loaded ${products.length} products (memory safe limit: $FAST_PRODUCT_LIMIT)",
      );

      for (var product in products) {
        if (product.name != null && product.name!.isNotEmpty) {
          // Higher relevance for products (2.0) - products get priority
          trieSearch.insert(product.name!, product, relevanceScore: 2.0);

          // **OPTIMIZED: Only index description if it's short (memory safety)**
          if (product.description != null &&
              product.description!.isNotEmpty &&
              product.description!.length < 100) {
            trieSearch.insert(
              product.description!,
              product,
              relevanceScore: 1.8,
            );
          }

          // **OPTIMIZED: Only index category if it's not too long**
          if (product.categoryID != null &&
              product.categoryID!.isNotEmpty &&
              product.categoryID!.length < 30) {
            trieSearch.insert(
              product.categoryID!,
              product,
              relevanceScore: 1.7,
            );
          }

          // **OPTIMIZED: Limit add-ons indexing to prevent memory bloat**
          if (product.addOnsTitle != null && product.addOnsTitle!.isNotEmpty) {
            for (var addon in product.addOnsTitle!.take(2)) {
              // Limit to 2 add-ons
              if (addon.toString().length < 20) {
                // Only short add-on names
                trieSearch.insert(
                  addon.toString(),
                  product,
                  relevanceScore: 1.6,
                );
              }
            }
          }

          // **OPTIMIZED: Only index specifications if they're short**
          if (product.productSpecification != null &&
              product.productSpecification!.isNotEmpty &&
              product.productSpecification.toString().length < 50) {
            trieSearch.insert(
              product.productSpecification.toString(),
              product,
              relevanceScore: 1.5,
            );
          }

          // **OPTIMIZED: Index veg/non-veg (these are short and useful)**
          if (product.veg != null && product.veg!) {
            trieSearch.insert("vegetarian", product, relevanceScore: 1.4);
            trieSearch.insert("veg", product, relevanceScore: 1.4);
          }
          if (product.nonveg != null && product.nonveg!) {
            trieSearch.insert("non-vegetarian", product, relevanceScore: 1.4);
            trieSearch.insert("nonveg", product, relevanceScore: 1.4);
          }
        }
        notifyListeners();
      }

      print("✅ Indexed ${products.length} products (memory optimized)");
      print("🔍 Total Trie items after products: ${trieSearch.itemCount}");
    } catch (e) {
      print("❌ Error loading products: $e");
      if (e.toString().contains('OutOfMemoryError')) {
        print(
          "🚨 OutOfMemoryError detected! Skipping product indexing to prevent crash.",
        );
      }
    }
  }

  /// **LOAD TRENDING SEARCHES**
  Future<void> _loadTrendingSearches() async {
    try {
      // Try to get trending searches from backend
      List<String> trending = await FireStoreUtils.getTrendingSearches();
      trendingSearches.assignAll(trending);
      notifyListeners();
    } catch (e) {
      print("❌ Error loading trending searches: $e");
      // Fallback to static trending searches
      trendingSearches.assignAll([
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
      ]);
      notifyListeners();
    }
  }

  /// **LOAD RECENT SEARCHES FROM STORAGE**
  Future<void> _loadRecentSearches() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? saved = prefs.getStringList('recent_searches');
      if (saved != null) {
        recentSearches.assignAll(saved);
      }
    } catch (e) {
      print("❌ Error loading recent searches: $e");
    }
  }

  /// **SAVE RECENT SEARCHES TO STORAGE**
  Future<void> _saveRecentSearches() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_searches', recentSearches);
    } catch (e) {
      print("❌ Error saving recent searches: $e");
    }
  }

  /// **MAIN SEARCH FUNCTION - ENHANCED MULTI-COLLECTION SEARCH**
  void search(String query) {
    if (query.isEmpty) {
      _clearSearchResults();
      return;
    }

    try {
      print(
        "🔍 Searching for: '$query' (using enhanced multi-collection search)",
      );
      // **ENHANCED: Use multi-collection search with grouped results**
      performEnhancedMultiCollectionSearch(query);
    } catch (e) {
      print("❌ Search error: $e");
      isSearching = false;
    }
  }

  /// **CLEAR SEARCH RESULTS**
  void _clearSearchResults() {
    restaurantResults.clear();
    productResults.clear();
    categoryResults.clear();
    hasSearched = false;
    isSearching = false;
    showSuggestions = false;
    currentResultCount = 0;
    hasMoreResults = true;
    _remainingProducts.clear();
    _remainingRestaurants.clear();
    _remainingCategories.clear();
  }

  /// **CLEAR SEARCH (PUBLIC METHOD)**
  void clearSearch() {
    searchText = '';
    _clearSearchResults();
  }

  /// **DEBUG METHOD - Show all loaded restaurants**

  /// **LOAD MORE RESULTS (PAGINATION) - ENHANCED MULTI-COLLECTION**
  void loadMoreResults() {
    if (isLoadingMore) {
      print("⚠️ Load more already in progress, skipping...");
      return;
    }

    try {
      print(
        "🔄 Loading more results (using enhanced multi-collection search)...",
      );

      // **ENHANCED: Use multi-collection search with increased limits**
      loadMoreResultsEnhanced();
    } catch (e) {
      print("❌ Error loading more results: $e");
    }
  }

  /// **UPDATE SEARCH TEXT AND SHOW SUGGESTIONS**
  void updateSearchText(String text) {
    searchText = text;

    // Cancel previous timers
    _debounceTimer?.cancel();
    _searchTimer?.cancel();

    if (text.isEmpty) {
      showSuggestions = false;
      return;
    }

    // Debounce the suggestions (fast)
    _debounceTimer = Timer(DEBOUNCE_DELAY, () {
      _updateSuggestions(text);
    });

    // Auto-search after user stops typing (slower)
    _searchTimer = Timer(const Duration(milliseconds: 1500), () {
      if (text.trim().isNotEmpty) {
        print("🔍 Auto-triggering search for: '$text'");
        performSearch(text.trim());
      }
    });
  }

  /// **ON SEARCH TEXT CHANGED (for TextField onChanged)**
  void onSearchTextChanged(String text) {
    updateSearchText(text);
  }

  /// **UPDATE SUGGESTIONS BASED ON SEARCH TEXT - OPTIMIZED**
  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      showSuggestions = false;
      return;
    }
    try {
      print("💡 Getting suggestions for: '$query'");

      // **OPTIMIZED: Use Firestore prefix search for suggestions**
      _updateSuggestionsOptimized(query);
    } catch (e) {
      print("❌ Suggestions failed: $e");
      showSuggestions = false;
    }
  }

  /// **SAVE RECENT SEARCH**
  void _saveRecentSearch(String query) {
    if (query.isEmpty) return;

    // Remove if already exists
    recentSearches.remove(query);

    // Add to beginning
    recentSearches.insert(0, query);

    // Keep only max recent searches
    if (recentSearches.length > MAX_RECENT_SEARCHES) {
      recentSearches.removeRange(MAX_RECENT_SEARCHES, recentSearches.length);
    }

    // Save to storage
    _saveRecentSearches();
  }

  /// **SELECT A SUGGESTION**
  void selectSuggestion(String suggestion) {
    searchText = suggestion;
    showSuggestions = false;
    performSearch(suggestion);
  }

  /// **HIDE SUGGESTIONS**
  void hideSuggestions() {
    showSuggestions = false;
  }

  static Future<List<VendorCategoryModel>> getVendorCategory() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}categories'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          return data
              .map((categoryJson) => VendorCategoryModel.fromJson(categoryJson))
              .toList();
        } else {
          throw Exception('API returned success: false');
        }
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  /// **PERFORM SEARCH - ENHANCED VERSION (as suggested) - MEMORY OPTIMIZED**
  Future<void> performSearch(String query) async {
    searchText = query;
    hasSearched = true;
    isLoadingData = true;

    if (query.trim().isEmpty) {
      restaurantResults.clear();
      productResults.clear();
      categoryResults.clear();
      isLoadingData = false;
      return;
    }

    // **MEMORY SAFETY CHECK: Check if we need emergency cleanup**
    if (!_isMemoryUsageSafe()) {
      print("⚠️ Memory usage unsafe, performing emergency cleanup");
      _emergencyMemoryCleanup();
    }

    final lowerQuery = query.toLowerCase();

    try {
      print("🔍 Enhanced search for: '$query'");

      // 🔎 Get results from Firestore (or local lists)
      List<VendorModel> allRestaurants = [];
      List<ProductModel> allProducts = [];
      List<VendorCategoryModel> allCategories = [];

      // **MEMORY SAFE: Use strict limits to prevent OutOfMemoryError**
      try {
        final String? zoneId = Constant.selectedZone?.id;
        final double latitude =
            Constant.selectedLocation.location?.latitude ?? 0.0;
        final double longitude =
            Constant.selectedLocation.location?.longitude ?? 0.0;

        if (zoneId == null || zoneId.isEmpty) {
          print('[DEBUG] No zone ID available, skipping restaurant fetch');
          return;
        }
        // Fetch restaurants from API with optional filter
        List<VendorModel> allRestaurants =
            await BestRestaurantProvider.getNearestRestaurants(
              zoneId: zoneId,
              latitude: latitude,
              longitude: longitude,
              radius: double.parse(Constant.radius),
              onFiltersReceived:
                  (List<String> availableFilters, String? currentFilter) {},
            );
        allProducts = await FireStoreUtils.getAllProductsInZone(
          limit: MAX_PRODUCTS_PER_SEARCH,
        ); // Limit to 40 products
        allCategories = await getVendorCategory();
        print(
          "🔍 Loaded ${allRestaurants.length} restaurants, ${allProducts.length} products, ${allCategories.length} categories (memory safe)",
        );
      } catch (e) {
        print("❌ Error loading fresh data: $e");
        if (e.toString().contains('OutOfMemoryError')) {
          print(
            "🚨 OutOfMemoryError detected! Using minimal data to prevent crash.",
          );
          // **FALLBACK: Use even smaller limits to prevent further crashes**
          allRestaurants = restaurantResults.take(5).toList();
          allProducts = productResults.take(10).toList();
          allCategories = categoryResults.take(3).toList();
        } else {
          // Use existing data as fallback
          allRestaurants = restaurantResults.toList();
          allProducts = productResults.toList();
          allCategories = categoryResults.toList();
        }
      }

      // ✅ COMPREHENSIVE SEARCH - search in ALL relevant fields based on actual model structure
      var filteredRestaurants = allRestaurants
          .where(
            (r) =>
                (r.title != null &&
                    r.title!.toLowerCase().contains(lowerQuery)) ||
                (r.description != null &&
                    r.description!.toLowerCase().contains(lowerQuery)) ||
                (r.location != null &&
                    r.location!.toLowerCase().contains(lowerQuery)) ||
                (r.categoryTitle != null &&
                    r.categoryTitle!.any(
                      (cat) => cat.toLowerCase().contains(lowerQuery),
                    )) ||
                (r.id != null && r.id!.toLowerCase().contains(lowerQuery)) ||
                (r.phonenumber != null &&
                    r.phonenumber!.toLowerCase().contains(lowerQuery)) ||
                (r.vType != null &&
                    r.vType!.toLowerCase().contains(lowerQuery)),
          )
          .toList();

      var filteredProducts = allProducts
          .where(
            (p) =>
                (p.name != null &&
                    p.name!.toLowerCase().contains(lowerQuery)) ||
                (p.description != null &&
                    p.description!.toLowerCase().contains(lowerQuery)) ||
                (p.categoryID != null &&
                    p.categoryID!.toLowerCase().contains(lowerQuery)) ||
                (p.vendorID != null &&
                    p.vendorID!.toLowerCase().contains(lowerQuery)) ||
                (p.id != null && p.id!.toLowerCase().contains(lowerQuery)) ||
                (p.price != null &&
                    p.price!.toLowerCase().contains(lowerQuery)) ||
                (p.disPrice != null &&
                    p.disPrice!.toLowerCase().contains(lowerQuery)),
          )
          .toList();

      var filteredCategories = allCategories
          .where(
            (c) =>
                (c.title != null &&
                    c.title!.toLowerCase().contains(lowerQuery)) ||
                (c.description != null &&
                    c.description!.toLowerCase().contains(lowerQuery)) ||
                (c.id != null && c.id!.toLowerCase().contains(lowerQuery)),
          )
          .toList();

      // Debug: Show comprehensive filtering results
      print("🔍 COMPREHENSIVE SEARCH RESULTS for '$query':");
      print(
        "  📍 RESTAURANT MATCHES: ${filteredRestaurants.length} out of ${allRestaurants.length}",
      );
      print(
        "    - Searched in: title, description, location, categoryTitle, id, phonenumber, vType",
      );
      print(
        "  🍕 PRODUCT MATCHES: ${filteredProducts.length} out of ${allProducts.length}",
      );
      print(
        "    - Searched in: name, description, categoryID, vendorID, id, price, disPrice",
      );
      print(
        "  📂 CATEGORY MATCHES: ${filteredCategories.length} out of ${allCategories.length}",
      );
      print("    - Searched in: title, description, id");

      // Enhanced debugging for restaurant search issues
      if (filteredRestaurants.isEmpty && allRestaurants.isNotEmpty) {
        print(
          "🔍 DEBUG: No restaurant matches found. Checking sample restaurant data:",
        );
        for (
          int i = 0;
          i < (allRestaurants.length > 3 ? 3 : allRestaurants.length);
          i++
        ) {
          var r = allRestaurants[i];
          print("  Restaurant ${i + 1}:");
          print("    - Title: '${r.title}'");
          print("    - Description: '${r.description}'");
          print("    - Location: '${r.location}'");
          print("    - CategoryTitle: ${r.categoryTitle}");
          print("    - ID: '${r.id}'");
          print("    - Phone: '${r.phonenumber}'");
          print("    - vType: '${r.vType}'");
          print("    - Query: '$lowerQuery'");
          print(
            "    - Title contains query: ${r.title?.toLowerCase().contains(lowerQuery) ?? false}",
          );
          print(
            "    - Description contains query: ${r.description?.toLowerCase().contains(lowerQuery) ?? false}",
          );
        }
      }

      // Show sample matches for debugging
      if (filteredRestaurants.isNotEmpty) {
        print("  📍 Sample restaurant matches:");
        for (
          int i = 0;
          i < (filteredRestaurants.length > 3 ? 3 : filteredRestaurants.length);
          i++
        ) {
          var r = filteredRestaurants[i];
          print("    - ${r.title} (${r.location})");
        }
      }

      if (filteredProducts.isNotEmpty) {
        print("  🍕 Sample product matches:");
        for (
          int i = 0;
          i < (filteredProducts.length > 3 ? 3 : filteredProducts.length);
          i++
        ) {
          var p = filteredProducts[i];
          print("    - ${p.name} (₹${p.price})");
        }
      }

      if (filteredCategories.isNotEmpty) {
        print("  📂 Sample category matches:");
        for (
          int i = 0;
          i < (filteredCategories.length > 3 ? 3 : filteredCategories.length);
          i++
        ) {
          var c = filteredCategories[i];
          print("    - ${c.title}");
        }
      }

      // If no results found, try partial/fuzzy matching
      if (filteredRestaurants.isEmpty &&
          filteredProducts.isEmpty &&
          filteredCategories.isEmpty) {
        print("🔍 No exact matches found, trying partial/fuzzy matching...");

        // Try partial word matching
        var words = lowerQuery.split(' ');
        for (String word in words) {
          if (word.length > 2) {
            // Only search words longer than 2 characters
            // Partial restaurant matches
            var partialRestaurants = allRestaurants
                .where(
                  (r) =>
                      (r.title != null &&
                          r.title!.toLowerCase().contains(word)) ||
                      (r.description != null &&
                          r.description!.toLowerCase().contains(word)) ||
                      (r.location != null &&
                          r.location!.toLowerCase().contains(word)) ||
                      (r.categoryTitle != null &&
                          r.categoryTitle!.any(
                            (cat) => cat.toLowerCase().contains(word),
                          )) ||
                      (r.phonenumber != null &&
                          r.phonenumber!.toLowerCase().contains(word)) ||
                      (r.vType != null &&
                          r.vType!.toLowerCase().contains(word)),
                )
                .toList();
            filteredRestaurants.addAll(partialRestaurants);

            // Partial product matches
            var partialProducts = allProducts
                .where(
                  (p) =>
                      (p.name != null &&
                          p.name!.toLowerCase().contains(word)) ||
                      (p.description != null &&
                          p.description!.toLowerCase().contains(word)) ||
                      (p.price != null &&
                          p.price!.toLowerCase().contains(word)) ||
                      (p.disPrice != null &&
                          p.disPrice!.toLowerCase().contains(word)),
                )
                .toList();
            filteredProducts.addAll(partialProducts);

            // Partial category matches
            var partialCategories = allCategories
                .where(
                  (c) =>
                      (c.title != null &&
                          c.title!.toLowerCase().contains(word)) ||
                      (c.description != null &&
                          c.description!.toLowerCase().contains(word)),
                )
                .toList();
            filteredCategories.addAll(partialCategories);
          }
        }

        // Remove duplicates
        filteredRestaurants = filteredRestaurants.toSet().toList();
        filteredProducts = filteredProducts.toSet().toList();
        filteredCategories = filteredCategories.toSet().toList();

        print("🔍 After partial matching:");
        print("  - Partial restaurant matches: ${filteredRestaurants.length}");
        print("  - Partial product matches: ${filteredProducts.length}");
        print("  - Partial category matches: ${filteredCategories.length}");

        // If still no results, log the issue
        if (filteredRestaurants.isEmpty &&
            filteredProducts.isEmpty &&
            filteredCategories.isEmpty) {
          print(
            "🔍 No matches found in database - this is expected if no data is loaded",
          );
        }
      }

      // Sort results by relevance (products first, then restaurants, then categories)
      filteredProducts.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
      filteredRestaurants.sort(
        (a, b) => (a.title ?? '').compareTo(b.title ?? ''),
      );
      filteredCategories.sort(
        (a, b) => (a.title ?? '').compareTo(b.title ?? ''),
      );

      // Show ALL matching results - no artificial limits
      // For initial display, show a reasonable number but keep ALL results available
      int initialDisplayLimit = 50; // Show first 50 of each type initially

      // Take initial results for display (but keep ALL results available)
      var initialProducts = filteredProducts.take(initialDisplayLimit).toList();
      var initialRestaurants = filteredRestaurants
          .take(initialDisplayLimit)
          .toList();
      var initialCategories = filteredCategories
          .take(initialDisplayLimit)
          .toList();

      // Store ALL remaining results for pagination (no artificial limits)
      _remainingProducts = filteredProducts.skip(initialDisplayLimit).toList();
      _remainingRestaurants = filteredRestaurants
          .skip(initialDisplayLimit)
          .toList();
      _remainingCategories = filteredCategories
          .skip(initialDisplayLimit)
          .toList();

      // Update observable lists
      productResults.assignAll(initialProducts);
      restaurantResults.assignAll(initialRestaurants);
      categoryResults.assignAll(initialCategories);

      // Update counts
      currentResultCount =
          initialProducts.length +
          initialRestaurants.length +
          initialCategories.length;
      totalAvailableResults =
          filteredProducts.length +
          filteredRestaurants.length +
          filteredCategories.length;

      // Check if there are more results
      hasMoreResults =
          _remainingProducts.isNotEmpty ||
          _remainingRestaurants.isNotEmpty ||
          _remainingCategories.isNotEmpty;

      // Fallback: If we have any results but no remaining, still show Load More for better UX
      if (!hasMoreResults &&
          (initialProducts.isNotEmpty ||
              initialRestaurants.isNotEmpty ||
              filteredCategories.isNotEmpty)) {
        hasMoreResults = true;
      }
      try {
        searchSuggestions = trieSearch.getSuggestions(
          lowerQuery,
          maxSuggestions: MAX_SUGGESTIONS,
        );
      } catch (e) {
        searchSuggestions.clear();
      }

      // Save to recent searches
      _saveRecentSearch(query);

      // **MEMORY MONITORING: Log memory usage after search**
      logMemoryUsage("After Search Completion");
    } catch (e) {
      if (e.toString().contains('OutOfMemoryError')) {
        _emergencyMemoryCleanup();
      }
    } finally {
      isLoadingData = false;
      notifyListeners();
    }
    notifyListeners();
  }

  /// **CLEAR ALL DATA**
  void clearAllData() {
    restaurantResults.clear();
    productResults.clear();
    categoryResults.clear();
    searchSuggestions.clear();
    recentSearches.clear();
    trendingSearches.clear();
    hasSearched = false;
    isSearching = false;
    showSuggestions = false;
    searchText = '';
    currentResultCount = 0;
    hasMoreResults = true;
    dataLoaded = false;
    _remainingProducts.clear();
    _remainingRestaurants.clear();
    _remainingCategories.clear();
    trieSearch.clear();
  }

  /// **MEMORY MONITORING - DEBUG METHOD**
  void logMemoryUsage(String context) {
    try {
      print("📊 MEMORY USAGE - $context:");
      print("  - Trie items: ${trieSearch.itemCount}");
      print("  - Restaurant results: ${restaurantResults.length}");
      print("  - Product results: ${productResults.length}");
      print("  - Category results: ${categoryResults.length}");
      print("  - Remaining products: ${_remainingProducts.length}");
      print("  - Remaining restaurants: ${_remainingRestaurants.length}");
      print("  - Remaining categories: ${_remainingCategories.length}");
      print("  - Search suggestions: ${searchSuggestions.length}");
      print("  - Recent searches: ${recentSearches.length}");
    } catch (e) {
      print("❌ Error logging memory usage: $e");
    }
  }

  /// **MEMORY SAFETY CHECK**
  bool _isMemoryUsageSafe() {
    try {
      // Check if we're approaching memory limits
      int totalItems =
          trieSearch.itemCount +
          restaurantResults.length +
          productResults.length +
          categoryResults.length +
          _remainingProducts.length +
          _remainingRestaurants.length +
          _remainingCategories.length;

      // If we have more than 200 total items, consider it unsafe
      bool isSafe = totalItems < 200;

      if (!isSafe) {
        print("⚠️ Memory usage warning: $totalItems total items (limit: 200)");
      }

      return isSafe;
    } catch (e) {
      print("❌ Error checking memory usage: $e");
      return false; // Assume unsafe if we can't check
    }
  }

  /// **EMERGENCY MEMORY CLEANUP**
  void _emergencyMemoryCleanup() {
    try {
      print("🚨 EMERGENCY MEMORY CLEANUP - Freeing memory to prevent crash");

      // Clear remaining results first (they take most memory)
      _remainingProducts.clear();
      _remainingRestaurants.clear();
      _remainingCategories.clear();

      // Clear some search results
      if (restaurantResults.length > 10) {
        restaurantResults = restaurantResults.take(10).toList();
      }
      if (productResults.length > 20) {
        productResults = productResults.take(20).toList();
      }
      if (categoryResults.length > 5) {
        categoryResults = categoryResults.take(5).toList();
      }

      // Clear suggestions
      searchSuggestions.clear();

      // Clear some Trie data if it's too large
      if (trieSearch.itemCount > 100) {
        print(
          "⚠️ Trie has ${trieSearch.itemCount} items, clearing to prevent memory issues",
        );
        trieSearch.clear();
        dataLoaded = false;
      }

      print("✅ Emergency cleanup completed");
      logMemoryUsage("After Emergency Cleanup");
    } catch (e) {
      print("❌ Error during emergency cleanup: $e");
    }
  }

  // **OPTIMIZED FIRESTORE QUERY METHODS**

  /// **PREFIX SEARCH WITH FIRESTORE (MOST EFFICIENT FOR AUTOCOMPLETE)**
  Future<List<dynamic>> _searchWithPrefix({
    required String query,
    int limit = 20,
  }) async {
    try {
      print('🔍 API prefix search for: "$query" (limit: $limit)');

      if (query.trim().isEmpty) {
        return [];
      }

      final String? zoneId = Constant.selectedZone?.id;
      final double latitude =
          Constant.selectedLocation.location?.latitude ?? 0.0;
      final double longitude =
          Constant.selectedLocation.location?.longitude ?? 0.0;

      if (zoneId == null || zoneId.isEmpty) {
        print('[DEBUG] No zone ID available, skipping restaurant search');
        return [];
      }

      List<dynamic> results = [];

      // Use your existing API function to search restaurants
      final restaurants = await BestRestaurantProvider.getNearestRestaurants(
        zoneId: zoneId,
        latitude: latitude,
        longitude: longitude,
        radius: double.parse(Constant.radius),
        filter: query,
        onFiltersReceived:
            (
              List<String> availableFilters,
              String? currentFilter,
            ) {}, // Use the search query as filter
      );

      // Filter restaurants locally to match the prefix search behavior
      final filteredRestaurants = restaurants
          .where((restaurant) {
            final title = restaurant.title?.toLowerCase() ?? '';
            final searchQuery = query.toLowerCase();
            return title.startsWith(searchQuery);
          })
          .take(limit ~/ 2)
          .toList();

      results.addAll(filteredRestaurants);

      print('✅ Prefix search found ${results.length} results via API');
      return results;
    } catch (e) {
      print('❌ Error in prefix search: $e');
      return [];
    }
  }

  /// **UPDATE SUGGESTIONS USING PREFIX SEARCH**
  Future<void> _updateSuggestionsOptimized(String query) async {
    if (query.isEmpty) {
      showSuggestions = false;
      return;
    }

    try {
      print("💡 Getting suggestions via Firestore prefix search for: '$query'");
      final suggestions = await _searchWithPrefix(
        query: query,
        limit: SUGGESTION_LIMIT,
      );

      // Extract suggestion strings
      final suggestionStrings = <String>[];
      for (var item in suggestions) {
        if (item is VendorModel && item.title != null) {
          suggestionStrings.add(item.title!);
        } else if (item is ProductModel && item.name != null) {
          suggestionStrings.add(item.name!);
        }
      }

      // Remove duplicates and limit
      final uniqueSuggestions = suggestionStrings
          .toSet()
          .take(MAX_SUGGESTIONS)
          .toList();
      searchSuggestions.assignAll(uniqueSuggestions);
      showSuggestions = uniqueSuggestions.isNotEmpty;

      print("💡 Showing ${uniqueSuggestions.length} suggestions via Firestore");
    } catch (e) {
      print("❌ Suggestions failed: $e");
      showSuggestions = false;
    }
  }

  /// **ENHANCED MULTI-COLLECTION SEARCH - GROUPED RESULTS**
  Future<void> performEnhancedMultiCollectionSearch(String query) async {
    if (query.isEmpty) {
      _clearSearchResults();
      return;
    }

    try {
      print("🔍 Enhanced multi-collection search for: '$query'");
      isSearching = true;
      hasSearched = true;

      final lowerQuery = query.toLowerCase().trim();

      // **PHASE 1: Primary search in main fields (title/name)**
      print("🔍 Phase 1: Primary search in main fields");
      final primaryResults = await _performPrimarySearch(lowerQuery);
      // **PHASE 2: Fallback search in descriptions if needed**
      if (primaryResults['totalResults'] < 10) {
        print("🔍 Phase 2: Fallback search in descriptions");
        final fallbackResults = await _performFallbackSearch(lowerQuery);
        _mergeSearchResults(primaryResults, fallbackResults);
      } else {
        _updateSearchResults(primaryResults);
      }
      // Save to recent searches
      _saveRecentSearch(query);
      print(
        "📊 Enhanced search completed: ${restaurantResults.length} restaurants, ${productResults.length} products, ${categoryResults.length} categories",
      );
    } catch (e) {
      print("❌ Enhanced search failed: $e");
      // Fallback to current method
      await performSearch(query);
    } finally {
      isSearching = false;
    }
  }

  /// **PRIMARY SEARCH - Main fields (title/name)**
  Future<Map<String, dynamic>> _performPrimarySearch(String lowerQuery) async {
    try {
      // **SINGLE OPTIMIZED QUERY: Use Firestore's array-contains-any for efficiency**
      final futures = await Future.wait([
        _searchVendorsOptimized(lowerQuery, RESTAURANT_SEARCH_LIMIT),
        _searchProductsOptimized(lowerQuery, PRODUCT_SEARCH_LIMIT),
        _searchCategoriesOptimized(lowerQuery, CATEGORY_SEARCH_LIMIT),
      ]);

      final vendorResults = futures[0] as List<VendorModel>;
      final productResults = futures[1] as List<ProductModel>;
      final categoryResults = futures[2] as List<VendorCategoryModel>;

      return {
        'vendors': vendorResults,
        'products': productResults,
        'categories': categoryResults,
        'totalResults':
            vendorResults.length +
            productResults.length +
            categoryResults.length,
      };
    } catch (e) {
      print("❌ Primary search failed: $e");
      return {
        'vendors': <VendorModel>[],
        'products': <ProductModel>[],
        'categories': <VendorCategoryModel>[],
        'totalResults': 0,
      };
    }
  }

  /// **FALLBACK SEARCH - Description fields**
  Future<Map<String, dynamic>> _performFallbackSearch(String lowerQuery) async {
    try {
      print("🔍 Fallback search in descriptions for: '$lowerQuery'");

      final futures = await Future.wait([
        _searchVendorsByDescription(lowerQuery, RESTAURANT_SEARCH_LIMIT),
        _searchProductsByDescription(lowerQuery, PRODUCT_SEARCH_LIMIT),
        _searchCategoriesByDescription(lowerQuery, CATEGORY_SEARCH_LIMIT),
      ]);

      final vendorResults = futures[0] as List<VendorModel>;
      final productResults = futures[1] as List<ProductModel>;
      final categoryResults = futures[2] as List<VendorCategoryModel>;

      return {
        'vendors': vendorResults,
        'products': productResults,
        'categories': categoryResults,
        'totalResults':
            vendorResults.length +
            productResults.length +
            categoryResults.length,
      };
    } catch (e) {
      print("❌ Fallback search failed: $e");
      return {
        'vendors': <VendorModel>[],
        'products': <ProductModel>[],
        'categories': <VendorCategoryModel>[],
        'totalResults': 0,
      };
    }
  }

  /// **OPTIMIZED VENDOR SEARCH - Main fields**
  Future<List<VendorModel>> _searchVendorsOptimized(
    String query,
    int limit,
  ) async {
    try {
      print("🔍 Optimized vendor search for: '$query' (limit: $limit)");

      // Get the zone ID
      final zoneId = Constant.selectedZone?.id.toString();
      if (zoneId == null) {
        print("❌ No zone selected");
        return [];
      }

      // **API CALL: Load vendors with zone filtering**
      final Uri uri = Uri.parse(
        '${AppConst.baseUrl}restaurants/by-zone/$zoneId',
      );

      print("🌐 Making API request to: ${uri.toString()}");

      final response = await http.get(uri, headers: await getHeaders());

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          List<VendorModel> allVendors = [];

          // Parse all vendors from API response
          for (var vendorData in data) {
            try {
              final vendor = VendorModel.fromJson(vendorData);
              allVendors.add(vendor);
            } catch (e) {
              print('❌ Error parsing vendor: $e');
            }
          }

          // **SMART MATCHING: Filter vendors based on search query**
          List<VendorModel> results = [];
          for (var vendor in allVendors) {
            if (_vendorMatchesPrimaryQuery(vendor, query)) {
              results.add(vendor);
            }

            // Apply limit
            if (results.length >= limit) {
              break;
            }
          }
          notifyListeners();
          print("✅ Found ${results.length} vendors via optimized search");
          return results;
        } else {
          print("❌ API returned error: ${responseData['message']}");
          return [];
        }
      } else {
        print("❌ HTTP error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Optimized vendor search failed: $e");
      return [];
    }
  }

  Future<List<ProductModel>> _searchProductsOptimized(
    String query,
    int limit,
  ) async {
    try {
      print("🔍 Optimized product search for: '$query' (limit: $limit)");
      // ✅ STEP 1: Identify allowed vendor IDs based on selected zone
      List<String> allowedVendorIds = [];
      if (Constant.selectedZone != null) {
        print("🌍 Filtering products for zone: ${Constant.selectedZone!.name}");

        final String zoneId = Constant.selectedZone!.id.toString();
        final String vendorsUrl =
            '${AppConst.baseUrl}restaurants/by-zone/$zoneId';

        final vendorsResponse = await http
            .get(Uri.parse(vendorsUrl), headers: await getHeaders())
            .timeout(const Duration(seconds: 30));

        if (vendorsResponse.statusCode == 200) {
          final Map<String, dynamic> vendorsData = json.decode(
            vendorsResponse.body,
          );
          if (vendorsData['success'] == true) {
            final List<dynamic> vendorsJson = vendorsData['data'];
            allowedVendorIds = vendorsJson
                .map<String>((vendor) => vendor['id'].toString())
                .toList();
            print("✅ Found ${allowedVendorIds.length} vendors in this zone");
          } else {
            print(
              '❌ API returned error fetching vendors: ${vendorsData['message']}',
            );
          }
        } else {
          print('❌ HTTP Error fetching vendors: ${vendorsResponse.statusCode}');
        }
      }

      // ✅ STEP 2: Query published products from API
      final String baseUrl = '${AppConst.baseUrl}products';
      final Map<String, String> queryParams = {
        'page': '1',
        'per_page': limit.toString(),
      };

      final Uri uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      print('🌐 Fetching products for optimized search: $uri');

      final response = await http
          .get(uri, headers: await getHeaders())
          .timeout(const Duration(seconds: 30));

      List<ProductModel> results = [];

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> productsJson = responseData['data'];

          for (var productJson in productsJson) {
            try {
              final product = ProductModel.fromJson(productJson);

              // ✅ STEP 3: Apply zone-based filter
              if (Constant.selectedZone != null) {
                if (!allowedVendorIds.contains(product.vendorID)) {
                  continue; // Skip products outside the selected zone
                }
              }
              // ✅ STEP 4: Smart search filtering
              if (_productMatchesPrimaryQuery(product, query)) {
                results.add(product);
              }
              // Stop if we've reached the limit
              if (results.length >= limit) {
                break;
              }
            } catch (e) {
              print('❌ Error parsing product ${productJson['id']}: $e');
            }
          }
          notifyListeners();
          print(
            "✅ Found ${results.length} zone-filtered products via optimized search",
          );
          return results;
        } else {
          print(
            '❌ API returned error in optimized product search: ${responseData['message']}',
          );
          return [];
        }
      } else {
        print(
          '❌ HTTP Error in optimized product search: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print("❌ Optimized product search failed: $e");

      if (e is http.ClientException) {
        print('🌐 Network error in optimized product search: ${e.message}');
      } else if (e is TimeoutException) {
        print('⏰ Optimized product search request timeout');
      }

      return [];
    }
  }

  /// **OPTIMIZED CATEGORY SEARCH - Main fields**
  Future<List<VendorCategoryModel>> _searchCategoriesOptimized(
    String query,
    int limit,
  ) async {
    try {
      print("🔍 Optimized category search for: '$query' (limit: $limit)");

      // **SINGLE QUERY: Load categories (no prefix matching)**
      Query firestoreQuery = FirebaseFirestore.instance
          .collection(CollectionName.vendorCategories)
          .limit(limit);

      QuerySnapshot querySnapshot = await firestoreQuery.get();

      List<VendorCategoryModel> results = [];
      for (var document in querySnapshot.docs) {
        try {
          final data = document.data() as Map<String, dynamic>;
          final category = VendorCategoryModel.fromJson(data);

          // **SMART MATCHING: Check title first, then description**
          if (_categoryMatchesPrimaryQuery(category, query)) {
            results.add(category);
          }
        } catch (e) {
          print('❌ Error parsing category ${document.id}: $e');
        }
      }
      notifyListeners();
      print("✅ Found ${results.length} categories via optimized search");
      return results;
    } catch (e) {
      print("❌ Optimized category search failed: $e");
      return [];
    }
  }

  /// **FALLBACK VENDOR SEARCH - Description fields**
  Future<List<VendorModel>> _searchVendorsByDescription(
    String query,
    int limit,
  ) async {
    try {
      print("🔍 Fallback vendor search in descriptions for: '$query'");
      // Use the restaurants by zone endpoint
      final String zoneId = Constant.selectedZone?.id.toString() ?? '';
      if (zoneId.isEmpty) {
        print('❌ No zone selected for vendor search');
        return [];
      }

      final String baseUrl = '${AppConst.baseUrl}restaurants/by-zone/$zoneId';
      print('🌐 Fetching vendors for fallback search: $baseUrl');

      final response = await http
          .get(Uri.parse(baseUrl), headers: await getHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> vendorsJson = responseData['data'];

          List<VendorModel> results = [];
          for (var vendorJson in vendorsJson) {
            try {
              final vendor = VendorModel.fromJson(vendorJson);

              // **FALLBACK MATCHING: Check description fields**
              if (_vendorMatchesFallbackQuery(vendor, query)) {
                results.add(vendor);
              }
              // Stop if we've reached the limit
              if (results.length >= limit) {
                break;
              }
            } catch (e) {
              print('❌ Error parsing vendor ${vendorJson['id']}: $e');
            }
          }
          notifyListeners();
          print("✅ Found ${results.length} vendors via fallback search");
          return results;
        } else {
          print(
            '❌ API returned error in fallback vendor search: ${responseData['message']}',
          );
          return [];
        }
      } else {
        print('❌ HTTP Error in fallback vendor search: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print("❌ Fallback vendor search failed: $e");

      if (e is http.ClientException) {
        print('🌐 Network error in fallback vendor search: ${e.message}');
      } else if (e is TimeoutException) {
        print('⏰ Fallback vendor search request timeout');
      }

      return [];
    }
  }

  /// **FALLBACK PRODUCT SEARCH - Description fields**
  Future<List<ProductModel>> _searchProductsByDescription(
    String query,
    int limit,
  ) async {
    try {
      print("🔍 Fallback product search in descriptions for: '$query'");

      final String baseUrl = '${AppConst.baseUrl}products';
      final Map<String, String> queryParams = {
        'page': '1', // Start from first page for search
        'limit': limit.toString(),
      };
      final Uri uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      print('🌐 Fetching products for fallback search: $uri');

      final response = await http
          .get(uri, headers: await getHeaders())
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> productsJson = responseData['data'];

          List<ProductModel> results = [];
          for (var productJson in productsJson) {
            try {
              final product = ProductModel.fromJson(productJson);
              // **FALLBACK MATCHING: Check description fields**
              if (_productMatchesFallbackQuery(product, query)) {
                results.add(product);
              }

              // Stop if we've reached the limit
              if (results.length >= limit) {
                break;
              }
            } catch (e) {
              print('❌ Error parsing product ${productJson['id']}: $e');
            }
          }

          notifyListeners();
          print("✅ Found ${results.length} products via fallback search");
          return results;
        } else {
          print(
            '❌ API returned error in fallback search: ${responseData['message']}',
          );
          return [];
        }
      } else {
        print('❌ HTTP Error in fallback search: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print("❌ Fallback product search failed: $e");

      if (e is http.ClientException) {
        print('🌐 Network error in fallback search: ${e.message}');
      } else if (e is TimeoutException) {
        print('⏰ Fallback search request timeout');
      }

      return [];
    }
  }

  /// **FALLBACK CATEGORY SEARCH - Description fields**
  Future<List<VendorCategoryModel>> _searchCategoriesByDescription(
    String query,
    int limit,
  ) async {
    try {
      print("🔍 Fallback category search in descriptions for: '$query'");

      // Make API call to get categories
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}categories'),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        print("❌ API call failed with status: ${response.statusCode}");
        return [];
      }

      final jsonResponse = json.decode(response.body);

      if (!jsonResponse['success']) {
        print("❌ API returned unsuccessful response");
        return [];
      }

      final List<dynamic> data = jsonResponse['data'];
      List<VendorCategoryModel> results = [];
      for (var item in data) {
        try {
          final category = VendorCategoryModel.fromJson(item);
          // **FALLBACK MATCHING: Check description fields**
          if (_categoryMatchesFallbackQuery(category, query)) {
            results.add(category);
          }
          // Apply limit
          if (results.length >= limit) {
            break;
          }
        } catch (e) {
          print('❌ Error parsing category ${item['id']}: $e');
        }
      }

      notifyListeners();
      print("✅ Found ${results.length} categories via fallback search");
      return results;
    } catch (e) {
      print("❌ Fallback category search failed: $e");
      return [];
    }
  }

  /// **PRIMARY QUERY MATCHING - Contains matching (finds items anywhere in text)**
  bool _vendorMatchesPrimaryQuery(VendorModel vendor, String lowerQuery) {
    return (vendor.title?.toLowerCase().contains(lowerQuery) ?? false) ||
        (vendor.location?.toLowerCase().contains(lowerQuery) ?? false) ||
        (vendor.categoryTitle?.any(
              (cat) => cat.toLowerCase().contains(lowerQuery),
            ) ??
            false);
  }

  bool _productMatchesPrimaryQuery(ProductModel product, String lowerQuery) {
    return (product.name?.toLowerCase().contains(lowerQuery) ?? false) ||
        (product.categoryID?.toLowerCase().contains(lowerQuery) ?? false);
  }

  bool _categoryMatchesPrimaryQuery(
    VendorCategoryModel category,
    String lowerQuery,
  ) {
    return (category.title?.toLowerCase().contains(lowerQuery) ?? false);
  }

  /// **FALLBACK QUERY MATCHING - Contains matching in descriptions**
  bool _vendorMatchesFallbackQuery(VendorModel vendor, String lowerQuery) {
    return (vendor.description?.toLowerCase().contains(lowerQuery) ?? false) ||
        (vendor.vType?.toLowerCase().contains(lowerQuery) ?? false);
  }

  bool _productMatchesFallbackQuery(ProductModel product, String lowerQuery) {
    return (product.description?.toLowerCase().contains(lowerQuery) ?? false);
  }

  bool _categoryMatchesFallbackQuery(
    VendorCategoryModel category,
    String lowerQuery,
  ) {
    return (category.description?.toLowerCase().contains(lowerQuery) ?? false);
  }

  /// **MERGE SEARCH RESULTS**
  void _mergeSearchResults(
    Map<String, dynamic> primary,
    Map<String, dynamic> fallback,
  ) {
    // Combine primary and fallback results, avoiding duplicates
    final combinedVendors = <VendorModel>[];
    final combinedProducts = <ProductModel>[];
    final combinedCategories = <VendorCategoryModel>[];

    // Add primary results
    combinedVendors.addAll(primary['vendors'] as List<VendorModel>);
    combinedProducts.addAll(primary['products'] as List<ProductModel>);
    combinedCategories.addAll(
      primary['categories'] as List<VendorCategoryModel>,
    );

    // Add fallback results (avoiding duplicates)
    for (var vendor in fallback['vendors'] as List<VendorModel>) {
      if (!combinedVendors.any((v) => v.id == vendor.id)) {
        combinedVendors.add(vendor);
      }
    }

    for (var product in fallback['products'] as List<ProductModel>) {
      if (!combinedProducts.any((p) => p.id == product.id)) {
        combinedProducts.add(product);
      }
    }

    for (var category in fallback['categories'] as List<VendorCategoryModel>) {
      if (!combinedCategories.any((c) => c.id == category.id)) {
        combinedCategories.add(category);
      }
    }

    _updateSearchResults({
      'vendors': combinedVendors,
      'products': combinedProducts,
      'categories': combinedCategories,
    });
    notifyListeners();
  }

  /// **UPDATE SEARCH RESULTS**
  void _updateSearchResults(Map<String, dynamic> results) {
    restaurantResults.assignAll(results['vendors'] as List<VendorModel>);
    productResults.assignAll(results['products'] as List<ProductModel>);
    categoryResults.assignAll(
      results['categories'] as List<VendorCategoryModel>,
    );

    // **FIX: Update counts properly**
    final totalResults =
        (results['vendors'] as List).length +
        (results['products'] as List).length +
        (results['categories'] as List).length;

    currentResultCount = totalResults;
    totalAvailableResults = totalResults;

    // Update pagination state - FIXED: hasMoreResults should be true when we haven't reached limits yet
    hasMoreResults =
        (results['vendors'] as List).length < RESTAURANT_SEARCH_LIMIT ||
        (results['products'] as List).length < PRODUCT_SEARCH_LIMIT ||
        (results['categories'] as List).length < CATEGORY_SEARCH_LIMIT;
    notifyListeners();
  }

  /// **LOAD MORE RESULTS ENHANCED - MULTI-COLLECTION SEARCH**
  Future<void> loadMoreResultsEnhanced() async {
    if (isLoadingMore || !hasMoreResults) {
      print("⚠️ Load more not available or already in progress");
      return;
    }

    try {
      isLoadingMore = true;
      print("🔄 Loading more results via enhanced multi-collection search...");

      final currentQuery = searchText;
      if (currentQuery.isEmpty) {
        print("⚠️ No search query for load more");
        return;
      }

      final lowerQuery = currentQuery.toLowerCase().trim();

      // **LOAD MORE: Search with current limits to get more results**
      final futures = await Future.wait([
        _searchVendorsOptimized(lowerQuery, RESTAURANT_SEARCH_LIMIT),
        _searchProductsOptimized(lowerQuery, PRODUCT_SEARCH_LIMIT),
        _searchCategoriesOptimized(lowerQuery, CATEGORY_SEARCH_LIMIT),
      ]);

      final moreVendors = futures[0] as List<VendorModel>;
      final moreProducts = futures[1] as List<ProductModel>;
      final moreCategories = futures[2] as List<VendorCategoryModel>;

      // **MERGE WITH EXISTING RESULTS (avoid duplicates)**
      final existingVendorIds = restaurantResults.map((v) => v.id).toSet();
      final existingProductIds = productResults.map((p) => p.id).toSet();
      final existingCategoryIds = categoryResults.map((c) => c.id).toSet();

      int newVendorsAdded = 0;
      int newProductsAdded = 0;
      int newCategoriesAdded = 0;

      // Add new vendors
      for (var vendor in moreVendors) {
        if (!existingVendorIds.contains(vendor.id)) {
          restaurantResults.add(vendor);
          newVendorsAdded++;
        }
      }

      // Add new products
      for (var product in moreProducts) {
        if (!existingProductIds.contains(product.id)) {
          productResults.add(product);
          newProductsAdded++;
        }
      }

      // Add new categories
      for (var category in moreCategories) {
        if (!existingCategoryIds.contains(category.id)) {
          categoryResults.add(category);
          newCategoriesAdded++;
        }
      }

      // **UPDATE COUNTS**
      final totalResults =
          restaurantResults.length +
          productResults.length +
          categoryResults.length;
      currentResultCount = totalResults;
      totalAvailableResults = totalResults;

      // **UPDATE PAGINATION STATE - FIXED: hasMoreResults should be false if we got no new results**
      final totalNewResults =
          newVendorsAdded + newProductsAdded + newCategoriesAdded;
      hasMoreResults =
          totalNewResults > 0; // Only true if we actually got new results
      notifyListeners();
    } catch (e) {
      print("❌ Load more enhanced failed: $e");
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
    notifyListeners();
  }
}
