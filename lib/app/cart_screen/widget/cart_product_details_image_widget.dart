import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/cart_product_model.dart'
    show CartProductModel;
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart' show AppThemeData;
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../constant/show_toast_dialog.dart';

Widget cartProductDetailsImageWidget(CartControllerProvider controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 0),
    child: Container(
      decoration: ShapeDecoration(
        color: AppThemeData.grey50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: HomeProvider.cartItem.length,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            CartProductModel cartProductModel = HomeProvider.cartItem[index];
            String? productId;
            if (cartProductModel.id != null &&
                cartProductModel.id!.isNotEmpty &&
                cartProductModel.id!.toLowerCase() != 'null') {
              final parts = cartProductModel.id!.split('~');
              if (parts.isNotEmpty &&
                  parts.first.isNotEmpty &&
                  parts.first.toLowerCase() != 'null') {
                productId = parts.first;
              }
            }
            if (productId == null ||
                productId.isEmpty ||
                productId.trim().isEmpty ||
                productId.toLowerCase() == 'null') {
              if (cartProductModel.id != null &&
                  cartProductModel.id!.toLowerCase() != 'null') {
                print(
                  '[CART_PRODUCT] Invalid or null product ID: ${cartProductModel.id}',
                );
              }
              return _buildProductItem(cartProductModel, null, controller);
            }

            // Use cached product from controller - no FutureBuilder needed!
            final cachedProduct = controller.getCachedProduct(productId);

            // Check if this is a mart item (mart items use cart data, not ProductModel)
            final isMartItem =
                cartProductModel.vendorID?.startsWith('mart_') == true ||
                cartProductModel.vendorID?.toLowerCase().contains('mart') ==
                    true;

            // If product is not cached yet and it's not a mart item
            if (cachedProduct == null &&
                !isMartItem &&
                !controller.productsLoaded) {
              // Trigger load if not already loading (loads in background)
              if (!controller.isLoadingProducts) {
                controller.preloadCartProducts();
              }
              // Show shimmer only while actively loading restaurant items
              if (controller.isLoadingProducts) {
                return _buildProductShimmer(cartProductModel);
              }
            }

            // Show product item:
            // - For restaurant items: use cachedProduct (may be null if still loading)
            // - For mart items: cachedProduct will be null, use cartProductModel data
            return _buildProductItem(
              cartProductModel,
              cachedProduct,
              controller,
            );
          },
        ),
      ),
    ),
  );
}

