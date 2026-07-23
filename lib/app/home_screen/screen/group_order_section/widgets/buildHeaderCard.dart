// widgets/group_order_header_card.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';

class GroupOrderHeaderCard extends StatelessWidget {
  final VendorModel restaurant;
  final String groupCode;
  final int minutes;
  final int seconds;
  final int memberCount;
  final bool isLeavingGroup;
  final List<String> memberAvatars;
  final VoidCallback onLeaveGroup;

  const GroupOrderHeaderCard({
    super.key,
    required this.restaurant,
    required this.groupCode,
    required this.minutes,
    required this.seconds,
    required this.memberCount,
    required this.isLeavingGroup,
    required this.memberAvatars,
    required this.onLeaveGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF5A5F), Color(0xFFE63950)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🎉 ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            restaurant.title ?? 'Group Order',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Group ID: $groupCode',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: isLeavingGroup ? null : Get.back,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                onSelected: (value) {
                  if (value == 'leave') {
                    onLeaveGroup();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'leave', child: Text('Leave group')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                height: 28,
                width: memberAvatars.length * 18 + 14,
                child: Stack(
                  children: [
                    for (int i = 0; i < memberAvatars.length; i++)
                      Positioned(
                        left: i * 18,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 13,
                            backgroundImage: NetworkImage(memberAvatars[i]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                memberCount > 0 ? '$memberCount members' : 'Group members',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text(
                  'Order closes in',
                  style: TextStyle(
                    fontFamily: AppThemeData.semiBold,
                    color: AppThemeData.grey900,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                _timeBox(_two(minutes), 'min'),
                const SizedBox(width: 6),
                Text(
                  ':',
                  style: TextStyle(
                    color: AppThemeData.grey900,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 6),
                _timeBox(_two(seconds), 'sec'),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, color: AppThemeData.grey500),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  Widget _timeBox(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppThemeData.grey900,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppThemeData.grey500, fontSize: 10),
        ),
      ],
    );
  }
}
