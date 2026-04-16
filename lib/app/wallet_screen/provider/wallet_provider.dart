import 'package:flutter/foundation.dart';

import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/coin_ledger_model.dart';
import 'package:jippymart_customer/models/coin_wallet_model.dart';
import 'package:jippymart_customer/models/daily_checkin_model.dart';
import 'package:jippymart_customer/models/referral_model.dart';
import 'package:jippymart_customer/services/wallet_api_service.dart';
import 'package:jippymart_customer/utils/preferences.dart';

class WalletProvider extends ChangeNotifier {
  final WalletApiService _api = WalletApiService.instance;

  /// Throttle: skip GET /wallet if last fetch was within this duration (rapid Home → Profile → Wallet).
  static const Duration _walletRefreshThrottle = Duration(seconds: 45);

  DateTime? _lastWalletRefresh;

  CoinWalletModel? _coinWallet;
  int? _moneyBalancePaise;
  List<CoinLedgerModel> _coinLedger = [];
  List<ReferralModel> _myReferrals = [];
  DailyCheckinModel? _checkinStatus;
  int _lastKnownPositiveStreak = 0;
  bool _loadingWallet = false;
  bool _loadingLedger = false;
  bool _loadingReferrals = false;
  bool _loadingCheckin = false;
  String? _walletError;
  String? _referralCode; // user's own code from backend if available

  CoinWalletModel? get coinWallet => _coinWallet;

  int? get moneyBalancePaise => _moneyBalancePaise;

  int get coinBalance => _coinWallet?.coinBalance ?? 0;

  List<CoinLedgerModel> get coinLedger => _coinLedger;

  List<ReferralModel> get myReferrals => _myReferrals;

  DailyCheckinModel? get checkinStatus => _checkinStatus;

  bool get loadingWallet => _loadingWallet;

  bool get loadingLedger => _loadingLedger;

  bool get loadingReferrals => _loadingReferrals;

  bool get loadingCheckin => _loadingCheckin;

  String? get walletError => _walletError;

  String? get referralCode => _referralCode;

  bool get checkedInToday => _checkinStatus?.checkedInToday ?? false;

  int get streakDay => _checkinStatus?.streakDayNumber ?? 0;

  /// UI-friendly streak value:
  /// - Uses API streak when available (>0)
  /// - If backend temporarily returns 0 before today's check-in but last check-in
  ///   date is yesterday, keep showing yesterday's streak instead of 0
  int get displayStreakDay {
    final status = _checkinStatus;
    final apiStreak = status?.streakDayNumber ?? 0;
    if (apiStreak > 0) {
      _lastKnownPositiveStreak = apiStreak;
      return apiStreak;
    }
    if (status == null) return 0;

    if (_lastKnownPositiveStreak <= 0) {
      _lastKnownPositiveStreak = Preferences.getInt(
        Preferences.walletLastKnownPositiveStreak,
      );
    }

    final d = status.date;
    if (d != null && _isYesterday(d)) {
      // Keep yesterday's streak visible until today's check-in is completed.
      return _lastKnownPositiveStreak > 0 ? _lastKnownPositiveStreak : 0;
    }

    // Missed at least one day => streak resets.
    return 0;
  }

  /// Money balance in rupees (for display). Backend may return paise.
  double get moneyBalanceRupees => (_moneyBalancePaise ?? 0) / 100.0;

  /// Refreshes wallet from API. Use [force: true] to bypass throttle (manual refresh, after redeem/referral/order).
  Future<void> refreshWallet({bool force = false}) async {
    if (!force &&
        _lastWalletRefresh != null &&
        DateTime.now().difference(_lastWalletRefresh!) <
            _walletRefreshThrottle) {
      return;
    }
    _loadingWallet = true;
    _walletError = null;
    notifyListeners();
    try {
      final data = await _api.getWallet();
      if (data != null) {
        _coinWallet = _api.parseCoinWallet(data);
        final mb = data['money_balance_paise'];
        if (mb is int) {
          _moneyBalancePaise = mb;
        } else if (mb != null) {
          _moneyBalancePaise = int.tryParse(mb.toString());
        }
        _referralCode = data['referral_code']?.toString();
        _lastWalletRefresh = DateTime.now();
      }
    } catch (e) {
      _walletError = e.toString();
    }
    _loadingWallet = false;
    notifyListeners();
  }

