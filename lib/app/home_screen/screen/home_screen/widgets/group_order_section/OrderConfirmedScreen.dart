import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';

import '../../../../../order_list_screen/screens/live_tracking_screen/live_tracking_screen.dart';
import 'create_group_orders_model.dart';

class OrderConfirmedScreen extends StatelessWidget {
  const OrderConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      OrderTrackingStep(
        title: 'Order Confirmed',
        timeLabel: '9:41 PM',
        status: OrderStepStatus.completed,
      ),
      OrderTrackingStep(
        title: 'Preparing',
        timeLabel: '9:43 PM',
        status: OrderStepStatus.completed,
      ),
      OrderTrackingStep(
        title: 'Out for delivery',
        timeLabel: 'In 12 mins',
        status: OrderStepStatus.current,
      ),
      OrderTrackingStep(
        title: 'Delivered',
        timeLabel: 'Upcoming',
        status: OrderStepStatus.upcoming,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 36),
            decoration: const BoxDecoration(
              color: Color(0xFF2EBD59),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF2EBD59),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Order Confirmed!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your order is being prepared',
                  style: TextStyle(color: Colors.white70, fontSize: 13.5),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppThemeData.grey100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppThemeData.primary50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Domino's Pizza",
                                  style: TextStyle(
                                    fontFamily: AppThemeData.semiBold,
                                    color: AppThemeData.grey900,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Order ID: #FD9842',
                                  style: TextStyle(
                                    fontFamily: AppThemeData.medium,
                                    color: AppThemeData.grey500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              children: [
                                Text(
                                  'View details',
                                  style: TextStyle(
                                    color: AppThemeData.grey500,
                                    fontSize: 12,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: AppThemeData.grey500,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      ...steps.map(_buildStep),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppThemeData.grey100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Get.to(() => const LiveTrackingScreen()),
                    icon: Icon(Icons.map_outlined, color: AppThemeData.grey800),
                    label: Text(
                      'Track on map',
                      style: TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        color: AppThemeData.grey900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(OrderTrackingStep step) {
    final bool isDone = step.status == OrderStepStatus.completed;
    final bool isCurrent = step.status == OrderStepStatus.current;
    final Color color = isDone || isCurrent
        ? const Color(0xFF2EBD59)
        : Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isDone || isCurrent
                    ? const Color(0xFF1A1A1A)
                    : Colors.grey,
              ),
            ),
          ),
          Text(
            step.timeLabel,
            style: TextStyle(
              fontSize: 12.5,
              color: isDone || isCurrent
                  ? const Color(0xFF2EBD59)
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
