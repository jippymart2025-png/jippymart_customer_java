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
  });

  CouponModel.fromJson(Map<String, dynamic> json) {
    discountType = json['discountType'];
    id = json['id'];
    code = json['code'];
    discount = json['discount']?.toString();
    image = json['image'];
    expiresAt = json['expiresAt']; // Can be String or other format
    description = json['description'];
    isPublic = json['isPublic'];
    resturantId = json['resturantId'];
    isEnabled = json['isEnabled'];
    itemValue = json['item_value']?.toString();
    cType = json['cType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['discountType'] = discountType;
    data['id'] = id;
    data['code'] = code;
    data['discount'] = discount;
    data['image'] = image;
    data['expiresAt'] = expiresAt;
    data['description'] = description;
    data['isPublic'] = isPublic;
    data['resturantId'] = resturantId;
    data['isEnabled'] = isEnabled;
    data['item_value'] = itemValue;
    data['cType'] = cType;
    return data;
  }
}
