import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';

class OutletProductTiming {
  final String day;
  final String? startTime;
  final String? endTime;

  OutletProductTiming({required this.day, this.startTime, this.endTime});

  factory OutletProductTiming.fromJson(Map<String, dynamic> json) {
    return OutletProductTiming(
      day: json['day']?.toString() ?? '',
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'day': day, 'startTime': startTime, 'endTime': endTime};
  }
}

// ============================================================
// OUTLET CATEGORY
// ============================================================

class OutletCategory {
  final int categoryId;
  final String categoryName;
  final bool? isAvailable;
  final List<ProductModel> products;

  OutletCategory({
    required this.categoryId,
    required this.categoryName,
    this.isAvailable,
    required this.products,
  });

  factory OutletCategory.fromJson(
    Map<String, dynamic> json, {
    required String outletId,
  }) {
    final rawCategoryId = json['categoryId'];

    final int categoryId = rawCategoryId is int
        ? rawCategoryId
        : int.tryParse(rawCategoryId?.toString() ?? '') ?? 0;

    final String categoryName = json['categoryName']?.toString() ?? '';

    final bool? isAvailable = _toBool(json['isAvailable']);

    final List<ProductModel> products = [];

    final productsJson = json['products'];

    if (productsJson is List) {
      for (final item in productsJson) {
        if (item is Map) {
          final productJson = Map<String, dynamic>.from(item);

          // Add category information to product.
          productJson['categoryId'] = categoryId.toString();

          productJson['categoryName'] = categoryName;

          try {
            final product = ProductModel.fromJson(productJson);

            // vendorID is NOT returned by the product API.
            // It comes from the parent outlet.
            if (outletId.isNotEmpty) {
              product.vendorID = outletId;
            }

            products.add(product);
          } catch (e) {
            // Don't allow one invalid product
            // to break the complete outlet.
            continue;
          }
        }
      }
    }

    return OutletCategory(
      categoryId: categoryId,
      categoryName: categoryName,
      isAvailable: isAvailable,
      products: products,
    );
  }

  VendorCategoryModel toVendorCategoryModel() {
    return VendorCategoryModel(
      categoryId: categoryId,
      categoryName: categoryName,
      categoryType: 'RESTAURANT',
      categoryImageUrl: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'isAvailable': isAvailable,
      'products': products.map((product) => product.toJson()).toList(),
    };
  }

  static bool? _toBool(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
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
}
// ============================================================
// OUTLET DETAILS
// ============================================================

class OutletDetails {
  // ==========================================================
  // BASIC DETAILS
  // ==========================================================

  final int outletId;
  final String outletName;
  final String? outletEmail;
  final String? outletPhone;
  final String? alternateOutletPhone;
  final String? cuisineType;

  // ==========================================================
  // LOCATION
  // ==========================================================

  final double? latitude;
  final double? longitude;

  // ==========================================================
  // BANK DETAILS
  // ==========================================================

  final String? accountNumber;
  final String? ifscCode;
  final String? bankName;
  final String? accountHolderName;

  // ==========================================================
  // ADDRESS
  // ==========================================================

  final String? buildingNumber;
  final String? road;
  final String? landmark;

  // ==========================================================
  // CITY
  // ==========================================================

  final int? cityId;
  final String? cityName;

  // ==========================================================
  // STATE
  // ==========================================================

  final int? stateId;
  final String? stateName;

  // ==========================================================
  // AREA
  // ==========================================================

  final int? areaId;
  final String? areaName;

  // ==========================================================
  // STATUS
  // ==========================================================

  final bool isFavourite;
  final bool? isAvailable;

  // ==========================================================
  // DISCOUNT
  // ==========================================================

  final dynamic activeDiscounts;

  // ==========================================================
  // TIMINGS
  //
  // IMPORTANT:
  // This uses OutletTiming from vendor_model.dart.
  // Do NOT create another OutletTiming class here.
  // ==========================================================

  final List<OutletTiming> outletTimings;

  // ==========================================================
  // CATEGORIES
  // ==========================================================

  final List<OutletCategory> categories;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  OutletDetails({
    required this.outletId,
    required this.outletName,
    this.outletEmail,
    this.outletPhone,
    this.alternateOutletPhone,
    this.cuisineType,
    this.latitude,
    this.longitude,
    this.accountNumber,
    this.ifscCode,
    this.bankName,
    this.accountHolderName,
    this.buildingNumber,
    this.road,
    this.landmark,
    this.cityId,
    this.cityName,
    this.stateId,
    this.stateName,
    this.areaId,
    this.areaName,
    this.isFavourite = false,
    this.isAvailable,
    this.activeDiscounts,
    required this.outletTimings,
    required this.categories,
  });

