class DeliveryCharge {
  num? minimumDeliveryChargesWithinKm;
  num? minimumDeliveryCharges;
  num? deliveryChargesPerKm;
  bool? vendorCanModify;
  num? itemTotalThreshold;
  num? baseDeliveryCharge;
  num? freeDeliveryDistanceKm;
  num? perKmChargeAboveFreeDistance;

  DeliveryCharge({
    this.minimumDeliveryChargesWithinKm,
    this.minimumDeliveryCharges,
    this.deliveryChargesPerKm,
    this.vendorCanModify,
    this.itemTotalThreshold,
    this.baseDeliveryCharge,
    this.freeDeliveryDistanceKm,
    this.perKmChargeAboveFreeDistance,
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory DeliveryCharge.fromJson(Map<String, dynamic> json) {
    return DeliveryCharge(
      minimumDeliveryChargesWithinKm: _toNum(
        json['minimum_delivery_charges_within_km'],
      ),

      minimumDeliveryCharges: _toNum(json['minimum_delivery_charges']),

      deliveryChargesPerKm: _toNum(json['delivery_charges_per_km']),

      vendorCanModify: _toBool(json['vendor_can_modify']),

      itemTotalThreshold: _toNum(json['item_total_threshold']),

      baseDeliveryCharge: _toNum(json['base_delivery_charge']),

      freeDeliveryDistanceKm: _toNum(json['free_delivery_distance_km']),

      perKmChargeAboveFreeDistance: _toNum(
        json['per_km_charge_above_free_distance'],
      ),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'minimum_delivery_charges_within_km': minimumDeliveryChargesWithinKm,

      'minimum_delivery_charges': minimumDeliveryCharges,

      'delivery_charges_per_km': deliveryChargesPerKm,

      'vendor_can_modify': vendorCanModify,

      'item_total_threshold': itemTotalThreshold,

      'base_delivery_charge': baseDeliveryCharge,

      'free_delivery_distance_km': freeDeliveryDistanceKm,

      'per_km_charge_above_free_distance': perKmChargeAboveFreeDistance,
    };
  }

  // ============================================================
  // NUM PARSER
  // ============================================================

  static num? _toNum(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value;
    }

    return num.tryParse(value.toString());
  }

  // ============================================================
  // BOOL PARSER
  // ============================================================

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

  // ============================================================
  // COPY WITH
  // ============================================================

  DeliveryCharge copyWith({
    num? minimumDeliveryChargesWithinKm,
    num? minimumDeliveryCharges,
    num? deliveryChargesPerKm,
    bool? vendorCanModify,
    num? itemTotalThreshold,
    num? baseDeliveryCharge,
    num? freeDeliveryDistanceKm,
    num? perKmChargeAboveFreeDistance,
  }) {
    return DeliveryCharge(
      minimumDeliveryChargesWithinKm:
          minimumDeliveryChargesWithinKm ?? this.minimumDeliveryChargesWithinKm,

      minimumDeliveryCharges:
          minimumDeliveryCharges ?? this.minimumDeliveryCharges,

      deliveryChargesPerKm: deliveryChargesPerKm ?? this.deliveryChargesPerKm,

      vendorCanModify: vendorCanModify ?? this.vendorCanModify,

      itemTotalThreshold: itemTotalThreshold ?? this.itemTotalThreshold,

      baseDeliveryCharge: baseDeliveryCharge ?? this.baseDeliveryCharge,

      freeDeliveryDistanceKm:
          freeDeliveryDistanceKm ?? this.freeDeliveryDistanceKm,

      perKmChargeAboveFreeDistance:
          perKmChargeAboveFreeDistance ?? this.perKmChargeAboveFreeDistance,
    );
  }

  @override
  String toString() {
    return 'DeliveryCharge('
        'minimumDeliveryChargesWithinKm: '
        '$minimumDeliveryChargesWithinKm, '
        'minimumDeliveryCharges: '
        '$minimumDeliveryCharges, '
        'deliveryChargesPerKm: '
        '$deliveryChargesPerKm, '
        'vendorCanModify: '
        '$vendorCanModify, '
        'itemTotalThreshold: '
        '$itemTotalThreshold, '
        'baseDeliveryCharge: '
        '$baseDeliveryCharge, '
        'freeDeliveryDistanceKm: '
        '$freeDeliveryDistanceKm, '
        'perKmChargeAboveFreeDistance: '
        '$perKmChargeAboveFreeDistance'
        ')';
  }
}
