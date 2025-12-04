import 'package:jippymart_customer/app/auth_screen/provider/login_provider.dart';
import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<LoginProvider>(context, listen: true);

    // run after UI builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.resendTimerStarted) {
        controller.startResendTimer();
      }
    });

    return Scaffold(
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Verify Your Number 📱".tr,
                    style: TextStyle(
                      color: AppThemeData.grey900,
                      fontSize: 22,
                      fontFamily: AppThemeData.semiBold,
                    ),
                  ),
                  Text(
                    "${'Enter the OTP sent to your mobile number.'.tr} "
                    "${controller.countryCode} "
                    "${Constant.maskingString(controller.phoneNumber, 3)}",
                    style: TextStyle(
                      color: AppThemeData.grey700,
                      fontSize: 16,
                      fontFamily: AppThemeData.regular,
                    ),
                  ),
                  const SizedBox(height: 60),

                  /// OTP BOX
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: PinCodeTextField(
                      length: 6,
                      appContext: context,
                      keyboardType: TextInputType.phone,
                      hintCharacter: "-",
                      controller: otpController,
                      textStyle: TextStyle(
                        color: AppThemeData.grey900,
                        fontFamily: AppThemeData.regular,
                      ),
                      pinTheme: PinTheme(
                        fieldHeight: 50,
                        fieldWidth: 40,
                        inactiveFillColor: AppThemeData.grey50,
                        selectedFillColor: AppThemeData.grey50,
                        activeFillColor: AppThemeData.grey50,
                        selectedColor: AppThemeData.grey50,
                        activeColor: AppThemeData.primary300,
                        inactiveColor: AppThemeData.grey50,
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enableActiveFill: true,
                      onCompleted: (v) {},
                    ),
                  ),

                  const SizedBox(height: 50),

                  /// VERIFY BUTTON
                  Consumer<SplashProvider>(
                    builder: (context, splashProvider, _) {
                      return RoundedButtonFill(
                        title: controller.isVerifying
                            ? "Verifying...".tr
                            : "Verify & Next".tr,
                        color: AppThemeData.primary300,
                        textColor: AppThemeData.grey50,
                        onPress: controller.isVerifying
                            ? null
                            : () async {
                                await controller.verifyOtp(
                                  context,
                                  splashProvider,
                                  otpController.text.trim(), // pass OTP
                                );
                              },
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  /// RESEND OTP
                  Text.rich(
                    TextSpan(
                      text: "Didn't receive any code?".tr,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        fontFamily: AppThemeData.medium,
                        color: AppThemeData.grey800,
                      ),
                      children: [
                        TextSpan(
                          text: controller.resendSeconds > 0
                              ? '  Resend in ${controller.resendSeconds}s'
                              : '  Send Again'.tr,
                          recognizer:
                              controller.resendSeconds > 0 ||
                                  controller.isVerifying
                              ? null
                              : (TapGestureRecognizer()
                                  ..onTap = () {
                                    controller.resendOtp();
                                    controller.startResendTimer();
                                  }),
                          style: TextStyle(
                            color: controller.resendSeconds > 0
                                ? AppThemeData.grey400
                                : AppThemeData.primary300,
                            decoration: controller.resendSeconds > 0
                                ? null
                                : TextDecoration.underline,
                            fontFamily: AppThemeData.medium,
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
}
