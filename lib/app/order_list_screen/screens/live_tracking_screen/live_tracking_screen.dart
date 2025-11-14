import 'package:jippymart_customer/app/order_list_screen/screens/live_tracking_screen/provider/live_tracking_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutterMap;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LiveTrackingProvider>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: AppThemeData.surface,
          appBar: AppBar(
            backgroundColor: AppThemeData.surface,
            centerTitle: false,
            titleSpacing: 0,
          ),
          body: controller.isLoading
              ? Constant.loader()
              : Constant.selectedMapType == 'osm'
              ? flutterMap.FlutterMap(
                  mapController: controller.osmMapController,
                  options: flutterMap.MapOptions(
                    initialCenter: controller.current,
                    initialZoom: 10,
                  ),
                  children: [
                    flutterMap.TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    flutterMap.MarkerLayer(
                      markers: [
                        flutterMap.Marker(
                          point: controller.current,
                          width: 50,
                          height: 50,
                          child: Image.asset('assets/images/food_delivery.png'),
                        ),
                        flutterMap.Marker(
                          point: controller.source,
                          width: 50,
                          height: 50,
                          child: Image.asset('assets/images/pickup.png'),
                        ),
                        flutterMap.Marker(
                          point: controller.destination,
                          width: 50,
                          height: 50,
                          child: Image.asset('assets/images/dropoff.png'),
                        ),
                      ],
                    ),
                    if (controller.routePoints.isNotEmpty)
                      flutterMap.PolylineLayer(
                        polylines: [
                          flutterMap.Polyline(
                            points: controller.routePoints,
                            strokeWidth: 5.0,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                  ],
                )
              : GoogleMap(
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapType: MapType.terrain,
                  zoomControlsEnabled: false,
                  polylines: Set<Polyline>.of(controller.polyLines.values),
                  padding: const EdgeInsets.only(top: 22.0),
                  markers: Set<Marker>.of(controller.markers.values),
                  onMapCreated: (GoogleMapController mapController) {
                    controller.mapController = mapController;
                  },
                  initialCameraPosition: CameraPosition(
                    zoom: 15,
                    target: LatLng(
                      controller.driverUserModel.location?.latitude != null
                          ? controller.driverUserModel.location?.latitude ??
                                45.521563
                          : 45.521563,
                      controller.driverUserModel.location?.longitude != null
                          ? controller.driverUserModel.location?.longitude ??
                                45.521563
                          : 45.521563,
                    ),
                  ),
                ),
        );
      },
    );
  }
}
