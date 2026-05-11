import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/widget/osm_map/map_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final OSMMapController controller = Get.put(OSMMapController());
  final TextEditingController searchController = TextEditingController();
  GoogleMapController? mapController;
  LatLng _currentPosition = const LatLng(20.5937, 78.9629); // Default India center
  Set<Marker> _markers = {};

  void _updateMarker(latlong.LatLng? coords) {
    if (coords != null && mounted) {
      final googleLatLng = LatLng(coords.latitude, coords.longitude);
      setState(() {
        _currentPosition = googleLatLng;
        _markers = {
          Marker(
            markerId: const MarkerId('picked_location'),
            position: googleLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        };
      });
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(googleLatLng, 15));
    }
  }

  @override
  void initState() {
    super.initState();
    // Update marker if place already exists
    if (controller.pickedPlace.value != null) {
      _updateMarker(controller.pickedPlace.value!.coordinates);
    }
    // Current location will be fetched after map is created
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position? position;
      
      try {
        // Use faster location accuracy for better performance
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        ).timeout(const Duration(seconds: 6));
      } catch (e) {
        // Fallback to last known position if timeout or error
        position = await Geolocator.getLastKnownPosition();
      }
      
      if (position != null && mounted) {
        final currentLatLng = LatLng(position.latitude, position.longitude);
        final latlongCoords = latlong.LatLng(position.latitude, position.longitude);
        
        setState(() {
          _currentPosition = currentLatLng;
        });
        
        // Center map on current location with smooth animation
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(currentLatLng, 15),
        );
        
        // Set marker and update picked place with current location
        _updateMarker(latlongCoords);
        controller.addLatLngOnly(latlongCoords);
      }
    } catch (e) {
      // Silently fail - map will show default location
      print('Error getting current location: $e');
    }
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppThemeData.surface,
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          "PickUp Location".tr,
          textAlign: TextAlign.start,
          style: TextStyle(
            fontFamily: AppThemeData.medium,
            fontSize: 16,
            color: AppThemeData.grey900,
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: controller.pickedPlace.value != null
                  ? LatLng(
                      controller.pickedPlace.value!.coordinates.latitude,
                      controller.pickedPlace.value!.coordinates.longitude,
                    )
                  : _currentPosition,
              zoom: 15,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
            onMapCreated: (GoogleMapController googleMapController) async {
              mapController = googleMapController;
              // Get current location after map is created (only if no place is already selected)
              if (controller.pickedPlace.value == null) {
                // Small delay to ensure map is fully rendered
                await Future.delayed(const Duration(milliseconds: 300));
                _getCurrentLocation();
              }
            },
            onTap: (LatLng position) {
              final latlongCoords = latlong.LatLng(position.latitude, position.longitude);
              _updateMarker(latlongCoords);
              controller.addLatLngOnly(latlongCoords);
            },
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search location...',
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      controller.searchPlace(value);
                    },
                  ),
                ),
                Obx(() => controller.isLoadingSearch.value
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _buildSearchResults()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.pickedPlace.value != null
                  ? "Picked Location:"
                  : "No Location Picked",
              style: TextStyle(
                color: AppThemeData.primary300,
                fontFamily: AppThemeData.semiBold,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            if (controller.pickedPlace.value != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Obx(() => Text(
                  controller.isLoadingAddress.value
                      ? "Loading address..."
                      : "${controller.pickedPlace.value!.address}\n(${controller.pickedPlace.value!.coordinates.latitude.toStringAsFixed(5)}, ${controller.pickedPlace.value!.coordinates.longitude.toStringAsFixed(5)})",
                  style: const TextStyle(fontSize: 13),
                )),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: RoundedButtonFill(
                    title: "Conform Location".tr,
                    color: AppThemeData.primary300,
                    textColor: AppThemeData.grey50,
                    height: 5,
                    onPress: () async {
                      final selected = controller.pickedPlace.value;
                      if (selected != null) {
                        Get.back(
                          result: selected,
                        ); // ✅ Return the selected place
                        print("Selected location: $selected");
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () {
                    controller.clearAll();
                    setState(() {
                      _markers = {};
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build search results
  Widget _buildSearchResults() {
    final searchResults = controller.searchResults;

    if (searchResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          final place = searchResults[index];
          return ListTile(
            title: Text(place['display_name']),
            onTap: () {
              controller.selectSearchResult(place);
              final lat = double.parse(place['lat']);
              final lon = double.parse(place['lon']);
              final pos = LatLng(lat, lon);
              final latlongCoords = latlong.LatLng(lat, lon);
              _updateMarker(latlongCoords);
              mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
              searchController.text = place['display_name'];
            },
          );
        },
      ),
    );
  }
}
