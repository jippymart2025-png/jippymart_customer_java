import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/constant/collection_name.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:flutter_map/flutter_map.dart' as flutterMap;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as location;

class LiveTrackingProvider extends ChangeNotifier {
  GoogleMapController? mapController;
  final flutterMap.MapController osmMapController = flutterMap.MapController();

  void initFunction({required OrderModel orderModel}) {
    addMarkerSetup();
    getArgument(orderModel: orderModel);
  }

  OrderModel orderModel = OrderModel();
  UserModel driverUserModel = UserModel();
  bool isLoading = true;
  location.LatLng source = location.LatLng(21.1702, 72.8311);
  location.LatLng current = location.LatLng(21.1800, 72.8400);
  location.LatLng destination = location.LatLng(
    21.2000,
    72.8600,
  ); // Destination
  getArgument({required OrderModel orderModel}) async {
    FireStoreUtils.fireStore
        .collection(CollectionName.restaurantOrders)
        .doc(orderModel.id)
        .snapshots()
        .listen((event) {
          if (event.data() != null) {
            OrderModel orderModelStream = OrderModel.fromJson(event.data()!);
            orderModel = orderModelStream;
            FireStoreUtils.fireStore
                .collection(CollectionName.users)
                .doc(orderModel.driverID)
                .snapshots()
                .listen((event) {
                  if (event.data() != null) {
                    driverUserModel = UserModel.fromJson(event.data()!);
                    if (Constant.selectedMapType != 'osm') {
                      if (orderModel.status == Constant.orderShipped) {
                        getPolyline(
                          sourceLatitude: driverUserModel.location!.latitude,
                          sourceLongitude: driverUserModel.location!.longitude,
                          destinationLatitude: orderModel.vendor!.latitude,
                          destinationLongitude: orderModel.vendor!.longitude,
                        );
                      } else if (orderModel.status == Constant.orderInTransit) {
                        getPolyline(
                          sourceLatitude: driverUserModel.location!.latitude,
                          sourceLongitude: driverUserModel.location!.longitude,
                          destinationLatitude:
                              orderModel.address!.location!.latitude,
                          destinationLongitude:
                              orderModel.address!.location!.longitude,
                        );
                      } else {
                        getPolyline(
                          sourceLatitude:
                              orderModel.address!.location!.latitude,
                          sourceLongitude:
                              orderModel.address!.location!.longitude,
                          destinationLatitude: orderModel.vendor!.latitude,
                          destinationLongitude: orderModel.vendor!.longitude,
                        );
                      }
                    } else {
                      if (orderModel.status == Constant.orderShipped) {
                        current = location.LatLng(
                          driverUserModel.location!.latitude ?? 0.0,
                          driverUserModel.location!.longitude ?? 0.0,
                        );
                        source = location.LatLng(
                          orderModel.vendor!.latitude ?? 0.0,
                          orderModel.vendor!.longitude ?? 0.0,
                        );
                        destination = location.LatLng(
                          orderModel.address!.location!.latitude ?? 0.0,
                          orderModel.address!.location!.longitude ?? 0.0,
                        );
                        fetchRoute(current, source);
                        animateToSource();
                      } else if (orderModel.status == Constant.orderInTransit) {
                        current = location.LatLng(
                          driverUserModel.location!.latitude ?? 0.0,
                          driverUserModel.location!.longitude ?? 0.0,
                        );
                        source = location.LatLng(
                          orderModel.vendor!.latitude ?? 0.0,
                          orderModel.vendor!.longitude ?? 0.0,
                        );
                        destination = location.LatLng(
                          orderModel.address!.location!.latitude ?? 0.0,
                          orderModel.address!.location!.longitude ?? 0.0,
                        );
                        fetchRoute(current, destination);
                        animateToSource();
                      } else {
                        current = location.LatLng(
                          driverUserModel.location!.latitude ?? 0.0,
                          driverUserModel.location!.longitude ?? 0.0,
                        );
                        source = location.LatLng(
                          orderModel.vendor!.latitude ?? 0.0,
                          orderModel.vendor!.longitude ?? 0.0,
                        );
                        destination = location.LatLng(
                          orderModel.address!.location!.latitude ?? 0.0,
                          orderModel.address!.location!.longitude ?? 0.0,
                        );
                        fetchRoute(current, source);
                        animateToSource();
                      }
                    }
                  }
                });

            if (orderModel.status == Constant.orderCompleted) {
              Get.back();
            }
          }
        });
    isLoading = false;
    notifyListeners();
  }

  void animateToSource() {
    osmMapController.move(
      location.LatLng(
        driverUserModel.location!.latitude ?? 0.0,
        driverUserModel.location!.longitude ?? 0.0,
      ),
      16,
    );
  }

  List<location.LatLng> routePoints = <location.LatLng>[];

