import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:jippymart_customer/app/address_screens/screens/widgets/tokan.dart';

import '../../../../themes/app_them_data.dart';

class LoadingView extends StatelessWidget {
  const LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.8,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppThemeData.primary300,
              ),
            ),
          ),
          const SizedBox(height: Tokens.sp16),
          Text(
            "Loading your addresses…".tr,
            style: const TextStyle(
              fontSize: Tokens.textSM,
              color: Tokens.textMuted,
              fontFamily: AppThemeData.medium,
            ),
          ),
        ],
      ),
    );
  }
}
