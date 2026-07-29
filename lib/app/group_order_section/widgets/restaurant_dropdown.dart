import 'package:flutter/material.dart';

import '../../../../../models/vendor_model.dart';
import '../../../../../themes/app_them_data.dart';
import '../../../../../widget/restaurant_image_with_status.dart';
import '../model/create_group_orders_model.dart';

class RestaurantDropdown extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final VendorModel? selectedVendor;
  final SelectedRestaurant? selectedRestaurant;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  const RestaurantDropdown({
    super.key,
    required this.isLoading,
    required this.error,
    required this.selectedVendor,
    required this.selectedRestaurant,
    required this.onTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppThemeData.grey100),
        ),
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B2C),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppThemeData.grey100),
        ),
        child: Column(
          children: [
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppThemeData.medium,
                color: AppThemeData.grey600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Color(0xFFFF6B2C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppThemeData.grey100),
        ),
        child: Row(
          children: [
            if (selectedRestaurant != null && selectedVendor != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: RestaurantImageWithStatus(
                  vendorModel: selectedVendor!,
                  width: 44,
                  height: 44,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedRestaurant!.name,
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
                      '${selectedRestaurant!.rating} • ${selectedRestaurant!.etaLabel}',
                      style: TextStyle(
                        fontFamily: AppThemeData.medium,
                        color: AppThemeData.grey500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Expanded(
                child: Text(
                  'Select a restaurant',
                  style: TextStyle(
                    fontFamily: AppThemeData.medium,
                    color: AppThemeData.grey500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppThemeData.grey600,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
