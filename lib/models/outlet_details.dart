import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';

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
      isOpen: json['isOpen'] == true,
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
}

class OutletProductTiming {
  final String day;
  final String? startTime;
  final String? endTime;

  OutletProductTiming({
    required this.day,
    this.startTime,
    this.endTime,
  });

  factory OutletProductTiming.fromJson(Map<String, dynamic> json) {
    return OutletProductTiming(
      day: json['day']?.toString() ?? '',
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

class OutletCategory {
  final int categoryId;
  final String categoryName;
  final List<ProductModel> products;

  OutletCategory({
    required this.categoryId,
    required this.categoryName,
    required this.products,
  });

  factory OutletCategory.fromJson(
    Map<String, dynamic> json, {
    required String outletId,
  }) {
    final categoryId = json['categoryId'] ?? 0;
    final categoryName = json['categoryName']?.toString() ?? '';
    final productsJson = json['products'];

    final products = <ProductModel>[];
    if (productsJson is List) {
      for (final item in productsJson) {
        if (item is Map<String, dynamic>) {
          item['categoryId'] = categoryId.toString();
          item['categoryName'] = categoryName;
          item['vendorID'] = outletId;
          products.add(ProductModel.fromApiJson(item));
        }
      }
    }

    return OutletCategory(
      categoryId: categoryId is int ? categoryId : int.tryParse('$categoryId') ?? 0,
      categoryName: categoryName,
      products: products,
    );
  }

  VendorCategoryModel toVendorCategoryModel() {
    return VendorCategoryModel(
      id: categoryId.toString(),
      title: categoryName,
      productCount: products.length,
      publish: true,
      vType: 'restaurant',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'products': products.map((p) => p.toJson()).toList(),
    };
  }
}

class OutletDetails {
  final int outletId;
  final String outletName;
  final String? outletPhone;
  final List<OutletTiming> outletTimings;
  final List<OutletCategory> categories;

  OutletDetails({
    required this.outletId,
    required this.outletName,
    this.outletPhone,
    required this.outletTimings,
    required this.categories,
  });

  factory OutletDetails.fromJson(Map<String, dynamic> json) {
    final outletId = json['outletId'] ?? 0;
    final outletIdStr = outletId.toString();

    final timingsJson = json['outletTimings'];
    final outletTimings = <OutletTiming>[];
    if (timingsJson is List) {
      for (final item in timingsJson) {
        if (item is Map<String, dynamic>) {
          outletTimings.add(OutletTiming.fromJson(item));
        }
      }
    }

    final categoriesJson = json['categories'];
    final categories = <OutletCategory>[];
    if (categoriesJson is List) {
      for (final item in categoriesJson) {
        if (item is Map<String, dynamic>) {
          categories.add(
            OutletCategory.fromJson(item, outletId: outletIdStr),
          );
        }
      }
    }

    return OutletDetails(
      outletId: outletId is int ? outletId : int.tryParse('$outletId') ?? 0,
      outletName: json['outletName']?.toString() ?? '',
      outletPhone: json['outletPhone']?.toString(),
      outletTimings: outletTimings,
      categories: categories,
    );
  }

  List<VendorCategoryModel> get vendorCategories =>
      categories.map((c) => c.toVendorCategoryModel()).toList();

  List<ProductModel> get allProducts =>
      categories.expand((c) => c.products).toList();

  VendorModel toVendorModel({VendorModel? existing}) {
    final workingHours = outletTimings
        .where((t) => t.isOpen && t.openingTime != null && t.closingTime != null)
        .map(
          (t) => WorkingHours(
            day: t.day,
            timeslot: [
              Timeslot(from: t.openingTime, to: t.closingTime),
            ],
          ),
        )
        .toList();

    final todayTiming = _todayTiming();
    final isOpenNow = todayTiming?.isOpen ?? true;

    if (existing != null) {
      existing.id = outletId.toString();
      existing.title = outletName;
      existing.phonenumber = outletPhone ?? existing.phonenumber;
      existing.workingHours = workingHours.isNotEmpty
          ? workingHours
          : existing.workingHours;
      existing.isOpen = isOpenNow;
      existing.openDineTime =
          todayTiming?.openingTime ?? existing.openDineTime;
      existing.closeDineTime =
          todayTiming?.closingTime ?? existing.closeDineTime;
      return existing;
    }

    return VendorModel(
      id: outletId.toString(),
      title: outletName,
      phonenumber: outletPhone ?? '',
      workingHours: workingHours,
      isOpen: isOpenNow,
      isActive: true,
      vType: 'restaurant',
      openDineTime: todayTiming?.openingTime ?? '',
      closeDineTime: todayTiming?.closingTime ?? '',
    );
  }

  OutletTiming? _todayTiming() {
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
    for (final timing in outletTimings) {
      if (timing.day.toLowerCase() == today.toLowerCase()) {
        return timing;
      }
    }
    return outletTimings.isNotEmpty ? outletTimings.first : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'outletId': outletId,
      'outletName': outletName,
      'outletPhone': outletPhone,
      'outletTimings': outletTimings.map((t) => t.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
    };
  }
}
