import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:provider/provider.dart';
import '../../../themes/app_them_data.dart';
import '../provider/swiggy_search_provider.dart';

Widget buildRecentSearchesHeader(context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        "Recent Searches",
        style: TextStyle(
          fontFamily: AppThemeData.semiBold,
          fontSize: 20,
          color: AppThemeData.grey900,
          letterSpacing: 0.3,
        ),
      ),
      GestureDetector(
        onTap: () => _clearRecentSearches(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppThemeData.grey200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.clear_all, color: AppThemeData.grey500, size: 14),
              const SizedBox(width: 4),
              Text(
                "Clear",
                style: TextStyle(
                  fontSize: 12,
                  color: AppThemeData.grey500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

void _clearRecentSearches(context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          "Clear Recent Searches?",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppThemeData.grey900,
          ),
        ),
        content: Text(
          "This will remove all your recent search history. This action cannot be undone.",
          style: TextStyle(color: AppThemeData.grey400),
        ),
        backgroundColor: AppThemeData.grey50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: AppThemeData.grey400),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<SwiggySearchProvider>().clearRecentSearches();
              Navigator.pop(context);
              Get.snackbar(
                "Cleared",
                "Recent searches have been cleared",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppThemeData.success500,
                colorText: AppThemeData.grey50,
              );
            },
            child: Text(
              "Clear",
              style: TextStyle(
                color: AppThemeData.danger500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}
