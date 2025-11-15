import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:flutter_map/flutter_map.dart' as flutterMap;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
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
  location.LatLng destination = location.LatLng(21.2000, 72.8600);

  Timer? _orderTrackingTimer;
  StreamSubscription? _orderTrackingSubscription;

  getArgument({required OrderModel orderModel}) async {
    // Cancel any existing timers/subscriptions
    _orderTrackingTimer?.cancel();
    _orderTrackingSubscription?.cancel();

    // Start periodic tracking
    _startOrderTracking(orderModel);

    isLoading = false;
    notifyListeners();
  }

  void _startOrderTracking(OrderModel orderModel) {
    // Fetch immediately first time
    _fetchOrderAndUpdate(orderModel);

    // Then set up periodic polling every 10 seconds
    _orderTrackingTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _fetchOrderAndUpdate(orderModel);
    });
  }

  Future<void> _fetchOrderAndUpdate(OrderModel initialOrderModel) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}order/${initialOrderModel.id}/tracking'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Update order model from API response
        OrderModel orderModelStream = OrderModel.fromJson(data['order']);
        this.orderModel = orderModelStream;

        // Update driver model from API response
        if (data['driver'] != null) {
          driverUserModel = UserModel.fromJson(data['driver']);

          // Handle polyline based on order status
          await _handlePolylineAndRouting(orderModelStream, data);
        }

        // Check if order is completed
        if (orderModelStream.status == Constant.orderCompleted) {
          _orderTrackingTimer?.cancel();
          _orderTrackingSubscription?.cancel();
          Get.back();
        }

        notifyListeners();
      } else {
        print('Failed to fetch order tracking: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching order tracking: $e');
    }
  }

  Future<void> _handlePolylineAndRouting(
    OrderModel orderModel,
    Map<String, dynamic> data,
  ) async {
    if (Constant.selectedMapType != 'osm') {
      // Google Maps logic
      if (orderModel.status == Constant.orderShipped) {
        await getPolyline(
          sourceLatitude: driverUserModel.location!.latitude,
          sourceLongitude: driverUserModel.location!.longitude,
          destinationLatitude: orderModel.vendor!.latitude,
          destinationLongitude: orderModel.vendor!.longitude,
        );
      } else if (orderModel.status == Constant.orderInTransit) {
        await getPolyline(
          sourceLatitude: driverUserModel.location!.latitude,
          sourceLongitude: driverUserModel.location!.longitude,
          destinationLatitude: orderModel.address!.location!.latitude,
          destinationLongitude: orderModel.address!.location!.longitude,
        );
      } else {
        await getPolyline(
          sourceLatitude: orderModel.address!.location!.latitude,
          sourceLongitude: orderModel.address!.location!.longitude,
          destinationLatitude: orderModel.vendor!.latitude,
          destinationLongitude: orderModel.vendor!.longitude,
        );
      }
    } else {
      // OSM routing logic
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
        await fetchRoute(current, source);
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
        await fetchRoute(current, destination);
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
        await fetchRoute(current, source);
        animateToSource();
      }
    }
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
    try {
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
        notifyListeners();
      } else {
        print("Failed to get route: ${response.body}");
      }
    } catch (e) {
      print("Error fetching route: $e");
    }
  }

  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? driverIcon;

  Future<void> getPolyline({
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

      // Clear existing markers
      markers.clear();

      if (orderModel.status == Constant.orderShipped) {
        addMarker(
          latitude: driverUserModel.location!.latitude,
          longitude: driverUserModel.location!.longitude,
          id: "Driver",
          descriptor: driverIcon!,
          rotation: double.parse(driverUserModel.rotation?.toString() ?? "0"),
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
          rotation: double.parse(driverUserModel.rotation?.toString() ?? "0"),
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
      notifyListeners();
    }
  }

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  void addMarker({
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

  Future<void> addMarkerSetup() async {
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
      departureIcon = BitmapDescriptor.fromBytes(departure);
      destinationIcon = BitmapDescriptor.fromBytes(destination);
      driverIcon = BitmapDescriptor.fromBytes(driver);
    }
  }

  Map<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{};
  PolylinePoints polylinePoints = PolylinePoints(apiKey: Constant.mapAPIKey);

  void _addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      points: polylineCoordinates,
      color: Colors.blue,
      width: 5,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
    polyLines[id] = polyline;

    if (polylineCoordinates.isNotEmpty) {
      updateCameraLocation(
        polylineCoordinates.first,
        polylineCoordinates.last,
        mapController,
      );
    }
    notifyListeners();
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

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 100);

    return checkCameraLocation(cameraUpdate, mapController);
  }

  Future<void> checkCameraLocation(
    CameraUpdate cameraUpdate,
    GoogleMapController mapController,
  ) async {
    try {
      await mapController.animateCamera(cameraUpdate);
      LatLngBounds visibleRegion = await mapController.getVisibleRegion();

      // Check if the bounds are valid (not at edge of world)
      if (visibleRegion.southwest.latitude == -90 ||
          visibleRegion.northeast.latitude == 90) {
        // Retry with different padding
        await mapController.animateCamera(cameraUpdate);
      }
    } catch (e) {
      print("Error checking camera location: $e");
    }
  }

  // Dispose method to clean up resources
  @override
  void dispose() {
    _orderTrackingTimer?.cancel();
    _orderTrackingSubscription?.cancel();
    super.dispose();
  }
}
