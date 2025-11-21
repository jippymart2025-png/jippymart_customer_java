import 'dart:convert';

import 'package:jippymart_customer/models/mart_category_model.dart';
import 'package:jippymart_customer/models/mart_item_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/utils/utils/common.dart';

class MartSearchProvider extends ChangeNotifier {
  // Search state
  String searchQuery = '';
  bool isSearching = false;
  bool isLoading = false;
  String errorMessage = '';

  // Search results
  List<MartItemModel> searchResults = <MartItemModel>[];
  List<MartCategoryModel> categoryResults = <MartCategoryModel>[];

  // Pagination
  int currentPage = 1;
  bool hasMoreItems = false;

  // Search history
  List<String> searchHistory = <String>[];

  // API Configuration
  static const String baseUrl = 'https://jippymart.in/api';
  static const String itemsEndpoint = '/search/items';
  static const String categoriesEndpoint = '/search/categories';

  // Search items using API
  Future<void> searchItems(
    String query, {
    int page = 1,
    bool append = false,
  }) async {
    if (query.trim().isEmpty) {
      clearResults();
      return;
    }

    try {
      isLoading = true;
      errorMessage = '';

      if (!append) {
        currentPage = page;
        searchResults.clear();
      }
      // Use API search
      await _searchItemsViaAPI(query, page: page, append: append);
    } catch (e) {
      errorMessage = 'Error searching items: $e';
      print('[MART_SEARCH] ❌ Search error: $e');
    } finally {
      isLoading = false;
    }
    notifyListeners();
  }

