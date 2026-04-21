import 'package:jippymart_customer/constant/constant.dart';

/// Payable total: **nearest whole rupee**, no paisa in the string (e.g. ₹266 not ₹266.28).
String payableAmountDisplay(double amount) {
  if (amount.isNaN || amount.isInfinite) {
    return _payableWholeFormat(0);
  }
  return _payableWholeFormat(_strictHalfRound(amount));
}

/// Custom rounding rule:
/// - decimal > 0.5 => next integer
/// - decimal <= 0.5 => current integer
int _strictHalfRound(double amount) {
  final sign = amount < 0 ? -1 : 1;
  final absAmount = amount.abs();
  final base = absAmount.floor();
  final fraction = absAmount - base;
  final rounded = fraction > 0.5 ? base + 1 : base;
  return rounded * sign;
}

String _payableWholeFormat(int wholeRupees) {
  final symbol = Constant.currencyModel?.symbol ?? '₹';
  final symbolAtRight = Constant.currencyModel?.symbolAtRight ?? false;
  if (symbolAtRight) {
    return '$wholeRupees $symbol';
  }
  return '$symbol $wholeRupees';
}