  Future<void> fetchRoute(
    location.LatLng source,
    location.LatLng destination,
  ) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/${source.longitude},${source.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final geometry = decoded['routes'][0]['geometry']['coordinates'];

      routePoints.clear();
      for (var coord in geometry) {
        final lon = coord[0];
        final lat = coord[1];
        routePoints.add(location.LatLng(lat, lon));
      }
    } else {
      print("Failed to get route: ${response.body}");
    }
  }

  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? driverIcon;

  void getPolyline({
    required double? sourceLatitude,
    required double? sourceLongitude,
    required double? destinationLatitude,
    required double? destinationLongitude,
  }) async {
    if (sourceLatitude != null &&
        sourceLongitude != null &&
        destinationLatitude != null &&
        destinationLongitude != null) {
      List<LatLng> polylineCoordinates = [];
      PolylineRequest polylineRequest = PolylineRequest(
        origin: PointLatLng(sourceLatitude, sourceLongitude),
        destination: PointLatLng(destinationLatitude, destinationLongitude),
        mode: TravelMode.driving,
      );

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: polylineRequest,
      );
      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      } else {
        print(result.errorMessage.toString());
      }
      if (orderModel.status == Constant.orderShipped) {
        addMarker(
          latitude: driverUserModel.location!.latitude,
          longitude: driverUserModel.location!.longitude,
          id: "Driver",
          descriptor: driverIcon!,
          rotation: double.parse(driverUserModel.rotation.toString()),
        );
        addMarker(
          latitude: orderModel.vendor!.latitude,
          longitude: orderModel.vendor!.longitude,
          id: "Departure",
          descriptor: departureIcon!,
          rotation: 0.0,
        );
      } else if (orderModel.status == Constant.orderInTransit) {
        addMarker(
          latitude: driverUserModel.location!.latitude,
          longitude: driverUserModel.location!.longitude,
          id: "Driver",
          descriptor: driverIcon!,
          rotation: double.parse(driverUserModel.rotation.toString()),
        );
        addMarker(
          latitude: orderModel.address!.location!.latitude,
          longitude: orderModel.address!.location!.longitude,
          id: "Destination",
          descriptor: destinationIcon!,
          rotation: 0.0,
        );
      } else {
        addMarker(
          latitude: orderModel.vendor!.latitude,
          longitude: orderModel.vendor!.longitude,
          id: "Departure",
          descriptor: departureIcon!,
          rotation: 0.0,
        );
        addMarker(
          latitude: orderModel.address!.location!.latitude,
          longitude: orderModel.address!.location!.longitude,
          id: "Destination",
          descriptor: destinationIcon!,
          rotation: 0.0,
        );
      }

      _addPolyLine(polylineCoordinates);
    }
  }

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  addMarker({
    required double? latitude,
    required double? longitude,
    required String id,
    required BitmapDescriptor descriptor,
    required double? rotation,
  }) {
    MarkerId markerId = MarkerId(id);
    Marker marker = Marker(
      markerId: markerId,
      icon: descriptor,
      position: LatLng(latitude ?? 0.0, longitude ?? 0.0),
      rotation: rotation ?? 0.0,
    );
    markers[markerId] = marker;
  }

  addMarkerSetup() async {
    if (Constant.selectedMapType != 'osm') {
      final Uint8List departure = await Constant().getBytesFromAsset(
        'assets/images/pickup.png',
        100,
      );
      final Uint8List destination = await Constant().getBytesFromAsset(
        'assets/images/dropoff.png',
        100,
      );
      final Uint8List driver = await Constant().getBytesFromAsset(
        'assets/images/food_delivery.png',
        100,
      );
      departureIcon = BitmapDescriptor.bytes(departure);
      destinationIcon = BitmapDescriptor.bytes(destination);
      driverIcon = BitmapDescriptor.bytes(driver);
    } else {}
  }

  Map<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{};
  PolylinePoints polylinePoints = PolylinePoints(apiKey: Constant.mapAPIKey);

  _addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      points: polylineCoordinates,
      consumeTapEvents: true,
      startCap: Cap.roundCap,
      width: 6,
    );
    polyLines[id] = polyline;
    updateCameraLocation(
      polylineCoordinates.first,
      polylineCoordinates.last,
      mapController,
    );
  }

  Future<void> updateCameraLocation(
    LatLng source,
    LatLng destination,
    GoogleMapController? mapController,
  ) async {
    if (mapController == null) return;

    LatLngBounds bounds;

    if (source.latitude > destination.latitude &&
        source.longitude > destination.longitude) {
      bounds = LatLngBounds(southwest: destination, northeast: source);
    } else if (source.longitude > destination.longitude) {
      bounds = LatLngBounds(
        southwest: LatLng(source.latitude, destination.longitude),
        northeast: LatLng(destination.latitude, source.longitude),
      );
    } else if (source.latitude > destination.latitude) {
      bounds = LatLngBounds(
        southwest: LatLng(destination.latitude, source.longitude),
        northeast: LatLng(source.latitude, destination.longitude),
      );
    } else {
      bounds = LatLngBounds(southwest: source, northeast: destination);
    }

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 10);

    return checkCameraLocation(cameraUpdate, mapController);
  }

  Future<void> checkCameraLocation(
    CameraUpdate cameraUpdate,
    GoogleMapController mapController,
  ) async {
    mapController.animateCamera(cameraUpdate);
    LatLngBounds l1 = await mapController.getVisibleRegion();
    LatLngBounds l2 = await mapController.getVisibleRegion();

    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      return checkCameraLocation(cameraUpdate, mapController);
    }
  }
}
