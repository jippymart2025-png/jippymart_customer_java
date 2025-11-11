import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/app/favourite_screens/provider/favorite_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/favourite_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';

class RestaurantListProvider extends ChangeNotifier {
  bool isLoading = false;

  void isLoadingFunction(bool value) {
    isLoading = value;
    notifyListeners();
  }

  List<VendorModel> vendorList = <VendorModel>[];
  List<VendorModel> vendorSearchList = <VendorModel>[];

  String title = "Restaurants";

  // FIX: Change this to FavouriteModel list
  List<FavouriteModel> favouriteList = <FavouriteModel>[];

  void initFunction({
    required List<VendorModel> vendorLists,
    String titles = 'Restaurants',
  }) async {
    isLoadingFunction(true);
    vendorList = vendorLists;
    vendorSearchList = vendorLists;
    title = titles;
    notifyListeners();
    await getFavouriteRestaurant();
    isLoadingFunction(false);
  }

  getFavouriteRestaurant() async {
    if (Constant.userModel != null) {
      try {
        // Get VendorModel list from API
        final List<VendorModel> vendorFavourites =
            await FavouriteProvider.getFavouriteRestaurants();

        // Convert to FavouriteModel list
        favouriteList.clear();
        final userId = await SqlStorageConst.getFirebaseId();

        for (var vendor in vendorFavourites) {
          favouriteList.add(
            FavouriteModel(
              restaurantId: vendor.id, // This is the vendor ID
              userId: userId,
            ),
          );
        }
        notifyListeners();
      } catch (e) {
        print('[ERROR] Failed to load favorites: $e');
      }
    }
  }

  // Helper method to check if a vendor is favorite
  bool isVendorFavorite(String vendorId) {
    return favouriteList.any((fav) => fav.restaurantId == vendorId);
  }

  // Method to add/remove favorite
  Future<void> toggleFavorite(VendorModel vendorModel) async {
    try {
      final userId = await SqlStorageConst.getFirebaseId();
      final vendorId = vendorModel.id.toString();
      bool isCurrentlyFavorite = isVendorFavorite(vendorId);
      if (isCurrentlyFavorite) {
        await FavouriteProvider.removeFavouriteRestaurant(vendorId);
        favouriteList.removeWhere((fav) => fav.restaurantId == vendorId);
      } else {
        await FavouriteProvider.addFavouriteRestaurant(vendorId);
        // Update local list
        favouriteList.add(
          FavouriteModel(restaurantId: vendorId, userId: userId),
        );
      }
      notifyListeners();
    } catch (e) {
      print('[ERROR] Toggle favorite failed: $e');
      rethrow;
    }
  }

  void disposeFunction() {
    vendorSearchList.clear();
  }
}
