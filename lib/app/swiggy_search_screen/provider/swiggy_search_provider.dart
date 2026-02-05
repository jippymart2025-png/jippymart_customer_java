import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/utils/trie_search.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

class SwiggySearchProvider extends ChangeNotifier {
  final TrieSearch trieSearch = TrieSearch();

  // Search data
  var recentSearches = <String>[];
  var trendingSearches = <String>[];
  var restaurantResults = <VendorModel>[];
  var productResults = <ProductModel>[];
  var categoryResults = <VendorCategoryModel>[];
  var searchSuggestions = <String>[];

  // Search state
  var isSearching = false;
  var showSuggestions = false;
  var searchText = '';
  var hasSearched = false;

  // Loading state
  bool isLoadingData = false;
  bool dataLoaded = false;

  // Pagination
  var isLoadingMore = false;
  var hasMoreResults = true;
  var currentResultCount = 0;
  var totalAvailableResults = 0;
  var currentPage = 1;

  // Timer for debounce
  Timer? _debounceTimer;
  
  // Batch update flag to prevent multiple notifyListeners
  bool _isUpdating = false;

  // Constants
  static const int MAX_RECENT_SEARCHES = 10;
  static const int MAX_SUGGESTIONS = 8;
  static const int SEARCH_LIMIT = 20;
  static const Duration DEBOUNCE_DELAY = Duration(milliseconds: 500);

  /// Initialize search system
  Future<void> initFunction() async {
    try {
      isLoadingData = true;
      notifyListeners();

      await _loadRecentSearches();
      await _loadTrendingSearches();

      isLoadingData = false;
      notifyListeners();

      print("✅ Swiggy Search initialized successfully");
    } catch (e) {
      print("❌ Search initialization failed: $e");
      isLoadingData = false;
      notifyListeners();
    }
  }

  /// Clean up timers
  void onClose() {
    _debounceTimer?.cancel();
  }

  /// Load recent searches from storage
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

