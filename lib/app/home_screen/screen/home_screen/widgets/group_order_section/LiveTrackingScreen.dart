import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groupAvatars = [
      'https://i.pravatar.cc/100?img=1',
      'https://i.pravatar.cc/100?img=2',
      'https://i.pravatar.cc/100?img=5',
      'https://i.pravatar.cc/100?img=6',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppThemeData.grey900,
            size: 18,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Live Tracking',
          style: TextStyle(
            fontFamily: AppThemeData.extraBold,
            color: AppThemeData.grey900,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.ios_share_rounded, color: AppThemeData.grey900),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ravi is on the way',
                    style: TextStyle(
                      fontFamily: AppThemeData.semiBold,
                      color: AppThemeData.grey900,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Arriving in ',
                        style: TextStyle(
                          fontFamily: AppThemeData.medium,
                          color: AppThemeData.grey500,
                          fontSize: 13,
                        ),
                      ),
                      const Text(
                        '12 mins',
                        style: TextStyle(
                          color: Color(0xFF2EBD59),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            // NOTE: This is a placeholder visual. Swap this Container for
            // google_maps_flutter (or your existing map widget) and plot
            // the live delivery-partner location on it.
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF1EE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.map_rounded,
                    size: 64,
                    color: Color(0xFFB9C2B5),
                  ),
                  Positioned(
                    bottom: 50,
                    left: 40,
                    child: _pin(Icons.local_pizza_rounded, Colors.red),
                  ),
                  const Positioned(
                    bottom: 30,
                    child: Icon(
                      Icons.delivery_dining_rounded,
                      size: 40,
                      color: Color(0xFFFF6B2C),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    right: 40,
                    child: _pin(Icons.home_rounded, const Color(0xFF2EBD59)),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
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
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/100?img=22',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery partner',
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                color: AppThemeData.grey500,
                                fontSize: 11.5,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Ravi Kumar',
                                  style: TextStyle(
                                    fontFamily: AppThemeData.semiBold,
                                    color: AppThemeData.grey900,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 15,
                                ),
                                const Text(
                                  ' 4.8',
                                  style: TextStyle(fontSize: 12.5),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _circleAction(Icons.call_rounded),
                      const SizedBox(width: 8),
                      _circleAction(Icons.chat_bubble_outline_rounded),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.groups_2_rounded,
                          size: 16,
                          color: AppThemeData.grey500,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Your order is shared with the group',
                            style: TextStyle(
                              fontFamily: AppThemeData.medium,
                              color: AppThemeData.grey500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 24,
                          width: groupAvatars.length * 16 + 10,
                          child: Stack(
                            children: [
                              for (int i = 0; i < groupAvatars.length; i++)
                                Positioned(
                                  left: i * 16.0,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 11,
                                      backgroundImage: NetworkImage(
                                        groupAvatars[i],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pin(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
        ],
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _circleAction(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E6),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: const Color(0xFFFF6B2C), size: 18),
    );
  }
}
