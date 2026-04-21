import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class ShowToastDialog {
  static DateTime? _lastToastAt;
  static String _lastToastMessage = '';
  static const Duration _toastDebounceWindow = Duration(milliseconds: 1200);
  static const Duration _iosGlobalToastThrottle = Duration(milliseconds: 2200);

  static showToast(
    String? message, {
    EasyLoadingToastPosition position = EasyLoadingToastPosition.top,
  }) {
    if (message == null || message.trim().isEmpty) return;

    final translatedMessage = message.tr;
    final now = DateTime.now();
    final bool isLikelyIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final bool isWithinIOSGlobalCooldown =
        isLikelyIOS &&
        _lastToastAt != null &&
        now.difference(_lastToastAt!) < _iosGlobalToastThrottle;
    final isDuplicateToast =
        _lastToastMessage == translatedMessage &&
        _lastToastAt != null &&
        now.difference(_lastToastAt!) < _toastDebounceWindow;

    if (isDuplicateToast || isWithinIOSGlobalCooldown) return;

    _lastToastMessage = translatedMessage;
    _lastToastAt = now;
    EasyLoading.showToast(translatedMessage, toastPosition: position);
  }

  static showLoader(String message) {
    EasyLoading.show(status: message);
  }

  static closeLoader() {
    EasyLoading.dismiss();
  }
}