  /// Save recent searches to storage
  Future<void> _saveRecentSearches() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_searches', recentSearches);
    } catch (e) {
      print("❌ Error saving recent searches: $e");
    }
  }

  /// Load trending searches
  Future<void> _loadTrendingSearches() async {
    try {
      // You can replace this with your trending searches logic
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
      ]);
      notifyListeners();
    } catch (e) {
      print("❌ Error loading trending searches: $e");
    }
  }

  /// Update search text with debounce
  void updateSearchText(String text) {
    searchText = text;
    _debounceTimer?.cancel();

    if (text.isEmpty) {
      showSuggestions = false;
      hasSearched = false;
      _clearSearchResults();
      return;
    }

    // Debounce search
    _debounceTimer = Timer(DEBOUNCE_DELAY, () {
      if (text.trim().isNotEmpty && text.trim() == searchText.trim()) {
        print("🔍 Auto-triggering search for: '$text'");
        performUnifiedSearch(text.trim());
      }
    });

    // Update suggestions immediately
    _updateSuggestions(text);
  }

  /// Update search suggestions
  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      showSuggestions = false;
      _notifyIfNotUpdating();
      return;
    }
    try {
      final suggestions = trieSearch.getSuggestions(
        query.toLowerCase(),
        maxSuggestions: MAX_SUGGESTIONS,
      );

      searchSuggestions.assignAll(suggestions);
      showSuggestions = suggestions.isNotEmpty;
      _notifyIfNotUpdating();

      print("💡 Showing ${suggestions.length} suggestions");
    } catch (e) {
      print("❌ Suggestions failed: $e");
      showSuggestions = false;
      _notifyIfNotUpdating();
    }
  }
  
  /// Helper to batch notifyListeners calls
  void _notifyIfNotUpdating() {
    if (!_isUpdating) {
      notifyListeners();
    }
  }

  /// Clear search results
  void _clearSearchResults() {
    restaurantResults.clear();
    productResults.clear();
    categoryResults.clear();
    hasSearched = false;
    isSearching = false;
    showSuggestions = false;
    currentResultCount = 0;
    hasMoreResults = true;
    currentPage = 1;
    notifyListeners();
  }

  /// Clear search (public method)
  void clearSearch() {
    searchText = '';
    _clearSearchResults();
  }

  /// Clear recent searches
  void clearRecentSearches() {
    try {
      recentSearches.clear();
      _clearRecentSearchesFromStorage();
      notifyListeners();
      print("✅ Recent searches cleared successfully");
    } catch (e) {
      print("❌ Error clearing recent searches: $e");
    }
  }

  /// Clear recent searches from storage
  Future<void> _clearRecentSearchesFromStorage() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_searches');
    } catch (e) {
      print("❌ Error clearing recent searches from storage: $e");
    }
  }

  /// Save recent search
  void _saveRecentSearch(String query) {
    if (query.isEmpty) return;

    recentSearches.remove(query);
    recentSearches.insert(0, query);

    if (recentSearches.length > MAX_RECENT_SEARCHES) {
      recentSearches.removeRange(MAX_RECENT_SEARCHES, recentSearches.length);
    }

    _saveRecentSearches();
  }

  /// Select a suggestion
  void selectSuggestion(String suggestion) {
    searchText = suggestion;
    showSuggestions = false;
    performUnifiedSearch(suggestion);
  }

  /// Hide suggestions
  void hideSuggestions() {
    showSuggestions = false;
    notifyListeners();
  }

  /// MAIN SEARCH FUNCTION - FAST SINGLE API CALL
  Future<void> performUnifiedSearch(
    String query, {
    bool loadMore = false,
  }) async {
    // Prevent multiple simultaneous searches
    if (isSearching && !loadMore) {
      return;
    }

    _isUpdating = true;
    
    if (!loadMore) {
      // New search
      searchText = query;
      hasSearched = true;
      isLoadingData = true;
      isSearching = true;
      currentPage = 1;
    } else {
      // Load more
      isLoadingMore = true;
      currentPage++;
    }
    
    _isUpdating = false;
    notifyListeners();

    if (query.trim().isEmpty) {
      _clearSearchResults();
      return;
    }

    try {
      print("🚀 FAST Unified search for: '$query' (Page: $currentPage)");

      final Map<String, dynamic> searchResults = await _performUnifiedApiSearch(
        query: query,
        page: currentPage,
        limit: SEARCH_LIMIT,
      );

      _isUpdating = true;
      
      if (loadMore) {
        // Append to existing results
        restaurantResults.addAll(searchResults['restaurants']);
        productResults.addAll(searchResults['products']);
        categoryResults.addAll(searchResults['categories']);
      } else {
        // Replace existing results
        restaurantResults.assignAll(searchResults['restaurants']);
        productResults.assignAll(searchResults['products']);
        categoryResults.assignAll(searchResults['categories']);
      }

      // Update counts
      currentResultCount =
          restaurantResults.length +
          productResults.length +
          categoryResults.length;
      totalAvailableResults =
          searchResults['total_results'] ?? currentResultCount;
      hasMoreResults = searchResults['has_more'] ?? true;

      // Save to recent searches (only for new searches)
      if (!loadMore) {
        _saveRecentSearch(query);
      }

      print("✅ Search completed in 1 API call:");
      print("   - Restaurants: ${restaurantResults.length}");
      print("   - Products: ${productResults.length}");
      print("   - Categories: ${categoryResults.length}");
      print("   - Has more: $hasMoreResults");
    } catch (e) {
      print("❌ Unified search failed: $e");
      // You can add fallback to individual searches here if needed
    } finally {
      _isUpdating = true;
      isLoadingData = false;
      isSearching = false;
      isLoadingMore = false;
      _isUpdating = false;
      notifyListeners();
    }
  }

  /// PERFORM UNIFIED API SEARCH - SINGLE FAST CALL
  Future<Map<String, dynamic>> _performUnifiedApiSearch({
    required String query,
    int page = 1,
    int limit = SEARCH_LIMIT,
  }) async {
    try {
      final String? zoneId = Constant.selectedZone?.id;
      final double latitude =
          Constant.selectedLocation.location?.latitude ?? 0.0;
      final double longitude =
          Constant.selectedLocation.location?.longitude ?? 0.0;
      // Build query parameters
      final Map<String, String> queryParams = {
        'query': query,
        'page': page.toString(),
        'limit': limit.toString(),
      };
      // Add optional parameters
      if (zoneId != null && zoneId.isNotEmpty) {
        queryParams['zone_id'] = zoneId;
      }
      if (latitude != 0.0) {
        queryParams['latitude'] = latitude.toString();
      }
      if (longitude != 0.0) {
        queryParams['longitude'] = longitude.toString();
      }

      final Uri uri = Uri.parse(
        '${AppConst.baseUrl}unified-search',
      ).replace(queryParameters: queryParams);

      print('🌐 Unified API Call: ${uri.toString()}');

      final response = await http
          .get(uri, headers: await getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final Map<String, dynamic> data = responseData['data'];
          final Map<String, dynamic> meta = responseData['meta'] ?? {};

          // Parse restaurants
          final List<VendorModel> restaurants = (data['restaurants'] as List)
              .map((json) => VendorModel.fromJson(json))
              .toList();

          // Parse products
          final List<ProductModel> products = (data['products'] as List)
              .map((json) => ProductModel.fromJson(json))
              .toList();

          // Parse categories
          final List<VendorCategoryModel> categories =
              (data['categories'] as List)
                  .map((json) => VendorCategoryModel.fromJson(json))
                  .toList();

          return {
            'restaurants': restaurants,
            'products': products,
            'categories': categories,
            'total_results': data['total_results'] ?? 0,
            'has_more': meta['has_more'] ?? true,
          };
        } else {
          throw Exception('API error: ${responseData['message']}');
        }
      } else {
        throw Exception('HTTP error ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Unified API search error: $e');
      rethrow;
    }
  }

  /// Load more results
  Future<void> loadMoreResults() async {
    if (isLoadingMore || !hasMoreResults || searchText.isEmpty) {
      return;
    }

    try {
      await performUnifiedSearch(searchText, loadMore: true);
    } catch (e) {
      print("❌ Load more failed: $e");
      isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Get search statistics
  Map<String, dynamic> getSearchStats() {
    return {
      'restaurants_count': restaurantResults.length,
      'products_count': productResults.length,
      'categories_count': categoryResults.length,
      'total_count': currentResultCount,
      'has_more': hasMoreResults,
      'current_page': currentPage,
    };
  }

  /// Clear all data
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
    currentPage = 1;
    trieSearch.clear();
    notifyListeners();
  }
}
