import 'dart:async';
import 'dart:convert';

import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/widget/osm_map/place_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:jippymart_customer/utils/preferences.dart';

class OSMMapController extends GetxController {
  // Store only one picked place instead of multiple
  var pickedPlace = Rxn<PlaceModel>(); // Use Rxn to hold a nullable value
  var searchResults = [].obs;
  var isLoadingSearch = false.obs;
  var isLoadingAddress = false.obs;
  
  // Debouncing for search
  Timer? _searchDebounce;
  
  // Cache for reverse geocoding to avoid repeated API calls
  final Map<String, String> _addressCache = {};
  
  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  Future<void> searchPlace(String query) async {
    // Cancel previous debounce timer
    _searchDebounce?.cancel();
    
    if (query.length < 3) {
      searchResults.clear();
      isLoadingSearch.value = false;
      return;
    }

    isLoadingSearch.value = true;
    
    // Debounce: wait 500ms before making API call
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      await _performSearch(query);
    });
  }
  
  Future<void> _performSearch(String query) async {
    // Use Google Maps Geocoding API with dynamic API key from backend
    final apiKey = _getApiKey();
    
    if (apiKey.isEmpty) {
      // Don't show error to user - just clear results silently
      searchResults.clear();
      isLoadingSearch.value = false;
      return;
    }
    
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&key=$apiKey'
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] != null) {
          // Convert Google Maps format to match expected format
          final results = (data['results'] as List).map((result) {
            return {
              'lat': result['geometry']['location']['lat'].toString(),
              'lon': result['geometry']['location']['lng'].toString(),
              'display_name': result['formatted_address'],
              'place_id': result['place_id'],
            };
          }).toList();
          searchResults.value = results;
        } else {
          // Handle different error statuses silently
          searchResults.clear();
          final status = data['status'] ?? 'UNKNOWN_ERROR';
          
          // Don't show "access blocked" or "REQUEST_DENIED" to user
          // Just log it for debugging
          if (status == 'REQUEST_DENIED' || status == 'OVER_QUERY_LIMIT') {
            print('[MAP] ⚠️ Google Maps API error: $status - Results cleared silently');
            // Try to reload API key from local storage
            _reloadApiKeyFromLocalStorage();
          } else {
            print('[MAP] ⚠️ Google Maps API returned status: $status');
          }
        }
      } else {
        searchResults.clear();
        print('[MAP] ⚠️ HTTP error ${response.statusCode} - Results cleared silently');
      }
    } catch (e) {
      searchResults.clear();
      print('[MAP] ⚠️ Error searching location: $e - Results cleared silently');
    } finally {
      isLoadingSearch.value = false;
    }
  }

  void selectSearchResult(Map<String, dynamic> place) {
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);
    final address = place['display_name'];

    // Store only the selected place
    pickedPlace.value = PlaceModel(
      coordinates: LatLng(lat, lon),
      address: address,
    );
    searchResults.clear();
  }

  void addLatLngOnly(LatLng coords) async {
    // Set coordinates immediately for better UX
    pickedPlace.value = PlaceModel(
      coordinates: coords,
      address: 'Loading address...',
    );
    
    // Fetch address in background
    isLoadingAddress.value = true;
    final address = await _getAddressFromLatLng(coords);
    isLoadingAddress.value = false;
    
    pickedPlace.value = PlaceModel(coordinates: coords, address: address);
  }

  Future<String> _getAddressFromLatLng(LatLng coords) async {
    // Create cache key (round to 4 decimal places to cache nearby locations)
    final cacheKey = '${coords.latitude.toStringAsFixed(4)},${coords.longitude.toStringAsFixed(4)}';
    
    // Check cache first
    if (_addressCache.containsKey(cacheKey)) {
      return _addressCache[cacheKey]!;
    }
    
    // Use Google Maps Reverse Geocoding API with dynamic API key from backend
    final apiKey = _getApiKey();
    
    if (apiKey.isEmpty) {
      return 'Unknown location';
    }
    
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=${coords.latitude},${coords.longitude}&key=$apiKey'
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          final address = data['results'][0]['formatted_address'] ?? 'Unknown location';
          // Cache the result
          _addressCache[cacheKey] = address;
          // Limit cache size to prevent memory issues
          if (_addressCache.length > 50) {
            _addressCache.remove(_addressCache.keys.first);
          }
          return address;
        } else {
          // Handle API errors silently - don't show "access blocked"
          final status = data['status'] ?? 'UNKNOWN_ERROR';
          if (status == 'REQUEST_DENIED' || status == 'OVER_QUERY_LIMIT') {
            print('[MAP] ⚠️ Reverse geocoding API error: $status - Trying to reload key');
            _reloadApiKeyFromLocalStorage();
          }
          return 'Unknown location';
        }
      } else {
        return 'Unknown location';
      }
    } catch (e) {
      print('[MAP] ⚠️ Error getting address: $e');
      return 'Unknown location';
    }
  }

  void clearAll() {
    pickedPlace.value = null; // Clear the selected place
  }
  
  /// Get API key - Priority: Backend → Local Storage → Static Fallback
  /// Falls back gracefully to prevent "access blocked" errors
  String _getApiKey() {
    // Priority 1: Check current value from backend settings
    final currentKey = Constant.mapAPIKey.trim();
    
    if (currentKey.isNotEmpty && currentKey.length > 10) {
      return currentKey;
    }
    
    // Priority 2: Try local storage
    try {
      final localKey = Preferences.getString(Preferences.googleMapsApiKey);
      if (localKey.isNotEmpty && localKey.length > 10) {
        // Update Constant so it's available for next time
        Constant.mapAPIKey = localKey;
        print('[MAP] ✅ Using API key from local storage');
        return localKey;
      }
    } catch (e) {
      print('[MAP] ⚠️ Error reading from local storage: $e');
    }
    
    // Priority 3: Static fallback (last resort)
    print('[MAP] ⚠️ Using static fallback API key');
    return 'AIzaSyCKCRzqaR1-uzbnEmB-JqVkbUKNGOJHv34';
  }
  
  /// Reload API key from local storage (used when API errors occur)
  void _reloadApiKeyFromLocalStorage() {
    try {
      final localKey = Preferences.getString(Preferences.googleMapsApiKey);
      if (localKey.isNotEmpty && localKey.length > 10) {
        Constant.mapAPIKey = localKey;
        print('[MAP] ✅ Reloaded API key from local storage after error');
      }
    } catch (e) {
      print('[MAP] ⚠️ Error reloading from local storage: $e');
    }
  }
}
