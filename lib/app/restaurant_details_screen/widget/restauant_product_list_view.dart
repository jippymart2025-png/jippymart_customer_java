import 'dart:math';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/widget/restaurant_without_categories_wiget.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/widget/resturant_product_details_view.dart';
import 'package:jippymart_customer/constant/constant.dart' show Constant;
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/themes/custom_dialog_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../constant/show_toast_dialog.dart';
import '../provider/PromotionIndicator.dart';

// ── Responsive sizing helper ───────────────────────────────────────
class _RS {
  final double sw;
  final double sh;

  const _RS({required this.sw, required this.sh});

  bool get isSmall => sw < 360;

  bool get isLarge => sw >= 600;

  // ── Grid ──────────────────────────────────────────────────────
  // FIXED: Always 2 columns for phones (< 600), 3 for tablets (>= 600)
  int get gridCols {
    if (sw >= 600) return 3; // tablets
    return 2; // ALL phones — 2 columns always
  }

  double get gridSpacing => isSmall ? 8.0 : 10.0;

  // FIXED: Lower ratio = taller card = no overflow
  // Width of each card = (screenWidth - hPad*2 - spacing) / 2
  // We need enough height for: image(1.2 ratio) + veg label + name + price + rating + button + padding
  // Using 0.72 gives ~40% more height than width → plenty of room
  double get gridAspectRatio {
    if (sw >= 600) return 0.78; // tablets
    if (sw < 360) return 0.68; // small phones — extra tall
    return 0.68; // all normal phones (Android + iPhone)
  }

  // Padding
  double get hPad => isSmall ? 10.0 : (isLarge ? 16.0 : 12.0);

  double get itemPad => isSmall ? 6.0 : (isLarge ? 10.0 : 8.0);

  // Font sizes — slightly larger now that we have 2 cols
  double get categoryFontSize => isSmall ? 16.0 : (isLarge ? 20.0 : 18.0);

  double get labelFontSize => isSmall ? 9.0 : (isLarge ? 11.0 : 10.0);

  double get nameFontSize => isSmall ? 12.0 : (isLarge ? 14.0 : 13.0);

  double get priceFontSize => isSmall ? 12.0 : (isLarge ? 14.0 : 13.0);

  double get strikethroughFontSize => isSmall ? 10.0 : (isLarge ? 12.0 : 11.0);

  double get ratingFontSize => isSmall ? 11.0 : (isLarge ? 13.0 : 12.0);

  double get unavailableFontSize => isSmall ? 9.0 : (isLarge ? 11.0 : 10.0);

  double get btnFontSize => isSmall ? 13.0 : (isLarge ? 15.0 : 14.0);

  double get btnIconSize => isSmall ? 15.0 : (isLarge ? 19.0 : 17.0);

  double get qtyFontSize => isSmall ? 13.0 : (isLarge ? 15.0 : 14.0);

  double get ratingIconSize => isSmall ? 13.0 : (isLarge ? 17.0 : 15.0);

  // Spacing
  double get labelGap => isSmall ? 3.0 : 4.0;

  double get nameGap => isSmall ? 1.0 : 2.0;

  double get ratingGap => isSmall ? 2.0 : 3.0;

  double get unavailableTopPad => isSmall ? 1.0 : 2.0;

  // Button — taller now we have room
  double get btnHeight => isSmall ? 30.0 : (isLarge ? 36.0 : 32.0);

  double get btnRadius => isSmall ? 8.0 : 10.0;

  double get btnInnerPad => isSmall ? 6.0 : 8.0;

  double get qtyHPad => isSmall ? 10.0 : 14.0;

  // Favorite icon
  double get favIconPos => isSmall ? 6.0 : 8.0;

  // No-products
  double get emptyVPad => isSmall ? 40.0 : (isLarge ? 80.0 : 60.0);

  double get emptyHPad => isSmall ? 16.0 : (isLarge ? 24.0 : 20.0);

  double get emptyIconSize => isSmall ? 60.0 : (isLarge ? 100.0 : 80.0);

  double get emptyTitleSize => isSmall ? 16.0 : (isLarge ? 20.0 : 18.0);

  double get emptySubSize => isSmall ? 12.0 : (isLarge ? 16.0 : 14.0);

  double get emptyTitleGap => isSmall ? 16.0 : (isLarge ? 24.0 : 20.0);

