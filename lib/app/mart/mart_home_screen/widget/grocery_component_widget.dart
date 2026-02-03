import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
import 'package:jippymart_customer/app/mart/provider/category_details_provider.dart';
import 'package:jippymart_customer/app/mart/screens/mart_categorhy_details_screen/mart_category_detail_screen.dart';
import 'package:jippymart_customer/models/mart_category_model.dart';
import 'package:jippymart_customer/utils/utils/color_const.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

Widget groceryComponent(Size size) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Consumer<MartProvider>(
          builder: (context, controller, _) {
            if (controller.isCategoryLoading && controller.featuredCategories.isEmpty) {
              return _buildCategoryShimmer();
            }
            // Prioritize categories - show grid if we have data (error may be from other loader)
            if (controller.featuredCategories.isNotEmpty) {
              return _buildCategoriesGrid(context, controller, size);
            }
            if (controller.errorMessage.isNotEmpty) {
              return _buildErrorState(controller);
            }
            if (!controller.isHomepageCategoriesLoaded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                controller.loadHomepageCategoriesStreaming(limit: 24);
              });
            }
            return _buildEmptyState();
          },
        ),
      ],
    ),
  );
}

// Enhanced Shimmer Loading
Widget _buildCategoryShimmer() {
  return SizedBox(
    height: 140,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 70,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 50,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// Enhanced Error State - use minHeight and mainAxisSize to prevent overflow
Widget _buildErrorState(MartProvider controller) {
  return Container(
    constraints: const BoxConstraints(minHeight: 160),
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.red[50]!, Colors.orange[50]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.red.withOpacity(0.1)),
      boxShadow: [
        BoxShadow(
          color: Colors.red.withOpacity(0.05),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
          const SizedBox(height: 8),
          const Text(
            'Unable to load categories',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              controller.errorMessage = '';
              controller.loadHomepageCategoriesStreaming(limit: 24);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shadowColor: Colors.red.withOpacity(0.3),
            ),
            child: const Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ),
  );
}

// Enhanced Empty State
Widget _buildEmptyState() {
  return Container(
    height: 120,
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.grey[50]!, Colors.grey[100]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.withOpacity(0.1)),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.category_outlined, color: Colors.grey, size: 24),
          ),
          const SizedBox(height: 12),
          const Text(
            'No categories found',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    ),
  );
}

// Enhanced Categories Grid
Widget _buildCategoriesGrid(
  BuildContext context,
  MartProvider controller,
  Size size,
) {
  return SizedBox(
    height: 120,
    child: ListView.separated(
      padding: EdgeInsets.zero,
      scrollDirection: Axis.horizontal,
      itemCount: controller.featuredCategories.length,
      separatorBuilder: (context, index) => const SizedBox(width: 30),
      itemBuilder: (context, index) {
        final category = controller.featuredCategories[index];
        return _buildCategoryItem(context, category, index, size);
      },
    ),
  );
}

// Enhanced Category Item with Modern Design
Widget _buildCategoryItem(
  BuildContext context,
  MartCategoryModel category,
  int index,
  Size size,
) {
  final categoryData = _getCategoryData(category.title ?? '');
  return InkWell(
    onTap: () {
      context.read<CategoryDetailsProvider>().initFunction(
        categoryIds: category.id ?? '',
        categoryNames: category.title ?? 'Category',
      );
      Get.to(() => const MartCategoryDetailScreen());
    },
    borderRadius: BorderRadius.circular(20),
    child: SizedBox(
      width: size.width * 0.11,
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(20),
      //   color: Colors.white,
      //   boxShadow: [
      //     BoxShadow(
      //       color: categoryData['color']!.withOpacity(0.15),
      //       blurRadius: 20,
      //       offset: const Offset(0, 8),
      //     ),
      //     BoxShadow(
      //       color: Colors.black.withOpacity(0.05),
      //       blurRadius: 5,
      //       offset: const Offset(0, 2),
      //     ),
      //   ],
      //   border: Border.all(
      //     color: Colors.grey.withOpacity(0.1),
      //     width: 1,
      //   ),
      // ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container with Enhanced Design
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  categoryData['color']!,
                  _adjustColorBrightness(categoryData['color']!, -0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: categoryData['color']!.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 4,
                  offset: const Offset(-2, -2),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background Pattern
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Icon(
                    categoryData['icon'],
                    color: Colors.white.withOpacity(0.2),
                    size: 20,
                  ),
                ),
                // Main Icon
                Center(
                  child: Icon(
                    categoryData['icon'],
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Category Name
          SizedBox(
            // constraints: const BoxConstraints(maxWidth: 90),
            height: 40,
            child: Text(
              category.title ?? 'Category',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3748),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    ),
  );
}

// Helper function to adjust color brightness
Color _adjustColorBrightness(Color color, double factor) {
  final hsl = HSLColor.fromColor(color);
  final newLightness = (hsl.lightness + factor).clamp(0.0, 1.0);
  return hsl.withLightness(newLightness).toColor();
}

// Enhanced category data with better color schemes
Map<String, dynamic> _getCategoryData(String categoryTitle) {
  final title = categoryTitle.toLowerCase();

  final categoryMap = {
    'dairy': {'icon': Icons.local_drink_rounded, 'color': Color(0xFF4FC3F7)},
    'milk': {'icon': Icons.local_drink_rounded, 'color': Color(0xFF4FC3F7)},
    'bread': {'icon': Icons.bakery_dining_rounded, 'color': Color(0xFF8D6E63)},
    'bakery': {'icon': Icons.bakery_dining_rounded, 'color': Color(0xFF8D6E63)},
    'eggs': {'icon': Icons.egg_rounded, 'color': Color(0xFFFFD54F)},
    'meat': {'icon': Icons.set_meal_rounded, 'color': Color(0xFFE57373)},
    'fish': {'icon': Icons.dinner_dining_rounded, 'color': Color(0xFF64B5F6)},
    'vegetables': {'icon': Icons.grass_rounded, 'color': Color(0xFF81C784)},
    'fruits': {'icon': Icons.apple_rounded, 'color': Color(0xFFF06292)},
    'beverages': {'icon': Icons.local_cafe_rounded, 'color': Color(0xFFBA68C8)},
    'snacks': {'icon': Icons.cookie_rounded, 'color': Color(0xFFFFB74D)},
    'frozen': {'icon': Icons.ac_unit_rounded, 'color': Color(0xFF4DD0E1)},
    'organic': {'icon': Icons.eco_rounded, 'color': Color(0xFF66BB6A)},
    'pharmacy': {
      'icon': Icons.local_pharmacy_rounded,
      'color': Color(0xFFF44336),
    },
    'baby': {'icon': Icons.child_care_rounded, 'color': Color(0xFFCE93D8)},
    'pet': {'icon': Icons.pets_rounded, 'color': Color(0xFFA1887F)},
    'cleaning': {
      'icon': Icons.cleaning_services_rounded,
      'color': Color(0xFF90CAF9),
    },
    'personal care': {'icon': Icons.spa_rounded, 'color': Color(0xFF80CBC4)},
  };

  for (final key in categoryMap.keys) {
    if (title.contains(key)) {
      return categoryMap[key]!;
    }
  }

  // Default category data
  return {'icon': Icons.category_rounded, 'color': ColorConst.martPrimary};
}
