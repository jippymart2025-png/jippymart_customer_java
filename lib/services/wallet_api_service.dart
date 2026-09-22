import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:jippymart_customer/models/coin_ledger_model.dart';
import 'package:jippymart_customer/models/customer_wallet_model.dart';
import 'package:jippymart_customer/models/daily_checkin_model.dart';
import 'package:jippymart_customer/models/referral_model.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';

/// Wallet & Coin API service (contract only; backend implementation out of scope).
/// Uses [AppConst.baseUrl] and auth from [getHeaders] (SqlStorageConst.getAuthToken).
class WalletApiService {
  WalletApiService._();

  static final WalletApiService instance = WalletApiService._();

  String get _base => AppConst.baseUrl;

  Future<Map<String, String>> _headers() => getHeaders();

  /// GET /wallet/config — runtime wallet configuration (coins, check-in, referral).
  ///
  /// Supported response shapes:
  /// 1) { "success": true, "data": { "version": 1, "wallet_config": { ... } } }
  /// 2) { "version": 1, "wallet_config": { ... } }
  // Future<Map<String, dynamic>?> getWalletConfig() async {
  //   try {
  //     final uri = Uri.parse('${_base}wallet/config');
  //     final response = await http
  //         .get(uri, headers: await _headers())
  //         .timeout(const Duration(seconds: 15));
  //     if (response.statusCode != 200) return null;
  //     final map = json.decode(response.body) as Map<String, dynamic>?;
  //     if (map == null) return null;
  //
  //     // If backend sends { success, data }, prefer data node.
  //     if (map.containsKey('data')) {
  //       if (map.containsKey('success') && map['success'] != true) {
  //         return null;
  //       }
  //       final data = map['data'];
  //       if (data is Map<String, dynamic>) {
  //         return data;
  //       }
  //       return Map<String, dynamic>.from(data as Map);
  //     }
  //
  //     // Otherwise treat the whole JSON as config root
  //     return map;
  //   } catch (e) {
  //     print('[WalletApiService] getWalletConfig error: $e');
  //     return null;
  //   }
  // }

  /// GET /co/customers/wallet/{customerId} — returns the customer wallet.
  /// Backend responds with a flat object (see [CustomerWalletModel]); a
  /// { success, data } wrapper is also handled if present.
  Future<CustomerWalletModel?> getWallet() async {
    try {
      final customerId = await _customerId();
      if (customerId == null) {
        print('[WalletApiService] getWallet: missing customerId');
        return null;
      }
      final uri = Uri.parse('${_base}co/customers/wallet/$customerId');
      final response = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final decoded = json.decode(response.body);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final raw = map['success'] == true && map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;
      return CustomerWalletModel.fromJson(raw);
    } catch (e) {
      print('[WalletApiService] getWallet error: $e');
      return null;
    }
  }