  // Search items via API
  Future<void> _searchItemsViaAPI(
    String query, {
    int page = 1,
    bool append = false,
  }) async {
    try {
      print('[MART_SEARCH] 🔍 Searching via API for: "$query" (page: $page)');
      // Removed isAvailable to avoid 422 validation errors
      final uri = Uri.parse('$baseUrl$itemsEndpoint').replace(
        queryParameters: {
          'search': query,
          'page': page.toString(),
          'limit': '40',
        },
      );
      print('[MART_SEARCH] 📡 API URL: $uri');
      final response = await http
          .get(uri, headers: await getHeaders())
          .timeout(const Duration(seconds: 10));
      print('[MART_SEARCH] 📡 API Response Status: ${response.statusCode}');
      print('[MART_SEARCH] 📡 API Response Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final itemsList = (data['data'] as List);
          final items = itemsList
              .map((item) => MartItemModel.fromJson(item))
              .toList();

          if (append) {
            searchResults.addAll(items);
          } else {
            searchResults = items;
          }

          // Update pagination info
          if (data['pagination'] != null) {
            hasMoreItems = data['pagination']['has_more'] ?? false;
          } else {
            hasMoreItems = false;
          }

          _saveToHistory(query);
          print(
            '[MART_SEARCH] ✅ API search successful: ${items.length} items found',
          );
          notifyListeners();
        } else {
          searchResults.clear();
          errorMessage = data['message'] ?? 'No results found';
          print(
            '[MART_SEARCH] ⚠️ API returned success=false: ${data['message']}',
          );
          notifyListeners();
        }
      } else {
        searchResults.clear();
        errorMessage = 'Failed to search items. Please try again.';
        print(
          '[MART_SEARCH] ❌ API request failed with status: ${response.statusCode}',
        );
        print('[MART_SEARCH] ❌ Error details: ${response.body}');
        notifyListeners();
      }
    } catch (e) {
      print('[MART_SEARCH] ❌ API search failed: $e');
      searchResults.clear();
      errorMessage = 'Search failed. Please check your connection.';
      notifyListeners();
      rethrow;
    }
  }

  // Search categories using API
  Future<void> searchCategories(String query) async {
    if (query.trim().isEmpty) {
      categoryResults.clear();
      return;
    }

    try {
      isLoading = true;
      errorMessage = '';

      // Use API search
      await _searchCategoriesViaAPI(query);
    } catch (e) {
      errorMessage = 'Error searching categories: $e';
      print('[MART_SEARCH] ❌ Category search error: $e');
    } finally {
      isLoading = false;
    }
    notifyListeners();
  }

  // Search categories via API
  Future<void> _searchCategoriesViaAPI(String query) async {
    try {
      print('[MART_SEARCH] 🔍 Searching categories via API for: "$query"');
      // Build API URL with query parameters
      final uri = Uri.parse(
        '$baseUrl$categoriesEndpoint',
      ).replace(queryParameters: {'q': query, 'limit': '20'});

      print('[MART_SEARCH] 📡 API URL: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('[MART_SEARCH] 📡 API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final categoriesList = (data['data'] as List);
          final categories = categoriesList
              .map((cat) => MartCategoryModel.fromJson(cat))
              .toList();

          categoryResults = categories;
          print(
            '[MART_SEARCH] ✅ API category search successful: ${categories.length} categories found',
          );
        } else {
          categoryResults.clear();
          errorMessage = data['message'] ?? 'No categories found';
          print(
            '[MART_SEARCH] ⚠️ API returned success=false: ${data['message']}',
          );
        }
      } else {
        categoryResults.clear();
        errorMessage = 'Failed to search categories. Please try again.';
        print(
          '[MART_SEARCH] ❌ API request failed with status: ${response.statusCode}',
        );
      }
      notifyListeners();
    } catch (e) {
      notifyListeners();
      print('[MART_SEARCH] ❌ API category search failed: $e');
      categoryResults.clear();
      errorMessage = 'Category search failed. Please check your connection.';
      rethrow;
    }
    notifyListeners();
  }

  // Combined search (items only - no categories)
  Future<void> searchAll(String query) async {
    if (query.trim().isEmpty) {
      clearResults();
      return;
    }

    searchQuery = query.trim();
    isSearching = true;

    // Search only items (no categories)
    await searchItems(query);

    isSearching = false;
    notifyListeners();
  }

  // Load more items (pagination)
  Future<void> loadMoreItems() async {
    if (hasMoreItems && !isLoading && searchQuery.isNotEmpty) {
      await searchItems(searchQuery, page: currentPage + 1, append: true);
    }
    notifyListeners();
  }

  // Clear all results
  void clearResults() {
    searchResults.clear();
    categoryResults.clear();
    searchQuery = '';
    isSearching = false;
    errorMessage = '';
    currentPage = 1;
    hasMoreItems = false;
    notifyListeners();
  }

  // Save search query to history
  void _saveToHistory(String query) {
    if (query.trim().isNotEmpty && !searchHistory.contains(query.trim())) {
      searchHistory.insert(0, query.trim());
      if (searchHistory.length > 10) {
        searchHistory.removeLast();
      }
    }
    notifyListeners();
  }

  // Clear search history
  void clearSearchHistory() {
    searchHistory.clear();
    notifyListeners();
  }

  // Remove item from search history
  void removeFromHistory(String query) {
    searchHistory.remove(query);
    notifyListeners();
  }

  // Get featured items using API
  Future<void> getFeaturedItems({String type = 'featured'}) async {
    try {
      isLoading = true;
      errorMessage = '';
      // Use API to get featured items
      await _getFeaturedItemsViaAPI(type: type);
    } catch (e) {
      errorMessage = 'Error loading featured items: $e';
      print('[MART_SEARCH] ❌ Featured items error: $e');
    } finally {
      isLoading = false;
    }
    notifyListeners();
  }

  // Get featured items via API
  Future<void> _getFeaturedItemsViaAPI({String type = 'featured'}) async {
    try {
      print('[MART_SEARCH] 🔍 Getting featured items via API (type: $type)');
      // Build API URL with query parameters
      final uri = Uri.parse(
        '$baseUrl/search/items/featured',
      ).replace(queryParameters: {'type': type, 'limit': '20'});

      print('[MART_SEARCH] 📡 API URL: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('[MART_SEARCH] 📡 API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final itemsList = (data['data'] as List);
          final items = itemsList
              .map((item) => MartItemModel.fromJson(item))
              .toList();
          searchResults = items;
          print(
            '[MART_SEARCH] ✅ API featured items loaded: ${items.length} items',
          );
        } else {
          searchResults.clear();
          errorMessage = data['message'] ?? 'No featured items found';
          print(
            '[MART_SEARCH] ⚠️ API returned success=false: ${data['message']}',
          );
        }
      } else {
        searchResults.clear();
        errorMessage = 'Failed to load featured items. Please try again.';
        print(
          '[MART_SEARCH] ❌ API request failed with status: ${response.statusCode}',
        );
      }
      notifyListeners();
    } catch (e) {
      print('[MART_SEARCH] ❌ API featured items request failed: $e');
      searchResults.clear();
      errorMessage =
          'Failed to load featured items. Please check your connection.';
      notifyListeners();
      rethrow;
    }
    notifyListeners();
  }

  // Get trending searches from API
  Future<List<Map<String, dynamic>>> getTrendingSearches() async {
    try {
      print('[MART_SEARCH] 🔥 Fetching trending searches from API...');
      final response = await http.get(
        Uri.parse('$baseUrl/trending-searches'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final trendingData = (data['data'] as List)
              .map(
                (item) => {
                  'text': item['text'] ?? item['name'] ?? '',
                  'color': _getColorFromString(item['color'] ?? ''),
                  'category': item['category'] ?? 'general',
                  'popularity': item['popularity'] ?? item['search_count'] ?? 0,
                },
              )
              .toList();

          print(
            '[MART_SEARCH] ✅ Trending searches loaded: ${trendingData.length} items',
          );
          notifyListeners();

          return trendingData;
        } else {
          print(
            '[MART_SEARCH] ⚠️ API returned success=false: ${data['message']}',
          );
          notifyListeners();

          return [];
        }
      } else {
        print(
          '[MART_SEARCH] ❌ API request failed with status: ${response.statusCode}',
        );
        notifyListeners();

        return [];
      }
    } catch (e) {
      notifyListeners();

      print('[MART_SEARCH] ❌ Error fetching trending searches: $e');
      return [];
    }
  }

  // Helper method to convert string color to Color object
  Color _getColorFromString(String colorString) {
    try {
      // Remove # if present
      String cleanColor = colorString.replaceAll('#', '');

      // Handle common color names
      switch (cleanColor.toLowerCase()) {
        case 'green':
          return const Color(0xFF4CAF50);
        case 'blue':
          return const Color(0xFF2196F3);
        case 'orange':
          return const Color(0xFFFF9800);
        case 'red':
          return const Color(0xFFE91E63);
        case 'purple':
          return const Color(0xFF9C27B0);
        case 'teal':
          return const Color(0xFF4CAF50);
        case 'pink':
          return const Color(0xFFE91E63);
        case 'indigo':
          return const Color(0xFF3F51B5);
        case 'amber':
          return const Color(0xFFFFC107);
        case 'cyan':
          return const Color(0xFF00BCD4);
        case 'lime':
          return const Color(0xFF8BC34A);
        case 'deeporange':
          return const Color(0xFFFF5722);
        default:
          // Try to parse as hex color
          if (cleanColor.length == 6) {
            return Color(int.parse('FF$cleanColor', radix: 16));
          }
          return const Color(0xFF4CAF50); // Default green
      }
    } catch (e) {
      print('[MART_SEARCH] ❌ Error parsing color: $colorString, using default');
      return const Color(0xFF4CAF50); // Default green
    }
  }

  // Health check
}
