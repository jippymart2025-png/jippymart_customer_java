class VendorCategoryModel {
  final int categoryId;
  final String categoryName;
  final String categoryType;
  final String categoryImageUrl;
  final List<dynamic>? reviewAttributes;

  VendorCategoryModel({
    this.categoryId = 0,
    this.categoryName = '',
    this.categoryType = '',
    this.categoryImageUrl = '',
    this.reviewAttributes,
  });

  factory VendorCategoryModel.empty() {
    return VendorCategoryModel();
  }

  factory VendorCategoryModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['categoryId'] ?? json['id'];
    final parsedId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return VendorCategoryModel(
      categoryId: parsedId,
      categoryName: (json['categoryName'] ?? json['title'] ?? '').toString(),
      categoryType: (json['categoryType'] ?? json['vType'] ?? '').toString(),
      categoryImageUrl:
          (json['categoryImageUrl'] ?? json['photo'] ?? '').toString(),
      reviewAttributes: json['review_attributes'] is List
          ? List<dynamic>.from(json['review_attributes'])
          : null,
    );
  }

  // Legacy getters kept for older call sites.
  String? get id => categoryId == 0 ? null : categoryId.toString();

  String? get title => categoryName.isEmpty ? null : categoryName;

  String? get photo => categoryImageUrl.isEmpty ? null : categoryImageUrl;

  String? get description => null;

  int? get productCount => null;

  bool? get showInHomepage => null;

  bool? get publish => categoryId != 0;

  String? get vType =>
      categoryType.isEmpty ? 'restaurant' : categoryType;

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryType': categoryType,
      'categoryImageUrl': categoryImageUrl,
      if (reviewAttributes != null) 'review_attributes': reviewAttributes,
    };
  }
}
