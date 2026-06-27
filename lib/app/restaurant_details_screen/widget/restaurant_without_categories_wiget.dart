import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/constant/constant.dart'
    show Constant, cartItem;
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/widget/special_price_badge.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/widget/resturant_product_details_view.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/widget/product_options_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../constant/show_toast_dialog.dart';

Widget buildProductsWithoutCategories(
  BuildContext context,
  RestaurantDetailsProvider controller,
) {
  return ListView.builder(
    itemCount: controller.productList.length,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.zero,
    itemBuilder: (context, index) {
      ProductModel productModel = controller.productList[index];

      bool isItemAvailable = productModel.isAvailable ?? true;
      String price = "0.0";
      String disPrice = "0.0";
      List<String> selectedVariants = [];
      List<String> selectedIndexVariants = [];
      List<String> selectedIndexArray = [];
      final hasItemAttributes =
          productModel.itemAttribute != null &&
          productModel.itemAttribute!.attributes != null &&
          productModel.itemAttribute!.attributes!.isNotEmpty;
      final hasOptionsOnly =
          productModel.options != null &&
          productModel.options!.isNotEmpty &&
          !hasItemAttributes;

      if (productModel.itemAttribute != null) {
        if (productModel.itemAttribute!.attributes!.isNotEmpty) {
          for (var element in productModel.itemAttribute!.attributes!) {
            if (element.attributeOptions!.isNotEmpty) {
              selectedVariants.add(
                productModel
                    .itemAttribute!
                    .attributes![productModel.itemAttribute!.attributes!
                        .indexOf(element)]
                    .attributeOptions![0]
                    .toString(),
              );
              selectedIndexVariants.add(
                '${productModel.itemAttribute!.attributes!.indexOf(element)} _${productModel.itemAttribute!.attributes![0].attributeOptions![0].toString()}',
              );
              selectedIndexArray.add(
                '${productModel.itemAttribute!.attributes!.indexOf(element)}_0',
              );
            }
          }
        }
        if (productModel.itemAttribute!.variants!
            .where(
              (element) => element.variantSku == selectedVariants.join('-'),
            )
            .isNotEmpty) {
          price = Constant.productCommissionPrice(
            controller.vendorModel,
            productModel.itemAttribute!.variants!
                    .where(
                      (element) =>
                          element.variantSku == selectedVariants.join('-'),
                    )
                    .first
                    .variantPrice ??
                '0',
          );
          disPrice = "0";
        }
      } else {
        // FIXED: Safe price parsing
        price = Constant.productCommissionPrice(
          controller.vendorModel,
          productModel.price?.toString() ?? '0',
        );

        // FIXED: Safe discount price handling
        final discountPriceStr = productModel.disPrice?.toString();
        if (discountPriceStr == null ||
            discountPriceStr.isEmpty ||
            discountPriceStr == 'null') {
          disPrice = "0";
        } else {
          final discountPriceValue = double.tryParse(discountPriceStr) ?? 0.0;
          disPrice = discountPriceValue <= 0
              ? "0"
              : Constant.productCommissionPrice(
                  controller.vendorModel,
                  discountPriceStr,
                );
        }
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      productModel.nonveg == true
                          ? SvgPicture.asset("assets/icons/ic_nonveg.svg")
                          : SvgPicture.asset("assets/icons/ic_veg.svg"),
                      const SizedBox(width: 5),
                      Text(
                        productModel.nonveg == true
                            ? "Non Veg.".tr
                            : "Pure veg.".tr,
                        style: TextStyle(
                          color: productModel.nonveg == true
                              ? AppThemeData.danger300
                              : AppThemeData.success400,
                          fontFamily: AppThemeData.semiBold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                productModel.name.toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppThemeData.grey900,
                                  fontFamily: AppThemeData.semiBold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Use cached promotion data - no server/Firestore calls
                            if (productModel.id != null &&
                                productModel.vendorID != null &&
                                controller.hasActivePromotion(
                                  productModel.id!.toString(),
                                  productModel.vendorID!,
                                ))
                              Container(
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
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (context) {
                          // Use cached data - no async/network calls
                          final promo =
                              productModel.id != null &&
                                  productModel.vendorID != null
                              ? controller.getActivePromotionForProduct(
                                  productId: productModel.id!.toString(),
                                  restaurantId: productModel.vendorID!,
                                )
                              : null;
                          final hasPromo = promo != null;
                          final promoPrice = hasPromo
                              ? (promo['special_price'] as num).toString()
                              : null;

                          if (hasPromo) {
                            // Special promotional price display
                            return Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    Constant.amountShow(amount: promoPrice!),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppThemeData.grey900,
                                      fontFamily: AppThemeData.semiBold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                // Show original price with strikethrough
                                Flexible(
                                  child: Text(
                                    Constant.amountShow(
                                      amount: Constant.productCommissionPrice(
                                        controller.vendorModel,
                                        productModel.price.toString(),
                                      ),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: AppThemeData.grey400,
                                      color: AppThemeData.grey400,
                                      fontFamily: AppThemeData.semiBold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else if (double.parse(disPrice) <= 0) {
                            // Normal price display
                            return Text(
                              Constant.amountShow(amount: price),
                              style: TextStyle(
                                fontSize: 16,
                                color: AppThemeData.grey900,
                                fontFamily: AppThemeData.semiBold,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          } else {
                            // Regular discount price display
                            return Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    Constant.amountShow(amount: disPrice),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppThemeData.grey900,
                                      fontFamily: AppThemeData.semiBold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    Constant.amountShow(amount: price),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: AppThemeData.grey400,
                                      color: AppThemeData.grey400,
                                      fontFamily: AppThemeData.semiBold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      if (!isItemAvailable)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Not Available",
                            style: TextStyle(
                              color: Colors.red,
                              fontFamily: AppThemeData.medium,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      SvgPicture.asset(
                        "assets/icons/ic_star.svg",
                        colorFilter: const ColorFilter.mode(
                          AppThemeData.warning300,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "${Constant.calculateReview(reviewCount: productModel.reviewsCount!.toStringAsFixed(0), reviewSum: productModel.reviewsSum.toString())} (${productModel.reviewsCount!.toStringAsFixed(0)})",
                        style: TextStyle(
                          color: AppThemeData.grey900,
                          fontFamily: AppThemeData.regular,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "${productModel.description}",
                    maxLines: 2,
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      color: AppThemeData.grey900,
                      fontFamily: AppThemeData.regular,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  child: ColorFiltered(
                    colorFilter: isItemAvailable
                        ? const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.multiply,
                          )
                        : const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          ),
                    child: NetworkImageWidget(
                      imageUrl: productModel.photo.toString(),
                      fit: BoxFit.cover,
                      height: Responsive.height(16, context),
                      width: Responsive.width(34, context),
                    ),
                  ),
                ),
                // Special promotional price badge - use cached data, no server calls
                if (productModel.id != null &&
                    productModel.vendorID != null &&
                    controller.hasActivePromotion(
                      productModel.id!.toString(),
                      productModel.vendorID!,
                    ))
                  Positioned(
                    top: 0,
                    left: 0,
                    child: const SpecialPriceBadge(
                      showShimmer: true,
                      width: 60,
                      height: 60,
                      margin: EdgeInsets.zero,
                    ),
                  ),
                if (!isItemAvailable)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: InkWell(
                    onTap: () async {
                      await controller.toggleProductFavorite(
                        productModel.id.toString(),
                      );
                    },
                    child:
                        controller.isProductFavorite(productModel.id.toString())
                        ? SvgPicture.asset("assets/icons/ic_like_fill.svg")
                        : SvgPicture.asset("assets/icons/ic_like.svg"),
                  ),
                ),
                !controller.canAcceptOrders() || Constant.userModel == null
                    ? const SizedBox()
                    : Positioned(
                        bottom: 10,
                        left: 20,
                        right: 20,
                        child: isItemAvailable
                            ? selectedVariants.isNotEmpty ||
                                      (productModel.addOnsTitle != null &&
                                          productModel
                                              .addOnsTitle!
                                              .isNotEmpty) ||
                                      (productModel.options != null &&
                                          productModel.options!.isNotEmpty)
                                  ? RoundedButtonFill(
                                      title:
                                          (productModel.options != null &&
                                              productModel
                                                  .options!
                                                  .isNotEmpty &&
                                              selectedVariants.isEmpty)
                                          ? "Options".tr
                                          : "Add".tr,
                                      width: 10,
                                      height: 4,
                                      color: AppThemeData.grey50,
                                      textColor: AppThemeData.primary300,
                                      onPress: () async {
                                        controller.selectedVariants.clear();
                                        controller.selectedIndexVariants
                                            .clear();
                                        controller.selectedIndexArray.clear();
                                        controller.selectedAddOns.clear();
                                        controller.quantity = 1;
                                        if (productModel.itemAttribute !=
                                            null) {
                                          if (productModel
                                              .itemAttribute!
                                              .attributes!
                                              .isNotEmpty) {
                                            for (var element
                                                in productModel
                                                    .itemAttribute!
                                                    .attributes!) {
                                              if (element
                                                  .attributeOptions!
                                                  .isNotEmpty) {
                                                controller.selectedVariants.add(
                                                  productModel
                                                      .itemAttribute!
                                                      .attributes![productModel
                                                          .itemAttribute!
                                                          .attributes!
                                                          .indexOf(element)]
                                                      .attributeOptions![0]
                                                      .toString(),
                                                );
                                                controller.selectedIndexVariants
                                                    .add(
                                                      '${productModel.itemAttribute!.attributes!.indexOf(element)} _${productModel.itemAttribute!.attributes![0].attributeOptions![0].toString()}',
                                                    );
                                                controller.selectedIndexArray.add(
                                                  '${productModel.itemAttribute!.attributes!.indexOf(element)}_0',
                                                );
                                              }
                                            }
                                          }
                                          final bool productIsInList =
                                              HomeProvider.cartItem.any(
                                                (product) =>
                                                    product.id ==
                                                    "${productModel.id}~${productModel.itemAttribute!.variants!.where((element) => element.variantSku == controller.selectedVariants.join('-')).isNotEmpty ? productModel.itemAttribute!.variants!.where((element) => element.variantSku == controller.selectedVariants.join('-')).first.variantId.toString() : ""}",
                                              );

                                          if (productIsInList) {
                                            CartProductModel
                                            element = HomeProvider.cartItem
                                                .firstWhere(
                                                  (product) =>
                                                      product.id ==
                                                      "${productModel.id}~${productModel.itemAttribute!.variants!.where((element) => element.variantSku == controller.selectedVariants.join('-')).isNotEmpty ? productModel.itemAttribute!.variants!.where((element) => element.variantSku == controller.selectedVariants.join('-')).first.variantId.toString() : ""}",
                                                );
                                            controller.quantity =
                                                element.quantity!;
                                          } else {
                                            controller.quantity = 1;
                                          }
                                        }

                                        controller.calculatePrice(productModel);
                                        if (hasOptionsOnly) {
                                          showProductOptionsBottomSheet(
                                            context: context,
                                            controller: controller,
                                            productModel: productModel,
                                            priceToPass: price,
                                            disPriceToPass: disPrice,
                                            buttonFontSize: 14,
                                          );
                                        } else {
                                          _showProductDetailsBottomSheet(
                                            context,
                                            productModel,
                                          );
                                        }
                                      },
                                    )
                                  : controller.isProductInCart(
                                      productModel.id ?? '',
                                    )
                                  ? Container(
                                      width: Responsive.width(120, context),
                                      height: Responsive.height(4.5, context),
                                      decoration: ShapeDecoration(
                                        color: AppThemeData.grey50,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            200,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: InkWell(
                                              onTap: () async {
                                                // Check for promotional price
                                                // Use cached promotion - no server call
                                                final promo = controller
                                                    .getActivePromotionForProduct(
                                                      productId:
                                                          productModel.id
                                                              .toString() ??
                                                          '',
                                                      restaurantId:
                                                          productModel
                                                              .vendorID ??
                                                          '',
                                                    );

                                                String finalPrice = price;
                                                String finalDiscountPrice =
                                                    disPrice;

                                                if (promo != null) {
                                                  // Use promotional price
                                                  finalPrice =
                                                      (promo['special_price']
                                                              as num)
                                                          .toString();
                                                  finalDiscountPrice =
                                                      Constant.productCommissionPrice(
                                                        controller.vendorModel,
                                                        productModel.price
                                                            .toString(),
                                                      ); // original price for strikethrough
                                                }

                                                controller.addToCart(
                                                  productModel: productModel,
                                                  price: finalPrice,
                                                  discountPrice:
                                                      finalDiscountPrice,
                                                  isIncrement: false,
                                                  quantity:
                                                      controller.productQuantityInCart(
                                                        productModel.id ?? '',
                                                      ) -
                                                      1,
                                                );
                                              },
                                              child: const Icon(Icons.remove),
                                            ),
                                          ),
                                          Flexible(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              child: Text(
                                                controller
                                                    .productQuantityInCart(
                                                      productModel.id ?? '',
                                                    )
                                                    .toString(),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                style: TextStyle(
                                                  fontSize:
                                                      controller
                                                              .productQuantityInCart(
                                                                productModel
                                                                        .id ??
                                                                    '',
                                                              )
                                                              .toString()
                                                              .length >
                                                          2
                                                      ? 12
                                                      : 16,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  fontFamily:
                                                      AppThemeData.medium,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppThemeData.grey800,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Flexible(
                                            child: InkWell(
                                              onTap: () async {
                                                if ((controller.productQuantityInCart(
                                                              productModel.id ??
                                                                  '',
                                                            )) <=
                                                        (productModel
                                                                .quantity ??
                                                            0) ||
                                                    (productModel.quantity ??
                                                            0) ==
                                                        -1) {
                                                  // Check for promotional price and limit (ULTRA-FAST - ZERO ASYNC)
                                                  final promo = controller
                                                      .getActivePromotionForProduct(
                                                        productId:
                                                            productModel.id
                                                                .toString() ??
                                                            '',
                                                        restaurantId:
                                                            productModel
                                                                .vendorID ??
                                                            '',
                                                      );

                                                  // Check promotional item limit using new helper method
                                                  if (promo != null) {
                                                    final isAllowed = controller
                                                        .isPromotionalItemQuantityAllowed(
                                                          productModel.id
                                                                  .toString() ??
                                                              '',
                                                          productModel
                                                                  .vendorID ??
                                                              '',
                                                          controller.productQuantityInCart(
                                                                  productModel
                                                                          .id ??
                                                                      '',
                                                                ) +
                                                              1,
                                                        );

                                                    if (!isAllowed) {
                                                      final limit = controller
                                                          .getPromotionalItemLimit(
                                                            productModel.id
                                                                    .toString() ??
                                                                '',
                                                            productModel
                                                                    .vendorID ??
                                                                '',
                                                          );
                                                      ShowToastDialog.showToast(
                                                        "Maximum $limit items allowed for this promotional offer"
                                                            .tr,
                                                      );
                                                      return;
                                                    }
                                                  }

                                                  String finalPrice = price;
                                                  String finalDiscountPrice =
                                                      disPrice;

                                                  if (promo != null) {
                                                    // Use promotional price
                                                    finalPrice =
                                                        (promo['special_price']
                                                                as num)
                                                            .toString();
                                                    finalDiscountPrice =
                                                        Constant.productCommissionPrice(
                                                          controller
                                                              .vendorModel,
                                                          productModel.price
                                                              .toString(),
                                                        ); // original price for strikethrough
                                                  }

                                                  controller.addToCart(
                                                    productModel: productModel,
                                                    price: finalPrice,
                                                    discountPrice:
                                                        finalDiscountPrice,
                                                    isIncrement: true,
                                                    quantity:
                                                        HomeProvider.cartItem
                                                            .where(
                                                              (p0) =>
                                                                  p0.id ==
                                                                  productModel
                                                                      .id,
                                                            )
                                                            .first
                                                            .quantity! +
                                                        1,
                                                  );
                                                } else {
                                                  ShowToastDialog.showToast(
                                                    "Out of stock".tr,
                                                  );
                                                }
                                              },
                                              child: const Icon(Icons.add),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  //changed here
                                  : RoundedButtonFill(
                                      title: "Add".tr,
                                      width: 10,
                                      height: 4,
                                      color: AppThemeData.grey50,
                                      textColor: AppThemeData.primary300,
                                      onPress: () async {
                                        if (1 <= (productModel.quantity ?? 0) ||
                                            (productModel.quantity ?? 0) ==
                                                -1) {
                                          // Check for promotional price and limit (ULTRA-FAST - ZERO ASYNC)
                                          final promo = controller
                                              .getActivePromotionForProduct(
                                                productId:
                                                    productModel.id
                                                        .toString() ??
                                                    '',
                                                restaurantId:
                                                    productModel.vendorID ?? '',
                                              );

                                          // Check promotional item limit using new helper method
                                          if (promo != null) {
                                            final isAllowed = controller
                                                .isPromotionalItemQuantityAllowed(
                                                  productModel.id.toString() ??
                                                      '',
                                                  productModel.vendorID ?? '',
                                                  1,
                                                );

                                            if (!isAllowed) {
                                              final limit = controller
                                                  .getPromotionalItemLimit(
                                                    productModel.id
                                                            .toString() ??
                                                        '',
                                                    productModel.vendorID ?? '',
                                                  );
                                              ShowToastDialog.showToast(
                                                "Maximum $limit items allowed for this promotional offer"
                                                    .tr,
                                              );
                                              return;
                                            }
                                          }
                                          String finalPrice = price;
                                          String finalDiscountPrice = disPrice;

                                          if (promo != null) {
                                            // Use promotional price
                                            finalPrice =
                                                (promo['special_price'] as num)
                                                    .toString();
                                            finalDiscountPrice =
                                                Constant.productCommissionPrice(
                                                  controller.vendorModel,
                                                  productModel.price.toString(),
                                                ); // original price for strikethrough
                                          }
                                          controller.addToCart(
                                            productModel: productModel,
                                            price: finalPrice,
                                            discountPrice: finalDiscountPrice,
                                            isIncrement: true,
                                            quantity: 1,
                                          );
                                        } else {
                                          ShowToastDialog.showToast(
                                            "Out of stock".tr,
                                          );
                                        }
                                      },
                                    )
                            : const SizedBox(),
                      ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

void _showProductDetailsBottomSheet(
  BuildContext context,
  ProductModel productModel,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    clipBehavior: Clip.antiAliasWithSaveLayer,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.85,
      child: StatefulBuilder(
        builder: (context1, setState) =>
            ProductDetailsView(productModel: productModel),
      ),
    ),
  );
}

void _showOptionsBottomSheet({
  required BuildContext context,
  required RestaurantDetailsProvider controller,
  required ProductModel productModel,
  required String price,
  required String disPrice,
}) {
  final options = productModel.options ?? [];
  final hasOptions = options.isNotEmpty;
  final hasAddOns =
      productModel.addOnsTitle != null &&
      productModel.addOnsTitle!.isNotEmpty &&
      productModel.addOnsPrice != null &&
      productModel.addOnsPrice!.isNotEmpty;

  if (!hasOptions && !hasAddOns) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final Set<int> selectedOptionIndices = hasOptions ? {0} : <int>{};
      final Set<int> selectedAddonIndices = <int>{};

      return StatefulBuilder(
        builder: (context, setState) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppThemeData.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppThemeData.grey300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        productModel.name ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: AppThemeData.semiBold,
                          fontWeight: FontWeight.w600,
                          color: AppThemeData.grey900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 340),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasOptions) ...[
                                Text(
                                  'Choose options'.tr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: AppThemeData.semiBold,
                                    color: AppThemeData.grey800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: options.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (context, index) {
                                    final option = options[index];
                                    final disabled =
                                        option.isAvailable == false ||
                                        option.price == null;
                                    final isSelected = selectedOptionIndices
                                        .contains(index);
                                    final priceText = Constant.amountShow(
                                      amount: Constant.productCommissionPrice(
                                        controller.vendorModel,
                                        option.price ?? '0',
                                      ),
                                    );

                                    return InkWell(
                                      onTap: disabled
                                          ? null
                                          : () {
                                              setState(() {
                                                if (isSelected) {
                                                  selectedOptionIndices.remove(
                                                    index,
                                                  );
                                                } else {
                                                  selectedOptionIndices.add(
                                                    index,
                                                  );
                                                }
                                              });
                                            },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppThemeData.primary300
                                                    .withOpacity(0.06)
                                              : AppThemeData.grey50,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppThemeData.primary300
                                                : AppThemeData.grey200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${option.title ?? ''}  $priceText',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: disabled
                                                      ? AppThemeData.grey400
                                                      : AppThemeData.grey900,
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(
                                                Icons.check_circle,
                                                color: AppThemeData.primary300,
                                                size: 18,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (hasAddOns) ...[
                                Text(
                                  'Add-ons'.tr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: AppThemeData.semiBold,
                                    color: AppThemeData.grey800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: productModel.addOnsTitle!.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (context, index) {
                                    final title = productModel
                                        .addOnsTitle![index]
                                        .toString();
                                    final rawPrice =
                                        index < productModel.addOnsPrice!.length
                                        ? productModel.addOnsPrice![index]
                                              .toString()
                                        : '0';
                                    final isSelected = selectedAddonIndices
                                        .contains(index);
                                    final addOnPriceText = Constant.amountShow(
                                      amount: Constant.productCommissionPrice(
                                        controller.vendorModel,
                                        rawPrice,
                                      ),
                                    );

                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            selectedAddonIndices.remove(index);
                                            controller.selectedAddOns.remove(
                                              title,
                                            );
                                          } else {
                                            selectedAddonIndices.add(index);
                                            controller.selectedAddOns.add(
                                              title,
                                            );
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppThemeData.primary300
                                                    .withOpacity(0.06)
                                              : AppThemeData.grey50,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppThemeData.primary300
                                                : AppThemeData.grey200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '$title  $addOnPriceText',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppThemeData.grey900,
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(
                                                Icons.check_circle,
                                                color: AppThemeData.primary300,
                                                size: 18,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppThemeData.primary300,
                            foregroundColor: AppThemeData.grey50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            if (hasOptions && selectedOptionIndices.isEmpty) {
                              ShowToastDialog.showToast(
                                'Please select at least one option'.tr,
                              );
                              return;
                            }

                            if (hasOptions) {
                              for (final index in selectedOptionIndices) {
                                if (index < 0 || index >= options.length) {
                                  continue;
                                }
                                final selected = options[index];
                                if (selected.isAvailable == false) {
                                  continue;
                                }

                                final optionPrice =
                                    Constant.productCommissionPrice(
                                      controller.vendorModel,
                                      selected.price ?? '0',
                                    );

                                final variantInfo = VariantInfo(
                                  variantId: selected.id,
                                  variantPrice: selected.price ?? '0',
                                  variantSku:
                                      selected.subtitle ?? selected.title ?? '',
                                  variantOptions: {
                                    'option':
                                        selected.subtitle ??
                                        selected.title ??
                                        '',
                                    'merchant_price':
                                        selected.originalPrice ?? '0',
                                  },
                                );

                                controller.addToCart(
                                  productModel: productModel,
                                  price: optionPrice,
                                  discountPrice: '0',
                                  isIncrement: true,
                                  quantity: 1,
                                  variantInfo: variantInfo,
                                );
                              }
                            } else {
                              controller.addProductAndRemoveProductFunction(
                                productModel: productModel,
                                price: price,
                                disPrice: disPrice,
                              );
                            }

                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Add'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: AppThemeData.semiBold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
