import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/app/search_screen/provider/search_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/themes/text_field_widget.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/widget/restaurant_image_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();

    // Auto-focus the search field after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _searchFocusNode.canRequestFocus) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchScreenProvider>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppThemeData.surface,
            centerTitle: false,
            titleSpacing: 0,
            title: Text(
              "Search Food & Restaurant".tr,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontFamily: AppThemeData.medium,
                fontSize: 16,
                color: AppThemeData.grey900,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(55),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFieldWidget(
                  hintText: 'Search the dish, restaurant, food, meals'.tr,
                  prefix: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SvgPicture.asset("assets/icons/ic_search.svg"),
                  ),
                  controller: controller.searchTextController,
                  focusNode: _searchFocusNode,
                  onchange: (value) {
                    if (mounted) {
                      controller.onSearchTextChanged(value);
                    }
                  },
                ),
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _buildSearchContent(controller),
          ),
        );
      },
    );
  }

  Widget _buildSearchContent(SearchScreenProvider controller) {
    // Show loading indicator when searching
    if (controller.isSearching.value) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppThemeData.primary300),
            const SizedBox(height: 16),
            Text(
              "Searching...".tr,
              style: TextStyle(fontSize: 16, color: AppThemeData.grey900),
            ),
          ],
        ),
      );
    }

    // Show suggestions while typing
    if (controller.showSuggestions.value &&
        controller.searchSuggestions.isNotEmpty) {
      return _buildSuggestionsList(controller);
    }

    // Show initial state when no search has been performed
    if (controller.searchText.value.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: AppThemeData.grey400),
            const SizedBox(height: 16),
            Text(
              "Search for restaurants and dishes".tr,
              style: TextStyle(
                fontSize: 18,
                fontFamily: AppThemeData.semiBold,
                color: AppThemeData.grey900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Type to start searching".tr,
              style: TextStyle(fontSize: 14, color: AppThemeData.grey400),
            ),
          ],
        ),
      );
    }

    // Show "No results found" when search has no results
    if (!controller.isSearching.value &&
        controller.vendorSearchList.isEmpty &&
        controller.productSearchList.isEmpty &&
        controller.searchText.value.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppThemeData.grey400),
            const SizedBox(height: 16),
            Text(
              "No results found".tr,
              style: TextStyle(
                fontSize: 18,
                fontFamily: AppThemeData.semiBold,
                color: AppThemeData.grey900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Try different keywords or check spelling".tr,
              style: TextStyle(color: AppThemeData.grey400),
            ),
            const SizedBox(height: 20),
            // Debug buttons
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    controller.debugProductData();
                  },
                  child: Text("Debug Product Data".tr),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    controller.forceSearchWithDebug(
                      controller.searchText.value,
                    );
                  },
                  child: Text("Force Search with Debug".tr),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Show search results
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results summary
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppThemeData.primary50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: AppThemeData.primary300, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Found ${controller.vendorSearchList.length + controller.productSearchList.length} results for \"${controller.searchText.value}\"",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppThemeData.primary300,
                    fontFamily: AppThemeData.semiBold,
                  ),
                ),
              ],
            ),
          ),

          // Restaurants section
          if (controller.vendorSearchList.isNotEmpty) ...[
            Text(
              "Restaurants (${controller.vendorSearchList.length})".tr,
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                fontSize: 18,
                color: AppThemeData.grey900,
              ),
            ),
            const SizedBox(height: 12),
            _buildRestaurantsList(controller),
            const SizedBox(height: 24),
          ],

          // Products section
          if (controller.productSearchList.isNotEmpty) ...[
            Text(
              "Products (${controller.productSearchList.length})".tr,
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                fontSize: 18,
                color: AppThemeData.grey900,
              ),
            ),
            const SizedBox(height: 12),
            _buildProductsList(controller),
          ],
        ],
      ),
    );
  }

  Widget _buildRestaurantsList(SearchScreenProvider controller) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.vendorSearchList.length,
      itemBuilder: (context, index) {
        VendorModel vendorModel = controller.vendorSearchList[index];
        return _buildRestaurantItem(vendorModel);
      },
    );
  }

  Widget _buildRestaurantItem(VendorModel vendorModel) {
    return Consumer<RestaurantDetailsProvider>(
      builder: (context, restaurantDetailsProvider, _) {
        return InkWell(
          onTap: () {
            restaurantDetailsProvider.initFunction(vendorModels: vendorModel);
            Get.to(
              () => const RestaurantDetailsScreen(),
              arguments: {"vendorModel": vendorModel},
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              decoration: ShapeDecoration(
                color: AppThemeData.grey50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            RestaurantImageView(vendorModel: vendorModel),
                            Container(
                              height: Responsive.height(20, context),
                              width: Responsive.width(100, context),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: const Alignment(-0.00, -1.00),
                                  end: const Alignment(0, 1),
                                  colors: [
                                    Colors.black.withOpacity(0),
                                    const Color(0xFF111827),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildRestaurantBadges(vendorModel),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendorModel.title ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: AppThemeData.semiBold,
                            color: AppThemeData.grey900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (vendorModel.location != null &&
                            vendorModel.location!.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: AppThemeData.grey400,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  vendorModel.location!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppThemeData.grey400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRestaurantBadges(VendorModel vendorModel) {
    return Transform.translate(
      offset: Offset(
        Responsive.width(-3, context),
        Responsive.height(17.5, context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (vendorModel.isSelfDelivery == true &&
              Constant.isSelfDeliveryFeature == true)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppThemeData.lightGreen,
                    borderRadius: BorderRadius.circular(120),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset("assets/icons/ic_free_delivery.svg"),
                      const SizedBox(width: 5),
                      Text(
                        "Free Delivery".tr,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppThemeData.darkGreen,
                          fontFamily: AppThemeData.semiBold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: ShapeDecoration(
              color: AppThemeData.primary50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(120),
              ),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  "assets/icons/ic_star.svg",
                  colorFilter: ColorFilter.mode(
                    AppThemeData.primary300,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  "${Constant.calculateReview(reviewCount: vendorModel.reviewsCount!.toStringAsFixed(0), reviewSum: vendorModel.reviewsSum.toString())} (${vendorModel.reviewsCount!.toStringAsFixed(0)})",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppThemeData.primary300,
                    fontFamily: AppThemeData.semiBold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: ShapeDecoration(
              color: AppThemeData.secondary50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(120),
              ),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  "assets/icons/ic_map_distance.svg",
                  colorFilter: const ColorFilter.mode(
                    AppThemeData.secondary300,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  "${Constant.getDistance(lat1: vendorModel.latitude.toString(), lng1: vendorModel.longitude.toString(), lat2: Constant.selectedLocation.location!.latitude.toString(), lng2: Constant.selectedLocation.location!.longitude.toString())} km",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppThemeData.secondary300,
                    fontFamily: AppThemeData.semiBold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(SearchScreenProvider controller) {
    print(
      "DEBUG: Building products list with ${controller.productSearchList.length} products",
    );
    if (controller.productSearchList.isNotEmpty) {
      print("DEBUG: First product: ${controller.productSearchList.first.name}");
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.productSearchList.length,
      itemBuilder: (context, index) {
        ProductModel productModel = controller.productSearchList[index];
        print("DEBUG: Building product item $index: ${productModel.name}");
        return _buildProductItem(productModel);
      },
    );
  }

  Widget _buildProductItem(ProductModel productModel) {
    // SIMPLE PRODUCT DISPLAY - NO FUTURE BUILDER
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          print("DEBUG: Product tapped: ${productModel.name}");
          // Get the vendor details for this product
          VendorModel? vendorModel = await FireStoreUtils.getVendorById(
            productModel.vendorID.toString(),
          );
          if (vendorModel != null) {
            print(
              "DEBUG: Navigating to restaurant with product: ${productModel.id}",
            );
            RestaurantDetailsProvider restaurantDetailsProvider =
                Provider.of<RestaurantDetailsProvider>(context, listen: false);

            restaurantDetailsProvider.initFunction(vendorModels: vendorModel);
            // Navigate to restaurant details screen with the product ID to scroll to
            Get.to(
              () => RestaurantDetailsScreen(scrollToProductId: productModel.id),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: ShapeDecoration(
            color: AppThemeData.grey50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: NetworkImageWidget(
                      imageUrl: productModel.photo ?? '',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productModel.name ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: AppThemeData.semiBold,
                          color: AppThemeData.grey900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (productModel.description != null &&
                          productModel.description!.isNotEmpty)
                        Text(
                          productModel.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppThemeData.grey400,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            "₹${productModel.price ?? '0'}",
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: AppThemeData.semiBold,
                              color: AppThemeData.primary300,
                            ),
                          ),
                          if (productModel.disPrice != null &&
                              productModel.disPrice != productModel.price)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                "₹${productModel.disPrice}",
                                style: TextStyle(
                                  fontSize: 14,
                                  decoration: TextDecoration.lineThrough,
                                  color: AppThemeData.grey400,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(SearchScreenProvider controller) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.searchSuggestions.length,
      itemBuilder: (context, index) {
        String suggestion = controller.searchSuggestions[index];
        return ListTile(
          leading: Icon(Icons.search, color: AppThemeData.grey400),
          title: Text(
            suggestion,
            style: TextStyle(fontSize: 16, color: AppThemeData.grey900),
          ),
          onTap: () {
            controller.selectSuggestion(suggestion);
          },
        );
      },
    );
  }
}
