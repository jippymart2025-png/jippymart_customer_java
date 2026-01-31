import 'dart:async';
import 'dart:convert';

import 'package:jippymart_customer/models/mart_category_model.dart';
import 'package:jippymart_customer/models/mart_item_model.dart';
import 'package:jippymart_customer/models/mart_subcategory_model.dart';
import 'package:jippymart_customer/models/mart_vendor_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/services/api_queue_manager.dart';
import 'package:jippymart_customer/services/cache_manager.dart';

class MartFirestoreService extends GetxService {
  // Firebase Firestore instance

  Future<MartFirestoreService> init() async {
    return this;
  }

  /// Get trending items from API
  Future<List<MartItemModel>> getTrendingItems({int limit = 20}) async {
    try {
      print('[MART API] 🔥 Fetching trending items from API...');
      // Make API request
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}mart-items/trending'),
        headers: await getHeaders(),
      );

      print('[MART API] 🔥 API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == true) {
          final List<dynamic> itemsData = responseData['data'];
          final int count = responseData['count'] ?? 0;
          print('[MART API] 🔥 API returned $count trending items');
          if (itemsData.isEmpty) {
            print('[MART API] ⚠️ No trending items found in API response');
            return [];
          }
          // Convert API data to MartItemModel
          final items = itemsData
              .map((itemData) {
                try {
                  // Create a copy of the item data and ensure it's a Map
                  final Map<String, dynamic> data = Map<String, dynamic>.from(
                    itemData,
                  );

                  // Handle any data transformations needed
                  return _parseApiItem(data);
                } catch (e) {
                  print(
                    '[MART API] ❌ Error parsing API item ${itemData['id']}: $e',
                  );
                  print('[MART API] Item data: $itemData');
                  return null;
                }
              })
              .whereType<MartItemModel>()
              .toList();

          print(
            '[MART API] ✅ Successfully parsed ${items.length} trending items from API',
          );
          // Debug: Log the trending items
          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            print(
              '[MART API]   ${i + 1}. ${item.name} - isTrending: ${item.isTrending}, price: ₹${item.price}',
            );
          }
          return items;
        } else {
          print('[MART API] ❌ API returned error: ${responseData['message']}');
          return [];
        }
      } else {
        print('[MART API] ❌ HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[MART API] ❌ Error fetching trending items from API: $e');
      return [];
    }
  }

  /// Helper method to parse API item data
  MartItemModel _parseApiItem(Map<String, dynamic> data) {
    // Handle data transformations from API format to model format
    final Map<String, dynamic> itemData = Map<String, dynamic>.from(data);

    // Ensure required fields have proper defaults
    itemData['id'] = itemData['id']?.toString() ?? '';
    itemData['name'] = itemData['name']?.toString() ?? '';
    itemData['description'] = itemData['description']?.toString() ?? '';
    itemData['photo'] = itemData['photo']?.toString() ?? '';

    // Handle numeric fields
    itemData['price'] = _parsePrice(itemData['price']);
    itemData['disPrice'] = _parsePrice(itemData['disPrice']);
    itemData['quantity'] = itemData['quantity'] ?? 0;

    // Handle boolean fields with proper defaults
    itemData['isAvailable'] = itemData['isAvailable'] ?? true;
    itemData['publish'] = itemData['publish'] ?? true;
    itemData['veg'] = itemData['veg'] ?? false;
    itemData['nonveg'] = itemData['nonveg'] ?? false;
    itemData['isTrending'] = itemData['isTrending'] ?? false;

    // Handle list fields that might be strings in API response
    itemData['addOnsTitle'] = _parseStringToList(itemData['addOnsTitle']);
    itemData['addOnsPrice'] = _parseStringToList(itemData['addOnsPrice']);
    itemData['photos'] = itemData['photos'] is List
        ? List<String>.from(itemData['photos'])
        : [];

    // Handle options field that might be a JSON string
    itemData['options'] = _parseOptions(itemData['options']);

    // Handle product specification
    if (itemData['product_specification'] == null) {
      itemData['product_specification'] = {};
    }

    return MartItemModel.fromJson(itemData);
  }

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is num) return price.toDouble();
    if (price is String) {
      return double.tryParse(price) ?? 0.0;
    }
    return 0.0;
  }

  List<String> _parseStringToList(dynamic data) {
    if (data == null) return [];
    if (data is List) return List<String>.from(data);
    if (data is String) {
      try {
        // Handle cases where the API returns JSON strings like "[]"
        if (data.trim().startsWith('[') && data.trim().endsWith(']')) {
          final parsed = json.decode(data) as List;
          return List<String>.from(parsed);
        }
        return [data];
      } catch (e) {
        return [data];
      }
    }
    return [];
  }

  List<Map<String, dynamic>> _parseOptions(dynamic options) {
    if (options == null) return [];
    if (options is List) return List<Map<String, dynamic>>.from(options);
    if (options is String) {
      try {
        if (options.trim().startsWith('[') && options.trim().endsWith(']')) {
          final parsed = json.decode(options) as List;
          return List<Map<String, dynamic>>.from(parsed);
        }
        return [];
      } catch (e) {
        print('[MART API] Error parsing options: $e');
        return [];
      }
    }
    return [];
  }

  /// Get featured items from API
  Future<List<MartItemModel>> getFeaturedItems({int limit = 20}) async {
    try {
      print('[MART API] ⭐ Fetching featured items from API...');

      // Make API request
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}mart-items/featured'),
        headers: await getHeaders(),
      );

      print('[MART API] ⭐ API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == true) {
          final List<dynamic> itemsData = responseData['data'];
          final int count = responseData['count'] ?? 0;

          print('[MART API] ⭐ API returned $count featured items');

          if (itemsData.isEmpty) {
            print('[MART API] ⚠️ No featured items found in API response');
            return [];
          }

          // Convert API data to MartItemModel
          final items = itemsData
              .map((itemData) {
                try {
                  // Create a copy of the item data and ensure it's a Map
                  final Map<String, dynamic> data = Map<String, dynamic>.from(
                    itemData,
                  );

                  // Handle any data transformations needed
                  return _parseApiItem(data);
                } catch (e) {
                  print(
                    '[MART API] ❌ Error parsing API item ${itemData['id']}: $e',
                  );
                  print('[MART API] Item data: $itemData');
                  return null;
                }
              })
              .whereType<MartItemModel>()
              .toList();

          print(
            '[MART API] ✅ Successfully parsed ${items.length} featured items from API',
          );

          // Debug: Log the featured items
          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            print(
              '[MART API]   ${i + 1}. ${item.name} - isFeature: ${item.isFeature}, price: ₹${item.price}',
            );
          }

          return items;
        } else {
          print('[MART API] ❌ API returned error: ${responseData['message']}');
          return [];
        }
      } else {
        print('[MART API] ❌ HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[MART API] ❌ Error fetching featured items from API: $e');
      return [];
    }
  }

  /// Get items on sale from API
  Future<List<MartItemModel>> getItemsOnSale({int limit = 20}) async {
    try {
      // Make API request
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}mart-items/on-sale'),
        headers: await getHeaders(),
      );

      print('[MART API] 🏷️ API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == true) {
          final List<dynamic> itemsData = responseData['data'];
          final int count = responseData['count'] ?? 0;

          print('[MART API] 🏷️ API returned $count items on sale');

          if (itemsData.isEmpty) {
            print('[MART API] ⚠️ No items on sale found in API response');
            return [];
          }

          // Convert API data to MartItemModel
          final items = itemsData
              .map((itemData) {
                try {
                  // Create a copy of the item data and ensure it's a Map
                  final Map<String, dynamic> data = Map<String, dynamic>.from(
                    itemData,
                  );

                  // Handle any data transformations needed
                  return _parseApiItem(data);
                } catch (e) {
                  print(
                    '[MART API] ❌ Error parsing API item ${itemData['id']}: $e',
                  );
                  print('[MART API] Item data: $itemData');
                  return null;
                }
              })
              .whereType<MartItemModel>()
              .toList();

          // Note: The API already returns only items on sale, so no need for additional filtering
          // But we can add a safety check to ensure items have valid sale prices
          final validSaleItems = items
              .where(
                (item) =>
                    item.disPrice != null &&
                    item.disPrice! > 0 &&
                    item.disPrice! < item.price,
              )
              .toList();

          print(
            '[MART API] ✅ Successfully parsed ${validSaleItems.length} valid items on sale from API',
          );

          // Debug: Log the sale items with discount information
          for (int i = 0; i < validSaleItems.length; i++) {
            final item = validSaleItems[i];
            final discountPercent =
                ((item.price - item.disPrice!) / item.price * 100).round();
            print(
              '[MART API]   ${i + 1}. ${item.name} - Original: ₹${item.price}, Sale: ₹${item.disPrice} (${discountPercent}% off)',
            );
          }

          return validSaleItems;
        } else {
          print('[MART API] ❌ API returned error: ${responseData['message']}');
          return [];
        }
      } else {
        print('[MART API] ❌ HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[MART API] ❌ Error fetching items on sale from API: $e');
      return [];
    }
  }

  /// Search items by name or description using API
  Future<List<MartItemModel>> searchItems({
    required String searchQuery,
    int limit = 20,
  }) async {
    try {
      print('[MART API] 🔍 Searching for items: "$searchQuery"');
      // Make API request with search query parameter
      final response = await http.get(
        Uri.parse(
          '${AppConst.baseUrl}mart-items/search?searchQuery=$searchQuery',
        ),
        headers: await getHeaders(),
      );

      print('[MART API] 🔍 API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == true) {
          final List<dynamic> itemsData = responseData['data'];
          final int count = responseData['count'] ?? 0;

          print(
            '[MART API] 🔍 API returned $count search results for "$searchQuery"',
          );

          if (itemsData.isEmpty) {
            print(
              '[MART API] ⚠️ No items found for search query: "$searchQuery"',
            );
            return [];
          }

          // Convert API data to MartItemModel
          final searchResults = itemsData
              .map((itemData) {
                try {
                  // Create a copy of the item data and ensure it's a Map
                  final Map<String, dynamic> data = Map<String, dynamic>.from(
                    itemData,
                  );

                  // Handle any data transformations needed
                  return _parseApiItem(data);
                } catch (e) {
                  print(
                    '[MART API] ❌ Error parsing API item ${itemData['id']}: $e',
                  );
                  print('[MART API] Item data: $itemData');
                  return null;
                }
              })
              .whereType<MartItemModel>()
              .toList();
          print(
            '[MART API] ✅ Search completed, found ${searchResults.length} matching items for "$searchQuery"',
          );
          // Debug: Log the search results
          for (int i = 0; i < searchResults.length; i++) {
            final item = searchResults[i];
            final shortDescription = item.description.length > 50
                ? '${item.description.substring(0, 50)}...'
                : item.description;
            print('[MART API]   ${i + 1}. ${item.name} - $shortDescription');
          }

          return searchResults;
        } else {
          print('[MART API] ❌ API returned error: ${responseData['message']}');
          return [];
        }
      } else {
        print('[MART API] ❌ HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[MART API] ❌ Error searching items: $e');
      return [];
    }
  }

  // ==================== CATEGORIES METHODS ====================
  /// Get all categories from API (with caching and queuing)
  Future<List<MartCategoryModel>> getCategories({int limit = 100}) async {
    const cacheKey = 'mart_categories';

    // Try cache first
    final cached = CacheManager().getCategories<List<MartCategoryModel>>(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      print('[MART API] 📂 Using cached categories (${cached.length} items)');
      return cached.take(limit).toList();
    }

    // Use queue manager for API call
    return await ApiQueueManager().enqueue(
      priority: RequestPriority.high,
      request: () async {
        try {
          print('[MART API] 📂 Fetching categories from API...');
          final url = '${AppConst.baseUrl}mart-items/getmartcategory';
          final response = await http.get(
            Uri.parse(url),
            headers: await getHeaders(),
          );
          if (response.statusCode != 200) {
            print('[MART API] ❌ HTTP error: ${response.statusCode}');
            return [];
          }
          final responseData = json.decode(response.body);

          // Support both 'status' and 'success' (API inconsistency)
          final isSuccess = responseData['status'] == true ||
              responseData['success'] == true;
          if (!isSuccess) {
            print(
              '[MART API] ❌ API returned error: ${responseData['message'] ?? responseData['msg']}',
            );
            return [];
          }
          print(
            '[MART API] 📂 API call completed, found ${responseData['count']} categories',
          );

          if (responseData['data'] == null || responseData['data'].isEmpty) {
            print('[MART API] ⚠️ No categories found');
            return [];
          }
          // Convert API response to MartCategoryModel
          final categories = (responseData['data'] as List)
              .map((item) {
                try {
                  if (item == null) return null;

                  final Map<String, dynamic> categoryData =
                      Map<String, dynamic>.from(item);

                  // Handle array fields that might be strings
                  // In getCategories method - keep this as it's correct
                  if (categoryData['review_attributes'] is String) {
                    try {
                      categoryData['review_attributes'] = json.decode(
                        categoryData['review_attributes'],
                      );
                    } catch (e) {
                      categoryData['review_attributes'] = [];
                    }
                  } else if (categoryData['review_attributes'] == null) {
                    categoryData['review_attributes'] = [];
                  }

                  // Handle numeric fields that might be strings
                  if (categoryData['category_order'] is String) {
                    categoryData['category_order'] =
                        int.tryParse(categoryData['category_order']) ?? 0;
                  }
                  if (categoryData['section_order'] is String) {
                    categoryData['section_order'] =
                        int.tryParse(categoryData['section_order']) ?? 0;
                  }

                  // Handle boolean fields that might be null
                  if (categoryData['show_in_homepage'] == null) {
                    categoryData['show_in_homepage'] = false;
                  }
                  if (categoryData['publish'] == null) {
                    categoryData['publish'] = true;
                  }
                  if (categoryData['has_subcategories'] == null) {
                    categoryData['has_subcategories'] = false;
                  }

                  // Handle subcategories_count
                  if (categoryData['subcategories_count'] == null) {
                    categoryData['subcategories_count'] = 0;
                  }
                  return MartCategoryModel.fromJson(categoryData);
                } catch (e) {
                  return null;
                }
              })
              .whereType<MartCategoryModel>()
              .toList();

          // Sort categories by category_order
          categories.sort(
            (a, b) => (a.categoryOrder ?? 0).compareTo(b.categoryOrder ?? 0),
          );

          // Cache the full result
          CacheManager().setCategories(cacheKey, categories);

          // Apply limit
          final limitedResults = categories.take(limit).toList();

          print(
            '[MART API] ✅ Successfully parsed ${limitedResults.length} categories from API',
          );

          // Debug: Log the categories
          for (int i = 0; i < limitedResults.length; i++) {
            final category = limitedResults[i];
            final title = category.title ?? 'No Title';
            final order = category.categoryOrder ?? 0;
            final section = category.section ?? 'No Section';
            print(
              '[MART API]   ${i + 1}. $title - Order: $order, Section: $section',
            );
          }

          return limitedResults;
        } catch (e) {
          print('[MART API] ❌ Error fetching categories from API: $e');
          return [];
        }
      },
      key: cacheKey, // Deduplication key
    );
  }

  /// Get homepage categories from API
  Future<List<MartCategoryModel>> getHomepageCategories({
    int limit = 10,
  }) async {
    try {
      print('[MART API] 🏠 Fetching homepage categories from API...');
      // Build the API URL
      final url = '${AppConst.baseUrl}mart-items/categoryhome';

      final response = await http.get(
        Uri.parse(url),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        print('[MART API] ❌ HTTP error: ${response.statusCode}');
        return [];
      }

      final responseData = json.decode(response.body);

      final isSuccess = responseData['status'] == true ||
          responseData['success'] == true;
      if (!isSuccess) {
        print(
          '[MART API] ❌ API returned error: ${responseData['message'] ?? responseData['msg']}',
        );
        return [];
      }

      print(
        '[MART API] 🏠 API call completed, found ${responseData['count']} homepage categories',
      );

      if (responseData['data'] == null || responseData['data'].isEmpty) {
        print('[MART API] ⚠️ No homepage categories found');
        return [];
      }

      // Convert API response to MartCategoryModel
      final categories = (responseData['data'] as List)
          .map((item) {
            try {
              if (item == null) return null;

              final Map<String, dynamic> categoryData =
                  Map<String, dynamic>.from(item);

              // Handle array fields that might be strings
              if (categoryData['review_attributes'] is String) {
                try {
                  categoryData['review_attributes'] = json.decode(
                    categoryData['review_attributes'],
                  );
                } catch (e) {
                  categoryData['review_attributes'] = [];
                }
              } else if (categoryData['review_attributes'] == null) {
                categoryData['review_attributes'] = [];
              }

              // Handle numeric fields that might be strings
              if (categoryData['category_order'] is String) {
                categoryData['category_order'] =
                    int.tryParse(categoryData['category_order']) ?? 0;
              }
              if (categoryData['section_order'] is String) {
                categoryData['section_order'] =
                    int.tryParse(categoryData['section_order']) ?? 0;
              }
              // Handle boolean fields that might be null
              if (categoryData['show_in_homepage'] == null) {
                categoryData['show_in_homepage'] = false;
              }
              if (categoryData['publish'] == null) {
                categoryData['publish'] = true;
              }
              if (categoryData['has_subcategories'] == null) {
                categoryData['has_subcategories'] = false;
              }
              // Handle subcategories_count
              if (categoryData['subcategories_count'] == null) {
                categoryData['subcategories_count'] = 0;
              }
              return MartCategoryModel.fromJson(categoryData);
            } catch (e) {
              return null;
            }
          })
          .whereType<MartCategoryModel>()
          .toList();
      // Sort categories by category_order
      categories.sort(
        (a, b) => (a.categoryOrder ?? 0).compareTo(b.categoryOrder ?? 0),
      );
      // Apply limit
      final limitedResults = categories.take(limit).toList();
      print(
        '[MART API] ✅ Successfully parsed ${limitedResults.length} homepage categories from API',
      );
      // Debug: Log the homepage categories
      for (int i = 0; i < limitedResults.length; i++) {
        final category = limitedResults[i];
        final title = category.title ?? 'No Title';
        final order = category.categoryOrder ?? 0;
        final section = category.section ?? 'No Section';
        print(
          '[MART API]   ${i + 1}. $title - Order: $order, Section: $section',
        );
      }
      return limitedResults;
    } catch (e) {
      print('[MART API] ❌ Error fetching homepage categories from API: $e');
      print('[MART API] ❌ Error type: ${e.runtimeType}');
      print('[MART API] ❌ Error details: $e');
      return [];
    }
  }

  Future<List<MartSubcategoryModel>> getSubcategoriesByParent({
    required String parentCategoryId,
    bool publish = true,
    String sortBy = 'subcategory_order',
    String sortOrder = 'asc',
    int limit = 100,
  }) async {
    try {
      print(
        '[MART API] 📋 Fetching subcategories for parent category: $parentCategoryId',
      );
      // Build the API URL
      final url =
          '${AppConst.baseUrl}mart-items/sub_category?parent_category_id=$parentCategoryId';
      print('getSubcategoriesByParent $url');
      final response = await http.get(
        Uri.parse(url),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        print('[MART API] ❌ HTTP error: ${response.statusCode}');
        return [];
      }

      final responseData = json.decode(response.body);

      if (!responseData['status']) {
        print(
          '[MART API] ❌ API returned false status: ${responseData['message']}',
        );
        return [];
      }

      print(
        '[MART API] 📋 API call completed, found ${responseData['count']} subcategories',
      );

      if (responseData['data'] == null || responseData['data'].isEmpty) {
        print(
          '[MART API] ⚠️ No subcategories found for parent category: $parentCategoryId',
        );
        return [];
      }
      // Convert API response to MartSubcategoryModel
      final subcategories = (responseData['data'] as List)
          .map((item) {
            try {
              if (item == null) return null;

              final Map<String, dynamic> subcategoryData =
                  Map<String, dynamic>.from(item);

              // Handle array fields that might be strings
              if (subcategoryData['review_attributes'] is String) {
                try {
                  subcategoryData['review_attributes'] = json.decode(
                    subcategoryData['review_attributes'],
                  );
                } catch (e) {
                  subcategoryData['review_attributes'] = [];
                }
              } else if (subcategoryData['review_attributes'] == null) {
                subcategoryData['review_attributes'] = [];
              }

              // Handle numeric fields that might be strings
              if (subcategoryData['subcategory_order'] is String) {
                subcategoryData['subcategory_order'] =
                    int.tryParse(subcategoryData['subcategory_order']) ?? 0;
              }
              if (subcategoryData['category_order'] is String) {
                subcategoryData['category_order'] =
                    int.tryParse(subcategoryData['category_order']) ?? 0;
              }
              if (subcategoryData['section_order'] is String) {
                subcategoryData['section_order'] =
                    int.tryParse(subcategoryData['section_order']) ?? 0;
              }

              // Handle boolean fields that might be null
              if (subcategoryData['publish'] == null) {
                subcategoryData['publish'] = true;
              }
              if (subcategoryData['show_in_homepage'] == null) {
                subcategoryData['show_in_homepage'] = false;
              }

              return MartSubcategoryModel.fromJson(subcategoryData);
            } catch (e) {
              return null;
            }
          })
          .whereType<MartSubcategoryModel>()
          .toList();
      // Sort subcategories based on sort parameters
      if (sortBy == 'subcategory_order') {
        if (sortOrder == 'asc') {
          subcategories.sort(
            (a, b) =>
                (a.subcategoryOrder ?? 0).compareTo(b.subcategoryOrder ?? 0),
          );
        } else {
          subcategories.sort(
            (a, b) =>
                (b.subcategoryOrder ?? 0).compareTo(a.subcategoryOrder ?? 0),
          );
        }
      } else if (sortBy == 'title') {
        if (sortOrder == 'asc') {
          subcategories.sort(
            (a, b) => (a.title ?? '').compareTo(b.title ?? ''),
          );
        } else {
          subcategories.sort(
            (a, b) => (b.title ?? '').compareTo(a.title ?? ''),
          );
        }
      }

      // Apply limit
      final limitedResults = subcategories.take(limit).toList();

      print(
        '[MART API] ✅ Successfully parsed ${limitedResults.length} subcategories from API',
      );

      // Debug: Log the subcategories
      for (int i = 0; i < limitedResults.length; i++) {
        final subcategory = limitedResults[i];
        final title = subcategory.title ?? 'No Title';
        final order = subcategory.subcategoryOrder ?? 0;
        final parentId = subcategory.parentCategoryId ?? 'No Parent';
        print(
          '[MART API]   ${i + 1}. $title - Order: $order, Parent: $parentId',
        );
      }

      return limitedResults;
    } catch (e) {
      print('[MART API] ❌ Error fetching subcategories from API: $e');
      return [];
    }
  }

  /// Get all homepage subcategories directly from Firestore
  Future<List<MartSubcategoryModel>> getAllHomepageSubcategories() async {
    try {
      print('[MART API] 🔥 Fetching all homepage subcategories from API...');

      final url = '${AppConst.baseUrl}mart-items/sub_category_home';
      final response = await http.get(
        Uri.parse(url),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        print('[MART API] ❌ HTTP error: ${response.statusCode}');
        return [];
      }

      final responseData = json.decode(response.body);

      if (!responseData['status']) {
        print(
          '[MART API] ❌ API returned false status: ${responseData['message']}',
        );
        return [];
      }

      print(
        '[MART API] 🔥 API call completed, found ${responseData['count']} homepage subcategories',
      );

      if (responseData['data'] == null || responseData['data'].isEmpty) {
        print('[MART API] ⚠️ No homepage subcategories found');
        return [];
      }

      // Log ALL documents found before parsing
      print('[MART API] 📋 ALL DOCUMENTS FOUND:');
      for (int i = 0; i < responseData['data'].length; i++) {
        final item = responseData['data'][i];
        print('[MART API] 📋 ${i + 1}. ID: ${item['id']}');
        print('[MART API] 📋    Data: $item');
        print('[MART API] 📋    show_in_homepage: ${item['show_in_homepage']}');
        print('[MART API] 📋    publish: ${item['publish']}');
        print('[MART API] 📋    title: ${item['title']}');
        print(
          '[MART API] 📋    parent_category_id: ${item['parent_category_id']}',
        );
        print('[MART API] 📋    ---');
      }

      // Convert API response to MartSubcategoryModel
      final subcategories = (responseData['data'] as List)
          .map((item) {
            try {
              if (item == null) {
                print('[MART API] ❌ Item is null');
                return null;
              }

              final Map<String, dynamic> subcategoryData =
                  Map<String, dynamic>.from(item);

              // Handle array fields that might be strings
              if (subcategoryData['review_attributes'] is String) {
                try {
                  subcategoryData['review_attributes'] = json.decode(
                    subcategoryData['review_attributes'],
                  );
                } catch (e) {
                  subcategoryData['review_attributes'] = [];
                }
              } else if (subcategoryData['review_attributes'] == null) {
                subcategoryData['review_attributes'] = [];
              }

              // Handle numeric fields that might be strings
              if (subcategoryData['category_order'] is String) {
                subcategoryData['category_order'] =
                    int.tryParse(subcategoryData['category_order']) ?? 0;
              }
              if (subcategoryData['section_order'] is String) {
                subcategoryData['section_order'] =
                    int.tryParse(subcategoryData['section_order']) ?? 0;
              }
              if (subcategoryData['subcategory_order'] is String) {
                subcategoryData['subcategory_order'] =
                    int.tryParse(subcategoryData['subcategory_order']) ?? 0;
              }

              // Handle boolean fields that might be null
              if (subcategoryData['show_in_homepage'] == null) {
                subcategoryData['show_in_homepage'] = false;
              }
              if (subcategoryData['publish'] == null) {
                subcategoryData['publish'] = true;
              }

              // Log the data being passed to fromJson
              print('[MART API] 🔍 Parsing item ${subcategoryData['id']}:');
              print('[MART API] 🔍   Raw data: $subcategoryData');

              final subcategory = MartSubcategoryModel.fromJson(
                subcategoryData,
              );
              print(
                '[MART API] ✅ Successfully parsed ${subcategoryData['id']}: ${subcategory.title}',
              );
              return subcategory;
            } catch (e) {
              print(
                '[MART API] ❌ Error parsing subcategory item ${item['id']}: $e',
              );
              print('[MART API] Item data: $item');
              return null;
            }
          })
          .whereType<MartSubcategoryModel>()
          .toList();

      // Sort subcategories by subcategory_order
      subcategories.sort(
        (a, b) => (a.subcategoryOrder ?? 0).compareTo(b.subcategoryOrder ?? 0),
      );

      print(
        '[MART API] ✅ Successfully parsed ${subcategories.length} homepage subcategories from API',
      );
      print('[MART API] 📊 PARSED SUBCATEGORIES:');

      // Debug: Log the homepage subcategories
      for (int i = 0; i < subcategories.length; i++) {
        final subcategory = subcategories[i];
        print(
          '[MART API]   ${i + 1}. ${subcategory.title} - Parent: ${subcategory.parentCategoryTitle} - Show in Homepage: ${subcategory.showInHomepage}',
        );
      }

      return subcategories;
    } catch (e) {
      print('[MART API] ❌ Error fetching homepage subcategories from API: $e');
      return [];
    }
  }

  /// Get ALL subcategories from Firestore (for debugging - no filters)

  /// Search subcategories by name or description
  Future<List<MartSubcategoryModel>> searchSubcategories({
    required String searchQuery,
    int limit = 20,
  }) async {
    try {
      print('[MART API] 🔍 Searching for subcategories: "$searchQuery"');

      // Build the API URL
      final url =
          '${AppConst.baseUrl}mart-items/searchSubcategories?query=${Uri.encodeComponent(searchQuery)}&limit=$limit';

      final response = await http.get(
        Uri.parse(url),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        print('[MART API] ❌ HTTP error: ${response.statusCode}');
        return [];
      }

      final responseData = json.decode(response.body);

      if (!responseData['success']) {
        print('[MART API] ❌ API returned false status');
        return [];
      }

      print(
        '[MART API] 🔍 API search completed, found ${responseData['count']} subcategories',
      );

      if (responseData['data'] == null || responseData['data'].isEmpty) {
        print(
          '[MART API] ⚠️ No subcategories found for search: "$searchQuery"',
        );
        return [];
      }

      // Convert API response to MartSubcategoryModel
      final subcategories = (responseData['data'] as List)
          .map((item) {
            try {
              if (item == null) return null;

              final Map<String, dynamic> subcategoryData =
                  Map<String, dynamic>.from(item);

              // Handle array fields that might be strings
              if (subcategoryData['review_attributes'] is String) {
                try {
                  subcategoryData['review_attributes'] = json.decode(
                    subcategoryData['review_attributes'],
                  );
                } catch (e) {
                  subcategoryData['review_attributes'] = [];
                }
              } else if (subcategoryData['review_attributes'] == null) {
                subcategoryData['review_attributes'] = [];
              }

              // Handle numeric fields that might be strings
              if (subcategoryData['category_order'] is String) {
                subcategoryData['category_order'] =
                    int.tryParse(subcategoryData['category_order']) ?? 0;
              }
              if (subcategoryData['section_order'] is String) {
                subcategoryData['section_order'] =
                    int.tryParse(subcategoryData['section_order']) ?? 0;
              }
              if (subcategoryData['subcategory_order'] is String) {
                subcategoryData['subcategory_order'] =
                    int.tryParse(subcategoryData['subcategory_order']) ?? 0;
              }

              // Handle boolean fields that might be null
              if (subcategoryData['show_in_homepage'] == null) {
                subcategoryData['show_in_homepage'] = false;
              }
              if (subcategoryData['publish'] == null) {
                subcategoryData['publish'] = true;
              }

              return MartSubcategoryModel.fromJson(subcategoryData);
            } catch (e) {
              return null;
            }
          })
          .whereType<MartSubcategoryModel>()
          .toList();

      print(
        '[MART API] ✅ Search completed, found ${subcategories.length} matching subcategories for "$searchQuery"',
      );

      // Debug: Log the search results
      for (int i = 0; i < subcategories.length; i++) {
        final subcategory = subcategories[i];
        final title = subcategory.title ?? 'No Title';
        final description = subcategory.description ?? 'No Description';
        final shortDescription = description.length > 50
            ? '${description.substring(0, 50)}...'
            : description;
        print('[MART API]   ${i + 1}. $title - $shortDescription');
      }

      return subcategories;
    } catch (e) {
      print('[MART API] ❌ Error searching subcategories: $e');
      return [];
    }
  }

  /// Search categories by title or description
  Future<List<MartCategoryModel>> searchCategories({
    required String searchQuery,
    int limit = 20,
  }) async {
    try {
      print('[MART API] 🔍 Searching for categories: "$searchQuery"');

      // Build the API URL
      final url =
          '${AppConst.baseUrl}mart-items/searchCategories?query=${Uri.encodeComponent(searchQuery)}';

      final response = await http.get(
        Uri.parse(url),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        print('[MART API] ❌ HTTP error: ${response.statusCode}');
        return [];
      }

      final responseData = json.decode(response.body);

      if (!responseData['success']) {
        print('[MART API] ❌ API returned false status');
        return [];
      }

      print(
        '[MART API] 🔍 API search completed, found ${responseData['count']} categories',
      );

      if (responseData['data'] == null || responseData['data'].isEmpty) {
        print('[MART API] ⚠️ No categories found for search: "$searchQuery"');
        return [];
      }

      // Convert API response to MartCategoryModel
      final categories = (responseData['data'] as List)
          .map((item) {
            try {
              if (item == null) return null;

              final Map<String, dynamic> categoryData =
                  Map<String, dynamic>.from(item);

              // Handle array fields that might be strings
              if (categoryData['review_attributes'] is String) {
                try {
                  categoryData['review_attributes'] = json.decode(
                    categoryData['review_attributes'],
                  );
                } catch (e) {
                  categoryData['review_attributes'] = [];
                }
              } else if (categoryData['review_attributes'] == null) {
                categoryData['review_attributes'] = [];
              }

              // Handle numeric fields that might be strings
              if (categoryData['category_order'] is String) {
                categoryData['category_order'] =
                    int.tryParse(categoryData['category_order']) ?? 0;
              }
              if (categoryData['section_order'] is String) {
                categoryData['section_order'] =
                    int.tryParse(categoryData['section_order']) ?? 0;
              }

              // Handle boolean fields that might be null
              if (categoryData['show_in_homepage'] == null) {
                categoryData['show_in_homepage'] = false;
              }
              if (categoryData['publish'] == null) {
                categoryData['publish'] = true;
              }
              if (categoryData['has_subcategories'] == null) {
                categoryData['has_subcategories'] = false;
              }

              // Handle subcategories_count
              if (categoryData['subcategories_count'] == null) {
                categoryData['subcategories_count'] = 0;
              }

              return MartCategoryModel.fromJson(categoryData);
            } catch (e) {
              return null;
            }
          })
          .whereType<MartCategoryModel>()
          .toList();

      // Apply limit (since API might return more than our limit)
      final limitedResults = categories.take(limit).toList();

      print(
        '[MART API] ✅ Search completed, found ${limitedResults.length} matching categories for "$searchQuery"',
      );

      // Debug: Log the search results
      for (int i = 0; i < limitedResults.length; i++) {
        final category = limitedResults[i];
        final title = category.title ?? 'No Title';
        final description = category.description ?? 'No Description';
        final shortDescription = description.length > 50
            ? '${description.substring(0, 50)}...'
            : description;
        print('[MART API]   ${i + 1}. $title - $shortDescription');
      }

      return limitedResults;
    } catch (e) {
      print('[MART API] ❌ Error searching categories: $e');
      return [];
    }
  }

  //changed here

  /// Get mart vendors from API
  Future<List<MartVendorModel>> getMartVendors({String? search}) async {
    try {
      print('[MART API] 🏪 Fetching mart vendors from API...');
      final Map<String, String> queryParams = {};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      // Build URI
      final uri = Uri.parse(
        '${AppConst.baseUrl}mart-items/getMartVendors',
      ).replace(queryParameters: queryParams);

      // Make API request
      final response = await http.get(uri, headers: await getHeaders());

      print(
        '[MART API] 🏪 API request completed with status: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        print(
          '[MART API] ❌ API request failed with status: ${response.statusCode}',
        );
        return [];
      }

      // Parse response body
      final responseBody = json.decode(response.body);

      if (responseBody == null || responseBody['success'] != true) {
        print('[MART API] ⚠️ No vendors found in API response');
        return [];
      }

      final List<dynamic> vendorsData = responseBody['data'] ?? [];

      print('[MART API] 🏪 API returned ${vendorsData.length} vendors');

      if (vendorsData.isEmpty) {
        print('[MART API] ⚠️ No vendors found in API');
        return [];
      }

      // Convert API response to MartVendorModel
      final vendors = vendorsData
          .map((vendorData) {
            try {
              if (vendorData == null) {
                print('[MART API] ⚠️ Vendor data is null');
                return null;
              }

              // Ensure data is a Map<String, dynamic>
              if (vendorData is! Map<String, dynamic>) {
                print(
                  '[MART API] ⚠️ Vendor data is not a Map, type: ${vendorData.runtimeType}',
                );
                return null;
              }

              final Map<String, dynamic> vendorMap = Map<String, dynamic>.from(
                vendorData,
              );

              // Handle JSON string fields that need parsing
              _handleJsonStringFields(vendorMap);

              // Handle numeric and boolean fields
              _handleNumericAndBooleanFields(vendorMap);

              return MartVendorModel.fromJson(vendorMap);
            } catch (e) {
              print('[MART API] ❌ Error parsing API vendor data: $e');
              return null;
            }
          })
          .whereType<MartVendorModel>()
          .toList();

      print(
        '[MART API] ✅ Successfully parsed ${vendors.length} vendors from API',
      );

      return vendors;
    } catch (e) {
      print('[MART API] ❌ Error fetching vendors from API: $e');
      return [];
    }
  }

  /// Helper method to handle JSON string fields
  void _handleJsonStringFields(Map<String, dynamic> vendorData) {
    final jsonStringFields = [
      'photos',
      'workingHours',
      'categoryID',
      'categoryTitle',
      'filters',
      'adminCommission',
      'specialDiscount',
      'coordinates',
      'g',
    ];

    for (final field in jsonStringFields) {
      if (vendorData[field] is String) {
        try {
          final parsed = json.decode(vendorData[field]);
          vendorData[field] = parsed;
        } catch (e) {
          print('[MART API] ⚠️ Failed to parse JSON field $field: $e');
          // Set to appropriate default based on field type
          if (field == 'photos' ||
              field == 'categoryID' ||
              field == 'categoryTitle') {
            vendorData[field] = [];
          } else if (field == 'workingHours' || field == 'specialDiscount') {
            vendorData[field] = [];
          } else if (field == 'filters' ||
              field == 'adminCommission' ||
              field == 'coordinates' ||
              field == 'g') {
            vendorData[field] = {};
          }
        }
      } else if (vendorData[field] == null) {
        // Set appropriate defaults for null fields
        if (field == 'photos' ||
            field == 'categoryID' ||
            field == 'categoryTitle') {
          vendorData[field] = [];
        } else if (field == 'workingHours' || field == 'specialDiscount') {
          vendorData[field] = [];
        } else if (field == 'filters' ||
            field == 'adminCommission' ||
            field == 'coordinates' ||
            field == 'g') {
          vendorData[field] = {};
        }
      }
    }
  }

  /// Helper method to handle numeric and boolean fields
  void _handleNumericAndBooleanFields(Map<String, dynamic> vendorData) {
    // Handle numeric fields
    final numericFields = [
      'specialDiscountEnable',
      'latitude',
      'longitude',
      'DeliveryCharge',
      'restaurantCost',
      'hidephotos',
      'reststatus',
      'isOpen',
      'publish',
      'enabledDelivery',
      'enabledDiveInFuture',
      'dine_in_active',
      'isSelfDelivery',
    ];

    for (final field in numericFields) {
      if (vendorData[field] is String) {
        if (field == 'latitude' ||
            field == 'longitude' ||
            field == 'DeliveryCharge' ||
            field == 'restaurantCost') {
          vendorData[field] = double.tryParse(vendorData[field]) ?? 0.0;
        } else {
          vendorData[field] = int.tryParse(vendorData[field]) ?? 0;
        }
      }
    }

    // Handle boolean-like fields (0/1 or true/false)
    final boolFields = [
      'specialDiscountEnable',
      'hidephotos',
      'reststatus',
      'isOpen',
      'publish',
      'enabledDelivery',
      'enabledDiveInFuture',
      'dine_in_active',
      'isSelfDelivery',
    ];

    for (final field in boolFields) {
      if (vendorData[field] is String) {
        final value = vendorData[field].toLowerCase();
        vendorData[field] = value == 'true' || value == '1';
      } else if (vendorData[field] is int) {
        vendorData[field] = vendorData[field] == 1;
      }
    }

    // Handle review counts
    if (vendorData['reviewsCount'] is String) {
      vendorData['reviewsCount'] =
          int.tryParse(vendorData['reviewsCount']) ?? 0;
    }

    // Handle review sums
    if (vendorData['reviewsSum'] is String) {
      vendorData['reviewsSum'] =
          double.tryParse(vendorData['reviewsSum']) ?? 0.0;
    }
  }

  /// Get published categories from Firestoresdf
  ///
  /// sdf
  Future<List<MartCategoryModel>> getFeaturedCategories({
    String? martId,
  }) async {
    try {
      print('[MART API] ⭐ Fetching featured categories from API...');
      // Build the API URL
      String url = '${AppConst.baseUrl}mart-items/getFeaturedCategories';
      if (martId != null && martId.isNotEmpty) {
        url += '?martId=$martId';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: await getHeaders(),
      );
      if (response.statusCode != 200) {
        print('[MART API] ❌ HTTP error: ${response.statusCode}');
        return [];
      }
      final responseData = json.decode(response.body);
      final isSuccess = responseData['success'] == true ||
          responseData['status'] == true;
      if (!isSuccess) {
        print('[MART API] ❌ API returned error');
        return [];
      }
      print(
        '[MART API] ⭐ API call completed, found ${responseData['count']} featured categories',
      );
      if (responseData['data'] == null || responseData['data'].isEmpty) {
        print('[MART API] ⚠️ No featured categories found');
        return [];
      }
      // Convert API response to MartCategoryModel
      final categories = (responseData['data'] as List)
          .map((item) {
            try {
              if (item == null) return null;

              final Map<String, dynamic> categoryData =
                  Map<String, dynamic>.from(item);

              // Handle array fields that might be strings
              if (categoryData['review_attributes'] is String) {
                try {
                  categoryData['review_attributes'] = json.decode(
                    categoryData['review_attributes'],
                  );
                } catch (e) {
                  categoryData['review_attributes'] = [];
                }
              } else if (categoryData['review_attributes'] == null) {
                categoryData['review_attributes'] = [];
              }

              // Handle numeric fields that might be strings
              if (categoryData['category_order'] is String) {
                categoryData['category_order'] =
                    int.tryParse(categoryData['category_order']) ?? 0;
              }
              if (categoryData['section_order'] is String) {
                categoryData['section_order'] =
                    int.tryParse(categoryData['section_order']) ?? 0;
              }

              // Handle boolean fields that might be null
              if (categoryData['show_in_homepage'] == null) {
                categoryData['show_in_homepage'] = false;
              }
              if (categoryData['publish'] == null) {
                categoryData['publish'] = true;
              }
              if (categoryData['has_subcategories'] == null) {
                categoryData['has_subcategories'] = false;
              }
              // Handle subcategories_count
              if (categoryData['subcategories_count'] == null) {
                categoryData['subcategories_count'] = 0;
              }

              return MartCategoryModel.fromJson(categoryData);
            } catch (e) {
              return null;
            }
          })
          .whereType<MartCategoryModel>()
          .toList();

      // Sort categories by category_order
      categories.sort(
        (a, b) => (a.categoryOrder ?? 0).compareTo(b.categoryOrder ?? 0),
      );
      print(
        '[MART API] ✅ Successfully parsed ${categories.length} featured categories from API',
      );
      return categories;
    } catch (e) {
      print('[MART API] ❌ Error fetching featured categories from API: $e');
      return [];
    }
  }

  /// Get items by vendor from API
  Future<List<MartItemModel>> getItemsByVendor({
    required String vendorId,
    String? categoryId,
    bool? isAvailable,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('[MART API] 🏪 Fetching items for vendor: $vendorId');

      // Build query parameters
      final Map<String, String> queryParams = {'vendorId': vendorId};

      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['categoryId'] = categoryId;
      }

      if (isAvailable != null) {
        queryParams['isAvailable'] = isAvailable.toString();
      }

      // Build URI
      final uri = Uri.parse(
        '${AppConst.baseUrl}mart-items/by-vendor',
      ).replace(queryParameters: queryParams);

      // Make API request
      final response = await http.get(uri, headers: await getHeaders());

      print(
        '[MART API] 🏪 API request completed with status: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        print(
          '[MART API] ❌ API request failed with status: ${response.statusCode}',
        );
        return [];
      }

      // Parse response body
      final responseBody = json.decode(response.body);
      final responseData = responseBody;

      if (responseData == null || responseData['status'] != true) {
        print('[MART API] ⚠️ No items found for vendor: $vendorId');
        return [];
      }

      final List<dynamic> itemsData = responseData['data'] ?? [];

      print('[MART API] 🏪 API returned ${itemsData.length} items for vendor');

      if (itemsData.isEmpty) {
        print('[MART API] ⚠️ No items found for vendor: $vendorId');
        return [];
      }

      // Convert API response to MartItemModel
      final items = itemsData
          .map((itemData) {
            try {
              if (itemData == null) return null;

              // Ensure data is a Map<String, dynamic>
              if (itemData is! Map<String, dynamic>) {
                print(
                  '[MART API] ⚠️ Item data is not a Map, type: ${itemData.runtimeType}',
                );
                return null;
              }

              final Map<String, dynamic> itemMap = Map<String, dynamic>.from(
                itemData,
              );

              // Handle array fields that might be strings or null
              _handleArrayFields(itemMap);

              // Handle numeric fields that might be strings
              _handleNumericFields(itemMap);

              return MartItemModel.fromJson(itemMap);
            } catch (e) {
              print('[MART API] ❌ Error parsing API item data: $e');
              return null;
            }
          })
          .whereType<MartItemModel>()
          .toList();

      print(
        '[MART API] ✅ Successfully parsed ${items.length} items for vendor from API',
      );
      return items;
    } catch (e) {
      print('[MART API] ❌ Error fetching items by vendor from API: $e');
      return [];
    }
  }

  /// Helper method to handle array fields
  void _handleArrayFields(Map<String, dynamic> itemData) {
    final arrayFields = [
      'addOnsPrice',
      'addOnsTitle',
      'options',
      'photos',
      'review_attributes',
      'subcategoryID',
    ];

    for (final field in arrayFields) {
      if (itemData[field] == null) {
        itemData[field] = [];
      } else if (itemData[field] is String) {
        // Try to parse JSON string to list
        try {
          final parsed = json.decode(itemData[field]);
          if (parsed is List) {
            itemData[field] = parsed;
          } else {
            itemData[field] = [];
          }
        } catch (e) {
          itemData[field] = [];
        }
      }
    }
  }

  /// Helper method to handle numeric fields
  void _handleNumericFields(Map<String, dynamic> itemData) {
    // Handle reviewCount
    if (itemData['reviewCount'] is String) {
      itemData['reviewCount'] = int.tryParse(itemData['reviewCount']) ?? 0;
    }

    // Handle reviewSum - this might be a double based on your API response
    if (itemData['reviewSum'] is String) {
      itemData['reviewSum'] = double.tryParse(itemData['reviewSum']) ?? 0.0;
    }

    // Handle price fields
    final priceFields = ['price', 'disPrice'];
    for (final field in priceFields) {
      if (itemData[field] is String) {
        itemData[field] = double.tryParse(itemData[field]) ?? 0.0;
      }
    }

    // Handle other numeric fields
    final numericFields = ['quantity', 'calories', 'grams', 'proteins', 'fats'];
    for (final field in numericFields) {
      if (itemData[field] is String) {
        itemData[field] = int.tryParse(itemData[field]) ?? 0;
      }
    }

    // Handle boolean fields that might be strings
    final boolFields = [
      'publish',
      'isAvailable',
      'nonveg',
      'veg',
      'takeawayOption',
      'isStealOfMoment',
      'isTrending',
      'isSeasonal',
      'has_options',
      'options_toggle',
      'options_enabled',
      'isBestSeller',
      'isNew',
      'isSpotlight',
      'isFeature',
    ];

    for (final field in boolFields) {
      if (itemData[field] is String) {
        final value = itemData[field].toLowerCase();
        itemData[field] = value == 'true' || value == '1';
      }
    }
  }

  Future<List<MartItemModel>> getItemsByCategoryOnly({
    required String categoryId,
    bool? isAvailable,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('[MART API] 📂 Fetching items for category: $categoryId');

      // Build query parameters
      final Map<String, String> queryParams = {'categoryId': categoryId};

      if (isAvailable != null) {
        queryParams['isAvailable'] = isAvailable.toString();
      }

      // Build URI
      final uri = Uri.parse(
        '${AppConst.baseUrl}mart-items/by-category-only',
      ).replace(queryParameters: queryParams);

      // Make API request
      final response = await http.get(uri, headers: await getHeaders());

      print(
        '[MART API] 📂 API request completed with status: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        print(
          '[MART API] ❌ API request failed with status: ${response.statusCode}',
        );
        return [];
      }
      // Parse response body
      final responseBody = json.decode(response.body);
      if (responseBody == null || responseBody['status'] != true) {
        print('[MART API] ⚠️ No items found for category: $categoryId');
        return [];
      }
      final List<dynamic> itemsData = responseBody['data'] ?? [];
      print(
        '[MART API] 📂 API returned ${itemsData.length} items for category',
      );
      if (itemsData.isEmpty) {
        print('[MART API] ⚠️ No items found for category: $categoryId');
        return [];
      }

      // Convert API response to MartItemModel
      final items = itemsData
          .map((itemData) {
            try {
              if (itemData == null) return null;

              // Ensure data is a Map<String, dynamic>
              if (itemData is! Map<String, dynamic>) {
                print(
                  '[MART API] ⚠️ Item data is not a Map, type: ${itemData.runtimeType}',
                );
                return null;
              }

              final Map<String, dynamic> itemMap = Map<String, dynamic>.from(
                itemData,
              );

              // Handle array fields that might be strings or null
              _handleArrayFields(itemMap);

              // Handle numeric fields that might be strings
              _handleNumericFields(itemMap);

              // Handle boolean fields
              _handleBooleanFields(itemMap);

              return MartItemModel.fromJson(itemMap);
            } catch (e) {
              print('[MART API] ❌ Error parsing API item data: $e');
              return null;
            }
          })
          .whereType<MartItemModel>()
          .toList();

      print(
        '[MART API] ✅ Successfully parsed ${items.length} items for category from API',
      );

      return items;
    } catch (e) {
      print('[MART API] ❌ Error fetching items by category only from API: $e');
      return [];
    }
  }

  /// Helper method to handle array fields

  /// Helper method to handle numeric fields

  /// Helper method to handle boolean fields
  void _handleBooleanFields(Map<String, dynamic> itemData) {
    final boolFields = [
      'publish',
      'isAvailable',
      'nonveg',
      'veg',
      'takeawayOption',
      'isStealOfMoment',
      'isTrending',
      'isSeasonal',
      'has_options',
      'options_toggle',
      'options_enabled',
      'isBestSeller',
      'isNew',
      'isSpotlight',
      'isFeature',
    ];

    for (final field in boolFields) {
      if (itemData[field] is String) {
        final value = itemData[field].toLowerCase();
        itemData[field] = value == 'true' || value == '1';
      } else if (itemData[field] is int) {
        itemData[field] = itemData[field] == 1;
      }
    }
  }

  /// Get unique sections from mart_items collection (optimized for speed)
  Future<List<String>> getUniqueSections() async {
    try {
      print('[MART API] 📂 Fetching unique sections from API...');

      final response = await http
          .get(
            Uri.parse('${AppConst.baseUrl}mart-items/sections'),
            headers: await getHeaders(),
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('[MART API] ⏰ Sections API timeout');
              throw TimeoutException(
                'Sections API timeout',
                const Duration(seconds: 5),
              );
            },
          );

      print(
        '[MART API] 📂 API call completed with status: ${response.statusCode}',
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == true) {
          final List<dynamic> sectionsData = responseData['data'];
          final sections = sectionsData.cast<String>().toList()..sort();

          print(
            '[MART API] ✅ Found ${sections.length} unique sections: $sections',
          );
          for (int i = 0; i < sections.length; i++) {
            print('[MART API] 📂 Section ${i + 1}: "${sections[i]}"');
          }
          return sections;
        } else {
          print(
            '[MART API] ⚠️ API returned false status: ${responseData['message']}',
          );
          return [];
        }
      } else {
        print('[MART API] ❌ API error: ${response.statusCode}');
        return [];
      }
    } on TimeoutException catch (e) {
      print('[MART API] ⏰ Timeout fetching sections: $e');
      return [];
    } catch (e) {
      print('[MART API] ❌ Error fetching unique sections: $e');
      return [];
    }
  }

  /// Get items by section from API
  Future<List<MartItemModel>> getItemsBySection({
    required String section,
  }) async {
    try {
      print('[MART API] 🛍️ Fetching items for section: $section');

      // Build query parameters
      final Map<String, String> queryParams = {'section': section};
      // Build URI
      final uri = Uri.parse(
        '${AppConst.baseUrl}mart-items/by-section',
      ).replace(queryParameters: queryParams);

      // Make API request
      final response = await http.get(uri, headers: await getHeaders());
      print(
        '[MART API] 🛍️ API request completed with status: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        print(
          '[MART API] ❌ API request failed with status: ${response.statusCode}',
        );
        return [];
      }
      // Parse response body
      final responseBody = json.decode(response.body);
      if (responseBody == null || responseBody['status'] != true) {
        print('[MART API] ⚠️ No items found for section: $section');
        return [];
      }

      final List<dynamic> itemsData = responseBody['data'] ?? [];
      print(
        '[MART API] 🛍️ API returned ${itemsData.length} items for section "$section"',
      );
      if (itemsData.isEmpty) {
        print('[MART API] ⚠️ No items found for section: $section');
        return [];
      }
      // Convert API response to MartItemModel
      final items = itemsData
          .map((itemData) {
            try {
              if (itemData == null) return null;

              // Ensure data is a Map<String, dynamic>
              if (itemData is! Map<String, dynamic>) {
                print(
                  '[MART API] ⚠️ Item data is not a Map, type: ${itemData.runtimeType}',
                );
                return null;
              }

              final Map<String, dynamic> itemMap = Map<String, dynamic>.from(
                itemData,
              );

              // Handle array fields that might be strings or null
              _handleArrayFields(itemMap);

              // Handle numeric fields that might be strings
              _handleNumericFields(itemMap);

              // Handle boolean fields
              _handleBooleanFields(itemMap);

              // Handle JSON string fields
              _handleJsonStringFields(itemMap);

              return MartItemModel.fromJson(itemMap);
            } catch (e) {
              print('[MART API] ❌ Error parsing API item data: $e');
              return null;
            }
          })
          .whereType<MartItemModel>()
          .toList();

      print(
        '[MART API] ✅ Successfully parsed ${items.length} items for section "$section"',
      );
      return items;
    } catch (e) {
      print('[MART API] ❌ Error fetching items by section: $e');
      return [];
    }
  }

  /// Helper method to handle numeric fields
  /// Helper method to handle boolean fields

  /// Helper method to handle JSON string fields
  /// Get all mart items from Firestore
  Future<List<MartItemModel>> getMartItems() async {
    try {
      print('[MART API] 🛍️ Fetching all mart items from API...');
      final response = await http
          .get(
            Uri.parse('${AppConst.baseUrl}mart-items/all'),
            headers: await getHeaders(),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('[MART API] ⏰ Mart items API timeout');
              throw TimeoutException(
                'Mart items API timeout',
                const Duration(seconds: 10),
              );
            },
          );
      print('getMartItems ');
      print(
        '[MART API] 🛍️ API call completed with status: ${response.statusCode}',
      );
      print('getMartItems: ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == true) {
          final List<dynamic> itemsData = responseData['data'];
          final int count = responseData['count'] ?? itemsData.length;

          print('[MART API] 🛍️ API returned $count items');

          if (itemsData.isEmpty) {
            print('[MART API] ⚠️ No items found in API response');
            return [];
          }

          // Convert API data to MartItemModel
          final items = itemsData
              .map((itemData) {
                try {
                  if (itemData == null) return null;

                  // Ensure data is a Map<String, dynamic>
                  if (itemData is! Map<String, dynamic>) {
                    print(
                      '[MART API] ⚠️ Item data is not a Map, type: ${itemData.runtimeType}',
                    );
                    return null;
                  }

                  final Map<String, dynamic> itemMap =
                      Map<String, dynamic>.from(itemData);

                  _parseJsonStringFields(itemMap);

                  // Handle numeric fields that might be strings
                  _convertNumericFields(itemMap);

                  // Handle array fields that might be null or strings
                  _initializeArrayFields(itemMap);

                  return MartItemModel.fromJson(itemMap);
                } catch (e) {
                  print(
                    '[MART API] ❌ Error parsing API item ${itemData['id']}: $e',
                  );
                  return null;
                }
              })
              .whereType<MartItemModel>()
              .toList();

          print(
            '[MART API] ✅ Successfully parsed ${items.length} mart items from API',
          );

          return items;
        } else {
          print(
            '[MART API] ⚠️ API returned false status: ${responseData['message']}',
          );
          return [];
        }
      } else {
        print('[MART API] ❌ API error: ${response.statusCode}');
        return [];
      }
    } on TimeoutException catch (e) {
      print('[MART API] ⏰ Timeout fetching mart items: $e');
      return [];
    } catch (e) {
      print('[MART API] ❌ Error fetching mart items from API: $e');
      return [];
    }
  }

  // Helper method to parse JSON string fields
  void _parseJsonStringFields(Map<String, dynamic> itemMap) {
    final jsonFields = [
      'addOnsTitle',
      'addOnsPrice',
      'options',
      'product_specification',
      'addOnesPrice',
    ];

    for (final field in jsonFields) {
      if (itemMap[field] is String) {
        try {
          final stringValue = itemMap[field] as String;
          if (stringValue.isNotEmpty) {
            itemMap[field] = json.decode(stringValue);
          } else {
            itemMap[field] = [];
          }
        } catch (e) {
          print('[MART API] ⚠️ Error parsing $field as JSON: $e');
          itemMap[field] = [];
        }
      }
    }
  }

  // Helper method to convert numeric fields
  void _convertNumericFields(Map<String, dynamic> itemMap) {
    final numericFields = [
      'price',
      'disPrice',
      'quantity',
      'calories',
      'grams',
      'proteins',
      'fats',
      'reviewCount',
      'reviewSum',
      'max_price',
      'min_price',
      'savings_percentage',
    ];

    for (final field in numericFields) {
      if (itemMap[field] is String) {
        final stringValue = itemMap[field] as String;
        if (stringValue.isNotEmpty) {
          if (field == 'price' ||
              field == 'disPrice' ||
              field == 'savings_percentage' ||
              field == 'max_price' ||
              field == 'min_price') {
            itemMap[field] = double.tryParse(stringValue) ?? 0.0;
          } else {
            itemMap[field] = int.tryParse(stringValue) ?? 0;
          }
        } else {
          itemMap[field] = 0;
        }
      } else if (itemMap[field] == null) {
        itemMap[field] = 0;
      }
    }
  }

  // Helper method to initialize array fields
  void _initializeArrayFields(Map<String, dynamic> itemMap) {
    final arrayFields = [
      'addOnsTitle',
      'addOnsPrice',
      'options',
      'photos',
      'review_attributes',
      'subcategoryID',
      'addOnesPrice',
    ];

    for (final field in arrayFields) {
      if (itemMap[field] == null) {
        itemMap[field] = [];
      }
    }
  }

  /// Get category by ID from Firestore

  /// Get mart vendor details from Firestore

  Future<MartItemModel?> getItemById(String itemId) async {
    try {
      print('[MART API] 🔍 Getting item by ID: $itemId');

      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}mart-items/getItemById?id=$itemId'),
        headers: await getHeaders(),
      );

      if (response.statusCode != 200) {
        print('[MART API] ❌ HTTP error: ${response.statusCode}');
        return null;
      }

      final responseData = json.decode(response.body);

      if (!responseData['status']) {
        print(
          '[MART API] ❌ API returned false status: ${responseData['message']}',
        );
        return null;
      }
      if (responseData['data'] == null || responseData['data'].isEmpty) {
        print('[MART API] ⚠️ Item not found: $itemId');
        return null;
      }
      print('[MART API] ✅ Found item: $itemId');
      final itemData = responseData['data'][0];
      // Convert the item data to proper format
      final Map<String, dynamic> processedData = Map<String, dynamic>.from(
        itemData,
      );
      // Ensure ID is set
      processedData['id'] = itemId;
      // Handle array fields that might be strings or null
      _processArrayField(processedData, 'addOnsPrice');
      _processArrayField(processedData, 'addOnsTitle');
      _processArrayField(processedData, 'options');
      _processArrayField(processedData, 'photos');
      _processArrayField(processedData, 'review_attributes');
      _processArrayField(processedData, 'subcategoryID');
      _processArrayField(processedData, 'variants');
      _processArrayField(processedData, 'attributes');
      _processArrayField(processedData, 'tags');
      _processArrayField(processedData, 'allergens');
      _processArrayField(processedData, 'nutritionalInfo');
      // Handle numeric fields that might be strings
      if (processedData['reviewCount'] is String) {
        processedData['reviewCount'] =
            int.tryParse(processedData['reviewCount']) ?? 0;
      }
      if (processedData['reviewSum'] is String) {
        processedData['reviewSum'] =
            double.tryParse(processedData['reviewSum']) ?? 0.0;
      }
      if (processedData['price'] is String) {
        processedData['price'] = double.tryParse(processedData['price']) ?? 0.0;
      }
      if (processedData['disPrice'] is String) {
        processedData['disPrice'] =
            double.tryParse(processedData['disPrice']) ?? 0.0;
      }
      // Handle stringified JSON fields
      _processJsonField(processedData, 'addOnsTitle');
      _processJsonField(processedData, 'addOnsPrice');
      _processJsonField(processedData, 'options');
      _processJsonField(processedData, 'product_specification');
      final item = MartItemModel.fromJson(processedData);
      print('[MART API] ✅ Successfully retrieved item: ${item.name}');

      return item;
    } catch (e) {
      print('[MART API] ❌ Error getting item by ID $itemId: $e');
      return null;
    }
  }

  // Helper function to process array fields
  void _processArrayField(Map<String, dynamic> data, String fieldName) {
    if (data[fieldName] == null) {
      data[fieldName] = [];
    } else if (data[fieldName] is String) {
      // Try to parse string as JSON array
      try {
        final parsed = json.decode(data[fieldName]);
        if (parsed is List) {
          data[fieldName] = parsed;
        } else {
          data[fieldName] = [];
        }
      } catch (e) {
        data[fieldName] = [];
      }
    }
  }

  // Helper function to process JSON string fields
  void _processJsonField(Map<String, dynamic> data, String fieldName) {
    if (data[fieldName] is String) {
      try {
        data[fieldName] = json.decode(data[fieldName]);
      } catch (e) {
        // If parsing fails, keep the original value or set to empty array
        if (fieldName == 'addOnsTitle' ||
            fieldName == 'addOnsPrice' ||
            fieldName == 'options') {
          data[fieldName] = [];
        } else if (fieldName == 'product_specification') {
          data[fieldName] = {};
        }
      }
    }
  }

  Stream<List<MartItemModel>> streamSimilarProducts({
    required String categoryId,
    String? subcategoryId,
    String? excludeProductId,
    bool? isAvailable,
    int limit = 6,
  }) {
    try {
      print(
        '[MART API] 📡 Starting stream for similar products - category: $categoryId',
      );
      if (subcategoryId != null) {
        print('[MART API] 📡 Subcategory filter: $subcategoryId');
      }
      if (excludeProductId != null) {
        print('[MART API] 📡 Excluding product: $excludeProductId');
      }
      // Build the API URL with query parameters
      final uri = Uri.parse('${AppConst.baseUrl}mart-items/by-category')
          .replace(
            queryParameters: {
              'categoryId': categoryId,
              if (subcategoryId != null && subcategoryId.isNotEmpty)
                'subcategoryId': subcategoryId,
              if (isAvailable != null) 'isAvailable': isAvailable.toString(),
              'limit': (limit + (excludeProductId != null ? 1 : 0)).toString(),
            },
          );

      print('[MART API] 📡 API URL: $uri');

      // Since we can't create a true real-time stream with HTTP API,
      // we'll use a periodic stream that polls the API at intervals
      return Stream.periodic(const Duration(seconds: 30), (_) async {
        try {
          final response = await http
              .get(uri, headers: await getHeaders())
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  print('[MART API] ⏰ Similar products API timeout');
                  throw TimeoutException('Similar products API timeout');
                },
              );

          print(
            '[MART API] 📡 API call completed with status: ${response.statusCode}',
          );

          if (response.statusCode == 200) {
            final Map<String, dynamic> responseData = json.decode(
              response.body,
            );

            if (responseData['status'] == true) {
              final List<dynamic> itemsData = responseData['data'];
              final int count = responseData['count'] ?? itemsData.length;

              print('[MART API] 📡 API returned $count items');

              if (itemsData.isEmpty) {
                print(
                  '[MART API] ⚠️ No items found in API response for category: $categoryId',
                );
                return <MartItemModel>[];
              }

              // Convert API data to MartItemModel
              final items = itemsData
                  .map((itemData) {
                    try {
                      if (itemData is! Map<String, dynamic>) {
                        print(
                          '[MART API] ⚠️ Item data is not a Map, type: ${itemData.runtimeType}',
                        );
                        return null;
                      }

                      final Map<String, dynamic> itemMap =
                          Map<String, dynamic>.from(itemData);

                      // Pre-process data before model creation
                      _preprocessItemData(itemMap);

                      return MartItemModel.fromJson(itemMap);
                    } catch (e) {
                      print(
                        '[MART API] ❌ Error parsing API item ${itemData['id']}: $e',
                      );
                      return null;
                    }
                  })
                  .whereType<MartItemModel>()
                  .toList();

              // Exclude the current product if specified
              List<MartItemModel> filteredItems = items;
              if (excludeProductId != null) {
                filteredItems = items
                    .where((item) => item.id != excludeProductId)
                    .toList();
              }

              // Limit to requested amount
              final finalItems = filteredItems.take(limit).toList();

              print(
                '[MART API] 📡 Stream returning ${finalItems.length} similar products',
              );
              return finalItems;
            } else {
              print(
                '[MART API] ⚠️ API returned false status: ${responseData['message']}',
              );
              return <MartItemModel>[];
            }
          } else {
            print('[MART API] ❌ API error: ${response.statusCode}');
            return <MartItemModel>[];
          }
        } on TimeoutException catch (e) {
          print('[MART API] ⏰ Timeout in stream for similar products: $e');
          return <MartItemModel>[];
        } catch (e) {
          print('[MART API] ❌ Error in stream for similar products: $e');
          return <MartItemModel>[];
        }
      }).asyncMap((event) => event).handleError((error) {
        print('[MART API] ❌ Stream error for similar products: $error');
        return <MartItemModel>[];
      });
    } catch (e) {
      print('[MART API] ❌ Error creating stream for similar products: $e');
      return Stream.value(<MartItemModel>[]);
    }
  }

  // Helper method to preprocess item data
  void _preprocessItemData(Map<String, dynamic> itemMap) {
    // Handle numeric fields that might be strings
    final numericFields = [
      'reviewCount',
      'reviewSum',
      'price',
      'disPrice',
      'calories',
      'proteins',
      'fats',
      'grams',
      'max_price',
      'min_price',
      'savings_percentage',
    ];

    for (final field in numericFields) {
      if (itemMap[field] is String) {
        final stringValue = itemMap[field] as String;
        if (stringValue.isNotEmpty) {
          if (field == 'price' ||
              field == 'disPrice' ||
              field == 'savings_percentage' ||
              field == 'max_price' ||
              field == 'min_price') {
            itemMap[field] = double.tryParse(stringValue) ?? 0.0;
          } else {
            itemMap[field] = int.tryParse(stringValue) ?? 0;
          }
        } else {
          itemMap[field] = 0;
        }
      } else if (itemMap[field] == null) {
        itemMap[field] = 0;
      }
    }

    // Handle JSON string fields
    final jsonFields = [
      'addOnsTitle',
      'addOnsPrice',
      'options',
      'product_specification',
      'addOnesPrice',
    ];

    for (final field in jsonFields) {
      if (itemMap[field] is String) {
        try {
          final stringValue = itemMap[field] as String;
          if (stringValue.isNotEmpty) {
            itemMap[field] = json.decode(stringValue);
          } else {
            itemMap[field] = [];
          }
        } catch (e) {
          print('[MART API] ⚠️ Error parsing $field as JSON: $e');
          itemMap[field] = [];
        }
      }
    }
  }

  /// Stream all products from API
  Stream<List<MartItemModel>> streamAllProducts({
    String? excludeProductId,
    bool? isAvailable,
    int limit = 10,
  }) {
    try {
      print('[MART API] 📡 Starting stream for all products');
      if (excludeProductId != null) {
        print('[MART API] 📡 Excluding product: $excludeProductId');
      }
      if (isAvailable != null) {
        print('[MART API] 📡 Filtering by isAvailable: $isAvailable');
      }
      print('[MART API] 📡 Limit: $limit');

      // Helper function to fetch and filter products
      Future<List<MartItemModel>> fetchAndFilter() async {
        try {
          print('[MART API] 📡 Fetching products...');
          final allItems = await getMartItems();
          
          // Apply filters
          List<MartItemModel> filteredItems = allItems;

          // Filter by isAvailable if specified
          if (isAvailable != null) {
            filteredItems = filteredItems
                .where((item) => item.isAvailable == isAvailable)
                .toList();
          }

          // Exclude specific product if specified
          if (excludeProductId != null) {
            filteredItems = filteredItems
                .where((item) => item.id != excludeProductId)
                .toList();
          }

          // Apply limit
          if (limit > 0 && filteredItems.length > limit) {
            filteredItems = filteredItems.take(limit).toList();
          }

          print(
            '[MART API] 📡 Filtered to ${filteredItems.length} products (from ${allItems.length} total)',
          );
          return filteredItems;
        } catch (e) {
          print('[MART API] ❌ Error fetching products in stream: $e');
          return <MartItemModel>[];
        }
      }

      // Create a stream controller
      final StreamController<List<MartItemModel>> controller =
          StreamController<List<MartItemModel>>.broadcast();

      // Emit immediately from Future
      fetchAndFilter().then((items) {
        if (!controller.isClosed) {
          print('[MART API] 📡 Emitting ${items.length} products immediately');
          controller.add(items);
        }
      }).catchError((error) {
        print('[MART API] ❌ Error in immediate fetch: $error');
        if (!controller.isClosed) {
          controller.add(<MartItemModel>[]);
        }
      });

      // Then emit periodically every 30 seconds
      Timer? periodicTimer;
      periodicTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) {
          if (controller.isClosed) {
            periodicTimer?.cancel();
            return;
          }
          fetchAndFilter().then((items) {
            if (!controller.isClosed) {
              print('[MART API] 📡 Periodic update: Emitting ${items.length} products');
              controller.add(items);
            }
          }).catchError((error) {
            print('[MART API] ❌ Error in periodic fetch: $error');
          });
        },
      );

      // Clean up when stream is cancelled
      controller.onCancel = () {
        periodicTimer?.cancel();
      };

      return controller.stream;
    } catch (e) {
      print('[MART API] ❌ Error creating stream for all products: $e');
      return Stream.value(<MartItemModel>[]);
    }
  }

  // ==================== BANNER METHODS ====================
  /// Stream all published banners
  /// Stream items by brand ID

  Stream<List<MartItemModel>> streamItemsByBrand(String brandID) {
    final StreamController<List<MartItemModel>> _controller =
        StreamController<List<MartItemModel>>.broadcast();

    // Initial fetch
    _fetchItemsByBrand(_controller, brandID);

    // Optional: Set up periodic refreshes if needed
    final timer = Timer.periodic(Duration(seconds: 30), (timer) {
      _fetchItemsByBrand(_controller, brandID);
    });

    // Clean up when stream is closed
    _controller.onCancel = () {
      timer.cancel();
      _controller.close();
    };

    return _controller.stream;
  }

  void _fetchItemsByBrand(
    StreamController<List<MartItemModel>> controller,
    String brandID,
  ) async {
    try {
      print('[MART API] 🔍 Fetching items for brand: $brandID');
      final response = await http
          .get(
            Uri.parse(
              '${AppConst.baseUrl}mart-items/by-brand?brandId=$brandID',
            ),
            headers: await getHeaders(),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == true && data['data'] is List) {
          final List<dynamic> itemsData = data['data'];
          final items = <MartItemModel>[];

          print(
            '[MART API] 📦 Brand items received with ${itemsData.length} documents',
          );

          for (var itemData in itemsData) {
            try {
              // Convert to Map and ensure it's mutable
              final Map<String, dynamic> itemMap = Map<String, dynamic>.from(
                itemData,
              );

              // Filter items based on publish and isAvailable (matching Firebase query)
              final bool isAvailable = itemMap['isAvailable'] == true;
              final bool isPublished = itemMap['publish'] == true;

              if (!isAvailable || !isPublished) {
                print(
                  '[MART API] ⏭️ Skipping item ${itemMap['id']} - not available or not published',
                );
                continue;
              }

              // Handle array fields that might be strings or null
              _processArrayField(itemMap, 'addOnsPrice');
              _processArrayField(itemMap, 'addOnsTitle');
              _processArrayField(itemMap, 'options');
              _processArrayField(itemMap, 'photos');
              _processArrayField(itemMap, 'review_attributes');
              _processArrayField(itemMap, 'subcategoryID');

              // Handle numeric fields that might be strings
              if (itemMap['reviewCount'] is String) {
                itemMap['reviewCount'] =
                    int.tryParse(itemMap['reviewCount']) ?? 0;
              }
              if (itemMap['reviewSum'] is String) {
                itemMap['reviewSum'] =
                    double.tryParse(itemMap['reviewSum']) ?? 0.0;
              }
              if (itemMap['price'] is String) {
                itemMap['price'] = double.tryParse(itemMap['price']) ?? 0.0;
              }
              if (itemMap['disPrice'] is String) {
                itemMap['disPrice'] =
                    double.tryParse(itemMap['disPrice']) ?? 0.0;
              }
              if (itemMap['quantity'] is String) {
                itemMap['quantity'] = int.tryParse(itemMap['quantity']) ?? 0;
              }

              // Handle JSON string fields
              _processJsonField(itemMap, 'product_specification');
              _processJsonField(itemMap, 'item_attribute');

              final item = MartItemModel.fromJson(itemMap);
              items.add(item);
              print('[MART API] ✅ Added brand item: ${item.name}');
            } catch (e) {
              print(
                '[MART API] ❌ Error parsing brand item ${itemData['id']}: $e',
              );
            }
          }

          print(
            '[MART API] 📦 Returning ${items.length} items for brand: $brandID',
          );
          controller.add(items);
        } else {
          print('[MART API] ❌ API returned error: ${data['message']}');
          controller.add([]);
        }
      } else {
        print('[MART API] ❌ HTTP error: ${response.statusCode}');
        controller.add([]);
      }
    } catch (e) {
      print('[MART API] ❌ Error fetching items by brand: $e');
      controller.add([]);
    }
  }

  Future<Map<String, dynamic>> getHomepageSubcategoriesPaginated({
    int limit = 10,
    int page = 1,
  }) async {
    try {
      // Build the API URL with query parameters
      final url = Uri.parse('${AppConst.baseUrl}mart-items/sub_category_home')
          .replace(
            queryParameters: {
              'limit': limit.toString(),
              'page': page.toString(),
            },
          );

      // Make the API call
      final response = await http.get(url, headers: await getHeaders());

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == true) {
          // Convert the API data to MartSubcategoryModel objects
          final subcategories = (responseData['data'] as List).map((item) {
            return MartSubcategoryModel.fromJson(item);
          }).toList();

          // Get meta information for pagination
          final meta = responseData['meta'] as Map<String, dynamic>;
          final currentPage = meta['page'] as int;
          final totalItems = meta['total'] as int;
          final lastPage = meta['last_page'] as int;

          return {
            'subcategories': subcategories,
            'currentPage': currentPage,
            'totalItems': totalItems,
            'hasNextPage': currentPage < lastPage,
            'lastPage': lastPage,
          };
        } else {
          throw Exception(
            'API returned false status: ${responseData['message']}',
          );
        }
      } else {
        throw Exception(
          'HTTP error ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('[API] ❌ Paginated query error: $e');
      return {
        'subcategories': [],
        'currentPage': 1,
        'totalItems': 0,
        'hasNextPage': false,
        'lastPage': 1,
      };
    }
  }
}
