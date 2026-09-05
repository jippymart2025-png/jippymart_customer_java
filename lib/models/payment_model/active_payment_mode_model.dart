class ActivePaymentModeModel {
  final int paymentModeId;
  final String paymentMode;
  final String? createdBy;
  final String? updatedBy;
  final String? createdAt;
  final String? updatedAt;
  final String isActive;

  const ActivePaymentModeModel({
    required this.paymentModeId,
    required this.paymentMode,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    required this.isActive,
  });

  bool get active => isActive.toUpperCase() == 'Y';

  factory ActivePaymentModeModel.fromJson(Map<String, dynamic> json) {
    return ActivePaymentModeModel(
      paymentModeId: json['paymentModeId'] ?? 0,
      paymentMode: (json['paymentMode'] ?? '').toString(),
      createdBy: json['createdBy']?.toString(),
      updatedBy: json['updatedBy']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      isActive: (json['isActive'] ?? 'N').toString(),
    );
  }

  static List<ActivePaymentModeModel> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .whereType<Map>()
        .map((e) => ActivePaymentModeModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
