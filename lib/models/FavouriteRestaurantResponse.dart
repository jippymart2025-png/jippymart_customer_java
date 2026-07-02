import 'package:jippymart_customer/models/vendor_model.dart';

class FavouriteRestaurantResponse {
  final List<VendorModel> favorites;
  final List<VendorModel> frequentOutlets;
  final VendorModel? recentOutlet;

  FavouriteRestaurantResponse({
    required this.favorites,
    required this.frequentOutlets,
    required this.recentOutlet,
  });
}
