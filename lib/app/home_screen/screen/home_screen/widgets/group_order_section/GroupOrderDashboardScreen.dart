import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';

import 'SharedCartScreen.dart';
import 'create_group_orders_model.dart';

class GroupOrderDashboardScreen extends StatefulWidget {
  final String groupCode;

  const GroupOrderDashboardScreen({super.key, required this.groupCode});

  @override
  State<GroupOrderDashboardScreen> createState() =>
      _GroupOrderDashboardScreenState();
}

class _GroupOrderDashboardScreenState extends State<GroupOrderDashboardScreen> {
  Duration _remaining = const Duration(minutes: 12, seconds: 14);
  Timer? _timer;

  final List<String> _memberAvatars = [
    'https://i.pravatar.cc/100?img=1',
    'https://i.pravatar.cc/100?img=2',
    'https://i.pravatar.cc/100?img=3',
    'https://i.pravatar.cc/100?img=4',
  ];

  final List<GroupActivityEvent> _activity = [
    GroupActivityEvent(
      memberName: 'Rahul',
      avatarUrl: 'https://i.pravatar.cc/100?img=1',
      action: 'added',
      detail: 'Chicken Burger',
      timeAgo: '2 mins ago',
    ),
    GroupActivityEvent(
      memberName: 'Sneha',
      avatarUrl: 'https://i.pravatar.cc/100?img=5',
      action: 'added',
      detail: 'Garlic Bread',
      timeAgo: '5 mins ago',
    ),
    GroupActivityEvent(
      memberName: 'Akash',
      avatarUrl: 'https://i.pravatar.cc/100?img=6',
      action: 'is browsing',
      detail: 'Desserts...',
      timeAgo: 'Just now',
      isLive: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 0) {
        _timer?.cancel();
        return;
      }
      setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeaderCard(minutes, seconds),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity',
                    style: TextStyle(
                      fontFamily: AppThemeData.semiBold,
                      color: AppThemeData.grey900,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._activity.map(_buildActivityRow),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFFCBA8)),
                    backgroundColor: const Color(0xFFFFF1E6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // TODO: open add-items / menu screen for this restaurant
                  },
                  child: const Text(
                    'Add items',
                    style: TextStyle(
                      color: Color(0xFFFF6B2C),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B2C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Get.to(() => const SharedCartScreen());
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 6),
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.white,
                        child: Text(
                          '6',
                          style: TextStyle(
                            color: Color(0xFFFF6B2C),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(int minutes, int seconds) {
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
                      children: const [
                        Text('🎉 ', style: TextStyle(fontSize: 16)),
                        Text(
                          'Friday Night Feast',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Group ID: ${widget.groupCode}',
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
                onPressed: () => Get.back(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                height: 28,
                width: _memberAvatars.length * 18 + 14,
                child: Stack(
                  children: [
                    for (int i = 0; i < _memberAvatars.length; i++)
                      Positioned(
                        left: i * 18.0,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 13,
                            backgroundImage: NetworkImage(_memberAvatars[i]),
                          ),
                        ),
                      ),
                    Positioned(
                      left: _memberAvatars.length * 18.0,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor: const Color(0xFFE63950),
                          child: const Text(
                            '+2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '6 members',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
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

  Widget _buildActivityRow(GroupActivityEvent e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 17, backgroundImage: NetworkImage(e.avatarUrl)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  color: AppThemeData.grey800,
                  fontSize: 13.5,
                ),
                children: [
                  TextSpan(
                    text: '${e.memberName} ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: '${e.action} '),
                  TextSpan(
                    text: e.detail,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          Text(
            e.timeAgo,
            style: TextStyle(
              fontFamily: AppThemeData.medium,
              color: e.isLive ? const Color(0xFF2EBD59) : AppThemeData.grey500,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