Widget _buildProductItem(
  CartProductModel cartProductModel,
  ProductModel? productModel,
  CartControllerProvider controller,
) {
  return Consumer2<RestaurantDetailsProvider, CartControllerProvider>(
    builder: (context, restaurantDetailsProvider, cartController, _) {
      // Use priceSyncVersion to force rebuild when prices update
      final _ = cartController.priceSyncVersion;
      final productPhoto = productModel?.photo?.isNotEmpty == true
          ? productModel!.photo
          : (cartProductModel.photo?.isNotEmpty == true
                ? cartProductModel.photo
                : null);
      final productName = productModel?.name?.isNotEmpty == true
          ? productModel!.name
          : (cartProductModel.name?.isNotEmpty == true
                ? cartProductModel.name
                : 'Product');

      // Check if this is a promotional item
      final isPromotional =
          cartProductModel.promoId != null &&
          cartProductModel.promoId!.isNotEmpty;

      // Get prices
      final price = double.tryParse(cartProductModel.price ?? '0') ?? 0.0;
      final discountPrice =
          double.tryParse(cartProductModel.discountPrice ?? '0') ?? 0.0;

      // For promotional items, the promotional price is in the 'price' field
      // and the original price is in 'discountPrice'
      // For regular items with discount, discountPrice is the discounted price
      // and price is the original price

      double finalPrice;
      double originalPriceForComparison;

      if (isPromotional) {
        // Promotional item: price = promotional price, discountPrice = original price
        finalPrice = price;
        originalPriceForComparison = discountPrice;
      } else if (discountPrice > 0 && discountPrice < price) {
        // Regular item with discount: discountPrice = discounted price, price = original price
        finalPrice = discountPrice;
        originalPriceForComparison = price;
      } else {
        // Regular item without discount
        finalPrice = price;
        originalPriceForComparison = 0.0; // No original price for comparison
      }

      final quantity = cartProductModel.quantity ?? 1;
      final totalPrice = finalPrice * quantity;
      final showOriginalPrice =
          isPromotional &&
          originalPriceForComparison > 0 &&
          originalPriceForComparison > finalPrice;

      return InkWell(
        onTap: () async {
          if (productModel != null) {
            await FireStoreUtils.getVendorById(
              productModel.vendorID.toString(),
            ).then((value) {
              if (value != null) {
                restaurantDetailsProvider.initFunction(vendorModels: value);
                Get.to(const RestaurantDetailsScreen());
              }
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with Promotional Badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: productPhoto != null && productPhoto.isNotEmpty
                        ? Image.network(
                            productPhoto,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 60,
                                  height: 60,
                                  color: AppThemeData.grey200,
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: AppThemeData.grey400,
                                    size: 30,
                                  ),
                                ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 60,
                                height: 60,
                                color: AppThemeData.grey200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: AppThemeData.grey200,
                            child: Icon(
                              Icons.image_not_supported,
                              color: AppThemeData.grey400,
                              size: 30,
                            ),
                          ),
                  ),

                  // Promotional Badge
                  if (isPromotional)
                    Positioned(
                      top: -5,
                      left: -5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Special Offer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name with Promotional Indicator
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            productName ?? 'Product',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: AppThemeData.semiBold,
                              color: AppThemeData.grey900,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Promotional Tag
                        if (isPromotional)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'OFFER',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontFamily: AppThemeData.semiBold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Price Display
                    Row(
                      children: [
                        // Final Price (promotional or discounted)
                        Text(
                          '${Constant.currencyModel?.symbol ?? '₹'}${finalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: AppThemeData.semiBold,
                            color: isPromotional
                                ? Colors.red
                                : AppThemeData.primary300,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        // Original Price with strikethrough
                        if (showOriginalPrice) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${Constant.currencyModel?.symbol ?? '₹'}${originalPriceForComparison.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: AppThemeData.regular,
                              color: AppThemeData.grey500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),

                          // Discount percentage for promotional items
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '${((originalPriceForComparison - finalPrice) / originalPriceForComparison * 100).round()}% OFF',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontFamily: AppThemeData.semiBold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Quantity Controls
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppThemeData.grey100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Decrease Button
                              InkWell(
                                onTap: () {
                                  cartController.addToCart(
                                    cartProductModel: cartProductModel,
                                    isIncrement: false,
                                    quantity: quantity > 1 ? quantity - 1 : 0,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.remove,
                                    size: 16,
                                    color: AppThemeData.grey900,
                                  ),
                                ),
                              ),

                              // Quantity Display
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  '$quantity',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: AppThemeData.semiBold,
                                    color: AppThemeData.grey900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              // Increase Button with promotional quantity check
                              InkWell(
                                onTap: () {
                                  // Check promotional quantity limits
                                  if (isPromotional) {
                                    final isAllowed = cartController
                                        .isPromotionalItemQuantityAllowed(
                                          cartProductModel.id ?? '',
                                          cartProductModel.vendorID ?? '',
                                          quantity + 1,
                                        );

                                    if (!isAllowed) {
                                      final limit = cartController
                                          .getPromotionalItemLimit(
                                            cartProductModel.id ?? '',
                                            cartProductModel.vendorID ?? '',
                                          );
                                      ShowToastDialog.showToast(
                                        "Maximum $limit items allowed for this promotional offer"
                                            .tr,
                                      );
                                      return;
                                    }
                                  }

                                  cartController.addToCart(
                                    cartProductModel: cartProductModel,
                                    isIncrement: true,
                                    quantity: quantity + 1,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.add,
                                    size: 16,
                                    color: AppThemeData.grey900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Total Price
                        Text(
                          '${Constant.currencyModel?.symbol ?? '₹'}${totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: AppThemeData.semiBold,
                            color: AppThemeData.grey900,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    // Variants and Add-ons if any
                    // if (cartProductModel.variantInfo != null &&
                    //     cartProductModel.variantInfo!.variantName != null)
                    //   Padding(
                    //     padding: const EdgeInsets.only(top: 4),
                    //     child: Text(
                    //       'Variant: ${cartProductModel.variantInfo!.variantName}',
                    //       style: TextStyle(
                    //         fontSize: 11,
                    //         fontFamily: AppThemeData.regular,
                    //         color: AppThemeData.grey500,
                    //         fontStyle: FontStyle.italic,
                    //       ),
                    //       maxLines: 1,
                    //       overflow: TextOverflow.ellipsis,
                    //     ),
                    //   ),
                    if (cartProductModel.extras != null &&
                        cartProductModel.extras!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Add-ons: ${cartProductModel.extras!.map((e) => e.title ?? '').where((title) => title.isNotEmpty).join(', ')}',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: AppThemeData.regular,
                            color: AppThemeData.grey500,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildProductShimmer(CartProductModel cartProductModel) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 60, height: 60, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      color: Colors.white,
                    ),
                    SizedBox(height: 4),
                    Container(width: 100, height: 14, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
