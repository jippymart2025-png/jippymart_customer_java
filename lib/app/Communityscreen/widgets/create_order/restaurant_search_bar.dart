import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';

class RestaurantSearchBar extends ConsumerWidget {
  const RestaurantSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).state = value,
              decoration: const InputDecoration(
                hintText: 'Search for restaurants or cuisines',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14.5),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
