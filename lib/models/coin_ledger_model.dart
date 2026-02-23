/// Coin ledger entry type (backend credits/debits).
enum CoinLedgerType {
  referral,
  orderCredit,
  checkin,
  streakBonus,
  redeemDebit,
  adjustment,
}

extension CoinLedgerTypeExt on CoinLedgerType {
  String get value {
    switch (this) {
      case CoinLedgerType.referral:
        return 'REFERRAL';
      case CoinLedgerType.orderCredit:
        return 'ORDER_CREDIT';
      case CoinLedgerType.checkin:
        return 'CHECKIN';
      case CoinLedgerType.streakBonus:
        return 'STREAK_BONUS';
      case CoinLedgerType.redeemDebit:
        return 'REDEEM_DEBIT';
      case CoinLedgerType.adjustment:
        return 'ADJUSTMENT';
    }
  }

  static CoinLedgerType fromString(String? v) {
    if (v == null) return CoinLedgerType.adjustment;
    switch (v.toUpperCase()) {
      case 'REFERRAL':
        return CoinLedgerType.referral;
      case 'ORDER_CREDIT':
        return CoinLedgerType.orderCredit;
      case 'CHECKIN':
        return CoinLedgerType.checkin;
      case 'STREAK_BONUS':
        return CoinLedgerType.streakBonus;
      case 'REDEEM_DEBIT':
        return CoinLedgerType.redeemDebit;
      case 'ADJUSTMENT':
        return CoinLedgerType.adjustment;
      default:
        return CoinLedgerType.adjustment;
    }
  }
}

class CoinLedgerModel {
  String? id;
  String? userId;
  String? type; // REFERRAL, ORDER_CREDIT, CHECKIN, STREAK_BONUS, REDEEM_DEBIT, ADJUSTMENT
  int? coins; // +/- amount
  String? referenceId;
  DateTime? createdAt;
  Map<String, dynamic>? metadata;

  CoinLedgerModel({
    this.id,
    this.userId,
    this.type,
    this.coins,
    this.referenceId,
    this.createdAt,
    this.metadata,
  });

  CoinLedgerType get typeEnum => CoinLedgerTypeExt.fromString(type);

  CoinLedgerModel.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    userId = json['userId']?.toString();
    type = json['type']?.toString();
    coins = json['coins'] is int
        ? json['coins'] as int
        : int.tryParse(json['coins']?.toString() ?? '0');
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
    data['userId'] = userId;
    data['type'] = type;
    data['coins'] = coins;
    data['referenceId'] = referenceId;
    data['createdAt'] = createdAt?.toIso8601String();
    data['metadata'] = metadata;
    return data;
  }
}
