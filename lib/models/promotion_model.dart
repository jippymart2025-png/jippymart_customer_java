class PromotionModel {
  final int? id;
  final String? paymentMode;
  final String productTitle;
  final double? extraKmCharge;
  final String productId;
  final DateTime? endTime;
  final String restaurantId;
  final DateTime? startTime;
  final int itemLimit;
  final String restaurantTitle;
  final String vType;
  final String? zoneId;
  final double freeDeliveryKm;
  final double specialPrice;
  final bool isAvailable;

  PromotionModel({
    this.id,
    this.paymentMode,
    required this.productTitle,
    this.extraKmCharge,
    required this.productId,
    this.endTime,
    required this.restaurantId,
    this.startTime,
    required this.itemLimit,
    required this.restaurantTitle,
    required this.vType,
    this.zoneId,
    required this.freeDeliveryKm,
    required this.specialPrice,
    required this.isAvailable,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        if (value is String) {
          return DateTime.parse(value);
        }
        return null;
      } catch (e) {
        return null;
      }
    }

    final isAvailableNow = json['is_available_now'];
    final isAvailableLegacy = json['isAvailable'];

    final availableNow =
        isAvailableNow == 1 ||
        isAvailableNow == true ||
        isAvailableNow == '1' ||
        isAvailableNow == 'true' ||
        ((isAvailableNow == null) &&
            (isAvailableLegacy == 1 ||
                isAvailableLegacy == true ||
                isAvailableLegacy == '1' ||
                isAvailableLegacy == 'true'));

    return PromotionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      paymentMode: json['payment_mode']?.toString(),
      productTitle: json['product_title']?.toString() ?? '',
      extraKmCharge: json['extra_km_charge'] is num
          ? json['extra_km_charge'].toDouble()
          : double.tryParse(json['extra_km_charge']?.toString() ?? '0'),
      productId: json['product_id']?.toString() ?? '',
      endTime: parseDateTime(json['end_time']),
      restaurantId: json['restaurant_id']?.toString() ?? '',
      startTime: parseDateTime(json['start_time']),
      itemLimit: json['item_limit'] is int
          ? json['item_limit']
          : int.tryParse(json['item_limit']?.toString() ?? '0') ?? 0,
      restaurantTitle: json['restaurant_title']?.toString() ?? '',
      vType: json['vType']?.toString() ?? 'restaurant',
      zoneId: json['zoneId']?.toString(),
      freeDeliveryKm: json['free_delivery_km'] is num
          ? json['free_delivery_km'].toDouble()
          : double.tryParse(json['free_delivery_km']?.toString() ?? '0'),
      specialPrice: json['special_price'] is num
          ? json['special_price'].toDouble()
          : double.tryParse(json['special_price']?.toString() ?? '0'),
      isAvailable: availableNow,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_mode': paymentMode,
      'product_title': productTitle,
      'extra_km_charge': extraKmCharge,
      'product_id': productId,
      'end_time': endTime?.toIso8601String(),
      'restaurant_id': restaurantId,
      'start_time': startTime?.toIso8601String(),
      'item_limit': itemLimit,
      'restaurant_title': restaurantTitle,
      'vType': vType,
      'zoneId': zoneId,
      'free_delivery_km': freeDeliveryKm,
      'special_price': specialPrice,
      'isAvailable': isAvailable,
      'is_available_now': isAvailable ? 1 : 0,
    };
  }
}



