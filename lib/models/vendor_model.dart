class VendorModel {
  // ============================================================
  // EXISTING APP / VENDOR FIELDS
  // ============================================================

  String? id;
  String? title;
  String? photo;
  String? phonenumber;

  double? reviewsSum;
  int? reviewsCount;

  double? distance;

  bool isOpen;
  bool isActive;
  bool isFavourite;

  String? vType;
  List<String>? categoryTitle;

  // ============================================================
  // OUTLET API FIELDS
  // ============================================================

  int? outletId;
  String? outletName;
  String? cuisineType;
  String? outletPhone;

  double? radius;
  dynamic review;

  double? distanceKm;
  String? roadDistance;
  String? deliveryTime;

  bool? subscriptionStatus;
  bool? promotionStatus;

  // ============================================================
  // OUTLET TIMINGS
  // ============================================================

  List<OutletTiming>? outletTimings;

  String? openingTime;
  String? closingTime;
  bool? openNow;

  // ============================================================
  // ACTIVE DISCOUNT
  // ============================================================

  int? promotionScheduleId;
  String? sourceType;
  int? sourceId;

  double? minOrderValue;
  String? priceType;
  double? discountAmount;

  int? usageLimitPerUser;

  String? couponCode;

  String? startDateTime;
  String? endDateTime;

  String? remainingTime;

  String? planType;
  String? offerName;

  // ============================================================
  // BACKWARD COMPATIBILITY / SYSTEM FIELDS
  // ============================================================

  dynamic author;
  String? fcmToken;
  double? latitude;
  double? longitude;
  String? location;
  bool? isSelfDelivery;
  String? zoneId;
  List<dynamic>? categoryID;
  dynamic subscriptionPlan;
  String? subscriptionTotalOrders;
  dynamic subscriptionExpiryDate;
  dynamic deliveryCharge;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  VendorModel({
    this.id,
    this.title,
    this.photo,
    this.phonenumber,

    this.reviewsSum,
    this.reviewsCount,

    this.distance,

    this.isOpen = false,
    this.isActive = true,
    this.isFavourite = false,

    this.vType,
    this.categoryTitle,

    this.outletId,
    this.outletName,
    this.cuisineType,
    this.outletPhone,

    this.radius,
    this.review,

    this.distanceKm,
    this.roadDistance,
    this.deliveryTime,

    this.subscriptionStatus,
    this.promotionStatus,

    this.outletTimings,

    this.openingTime,
    this.closingTime,
    this.openNow,

    this.promotionScheduleId,
    this.sourceType,
    this.sourceId,
    this.minOrderValue,
    this.priceType,
    this.discountAmount,
    this.usageLimitPerUser,
    this.couponCode,
    this.startDateTime,
    this.endDateTime,
    this.remainingTime,
    this.planType,
    this.offerName,

    this.author,
    this.fcmToken,
    this.latitude,
    this.longitude,
    this.location,
    this.isSelfDelivery,
    this.zoneId,
    this.categoryID,
    this.subscriptionPlan,
    this.subscriptionTotalOrders,
    this.subscriptionExpiryDate,
    this.deliveryCharge,
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    // ----------------------------------------------------------
    // DISCOUNT
    // ----------------------------------------------------------

    Map<String, dynamic>? discountJson;

    final discount = json['activeDiscountsDto'];

    if (discount is Map) {
      discountJson = Map<String, dynamic>.from(discount);
    }

    // ----------------------------------------------------------
    // TIMINGS
    // ----------------------------------------------------------

    List<OutletTiming>? timings;

    final timingsJson = json['outletTimings'];

    if (timingsJson is List) {
      timings = timingsJson
          .whereType<Map>()
          .map((item) => OutletTiming.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    // ----------------------------------------------------------
    // BASIC VALUES
    // ----------------------------------------------------------

    final int? parsedOutletId = _toInt(json['outletId']);

    final String? parsedOutletName = json['outletName']?.toString();

    final String? parsedCuisine = json['cuisineType']?.toString();

    final String? parsedPhone = json['outletPhone']?.toString();

    final double? parsedDistance = _toDouble(json['distanceKm']);

    final String? parsedOpeningTime = json['openingTime']?.toString();

    final String? parsedClosingTime = json['closingTime']?.toString();

    final bool parsedOpenNow = _toBool(json['openNow']) ?? false;

    // ----------------------------------------------------------
    // CATEGORY
    // ----------------------------------------------------------

    List<String>? categories;

    if (parsedCuisine != null && parsedCuisine.isNotEmpty) {
      categories = [parsedCuisine];
    }

    // ----------------------------------------------------------
    // RETURN
    // ----------------------------------------------------------

    return VendorModel(
      // Existing app fields
      id: parsedOutletId != null
          ? parsedOutletId.toString()
          : json['id']?.toString(),

      title: parsedOutletName ?? json['title']?.toString(),

      photo: json['photo']?.toString() ?? json['outletPicUrl']?.toString(),

      phonenumber: parsedPhone ?? json['phonenumber']?.toString() ?? '',

      reviewsSum: _toDouble(json['reviewsSum']) ?? _toDouble(json['review']),

      reviewsCount: _toInt(json['reviewsCount']),

      distance: parsedDistance ?? _toDouble(json['distance']),

      isOpen: parsedOpenNow,

      isActive: _toBool(json['isActive']) ?? true,

      isFavourite: _toBool(json['isFavourite']) ?? false,

      vType: json['vType']?.toString() ?? 'restaurant',

      categoryTitle: categories ?? _parseStringList(json['categoryTitle']),

      // Outlet fields
      outletId: parsedOutletId,

      outletName: parsedOutletName,

      cuisineType: parsedCuisine,

      outletPhone: parsedPhone,

      radius: _toDouble(json['radius']),

      review: json['review'],

      distanceKm: parsedDistance,

      roadDistance: json['roadDistance']?.toString(),

      deliveryTime: json['deliveryTime']?.toString(),

      subscriptionStatus: _toBool(json['subscriptionStatus']),

      promotionStatus: _toBool(json['promotionStatus']),

      outletTimings: timings,

      openingTime: parsedOpeningTime,

      closingTime: parsedClosingTime,

      openNow: _toBool(json['openNow']),

      // Discount
      promotionScheduleId: _toInt(discountJson?['promotionScheduleId']),

      sourceType: discountJson?['sourceType']?.toString(),

      sourceId: _toInt(discountJson?['sourceId']),

      minOrderValue: _toDouble(discountJson?['minOrderValue']),

      priceType: discountJson?['priceType']?.toString(),

      discountAmount: _toDouble(discountJson?['discountAmount']),

      usageLimitPerUser: _toInt(discountJson?['usageLimitPerUser']),

      couponCode: discountJson?['couponCode']?.toString(),

      startDateTime: discountJson?['startDateTime']?.toString(),

      endDateTime: discountJson?['endDateTime']?.toString(),

      remainingTime: discountJson?['remainingTime']?.toString(),

      planType: discountJson?['planType']?.toString(),

      offerName: discountJson?['offerName']?.toString(),

      author: json['author'],
      fcmToken: json['fcmToken']?.toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      location: json['location']?.toString(),
      isSelfDelivery: _toBool(json['isSelfDelivery']),
      zoneId: json['zoneId']?.toString(),
      categoryID: json['categoryID'] is List
          ? json['categoryID'] as List<dynamic>
          : null,
      subscriptionPlan: json['subscription_plan'] ?? json['subscriptionPlan'],
      subscriptionTotalOrders: json['subscriptionTotalOrders']?.toString(),
      subscriptionExpiryDate: json['subscriptionExpiryDate'],
      deliveryCharge: json['DeliveryCharge'] ?? json['deliveryCharge'],
    );
  }

  // ============================================================
  // TODAY TIMING
  // ============================================================

  OutletTiming? getTodayTiming() {
    if (outletTimings == null || outletTimings!.isEmpty) {
      return null;
    }

    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final today = days[DateTime.now().weekday - 1];

    for (final timing in outletTimings!) {
      if (timing.day.toLowerCase() == today.toLowerCase()) {
        return timing;
      }
    }

    return null;
  }

  // ============================================================
  // CURRENTLY OPEN
  // ============================================================

  bool isCurrentlyOpen() {
    final timing = getTodayTiming();

    // If API already gives openNow,
    // prefer that when timings are unavailable.
    if (timing == null) {
      return openNow ?? isOpen;
    }

    if (!timing.isOpen) {
      return false;
    }

    if (timing.openingTime == null || timing.closingTime == null) {
      return true;
    }

    final now = DateTime.now();

    final opening = _parseTimeToday(timing.openingTime!);

    final closing = _parseTimeToday(timing.closingTime!);

    if (opening == null || closing == null) {
      return openNow ?? true;
    }

    // Normal:
    // 09:00 -> 20:00
    if (closing.isAfter(opening)) {
      return !now.isBefore(opening) && !now.isAfter(closing);
    }

    // Overnight:
    // 20:00 -> 02:00
    return !now.isBefore(opening) || !now.isAfter(closing);
  }

  // ============================================================
  // UPDATE OPEN STATUS
  // ============================================================

  void updateOpenStatus() {
    final status = isCurrentlyOpen();

    isOpen = status;
    openNow = status;

    final today = getTodayTiming();

    if (today != null) {
      openingTime = today.openingTime;
      closingTime = today.closingTime;
    }
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'photo': photo,
      'phonenumber': phonenumber,

      'reviewsSum': reviewsSum,
      'reviewsCount': reviewsCount,

      'distance': distance,

      'isOpen': isOpen,
      'isActive': isActive,
      'isFavourite': isFavourite,

      'vType': vType,
      'categoryTitle': categoryTitle,

      'outletId': outletId,
      'outletName': outletName,
      'cuisineType': cuisineType,
      'outletPhone': outletPhone,

      'radius': radius,
      'review': review,

      'distanceKm': distanceKm,
      'roadDistance': roadDistance,
      'deliveryTime': deliveryTime,

      'subscriptionStatus': subscriptionStatus,
      'promotionStatus': promotionStatus,

      'outletTimings': outletTimings?.map((timing) => timing.toJson()).toList(),

      'openingTime': openingTime,
      'closingTime': closingTime,
      'openNow': openNow,

      'activeDiscountsDto': {
        'promotionScheduleId': promotionScheduleId,
        'sourceType': sourceType,
        'sourceId': sourceId,
        'minOrderValue': minOrderValue,
        'priceType': priceType,
        'discountAmount': discountAmount,
        'usageLimitPerUser': usageLimitPerUser,
        'couponCode': couponCode,
        'startDateTime': startDateTime,
        'endDateTime': endDateTime,
        'remainingTime': remainingTime,
        'planType': planType,
        'offerName': offerName,
      },

      'author': author,
      'fcmToken': fcmToken,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'isSelfDelivery': isSelfDelivery,
      'zoneId': zoneId,
      'categoryID': categoryID,
      'subscription_plan': subscriptionPlan,
      'subscriptionTotalOrders': subscriptionTotalOrders,
      'subscriptionExpiryDate': subscriptionExpiryDate,
      'DeliveryCharge': deliveryCharge,
    };
  }

  // ============================================================
  // TIME PARSER
  // ============================================================

  DateTime? _parseTimeToday(String time) {
    try {
      final parts = time.split(':');

      if (parts.length < 2) {
        return null;
      }

      final hour = int.parse(parts[0]);

      final minute = int.parse(parts[1]);

      final second = parts.length > 2 ? int.parse(parts[2]) : 0;

      final now = DateTime.now();

      return DateTime(now.year, now.month, now.day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static bool? _toBool(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      final text = value.toLowerCase().trim();

      if (text == 'true' || text == '1') {
        return true;
      }

      if (text == 'false' || text == '0') {
        return false;
      }
    }

    return null;
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    if (value is String && value.isNotEmpty) {
      return [value];
    }

    return null;
  }
}

// ==================================================================
// OUTLET TIMING
// IMPORTANT:
// Keep this class ONLY here.
// Do NOT define another OutletTiming in OutletDetails.
// ==================================================================

class OutletTiming {
  final String day;
  final bool isOpen;
  final String? openingTime;
  final String? closingTime;

  OutletTiming({
    required this.day,
    required this.isOpen,
    this.openingTime,
    this.closingTime,
  });

  factory OutletTiming.fromJson(Map<String, dynamic> json) {
    return OutletTiming(
      day: json['day']?.toString() ?? '',
      isOpen: _parseBool(json['isOpen']),
      openingTime: json['openingTime']?.toString(),
      closingTime: json['closingTime']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'isOpen': isOpen,
      'openingTime': openingTime,
      'closingTime': closingTime,
    };
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      final text = value.toLowerCase().trim();

      return text == 'true' || text == '1';
    }

    return false;
  }
}
