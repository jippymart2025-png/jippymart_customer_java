import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/promotion_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';

import '../../../core/responsive.dart';
import 'DeliveryTicker.dart';
import 'PromotionCard.dart';
import 'appbar.dart';

/// One restaurant's card: header (logo, name, rating, delivery time,
/// deal count) plus a horizontal scroll of its promoted products.
class RestaurantSection extends StatelessWidget {
  const RestaurantSection({
    super.key,
    required this.vendorId,
    required this.vendor,
    required this.promotions,
    required this.isOpen,
    required this.productCache,
    required this.vendorCache,
    required this.restaurantStatusCache,
    required this.rs,
  });

  final String vendorId;
  final VendorModel? vendor;
  final List<PromotionModel> promotions;
  final bool isOpen;
  final Map<String, ProductModel> productCache;
  final Map<String, VendorModel> vendorCache;
  final Map<String, bool> restaurantStatusCache;
  final Responsive rs;

  String get _name =>
      vendor?.title ??
      (promotions.isNotEmpty ? promotions.first.restaurantTitle : 'Restaurant');

  String get _deliveryTime =>
      vendor != null ? Constant.getDeliveryTimeText(vendor!) : '30–35 mins';

  void _openRestaurant(BuildContext context) {
    if (vendor == null) return;
    Provider.of<RestaurantDetailsProvider>(
      context,
      listen: false,
    ).initFunction(vendorModels: vendor!);
    Get.to(() => const RestaurantDetailsScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(rs.hPad, 0, rs.hPad, 10),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x122D1B4E),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openRestaurant(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Row(
                children: [
                  _VendorLogo(vendor: vendor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: TextStyle(
                            fontSize: rs.restNameFs,
                            fontWeight: FontWeight.w800,
                            color: C.text1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 3,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: C.green,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    '4.5',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DeliveryTicker(deliveryTime: _deliveryTime),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: C.brandLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${promotions.length} deals ›',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: C.brand,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: rs.prodScrollH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: promotions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) => RepaintBoundary(
                child: PromotionCard(
                  key: ValueKey(promotions[i].productId),
                  promotion: promotions[i],
                  productCache: productCache,
                  vendorCache: vendorCache,
                  restaurantStatusCache: restaurantStatusCache,
                  rs: rs,
                  animIndex: i,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorLogo extends StatelessWidget {
  const _VendorLogo({required this.vendor});

  final VendorModel? vendor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: C.brandLight,
        shape: BoxShape.circle,
        border: Border.all(color: C.border, width: 1.5),
      ),
      child: ClipOval(
        child: vendor?.photo != null && vendor!.photo!.isNotEmpty
            ? Image.network(
                vendor!.photo!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _FoodPlaceholder(),
              )
            : const _FoodPlaceholder(),
      ),
    );
  }
}

class _FoodPlaceholder extends StatelessWidget {
  const _FoodPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: C.brandLight,
      alignment: Alignment.center,
      child: const Icon(Icons.fastfood_rounded, size: 20, color: C.brand),
    );
  }
}
