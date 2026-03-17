// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:jippymart_customer/models/cart_product_model.dart';
// import 'package:jippymart_customer/models/tax_model.dart';
// import 'package:jippymart_customer/models/user_model.dart';
// import 'package:jippymart_customer/models/vendor_model.dart';
//
// class OrderModel {
//   ShippingAddress? address;
//   String? status;
//   String? couponId;
//   String? vendorID;
//   String? driverID;
//   num? discount;
//   String? authorID;
//   String? estimatedTimeToPrepare;
//   Timestamp? createdAt;
//   Timestamp? triggerDelivery;
//   List<TaxModel>? taxSetting;
//   String? paymentMethod;
//   List<CartProductModel>? products;
//   String? adminCommissionType;
//   VendorModel? vendor;
//   String? id;
//   String? adminCommission;
//   String? couponCode;
//   Map<String, dynamic>? specialDiscount;
//   String? deliveryCharge;
//   Timestamp? scheduleTime;
//   String? tipAmount;
//   String? notes;
//   UserModel? author;
//   UserModel? driver;
//   bool? takeAway;
//   List<dynamic>? rejectedByDrivers;
//   double? toPayAmount;
//   String? surgeFee;
//
//   // NEW FIELDS
//   dynamic calculatedCharges;
//   Timestamp? orderAutoCancelAt;
//   List<dynamic>? photos;
//   List<String>? photo;
//   List<dynamic>? restaurantMenuPhotos;
//   List<dynamic>? workingHours;
//
//   OrderModel({
//     this.address,
//     this.status,
//     this.couponId,
//     this.vendorID,
//     this.driverID,
//     this.discount,
//     this.authorID,
//     this.estimatedTimeToPrepare,
//     this.createdAt,
//     this.triggerDelivery,
//     this.taxSetting,
//     this.paymentMethod,
//     this.products,
//     this.adminCommissionType,
//     this.vendor,
//     this.id,
//     this.adminCommission,
//     this.couponCode,
//     this.specialDiscount,
//     this.deliveryCharge,
//     this.scheduleTime,
//     this.tipAmount,
//     this.notes,
//     this.author,
//     this.driver,
//     this.takeAway,
//     this.rejectedByDrivers,
//     this.toPayAmount,
//     this.surgeFee,
//     // NEW FIELDS IN CONSTRUCTOR
//     this.calculatedCharges,
//     this.orderAutoCancelAt,
//     this.photos,
//     this.photo,
//     this.restaurantMenuPhotos,
//     this.workingHours,
//   });
//
//   OrderModel.fromJson(Map<String, dynamic> json) {
//     address = (json['address'] != null && json['address'] is Map)
//         ? ShippingAddress.fromJson(
//             Map<String, dynamic>.from(json['address'] as Map))
//         : null;
//     final rawStatus = json['status'];
//     status = rawStatus == null ? null : rawStatus.toString().trim();
//     couponId = json['couponId'];
//     vendorID = json['vendorID'];
//     driverID = json['driverID'];
//     discount = json['discount'] != null
//         ? (num.tryParse(json['discount'].toString()) ?? 0)
//         : 0;
//     authorID = json['authorID'];
//     estimatedTimeToPrepare = json['estimatedTimeToPrepare'];
//
//     // Handle createdAt - could be String or Timestamp
//     createdAt = _parseTimestamp(json['createdAt']);
//
//     // Handle triggerDelivery - could be String or Timestamp
//     triggerDelivery = _parseTimestamp(
//       json['triggerDelivery'] ?? json['triggerDelevery'],
//     );
//
//     if (json['taxSetting'] != null && json['taxSetting'] is List) {
//       taxSetting = <TaxModel>[];
//       for (final v in json['taxSetting'] as List) {
//         if (v is Map<String, dynamic>) {
//           taxSetting!.add(TaxModel.fromJson(v));
//         } else if (v is Map) {
//           taxSetting!.add(TaxModel.fromJson(Map<String, dynamic>.from(v)));
//         }
//       }
//     }
//     paymentMethod = json['payment_method'];
//     if (json['products'] != null && json['products'] is List) {
//       products = <CartProductModel>[];
//       for (final v in json['products'] as List) {
//         if (v is Map<String, dynamic>) {
//           products!.add(CartProductModel.fromJson(v));
//         } else if (v is Map) {
//           products!.add(CartProductModel.fromJson(Map<String, dynamic>.from(v)));
//         }
//       }
//     }
//     adminCommissionType = json['adminCommissionType'];
//     vendor = (json['vendor'] != null && json['vendor'] is Map)
//         ? VendorModel.fromJson(Map<String, dynamic>.from(json['vendor'] as Map))
//         : null;
//     id = json['id'];
//     adminCommission = json['adminCommission'];
//     couponCode = json['couponCode'];
//     specialDiscount = json['specialDiscount'];
//     final rawDelivery = json['deliveryCharge'];
//     deliveryCharge = (rawDelivery == null ||
//             rawDelivery.toString().isEmpty ||
//             rawDelivery.toString() == 'null')
//         ? '0.0'
//         : rawDelivery.toString();
//
//     // Handle scheduleTime - could be String or Timestamp
//     scheduleTime = _parseTimestamp(json['scheduleTime']);
//
//     final rawTip = json['tip_amount'];
//     tipAmount = (rawTip == null ||
//             rawTip.toString().isEmpty ||
//             rawTip.toString() == 'null')
//         ? '0.0'
//         : rawTip.toString();
//     notes = json['notes'];
//     author = (json['author'] != null && json['author'] is Map)
//         ? UserModel.fromJson(Map<String, dynamic>.from(json['author'] as Map))
//         : null;
//     driver = (json['driver'] != null && json['driver'] is Map)
//         ? UserModel.fromJson(Map<String, dynamic>.from(json['driver'] as Map))
//         : null;
//     takeAway = json['takeAway'] is bool
//         ? json['takeAway']
//         : (json['takeAway']?.toString().toLowerCase() == 'true');
//     rejectedByDrivers = json['rejectedByDrivers'] is List
//         ? List<dynamic>.from(json['rejectedByDrivers'] as List)
//         : [];
//
//     // FIXED: Handle both "ToPay" (capital T) and "toPayAmount" variations
//     toPayAmount = _parseToPayAmount(json);
//
//     surgeFee = json['surge_fee'];
//
//     // NEW FIELDS PARSING
//     calculatedCharges = json['calculatedCharges'];
//     orderAutoCancelAt = _parseTimestamp(json['orderAutoCancelAt']);
//     photos = json['photos'] ?? [];
//
//     // Parse photo array - handle List, single string, or null
//     if (json['photo'] == null) {
//       photo = [];
//     } else if (json['photo'] is List) {
//       photo =
//           List<String>.from((json['photo'] as List).map((x) => x.toString()));
//     } else {
//       photo = [json['photo'].toString()];
//     }
//
//     restaurantMenuPhotos = json['restaurantMenuPhotos'] ?? [];
//     workingHours = json['workingHours'] ?? [];
//   }
//
//   // Helper method to parse toPay amount from multiple possible field names
//   double? _parseToPayAmount(Map<String, dynamic> json) {
//     // Try "ToPay" first (capital T - from your JSON)
//     if (json['ToPay'] != null) {
//       return double.tryParse(json['ToPay'].toString());
//     }
//     // Then try "toPayAmount"
//     if (json['toPayAmount'] != null) {
//       if (json['toPayAmount'] is num) {
//         return (json['toPayAmount'] as num).toDouble();
//       } else {
//         return double.tryParse(json['toPayAmount'].toString());
//       }
//     }
//     // Then try "toPay" (lowercase)
//     if (json['toPay'] != null) {
//       return double.tryParse(json['toPay'].toString());
//     }
//     return null;
//   }
//
//   // Helper method to parse timestamp from various formats
//   Timestamp? _parseTimestamp(dynamic timestampData) {
//     if (timestampData == null) return null;
//
//     if (timestampData is Timestamp) {
//       return timestampData;
//     } else if (timestampData is String) {
//       try {
//         // Parse ISO 8601 string
//         final dateTime = DateTime.parse(timestampData);
//         return Timestamp.fromDate(dateTime);
//       } catch (e) {
//         print('Error parsing timestamp string: $timestampData, error: $e');
//         return null;
//       }
//     } else if (timestampData is int) {
//       // Handle milliseconds since epoch
//       return Timestamp.fromMillisecondsSinceEpoch(timestampData);
//     }
//
//     return null;
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     if (address != null) {
//       data['address'] = address!.toJson();
//     }
//     data['status'] = status;
//     data['couponId'] = couponId;
//     data['vendorID'] = vendorID;
//     data['driverID'] = driverID;
//     data['discount'] = discount;
//     data['authorID'] = authorID;
//     data['estimatedTimeToPrepare'] = estimatedTimeToPrepare;
//     data['createdAt'] = createdAt;
//     data['triggerDelivery'] = triggerDelivery;
//     if (taxSetting != null) {
//       data['taxSetting'] = taxSetting!.map((v) => v.toJson()).toList();
//     }
//     data['payment_method'] = paymentMethod;
//     if (products != null) {
//       data['products'] = products!.map((v) => v.toJson()).toList();
//     }
//     data['adminCommissionType'] = adminCommissionType;
//     if (vendor != null) {
//       data['vendor'] = vendor!.toJson();
//     }
//     data['id'] = id;
//     data['adminCommission'] = adminCommission;
//     data['couponCode'] = couponCode;
//     data['specialDiscount'] = specialDiscount;
//     data['deliveryCharge'] = deliveryCharge;
//     data['scheduleTime'] = scheduleTime;
//     data['tip_amount'] = tipAmount;
//     data['notes'] = notes;
//     if (author != null) {
//       data['author'] = author!.toJson();
//     }
//     if (driver != null) {
//       data['driver'] = driver!.toJson();
//     }
//     data['takeAway'] = takeAway;
//     data['rejectedByDrivers'] = rejectedByDrivers;
//
//     // Include toPay amount with the field name that matches your backend
//     data['ToPay'] = toPayAmount?.toString();
//     data['toPayAmount'] = toPayAmount;
//     data['surge_fee'] = surgeFee;
//     // NEW FIELDS IN TOJSON
//     data['calculatedCharges'] = calculatedCharges;
//     data['orderAutoCancelAt'] = orderAutoCancelAt;
//     data['photos'] = photos;
//     data['photo'] = photo;
//     data['restaurantMenuPhotos'] = restaurantMenuPhotos;
//     data['workingHours'] = workingHours;
//
//     return data;
//   }
//
//   @override
//   String toString() {
//     return 'OrderModel(id: $id, status: $status, toPayAmount: $toPayAmount, vendor: ${vendor?.title}, products: ${products?.length})';
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/tax_model.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';

class OrderModel {
  ShippingAddress? address;
  String? status;
  String? couponId;
  String? vendorID;
  String? driverID;
  num? discount;
  String? authorID;
  String? estimatedTimeToPrepare;
  Timestamp? createdAt;
  Timestamp? triggerDelivery;
  List<TaxModel>? taxSetting;
  String? paymentMethod;
  List<CartProductModel>? products;
  String? adminCommissionType;
  VendorModel? vendor;
  String? id;
  String? adminCommission;
  String? couponCode;
  Map<String, dynamic>? specialDiscount;
  String? deliveryCharge;
  Timestamp? scheduleTime;
  String? tipAmount;
  String? notes;
  UserModel? author;
  UserModel? driver;
  bool? takeAway;
  List<dynamic>? rejectedByDrivers;
  double? toPayAmount;
  String? surgeFee;

  // NEW FIELDS
  dynamic calculatedCharges;
  Timestamp? orderAutoCancelAt;
  List<dynamic>? photos;
  List<String>? photo;
  List<dynamic>? restaurantMenuPhotos;
  List<dynamic>? workingHours;

  OrderModel({
    this.address,
    this.status,
    this.couponId,
    this.vendorID,
    this.driverID,
    this.discount,
    this.authorID,
    this.estimatedTimeToPrepare,
    this.createdAt,
    this.triggerDelivery,
    this.taxSetting,
    this.paymentMethod,
    this.products,
    this.adminCommissionType,
    this.vendor,
    this.id,
    this.adminCommission,
    this.couponCode,
    this.specialDiscount,
    this.deliveryCharge,
    this.scheduleTime,
    this.tipAmount,
    this.notes,
    this.author,
    this.driver,
    this.takeAway,
    this.rejectedByDrivers,
    this.toPayAmount,
    this.surgeFee,
    // NEW FIELDS IN CONSTRUCTOR
    this.calculatedCharges,
    this.orderAutoCancelAt,
    this.photos,
    this.photo,
    this.restaurantMenuPhotos,
    this.workingHours,
  });

  OrderModel.fromJson(Map<String, dynamic> json) {
    address = (json['address'] != null && json['address'] is Map)
        ? ShippingAddress.fromJson(
            Map<String, dynamic>.from(json['address'] as Map),
          )
        : null;

    // FIXED: Handle status properly - don't filter or modify
    final rawStatus = json['status'];
    status = rawStatus == null ? null : rawStatus.toString().trim();

    couponId = json['couponId'];
    vendorID = json['vendorID'];
    driverID = json['driverID'];
    discount = json['discount'] != null
        ? (num.tryParse(json['discount'].toString()) ?? 0)
        : 0;
    authorID = json['authorID'];
    estimatedTimeToPrepare = json['estimatedTimeToPrepare'];

    // Handle createdAt - could be String or Timestamp
    createdAt = _parseTimestamp(json['createdAt']);

    // Handle triggerDelivery - could be String or Timestamp
    triggerDelivery = _parseTimestamp(
      json['triggerDelivery'] ?? json['triggerDelevery'],
    );

    if (json['taxSetting'] != null && json['taxSetting'] is List) {
      taxSetting = <TaxModel>[];
      for (final v in json['taxSetting'] as List) {
        if (v is Map<String, dynamic>) {
          taxSetting!.add(TaxModel.fromJson(v));
        } else if (v is Map) {
          taxSetting!.add(TaxModel.fromJson(Map<String, dynamic>.from(v)));
        }
      }
    }
    paymentMethod = json['payment_method'];

    if (json['products'] != null && json['products'] is List) {
      products = <CartProductModel>[];
      for (final v in json['products'] as List) {
        if (v is Map<String, dynamic>) {
          products!.add(CartProductModel.fromJson(v));
        } else if (v is Map) {
          products!.add(
            CartProductModel.fromJson(Map<String, dynamic>.from(v)),
          );
        }
      }
    }

    adminCommissionType = json['adminCommissionType'];
    vendor = (json['vendor'] != null && json['vendor'] is Map)
        ? VendorModel.fromJson(Map<String, dynamic>.from(json['vendor'] as Map))
        : null;
    id = json['id'];
    adminCommission = json['adminCommission'];
    couponCode = json['couponCode'];
    specialDiscount = json['specialDiscount'];

    final rawDelivery = json['deliveryCharge'];
    deliveryCharge =
        (rawDelivery == null ||
            rawDelivery.toString().isEmpty ||
            rawDelivery.toString() == 'null')
        ? '0.0'
        : rawDelivery.toString();

    // Handle scheduleTime - could be String or Timestamp
    scheduleTime = _parseTimestamp(json['scheduleTime']);

    final rawTip = json['tip_amount'];
    tipAmount =
        (rawTip == null ||
            rawTip.toString().isEmpty ||
            rawTip.toString() == 'null')
        ? '0.0'
        : rawTip.toString();

    notes = json['notes'];

    author = (json['author'] != null && json['author'] is Map)
        ? UserModel.fromJson(Map<String, dynamic>.from(json['author'] as Map))
        : null;

    driver = (json['driver'] != null && json['driver'] is Map)
        ? UserModel.fromJson(Map<String, dynamic>.from(json['driver'] as Map))
        : null;

    takeAway = json['takeAway'] is bool
        ? json['takeAway']
        : (json['takeAway']?.toString().toLowerCase() == 'true');

    rejectedByDrivers = json['rejectedByDrivers'] is List
        ? List<dynamic>.from(json['rejectedByDrivers'] as List)
        : [];

    // FIXED: Updated to handle all possible field names, prioritizing lowercase 'toPay'
    toPayAmount = _parseToPayAmount(json);

    surgeFee = json['surge_fee'];

    // NEW FIELDS PARSING
    calculatedCharges = json['calculatedCharges'];
    orderAutoCancelAt = _parseTimestamp(json['orderAutoCancelAt']);
    photos = json['photos'] ?? [];

    // Parse photo array - handle List, single string, or null
    if (json['photo'] == null) {
      photo = [];
    } else if (json['photo'] is List) {
      photo = List<String>.from(
        (json['photo'] as List).map((x) => x.toString()),
      );
    } else {
      photo = [json['photo'].toString()];
    }

    restaurantMenuPhotos = json['restaurantMenuPhotos'] ?? [];
    workingHours = json['workingHours'] ?? [];
  }

  // FIXED: Complete overhaul of toPay parsing to handle all possible field names
  double? _parseToPayAmount(Map<String, dynamic> json) {
    // Try all possible field names in order of likelihood
    final possibleFields = [
      'toPay', // lowercase - this is what your API returns
      'ToPay', // capital T - what your old code looked for
      'toPayAmount', // camelCase - fallback
      'topay', // all lowercase - fallback
      'pay', // short form - fallback
      'total', // maybe it's called total
      'amount', // maybe it's called amount
    ];

    for (final field in possibleFields) {
      if (json.containsKey(field) && json[field] != null) {
        try {
          if (json[field] is num) {
            return (json[field] as num).toDouble();
          } else if (json[field] is String) {
            final parsed = double.tryParse(json[field].toString().trim());
            if (parsed != null) {
              return parsed;
            }
          }
        } catch (e) {
          // Silently continue to next field
          continue;
        }
      }
    }

    return null;
  }

  // Helper method to parse timestamp from various formats
  Timestamp? _parseTimestamp(dynamic timestampData) {
    if (timestampData == null) return null;

    if (timestampData is Timestamp) {
      return timestampData;
    } else if (timestampData is String) {
      try {
        // Parse ISO 8601 string
        final dateTime = DateTime.parse(timestampData);
        return Timestamp.fromDate(dateTime);
      } catch (e) {
        print('Error parsing timestamp string: $timestampData, error: $e');
        return null;
      }
    } else if (timestampData is int) {
      // Handle milliseconds since epoch
      return Timestamp.fromMillisecondsSinceEpoch(timestampData);
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (address != null) {
      data['address'] = address!.toJson();
    }
    data['status'] = status;
    data['couponId'] = couponId;
    data['vendorID'] = vendorID;
    data['driverID'] = driverID;
    data['discount'] = discount;
    data['authorID'] = authorID;
    data['estimatedTimeToPrepare'] = estimatedTimeToPrepare;
    data['createdAt'] = createdAt;
    data['triggerDelivery'] = triggerDelivery;

    if (taxSetting != null) {
      data['taxSetting'] = taxSetting!.map((v) => v.toJson()).toList();
    }

    data['payment_method'] = paymentMethod;

    if (products != null) {
      data['products'] = products!.map((v) => v.toJson()).toList();
    }

    data['adminCommissionType'] = adminCommissionType;

    if (vendor != null) {
      data['vendor'] = vendor!.toJson();
    }

    data['id'] = id;
    data['adminCommission'] = adminCommission;
    data['couponCode'] = couponCode;
    data['specialDiscount'] = specialDiscount;
    data['deliveryCharge'] = deliveryCharge;
    data['scheduleTime'] = scheduleTime;
    data['tip_amount'] = tipAmount;
    data['notes'] = notes;

    if (author != null) {
      data['author'] = author!.toJson();
    }

    if (driver != null) {
      data['driver'] = driver!.toJson();
    }

    data['takeAway'] = takeAway;
    data['rejectedByDrivers'] = rejectedByDrivers;

    // FIXED: Include toPay with lowercase field name (matches API)
    data['toPay'] = toPayAmount;
    // Keep backward compatibility
    data['ToPay'] = toPayAmount?.toString();
    data['toPayAmount'] = toPayAmount;

    data['surge_fee'] = surgeFee;

    // NEW FIELDS IN TOJSON
    data['calculatedCharges'] = calculatedCharges;
    data['orderAutoCancelAt'] = orderAutoCancelAt;
    data['photos'] = photos;
    data['photo'] = photo;
    data['restaurantMenuPhotos'] = restaurantMenuPhotos;
    data['workingHours'] = workingHours;

    return data;
  }

  @override
  String toString() {
    return 'OrderModel(id: $id, status: $status, toPayAmount: $toPayAmount, vendor: ${vendor?.title}, products: ${products?.length})';
  }
}
