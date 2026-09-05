import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/swiggy_search_screen/provider/swiggy_search_provider.dart';
import 'package:jippymart_customer/app/swiggy_search_screen/widget/buildAppBar.dart';
import 'package:jippymart_customer/app/swiggy_search_screen/widget/buildCreativeSearchChip.dart';
import 'package:jippymart_customer/app/swiggy_search_screen/widget/buildRecentSearchesHeader.dart';
import 'package:jippymart_customer/app/swiggy_search_screen/widget/buildRestaurantCard.dart';
import 'package:jippymart_customer/app/swiggy_search_screen/widget/getSearchEmoji.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/widget/product_options_bottom_sheet.dart';

class SwiggySearchScreen extends StatefulWidget {
  const SwiggySearchScreen({Key? key}) : super(key: key);

  @override
  State<SwiggySearchScreen> createState() => _SwiggySearchScreenState();
}

class _SwiggySearchScreenState extends State<SwiggySearchScreen> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  // Cache vendor details to avoid repeated API calls
  final Map<String, VendorModel?> _vendorCache = {};
  final Map<String, Future<VendorModel?>> _vendorFutures = {};

  // Memoize emoji lookups for performance
  final Map<String, String> _emojiCache = {};

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
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppThemeData.grey50,
        appBar: buildAppBar(searchController, searchFocusNode),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Selector<SwiggySearchProvider, Map<String, dynamic>>(
      selector: (_, provider) => {
        'isLoadingData': provider.isLoadingData,
        'hasSearched': provider.hasSearched,
        'isSearching': provider.isSearching,
        'showSuggestions': provider.showSuggestions,
        'hasSuggestions': provider.searchSuggestions.isNotEmpty,
      },
      builder: (context, state, _) {
        final controller = context.read<SwiggySearchProvider>();

        // Show loading state
        if (state['isLoadingData'] == true && state['hasSearched'] == false) {
          return _buildLoadingState();
        }

        // Show search loading state
        if (state['isSearching'] == true) {
          return _buildSearchLoadingState();
        }

        // Show suggestions while typing
        if (state['showSuggestions'] == true &&
            state['hasSuggestions'] == true) {
          return _buildSuggestionsList();
        }

        // Show search results
        if (state['hasSearched'] == true) {
          return _buildSearchResults();
        }

        // Show initial state (recent + trending)
        return _buildInitialState();
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 80,
            width: 80,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppThemeData.primary300,
              backgroundColor: AppThemeData.primary300.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 32),
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
            style: TextStyle(fontSize: 14, color: AppThemeData.grey400),
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
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppThemeData.primary300,
              backgroundColor: AppThemeData.primary300.withOpacity(0.2),
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

  Widget _buildInitialState() {
    return Selector<SwiggySearchProvider, Map<String, dynamic>>(
      selector: (_, provider) => {
        'recentSearches': provider.recentSearches,
        'trendingSearches': provider.trendingSearches,
      },
      builder: (context, state, _) {
        final controller = context.read<SwiggySearchProvider>();
        final recentSearches = state['recentSearches'] as List<String>;
        final trendingSearches = state['trendingSearches'] as List<String>;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recentSearches.isNotEmpty) ...[
                buildRecentSearchesHeader(context),
                const SizedBox(height: 16),
                _buildRecentSearches(context, searchController, recentSearches),
                const SizedBox(height: 32),
              ],
              if (trendingSearches.isNotEmpty) ...[
                _buildSectionHeader("🔥 Trending Now"),
                const SizedBox(height: 16),
                _buildTrendingSearches(
                  context,
                  searchController,
                  trendingSearches,
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsList() {
    return Selector<SwiggySearchProvider, List<String>>(
      selector: (_, provider) => provider.searchSuggestions,
      builder: (context, suggestions, _) {
        final controller = context.read<SwiggySearchProvider>();
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return RepaintBoundary(
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
                        getSearchEmoji(suggestion),
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
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return Selector<SwiggySearchProvider, Map<String, dynamic>>(
      selector: (_, provider) => {
        'restaurantCount': provider.restaurantResults.length,
        'productCount': provider.productResults.length,
        'categoryCount': provider.categoryResults.length,
        'hasMore': provider.hasMoreResults,
        'isLoadingMore': provider.isLoadingMore,
        'searchText': provider.searchText,
      },
      builder: (context, state, _) {
        final controller = context.read<SwiggySearchProvider>();

        // Show "No results found" when search has no results
        if (state['restaurantCount'] == 0 &&
            state['productCount'] == 0 &&
            state['categoryCount'] == 0) {
          return _buildNoResults();
        }

        // Use CustomScrollView for better performance with nested lists
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Results summary
                  _buildResultsSummary(),
                  const SizedBox(height: 20),
                ]),
              ),
            ),

            // Products section
            if (state['productCount'] as int > 0)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader("🍕 Dishes (${state['productCount']})"),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),
            if (state['productCount'] as int > 0)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: _buildProductsSliver(),
              ),
            if (state['productCount'] as int > 0)
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),

            // Restaurants section
            if (state['restaurantCount'] as int > 0)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader(
                      "🍴 Restaurants (${state['restaurantCount']})",
                    ),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),
            if (state['restaurantCount'] as int > 0)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: _buildRestaurantsSliver(),
              ),

            // Categories section
            if (state['categoryCount'] as int > 0)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader(
                      "📂 Categories (${state['categoryCount']})",
                    ),
                    const SizedBox(height: 12),
                    _buildCategoriesList(),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),

            // Load More Button or Loading indicator
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (state['hasMore'] == true &&
                      state['isLoadingMore'] == false)
                    _buildLoadMoreButton()
                  else if (state['hasMore'] == false &&
                      (state['restaurantCount'] as int > 0 ||
                          state['productCount'] as int > 0))
                    _buildNoMoreResultsMessage()
                  else if (state['isLoadingMore'] == true)
                    _buildLoadingIndicator(),
                ]),
              ),
            ),
          ],
        );
      },
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
            child: const Text("Go Back"),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSummary() {
    return Selector<SwiggySearchProvider, Map<String, dynamic>>(
      selector: (_, provider) => {
        'restaurantCount': provider.restaurantResults.length,
        'productCount': provider.productResults.length,
        'categoryCount': provider.categoryResults.length,
        'searchText': provider.searchText,
      },
      builder: (context, state, _) {
        final totalResults =
            (state['restaurantCount'] as int) +
            (state['productCount'] as int) +
            (state['categoryCount'] as int);

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
                  Expanded(
                    child: Text(
                      "Found $totalResults results for \"${state['searchText']}\"",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppThemeData.primary300,
                        fontFamily: AppThemeData.semiBold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "🍕 Dishes: ${state['productCount']} | "
                "🍴 Restaurants: ${state['restaurantCount']} | "
                "📂 Categories: ${state['categoryCount']}",
                style: TextStyle(fontSize: 12, color: AppThemeData.primary400),
              ),
            ],
          ),
        );
      },
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

  Widget _buildRecentSearches(
    BuildContext context,
    TextEditingController searchController,
    List<String> searches,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: searches.asMap().entries.map((entry) {
        return buildCreativeSearchChip(
          context: context,
          searchController: searchController,
          search: entry.value,
          isRecent: true,
          index: entry.key,
        );
      }).toList(),
    );
  }

  Widget _buildTrendingSearches(
    BuildContext context,
    TextEditingController searchController,
    List<String> searches,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: searches.asMap().entries.map((entry) {
        return buildCreativeSearchChip(
          context: context,
          searchController: searchController,
          search: entry.value,
          isRecent: false,
          index: entry.key,
        );
      }).toList(),
    );
  }

  Widget _buildRestaurantsSliver() {
    return Selector<SwiggySearchProvider, List<VendorModel>>(
      selector: (_, provider) => provider.restaurantResults,
      builder: (context, restaurants, _) {
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return RepaintBoundary(
              child: buildRestaurantCard(
                restaurants[index],
                BuildContext as BuildContext,
              ),
            );
          }, childCount: restaurants.length),
        );
      },
    );
  }

  Widget _buildProductsSliver() {
    return Selector<SwiggySearchProvider, List<ProductModel>>(
      selector: (_, provider) => provider.productResults,
      builder: (context, products, _) {
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return RepaintBoundary(child: _buildProductCard(products[index]));
          }, childCount: products.length),
        );
      },
    );
  }

  Widget _buildCategoriesList() {
    return Selector<SwiggySearchProvider, List<VendorCategoryModel>>(
      selector: (_, provider) => provider.categoryResults,
      builder: (context, categories, _) {
        final controller = context.read<SwiggySearchProvider>();
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map<Widget>((VendorCategoryModel category) {
            return GestureDetector(
              onTap: () {
                searchController.text = category.categoryName ?? '';
                controller.performUnifiedSearch(category.categoryName ?? '');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppThemeData.primary100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppThemeData.primary200),
                ),
                child: Text(
                  category.categoryName ?? 'Category',
                  style: TextStyle(
                    color: AppThemeData.primary300,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLoadMoreButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          context.read<SwiggySearchProvider>().loadMoreResults();
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

  Widget _buildProductCard(ProductModel product) {
    return RepaintBoundary(
      child: Card(
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
                : Icon(
                    Icons.fastfood,
                    color: AppThemeData.warning300,
                    size: 20,
                  ),
          ),
          title: Text(
            product.productName ?? 'Product',
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
            // children: [
            //   if (product.disPrice != null &&
            //       product.disPrice!.isNotEmpty &&
            //       product.disPrice != "0")
            //     Text(
            //       "₹${product.disPrice}",
            //       style: TextStyle(
            //         fontFamily: AppThemeData.semiBold,
            //         color: AppThemeData.primary300,
            //         fontSize: 16,
            //       ),
            //     )
            //   else
            //     Text(
            //       "₹${product.price ?? '0'}",
            //       style: TextStyle(
            //         fontFamily: AppThemeData.semiBold,
            //         color: AppThemeData.primary300,
            //         fontSize: 16,
            //       ),
            //     ),
            //   Icon(
            //     Icons.arrow_forward_ios,
            //     color: AppThemeData.grey400,
            //     size: 16,
            //   ),
            // ],
          ),
          onTap: () {
            _showProductDetailsBottomSheet(context, product);
          },
        ),
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
    final vendorId = product.vendorID ?? '';
    final vendorFuture = vendorId.isNotEmpty
        ? _getVendorDetails(vendorId)
        : null;

    return SafeArea(
      child: Container(
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
              child: vendorFuture != null
                  ? FutureBuilder<VendorModel?>(
                      future: vendorFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildProductDetailsContent(
                              context,
                              product,
                              null,
                              true,
                            ),
                          );
                        }
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildProductDetailsContent(
                            context,
                            product,
                            snapshot.data,
                            false,
                          ),
                        );
                      },
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildProductDetailsContent(
                        context,
                        product,
                        null,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetailsContent(
    BuildContext context,
    ProductModel product, [
    VendorModel? vendor,
    bool isLoading = false,
  ]) {
    final canAcceptOrders =
        vendor != null && RestaurantStatusUtils.canAcceptOrders(vendor);
    final isProductAvailable = product.isAvailable ?? true;
    // final isProductAvailableNow = product.isAvailableAtCurrentTime;
    final hasOptions = _hasProductOptions(product);
    final hasAddOns = _hasProductAddOns(product);
    final shouldShowOptions = hasOptions || hasAddOns;
    final isButtonEnabled =
        canAcceptOrders &&
        isProductAvailable &&
        // isProductAvailableNow &&
        !isLoading;

    return Column(
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
                child: const Center(child: CircularProgressIndicator()),
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
          product.productName ?? 'Unknown Product',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppThemeData.grey900,
          ),
        ),
        const SizedBox(height: 12),
        if (product.description != null && product.description!.isNotEmpty)
          Text(
            product.description!,
            style: TextStyle(fontSize: 16, color: AppThemeData.grey600),
          ),
        const SizedBox(height: 20),
        if (product.vendorID != null && product.vendorID!.isNotEmpty)
          isLoading
              ? Container(
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
                        child: CircularProgressIndicator(strokeWidth: 2),
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
                )
              : vendor != null
              ? Container(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: vendor.photo ?? '',
                                    height: 50,
                                    width: 50,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      height: 50,
                                      width: 50,
                                      color: AppThemeData.grey200,
                                      child: const Icon(
                                        Icons.restaurant,
                                        size: 25,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
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
                                        vendor.title ?? 'Unknown Restaurant',
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
                                            color: AppThemeData.warning400,
                                          ),
                                          const SizedBox(width: 4),
                                          // Text(
                                          //   _calculateRating(
                                          //     product.reviewsSum,
                                          //     product.reviewsCount,
                                          //   ),
                                          //   style: TextStyle(
                                          //     fontSize: 14,
                                          //     color: AppThemeData.grey600,
                                          //   ),
                                          // ),
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
                            if (product.price != null && product.price != "0")
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "₹${product.price}",
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
                                      decoration: TextDecoration.lineThrough,
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
                )
              : const SizedBox.shrink(),
        const SizedBox(height: 20),
        if (product.vendorID != null && product.vendorID!.isNotEmpty) ...[
          if (vendor != null)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<RestaurantDetailsProvider>().initFunction(
                    vendorModels: vendor,
                  );
                  Get.to(() => const RestaurantDetailsScreen());
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
                    Icon(Icons.restaurant, color: AppThemeData.grey900),
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
            ),
          if (vendor != null) const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isButtonEnabled
                  ? () async {
                      if (shouldShowOptions && vendor != null) {
                        await _openProductOptionsBottomSheet(
                          context: context,
                          product: product,
                          vendor: vendor,
                        );
                        return;
                      }
                      await _addToCart(product);
                    }
                  : () {
                      if (!isLoading && vendor != null) {
                        String message;
                        if (!canAcceptOrders) {
                          final status =
                              RestaurantStatusUtils.getRestaurantStatus(vendor);
                          message = status['reason'];
                        } else if (!isProductAvailable) {
                          message = "This product is currently unavailable".tr;
                        } else {
                          message = "Unable to add to cart".tr;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
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
                _getAddToCartButtonText(
                  isLoading,
                  canAcceptOrders,
                  isProductAvailable,
                  // isProductAvailableNow,
                  vendor,
                  shouldShowOptions,
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isButtonEnabled
                      ? AppThemeData.grey50
                      : AppThemeData.grey600,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  String _getAddToCartButtonText(
    bool isLoading,
    bool canAcceptOrders,
    bool isProductAvailable,
    // bool isProductAvailableNow,
    VendorModel? vendor,
    bool shouldShowOptions,
  ) {
    if (isLoading) return "Loading...".tr;
    if (vendor == null) return "Restaurant unavailable".tr;
    if (!canAcceptOrders) return "Restaurant is closed".tr;
    if (!isProductAvailable) return "Product unavailable".tr;
    // if (!isProductAvailableNow) return "Unavailable now".tr;
    if (shouldShowOptions) return "Options".tr;
    return "Add to Cart".tr;
  }

  bool _hasProductOptions(ProductModel product) {
    return product.variants?.isNotEmpty ?? false;
  }

  bool _hasProductAddOns(ProductModel product) {
    return product.addOnsTitle != null &&
        product.addOnsTitle!.isNotEmpty &&
        product.addOnsPrice != null &&
        product.addOnsPrice!.isNotEmpty;
  }

  Future<void> _openProductOptionsBottomSheet({
    required BuildContext context,
    required ProductModel product,
    required VendorModel vendor,
  }) async {
    final restaurantDetailsProvider = context.read<RestaurantDetailsProvider>();
    restaurantDetailsProvider.vendorModel = vendor;
    restaurantDetailsProvider.selectedAddOns.clear();

    final hasDiscount = product.price != null && product.price != "0";

    final priceToPass = hasDiscount ? product.price! : (product.price ?? "0");
    final disPriceToPass = hasDiscount ? (product.price ?? "0") : "0";

    showProductOptionsBottomSheet(
      context: context,
      controller: restaurantDetailsProvider,
      productModel: product,
      priceToPass: priceToPass.toString(),
      disPriceToPass: disPriceToPass.toString(),
      buttonFontSize: 16,
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
      debugPrint("Error getting vendor details: $e");
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
      debugPrint("Error fetching vendor details: $e");
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
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // if (!product.isAvailableAtCurrentTime) {
    //   Get.snackbar(
    //     "Unavailable",
    //     "This product is not available at this time",
    //     snackPosition: SnackPosition.BOTTOM,
    //     backgroundColor: AppThemeData.danger500,
    //     colorText: AppThemeData.grey50,
    //     duration: const Duration(seconds: 3),
    //   );
    //   return;
    // }

    try {
      final vendor = await _getVendorDetails(product.vendorID ?? '');

      String finalPrice = product.price.toString();
      String finalDiscountPrice = '0';

      // if (product.disPrice != null &&
      //     product.disPrice!.isNotEmpty &&
      //     product.disPrice != "0") {
      //   finalDiscountPrice = product.disPrice!;
      //   finalPrice = product.price.toString();
      // }

      CartProductModel cartProductModel = CartProductModel(
        id: product.productId.toString(),
        // categoryId: product.OutletCategory,
        name: product.productName,
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

      final isAdded = await cartProvider.addToCart(
        currentContext,
        cartProductModel,
        1,
      );
      if (!isAdded) {
        return;
      }
      final cartCount = context.read<CartProvider>().totalQuantity;

      Get.snackbar(
        "Added to Cart",
        "${product.productName} added. Cart: $cartCount ${cartCount == 1 ? 'item' : 'items'}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeData.success500,
        colorText: AppThemeData.grey50,
        duration: const Duration(seconds: 2),
      );

      Navigator.pop(currentContext);
    } catch (e) {
      debugPrint("Error adding to cart: $e");

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
