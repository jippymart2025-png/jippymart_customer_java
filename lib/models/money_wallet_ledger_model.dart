/// Money wallet ledger type.
enum MoneyWalletLedgerType {
  coinRedeemCredit,
  orderDebit,
  refund,
  adjustment,
}

extension MoneyWalletLedgerTypeExt on MoneyWalletLedgerType {
  String get value {
    switch (this) {
      case MoneyWalletLedgerType.coinRedeemCredit:
        return 'COIN_REDEEM_CREDIT';
      case MoneyWalletLedgerType.orderDebit:
        return 'ORDER_DEBIT';
      case MoneyWalletLedgerType.refund:
        return 'REFUND';
      case MoneyWalletLedgerType.adjustment:
        return 'ADJUSTMENT';
    }
  }

  static MoneyWalletLedgerType fromString(String? v) {
    if (v == null) return MoneyWalletLedgerType.adjustment;
    switch (v.toUpperCase()) {
      case 'COIN_REDEEM_CREDIT':
        return MoneyWalletLedgerType.coinRedeemCredit;
      case 'ORDER_DEBIT':
        return MoneyWalletLedgerType.orderDebit;
      case 'REFUND':
        return MoneyWalletLedgerType.refund;
      case 'ADJUSTMENT':
        return MoneyWalletLedgerType.adjustment;
      default:
        return MoneyWalletLedgerType.adjustment;
    }
  }
}

class MoneyWalletLedgerModel {
  String? id;
  String? type; // COIN_REDEEM_CREDIT, ORDER_DEBIT, REFUND, ADJUSTMENT
  int? amountInPaise;
  String? referenceId;
  DateTime? createdAt;
  Map<String, dynamic>? metadata;

  MoneyWalletLedgerModel({
    this.id,
    this.type,
    this.amountInPaise,
    this.referenceId,
    this.createdAt,
    this.metadata,
  });

  MoneyWalletLedgerType get typeEnum => MoneyWalletLedgerTypeExt.fromString(type);

  MoneyWalletLedgerModel.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    type = json['type']?.toString();
    amountInPaise = json['amountInPaise'] is int
        ? json['amountInPaise'] as int
        : int.tryParse(json['amountInPaise']?.toString() ?? '0');
    referenceId = json['referenceId']?.toString();
    if (json['createdAt'] != null) {
      if (json['createdAt'] is String) {
        createdAt = DateTime.tryParse(json['createdAt'] as String);
      } else if (json['createdAt'] is DateTime) {
        createdAt = json['createdAt'] as DateTime;
      }
    }
    metadata = json['metadata'] is Map<String, dynamic>
        ? json['metadata'] as Map<String, dynamic>
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['type'] = type;
    data['amountInPaise'] = amountInPaise;
    data['referenceId'] = referenceId;
    data['createdAt'] = createdAt?.toIso8601String();
    data['metadata'] = metadata;
    return data;
  }
}
