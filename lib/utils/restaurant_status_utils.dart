import 'package:flutter/material.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/restaurant_status_manager.dart';

/// Restaurant Status Utilities
///
/// Centralizes restaurant open/close status handling.
///
/// The final status is determined from:
/// 1. Outlet timing for today's day
/// 2. Today's isOpen value
/// 3. Current time vs opening/closing time
class RestaurantStatusUtils {
  static final RestaurantStatusManager _statusManager =
      RestaurantStatusManager();

  // ============================================================
  // CHECK IF RESTAURANT IS OPEN
  // ============================================================

  static bool isRestaurantOpen(VendorModel vendor) {
    // API says restaurant is open → consider it OPEN
    if (vendor.openNow == true) {
      return true;
    }

    // Otherwise check outlet timings
    return _statusManager.isRestaurantOpenNow(
      vendor.outletTimings,
      apiOpenNow: vendor.openNow,
    );
  }

  // ============================================================
  // GET RESTAURANT STATUS
  // ============================================================

  static Map<String, dynamic> getRestaurantStatus(VendorModel vendor) {
    return _statusManager.getRestaurantStatus(
      vendor.outletTimings,
      openNow: vendor.openNow,
    );
  }

  // ============================================================
  // CHECK IF RESTAURANT CAN ACCEPT ORDERS
  // ============================================================

  static bool canAcceptOrders(VendorModel vendor) {
    return isRestaurantOpen(vendor);
  }

  // ============================================================
  // STATUS WIDGET
  // ============================================================

  static Widget getStatusWidget(VendorModel vendor) {
    final Map<String, dynamic> status = getRestaurantStatus(vendor);

    final bool isOpen = status['isOpen'] == true;

    final bool isClosed = !isOpen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isClosed ? Colors.red[600] : status['statusColor'] as Color?,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isClosed ? Icons.lock : status['statusIcon'] as IconData?,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isClosed ? 'Closed' : status['statusText']?.toString() ?? 'Open',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GET STATUS TEXT
  // ============================================================

  static String getStatusText(VendorModel vendor) {
    final status = getRestaurantStatus(vendor);

    return status['statusText']?.toString() ?? 'Closed';
  }

  // ============================================================
  // GET STATUS REASON
  // ============================================================

  static String getStatusReason(VendorModel vendor) {
    final status = getRestaurantStatus(vendor);

    return status['reason']?.toString() ?? 'Restaurant is closed';
  }

  // ============================================================
  // GET TODAY'S TIMING
  // ============================================================

  static OutletTiming? getTodayTiming(VendorModel vendor) {
    return _statusManager.getTodayTiming(vendor.outletTimings);
  }

  // ============================================================
  // GET NEXT OPENING TIME
  // ============================================================

  static String? getNextOpeningTime(VendorModel vendor) {
    return _statusManager.getNextOpeningTime(vendor.outletTimings);
  }

  // ============================================================
  // VALIDATE OUTLET TIMINGS
  // ============================================================

  static bool validateWorkingHours(VendorModel vendor) {
    return _statusManager.validateWorkingHours(vendor.outletTimings);
  }
}