  // ==========================================================
  // FROM JSON
  // ==========================================================

  factory OutletDetails.fromJson(Map<String, dynamic> json) {
    // --------------------------------------------------------
    // OUTLET ID
    // --------------------------------------------------------

    final int outletId = _toInt(json['outletId']) ?? 0;

    final String outletIdString = outletId > 0 ? outletId.toString() : '';

    // --------------------------------------------------------
    // OUTLET TIMINGS
    // --------------------------------------------------------

    final List<OutletTiming> timings = [];

    final timingsJson = json['outletTimings'];

    if (timingsJson is List) {
      for (final item in timingsJson) {
        if (item is Map) {
          try {
            timings.add(OutletTiming.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {
            // Ignore invalid timing.
          }
        }
      }
    }

    // --------------------------------------------------------
    // CATEGORIES
    // --------------------------------------------------------

    final List<OutletCategory> categories = [];

    final categoriesJson = json['categories'];

    if (categoriesJson is List) {
      for (final item in categoriesJson) {
        if (item is Map) {
          try {
            categories.add(
              OutletCategory.fromJson(
                Map<String, dynamic>.from(item),
                outletId: outletIdString,
              ),
            );
          } catch (_) {
            // Ignore invalid category.
          }
        }
      }
    }

    // --------------------------------------------------------
    // RETURN
    // --------------------------------------------------------

    return OutletDetails(
      outletId: outletId,

      outletName: json['outletName']?.toString() ?? '',

      outletEmail: json['outletEmail']?.toString(),

      outletPhone: json['outletPhone']?.toString(),

      alternateOutletPhone: json['alternateOutletPhone']?.toString(),

      cuisineType: json['cuisineType']?.toString(),

      // Location
      latitude: _toDouble(json['latitude']),

      longitude: _toDouble(json['longitude']),

      // Bank
      accountNumber: json['accountNumber']?.toString(),

      ifscCode: json['ifscCode']?.toString(),

      bankName: json['bankName']?.toString(),

      accountHolderName: json['accountHolderName']?.toString(),

      // Address
      buildingNumber: json['buildingNumber']?.toString(),

      road: json['road']?.toString(),

      landmark: json['landmark']?.toString(),

      // City
      cityId: _toInt(json['cityId']),

      cityName: json['cityName']?.toString(),

      // State
      stateId: _toInt(json['stateId']),

      stateName: json['stateName']?.toString(),

      // Area
      areaId: _toInt(json['areaId']),

      areaName: json['areaName']?.toString(),

      // Status
      isFavourite: _toBool(json['isFavourite']) ?? false,

      isAvailable: _toBool(json['isAvailable']),

      // Discount
      activeDiscounts: json['activeDiscountsDto'] ?? json['activeDiscounts'],

      // Timings
      outletTimings: timings,

      // Categories
      categories: categories,
    );
  }

  // ==========================================================
  // CATEGORY GETTERS
  // ==========================================================

  List<VendorCategoryModel> get vendorCategories {
    return categories
        .map((category) => category.toVendorCategoryModel())
        .toList();
  }

  // ==========================================================
  // ALL PRODUCTS
  // ==========================================================

  List<ProductModel> get allProducts {
    return categories.expand((category) => category.products).toList();
  }

  // ==========================================================
  // TODAY'S TIMING
  // ==========================================================

  OutletTiming? getTodayTiming() {
    if (outletTimings.isEmpty) {
      return null;
    }

    const List<String> days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final String today = days[DateTime.now().weekday - 1];

    for (final timing in outletTimings) {
      if (timing.day.toLowerCase() == today.toLowerCase()) {
        return timing;
      }
    }

    return null;
  }

  // ==========================================================
  // CHECK CURRENTLY OPEN
  // ==========================================================

  bool isCurrentlyOpen() {
    final OutletTiming? timing = getTodayTiming();

    if (timing == null) {
      return false;
    }

    if (!timing.isOpen) {
      return false;
    }

    if (timing.openingTime == null || timing.closingTime == null) {
      return true;
    }

    final DateTime now = DateTime.now();

    final DateTime? opening = _parseTimeToday(timing.openingTime!);

    final DateTime? closing = _parseTimeToday(timing.closingTime!);

    if (opening == null || closing == null) {
      return true;
    }

    // --------------------------------------------------------
    // NORMAL TIMING
    // Example:
    // 09:00 -> 20:00
    // --------------------------------------------------------

    if (closing.isAfter(opening)) {
      return !now.isBefore(opening) && !now.isAfter(closing);
    }

    // --------------------------------------------------------
    // OVERNIGHT TIMING
    // Example:
    // 20:00 -> 02:00
    // --------------------------------------------------------

    return !now.isBefore(opening) || !now.isAfter(closing);
  }

  // ==========================================================
  // CONVERT TO VENDOR MODEL
  //
  // This is used when opening an outlet details page and
  // you need the same VendorModel used by the restaurant list.
  // ==========================================================

  VendorModel toVendorModel({VendorModel? existing}) {
    final OutletTiming? todayTiming = getTodayTiming();

    final bool currentlyOpen = isCurrentlyOpen();

    // ========================================================
    // UPDATE EXISTING
    // ========================================================

    if (existing != null) {
      // ID
      if (outletId > 0) {
        existing.id = outletId.toString();

        existing.outletId = outletId;
      }

      // Name
      if (outletName.isNotEmpty) {
        existing.title = outletName;

        existing.outletName = outletName;
      }

      // Phone
      if (outletPhone != null && outletPhone!.isNotEmpty) {
        existing.phonenumber = outletPhone!;

        existing.outletPhone = outletPhone;
      }

      // Cuisine
      existing.cuisineType = cuisineType;

      // Favourite
      existing.isFavourite = isFavourite;

      // Timings
      existing.outletTimings = List<OutletTiming>.from(outletTimings);

      // Today's timing
      existing.openingTime = todayTiming?.openingTime;

      existing.closingTime = todayTiming?.closingTime;

      // Open status
      existing.openNow = currentlyOpen;

      existing.isOpen = currentlyOpen;

      // Availability
      if (isAvailable != null) {
        existing.isActive = isAvailable!;
      }

      // Always restaurant
      existing.vType = 'restaurant';

      return existing;
    }

    // ========================================================
    // CREATE NEW VENDOR
    // ========================================================

    return VendorModel(
      id: outletId > 0 ? outletId.toString() : null,

      title: outletName,

      phonenumber: outletPhone ?? '',

      isOpen: currentlyOpen,

      isActive: isAvailable ?? true,

      isFavourite: isFavourite,

      vType: 'restaurant',

      outletId: outletId,

      outletName: outletName,

      outletPhone: outletPhone,

      cuisineType: cuisineType,

      outletTimings: List<OutletTiming>.from(outletTimings),

      openingTime: todayTiming?.openingTime,

      closingTime: todayTiming?.closingTime,

      openNow: currentlyOpen,
    );
  }

  // ==========================================================
  // TO JSON
  // ==========================================================

  Map<String, dynamic> toJson() {
    return {
      'outletId': outletId,

      'outletName': outletName,

      'outletEmail': outletEmail,

      'outletPhone': outletPhone,

      'alternateOutletPhone': alternateOutletPhone,

      'cuisineType': cuisineType,

      'latitude': latitude,

      'longitude': longitude,

      'accountNumber': accountNumber,

      'ifscCode': ifscCode,

      'bankName': bankName,

      'accountHolderName': accountHolderName,

      'buildingNumber': buildingNumber,

      'road': road,

      'landmark': landmark,

      'cityId': cityId,

      'cityName': cityName,

      'stateId': stateId,

      'stateName': stateName,

      'areaId': areaId,

      'areaName': areaName,

      'isFavourite': isFavourite,

      'isAvailable': isAvailable,

      'activeDiscounts': activeDiscounts,

      'outletTimings': outletTimings.map((timing) => timing.toJson()).toList(),

      'categories': categories.map((category) => category.toJson()).toList(),
    };
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

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
      final String text = value.toLowerCase().trim();

      if (text == 'true' || text == '1') {
        return true;
      }

      if (text == 'false' || text == '0') {
        return false;
      }
    }

    return null;
  }

  static DateTime? _parseTimeToday(String time) {
    try {
      final List<String> parts = time.split(':');

      if (parts.length < 2) {
        return null;
      }

      final int hour = int.parse(parts[0]);

      final int minute = int.parse(parts[1]);

      final int second = parts.length > 2 ? int.parse(parts[2]) : 0;

      final DateTime now = DateTime.now();

      return DateTime(now.year, now.month, now.day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }
}
