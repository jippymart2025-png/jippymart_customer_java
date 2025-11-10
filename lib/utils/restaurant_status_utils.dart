import 'package:flutter/material.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/restaurant_status_manager.dart';

/// **Restaurant Status Utilities**
///
/// Provides helper methods for restaurant status checks across the app.
/// This class centralizes status logic and provides consistent behavior.
class RestaurantStatusUtils {
  static final RestaurantStatusManager _statusManager =
      RestaurantStatusManager();

  /// **CHECK IF RESTAURANT IS OPEN**
  ///
  /// Uses the failproof system to determine if a restaurant is open
  /// @param vendor - The restaurant vendor model
  /// @return true if restaurant is open, false otherwise
  static bool isRestaurantOpen(VendorModel vendor) {
    return _statusManager.isRestaurantOpenNow(
      vendor.workingHours,
      vendor.isOpen,
    );
  }

  /// **GET RESTAURANT STATUS INFO**
  ///
  /// Returns comprehensive status information for a restaurant
  /// @param vendor - The restaurant vendor model
  /// @return Map containing status information
  static Map<String, dynamic> getRestaurantStatus(VendorModel vendor) {
    return _statusManager.getRestaurantStatus(
      vendor.workingHours,
      vendor.isOpen,
    );
  }

  /// **CHECK IF RESTAURANT CAN ACCEPT ORDERS**
  ///
  /// Determines if a restaurant can accept orders based on status
  /// @param vendor - The restaurant vendor model
  /// @return true if orders can be accepted, false otherwise
  // static bool canAcceptOrders(VendorModel vendor) {
  //   return isRestaurantOpen(vendor);
  // }

  static bool canAcceptOrders(VendorModel vendor) {
    return vendor.isOpen == true && vendor.isActive == true;
  }

  static Widget getStatusWidget(VendorModel vendor) {
    final status = getRestaurantStatus(vendor);
    final isClosed = !canAcceptOrders(vendor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      // Keep original padding
      decoration: BoxDecoration(
        color: isClosed ? Colors.red[600] : status['statusColor'],
        borderRadius: BorderRadius.circular(24), // Keep original border radius
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isClosed ? Icons.lock : status['statusIcon'],
            color: Colors.white,
            size: 16, // Keep original size
          ),
          const SizedBox(width: 6), // Keep original spacing
          Text(
            isClosed ? 'Closed' : status['statusText'],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold, // Keep original weight
              fontSize: 12, // Keep original size
            ),
          ),
        ],
      ),
    );
  }
}
