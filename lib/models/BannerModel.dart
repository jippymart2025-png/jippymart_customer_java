// class BannerModel {
//   String? id;
//   int? setOrder;
//   String? photo;
//   String? title;
//   bool? isPublish;
//   String? position;
//   String? redirectType;
//   String? redirectId;
//   String? zoneId;
//   String? zoneTitle;
//
//   BannerModel({
//     this.id,
//     this.setOrder,
//     this.photo,
//     this.title,
//     this.isPublish,
//     this.position,
//     this.redirectType,
//     this.redirectId,
//     this.zoneId,
//     this.zoneTitle,
//   });
//
//   BannerModel.fromJson(Map<String, dynamic> json) {
//     id = json['id']?.toString();
//     setOrder = json['set_order'];
//     photo = json['photo'];
//     title = json['title'];
//     isPublish = json['is_publish'];
//     position = json['position'];
//     redirectType = json['redirect_type'];
//     redirectId = json['redirect_id'];
//     zoneId = json['zoneId']?.toString();
//     zoneTitle = json['zoneTitle']?.toString();
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['id'] = id;
//     data['set_order'] = setOrder;
//     data['photo'] = photo;
//     data['title'] = title;
//     data['is_publish'] = isPublish;
//     data['position'] = position;
//     data['redirect_type'] = redirectType;
//     data['redirect_id'] = redirectId;
//     data['zoneId'] = zoneId;
//     data['zoneTitle'] = zoneTitle;
//     return data;
//   }
// }

class BannerModel {
  final int? areaId;
  final int? outletId;
  final String? outletName;
  final int? slotNumber;
  final String? bannerType;
  final String? bannerUrl;
  final String? priceModelType;
  final double? offerAmount;
  final double? radiusInKms;
  final double? latitude;
  final double? longitude;
  final List<int> mealTypeTimingIds;
  final String? bannerFromDate;
  final String? bannerToDate;

  BannerModel({
    this.areaId,
    this.outletId,
    this.outletName,
    this.slotNumber,
    this.bannerType,
    this.bannerUrl,
    this.priceModelType,
    this.offerAmount,
    this.radiusInKms,
    this.latitude,
    this.longitude,
    this.mealTypeTimingIds = const [],
    this.bannerFromDate,
    this.bannerToDate,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      areaId: json['areaId'],
      outletId: json['outletId'],
      outletName: json['outletName'],
      slotNumber: json['slotNumber'],
      bannerType: json['bannerType'],
      bannerUrl: json['bannerUrl'],
      priceModelType: json['priceModelType'],
      offerAmount: (json['offerAmount'] as num?)?.toDouble(),
      radiusInKms: (json['radiusInKms'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      mealTypeTimingIds:
          (json['mealTypeTimingIds'] as List?)?.map((e) => e as int).toList() ??
          [],
      bannerFromDate: json['bannerFromDate'],
      bannerToDate: json['bannerToDate'],
    );
  }
}
