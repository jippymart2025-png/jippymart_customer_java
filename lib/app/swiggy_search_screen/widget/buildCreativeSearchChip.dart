import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../themes/app_them_data.dart';
import '../provider/swiggy_search_provider.dart';
import 'getSearchEmoji.dart';

Widget buildCreativeSearchChip({
  required BuildContext context,
  required TextEditingController searchController,
  required String search,
  required bool isRecent,
  required int index,
}) {
  final emoji = getSearchEmoji(search);

  final primaryColor = isRecent
      ? AppThemeData.primary300
      : AppThemeData.warning300;

  final backgroundColor = isRecent
      ? AppThemeData.primary50
      : AppThemeData.warning50;

  final borderColor = isRecent
      ? AppThemeData.primary200
      : AppThemeData.warning200;

  return GestureDetector(
    onTap: () {
      searchController.text = search;
      context.read<SwiggySearchProvider>().performUnifiedSearch(search);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withOpacity(0.6), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(emoji), const SizedBox(width: 8), Text(search)],
      ),
    ),
  );
}
