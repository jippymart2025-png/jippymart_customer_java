import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';

class PromotionBadge extends StatelessWidget {
  final String productId;
  final String restaurantId;

  const PromotionBadge({
    super.key,
    required this.productId,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    if (productId.isEmpty || restaurantId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Consumer<RestaurantDetailsProvider>(
      builder: (context, controller, _) {
        // FAST: Just check if promotion exists
        final hasPromo = controller.hasActivePromotion(productId, restaurantId);

        if (!hasPromo) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'SPECIAL OFFER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
