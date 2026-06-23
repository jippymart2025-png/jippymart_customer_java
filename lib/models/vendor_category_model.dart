class VendorCategoryModel {
  List<dynamic>? reviewAttributes;
  String? photo;
  String? description;
  String? id;
  String? title;
  int? productCount;
  bool? showInHomepage;
  bool? publish;
  String? vType;

  VendorCategoryModel({
    this.reviewAttributes,
    this.photo,
    this.description,
    this.id,
    this.title,
    this.productCount,
    this.showInHomepage,
    this.publish,
    this.vType,
  });

  VendorCategoryModel.fromJson(Map<String, dynamic> json) {
    reviewAttributes = json['review_attributes'] ?? [];
    photo = json['photo'] ?? "";
    description = json['description'] ?? '';
    id = json['id']?.toString() ??
        json['categoryId']?.toString() ??
        "";
    title = json['title'] ?? json['categoryName'] ?? "";
    productCount = json['product_count'] ??
        (json['products'] is List ? (json['products'] as List).length : 0);
    showInHomepage = json['show_in_homepage'] == true;
    publish = json['publish'] == true || json['categoryId'] != null;
    vType = json['vType'] ?? 'restaurant';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['review_attributes'] = reviewAttributes;
    data['photo'] = photo;
    data['description'] = description;
    data['id'] = id;
    data['title'] = title;
    data['product_count'] = productCount;
    data['show_in_homepage'] = showInHomepage;
    data['publish'] = publish;
    data['vType'] = vType;
    return data;
  }
}