  Future<void> refreshCoinLedger() async {
    _loadingLedger = true;
    notifyListeners();
    try {
      _coinLedger = await _api.getCoinLedger();
    } catch (_) {
      _coinLedger = [];
    }
    _loadingLedger = false;
    notifyListeners();
  }

  Future<void> refreshMyReferrals() async {
    _loadingReferrals = true;
    notifyListeners();
    try {
      _myReferrals = await _api.getMyReferrals();
    } catch (_) {
      _myReferrals = [];
    }
    _loadingReferrals = false;
    notifyListeners();
  }

  // Inside WalletProvider:
  int get totalCoinsEarned => coinLedger
      .where((e) => (e.coins ?? 0) > 0)
      .fold(0, (sum, e) => sum + (e.coins ?? 0));

  int get totalCoinsSpent => coinLedger
      .where((e) => (e.coins ?? 0) < 0)
      .fold(0, (sum, e) => sum + (e.coins ?? 0));

  Future<void> refreshCheckinStatus() async {
    _loadingCheckin = true;
    notifyListeners();
    try {
      _checkinStatus = await _api.getCheckinStatus();
      final fetchedStreak = _checkinStatus?.streakDayNumber ?? 0;
      if (fetchedStreak > 0) {
        _lastKnownPositiveStreak = fetchedStreak;
        await Preferences.setInt(
          Preferences.walletLastKnownPositiveStreak,
          fetchedStreak,
        );
      } else {
        final lastDate = _checkinStatus?.date;
        final isCarryOverAllowed = lastDate != null && _isYesterday(lastDate);
        if (!isCarryOverAllowed) {
          _lastKnownPositiveStreak = 0;
          await Preferences.setInt(
            Preferences.walletLastKnownPositiveStreak,
            0,
          );
        }
      }
    } catch (_) {
      _checkinStatus = null;
    }
    _loadingCheckin = false;
    notifyListeners();
  }

  bool _isYesterday(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputDay = DateTime(local.year, local.month, local.day);
    return inputDay == today.subtract(const Duration(days: 1));
  }

  /// Redeem coins. Returns success message or error. Idempotency key optional.
  Future<String?> redeemCoins({
    required int coins,
    String? idempotencyKey,
  }) async {
    try {
      final res = await _api.redeemCoins(
        coins: coins,
        idempotencyKey: idempotencyKey,
      );
      if (res != null && res['success'] == true) {
        await refreshWallet(force: true);
        return null; // success
      }
      return res?['message']?.toString() ?? 'Redemption failed';
    } catch (e) {
      return e.toString();
    }
  }

  /// Apply referral code (referee). Idempotency key optional.
  Future<String?> applyReferralCode({
    required String code,
    String? idempotencyKey,
  }) async {
    try {
      final res = await _api.applyReferralCode(
        code: code.trim(),
        idempotencyKey: idempotencyKey,
      );
      if (res != null && res['success'] == true) {
        await refreshWallet(force: true);
        await refreshMyReferrals();
        return null;
      }
      return res?['message']?.toString() ??
          '"You have already applied a referral code"';
    } catch (e) {
      return e.toString();
    }
  }

  /// POST check-in. Idempotency key optional.
  Future<String?> doCheckin({String? idempotencyKey}) async {
    try {
      final res = await _api.postCheckin(idempotencyKey: idempotencyKey);
      if (res != null && res['success'] == true) {
        await refreshCheckinStatus();
        await refreshWallet(force: true);
        return null;
      }
      return res?['message']?.toString() ?? 'Check-in failed';
    } catch (e) {
      return e.toString();
    }
  }

  /// Coins to rupees (1000 coins = ₹100).
  static double coinsToRupees(int coins) {
    if (Constant.coinsPer100Rupees <= 0) return 0;
    return (coins / Constant.coinsPer100Rupees) * 100.0;
  }

  /// Next streak bonus day (10, 20, 30).
  static int? nextStreakBonusDay(int currentStreak) {
    if (currentStreak < 10) return 10;
    if (currentStreak < 20) return 20;
    if (currentStreak < 30) return 30;
    return null;
  }

  static int streakBonusForDay(int day) {
    if (day == 10) return Constant.streakBonusDay10;
    if (day == 20) return Constant.streakBonusDay20;
    if (day == 30) return Constant.streakBonusDay30;
    return 0;
  }
}
