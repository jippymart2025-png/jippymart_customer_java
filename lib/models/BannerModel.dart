class BannerModel {
  String? id;
  int? setOrder;
  String? photo;
  String? title;
  bool? isPublish;
  String? position;
  String? redirectType;
  String? redirectId;
  String? zoneId;
  String? zoneTitle;

  BannerModel({
    this.id,
    this.setOrder,
    this.photo,
    this.title,
    this.isPublish,
    this.position,
    this.redirectType,
    this.redirectId,
    this.zoneId,
    this.zoneTitle,
  });

  BannerModel.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    setOrder = json['set_order'];
    photo = json['photo'];
    title = json['title'];
    isPublish = json['is_publish'];
    position = json['position'];
    redirectType = json['redirect_type'];
    redirectId = json['redirect_id'];
    zoneId = json['zoneId']?.toString();
    zoneTitle = json['zoneTitle']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['set_order'] = setOrder;
    data['photo'] = photo;
    data['title'] = title;
    data['is_publish'] = isPublish;
    data['position'] = position;
    data['redirect_type'] = redirectType;
    data['redirect_id'] = redirectId;
    data['zoneId'] = zoneId;
    data['zoneTitle'] = zoneTitle;
    return data;
  }
}
