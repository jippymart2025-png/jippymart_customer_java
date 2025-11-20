import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/app/mart/provider/category_details_provider.dart';
import 'package:jippymart_customer/models/mart_subcategory_model.dart';
import 'package:jippymart_customer/models/mart_item_model.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/app/mart/widgets/mart_product_card.dart';
import 'package:jippymart_customer/themes/mart_theme.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/color_const.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:provider/provider.dart';

class MartCategoryDetailScreen extends StatelessWidget {
  const MartCategoryDetailScreen({super.key});

  // Get appropriate icon for the subcategory
  IconData _getCategoryIcon(String categoryTitle) {
    final title = categoryTitle.toLowerCase();

    if (title.contains('veggie') || title.contains('vegetable')) {
      return Icons.eco;
    } else if (title.contains('spice')) {
      return Icons.local_dining;
    } else if (title.contains('oil')) {
      return Icons.opacity;
    } else if (title.contains('dal') || title.contains('pulse')) {
      return Icons.grain;
    } else if (title.contains('rice')) {
      return Icons.grain;
    } else if (title.contains('atta') || title.contains('flour')) {
      return Icons.grain;
    } else if (title.contains('fruit')) {
      return Icons.apple;
    } else if (title.contains('milk') || title.contains('dairy')) {
      return Icons.local_drink;
    } else if (title.contains('bread') || title.contains('bakery')) {
      return Icons.local_dining;
    } else {
      return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryDetailsProvider>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: ColorConst.white,
          body: Column(
            children: [
              _buildHeader(context, controller),
              _buildFilterChips(controller),
              Flexible(
                child: Row(
                  children: [
                    _buildCategorySidebar(controller),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: _buildProductContent(controller),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    CategoryDetailsProvider controller,
  ) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 2,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: ColorConst.martPrimary,
        // MartTheme.jippyMartButton, // Use jippyMartButton color
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row with back button, title, and search
          Row(
            children: [
              // Back button
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Text(
                  controller.categoryName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(CategoryDetailsProvider controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      // 🔑 Reduced from 8 to 4
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              controller,
              'All',
              Icons.all_inclusive,
              null,
              isDefault: true,
            ),
            const SizedBox(width: 6), // 🔑 Reduced from 8 to 6
            _buildFilterChip(
              controller,
              'Best Sellers',
              Icons.star,
              'best_sellers',
            ),
            const SizedBox(width: 6), // 🔑 Reduced from 8 to 6
            _buildFilterChip(
              controller,
              'Featured',
              Icons.featured_play_list,
              'featured',
            ),
            const SizedBox(width: 6), // 🔑 Reduced from 8 to 6
            _buildFilterChip(controller, 'New', Icons.new_releases, 'new'),
            const SizedBox(width: 8),
            _buildFilterChip(
              controller,
              'Trending',
              Icons.trending_up,
              'trending',
            ),
            const SizedBox(width: 8),

            _buildFilterChip(
              controller,
              'Seasonal',
              Icons.local_florist,
              'seasonal',
            ),

            const SizedBox(width: 8),

            // Spotlight filter
            _buildFilterChip(
              controller,
              'Spotlight',
              Icons.highlight,
              'spotlight',
            ),

            const SizedBox(width: 8),

            // Steal of moment filter
            _buildFilterChip(
              controller,
              'Steal Deal',
              Icons.local_offer,
              'steal_of_moment',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    CategoryDetailsProvider controller,
    String label,
    IconData icon,
    String? filterType, {
    bool isDefault = false,
  }) {
    final isSelected = controller.selectedFilter == filterType;
    return GestureDetector(
      onTap: () {
        controller.selectFilter(filterType);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? MartTheme.jippyMartButton : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? MartTheme.jippyMartButton : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySidebar(CategoryDetailsProvider controller) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: ColorConst.white, // Reusable home screen background
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: controller.isLoadingSubcategories
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF292966)),
              ),
            )
          : controller.subcategories.isEmpty
          ? const Center(
              child: Text(
                'No categories',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              // 🔑 Reduced from 8 to 4
              itemCount: controller.subcategories.length,
              itemBuilder: (context, index) {
                final category = controller.subcategories[index];
                final isSelected =
                    controller.selectedSubCategoryId == category.id;
                return _buildCategoryItem(category, isSelected, controller);
              },
            ),
    );
  }

  Widget _buildCategoryItem(
    MartSubcategoryModel category,
    bool isSelected,
    CategoryDetailsProvider controller,
  ) {
    return GestureDetector(
      onTap: () => controller.selectSubCategory(category.id ?? ''),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF1FBEA), // #f1fbea - top color
                    Color(0xFF00998A), // #00998a - bottom color (fixed hex)
                  ],
                  stops: [0.0, 1.0],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category icon
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF292966) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: _buildCategoryIcon(category, isSelected, controller),
              ),
            ),
            const SizedBox(height: 6),
            // Category name
            Text(
              category.title ?? 'Unknown Category',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(
    MartSubcategoryModel category,
    bool isSelected,
    CategoryDetailsProvider controller,
  ) {
    final validImageUrl = category.getValidImageUrlWithParentFallback(
      controller.parentCategoryImageUrl,
    );
    final hasValidPhoto = validImageUrl.isNotEmpty;

    print(
      '[CATEGORY DETAIL UI] 📸 Category: ${category.title}, ValidImageUrl: $validImageUrl, HasValidPhoto: $hasValidPhoto',
    );

    if (hasValidPhoto) {
      return NetworkImageWidget(
        imageUrl: validImageUrl,
        width: 45,
        height: 45,
        fit: BoxFit.cover,
        errorWidget: Icon(
          _getCategoryIcon(category.title ?? ''),
          color: isSelected ? Colors.white : const Color(0xFF292966),
          size: 22,
        ),
      );
    } else {
      return Icon(
        _getCategoryIcon(category.title ?? ''),
        color: isSelected ? Colors.white : const Color(0xFF292966),
        size: 22,
      );
    }
  }

  Widget _buildProductContent(CategoryDetailsProvider controller) {
    if (controller.isLoadingProducts) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF292966)),
        ),
      );
    }
    if (controller.errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF292966),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: controller.testFirestoreEndpoints,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Test Firestore'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _buildProductStream(controller),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading products: ${snapshot.error}',
                  style: TextStyle(fontSize: 16, color: Colors.red[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF292966)),
            ),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No products found',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try selecting a different category or filter',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isTablet = screenWidth > 600;
              final isLargePhone = screenWidth > 400;

