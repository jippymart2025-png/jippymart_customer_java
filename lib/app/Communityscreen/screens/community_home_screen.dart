import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home_screen/screen/group_order_section/screens/create_group_order.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import 'create_group_order_screen.dart';
import 'home_screen.dart';

class CommunityHomeScreen extends ConsumerWidget {
  const CommunityHomeScreen({super.key});

  static const _destinations = [
    (icon: Icons.home_outlined, active: Icons.home_rounded, label: 'Home'),
    (
      icon: Icons.add_circle_outline_rounded,
      active: Icons.add_circle_rounded,
      label: 'Create Order',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final onSelect = (int i) =>
        ref.read(selectedIndexProvider.notifier).state = i;

    final body = IndexedStack(
      index: selectedIndex,
      children: [const HomeScreen(), const CreateGroupOrderScreen()],
    );

    // Phones get a bottom bar; tablet/desktop get a side rail — a
    // bottom bar on a wide screen reads like a leftover mobile habit.
    if (context.isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: body,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: onSelect,
              items: _destinations
                  .map(
                    (d) => BottomNavigationBarItem(
                      icon: Icon(d.icon),
                      activeIcon: Icon(d.active),
                      label: d.label,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              backgroundColor: AppColors.surface,
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              labelType: NavigationRailLabelType.all,
              minWidth: context.isDesktop ? 84 : 72,
              selectedIconTheme: const IconThemeData(color: AppColors.primary),
              selectedLabelTextStyle: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedIconTheme: const IconThemeData(
                color: AppColors.textMuted,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
              destinations: _destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.active),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(width: 1, color: AppColors.border),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
