/// Customer wallet returned by GET /co/customers/wallet/{customerId}.
///
/// Backend sends a flat object:
/// { "walletId", "customerId", "customerName", "referralCode", "balanceAmount", "balancePoints", ... }
class CustomerWalletModel {
  final int walletId;
  final int customerId;
  final String? customerName;
  final String? referralCode;

  /// Amount in rupees.
  final int balanceAmount;

  /// Coin/points balance.
  final int balancePoints;

  const CustomerWalletModel({
    this.walletId = 0,
    this.customerId = 0,
    this.customerName,
    this.referralCode,
    this.balanceAmount = 0,
    this.balancePoints = 0,
  });

  factory CustomerWalletModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '0') ?? 0;
    return CustomerWalletModel(
      walletId: toInt(json['walletId']),
      customerId: toInt(json['customerId']),
      customerName: json['customerName']?.toString(),
      referralCode: json['referralCode']?.toString(),
      balanceAmount: toInt(json['balanceAmount']),
      balancePoints: toInt(json['balancePoints']),
    );
  }

  /// Money balance in paise (what the rest of the app expects).
  int get moneyBalancePaise => balanceAmount * 100;
}