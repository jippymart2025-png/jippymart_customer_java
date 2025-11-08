import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/restaurant_list_screen/provider/restaurant_list_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/restaurant_list_screen/restaurant_list_screen.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
import 'package:jippymart_customer/widget/filter_bar.dart';
import 'package:jippymart_customer/widget/restaurant_image_with_status.dart';
import 'package:provider/provider.dart';

class BestRestaurantsSection extends StatefulWidget {
  final List<VendorModel> restaurantList;

  const BestRestaurantsSection({super.key, required this.restaurantList});

  @override
  State<BestRestaurantsSection> createState() => _BestRestaurantsSectionState();
}

class _BestRestaurantsSectionState extends State<BestRestaurantsSection> {
  Set<FilterType> selectedFilters = {};
  late List<VendorModel> filteredList;

  @override
  void initState() {
    super.initState();
    filteredList = List.from(widget.restaurantList);
  }

  void onFilterToggled(FilterType filter, BestRestaurantProvider provider) {
    String? apiFilter;

    switch (filter) {
      case FilterType.distance:
        apiFilter = 'distance';
        break;
      case FilterType.rating:
        apiFilter = 'rating';
        break;
      case FilterType.priceLowToHigh:
      case FilterType.priceHighToLow:
        // These filters are not supported by API, show message or ignore
        _showUnsupportedFilterMessage();
        return;
    }

    // Apply filter through API
    provider.applyFilter(apiFilter);
  }

  void _showUnsupportedFilterMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('This filter is currently not available'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<
      BestRestaurantProvider,
      HomeProvider,
      RestaurantListProvider,
      RestaurantDetailsProvider
    >(
      builder:
          (
            context,
            provider,
            homeProvider,
            restaurantListProvider,
            restaurantDetailsProvider,
            _,
          ) {
            final displayList = provider.allNearestRestaurant;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Best Restaurants",
                          style: TextStyle(
                            fontFamily: AppThemeData.medium,
                            color: AppThemeData.grey900,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          restaurantListProvider.initFunction(
                            vendorLists: displayList,
                            titles: "Best Restaurants",
                          );
                          Get.to(const RestaurantListScreen());
                        },
                        child: Text(
                          "See all".tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppThemeData.medium,
                            color: AppThemeData.primary300,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: FilterBar(
                    selectedFilters: selectedFilters,
                    onFilterToggled: (filter) =>
                        onFilterToggled(filter, provider),
                    availableFilters: provider.availableFilters,
                    currentFilter: provider.currentFilter,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.builder(
                        shrinkWrap: true,
                        primary: false,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayList.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.65,
                            ),
                        itemBuilder: (BuildContext context, int index) {
                          final vendorModel = displayList[index];
                          // final isClosed = !RestaurantStatusUtils.canAcceptOrders(
                          //   vendorModel,
                          // );
                          final isClosed =
                              !RestaurantStatusUtils.canAcceptOrders(
                                vendorModel,
                              );
                          return InkWell(
                            onTap: isClosed
                                ? null
                                : () {
                                    restaurantDetailsProvider.initFunction(
                                      vendorModels: vendorModel,
                                    );
                                    Get.to(const RestaurantDetailsScreen());
                                  },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppThemeData.grey50,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Main Content
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 🖼 Image Section
                                        AspectRatio(
                                          aspectRatio: 1,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color: AppThemeData.grey200
                                                  .withOpacity(0.5),
                                            ),
                                            child: Stack(
                                              children: [
                                                // Restaurant Image
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child:
                                                      RestaurantImageWithStatus(
                                                        vendorModel:
                                                            vendorModel,
                                                        height: double.infinity,
                                                        width: double.infinity,
                                                      ),
                                                ),
                                                // Status Badge
                                                Positioned(
                                                  top: 6,
                                                  left: 6,
                                                  child:
                                                      _buildEnhancedStatusBadge(
                                                        vendorModel,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          vendorModel.title ?? 'Restaurant',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: AppThemeData.semiBold,
                                            color: AppThemeData.grey900,
                                            height: 1.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        const Spacer(),
                                        _buildBottomInfoRow(vendorModel),
                                      ],
                                    ),
                                  ),
                                  if (isClosed) ...[
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.7,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'CLOSED',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontFamily: AppThemeData.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
    );
  }

  Widget _buildEnhancedStatusBadge(VendorModel vendorModel) {
    final isOpen = RestaurantStatusUtils.canAcceptOrders(vendorModel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isOpen
            ? Colors.green.withOpacity(0.9)
            : Colors.red.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.circle : Icons.circle_outlined,
            size: 6,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'OPEN' : 'CLOSED',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontFamily: AppThemeData.bold,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfoRow(VendorModel vendorModel) {
    return Row(
      children: [
        // Rating
        Expanded(
          child: Row(
            children: [
              Icon(Icons.star, size: 12, color: AppThemeData.primary300),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  "${Constant.calculateReview(reviewCount: vendorModel.reviewsCount.toString(), reviewSum: vendorModel.reviewsSum.toString())} (${vendorModel.reviewsCount?.toStringAsFixed(0) ?? '0'})",
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: AppThemeData.medium,
                    color: AppThemeData.grey500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Distance (if available)
        if (vendorModel.distance != null) ...[
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 10,
                  color: AppThemeData.grey400,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    "${(vendorModel.distance ?? 0).toStringAsFixed(1)} km",
                    style: TextStyle(
                      fontSize: 9,
                      fontFamily: AppThemeData.medium,
                      color: AppThemeData.grey500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