  double get emptySubGap => isSmall ? 8.0 : (isLarge ? 12.0 : 10.0);
}

// ─────────────────────────────────────────────────────────────────────────────

class ProductListView extends StatelessWidget {
  const ProductListView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final rs = _RS(sw: size.width, sh: size.height);

    return Consumer<RestaurantDetailsProvider>(
      builder: (context, controller, _) {
        return Container(
          color: AppThemeData.grey50,
          padding: EdgeInsets.symmetric(horizontal: rs.hPad),
          child: controller.productList.isEmpty
              ? _buildNoProductsMessage(context, rs)
              : controller.vendorCategoryList.isEmpty
              ? buildProductsWithoutCategories(context, controller)
              : controller.searchEditingController.value.text.isNotEmpty ||
                    controller.isVag ||
                    controller.isNonVag ||
                    controller.isOfferFilter
              ? buildProductsWithoutCategories(context, controller)
              : ListView.builder(
                  controller: controller.scrollControllerProduct,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: controller.vendorCategoryList.length,
                  itemBuilder: (context, index) {
                    final vendorCategoryModel =
                        controller.vendorCategoryList[index];
                    final categoryKey =
                        controller.returnKeyCategories(index: index) ??
                        'category_$index';
                    final stableKey = ValueKey<String>(
                      vendorCategoryModel.id?.toString() ?? categoryKey,
                    );
                    return KeyedSubtree(
                      key: stableKey,
                      child: _buildCategoryExpansionTile(
                        context,
                        vendorCategoryModel,
                        index,
                        controller,
                        rs,
                        categoryKey,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildCategoryExpansionTile(
    BuildContext context,
    VendorCategoryModel vendorCategoryModel,
    int index,
    RestaurantDetailsProvider controller,
    _RS rs,
    String categoryKey,
  ) {
    final globalKey = controller.categoryKeys[categoryKey];
    return ExpansionTile(
      key: globalKey,
      childrenPadding: EdgeInsets.zero,
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      initiallyExpanded: true,
      title: Text(
        '${vendorCategoryModel.title}'
        ' (${controller.getProductsByCategory(vendorCategoryModel.id.toString()).length})',
        style: TextStyle(
          fontSize: rs.categoryFontSize,
          fontFamily: AppThemeData.semiBold,
          fontWeight: FontWeight.w600,
          color: AppThemeData.grey900,
        ),
      ),
      children: [
        Consumer<RestaurantDetailsProvider>(
          builder: (context, ctrl, _) =>
              _buildProductsForCategory(vendorCategoryModel, context, ctrl, rs),
        ),
      ],
    );
  }

  Widget _buildProductsForCategory(
    VendorCategoryModel vendorCategoryModel,
    BuildContext context,
    RestaurantDetailsProvider controller,
    _RS rs,
  ) {
    final products = controller.getProductsByCategory(
      vendorCategoryModel.id.toString(),
    );

    return Consumer<HomeProvider>(
      builder: (context, _, __) {
        return GridView.builder(
          itemCount: products.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: rs.gridSpacing),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: rs.gridCols,
            crossAxisSpacing: rs.gridSpacing,
            mainAxisSpacing: rs.gridSpacing,
            childAspectRatio: rs.gridAspectRatio,
          ),
          itemBuilder: (context, productIndex) {
            final productModel = products[productIndex];
            return RepaintBoundary(
              child: _buildProductItem(
                productModel,
                context,
                vendorCategoryModel,
                productIndex,
                controller,
                rs,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductItem(
    ProductModel productModel,
    BuildContext context,
    VendorCategoryModel vendorCategoryModel,
    int index,
    RestaurantDetailsProvider controller,
    _RS rs,
  ) {
    final isItemAvailable = productModel.isAvailable ?? true;

    String basePrice = '0.0';
    String baseDisPrice = '0.0';

    if (productModel.itemAttribute != null &&
        productModel.itemAttribute!.variants != null &&
        productModel.itemAttribute!.variants!.isNotEmpty) {
      final variant = controller.selectedVariants.isEmpty
          ? productModel.itemAttribute!.variants!.first
          : productModel.itemAttribute!.variants!.firstWhere(
              (e) => e.variantSku == controller.selectedVariants.join('-'),
              orElse: () => productModel.itemAttribute!.variants!.first,
            );
      basePrice = Constant.productCommissionPrice(
        controller.vendorModel,
        variant.variantPrice ?? '0',
      );
      baseDisPrice = '0';
    } else {
      basePrice = Constant.productCommissionPrice(
        controller.vendorModel,
        productModel.price.toString(),
      );
      baseDisPrice = double.parse(productModel.disPrice.toString()) <= 0
          ? '0'
          : Constant.productCommissionPrice(
              controller.vendorModel,
              productModel.disPrice.toString(),
            );
    }

    // FIXED: Use Column with mainAxisSize.max so it fills the grid cell
    // and never overflows — content is constrained within the cell
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      // FIXED: ClipRect prevents any child from painting outside bounds
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image: fixed fraction of card height ──────────────
            // Use Flexible so image takes proportional space, not fixed AspectRatio
            Flexible(
              flex: 5, // image gets 5 parts
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
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
                        fit: BoxFit.fill,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),

                  // Promotion badge
                  if (productModel.id != null && productModel.vendorID != null)
                    PromotionIndicator(
                      productId: productModel.id!.toString(),
                      restaurantId: productModel.vendorID!,
                      child: Container(),
                    ),

                  // Unavailable overlay
                  if (!isItemAvailable)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0x66000000),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  // Favorite button
                  Positioned(
                    right: rs.favIconPos,
                    top: rs.favIconPos,
                    child: InkWell(
                      onTap: () async {
                        if (productModel.id == null ||
                            productModel.id.toString().isEmpty) {
                          ShowToastDialog.showToast('Invalid product data');
                          return;
                        }
                        try {
                          await controller.toggleProductFavorite(
                            productModel.id!.toString(),
                          );
                        } catch (_) {
                          ShowToastDialog.showToast(
                            'Failed to update favorites',
                          );
                        }
                      },
                      child:
                          controller.isProductFavorite(
                            productModel.id.toString(),
                          )
                          ? SvgPicture.asset('assets/icons/ic_like_fill.svg')
                          : SvgPicture.asset('assets/icons/ic_like.svg'),
                    ),
                  ),
                ],
              ),
            ),

            // ── Details: fills remaining space, never overflows ───
            Flexible(
              flex: 4, // details get 4 parts
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: rs.itemPad,
                  vertical: 4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top: veg + name + price + rating ──────────
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Veg / Non-veg label
                        Row(
                          children: [
                            SizedBox(
                              width: rs.labelFontSize + 2,
                              height: rs.labelFontSize + 2,
                              child: productModel.nonveg == true
                                  ? SvgPicture.asset(
                                      'assets/icons/ic_nonveg.svg',
                                      fit: BoxFit.contain,
                                    )
                                  : SvgPicture.asset(
                                      'assets/icons/ic_veg.svg',
                                      fit: BoxFit.contain,
                                    ),
                            ),
                            SizedBox(width: rs.labelGap),
                            Expanded(
                              child: Text(
                                productModel.nonveg == true
                                    ? 'Non Veg.'.tr
                                    : 'Pure veg.'.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: rs.labelFontSize,
                                  color: productModel.nonveg == true
                                      ? AppThemeData.danger300
                                      : AppThemeData.success400,
                                  fontFamily: AppThemeData.semiBold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 1),

                        // Product name
                        Text(
                          productModel.name.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: rs.nameFontSize,
                            color: AppThemeData.grey900,
                            fontFamily: AppThemeData.semiBold,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),

                        const SizedBox(height: 1),

                        // Price
                        Consumer<RestaurantDetailsProvider>(
                          builder: (context, ctrl, _) {
                            final productId = productModel.id?.toString() ?? '';
                            final restaurantId = productModel.vendorID ?? '';

                            if (productId.isEmpty || restaurantId.isEmpty) {
                              return _PriceText(
                                amount: basePrice,
                                fontSize: rs.priceFontSize,
                              );
                            }

                            final currentPromo =
                                ctrl.hasActivePromotion(productId, restaurantId)
                                ? ctrl.getActivePromotionForProduct(
                                    productId: productId,
                                    restaurantId: restaurantId,
                                  )
                                : null;

                            if (currentPromo != null) {
                              final promoPrice =
                                  (currentPromo['special_price'] as num)
                                      .toString();
                              return _PromoPriceRow(
                                promoPrice: promoPrice,
                                originalPrice: basePrice,
                                rs: rs,
                              );
                            }

                            if (double.parse(baseDisPrice) > 0) {
                              return _DiscountPriceRow(
                                discountPrice: baseDisPrice,
                                originalPrice: basePrice,
                                rs: rs,
                              );
                            }

                            return _PriceText(
                              amount: basePrice,
                              fontSize: rs.priceFontSize,
                            );
                          },
                        ),

                        // Rating
                        _RatingWidget(productModel: productModel, rs: rs),

                        // Not available
                        if (!isItemAvailable)
                          Text(
                            'Not Available',
                            style: TextStyle(
                              fontSize: rs.unavailableFontSize,
                              color: Colors.red,
                              fontFamily: AppThemeData.medium,
                              height: 1.1,
                            ),
                          ),
                      ],
                    ),

                    // ── Bottom: Add button (spaceBetween pushes it down) ──
                    if (controller.canAcceptOrders() && isItemAvailable)
                      _AddToCartButton(
                        controller: controller,
                        productModel: productModel,
                        basePrice: basePrice,
                        baseDisPrice: baseDisPrice,
                        rs: rs,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Price widgets ──────────────────────────────────────────────────

class _PriceText extends StatelessWidget {
  final String amount;
  final double fontSize;

  const _PriceText({required this.amount, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Text(
      Constant.amountShow(amount: amount),
      style: TextStyle(
        fontSize: fontSize,
        color: AppThemeData.grey900,
        fontFamily: AppThemeData.semiBold,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PromoPriceRow extends StatelessWidget {
  final String promoPrice;
  final String originalPrice;
  final _RS rs;

  const _PromoPriceRow({
    required this.promoPrice,
    required this.originalPrice,
    required this.rs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            Constant.amountShow(amount: promoPrice),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: rs.priceFontSize,
              color: Colors.red,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: rs.labelGap),
        Flexible(
          child: Text(
            Constant.amountShow(amount: originalPrice),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: rs.strikethroughFontSize,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppThemeData.grey300,
              color: AppThemeData.grey300,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _DiscountPriceRow extends StatelessWidget {
  final String discountPrice;
  final String originalPrice;
  final _RS rs;

  const _DiscountPriceRow({
    required this.discountPrice,
    required this.originalPrice,
    required this.rs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            Constant.amountShow(amount: discountPrice),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: rs.priceFontSize,
              color: AppThemeData.grey900,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: rs.labelGap),
        Flexible(
          child: Text(
            Constant.amountShow(amount: originalPrice),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: rs.strikethroughFontSize,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppThemeData.grey300,
              color: AppThemeData.grey300,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Rating widget ──────────────────────────────────────────────────

class _RatingWidget extends StatelessWidget {
  final ProductModel productModel;
  final _RS rs;

  const _RatingWidget({required this.productModel, required this.rs});

  @override
  Widget build(BuildContext context) {
    final productId = productModel.id?.toString() ?? '0';
    final random = Random(productId.hashCode);
    final rating = 3.0 + (random.nextDouble() * 2.0);
    final ratingText = rating.toStringAsFixed(1);
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(1, (index) {
            if (index < fullStars) {
              return Icon(
                Icons.star,
                size: rs.ratingIconSize,
                color: Colors.amber,
              );
            } else if (index == fullStars && hasHalfStar) {
              return Icon(
                Icons.star_half,
                size: rs.ratingIconSize,
                color: Colors.amber,
              );
            }
            return Icon(
              Icons.star_border,
              size: rs.ratingIconSize,
              color: AppThemeData.grey300,
            );
          }),
        ),
        SizedBox(width: rs.labelGap),
        Text(
          ratingText,
          style: TextStyle(
            fontSize: rs.ratingFontSize,
            color: AppThemeData.grey600,
            fontFamily: AppThemeData.medium,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Add to cart button ─────────────────────────────────────────────

class _AddToCartButton extends StatelessWidget {
  final RestaurantDetailsProvider controller;
  final ProductModel productModel;
  final String basePrice;
  final String baseDisPrice;
  final _RS rs;

  const _AddToCartButton({
    required this.controller,
    required this.productModel,
    required this.basePrice,
    required this.baseDisPrice,
    required this.rs,
  });

  String get _productId => productModel.id?.toString() ?? '';

  bool get _hasVariantsOrAddons {
    final hasItemAttributes =
        productModel.itemAttribute != null &&
        productModel.itemAttribute!.attributes != null &&
        productModel.itemAttribute!.attributes!.isNotEmpty;
    return hasItemAttributes;
  }

  bool get _hasOptionsOnly {
    final hasOptions =
        productModel.options != null && productModel.options!.isNotEmpty;
    final hasItemAttributes =
        productModel.itemAttribute != null &&
        productModel.itemAttribute!.attributes != null &&
        productModel.itemAttribute!.attributes!.isNotEmpty;
    return hasOptions && !hasItemAttributes;
  }

  bool get _isInCart => HomeProvider.cartItem.any((item) {
    if (item.id == null || item.id!.isEmpty) return false;
    return item.id == _productId || item.id!.startsWith('$_productId~');
  });

  int get _cartQty {
    if (_productId.isEmpty) return 0;
    return HomeProvider.cartItem
        .where(
          (item) =>
              item.id != null &&
              (item.id == _productId || item.id!.startsWith('$_productId~')),
        )
        .fold<int>(0, (sum, item) => sum + (item.quantity ?? 0));
  }

  Map<String, dynamic>? get _promo => controller.getActivePromotionForProduct(
    productId: _productId,
    restaurantId: productModel.vendorID ?? '',
  );

  String get _priceToPass {
    final p = _promo;
    if (p != null) return (p['special_price'] as num).toString();
    if (double.parse(baseDisPrice) > 0) return baseDisPrice;
    return basePrice;
  }

  String get _disPriceToPass {
    final p = _promo;
    if (p != null) return basePrice;
    if (double.parse(baseDisPrice) > 0) return basePrice;
    return baseDisPrice;
  }

  BoxDecoration get _btnDecoration => BoxDecoration(
    color: AppThemeData.primary300,
    borderRadius: BorderRadius.circular(rs.btnRadius),
    boxShadow: [
      BoxShadow(
        color: AppThemeData.primary300.withOpacity(0.3),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (_hasVariantsOrAddons) {
      return _buildVariantButton(context);
    } else if (_hasOptionsOnly) {
      return _buildOptionsButton(context);
    } else if (_isInCart) {
      return _buildInCartButton(context);
    } else {
      return _buildAddButton(context);
    }
  }

  Widget _buildVariantButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: rs.btnHeight,
      child: DecoratedBox(
        decoration: _btnDecoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
              if (!isLoggedIn) {
                _showLoginDialog(context);
                return;
              }
              controller.selectedVariants.clear();
              controller.selectedIndexVariants.clear();
              controller.selectedIndexArray.clear();
              controller.selectedAddOns.clear();
              controller.quantity = 1;
              controller.calculatePrice(productModel);
              productDetailsBottomSheet(context, productModel);
            },
            borderRadius: BorderRadius.circular(rs.btnRadius),
            child: Center(
              child: Text(
                'Add'.tr,
                style: TextStyle(
                  fontSize: rs.btnFontSize,
                  fontFamily: AppThemeData.semiBold,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: rs.btnHeight,
      child: DecoratedBox(
        decoration: _btnDecoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
              if (!isLoggedIn) {
                _showLoginDialog(context);
                return;
              }
              controller.selectedAddOns.clear();
              _showOptionsBottomSheet(context);
            },
            borderRadius: BorderRadius.circular(rs.btnRadius),
            child: Center(
              child: Text(
                'Options'.tr,
                style: TextStyle(
                  fontSize: rs.btnFontSize,
                  fontFamily: AppThemeData.semiBold,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context) {
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
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppThemeData.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
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
                        Row(
                          children: [
                            if (productModel.photo != null &&
                                productModel.photo!.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: NetworkImageWidget(
                                  imageUrl: productModel.photo!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                  const SizedBox(height: 4),
                                  if (hasOptions)
                                    Text(
                                      'Choose options'.tr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppThemeData.grey600,
                                        fontFamily: AppThemeData.medium,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 360),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hasOptions) ...[
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: options.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final option = options[index];
                                      final priceText = Constant.amountShow(
                                        amount: Constant.productCommissionPrice(
                                          controller.vendorModel,
                                          option.price ?? '0',
                                        ),
                                      );
                                      final disabled =
                                          option.isAvailable == false ||
                                          option.price == null;
                                      final isSelected = selectedOptionIndices
                                          .contains(index);

                                      return InkWell(
                                        onTap: disabled
                                            ? null
                                            : () {
                                                setState(() {
                                                  if (selectedOptionIndices
                                                      .contains(index)) {
                                                    selectedOptionIndices
                                                        .remove(index);
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
                                              Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? AppThemeData
                                                              .primary300
                                                        : AppThemeData.grey400,
                                                    width: 2,
                                                  ),
                                                  color: Colors.transparent,
                                                ),
                                                child: Center(
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 150,
                                                    ),
                                                    width: 10,
                                                    height: 10,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: isSelected
                                                          ? AppThemeData
                                                                .primary300
                                                          : Colors.transparent,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      option.title ?? '',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontFamily:
                                                            AppThemeData.medium,
                                                        color: disabled
                                                            ? AppThemeData
                                                                  .grey400
                                                            : AppThemeData
                                                                  .grey900,
                                                      ),
                                                    ),
                                                    if (option
                                                            .subtitle
                                                            ?.isNotEmpty ==
                                                        true) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        option.subtitle!,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontFamily:
                                                              AppThemeData
                                                                  .regular,
                                                          color: disabled
                                                              ? AppThemeData
                                                                    .grey400
                                                              : AppThemeData
                                                                    .grey600,
                                                        ),
                                                      ),
                                                    ],
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      priceText,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: disabled
                                                            ? AppThemeData
                                                                  .grey400
                                                            : AppThemeData
                                                                  .grey700,
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
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: productModel.addOnsTitle!.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final title = productModel
                                          .addOnsTitle![index]
                                          .toString();
                                      final rawPrice =
                                          index <
                                              productModel.addOnsPrice!.length
                                          ? productModel.addOnsPrice![index]
                                                .toString()
                                          : '0';
                                      final priceText = Constant.amountShow(
                                        amount: Constant.productCommissionPrice(
                                          controller.vendorModel,
                                          rawPrice,
                                        ),
                                      );
                                      final isSelected = selectedAddonIndices
                                          .contains(index);

                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              selectedAddonIndices.remove(
                                                index,
                                              );
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
                                              Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? AppThemeData
                                                              .primary300
                                                        : AppThemeData.grey400,
                                                    width: 2,
                                                  ),
                                                  color: Colors.transparent,
                                                ),
                                                child: Center(
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 150,
                                                    ),
                                                    width: 10,
                                                    height: 10,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: isSelected
                                                          ? AppThemeData
                                                                .primary300
                                                          : Colors.transparent,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      title,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontFamily:
                                                            AppThemeData.medium,
                                                        color: AppThemeData
                                                            .grey900,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      priceText,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: AppThemeData
                                                            .grey700,
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
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                              // Options + add-ons
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
                                        selected.subtitle ??
                                        selected.title ??
                                        '',
                                    variantOptions: {
                                      'option':
                                          selected.subtitle ??
                                          selected.title ??
                                          '',
                                      // merchant_price is original_price from API
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
                                // Only add-ons, no options
                                controller.addProductAndRemoveProductFunction(
                                  productModel: productModel,
                                  price: _priceToPass,
                                  disPrice: _disPriceToPass,
                                );
                              }

                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'Add'.tr,
                              style: TextStyle(
                                fontSize: rs.btnFontSize,
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

  Widget _buildInCartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: rs.btnHeight,
      child: DecoratedBox(
        decoration: _btnDecoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final p = _promo;
                  final finalPrice = p != null
                      ? (p['special_price'] as num).toString()
                      : _priceToPass;
                  final finalDisPrice = p != null ? basePrice : _disPriceToPass;
                  controller.addToCart(
                    productModel: productModel,
                    price: finalPrice,
                    discountPrice: finalDisPrice,
                    isIncrement: false,
                    quantity: _cartQty - 1,
                  );
                },
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(rs.btnRadius),
                  bottomLeft: Radius.circular(rs.btnRadius),
                ),
                child: Padding(
                  padding: EdgeInsets.all(rs.btnInnerPad),
                  child: Icon(
                    Icons.remove,
                    size: rs.btnIconSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: rs.qtyHPad),
              child: Text(
                _cartQty.toString(),
                style: TextStyle(
                  fontSize: rs.qtyFontSize,
                  fontFamily: AppThemeData.semiBold,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
                  if (!isLoggedIn) {
                    _showLoginDialog(context);
                    return;
                  }
                  final currentQty = _cartQty;
                  if (currentQty <= (productModel.quantity ?? 0) ||
                      (productModel.quantity ?? 0) == -1) {
                    final p = _promo;
                    if (p != null) {
                      final isAllowed = controller
                          .isPromotionalItemQuantityAllowed(
                            _productId,
                            productModel.vendorID ?? '',
                            currentQty + 1,
                          );
                      if (!isAllowed) {
                        final limit = controller.getPromotionalItemLimit(
                          _productId,
                          productModel.vendorID ?? '',
                        );
                        ShowToastDialog.showToast(
                          'Maximum $limit items allowed for this promotional offer'
                              .tr,
                        );
                        return;
                      }
                    }
                    final finalPrice = p != null
                        ? (p['special_price'] as num).toString()
                        : _priceToPass;
                    final finalDisPrice = p != null
                        ? basePrice
                        : _disPriceToPass;
                    controller.addToCart(
                      productModel: productModel,
                      price: finalPrice,
                      discountPrice: finalDisPrice,
                      isIncrement: true,
                      quantity: currentQty + 1,
                    );
                  } else {
                    ShowToastDialog.showToast('Out of stock'.tr);
                  }
                },
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(rs.btnRadius),
                  bottomRight: Radius.circular(rs.btnRadius),
                ),
                child: Padding(
                  padding: EdgeInsets.all(rs.btnInnerPad),
                  child: Icon(
                    Icons.add,
                    size: rs.btnIconSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: rs.btnHeight,
      child: DecoratedBox(
        decoration: _btnDecoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
              if (!isLoggedIn) {
                _showLoginDialog(context);
                return;
              }
              controller.addProductAndRemoveProductFunction(
                productModel: productModel,
                price: _priceToPass,
                disPrice: _disPriceToPass,
              );
            },
            borderRadius: BorderRadius.circular(rs.btnRadius),
            child: Center(
              child: Text(
                (productModel.options != null &&
                        productModel.options!.isNotEmpty &&
                        (productModel.itemAttribute == null ||
                            productModel.itemAttribute!.attributes == null ||
                            productModel.itemAttribute!.attributes!.isEmpty))
                    ? 'Options'.tr
                    : 'Add'.tr,
                style: TextStyle(
                  fontSize: rs.btnFontSize,
                  fontFamily: AppThemeData.semiBold,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CustomDialogBox(
        title: 'Login Required'.tr,
        descriptions:
            'Please login to add items to your cart and continue shopping.'.tr,
        positiveString: 'Login'.tr,
        negativeString: 'Cancel'.tr,
        positiveClick: () {
          Get.back();
          Get.to(() => PhoneNumberScreen());
        },
        negativeClick: () => Get.back(),
        img: Image.asset(
          'assets/images/ic_launcher.png',
          height: 50,
          width: 50,
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────

productDetailsBottomSheet(BuildContext context, ProductModel productModel) {
  return showModalBottomSheet(
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

infoDialog(RestaurantDetailsProvider controller, ProductModel productModel) {
  return Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    insetPadding: const EdgeInsets.all(10),
    clipBehavior: Clip.antiAliasWithSaveLayer,
    backgroundColor: AppThemeData.surface,
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "Food Information's".tr,
                  style: TextStyle(
                    fontFamily: AppThemeData.semiBold,
                    color: AppThemeData.grey900,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                productModel.description.toString(),
                style: TextStyle(
                  fontFamily: AppThemeData.regular,
                  fontWeight: FontWeight.w400,
                  color: AppThemeData.grey900,
                ),
              ),
              const SizedBox(height: 20),
              RoundedButtonFill(
                title: 'Back'.tr,
                color: AppThemeData.primary300,
                textColor: AppThemeData.grey50,
                onPress: () async => Get.back(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ── No products empty state ────────────────────────────────────────

Widget _buildNoProductsMessage(BuildContext context, _RS rs) {
  return Container(
    padding: EdgeInsets.symmetric(
      vertical: rs.emptyVPad,
      horizontal: rs.emptyHPad,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.restaurant_menu_outlined,
          size: rs.emptyIconSize,
          color: AppThemeData.grey600,
        ),
        SizedBox(height: rs.emptyTitleGap),
        Text(
          'No products available here'.tr,
          style: TextStyle(
            fontSize: rs.emptyTitleSize,
            fontWeight: FontWeight.w600,
            color: AppThemeData.grey700,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: rs.emptySubGap),
        Text(
          "This restaurant doesn't have any items in their menu right now.".tr,
          style: TextStyle(
            fontSize: rs.emptySubSize,
            color: AppThemeData.grey600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
