import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/vendor_model.dart';

class RestaurantService {
  Future<List<VendorModel>> loadRestaurants() async {
    final cached = Constant.restaurantList ?? [];

    if (cached.isNotEmpty) {
      return cached;
    }

    final latitude = Constant.selectedLocation.location?.latitude ?? 0.0;

    final longitude = Constant.selectedLocation.location?.longitude ?? 0.0;

    if (latitude == 0 || longitude == 0) {
      throw Exception("LOCATION_NOT_SELECTED");
    }

    return BestRestaurantProvider.getNearestRestaurants(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
