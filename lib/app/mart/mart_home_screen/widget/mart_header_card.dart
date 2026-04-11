import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/utils/utils/color_const.dart';

class MartHeaderCard extends StatefulWidget {
  final double screenWidth;

  const MartHeaderCard({super.key, required this.screenWidth});

  @override
  State<MartHeaderCard> createState() => _MartHeaderCardState();
}

class _MartHeaderCardState extends State<MartHeaderCard> {
  bool isMartSelected = true; // Since we're in mart screen, mart is selected

  void _navigateToCorrectHomeScreen() {
    print('Jippy Food button tapped!');
    try {
      Get.back();
    } catch (e) {
      print('Navigation error: $e');
      Get.back();
    }
  }

  void _selectMart() {
    print('JippyMart button tapped!');
    // Already in mart screen, so just stay here
    // Could add some visual feedback if needed
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).viewPadding.top + 8,
          left: 16,
          right: 16,
          bottom: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Group 280 - Toggle Button
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9EE),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Jippy Food Button (Left)
                  Expanded(
                    child: GestureDetector(
                      onTap: _navigateToCorrectHomeScreen,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF9EE),
                          // Jippy Food is not selected in mart screen
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            'FOOD',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // JippyMart Button (Right)
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectMart,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: ColorConst.orangeLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            'MART',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Group 289 - Delivery Address Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User avatar with initials
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ColorConst.orangeLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getUserInitials(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Delivery address information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery to ${Constant.selectedLocation.addressAs ?? 'Current Location'}',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: ColorConst.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Constant.selectedLocation.getFullAddress(),
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                          color: ColorConst.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _getUserInitials() {
  final userModel = Constant.userModel;
  if (userModel == null) return 'U';

  String firstName = userModel.firstName?.trim() ?? '';
  String lastName = userModel.lastName?.trim() ?? '';

  String firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
  String lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';

  if (firstInitial.isNotEmpty && lastInitial.isNotEmpty) {
    return '$firstInitial$lastInitial';
  } else if (firstInitial.isNotEmpty) {
    return firstInitial;
  } else if (lastInitial.isNotEmpty) {
    return lastInitial;
  } else {
    return 'U';
  }
}