              final crossAxisCount = isTablet ? 3 : 2;
              final spacing = isTablet ? 12.0 : (isLargePhone ? 8.0 : 4.0);
              final horizontalPadding = isTablet
                  ? 16.0
                  : (isLargePhone ? 8.0 : 4.0);

              // 🔑 Auto-adjustable layout using Wrap for truly flexible card heights
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  bottom:
                      MediaQuery.of(context).padding.bottom +
                      8, // 🔑 Reduced from 16 to 8
                  top: 4, // 🔑 Added small top padding instead of 0
                ),
                child: Wrap(
                  alignment: WrapAlignment.start,
                  // 🔑 Ensure products start from the left
                  crossAxisAlignment: WrapCrossAlignment.start,
                  // 🔑 Ensure products start from the top
                  runAlignment: WrapAlignment.start,
                  // 🔑 Ensure runs start from the top
                  spacing: spacing,
                  runSpacing: spacing,
                  children: products.map((productData) {
                    // Transform the data to match the expected format
                    final transformedData = Map<String, dynamic>.from(
                      productData,
                    );

                    // Handle array fields that might be null
                    if (transformedData['addOnsPrice'] == null)
                      transformedData['addOnsPrice'] = [];
                    if (transformedData['addOnsTitle'] == null)
                      transformedData['addOnsTitle'] = [];
                    if (transformedData['options'] == null)
                      transformedData['options'] = [];
                    if (transformedData['photos'] == null)
                      transformedData['photos'] = [];
                    // Updated: subcategoryID is now a string, not an array
                    if (transformedData['subcategoryID'] == null)
                      transformedData['subcategoryID'] = '';
                    if (transformedData['product_specification'] == null)
                      transformedData['product_specification'] = {};

                    // Handle numeric fields that might be strings (this fixes the rating issue)
                    if (transformedData['reviewCount'] is String) {
                      transformedData['reviewCount'] =
                          int.tryParse(transformedData['reviewCount']) ?? 0;
                    }
                    if (transformedData['reviewSum'] is String) {
                      transformedData['reviewSum'] =
                          double.tryParse(transformedData['reviewSum']) ?? 0.0;
                    }

                    // Handle other numeric fields that might be strings
                    if (transformedData['price'] is String) {
                      transformedData['price'] =
                          double.tryParse(transformedData['price']) ?? 0.0;
                    }
                    if (transformedData['disPrice'] is String) {
                      transformedData['disPrice'] =
                          double.tryParse(transformedData['disPrice']) ?? 0.0;
                    }
                    if (transformedData['quantity'] is String) {
                      transformedData['quantity'] =
                          int.tryParse(transformedData['quantity']) ?? 0;
                    }
                    if (transformedData['calories'] is String) {
                      transformedData['calories'] =
                          int.tryParse(transformedData['calories']) ?? 0;
                    }
                    if (transformedData['proteins'] is String) {
                      transformedData['proteins'] =
                          double.tryParse(transformedData['proteins']) ?? 0.0;
                    }
                    if (transformedData['fats'] is String) {
                      transformedData['fats'] =
                          double.tryParse(transformedData['fats']) ?? 0.0;
                    }
                    if (transformedData['grams'] is String) {
                      transformedData['grams'] =
                          double.tryParse(transformedData['grams']) ?? 0.0;
                    }
                    if (transformedData['options_count'] is String) {
                      transformedData['options_count'] =
                          int.tryParse(transformedData['options_count']) ?? 0;
                    }

                    // Handle boolean fields that might be null
                    if (transformedData['has_options'] == null)
                      transformedData['has_options'] = false;
                    if (transformedData['isAvailable'] == null)
                      transformedData['isAvailable'] = true;
                    if (transformedData['isBestSeller'] == null)
                      transformedData['isBestSeller'] = false;
                    if (transformedData['isFeature'] == null)
                      transformedData['isFeature'] = false;
                    if (transformedData['isNew'] == null)
                      transformedData['isNew'] = false;
                    if (transformedData['isSeasonal'] == null)
                      transformedData['isSeasonal'] = false;
                    if (transformedData['isSpotlight'] == null)
                      transformedData['isSpotlight'] = false;
                    if (transformedData['isStealOfMoment'] == null)
                      transformedData['isStealOfMoment'] = false;
                    if (transformedData['isTrending'] == null)
                      transformedData['isTrending'] = false;
                    if (transformedData['veg'] == null)
                      transformedData['veg'] = true;
                    if (transformedData['nonveg'] == null)
                      transformedData['nonveg'] = false;
                    if (transformedData['takeawayOption'] == null)
                      transformedData['takeawayOption'] = false;
                    if (transformedData['publish'] == null)
                      transformedData['publish'] = true;

                    final product = MartItemModel.fromJson(transformedData);

                    // Debug: Log rating information
                    print('[CATEGORY DETAIL] 📊 Product: ${product.name}');
                    print(
                      '[CATEGORY DETAIL] 📊 Review Count: ${product.reviewCount} (type: ${product.reviewCount.runtimeType})',
                    );
                    print(
                      '[CATEGORY DETAIL] 📊 Review Sum: ${product.reviewSum} (type: ${product.reviewSum.runtimeType})',
                    );
                    print(
                      '[CATEGORY DETAIL] 📊 Average Rating: ${product.averageRating}',
                    );
                    print(
                      '[CATEGORY DETAIL] 📊 Total Reviews: ${product.totalReviews}',
                    );

                    // Calculate card width based on screen size and crossAxisCount
                    final cardWidth =
                        (screenWidth -
                            horizontalPadding * 2 -
                            spacing * (crossAxisCount - 1)) /
                        crossAxisCount;

                    // Using MartProductCard with calculated width for proper sizing
                    return SizedBox(
                      width: cardWidth,
                      child: MartProductCard(
                        product: product,
                        screenWidth: screenWidth,
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _buildProductStream(
    CategoryDetailsProvider controller,
  ) async* {
    try {
      print('[PRODUCT STREAM] 🔍 Building API request with:');
      print('[PRODUCT STREAM]   - Category ID: ${controller.categoryId}');
      print(
        '[PRODUCT STREAM]   - Selected Subcategory: ${controller.selectedSubCategoryId}',
      );
      print('[PRODUCT STREAM]   - Filter: ${controller.selectedFilter}');
      print('[PRODUCT STREAM]   - Search: ${controller.searchQuery}');
      // Build query parameters based on filters
      final Map<String, String> queryParams = {};

      if (controller.categoryId == 'trending') {
        queryParams['isTrending'] = 'true';
        print('[PRODUCT STREAM] 🔥 Special case: Trending items');
      } else if (controller.categoryId == 'featured') {
        queryParams['isFeature'] = 'true';
        print('[PRODUCT STREAM] ⭐ Special case: Featured items');
      } else if (controller.categoryId.startsWith('section_') &&
          controller.sectionName.isNotEmpty) {
        queryParams['section'] = controller.sectionName;
        print('[PRODUCT STREAM] 📂 Section-based: ${controller.sectionName}');
      } else if (controller.categoryId.isNotEmpty) {
        queryParams['categoryID'] = controller.categoryId;
        print('[PRODUCT STREAM] 📂 Regular category: ${controller.categoryId}');
      }

      // Apply subcategory filter - only for regular categories
      if (controller.categoryId != 'trending' &&
          controller.categoryId != 'featured' &&
          !controller.categoryId.startsWith('section_') &&
          controller.selectedSubCategoryId.isNotEmpty &&
          controller.selectedSubCategoryId != controller.categoryId) {
        queryParams['subcategoryID'] = controller.selectedSubCategoryId;
        print(
          '[PRODUCT STREAM] 🏷️ Subcategory filter: ${controller.selectedSubCategoryId}',
        );
      }

      // Apply additional filters based on selectedFilter
      if (controller.selectedFilter.isNotEmpty) {
        switch (controller.selectedFilter) {
          case 'trending':
            if (controller.categoryId != 'trending') {
              queryParams['isTrending'] = 'true';
            }
            break;
          case 'featured':
            if (controller.categoryId != 'featured') {
              queryParams['isFeature'] = 'true';
            }
            break;
          case 'best_sellers':
            queryParams['isBestSeller'] = 'true';
            break;
          case 'new':
            queryParams['isNew'] = 'true';
            break;
          case 'on_sale':
            queryParams['on_sale'] = 'true';
            break;
        }
        print(
          '[PRODUCT STREAM] 🎯 Additional filter: ${controller.selectedFilter}',
        );
      }

      // Apply search filter if available
      if (controller.searchQuery.isNotEmpty) {
        queryParams['search'] = controller.searchQuery;
        print('[PRODUCT STREAM] 🔍 Search query: ${controller.searchQuery}');
      }

      // Always filter by publish = true
      queryParams['publish'] = 'true';

      // Build the URL with query parameters
      final Uri uri = Uri.parse(
        '${AppConst.baseUrl}mart-items/all',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      print('[PRODUCT STREAM] 🌐 Making API request to: ${uri.toString()}');

      // Make the API request
      final response = await http.get(uri, headers: await getHeaders());

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == true) {
          final List<dynamic> data = responseData['data'];
          final List<Map<String, dynamic>> products =
              List<Map<String, dynamic>>.from(data);

          print(
            '[PRODUCT STREAM] ✅ Successfully fetched ${products.length} products',
          );
          // Yield the products as a stream
          yield products;
        } else {
          print(
            '[PRODUCT STREAM] ❌ API returned error: ${responseData['message']}',
          );
          yield []; // Return empty list on error
        }
      } else {
        print('[PRODUCT STREAM] ❌ HTTP error: ${response.statusCode}');
        yield []; // Return empty list on HTTP error
      }
    } catch (e) {
      print('[PRODUCT STREAM] 💥 Exception: $e');
      yield []; // Return empty list on exception
    }
  }
}
