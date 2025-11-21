import 'package:jippymart_customer/app/favourite_screens/provider/favorite_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/constant/constant.dart'
    show Constant, cartItem;
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/favourite_item_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/widget/special_price_badge.dart';
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
                            FutureBuilder<Map<String, dynamic>?>(
                              future:
                                  FireStoreUtils.getActivePromotionForProduct(
                                    productId: productModel.id.toString() ?? '',
                                    restaurantId: productModel.vendorID ?? '',
                                  ),
                              builder: (context, promoSnapshot) {
                                if (promoSnapshot.data != null) {
                                  return Container(
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
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<Map<String, dynamic>?>(
                        future: Future.value(
                          controller.getActivePromotionForProduct(
                            productId: productModel.id.toString() ?? '',
                            restaurantId: productModel.vendorID ?? '',
                          ),
                        ),
                        builder: (context, promoSnapshot) {
                          final hasPromo = promoSnapshot.data != null;
                          final promoPrice = hasPromo
                              ? (promoSnapshot.data!['special_price'] as num)
                                    .toString()
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
                // Special promotional price badge
                FutureBuilder<Map<String, dynamic>?>(
                  future: Future.value(
                    controller.getActivePromotionForProduct(
                      productId: productModel.id.toString() ?? '',
                      restaurantId: productModel.vendorID ?? '',
                    ),
                  ),
                  builder: (context, promoSnapshot) {
                    print(
                      '[DEBUG] Product ${productModel.id} - Promotion data: ${promoSnapshot.data}',
                    );
                    if (promoSnapshot.data != null) {
                      print(
                        '[DEBUG] Showing SPECIAL badge for product ${productModel.id}',
                      );
                      print(
                        '[DEBUG] Badge will be rendered with black background and white text',
                      );
                      return Positioned(
                        top: 0,
                        left: 0,
                        child: const SpecialPriceBadge(
                          showShimmer: true,
                          width: 60,
                          height: 60,
                          margin: EdgeInsets.zero,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
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
                      final userId = await SqlStorageConst.getFirebaseId();
                      if (controller.favouriteItemList
                          .where((p0) => p0.productId == productModel.id)
                          .isNotEmpty) {
                        controller.favouriteItemList.removeWhere(
                          (item) => item.productId == productModel.id,
                        );
                        await FavouriteProvider.removeFavouriteFood(
                          productModel.id.toString(),
                        );
                      } else {
                        FavouriteItemModel favouriteModel = FavouriteItemModel(
                          productId: productModel.id.toString(),
                          storeId: controller.vendorModel.id,
                          userId: userId,
                        );
                        controller.favouriteItemList.add(favouriteModel);

                        await FavouriteProvider.addFavouriteFood(
                          productModel.id.toString(),
                        );
                      }
                    },
                    child:
                        controller.favouriteItemList
                            .where((p0) => p0.productId == productModel.id)
                            .isNotEmpty
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
                                          productModel.addOnsTitle!.isNotEmpty)
                                  ? RoundedButtonFill(
                                      title: "Add".tr,
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

                                        controller
                                            .calculatePrice(productModel)
                                            .then((_) {});
                                        // productDetailsBottomSheet(
                                        //     context,
                                        //     productModel);
                                      },
                                    )
                                  : HomeProvider.cartItem
                                        .where((p0) => p0.id == productModel.id)
                                        .isNotEmpty
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
                                                final promo =
                                                    await FireStoreUtils.getActivePromotionForProduct(
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
                                                      HomeProvider.cartItem
                                                          .where(
                                                            (p0) =>
                                                                p0.id ==
                                                                productModel.id,
                                                          )
                                                          .first
                                                          .quantity! -
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
                                                HomeProvider.cartItem
                                                    .where(
                                                      (p0) =>
                                                          p0.id ==
                                                          productModel.id,
                                                    )
                                                    .first
                                                    .quantity
                                                    .toString(),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                style: TextStyle(
                                                  fontSize:
                                                      HomeProvider.cartItem
                                                              .where(
                                                                (p0) =>
                                                                    p0.id ==
                                                                    productModel
                                                                        .id,
                                                              )
                                                              .first
                                                              .quantity
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
                                                if ((HomeProvider.cartItem
                                                                .where(
                                                                  (p0) =>
                                                                      p0.id ==
                                                                      productModel
                                                                          .id,
                                                                )
                                                                .first
                                                                .quantity ??
                                                            0) <=
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
