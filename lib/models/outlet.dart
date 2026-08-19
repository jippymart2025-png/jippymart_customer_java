// import 'package:jippymart_customer/models/vendor_model.dart';
//
// class Outlet {
//   final int outletId;
//   final String outletName;
//   final String? cuisineType;
//   final String? outletPicUrl;
//   final String? outletPhone;
//   final double? radius;
//   final double? review;
//   final String? subscriptionStatus;
//   final String? promotionStatus;
//   final double distanceKm;
//   final String? roadDistance;
//   final String? deliveryTime;
//   final String? openingTime;
//   final String? closingTime;
//   final bool? openNow;
//
//   Outlet({
//     required this.outletId,
//     required this.outletName,
//     this.cuisineType,
//     this.outletPicUrl,
//     this.outletPhone,
//     this.radius,
//     this.review,
//     this.subscriptionStatus,
//     this.promotionStatus,
//     required this.distanceKm,
//     this.roadDistance,
//     this.deliveryTime,
//     this.openingTime,
//     this.closingTime,
//     this.openNow,
//   });
//
//   factory Outlet.fromJson(Map<String, dynamic> json) {
//     final rawId = json['outletId'];
//     final parsedId = rawId is int
//         ? rawId
//         : int.tryParse(rawId?.toString() ?? '');
//     if (parsedId == null || parsedId == 0) {
//       throw FormatException('Invalid outletId: $rawId');
//     }
//
//     return Outlet(
//       outletId: parsedId,
//       outletName: json['outletName']?.toString() ?? '',
//       cuisineType: json['cuisineType']?.toString(),
//       outletPicUrl: json['outletPicUrl']?.toString(),
//       outletPhone: json['outletPhone']?.toString(),
//       radius: (json['radius'] as num?)?.toDouble(),
//       review: (json['review'] as num?)?.toDouble(),
//       subscriptionStatus: json['subscriptionStatus']?.toString(),
//       promotionStatus: json['promotionStatus']?.toString(),
//       distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
//       roadDistance: json['roadDistance']?.toString(),
//       deliveryTime: json['deliveryTime']?.toString(),
//       openingTime: json['openingTime']?.toString(),
//       closingTime: json['closingTime']?.toString(),
//       openNow: json['openNow'] as bool?,
//     );
//   }
//
//   VendorModel toVendorModel() {
//     final rating = review;
//
//     return VendorModel(
//       id: outletId.toString(),
//       title: outletName,
//       photo: outletPicUrl,
//       phonenumber: outletPhone ?? '',
//       reviewsSum: rating,
//       reviewsCount: rating != null && rating > 0 ? 1 : null,
//       distance: distanceKm,
//       isOpen: openNow ?? true,
//       isActive: true,
//       vType: 'restaurant',
//       categoryTitle: cuisineType != null && cuisineType!.isNotEmpty
//           ? [cuisineType!]
//           : null,
//       openDineTime: openingTime ?? '',
//       closeDineTime: closingTime ?? '',
//     );
//   }
// }
