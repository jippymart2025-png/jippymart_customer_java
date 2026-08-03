import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../common/OrderCard.dart';

class GroupOrdersSection extends ConsumerWidget {
  const GroupOrdersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(filteredGroupOrdersProvider);

    return Column(
      children: [
        const _OrderTabs(),
        const SizedBox(height: AppSpacing.md),
        if (orders.isEmpty)
          const _EmptyOrders()
        else
          SizedBox(
            height: 258,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 210,
                  child: OrderCard(order: orders[index], compact: false),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _OrderTabs extends ConsumerWidget {
  const _OrderTabs();

  static const _tabs = <String, OrderMembership?>{
    'All Orders': null,
    'Joined': OrderMembership.joined,
    'My Orders': OrderMembership.mine,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedOrderTabProvider);

    return Row(
      children: _tabs.entries.map((entry) {
        final isActive = selected == entry.value;
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xl),
          child: GestureDetector(
            onTap: () =>
                ref.read(selectedOrderTabProvider.notifier).state = entry.value,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 3,
                  width: 26,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _Pill({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: AppDecorations.outlinedCard(),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, color: AppColors.textMuted, size: 28),
          const SizedBox(height: 8),
          Text('No orders here yet', style: AppText.body),
        ],
      ),
    );
  }
}
