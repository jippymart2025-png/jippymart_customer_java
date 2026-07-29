import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../models/vendor_model.dart';
import '../../../../../themes/app_them_data.dart';
import '../../../../../widget/restaurant_image_with_status.dart';
import '../model/create_group_orders_model.dart';

Widget buildRestaurantTile(
  VendorModel vendor, {
  required bool isSelected,
  required VoidCallback onSelected,
}) {
  final restaurant = SelectedRestaurant.fromVendorModel(vendor);

  return InkWell(
    onTap: onSelected,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFF1E6) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF6B2C) : AppThemeData.grey100,
          width: isSelected ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: RestaurantImageWithStatus(
              vendorModel: vendor,
              width: 52,
              height: 52,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppThemeData.semiBold,
                    color: AppThemeData.grey900,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${restaurant.rating} • ${restaurant.etaLabel}',
                  style: TextStyle(
                    fontFamily: AppThemeData.medium,
                    color: AppThemeData.grey500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isSelected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: isSelected ? const Color(0xFFFF6B2C) : AppThemeData.grey400,
            size: 22,
          ),
        ],
      ),
    ),
  );
}
