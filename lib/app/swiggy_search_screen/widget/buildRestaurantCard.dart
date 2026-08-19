import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart'
    show GetNavigation;
import 'package:provider/provider.dart';
import '../../../models/vendor_model.dart';
import '../../../themes/app_them_data.dart';
import '../../../utils/restaurant_status_utils.dart';
import '../../restaurant_details_screen/provider/restaurant_details_provider.dart';
import '../../restaurant_details_screen/restaurant_details_screen.dart';

Widget buildRestaurantCard(VendorModel restaurant, BuildContext context) {
  return RepaintBoundary(
    child: Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppThemeData.grey50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                context.read<RestaurantDetailsProvider>().initFunction(
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
                      child: const Center(child: CircularProgressIndicator()),
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
                    restaurant.distance as String ?? 'Location not available',
                    style: TextStyle(fontSize: 14, color: AppThemeData.grey400),
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
    ),
  );
}
