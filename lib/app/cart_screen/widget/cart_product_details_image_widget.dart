import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
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

            return FutureBuilder<ProductModel?>(
              future: FireStoreUtils.getProductById(
                cartProductModel.id!.split('~').first,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildProductShimmer(cartProductModel);
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return _buildProductItem(cartProductModel, null);
                }

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
  return Consumer<RestaurantDetailsProvider>(
    builder: (context, restaurantDetailsProvider, _) {
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
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Your existing product UI code here
              // Use productModel instead of the local variable
              LayoutBuilder(
                builder: (context, constraints) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Your product UI components
                        // Use productModel for stock checks, etc.
                      ],
                    ),
                  );
                },
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
