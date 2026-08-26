class BannerModel {
  final int? outletId;
  final String? outletName;
  final int? slotNumber;
  final String? bannerType;
  final String? bannerUrl;

  const BannerModel({
    this.outletId,
    this.outletName,
    this.slotNumber,
    this.bannerType,
    this.bannerUrl,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      outletId: _toInt(json['outletId']),
      outletName: json['outletName'] as String?,
      slotNumber: _toInt(json['slotNumber']),
      bannerType: json['bannerType'] as String?,
      bannerUrl: _getBannerUrl(json),
    );
  }

  static String? _getBannerUrl(Map<String, dynamic> json) {
    final bannerUrl = json['bannerUrl']?.toString().trim();

    if (bannerUrl != null && bannerUrl.isNotEmpty) {
      return bannerUrl;
    }

    final photo = json['photo']?.toString().trim();

    if (photo != null && photo.isNotEmpty) {
      return photo;
    }

    return null;
  }

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

  bool get isValid {
    return bannerUrl != null && bannerUrl!.isNotEmpty;
  }

  bool get isDefaultBanner {
    return bannerType?.toUpperCase() == 'DEFAULT';
  }

  bool get isOutletBanner {
    return outletId != null;
  }

  @override
  String toString() {
    return 'BannerModel('
        'slotNumber: $slotNumber, '
        'bannerType: $bannerType, '
        'outletId: $outletId, '
        'outletName: $outletName, '
        'bannerUrl: $bannerUrl'
        ')';
  }
}

class BannerResponse {
  final List<BannerModel> mainBannerInfoDtos;
  final List<BannerModel> bestRestaurantBannerInfoDtos;
  final List<BannerModel> dealsBannerInfoDtos;

  const BannerResponse({
    this.mainBannerInfoDtos = const [],
    this.bestRestaurantBannerInfoDtos = const [],
    this.dealsBannerInfoDtos = const [],
  });

  factory BannerResponse.fromJson(Map<String, dynamic> json) {
    return BannerResponse(
      mainBannerInfoDtos: _parseBannerList(json['mainBannerInfoDtos']),
      bestRestaurantBannerInfoDtos: _parseBannerList(
        json['bestRestaurantBannerInfoDtos'],
      ),
      dealsBannerInfoDtos: _parseBannerList(json['dealsBannerInfoDtos']),
    );
  }

  static List<BannerModel> _parseBannerList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => BannerModel.fromJson(Map<String, dynamic>.from(item)))
        .where((banner) => banner.isValid)
        .toList();
  }

  bool get isEmpty {
    return mainBannerInfoDtos.isEmpty &&
        bestRestaurantBannerInfoDtos.isEmpty &&
        dealsBannerInfoDtos.isEmpty;
  }

  bool get isNotEmpty {
    return !isEmpty;
  }
}
