import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
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
          itemCount: cartItem.length,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            CartProductModel cartProductModel = cartItem[index];
            
            // Validate product ID before making API call
            String? productId;
            if (cartProductModel.id != null && cartProductModel.id!.isNotEmpty) {
              final parts = cartProductModel.id!.split('~');
              if (parts.isNotEmpty && parts.first.isNotEmpty) {
                productId = parts.first;
              }
            }
            
            // If no valid product ID, skip API call and show product with cart data
            if (productId == null || productId.isEmpty) {
              print('[CART_PRODUCT] Invalid or null product ID: ${cartProductModel.id}');
              return _buildProductItem(cartProductModel, null);
            }
            
            return FutureBuilder<ProductModel?>(
              future: FireStoreUtils.getProductById(productId).timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  print('[CART_PRODUCT] Timeout loading product: $productId');
                  return null;
                },
              ),
              builder: (context, snapshot) {
                // Show shimmer while loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildProductShimmer(cartProductModel);
                }

                // Show product even if API fails (use cartProductModel data)
                // This ensures the cart is still usable even if product details can't be fetched
                return _buildProductItem(cartProductModel, snapshot.data);
              },
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
) {
  return Consumer2<RestaurantDetailsProvider, CartControllerProvider>(
    builder: (context, restaurantDetailsProvider, cartController, _) {
      // Use productModel photo if available, otherwise use cartProductModel photo
      final productPhoto = productModel?.photo?.isNotEmpty == true
          ? productModel!.photo
          : (cartProductModel.photo?.isNotEmpty == true
              ? cartProductModel.photo
              : null);
      
      // Use productModel name if available, otherwise use cartProductModel name
      final productName = productModel?.name?.isNotEmpty == true
          ? productModel!.name
          : (cartProductModel.name?.isNotEmpty == true
              ? cartProductModel.name
              : 'Product');
      
      // Calculate price
      final price = double.tryParse(cartProductModel.price ?? '0') ?? 0.0;
      final discountPrice = double.tryParse(cartProductModel.discountPrice ?? '0') ?? 0.0;
      final finalPrice = discountPrice > 0 ? discountPrice : price;
      final quantity = cartProductModel.quantity ?? 1;
      final totalPrice = finalPrice * quantity;

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
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: productPhoto != null && productPhoto.isNotEmpty
                    ? Image.network(
                        productPhoto,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
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
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
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
              const SizedBox(width: 12),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
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
                    const SizedBox(height: 4),
                    // Price
                    Row(
                      children: [
                        if (discountPrice > 0 && discountPrice < price) ...[
                          Text(
                            '${Constant.currencyModel?.symbol ?? '₹'}${price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: AppThemeData.regular,
                              color: AppThemeData.grey500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '${Constant.currencyModel?.symbol ?? '₹'}${finalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: AppThemeData.semiBold,
                            color: AppThemeData.primary300,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                              InkWell(
                                onTap: () {
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
