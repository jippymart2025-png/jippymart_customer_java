import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:jippymart_customer/models/coin_ledger_model.dart';
import 'package:jippymart_customer/models/coin_wallet_model.dart';
import 'package:jippymart_customer/models/daily_checkin_model.dart';
import 'package:jippymart_customer/models/referral_model.dart';
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
  Future<Map<String, dynamic>?> getWalletConfig() async {
    try {
      final uri = Uri.parse('${_base}wallet/config');
      final response = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final map = json.decode(response.body) as Map<String, dynamic>?;
      if (map == null) return null;

      // If backend sends { success, data }, prefer data node.
      if (map.containsKey('data')) {
        if (map.containsKey('success') && map['success'] != true) {
          return null;
        }
        final data = map['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
        return Map<String, dynamic>.from(data as Map);
      }

      // Otherwise treat the whole JSON as config root
      return map;
    } catch (e) {
      print('[WalletApiService] getWalletConfig error: $e');
      return null;
    }
  }

  /// GET /wallet — returns wallet data (coin balance, money balance).
  /// Sends firebase_id as query param for backend. Response: { "success": true, "data": { "coin_wallet": {...}, "money_balance_paise": int?, ... } }
  Future<Map<String, dynamic>?> getWallet() async {
    try {
      final firebaseId = await SqlStorageConst.getFirebaseId() ?? '';
      final uri = Uri.parse('${_base}wallet').replace(
        queryParameters: firebaseId.isNotEmpty ? {'firebase_id': firebaseId} : null,
      );
      final response = await http.get(
        uri,
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final map = json.decode(response.body) as Map<String, dynamic>?;
      if (map?['success'] != true || map?['data'] == null) return null;
      return map!['data'] as Map<String, dynamic>;
    } catch (e) {
      print('[WalletApiService] getWallet error: $e');
      return null;
    }
  }

  /// GET /wallet/coins/ledger — coin ledger list.
  /// Response: { "success": true, "data": [ { "id", "userId", "type", "coins", "referenceId", "createdAt", "metadata" }, ... ] }
  Future<List<CoinLedgerModel>> getCoinLedger({int? page, int? limit}) async {
    try {
      final firebaseId = await SqlStorageConst.getFirebaseId() ?? '';
      final q = <String, String>{};
      if (firebaseId.isNotEmpty) q['firebase_id'] = firebaseId;
      if (page != null) q['page'] = page.toString();
      if (limit != null) q['limit'] = limit.toString();
      final uri = Uri.parse('${_base}wallet/coins/ledger').replace(queryParameters: q.isNotEmpty ? q : null);
      final response = await http.get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final map = json.decode(response.body) as Map<String, dynamic>?;
      if (map?['success'] != true) return [];
      final list = map!['data'];
      if (list is! List) return [];
      return list
          .map((e) => CoinLedgerModel.fromJson(
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)))
          .toList();
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
      final body = <String, dynamic>{
        'firebase_id': firebaseId,
        'coins': coins,
      };
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        body['idempotency_key'] = idempotencyKey;
      }
      final response = await http.post(
        Uri.parse('${_base}wallet/coins/redeem'),
        headers: await _headers(),
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));
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
      final body = <String, dynamic>{
        'firebase_id': firebaseId,
        'code': code,
      };
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        body['idempotency_key'] = idempotencyKey;
      }
      final response = await http.post(
        Uri.parse('${_base}referral/apply-code'),
        headers: await _headers(),
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));
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
  Future<List<ReferralModel>> getMyReferrals() async {
    try {
      final firebaseId = await SqlStorageConst.getFirebaseId() ?? '';
      final uri = Uri.parse('${_base}referral/my-referrals').replace(
        queryParameters: firebaseId.isNotEmpty ? {'firebase_id': firebaseId} : null,
      );
      final response = await http.get(
        uri,
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final map = json.decode(response.body) as Map<String, dynamic>?;
      if (map?['success'] != true) return [];
      final list = map!['data'];
      if (list is! List) return [];
      return list
          .map((e) => ReferralModel.fromJson(
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      print('[WalletApiService] getMyReferrals error: $e');
      return [];
    }
  }

  /// POST /checkin — daily check-in (idempotent; timezone Asia/Kolkata).
  /// Body: { "firebase_id", "timezone", "idempotency_key" optional }
  Future<Map<String, dynamic>?> postCheckin({String? idempotencyKey}) async {
    try {
      final firebaseId = await SqlStorageConst.getFirebaseId() ?? '';
      final body = <String, dynamic>{
        'firebase_id': firebaseId,
        'timezone': 'Asia/Kolkata',
      };
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        body['idempotency_key'] = idempotencyKey;
      }
      final response = await http.post(
        Uri.parse('${_base}checkin'),
        headers: await _headers(),
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));
      final map = json.decode(response.body) as Map<String, dynamic>?;
      if (response.statusCode != 200 && response.statusCode != 201) return null;
      return map;
    } catch (e) {
      print('[WalletApiService] postCheckin error: $e');
      return null;
    }
  }

  /// GET /checkin/status — today's status and streak.
  /// Query: firebase_id. Response: { "success": true, "data": DailyCheckinModel }
  Future<DailyCheckinModel?> getCheckinStatus() async {
    try {
      final firebaseId = await SqlStorageConst.getFirebaseId() ?? '';
      final uri = Uri.parse('${_base}checkin/status').replace(
        queryParameters: firebaseId.isNotEmpty ? {'firebase_id': firebaseId} : null,
      );
      final response = await http.get(
        uri,
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final map = json.decode(response.body) as Map<String, dynamic>?;
      if (map?['success'] != true || map?['data'] == null) return null;
      final data = map!['data'];
      if (data is Map<String, dynamic>) {
        return DailyCheckinModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('[WalletApiService] getCheckinStatus error: $e');
      return null;
    }
  }

  /// Parse coin_wallet from GET /wallet response.
  CoinWalletModel? parseCoinWallet(Map<String, dynamic>? data) {
    if (data == null) return null;
    final cw = data['coin_wallet'];
    if (cw is Map<String, dynamic>) {
      return CoinWalletModel.fromJson(cw);
    }
    return null;
  }
}
