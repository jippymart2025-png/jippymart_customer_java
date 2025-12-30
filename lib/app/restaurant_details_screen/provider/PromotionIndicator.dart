import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';

class PromotionIndicator extends StatelessWidget {
  final String productId;
  final String restaurantId;
  final Widget? child;

  const PromotionIndicator({
    super.key,
    required this.productId,
    required this.restaurantId,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (productId.isEmpty || restaurantId.isEmpty) {
      return child ?? const SizedBox.shrink();
    }

    return Consumer<RestaurantDetailsProvider>(
      builder: (context, controller, _) {
        final hasPromotion = controller.hasActivePromotion(
          productId,
          restaurantId,
        );

        return Stack(
          children: [
            if (child != null) child!,
            if (hasPromotion)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
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
                ),
              ),
          ],
        );
      },
    );
  }
}
