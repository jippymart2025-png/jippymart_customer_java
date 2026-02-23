class CoinWalletModel {
  String? userId;
  int? coinBalance;
  DateTime? updatedAt;

  CoinWalletModel({this.userId, this.coinBalance, this.updatedAt});

  CoinWalletModel.fromJson(Map<String, dynamic> json) {
    userId = json['userId']?.toString();
    coinBalance = json['coinBalance'] is int
        ? json['coinBalance'] as int
        : int.tryParse(json['coinBalance']?.toString() ?? '0');
    if (json['updatedAt'] != null) {
      if (json['updatedAt'] is String) {
        updatedAt = DateTime.tryParse(json['updatedAt'] as String);
      } else if (json['updatedAt'] is DateTime) {
        updatedAt = json['updatedAt'] as DateTime;
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['coinBalance'] = coinBalance;
    data['updatedAt'] = updatedAt?.toIso8601String();
    return data;
  }
}
