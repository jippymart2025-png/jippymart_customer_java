import 'dart:convert';

import 'package:crypto/crypto.dart';

/// PayU India legacy `_payment` hash rule:
///
/// `sha512(key|txnid|amount|productinfo|firstname|email|udf1|udf2|udf3|udf4|udf5||||||SALT)`
///
/// Only used for diagnostics — the SALT must never ship in the app binary.
class PayUHashUtil {
  PayUHashUtil._();

  /// The pipe-separated string that PayU validates against [hash].
  static String sourceString({
    required String key,
    required String txnid,
    required String amount,
    required String productinfo,
    required String firstname,
    required String email,
    String udf1 = '',
    String udf2 = '',
    String udf3 = '',
    String udf4 = '',
    String udf5 = '',
    required String salt,
  }) {
    return [
      key,
      txnid,
      amount,
      productinfo,
      firstname,
      email,
      udf1,
      udf2,
      udf3,
      udf4,
      udf5,
      '',
      '',
      '',
      '',
      '',
      salt,
    ].join('|');
  }

  static String compute({
    required String key,
    required String txnid,
    required String amount,
    required String productinfo,
    required String firstname,
    required String email,
    String udf1 = '',
    String udf2 = '',
    String udf3 = '',
    String udf4 = '',
    String udf5 = '',
    required String salt,
  }) {
    return sha512
        .convert(
          utf8.encode(
            sourceString(
              key: key,
              txnid: txnid,
              amount: amount,
              productinfo: productinfo,
              firstname: firstname,
              email: email,
              udf1: udf1,
              udf2: udf2,
              udf3: udf3,
              udf4: udf4,
              udf5: udf5,
              salt: salt,
            ),
          ),
        )
        .toString();
  }
}