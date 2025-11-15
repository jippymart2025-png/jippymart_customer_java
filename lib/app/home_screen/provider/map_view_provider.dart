import 'dart:typed_data';

import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutterMap;
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as location;
import 'package:provider/provider.dart';

import '../screen/home_screen/provider/home_provider.dart';

class MapViewProvider extends ChangeNotifier {
  GoogleMapController? mapController;
  BitmapDescriptor? parkingMarker;
  BitmapDescriptor? currentLocationMarker;

  late HomeProvider homeController;
  late BestRestaurantProvider bestRestaurantProvider;
  Image? departureOsmIcon; //OSM
  late RestaurantDetailsProvider restaurantDetailsProvider;

  RxList<flutterMap.Marker> osmMarker = <flutterMap.Marker>[].obs;
  final flutterMap.MapController osmMapController = flutterMap.MapController();

  void initFunction(BuildContext context) {
    homeController = Provider.of<HomeProvider>(context, listen: false);
    bestRestaurantProvider = Provider.of<BestRestaurantProvider>(
      context,
      listen: false,
    );
    restaurantDetailsProvider = Provider.of<RestaurantDetailsProvider>(
      context,
      listen: false,
    );
    addMarkerSetup();
  }

  addMarkerSetup() async {
    if (Constant.selectedMapType == "osm") {
      departureOsmIcon = Image.asset(
        "assets/images/map_selected.png",
        width: 30,
        height: 30,
      ); //OSM

      for (var element in bestRestaurantProvider.allNearestRestaurant) {
        osmMarker.add(
          flutterMap.Marker(
            point: location.LatLng(
              element.latitude ?? 0.0,
              element.longitude ?? 0.0,
            ),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                restaurantDetailsProvider.initFunction(vendorModels: element);
                Get.to(const RestaurantDetailsScreen());
              },
              child: departureOsmIcon,
            ),
          ),
        );
      }
    } else {
      final Uint8List parking = await Constant().getBytesFromAsset(
        "assets/images/map_selected.png",
        20,
      );
      parkingMarker = BitmapDescriptor.bytes(parking);
      for (var element in bestRestaurantProvider.allNearestRestaurant) {
        addMarker(
          latitude: element.latitude,
          longitude: element.longitude,
          id: element.id.toString(),
          rotation: 0,
          descriptor: parkingMarker!,
          title: element.title.toString(),
        );
      }
    }
  }

  RxMap<MarkerId, Marker> markers = <MarkerId, Marker>{}.obs;

  addMarker({
    required double? latitude,
    required double? longitude,
    required String id,
    required BitmapDescriptor descriptor,
    required double? rotation,
    required String title,
  }) {
    MarkerId markerId = MarkerId(id);
    Marker marker = Marker(
      markerId: markerId,
      icon: descriptor,
      infoWindow: InfoWindow(
        title: title,
        onTap: () {
          int index = bestRestaurantProvider.allNearestRestaurant.indexWhere(
            (p0) => p0.id == id,
          );
          restaurantDetailsProvider.initFunction(
            vendorModels: bestRestaurantProvider.allNearestRestaurant[index],
          );
          Get.to(const RestaurantDetailsScreen());
        },
      ),
      position: LatLng(latitude ?? 0.0, longitude ?? 0.0),
      rotation: rotation ?? 0.0,
    );
    markers[markerId] = marker;
  }
}