  /// GET /co/wallet/transactions/{customerId} — coin ledger list.
  /// Response:
  /// - Non-empty: raw JSON array of { "customerWalletTransactionsId", "walletId",
  ///   "orderId", "transactionType", "points", "amount", "createdAt", ... }
  /// - Empty: { "success": true, "message": "No wallet transaction history found" }
  Future<List<CoinLedgerModel>> getCoinLedger({int? page, int? limit}) async {
    try {
      final customerId = await _customerId();
      if (customerId == null) {
        print('[WalletApiService] getCoinLedger: missing customerId');
        return [];
      }
      final uri = Uri.parse('${_base}co/wallet/transactions/$customerId');
      final response = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final decoded = json.decode(response.body);
      if (decoded is List) {
        return decoded
            .where((e) => e is Map)
            .map(
              (e) =>
                  CoinLedgerModel.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      }
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        if (map['success'] == true) {
          final data = map['data'];
          if (data is List) {
            return data
                .where((e) => e is Map)
                .map(
                  (e) => CoinLedgerModel.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList();
          }
          return []; // e.g. "No wallet transaction history found"
        }
      }
      return [];
    } catch (e) {
      print('[WalletApiService] getCoinLedger error: $e');
      return [];
    }
  }

  /// POST /wallet/coins/redeem — redeem coins to money (idempotent; send idempotency_key when applicable).
  /// Body: { "coins": int, "idempotency_key": String? }
  Future<Map<String, dynamic>?> redeemCoins({
    required int coins,
    String? idempotencyKey,
  }) async {
    try {
      final firebaseId = await SqlStorageConst.getFirebaseId() ?? '';
      final body = <String, dynamic>{'firebase_id': firebaseId, 'coins': coins};
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        body['idempotency_key'] = idempotencyKey;
      }
      final response = await http
          .post(
            Uri.parse('${_base}wallet/coins/redeem'),
            headers: await _headers(),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));
      final map = json.decode(response.body) as Map<String, dynamic>?;
      // Always return parsed JSON (even on 4xx) so caller can read `message`.
      return map;
    } catch (e) {
      print('[WalletApiService] redeemCoins error: $e');
      return null;
    }
  }

  /// POST /referral/apply-code — apply referral code (referee).
  /// Body: { "firebase_id", "code", "idempotency_key" optional }
  Future<Map<String, dynamic>?> applyReferralCode({
    required String code,
    String? idempotencyKey,
  }) async {
    try {
      final firebaseId = await SqlStorageConst.getFirebaseId() ?? '';
      final body = <String, dynamic>{'firebase_id': firebaseId, 'code': code};
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        body['idempotency_key'] = idempotencyKey;
      }
      final response = await http
          .post(
            Uri.parse('${_base}referral/apply-code'),
            headers: await _headers(),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));
      final map = json.decode(response.body) as Map<String, dynamic>?;
      if (response.statusCode != 200 && response.statusCode != 201) return null;
      return map;
    } catch (e) {
      print('[WalletApiService] applyReferralCode error: $e');
      return null;
    }
  }

  /// GET /referral/my-referrals — my referrals list.
  /// Query: firebase_id. Response: { "success": true, "data": [ ReferralModel (extended), ... ] }
  // Future<List<ReferralModel>> getMyReferrals() async {
  //   try {
  //     final firebaseId = await SqlStorageConst.getFirebaseId() ?? '';
  //     final uri = Uri.parse('${_base}referral/my-referrals').replace(
  //       queryParameters: firebaseId.isNotEmpty
  //           ? {'firebase_id': firebaseId}
  //           : null,
  //     );
  //     final response = await http
  //         .get(uri, headers: await _headers())
  //         .timeout(const Duration(seconds: 15));
  //     if (response.statusCode != 200) return [];
  //     final map = json.decode(response.body) as Map<String, dynamic>?;
  //     if (map?['success'] != true) return [];
  //     final list = map!['data'];
  //     if (list is! List) return [];
  //     return list
  //         .map(
  //           (e) => ReferralModel.fromJson(
  //             e is Map<String, dynamic>
  //                 ? e
  //                 : Map<String, dynamic>.from(e as Map),
  //           ),
  //         )
  //         .toList();
  //   } catch (e) {
  //     print('[WalletApiService] getMyReferrals error: $e');
  //     return [];
  //   }
  // }

  static String _todayDateParam() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<int?> _customerId() async {
    final storedId = await SqlStorageConst.getUserId() ?? '';
    return int.tryParse(storedId);
  }

  /// POST /co/customers/daily-streak/{customerId}?date=YYYY-MM-DD
  /// Response: { "success": true, "message": "...", "currentStreak": int, "maxStreak": int?, "points": int }
  Future<Map<String, dynamic>?> postCheckin({String? idempotencyKey}) async {
    try {
      final customerId = await _customerId();
      if (customerId == null) {
        print('[WalletApiService] postCheckin: missing customerId');
        return null;
      }
      final uri = Uri.parse(
        '${AppConst.outletBaseUrl}co/customers/daily-streak/$customerId',
      ).replace(queryParameters: {'date': _todayDateParam()});
      final response = await http
          .post(uri, headers: await _headers())
          .timeout(const Duration(seconds: 15));
      final map = json.decode(response.body) as Map<String, dynamic>?;
      if (response.statusCode != 200 && response.statusCode != 201) {
        return map;
      }
      if (map?['success'] == true) {
        await _persistCheckinFromResponse(map!);
      }
      return map;
    } catch (e) {
      print('[WalletApiService] postCheckin error: $e');
      return null;
    }
  }

  /// No GET endpoint on Spring Boot — rebuild status from locally cached streak data.
  Future<DailyCheckinModel?> getCheckinStatus() async {
    try {
      final dateStr = Preferences.getString(Preferences.walletLastCheckinDate);
      if (dateStr.isEmpty) return null;

      final parsed = DateTime.tryParse(dateStr);
      if (parsed == null) return null;

      final lastDay = DateTime(parsed.year, parsed.month, parsed.day);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final daysSinceLastCheckin = today.difference(lastDay).inDays;

      var streak = Preferences.getInt(
        Preferences.walletLastKnownPositiveStreak,
      );
      if (daysSinceLastCheckin > 1) {
        streak = 0;
      }

      return DailyCheckinModel(date: lastDay, streakDayNumber: streak);
    } catch (e) {
      print('[WalletApiService] getCheckinStatus error: $e');
      return null;
    }
  }

  Future<void> _persistCheckinFromResponse(Map<String, dynamic> map) async {
    final streak = map['currentStreak'] is int
        ? map['currentStreak'] as int
        : int.tryParse(map['currentStreak']?.toString() ?? '0') ?? 0;
    await Preferences.setString(
      Preferences.walletLastCheckinDate,
      _todayDateParam(),
    );
    await Preferences.setInt(Preferences.walletLastKnownPositiveStreak, streak);
  }

  Future<Map<String, dynamic>?> transferWalletPoints({
    required int senderCustomerId,
    required String receiverPhoneNumber,
    required int transferPoints,
    required int createdBy,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConst.baseUrl}/api/co/customers/wallet/transfer'),
      headers: await getHeaders(),
      body: jsonEncode({
        'senderCustomerId': senderCustomerId,
        'receiverPhoneNumber': receiverPhoneNumber,
        'transferPoints': transferPoints,
        'createdBy': createdBy,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data['message']?.toString() ?? 'Unable to transfer points');
  }
}
