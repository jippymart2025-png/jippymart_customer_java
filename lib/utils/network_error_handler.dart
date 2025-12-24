import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/services/network_connectivity_service.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';

/// Network error handler utility
class NetworkErrorHandler {
  /// Check if error is a network-related error
  static bool isNetworkError(dynamic error) {
    if (error is SocketException) {
      return true;
    }
    if (error is HttpException) {
      return true;
    }
    if (error is FormatException && error.message.contains('network')) {
      return true;
    }
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('no internet') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection timed out') ||
        errorString.contains('connection reset');
  }

  /// Get user-friendly error message
  static String getErrorMessage(dynamic error, {String? customMessage}) {
    if (customMessage != null && customMessage.isNotEmpty) {
      return customMessage;
    }

    if (isNetworkError(error)) {
      return "No internet connection. Please check your network and try again."
          .tr;
    }

    if (error.toString().toLowerCase().contains('timeout')) {
      return "Request timed out. Please check your internet connection and try again."
          .tr;
    }

    return "Something went wrong. Please try again.".tr;
  }

  /// Show network error dialog
  static Future<void> showNetworkErrorDialog(
    BuildContext? context, {
    String? customMessage,
    VoidCallback? onRetry,
  }) async {
    final message = customMessage ??
        "No internet connection. Please check your network and try again.".tr;

    if (context != null && context.mounted) {
      return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text("No Internet Connection".tr),
            content: Text(message),
            actions: [
              if (onRetry != null)
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onRetry();
                  },
                  child: Text("Retry".tr),
                ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text("OK".tr),
              ),
            ],
          );
        },
      );
    } else {
      // Fallback to toast if no context
      ShowToastDialog.showToast(message);
    }
  }

  /// Show network error toast
  static void showNetworkErrorToast({String? customMessage}) {
    final message = customMessage ??
        "No internet connection. Please check your network and try again.".tr;
    ShowToastDialog.showToast(message);
  }

  /// Handle network error with appropriate UI feedback
  static Future<void> handleNetworkError(
    dynamic error,
    BuildContext? context, {
    String? customMessage,
    VoidCallback? onRetry,
    bool showDialog = true,
  }) async {
    if (kDebugMode) {
      print('❌ [NETWORK_ERROR] ${error.toString()}');
    }

    if (showDialog && context != null) {
      await showNetworkErrorDialog(
        context,
        customMessage: customMessage,
        onRetry: onRetry,
      );
    } else {
      showNetworkErrorToast(customMessage: customMessage);
    }
  }

  /// Check connectivity before making API call
  static Future<bool> checkConnectivityBeforeCall({
    BuildContext? context,
    bool showError = true,
  }) async {
    final connectivityService = NetworkConnectivityService();
    final isConnected = await connectivityService.checkConnectivity();

    if (!isConnected && showError) {
      if (context != null && context.mounted) {
        await showNetworkErrorDialog(context);
      } else {
        showNetworkErrorToast();
      }
    }

    return isConnected;
  }
}

