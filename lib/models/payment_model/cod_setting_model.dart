class CodSettingModel {
  bool? isEnabled;
  double? maxAmount; // Maximum order amount allowed for COD (default: 599)

  CodSettingModel({this.isEnabled, this.maxAmount});

  CodSettingModel.fromJson(Map<String, dynamic> json) {
    isEnabled = json['isEnabled'];
    maxAmount = json['maxAmount'] != null
        ? (json['maxAmount'] is int
            ? (json['maxAmount'] as int).toDouble()
            : json['maxAmount'] as double?)
        : 599.0; // Default to 599 if not provided
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['isEnabled'] = isEnabled;
    data['maxAmount'] = maxAmount ?? 599.0;
    return data;
  }

  // Get max amount with default fallback
  double getMaxAmount() {
    return maxAmount ?? 599.0;
  }
}
