import 'package:flutter/material.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';

class OrderOptionsView extends StatelessWidget {
  final VoidCallback onGroupOrderingTap;
  final VoidCallback onHomeMadeMealsTap;
  final VoidCallback onDineInTap;
  final VoidCallback onMultiOrderingTap;
  final VoidCallback onScheduleOrderTap;

  const OrderOptionsView({
    super.key,
    required this.onGroupOrderingTap,
    required this.onHomeMadeMealsTap,
    required this.onDineInTap,
    required this.onMultiOrderingTap,
    required this.onScheduleOrderTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<_OrderOptionData> options = [
      _OrderOptionData(
        icon: Icons.groups_rounded,
        bgColor: const Color(0xFFE6F8EC),
        iconColor: const Color(0xFF2EBD59),
        title: 'Group\nOrdering',
        subtitle: 'Order together',
        onTap: onGroupOrderingTap,
      ),
      _OrderOptionData(
        icon: Icons.home_rounded,
        bgColor: const Color(0xFFFFF1DE),
        iconColor: const Color(0xFFFF9F1C),
        title: 'Home Made\nMeals',
        subtitle: 'Made with love',
        onTap: onHomeMadeMealsTap,
      ),
      // _OrderOptionData(
      //   icon: Icons.table_restaurant_rounded,
      //   bgColor: const Color(0xFFF1E9FF),
      //   iconColor: const Color(0xFF8C5DF0),
      //   title: 'Dine In',
      //   subtitle: 'Book a table',
      //   onTap: onDineInTap,
      // ),
      _OrderOptionData(
        icon: Icons.diversity_3_rounded,
        bgColor: const Color(0xFFFFE9EF),
        iconColor: const Color(0xFFF0568A),
        title: 'Multi\nOrdering',
        subtitle: 'From many places',
        onTap: onMultiOrderingTap,
      ),
      _OrderOptionData(
        icon: Icons.calendar_month_rounded,
        bgColor: const Color(0xFFE6F1FF),
        iconColor: const Color(0xFF2D8CF0),
        title: 'Schedule\nOrder',
        subtitle: 'Later delivery',
        onTap: onScheduleOrderTap,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: options
            .map((option) => Expanded(child: _OrderOptionTile(data: option)))
            .toList(),
      ),
    );
  }
}

class _OrderOptionData {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _OrderOptionData({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _OrderOptionTile extends StatelessWidget {
  final _OrderOptionData data;

  const _OrderOptionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: data.bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(data.icon, color: data.iconColor, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                data.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  color: AppThemeData.grey900,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  color: AppThemeData.grey500,
                  fontSize: 9.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
