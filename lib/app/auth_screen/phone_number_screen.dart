import 'package:country_code_picker/country_code_picker.dart';
import 'package:jippymart_customer/app/auth_screen/provider/login_provider.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/themes/text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Store the selected country code
  String selectedCountryCode = '+91';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginProvider>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: AppThemeData.surface,
          extendBodyBehindAppBar: true,
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: Stack(
            children: [
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppThemeData.primary300.withOpacity(0.1),
                        AppThemeData.primary300.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                left: -100,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppThemeData.primary300.withOpacity(0.08),
                        AppThemeData.primary300.withOpacity(0.03),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: SingleChildScrollView(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppThemeData.primary300,
                                    AppThemeData.primary300.withOpacity(0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppThemeData.primary300.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.phone_android_rounded,
                                color: Colors.white,
                                size: 35,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Title and subtitle
                            Text(
                              "Welcome Back! 👋".tr,
                              style: TextStyle(
                                color: AppThemeData.grey900,
                                fontSize: 32,
                                fontFamily: AppThemeData.semiBold,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Log in to continue enjoying delicious food delivered to your doorstep."
                                  .tr,
                              style: TextStyle(
                                color: AppThemeData.grey500,
                                fontSize: 16,
                                fontFamily: AppThemeData.regular,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 48),
                            TextFieldWidget(
                              title: 'Phone Number'.tr,
                              controller: controller.phoneEditingController,
                              hintText: 'Enter Phone Number'.tr,
                              textInputType:
                                  const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.done,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp('[0-9]'),
                                ),
                              ],
                              prefix: CountryCodePicker(
                                onChanged: (CountryCode countryCode) {
                                  // Update the selected country code
                                  setState(() {
                                    selectedCountryCode =
                                        countryCode.dialCode ?? '+91';
                                  });
                                  // Also update the provider's country code
                                  controller.countryCode = selectedCountryCode;
                                },
                                dialogTextStyle: TextStyle(
                                  color: AppThemeData.grey900,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppThemeData.medium,
                                ),
                                dialogBackgroundColor: AppThemeData.grey100,
                                initialSelection: 'IN',
                                countryFilter: const ['IN'],
                                comparator: (a, b) =>
                                    b.name!.compareTo(a.name.toString()),
                                textStyle: TextStyle(
                                  fontSize: 14,
                                  color: AppThemeData.grey900,
                                  fontFamily: AppThemeData.medium,
                                ),
                                searchDecoration: InputDecoration(
                                  iconColor: AppThemeData.grey900,
                                ),
                                searchStyle: TextStyle(
                                  color: AppThemeData.grey900,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppThemeData.medium,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // OTP sent success message
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: controller.isOtpSent ? 60 : 0,
                              child: controller.isOtpSent
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.green,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'OTP sent successfully!'.tr,
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 14,
                                                fontFamily: AppThemeData.medium,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            SizedBox(height: controller.isOtpSent ? 24 : 0),
                            // Send OTP button
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: !controller.isOtpSent
                                  ? Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppThemeData.primary300
                                                .withOpacity(0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: RoundedButtonFill(
                                        title: controller.isVerifying
                                            ? "Sending...".tr
                                            : "Send OTP".tr,
                                        color: AppThemeData.primary300,
                                        textColor: AppThemeData.grey50,
                                        onPress: controller.isVerifying
                                            ? null
                                            : () async {
                                                // Pass the country code to the sendOtp method
                                                await controller.sendOtp(
                                                  countryCode:
                                                      selectedCountryCode,
                                                );
                                              },
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppThemeData.grey100.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lock_rounded,
                                    color: AppThemeData.grey500,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Your phone number is safe with us. We'll send you a one-time password."
                                          .tr,
                                      style: TextStyle(
                                        color: AppThemeData.grey500,
                                        fontSize: 13,
                                        fontFamily: AppThemeData.regular,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 150),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
