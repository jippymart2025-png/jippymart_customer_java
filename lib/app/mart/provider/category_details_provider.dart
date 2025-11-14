import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/models/mart_subcategory_model.dart';
import 'package:jippymart_customer/models/mart_item_model.dart';
import 'package:jippymart_customer/services/mart_firestore_service.dart';

class CategoryDetailsProvider extends ChangeNotifier {
  final MartFirestoreService _firestoreService =
      Get.find<MartFirestoreService>();

  // Category info
  late String categoryId;
  late String categoryName;
  late String sectionName; // For section-based navigation
  String parentCategoryImageUrl = '';

  // Observable data
  List<MartSubcategoryModel> subcategories = <MartSubcategoryModel>[];
  List<MartItemModel> products = <MartItemModel>[];
  String selectedSubCategoryId = '';
  bool isLoadingSubcategories = true;
  bool isLoadingProducts = false;
  String errorMessage = '';

  // Search and filter
  String searchQuery = '';
  String selectedFilter = '';
  late String initialSubcategoryId; // Add this field
  void initFunction() {
    final arguments = Get.arguments as Map<String, dynamic>?;
    categoryId = arguments?['categoryId'] ?? '';
    categoryName = arguments?['categoryName'] ?? 'Category';
    sectionName = arguments?['sectionName'] ?? '';
    initialSubcategoryId = arguments?['subcategoryId'] ?? ''; // ✅ ADD THIS
    print(
      '[CATEGORY DETAIL] 🚀 Initializing for category: $categoryName (ID: $categoryId)',
    );
    print('[CATEGORY DETAIL] 🎯 Initial subcategory: $initialSubcategoryId');
    _initializeData();
    if (arguments?['initialFilter'] == 'trending' ||
        arguments?['initialFilter'] == 'featured') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        selectFilter(arguments?['initialFilter']);
      });
    }
    notifyListeners();
  }

  Future<void> _initializeData() async {
    await loadParentCategoryImage();
    await loadSubcategories();
  }

  Future<void> loadParentCategoryImage() async {
    try {
      print(
        '[CATEGORY DETAIL] 📸 Loading parent category image for: $categoryId',
      );

      // Special case for trending category - use default image
      if (categoryId == 'trending') {
        print(
          '[CATEGORY DETAIL] 🔥 Special case: Using default image for trending',
        );
        parentCategoryImageUrl =
            'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=300&h=300&fit=crop';
        return;
      }

      if (categoryId == 'featured') {
        print(
          '[CATEGORY DETAIL] ⭐ Special case: Using default image for featured',
        );
        parentCategoryImageUrl =
            'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=300&h=300&fit=crop';
        return;
      }

      // Use Firestore to get parent category image
      final categories = await _firestoreService.getCategories(limit: 100);
      final parentCategory = categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => categories.first,
      );

      parentCategoryImageUrl = parentCategory.photo ?? '';
      print(
        '[CATEGORY DETAIL] 📸 Parent category image URL: $parentCategoryImageUrl',
      );
    } catch (e) {
      print('[CATEGORY DETAIL] ❌ Error loading parent category image: $e');
    }
  }

  /// Load subcategories for compatibility with existing code
  Future<void> loadSubcategories() async {
    try {
      isLoadingSubcategories = true;
      print(
        '[CATEGORY DETAIL] 📋 Loading subcategories for category: $categoryId',
      );

      // Special case for trending category - create mock subcategories
      if (categoryId == 'trending') {
        print(
          '[CATEGORY DETAIL] 🔥 Special case: Creating mock subcategories for trending',
        );
        subcategories = [
          MartSubcategoryModel(
            id: 'trending',
            title: 'Trending',
            photo:
                'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=300&h=300&fit=crop',
          ),
        ];
        selectedSubCategoryId = 'trending';
        isLoadingSubcategories = false;
        return;
      }

      // Special case for featured category - create mock subcategories
      if (categoryId == 'featured') {
        print(
          '[CATEGORY DETAIL] ⭐ Special case: Creating mock subcategories for featured',
        );
        subcategories = [
          MartSubcategoryModel(
            id: 'featured',
            title: 'Featured',
            photo:
                'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=300&h=300&fit=crop',
          ),
        ];
        selectedSubCategoryId = 'featured';
        isLoadingSubcategories = false;
        return;
      }

      // Special case for section-based navigation
      if (categoryId.startsWith('section_') && sectionName.isNotEmpty) {
        print(
          '[CATEGORY DETAIL] 📂 Special case: Creating mock subcategories for section: $sectionName',
        );
        subcategories = [
          MartSubcategoryModel(
            id: 'section_${sectionName.toLowerCase().replaceAll(' ', '_')}',
            title: sectionName,
            photo:
                'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=300&h=300&fit=crop',
          ),
        ];
        selectedSubCategoryId =
            'section_${sectionName.toLowerCase().replaceAll(' ', '_')}';
        isLoadingSubcategories = false;
        return;
      }

      // Use Firestore to get subcategories by parent category
      final response = await _firestoreService.getSubcategoriesByParent(
        parentCategoryId: categoryId,
        publish: true,
        sortBy: 'subcategory_order',
        sortOrder: 'asc',
      );

      if (response.isNotEmpty) {
        subcategories.assignAll(response);

        // Select first subcategory by default
        // ✅ Auto-select correct subcategory if available
        if (subcategories.isNotEmpty) {
          if (initialSubcategoryId.isNotEmpty &&
              subcategories.any((sub) => sub.id == initialSubcategoryId)) {
            selectedSubCategoryId = initialSubcategoryId;
            print(
              '[CATEGORY DETAIL] ✅ Auto-selected subcategory: $initialSubcategoryId',
            );
          } else {
            selectedSubCategoryId = subcategories.first.id ?? '';
            print('[CATEGORY DETAIL] ⚠️ Defaulted to first subcategory');
          }
        } else {
          selectedSubCategoryId = categoryId;
          print(
            '[CATEGORY DETAIL] ⚠️ No subcategories found, fallback to parent',
          );
        }

        // if (subcategories.isNotEmpty) {
        //   selectedSubCategoryId = subcategories.first.id ?? '';
        //   print(
        //       '[CATEGORY DETAIL] ✅ Loaded ${subcategories.length} subcategories');
        // } else {
        //   print(
        //       '[CATEGORY DETAIL] ⚠️ No subcategories found, using main category');
        //   selectedSubCategoryId = categoryId;
        // }
      } else {
        print(
          '[CATEGORY DETAIL] ⚠️ No subcategories found for parent category: $categoryId',
        );
        // If no subcategories found, we'll still use the main category
        selectedSubCategoryId = categoryId;
      }
    } catch (e) {
      print('[CATEGORY DETAIL] ❌ Error loading subcategories: $e');
      errorMessage = 'Unable to load subcategories';
      // Fallback to using main category
      selectedSubCategoryId = categoryId;
    } finally {
      isLoadingSubcategories = false;
    }
  }

  /// Select a subcategory
  void selectSubCategory(String subcategoryId) {
    selectedSubCategoryId = subcategoryId;
    print('[CATEGORY DETAIL] 🔄 Selected subcategory: $subcategoryId');
    print('[CATEGORY DETAIL] 🔄 Current category ID: $categoryId');
    print('[CATEGORY DETAIL] 🔄 This will trigger product stream update');
  }

  /// Select a filter and update the UI
  void selectFilter(String? filterType) {
    selectedFilter = filterType ?? '';
    print('[CATEGORY DETAIL] 🔄 Selected filter: $filterType');
  }

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery = query;
    print('[CATEGORY DETAIL] 🔍 Search query updated: $query');
  }

  /// Refresh data (for RefreshIndicator)
  Future<void> refreshData() async {
    print('[CATEGORY DETAIL] 🔄 Refreshing data...');
    errorMessage = '';

    // Reload subcategories for compatibility
    await loadSubcategories();

    // The StreamBuilder will automatically refresh the product data
    await Future.delayed(const Duration(milliseconds: 500));
    print('[CATEGORY DETAIL] ✅ Data refresh completed');
  }

  /// Load products (legacy method - kept for compatibility)
  Future<void> loadProducts() async {
    print(
      '[CATEGORY DETAIL] 🔄 loadProducts() called - using StreamBuilder now',
    );
    // This method is no longer needed as we're using StreamBuilder
    // But keeping it for compatibility with existing code
  }

  /// Test method for debugging (kept for compatibility)
  void testFirestoreEndpoints() async {
    print('[CATEGORY DETAIL] 🧪 Testing Firestore endpoints...');
    try {
      // Test subcategories loading
      await loadSubcategories();
      print('[CATEGORY DETAIL] 🧪 Subcategories test completed');
    } catch (e) {
      print('[CATEGORY DETAIL] ❌ Test failed: $e');
    }
  }
}
