import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/restaurant_list_screen/provider/restaurant_list_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/restaurant_list_screen/restaurant_list_screen.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/restaurant_status_utils.dart';
import 'package:jippymart_customer/widget/restaurant_image_with_status.dart';
import 'package:provider/provider.dart';

import '../../../../../widgets/app_loading_widget.dart';

class BestRestaurantsSection extends StatelessWidget {
  final List restaurantList;

  const BestRestaurantsSection({super.key, required this.restaurantList});

  @override
  Widget build(BuildContext context) {
    return Consumer3<
      BestRestaurantProvider,
      RestaurantListProvider,
      RestaurantDetailsProvider
    >(
      builder:
          (
            context,
            provider,
            restaurantListProvider,
            restaurantDetailsProvider,
            _,
          ) {
            final filteredRestaurantList = provider.filteredRestaurantList;
            final displayList = provider.displayList;

            if (provider.isLoading && displayList.isEmpty) {
              return const RestaurantLoadingWidget();
            }
            final allRestaurantsList = filteredRestaurantList;

            if (displayList.isEmpty) {
              return const SizedBox.shrink();
            }

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
                            vendorLists: allRestaurantsList,
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
                const SizedBox(height: 12),
                SizedBox(
                  // Card height: roughly screen_width/3 * (1/0.65) + paddings
                  // Use a fixed height that matches childAspectRatio: 0.65 for a card width of ~(screenWidth - 32 - 12) / 3
                  height:
                      (MediaQuery.of(context).size.width - 32 - 12) / 3 / 0.65,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: displayList.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (BuildContext context, int index) {
                      final vendorModel = displayList[index];
                      final isClosed = !RestaurantStatusUtils.canAcceptOrders(
                        vendorModel,
                      );

                      // Each card width matches the original grid column width
                      final cardWidth =
                          (MediaQuery.of(context).size.width - 32 - 12) / 3;

                      return RepaintBoundary(
                        child: SizedBox(
                          width: cardWidth,
                          child: InkWell(
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
                                    padding: const EdgeInsets.all(8),
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
                                        const SizedBox(height: 2),
                                        _buildDeliveryTimeAndFastRow(
                                          vendorModel,
                                        ),
                                        const SizedBox(height: 1),
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
                          ),
                        ),
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

  Widget _buildDeliveryTimeAndFastRow(VendorModel vendorModel) {
    final deliveryTime = Constant.getDeliveryTimeText(vendorModel);
    return SizedBox(
      height: 12,
      child: _TimeThenFastDeliveryWidget(deliveryTime: deliveryTime),
    );
  }

  Widget _buildBottomInfoRow(VendorModel vendorModel) {
    // Prefer precomputed/API distance when available; fall back to live calculation
    String distanceText;
    if (vendorModel.distance != null && vendorModel.distance! > 0) {
      distanceText =
          '${vendorModel.distance!.toStringAsFixed(1)} ${Constant.distanceType}';
    } else {
      distanceText =
          '${Constant.getDistanceFromVendor(vendorModel)} ${Constant.distanceType}';
    }

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(Icons.star, size: 12, color: AppThemeData.primary300),
              const SizedBox(width: 1),
              Expanded(
                child: Text(
                  "${Constant.calculateReview(reviewCount: vendorModel.reviewsCount.toString(), reviewSum: vendorModel.reviewsSum.toString())}",
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
                  distanceText,
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
    );
  }
}

/// First shows delivery time; after 2 seconds replaces with "Fast delivery" in the same place (looping).
class _TimeThenFastDeliveryWidget extends StatefulWidget {
  final String deliveryTime;

  const _TimeThenFastDeliveryWidget({required this.deliveryTime});

  @override
  State<_TimeThenFastDeliveryWidget> createState() =>
      _TimeThenFastDeliveryWidgetState();
}

class _TimeThenFastDeliveryWidgetState
    extends State<_TimeThenFastDeliveryWidget> {
  bool _showFastDelivery = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() => _showFastDelivery = !_showFastDelivery);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _showFastDelivery
            ? Row(
                key: const ValueKey('fast'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delivery_dining,
                    size: 10,
                    color: AppThemeData.primary300,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Fast delivery',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: AppThemeData.medium,
                      color: AppThemeData.primary300,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : Text(
                key: const ValueKey('time'),
                widget.deliveryTime,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: AppThemeData.medium,
                  color: AppThemeData.primary300,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}
