class CouponModel {
  String? discountType;
  String? id;
  String? code;
  String? discount;
  String? image;
  dynamic expiresAt; // Changed from Timestamp to dynamic
  String? description;
  bool? isPublic;
  String? resturantId;
  bool? isEnabled;
  String? itemValue;
  String? cType;
  int? priceModelId;
  int? applicationType;
  int? paymentMethod;
  int? usageLimitPerUser;
  String? userType;

  CouponModel({
    this.discountType,
    this.id,
    this.code,
    this.discount,
    this.image,
    this.expiresAt,
    this.description,
    this.isPublic,
    this.resturantId,
    this.isEnabled,
    this.itemValue,
    this.cType,
    this.priceModelId,
    this.applicationType,
    this.paymentMethod,
    this.usageLimitPerUser,
    this.userType,
  });

  CouponModel.fromJson(Map<String, dynamic> json) {
    discountType = json['discountType']?.toString();
    id = json['couponId']?.toString() ?? json['id']?.toString();
    code = json['couponCode']?.toString() ?? json['code']?.toString();
    discount =
        json['discountValue']?.toString() ?? json['discount']?.toString();
    image = json['image'];
    expiresAt = json['endTime'] ?? json['expiresAt']; // Can be String or other format
    description = json['description']?.toString();
    isPublic = json['isPublic'];
    resturantId = json['resturantId'];
    isEnabled = json['isActive'] ?? json['isEnabled'];
    itemValue =
        json['minOrderValue']?.toString() ?? json['item_value']?.toString();
    cType = json['cType']?.toString();
    priceModelId = _toOptionalInt(json['priceModelId']);
    applicationType = _toOptionalInt(json['applicationType']);
    paymentMethod = _toOptionalInt(json['paymentMethod']);
    usageLimitPerUser = _toOptionalInt(json['usageLimitPerUser']);
    userType = json['userType']?.toString();

    // New API: priceModelId 1 = flat/fix, 2 = percentage
    if ((discountType == null || discountType!.isEmpty) && priceModelId != null) {
      discountType = priceModelId == 1 ? 'fix price' : 'percentage';
    }

    // New API has no description field - build a friendly one so the
    // coupon card in CouponListScreen has something to show.
    if ((description == null || description!.isEmpty) && code != null) {
      final isPercentage = _isPercentageType;
      final discountText = isPercentage ? '$discount% OFF' : '₹$discount OFF';
      final minText = (itemValue != null &&
              double.tryParse(itemValue!) != null &&
              double.parse(itemValue!) > 0)
          ? ' on orders above ₹${double.parse(itemValue!).toStringAsFixed(0)}'
          : '';
      description = 'Get $discountText$minText';
    }
  }

  bool get _isPercentageType {
    final normalizedDiscountType = (discountType ?? '').trim().toLowerCase();
    return normalizedDiscountType == "percentage" ||
        normalizedDiscountType.contains("percent");
  }

  static int? _toOptionalInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['discountType'] = discountType;
    data['id'] = id;
    data['couponId'] = id;
    data['code'] = code;
    data['couponCode'] = code;
    data['discount'] = discount;
    data['discountValue'] = discount;
    data['image'] = image;
    data['expiresAt'] = expiresAt;
    data['description'] = description;
    data['isPublic'] = isPublic;
    data['resturantId'] = resturantId;
    data['isEnabled'] = isEnabled;
    data['isActive'] = isEnabled;
    data['item_value'] = itemValue;
    data['minOrderValue'] = itemValue;
    data['cType'] = cType;
    data['priceModelId'] = priceModelId;
    data['applicationType'] = applicationType;
    data['paymentMethod'] = paymentMethod;
    data['usageLimitPerUser'] = usageLimitPerUser;
    data['userType'] = userType;
    return data;
  }
}
