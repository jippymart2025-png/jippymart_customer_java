import 'package:flutter/material.dart';
import 'package:jippymart_customer/models/vendor_model.dart';

/// Restaurant Open / Close Status Manager
///
/// Uses the new OutletTiming structure:
///
/// {
///   "day": "Monday",
///   "isOpen": true,
///   "openingTime": "09:00:00",
///   "closingTime": "20:00:00"
/// }
///
/// Restaurant is OPEN only when:
/// 1. Today's timing exists
/// 2. Today's isOpen == true
/// 3. Current time is inside today's opening/closing time
class RestaurantStatusManager {
  static final RestaurantStatusManager _instance =
      RestaurantStatusManager._internal();

  factory RestaurantStatusManager() => _instance;

  RestaurantStatusManager._internal();

  // ============================================================
  // MAIN STATUS CHECK
  // ============================================================

  bool isRestaurantOpenNow(
    List<OutletTiming>? outletTimings, {
    bool? apiOpenNow,
  }) {
    debugPrint('[RESTAURANT_STATUS] Checking restaurant status');

    // No timings = closed for safety.
    if (outletTimings == null || outletTimings.isEmpty) {
      debugPrint('[RESTAURANT_STATUS] No outlet timings found');

      return false;
    }

    final OutletTiming? todayTiming = _getTodayTiming(outletTimings);

    if (todayTiming == null) {
      debugPrint('[RESTAURANT_STATUS] No timing found for today');

      return false;
    }

    debugPrint('[RESTAURANT_STATUS] Today: ${todayTiming.day}');

    debugPrint('[RESTAURANT_STATUS] isOpen: ${todayTiming.isOpen}');

    debugPrint('[RESTAURANT_STATUS] Opening: ${todayTiming.openingTime}');

    debugPrint('[RESTAURANT_STATUS] Closing: ${todayTiming.closingTime}');

    // ----------------------------------------------------------
    // API says today's restaurant is manually closed
    // ----------------------------------------------------------

    if (!todayTiming.isOpen) {
      debugPrint('[RESTAURANT_STATUS] CLOSED - isOpen is false');

      return false;
    }

    // ----------------------------------------------------------
    // Missing timing
    // ----------------------------------------------------------

    if (todayTiming.openingTime == null ||
        todayTiming.closingTime == null ||
        todayTiming.openingTime!.isEmpty ||
        todayTiming.closingTime!.isEmpty) {
      debugPrint('[RESTAURANT_STATUS] OPEN - no time restriction configured');

      return true;
    }

    // ----------------------------------------------------------
    // Check current time
    // ----------------------------------------------------------

    final bool withinHours = _isCurrentTimeWithinRange(
      todayTiming.openingTime!,
      todayTiming.closingTime!,
    );

    debugPrint('[RESTAURANT_STATUS] Within working hours: $withinHours');

    if (!withinHours) {
      debugPrint('[RESTAURANT_STATUS] CLOSED - outside working hours');

      return false;
    }

    debugPrint('[RESTAURANT_STATUS] OPEN');

    return true;
  }

  // ============================================================
  // GET DETAILED STATUS
  // ============================================================

  Map<String, dynamic> getRestaurantStatus(
    List<OutletTiming>? outletTimings, {
    bool? openNow,
  }) {
    final OutletTiming? todayTiming = _getTodayTiming(outletTimings);

    final bool hasTimings = outletTimings != null && outletTimings.isNotEmpty;

    final bool isOpen = isRestaurantOpenNow(outletTimings, apiOpenNow: openNow);

    String reason;
    Color statusColor;
    IconData statusIcon;
    String statusText;

    // ----------------------------------------------------------
    // No timing
    // ----------------------------------------------------------

    if (!hasTimings) {
      reason = 'Restaurant timing not available';
      statusColor = Colors.red;
      statusIcon = Icons.schedule;
      statusText = 'Closed';
    }
    // ----------------------------------------------------------
    // Today manually closed
    // ----------------------------------------------------------
    else if (todayTiming != null && !todayTiming.isOpen) {
      reason = 'Restaurant is closed today';
      statusColor = Colors.red;
      statusIcon = Icons.lock;
      statusText = 'Closed';
    }
    // ----------------------------------------------------------
    // Outside working hours
    // ----------------------------------------------------------
    else if (!isOpen) {
      reason = 'Outside working hours';
      statusColor = Colors.red;
      statusIcon = Icons.access_time;
      statusText = 'Closed';
    }
    // ----------------------------------------------------------
    // Open
    // ----------------------------------------------------------
    else {
      reason = 'Open now';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Open';
    }

    return {
      'isOpen': isOpen,

      'reason': reason,

      'statusColor': statusColor,

      'statusIcon': statusIcon,

      'statusText': statusText,

      'hasWorkingHours': hasTimings,

      'todayTiming': todayTiming,

      'openingTime': todayTiming?.openingTime,

      'closingTime': todayTiming?.closingTime,

      'currentDay': _getCurrentDay(),

      'currentTime': _formatCurrentTime(),
    };
  }

  // ============================================================
  // GET TODAY'S TIMING
  // ============================================================

  OutletTiming? _getTodayTiming(List<OutletTiming>? outletTimings) {
    if (outletTimings == null || outletTimings.isEmpty) {
      return null;
    }

    final String today = _getCurrentDay();

    for (final OutletTiming timing in outletTimings) {
      if (timing.day.toLowerCase().trim() == today.toLowerCase().trim()) {
        return timing;
      }
    }

    return null;
  }

