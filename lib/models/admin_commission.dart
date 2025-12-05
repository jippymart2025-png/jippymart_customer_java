class AdminCommission {
  String? amount;
  bool? isEnabled;
  String? commissionType;

  AdminCommission({this.amount, this.isEnabled, this.commissionType});

  AdminCommission.fromJson(Map<String, dynamic> json) {
    // Handle amount field - could be fix_commission or amount
    if (json['fix_commission'] != null) {
      amount = json['fix_commission'].toString();
    } else if (json['amount'] != null) {
      amount = json['amount'].toString();
    }
    
    // Handle isEnabled - could be bool, int, or string
    isEnabled = _parseBool(json['isEnabled']);
    
    commissionType = json['commissionType']?.toString();
  }
  
  // Helper method to parse boolean values from bool, int, or string
  bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['fix_commission'] = amount;
    data['isEnabled'] = isEnabled;
    data['commissionType'] = commissionType;
    return data;
  }
}
