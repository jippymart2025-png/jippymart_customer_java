// import 'dart:io';
//
// import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
// import 'package:jippymart_customer/app/auth_screen/provider/login_provider.dart';
// import 'package:jippymart_customer/app/dash_board_screens/dash_board_screen.dart';
// import 'package:jippymart_customer/app/location_permission_screen/location_permission_screen.dart';
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/themes/app_them_data.dart';
// import 'package:jippymart_customer/themes/round_button_fill.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
//
// class LoginScreen extends StatelessWidget {
//   const LoginScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<LoginProvider>(
//       builder: (context, controller, _) {
//         return Scaffold(
//           appBar: AppBar(
//             backgroundColor: AppThemeData.surface,
//             actions: [
//               InkWell(
//                 onTap: () async {
//                   LocationPermission permission =
//                       await Geolocator.checkPermission();
//                   if (permission == LocationPermission.always ||
//                       permission == LocationPermission.whileInUse) {
//                     if (Constant.selectedLocation.location == null) {
//                       Get.offAll(() => LocationPermissionScreen());
//                     } else {
//                       Get.offAll(const DashBoardScreen());
//                     }
//                   } else {
//                     Get.offAll(() => LocationPermissionScreen());
//                   }
//                 },
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   child: Text(
//                     "Skip".tr,
//                     style: TextStyle(
//                       color: AppThemeData.primary300,
//                       fontSize: 18,
//                       fontFamily: AppThemeData.semiBold,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           body: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Welcome Back! 👋".tr,
//                     style: TextStyle(
//                       color: AppThemeData.grey900,
//                       fontSize: 22,
//                       fontFamily: AppThemeData.semiBold,
//                     ),
//                   ),
//                   Text(
//                     "Log in to continue enjoying delicious food delivered to your doorstep."
//                         .tr,
//                     style: TextStyle(
//                       color: AppThemeData.grey500,
//                       fontSize: 16,
//                       fontFamily: AppThemeData.regular,
//                     ),
//                   ),
//                   const SizedBox(height: 32),
//                   Visibility(
//                     visible: true,
//                     child: RoundedButtonFill(
//                       title: "Continue with Mobile Number".tr,
//                       textColor: AppThemeData.grey900,
//                       color: AppThemeData.grey100,
//                       icon: SvgPicture.asset(
//                         "assets/icons/ic_phone.svg",
//                         colorFilter: const ColorFilter.mode(
//                           AppThemeData.grey900,
//                           BlendMode.srcIn,
//                         ),
//                       ),
//                       isRight: false,
//                       onPress: () async {
//                         Get.to(() => PhoneNumberScreen());
//                       },
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                 ],
//               ),
//             ),
//           ),
//           bottomNavigationBar: Padding(
//             padding: EdgeInsets.symmetric(
//               vertical: Platform.isAndroid ? 10 : 30,
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text.rich(
//                   TextSpan(
//                     children: [
//                       TextSpan(
//                         text: "Didn't have an account?".tr,
//                         style: TextStyle(
//                           color: AppThemeData.grey900,
//                           fontFamily: AppThemeData.medium,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const WidgetSpan(child: SizedBox(width: 10)),
//                       // TextSpan(
//                       //   recognizer: TapGestureRecognizer()
//                       //     ..onTap = () {
//                       //       Get.to(const SignupScreen());
//                       //     },
//                       //   text: 'Sign up'.tr,
//                       //   style: TextStyle(
//                       //     color: AppThemeData.primary300,
//                       //     fontFamily: AppThemeData.bold,
//                       //     fontWeight: FontWeight.w500,
//                       //     decoration: TextDecoration.underline,
//                       //     decorationColor: AppThemeData.primary300,
//                       //   ),
//                       // ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