  // ============================================================
  // PUBLIC TODAY TIMING
  // ============================================================

  OutletTiming? getTodayTiming(List<OutletTiming>? outletTimings) {
    return _getTodayTiming(outletTimings);
  }

  // ============================================================
  // CURRENT DAY
  // ============================================================

  String _getCurrentDay() {
    const List<String> days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return days[DateTime.now().weekday - 1];
  }

  // ============================================================
  // CURRENT TIME
  // ============================================================

  String _formatCurrentTime() {
    final DateTime now = DateTime.now();

    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // CHECK CURRENT TIME
  // ============================================================

  bool _isCurrentTimeWithinRange(String openingTime, String closingTime) {
    final DateTime now = DateTime.now();

    final int currentMinutes = now.hour * 60 + now.minute;

    final int? openingMinutes = _timeToMinutes(openingTime);

    final int? closingMinutes = _timeToMinutes(closingTime);

    if (openingMinutes == null || closingMinutes == null) {
      return false;
    }

    debugPrint(
      '[RESTAURANT_STATUS] '
      'Current: $currentMinutes '
      'Opening: $openingMinutes '
      'Closing: $closingMinutes',
    );

    // ----------------------------------------------------------
    // Same-day timing
    //
    // Example:
    // 09:00 -> 20:00
    // ----------------------------------------------------------

    if (closingMinutes > openingMinutes) {
      return currentMinutes >= openingMinutes &&
          currentMinutes <= closingMinutes;
    }

    // ----------------------------------------------------------
    // Same exact time
    //
    // Example:
    // 00:00 -> 00:00
    //
    // Treat as open all day.
    // ----------------------------------------------------------

    if (closingMinutes == openingMinutes) {
      return true;
    }

    // ----------------------------------------------------------
    // Overnight timing
    //
    // Example:
    // 20:00 -> 02:00
    // ----------------------------------------------------------

    return currentMinutes >= openingMinutes || currentMinutes <= closingMinutes;
  }

  // ============================================================
  // TIME STRING -> MINUTES
  // ============================================================

  int? _timeToMinutes(String time) {
    try {
      final List<String> parts = time.split(':');

      if (parts.length < 2) {
        return null;
      }

      final int? hours = int.tryParse(parts[0]);

      final int? minutes = int.tryParse(parts[1]);

      if (hours == null || minutes == null) {
        return null;
      }

      if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) {
        return null;
      }

      return hours * 60 + minutes;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // VALIDATE TIMINGS
  // ============================================================

  bool validateWorkingHours(List<OutletTiming>? outletTimings) {
    if (outletTimings == null || outletTimings.isEmpty) {
      return false;
    }

    for (final OutletTiming timing in outletTimings) {
      if (timing.day.trim().isEmpty) {
        return false;
      }

      // If the day is closed, time values are not mandatory.
      if (!timing.isOpen) {
        continue;
      }

      if (timing.openingTime == null || timing.closingTime == null) {
        return false;
      }

      if (_timeToMinutes(timing.openingTime!) == null) {
        return false;
      }

      if (_timeToMinutes(timing.closingTime!) == null) {
        return false;
      }
    }

    return true;
  }

  // ============================================================
  // GET NEXT OPENING TIME
  // ============================================================

  String? getNextOpeningTime(List<OutletTiming>? outletTimings) {
    if (outletTimings == null || outletTimings.isEmpty) {
      return null;
    }

    final DateTime now = DateTime.now();

    final int todayIndex = now.weekday - 1;

    const List<String> days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    // ----------------------------------------------------------
    // Check today's remaining time
    // ----------------------------------------------------------

    final String today = days[todayIndex];

    final OutletTiming? todayTiming = _findTiming(outletTimings, today);

    if (todayTiming != null &&
        todayTiming.isOpen &&
        todayTiming.openingTime != null) {
      final int? opening = _timeToMinutes(todayTiming.openingTime!);

      final int current = now.hour * 60 + now.minute;

      if (opening != null && opening > current) {
        return '${todayTiming.openingTime} (Today)';
      }
    }

    // ----------------------------------------------------------
    // Check next 7 days
    // ----------------------------------------------------------

    for (int i = 1; i <= 7; i++) {
      final int nextIndex = (todayIndex + i) % 7;

      final String nextDay = days[nextIndex];

      final OutletTiming? timing = _findTiming(outletTimings, nextDay);

      if (timing != null && timing.isOpen && timing.openingTime != null) {
        return '${timing.openingTime} ($nextDay)';
      }
    }

    return null;
  }

  // ============================================================
  // FIND TIMING BY DAY
  // ============================================================

  OutletTiming? _findTiming(List<OutletTiming> outletTimings, String day) {
    for (final OutletTiming timing in outletTimings) {
      if (timing.day.toLowerCase() == day.toLowerCase()) {
        return timing;
      }
    }

    return null;
  }

  // ============================================================
  // UPDATE UI
  // ============================================================

  void updateRestaurantStatusUI(
    Map<String, dynamic> status, {
    Function(bool)? onStatusChange,
    Function(String)? onStatusMessageChange,
  }) {
    if (onStatusChange != null) {
      onStatusChange(status['isOpen'] == true);
    }

    if (onStatusMessageChange != null) {
      onStatusMessageChange(status['reason']?.toString() ?? 'Unknown status');
    }
  }
}
