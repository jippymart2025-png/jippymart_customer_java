import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/widget/product_options_bottom_sheet.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/widget/restauant_product_list_view.dart';
import 'package:provider/provider.dart';
import '../../../constant/constant.dart';
import '../../../constant/show_toast_dialog.dart';
import '../../../models/product_model.dart';
import '../../../models/vendor_category_model.dart';
import '../../../themes/app_them_data.dart';
import '../../../themes/custom_dialog_box.dart';
import '../../../themes/responsive.dart';
import '../../../utils/network_image_widget.dart';
import '../../../utils/utils/sql_storage_const.dart';
import '../../auth_screen/phone_number_screen.dart';
import '../../home_screen/screen/home_screen/provider/home_provider.dart';
import '../provider/PromotionIndicator.dart';
import '../provider/restaurant_details_provider.dart';

class PromotionalProductsSection extends StatelessWidget {
  const PromotionalProductsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final rs = RS(sw: size.width, sh: size.height);

    return Consumer<RestaurantDetailsProvider>(
      builder: (context, controller, _) {
        final promotionalProducts = controller.productList.where((product) {
          final productId = product.id?.toString() ?? "";
          final restaurantId = product.vendorID ?? "";

          return productId.isNotEmpty &&
              restaurantId.isNotEmpty &&
              controller.hasActivePromotion(productId, restaurantId);
        }).toList();

        // Create category map ONCE here
        final categoryMap = <String, VendorCategoryModel>{
          for (final category in controller.vendorCategoryList)
            category.id.toString(): category,
        };

        if (promotionalProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        // Responsive values
        final cardWidth = rs.isLarge ? rs.sw * 0.28 : rs.sw * 0.40;
        final listHeight = rs.isLarge ? rs.sh * 0.33 : rs.sh * 0.30;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Padding(
              padding: EdgeInsets.only(
                top: rs.isSmall ? 12 : 16,
                right: rs.hPad,
                left: 0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "🔥 Deals For ${Constant.userModel?.firstName ?? ''}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: rs.categoryFontSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  SizedBox(width: rs.gridSpacing),

                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: rs.itemPad + 2,
                      vertical: rs.isSmall ? 4 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${promotionalProducts.length} Items",
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: rs.labelFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: rs.gridSpacing + 2),

            /// Promotional Products
            // Create once
            SizedBox(
              height: listHeight,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: promotionalProducts.length,
                separatorBuilder: (_, __) => SizedBox(width: rs.gridSpacing),
                itemBuilder: (context, index) {
                  final product = promotionalProducts[index];

                  final category = categoryMap[product.categoryID.toString()];

                  // Skip invalid products safely
                  if (category == null) {
                    return const SizedBox.shrink();
                  }

                  return SizedBox(
                    key: ValueKey(product.id),
                    width: cardWidth,
                    child: _buildProductItem(
                      product,
                      context,
                      category,
                      index,
                      controller,
                      rs,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

Widget _buildProductItem(
  ProductModel productModel,
  BuildContext context,
  VendorCategoryModel vendorCategoryModel,
  int index,
  RestaurantDetailsProvider controller,
  RS rs,
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
                        ShowToastDialog.showToast('Failed to update favorites');
                      }
                    },
                    child:
                        controller.isProductFavorite(productModel.id.toString())
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
  final RS rs;

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
  final RS rs;

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
  final RS rs;

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
  final RS rs;

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
    showProductOptionsBottomSheet(
      context: context,
      controller: controller,
      productModel: productModel,
      priceToPass: _priceToPass,
      disPriceToPass: _disPriceToPass,
      buttonFontSize: rs.btnFontSize,
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
