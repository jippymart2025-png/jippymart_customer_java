/// Referral status: PENDING | QUALIFIED | REWARDED
enum ReferralStatus { pending, qualified, rewarded }

extension ReferralStatusExt on ReferralStatus {
  String get value {
    switch (this) {
      case ReferralStatus.pending:
        return 'PENDING';
      case ReferralStatus.qualified:
        return 'QUALIFIED';
      case ReferralStatus.rewarded:
        return 'REWARDED';
    }
  }

  static ReferralStatus fromString(String? v) {
    if (v == null) return ReferralStatus.pending;
    switch (v.toUpperCase()) {
      case 'QUALIFIED':
        return ReferralStatus.qualified;
      case 'REWARDED':
        return ReferralStatus.rewarded;
      default:
        return ReferralStatus.pending;
    }
  }
}

class ReferralModel {
  String? id;
  String? referralCode;
  String? referralBy;

  /// Extended fields for wallet/referral feature
  String? status; // PENDING | QUALIFIED | REWARDED
  String? refereeUserId;
  String? referrerUserId;
  String? codeUsed;
  DateTime? rewardedAt;

  ReferralModel({
    this.id,
    this.referralCode,
    this.referralBy,
    this.status,
    this.refereeUserId,
    this.referrerUserId,
    this.codeUsed,
    this.rewardedAt,
  });

  ReferralStatus get statusEnum => ReferralStatusExt.fromString(status);

  ReferralModel.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    referralCode = json['referralCode']?.toString();
    referralBy = json['referralBy']?.toString();
    status = json['status']?.toString();
    refereeUserId = json['refereeUserId']?.toString();
    referrerUserId = json['referrerUserId']?.toString();
    codeUsed = json['codeUsed']?.toString();
    if (json['rewardedAt'] != null) {
      if (json['rewardedAt'] is String) {
        rewardedAt = DateTime.tryParse(json['rewardedAt'] as String);
      } else if (json['rewardedAt'] is DateTime) {
        rewardedAt = json['rewardedAt'] as DateTime;
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['referralCode'] = referralCode;
    data['referralBy'] = referralBy;
    data['status'] = status;
    data['refereeUserId'] = refereeUserId;
    data['referrerUserId'] = referrerUserId;
    data['codeUsed'] = codeUsed;
    data['rewardedAt'] = rewardedAt?.toIso8601String();
    return data;
  }
}
