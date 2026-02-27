import 'dart:convert';

/// Runtime-configurable wallet & coin settings.
///
/// Expected backend response shape:
/// {
///   "version": 1,
///   "wallet_config": {
///     "coins_per_100_rupees": 1000,
///     "min_redeem_coins": 1000,
///     "daily_redeem_cap_rupees": 100.0,
///     "checkin": {
///       "coins_per_day": 25,
///       "streak_bonus": {
///         "day_10": 100,
///         "day_20": 250,
///         "day_30": 500
///       }
///     },
///     "referral": {
///       "referee_first_order_coins": 100
///     }
///   }
/// }
class WalletConfig {
  final int coinsPer100Rupees;
  final int minRedeemCoins;
  final double dailyRedeemCapRupees;
  final int checkinCoinsPerDay;
  final int streakBonusDay10;
  final int streakBonusDay20;
  final int streakBonusDay30;
  final int refereeFirstOrderCoins;

  /// Optional config version (ignored by app logic, useful for backend/auditing).
  final int? version;

  const WalletConfig({
    required this.coinsPer100Rupees,
    required this.minRedeemCoins,
    required this.dailyRedeemCapRupees,
    required this.checkinCoinsPerDay,
    required this.streakBonusDay10,
    required this.streakBonusDay20,
    required this.streakBonusDay30,
    required this.refereeFirstOrderCoins,
    this.version,
  });

  factory WalletConfig.fromJson(Map<String, dynamic> json) {
    // Allow backend to either send the full wrapper or just the wallet_config node.
    final Map<String, dynamic> root;
    if (json.containsKey('wallet_config')) {
      root = json;
    } else {
      root = {'wallet_config': json};
    }

    final wc = (root['wallet_config'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    final checkin = (wc['checkin'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    final streak = (checkin['streak_bonus'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    final referral = (wc['referral'] ?? <String, dynamic>{}) as Map<String, dynamic>;

    double _toDouble(dynamic v, double fallback) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      final parsed = double.tryParse(v.toString());
      return parsed ?? fallback;
    }

    int _toInt(dynamic v, int fallback) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      final parsed = int.tryParse(v.toString());
      return parsed ?? fallback;
    }

    return WalletConfig(
      coinsPer100Rupees: _toInt(wc['coins_per_100_rupees'], 1000),
      minRedeemCoins: _toInt(wc['min_redeem_coins'], 1000),
      dailyRedeemCapRupees: _toDouble(wc['daily_redeem_cap_rupees'], 100.0),
      checkinCoinsPerDay: _toInt(checkin['coins_per_day'], 25),
      streakBonusDay10: _toInt(streak['day_10'], 100),
      streakBonusDay20: _toInt(streak['day_20'], 250),
      streakBonusDay30: _toInt(streak['day_30'], 500),
      refereeFirstOrderCoins: _toInt(referral['referee_first_order_coins'], 100),
      version: json['version'] is int ? json['version'] as int : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (version != null) 'version': version,
      'wallet_config': {
        'coins_per_100_rupees': coinsPer100Rupees,
        'min_redeem_coins': minRedeemCoins,
        'daily_redeem_cap_rupees': dailyRedeemCapRupees,
        'checkin': {
          'coins_per_day': checkinCoinsPerDay,
          'streak_bonus': {
            'day_10': streakBonusDay10,
            'day_20': streakBonusDay20,
            'day_30': streakBonusDay30,
          },
        },
        'referral': {
          'referee_first_order_coins': refereeFirstOrderCoins,
        },
      },
    };
  }

  String toJsonString() => json.encode(toJson());

  static WalletConfig fromJsonString(String source) =>
      WalletConfig.fromJson(json.decode(source) as Map<String, dynamic>);
}

