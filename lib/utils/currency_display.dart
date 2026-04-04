import 'package:jippymart_customer/constant/constant.dart';

/// Payable total: **nearest whole rupee**, no paisa in the string (e.g. ₹266 not ₹266.28).
String payableAmountDisplay(double amount) {
  if (amount.isNaN || amount.isInfinite) {
    return _payableWholeFormat(0);
  }
  return _payableWholeFormat(amount.round());
}

String _payableWholeFormat(int wholeRupees) {
  final symbol = Constant.currencyModel?.symbol ?? '₹';
  final symbolAtRight = Constant.currencyModel?.symbolAtRight ?? false;
  if (symbolAtRight) {
    return '$wholeRupees $symbol';
  }
  return '$symbol $wholeRupees';
}
