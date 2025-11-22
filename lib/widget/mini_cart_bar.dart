import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/cart_check_out_page/cart_check_out_screen.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:provider/provider.dart';
import '../app/restaurant_details_screen/restaurant_details_screen.dart';
import '../utils/fire_store_utils.dart';
import '../constant/show_toast_dialog.dart';
import '../services/cart_provider.dart';

class MiniCartBar extends StatelessWidget {
  const MiniCartBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<HomeProvider, CartProvider>(
      builder: (context, homeProvider, cartProvider, _) {
        final int itemCount = HomeProvider.cartItem.length;
        if (itemCount == 0) return const SizedBox.shrink();
        final String vendorName =
            HomeProvider.cartItem.first.vendorName ?? 'Restaurant';
        final vendorId = HomeProvider.cartItem.first.vendorID;
        final String productImage = HomeProvider.cartItem.first.photo ?? '';
        return SafeArea(
      minimum: const EdgeInsets.only(bottom: 8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (productImage.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  productImage,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 44,
                    height: 44,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, color: Colors.grey, size: 24),
              ),
            const SizedBox(width: 12),
            // Restaurant name (clickable)
            Expanded(
              child: Consumer<RestaurantDetailsProvider>(
                builder: (context, restaurantDetailsProvider, _) {
                  return InkWell(
                    onTap: () async {
                      if (vendorId != null) {
                        ShowToastDialog.showLoader("Loading restaurant...");
                        final vendorModel = await FireStoreUtils.getVendorById(
                          vendorId.toString(),
                        );
                        ShowToastDialog.closeLoader();
                        if (vendorModel != null) {
                          restaurantDetailsProvider.initFunction(
                            vendorModels: vendorModel,
                          );
                          Get.to(
                            const RestaurantDetailsScreen(),
                            arguments: {'vendorModel': vendorModel},
                          );
                        } else {
                          ShowToastDialog.showToast("Restaurant not found");
                        }
                      }
                    },
                    child: Text(
                      vendorName,
                      style: const TextStyle(
                        color: Color(0xFFff5201),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await Future.delayed(const Duration(milliseconds: 100));
                    Get.to(const CartCheckOutScreen());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFff5201),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  child: Text(
                    'View Cart • $itemCount item${itemCount > 1 ? 's' : ''}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}
