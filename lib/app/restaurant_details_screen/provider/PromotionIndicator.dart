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

        if (!hasPromotion) {
          return child ?? const SizedBox.shrink();
        }

        final promoData = controller.getActivePromotionForProduct(
          productId: productId,
          restaurantId: restaurantId,
        );

        String badgeText = 'SPECIAL OFFER';
        if (promoData != null) {
          final offerName = promoData['offerName'] ?? promoData['offer_name'];
          final planType = promoData['planType'] ?? promoData['plan_type'];
          final discountAmount = promoData['discountAmount'] ?? promoData['discount'];
          final priceType = promoData['priceType'] ?? promoData['price_type'];

          if (offerName != null && offerName.toString().isNotEmpty) {
            badgeText = offerName.toString();
          } else if (planType != null && planType.toString().isNotEmpty) {
            badgeText = planType.toString();
          } else if (discountAmount != null) {
            badgeText = priceType == 'PERCENTAGE'
                ? '$discountAmount% OFF'
                : '₹$discountAmount OFF';
          }
        }

        return Stack(
          children: [
            if (child != null) child!,
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
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  badgeText.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
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
