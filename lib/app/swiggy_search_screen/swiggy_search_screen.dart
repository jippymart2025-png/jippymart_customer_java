import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/swiggy_search_screen/provider/swiggy_search_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/widgets/app_loading_widget.dart';
import 'package:jippymart_customer/utils/restaurant_status_utils.dart';

class SwiggySearchScreen extends StatefulWidget {
  const SwiggySearchScreen({Key? key}) : super(key: key);

  @override
  State<SwiggySearchScreen> createState() => _SwiggySearchScreenState();
}

class _SwiggySearchScreenState extends State<SwiggySearchScreen> {
  final TextEditingController searchController = TextEditingController();
  final CartProvider cartProvider = CartProvider();
  final FocusNode searchFocusNode = FocusNode();

  // Cache vendor details to avoid repeated API calls
  final Map<String, VendorModel?> _vendorCache = {};
  final Map<String, Future<VendorModel?>> _vendorFutures = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SwiggySearchProvider>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: AppThemeData.grey50,
          appBar: _buildAppBar(controller),
          body: _buildBody(controller),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(SwiggySearchProvider controller) {
    return AppBar(
      backgroundColor: AppThemeData.grey50,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: AppThemeData.grey900),
        onPressed: () => Get.back(),
      ),
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppThemeData.grey100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          controller: searchController,
          focusNode: searchFocusNode,
          onChanged: controller.updateSearchText,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              controller.performUnifiedSearch(value.trim());
            }
          },
          style: TextStyle(color: AppThemeData.grey900, fontSize: 16),
          decoration: InputDecoration(
            hintText: "Search for restaurants, dishes, or cuisines",
            hintStyle: TextStyle(color: AppThemeData.grey400, fontSize: 16),
            prefixIcon: Icon(
              Icons.search,
              color: AppThemeData.grey400,
              size: 20,
            ),
            suffixIcon: controller.searchText.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: AppThemeData.grey400,
                      size: 20,
                    ),
                    onPressed: () {
                      searchController.clear();
                      controller.clearSearch();
                    },
                  )
                : const SizedBox.shrink(),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(SwiggySearchProvider controller) {
    // Show loading state
    if (controller.isLoadingData && !controller.hasSearched) {
      return _buildLoadingState();
    }

    // Show search loading state
    if (controller.isSearching) {
      return _buildSearchLoadingState();
    }

    // Show suggestions while typing
    if (controller.showSuggestions && controller.searchSuggestions.isNotEmpty) {
      return _buildSuggestionsList(controller);
    }

    // Show search results
    if (controller.hasSearched) {
      return _buildSearchResults(controller);
    }

    // Show initial state (recent + trending)
    return _buildInitialState(controller);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 2),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.rotate(
                      angle: value * 2 * 3.14159,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppThemeData.primary300.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1500),
                  tween: Tween(begin: 0.8, end: 1.2),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppThemeData.primary300,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppThemeData.primary300.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 2000),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Column(
                  children: [
                    Text(
                      "🍽️ Preparing Your Food Journey",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppThemeData.grey900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Loading delicious restaurants & dishes...",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppThemeData.grey400,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1000),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.9 + (0.1 * value),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppThemeData.primary300,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "🔍 Searching...",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppThemeData.grey900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Finding the best matches for you",
            style: TextStyle(fontSize: 14, color: AppThemeData.grey400),
          ),
        ],
      ),
    );
  }

  void _clearRecentSearches(SwiggySearchProvider controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Clear Recent Searches?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppThemeData.grey900,
            ),
          ),
          content: Text(
            "This will remove all your recent search history. This action cannot be undone.",
            style: TextStyle(color: AppThemeData.grey400),
          ),
          backgroundColor: AppThemeData.grey50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: AppThemeData.grey400),
              ),
            ),
            TextButton(
              onPressed: () {
                controller.clearRecentSearches();
                Navigator.pop(context);
                Get.snackbar(
                  "Cleared",
                  "Recent searches have been cleared",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppThemeData.success500,
                  colorText: AppThemeData.grey50,
                );
              },
              child: Text(
                "Clear",
                style: TextStyle(
                  color: AppThemeData.danger500,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInitialState(SwiggySearchProvider controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.recentSearches.isNotEmpty) ...[
            _buildRecentSearchesHeader(controller),
            const SizedBox(height: 16),
            _buildRecentSearches(controller),
            const SizedBox(height: 32),
          ],
          if (controller.trendingSearches.isNotEmpty) ...[
            _buildSectionHeader("🔥 Trending Now"),
            const SizedBox(height: 16),
            _buildTrendingSearches(controller),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentSearchesHeader(SwiggySearchProvider controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Recent Searches",
          style: TextStyle(
            fontFamily: AppThemeData.semiBold,
            fontSize: 20,
            color: AppThemeData.grey900,
            letterSpacing: 0.3,
          ),
        ),
        GestureDetector(
          onTap: () => _clearRecentSearches(controller),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppThemeData.grey200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.clear_all, color: AppThemeData.grey500, size: 14),
                const SizedBox(width: 4),
                Text(
                  "Clear",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppThemeData.grey500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionsList(SwiggySearchProvider controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.searchSuggestions.length,
      itemBuilder: (context, index) {
        String suggestion = controller.searchSuggestions[index];

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 200 + (index * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppThemeData.grey50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppThemeData.grey200, width: 1),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppThemeData.primary100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getSearchEmoji(suggestion),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    title: Text(
                      suggestion,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppThemeData.grey900,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: AppThemeData.grey400,
                      size: 16,
                    ),
                    onTap: () {
                      searchController.text = suggestion;
                      controller.selectSuggestion(suggestion);
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults(SwiggySearchProvider controller) {
    // Show "No results found" when search has no results
    if (controller.restaurantResults.isEmpty &&
        controller.productResults.isEmpty &&
        controller.categoryResults.isEmpty) {
      return _buildNoResults();
    }

    // Show search results
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results summary
          _buildResultsSummary(controller),
          const SizedBox(height: 20),

          // Products section (Show first - users want dishes first)
          if (controller.productResults.isNotEmpty) ...[
            _buildSectionHeader(
              "🍕 Dishes (${controller.productResults.length})",
            ),
            const SizedBox(height: 12),
            _buildProductsList(controller),
            const SizedBox(height: 24),
          ],

          // Restaurants section
          if (controller.restaurantResults.isNotEmpty) ...[
            _buildSectionHeader(
              "🍴 Restaurants (${controller.restaurantResults.length})",
            ),
            const SizedBox(height: 12),
            _buildRestaurantsList(controller),
          ],

          // Categories section (if you want to show them)
          if (controller.categoryResults.isNotEmpty) ...[
            _buildSectionHeader(
              "📂 Categories (${controller.categoryResults.length})",
            ),
            const SizedBox(height: 12),
            _buildCategoriesList(controller),
            const SizedBox(height: 24),
          ],

          // Load More Button
          if (controller.hasMoreResults && !controller.isLoadingMore) ...[
            const SizedBox(height: 20),
            _buildLoadMoreButton(controller),
          ] else if (!controller.hasMoreResults &&
              (controller.restaurantResults.isNotEmpty ||
                  controller.productResults.isNotEmpty)) ...[
            const SizedBox(height: 20),
            _buildNoMoreResultsMessage(),
          ],

          // Loading indicator for pagination
          if (controller.isLoadingMore) ...[
            const SizedBox(height: 20),
            _buildLoadingIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppThemeData.grey400),
          const SizedBox(height: 16),
          Text(
            "No results found",
            style: TextStyle(
              fontSize: 18,
              fontFamily: AppThemeData.semiBold,
              color: AppThemeData.grey900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try different keywords or check spelling",
            style: TextStyle(color: AppThemeData.grey400),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              searchController.clear();
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeData.primary300,
              foregroundColor: Colors.white,
            ),
            child: Text("Go Back"),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSummary(SwiggySearchProvider controller) {
    final totalResults =
        controller.restaurantResults.length +
        controller.productResults.length +
        controller.categoryResults.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeData.primary50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: AppThemeData.primary300, size: 20),
              const SizedBox(width: 8),
              Text(
                "Found $totalResults results for \"${controller.searchText}\"",
                style: TextStyle(
                  fontSize: 14,
                  color: AppThemeData.primary300,
                  fontFamily: AppThemeData.semiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "🍕 Dishes: ${controller.productResults.length} | "
            "🍴 Restaurants: ${controller.restaurantResults.length} | "
            "📂 Categories: ${controller.categoryResults.length}",
            style: TextStyle(fontSize: 12, color: AppThemeData.primary400),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppThemeData.semiBold,
          fontSize: 20,
          color: AppThemeData.grey900,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildRecentSearches(SwiggySearchProvider controller) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: controller.recentSearches.asMap().entries.map((entry) {
        int index = entry.key;
        String search = entry.value;
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(
                opacity: value,
                child: _buildCreativeSearchChip(
                  search: search,
                  isRecent: true,
                  index: index,
                  controller: controller,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildTrendingSearches(SwiggySearchProvider controller) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: controller.trendingSearches.asMap().entries.map((entry) {
        int index = entry.key;
        String trend = entry.value;
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 120)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(
                opacity: value,
                child: _buildCreativeSearchChip(
                  search: trend,
                  isRecent: false,
                  index: index,
                  controller: controller,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildCreativeSearchChip({
    required String search,
    required bool isRecent,
    required int index,
    required SwiggySearchProvider controller,
  }) {
    String emoji = _getSearchEmoji(search);
    Color primaryColor = isRecent
        ? AppThemeData.primary300
        : AppThemeData.warning300;
    Color backgroundColor = isRecent
        ? AppThemeData.primary50
        : AppThemeData.warning50;
    Color borderColor = isRecent
        ? AppThemeData.primary200
        : AppThemeData.warning200;

    return GestureDetector(
      onTap: () {
        searchController.text = search;
        controller.performUnifiedSearch(search);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor.withOpacity(0.6), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 11)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              search,
              style: TextStyle(
                color: primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSearchEmoji(String search) {
    final lowerSearch = search.toLowerCase();

    // Food categories
    if (lowerSearch.contains('pizza')) return '🍕';
    if (lowerSearch.contains('biryani')) return '🍛';
    if (lowerSearch.contains('burger')) return '🍔';
    if (lowerSearch.contains('coffee')) return '☕';
    if (lowerSearch.contains('ice cream')) return '🍦';
    if (lowerSearch.contains('chicken')) return '🍗';
    if (lowerSearch.contains('pasta')) return '🍝';
    if (lowerSearch.contains('sushi')) return '🍣';
    if (lowerSearch.contains('taco')) return '🌮';
    if (lowerSearch.contains('sandwich')) return '🥪';
    if (lowerSearch.contains('salad')) return '🥗';
    if (lowerSearch.contains('soup')) return '🍲';
    if (lowerSearch.contains('noodles')) return '🍜';
    if (lowerSearch.contains('rice')) return '🍚';
    if (lowerSearch.contains('bread')) return '🍞';
    if (lowerSearch.contains('cake')) return '🍰';
    if (lowerSearch.contains('dessert')) return '🍮';
    if (lowerSearch.contains('sweet')) return '🍭';
    if (lowerSearch.contains('spicy')) return '🌶️';
    if (lowerSearch.contains('healthy')) return '🥑';
    if (lowerSearch.contains('vegetarian') || lowerSearch.contains('veg'))
      return '🥬';

    // Cuisines
    if (lowerSearch.contains('chinese')) return '🥢';
    if (lowerSearch.contains('italian')) return '🍝';
    if (lowerSearch.contains('indian')) return '🍛';
    if (lowerSearch.contains('mexican')) return '🌮';
    if (lowerSearch.contains('japanese')) return '🍣';
    if (lowerSearch.contains('thai')) return '🍜';
    if (lowerSearch.contains('korean')) return '🥘';
    if (lowerSearch.contains('american')) return '🍔';
    if (lowerSearch.contains('fast food')) return '🍟';

    // General food terms
    if (lowerSearch.contains('food')) return '🍽️';
    if (lowerSearch.contains('restaurant')) return '🍴';
    if (lowerSearch.contains('meal')) return '🍽️';
    if (lowerSearch.contains('lunch')) return '🍱';
    if (lowerSearch.contains('dinner')) return '🍽️';
    if (lowerSearch.contains('breakfast')) return '🥞';
    if (lowerSearch.contains('snack')) return '🍿';

    return '🍽️';
  }

  Widget _buildRestaurantsList(SwiggySearchProvider controller) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.restaurantResults.length,
      itemBuilder: (context, index) {
        VendorModel restaurant = controller.restaurantResults[index];
        return _buildRestaurantCard(restaurant);
      },
    );
  }

  Widget _buildProductsList(SwiggySearchProvider controller) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.productResults.length,
      itemBuilder: (context, index) {
        ProductModel product = controller.productResults[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildCategoriesList(SwiggySearchProvider controller) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: controller.categoryResults.map((category) {
        return GestureDetector(
          onTap: () {
            // You can implement category search here
            searchController.text = category.title ?? '';
            controller.performUnifiedSearch(category.title ?? '');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppThemeData.primary100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppThemeData.primary200),
            ),
            child: Text(
              category.title ?? 'Category',
              style: TextStyle(
                color: AppThemeData.primary300,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadMoreButton(SwiggySearchProvider controller) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          controller.loadMoreResults();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppThemeData.primary500,
          foregroundColor: AppThemeData.grey50,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          "Load More Results",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppThemeData.grey50,
          ),
        ),
      ),
    );
  }

  Widget _buildNoMoreResultsMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 32,
              color: AppThemeData.grey500,
            ),
            const SizedBox(height: 16),
            Text(
              "🎯 That's all we found!",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppThemeData.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "No more results available for your search",
              style: TextStyle(fontSize: 14, color: AppThemeData.grey500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Column(
      children: [
        SizedBox(height: 20),
        CircularProgressIndicator(),
        SizedBox(height: 10),
        Text("Loading more results..."),
      ],
    );
  }

  Widget _buildRestaurantCard(VendorModel restaurant) {
    return Consumer<RestaurantDetailsProvider>(
      builder: (context, restaurantDetailsProvider, _) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: AppThemeData.grey50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: !RestaurantStatusUtils.canAcceptOrders(restaurant)
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Restaurant Closed"),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                : () {
                    restaurantDetailsProvider.initFunction(
                      vendorModels: restaurant,
                    );
                    Get.to(() => const RestaurantDetailsScreen());
                  },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: restaurant.photo ?? '',
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 180,
                          color: AppThemeData.grey200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 180,
                          color: AppThemeData.grey200,
                          child: const Icon(Icons.restaurant, size: 50),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: RestaurantStatusUtils.getStatusWidget(restaurant),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.title ?? 'Restaurant',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppThemeData.grey900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurant.location ?? 'Location not available',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppThemeData.grey400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (restaurant.categoryTitle != null &&
                          restaurant.categoryTitle!.isNotEmpty)
                        Text(
                          restaurant.categoryTitle!.join(', '),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppThemeData.primary300,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppThemeData.grey50,
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: AppThemeData.warning100,
          child: product.photo != null && product.photo!.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: product.photo!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Icon(
                      Icons.fastfood,
                      color: AppThemeData.warning300,
                      size: 20,
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.fastfood,
                      color: AppThemeData.warning300,
                      size: 20,
                    ),
                  ),
                )
              : Icon(Icons.fastfood, color: AppThemeData.warning300, size: 20),
        ),
        title: Text(
          product.name ?? 'Product',
          style: TextStyle(
            fontFamily: AppThemeData.semiBold,
            color: AppThemeData.grey900,
          ),
        ),
        subtitle: Text(
          product.description ?? 'Description not available',
          style: TextStyle(color: AppThemeData.grey400),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (product.disPrice != null &&
                product.disPrice!.isNotEmpty &&
                product.disPrice != "0")
              Text(
                "₹${product.disPrice}",
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  color: AppThemeData.primary300,
                  fontSize: 16,
                ),
              )
            else
              Text(
                "₹${product.price ?? '0'}",
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  color: AppThemeData.primary300,
                  fontSize: 16,
                ),
              ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppThemeData.grey400,
              size: 16,
            ),
          ],
        ),
        onTap: () {
          _showProductDetailsBottomSheet(context, product);
        },
      ),
    );
  }

  void _showProductDetailsBottomSheet(
    BuildContext context,
    ProductModel productModel,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _buildSimpleProductDetails(productModel),
      ),
    );
  }

  Widget _buildSimpleProductDetails(ProductModel product) {
    return Container(
      decoration: BoxDecoration(
        color: AppThemeData.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppThemeData.grey400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Product Details",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppThemeData.grey900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: AppThemeData.grey900),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: product.photo ?? '',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 200,
                          color: AppThemeData.grey200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 200,
                          color: AppThemeData.grey200,
                          child: const Icon(Icons.fastfood, size: 50),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    product.name ?? 'Unknown Product',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppThemeData.grey900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (product.description != null &&
                      product.description!.isNotEmpty)
                    Text(
                      product.description!,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppThemeData.grey600,
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (product.vendorID != null && product.vendorID!.isNotEmpty)
                    FutureBuilder<VendorModel?>(
                      future: _getVendorDetails(product.vendorID!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppThemeData.grey100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Loading restaurant details...",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppThemeData.grey600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return const SizedBox.shrink();
                        }
                        if (snapshot.hasData && snapshot.data != null) {
                          final vendor = snapshot.data!;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppThemeData.grey100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "From Restaurant",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppThemeData.grey900,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: vendor.photo ?? '',
                                              height: 50,
                                              width: 50,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                    height: 50,
                                                    width: 50,
                                                    color: AppThemeData.grey200,
                                                    child: const Icon(
                                                      Icons.restaurant,
                                                      size: 25,
                                                    ),
                                                  ),
                                              errorWidget:
                                                  (
                                                    context,
                                                    url,
                                                    error,
                                                  ) => Container(
                                                    height: 50,
                                                    width: 50,
                                                    color: AppThemeData.grey200,
                                                    child: const Icon(
                                                      Icons.restaurant,
                                                      size: 25,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  vendor.title ??
                                                      'Unknown Restaurant',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppThemeData.grey900,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.star,
                                                      size: 16,
                                                      color: AppThemeData
                                                          .warning400,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _calculateRating(
                                                        product.reviewsSum,
                                                        product.reviewsCount,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: AppThemeData
                                                            .grey600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Price",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppThemeData.grey900,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (product.disPrice != null &&
                                          product.disPrice!.isNotEmpty &&
                                          product.disPrice != "0")
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "₹${product.disPrice}",
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: AppThemeData.success500,
                                              ),
                                            ),
                                            Text(
                                              "₹${product.price ?? '0'}",
                                              style: TextStyle(
                                                fontSize: 16,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                color: AppThemeData.grey500,
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Text(
                                          "₹${product.price ?? '0'}",
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppThemeData.warning500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      if (product.vendorID != null)
                        Consumer<RestaurantDetailsProvider>(
                          builder: (context, restaurantDetailsProvider, _) {
                            return SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final vendor = await _getVendorDetails(
                                    product.vendorID!,
                                  );
                                  if (vendor != null) {
                                    Navigator.pop(context);
                                    restaurantDetailsProvider.initFunction(
                                      vendorModels: vendor,
                                    );
                                    Get.to(
                                      () => const RestaurantDetailsScreen(),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppThemeData.grey200,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.restaurant,
                                      color: AppThemeData.grey900,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Go to Restaurant",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppThemeData.grey900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      if (product.vendorID != null) const SizedBox(height: 12),
                      FutureBuilder<VendorModel?>(
                        future: _getVendorDetails(product.vendorID ?? ''),
                        builder: (context, vendorSnapshot) {
                          bool isLoadingVendor =
                              vendorSnapshot.connectionState ==
                              ConnectionState.waiting;
                          bool canAcceptOrders = false;
                          String buttonText = "Loading...".tr;
                          String statusReason = "";
                          if (vendorSnapshot.hasData &&
                              vendorSnapshot.data != null) {
                            final vendor = vendorSnapshot.data!;
                            canAcceptOrders =
                                RestaurantStatusUtils.canAcceptOrders(vendor);
                            final status =
                                RestaurantStatusUtils.getRestaurantStatus(
                                  vendor,
                                );
                            statusReason = status['reason'];
                            if (canAcceptOrders &&
                                (product.isAvailable ?? true)) {
                              buttonText = "Add to Cart".tr;
                            } else if (!canAcceptOrders) {
                              buttonText = "Restaurant is closed".tr;
                            } else if (!(product.isAvailable ?? true)) {
                              buttonText = "Product unavailable".tr;
                            }
                          } else if (!isLoadingVendor) {
                            buttonText = "Restaurant unavailable".tr;
                          }
                          bool isButtonEnabled =
                              canAcceptOrders &&
                              (product.isAvailable ?? true) &&
                              !isLoadingVendor;
                          return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isButtonEnabled
                                  ? () async {
                                      await _addToCart(product);
                                    }
                                  : () {
                                      if (!isLoadingVendor &&
                                          vendorSnapshot.hasData &&
                                          vendorSnapshot.data != null) {
                                        String message;
                                        if (!canAcceptOrders) {
                                          final status =
                                              RestaurantStatusUtils.getRestaurantStatus(
                                                vendorSnapshot.data!,
                                              );
                                          message = status['reason'];
                                        } else if (!(product.isAvailable ??
                                            true)) {
                                          message =
                                              "This product is currently unavailable"
                                                  .tr;
                                        } else {
                                          message = "Unable to add to cart".tr;
                                        }

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(message),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(
                                              seconds: 3,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isButtonEnabled
                                    ? const Color(0xFFFF5200)
                                    : AppThemeData.grey400,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                buttonText,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isButtonEnabled
                                      ? AppThemeData.grey50
                                      : AppThemeData.grey600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<VendorModel?> _getVendorDetails(String vendorID) async {
    if (_vendorCache.containsKey(vendorID)) {
      return _vendorCache[vendorID];
    }

    if (_vendorFutures.containsKey(vendorID)) {
      return _vendorFutures[vendorID];
    }

    final future = _fetchVendorDetails(vendorID);
    _vendorFutures[vendorID] = future;

    try {
      final vendor = await future;
      _vendorCache[vendorID] = vendor;
      return vendor;
    } catch (e) {
      print("Error getting vendor details: $e");
      _vendorCache[vendorID] = null;
      return null;
    } finally {
      _vendorFutures.remove(vendorID);
    }
  }

  Future<VendorModel?> _fetchVendorDetails(String vendorID) async {
    try {
      return await FireStoreUtils.getVendorById(vendorID);
    } catch (e) {
      print("Error fetching vendor details: $e");
      return null;
    }
  }

  String _calculateRating(num? reviewsSum, num? reviewsCount) {
    if (reviewsSum == null || reviewsCount == null || reviewsCount == 0) {
      return "No rating";
    }
    final rating = reviewsSum / reviewsCount;
    return rating.toStringAsFixed(1);
  }

  Future<void> _addToCart(ProductModel product) async {
    final currentContext = context;

    try {
      final vendor = await _getVendorDetails(product.vendorID ?? '');

      String finalPrice = product.price ?? '0';
      String finalDiscountPrice = '0';

      if (product.disPrice != null &&
          product.disPrice!.isNotEmpty &&
          product.disPrice != "0") {
        finalDiscountPrice = product.disPrice!;
        finalPrice = product.price ?? '0';
      }

      CartProductModel cartProductModel = CartProductModel(
        id: product.id.toString(),
        categoryId: product.categoryID,
        name: product.name,
        photo: product.photo,
        price: finalPrice,
        discountPrice: finalDiscountPrice,
        vendorID: product.vendorID,
        vendorName: vendor?.title ?? 'Unknown Restaurant',
        quantity: 1,
        extrasPrice: "0",
        extras: null,
        variantInfo: null,
        promoId: null,
      );

      await cartProvider.addToCart(currentContext, cartProductModel, 1);

      Get.snackbar(
        "Added to Cart",
        "${product.name} has been added to your cart",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeData.success500,
        colorText: AppThemeData.grey50,
        duration: const Duration(seconds: 2),
      );

      Navigator.pop(currentContext);
    } catch (e) {
      print("Error adding to cart: $e");

      Get.snackbar(
        "Error",
        "Failed to add item to cart. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeData.danger500,
        colorText: AppThemeData.grey50,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
