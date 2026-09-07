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

import '../../constant/show_toast_dialog.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  late final LoginProvider _controller;

  @override
  void initState() {
    super.initState();
    _controller = Provider.of<LoginProvider>(context, listen: false);
    if (!_controller.resendTimerStarted) {
      _controller.startResendTimer();
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      ShowToastDialog.showToast("Please enter 6-digit OTP".tr);
      return;
    }
    _controller.verifyOtp(
      context,
      Provider.of<SplashProvider>(context, listen: false),
      otp,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          _buildBackgroundDecorations(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 60),
                  _buildOtpField(),
                  const SizedBox(height: 50),
                  _buildVerifyButton(),
                  const SizedBox(height: 40),
                  _buildResendSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Stack(
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
      ],
    );
  }

  Widget _buildHeader() {
    return Selector<LoginProvider, ({String countryCode, String phoneNumber})>(
      selector: (_, p) =>
          (countryCode: p.countryCode, phoneNumber: p.phoneNumber),
      builder: (context, data, _) {
        return Column(
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
            const SizedBox(height: 8),
            Text(
              "${'Enter the OTP sent to your mobile number.'.tr} "
              "${data.countryCode} "
              "${Constant.maskingString(data.phoneNumber, 3)}",
              style: TextStyle(
                color: AppThemeData.grey700,
                fontSize: 16,
                fontFamily: AppThemeData.regular,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOtpField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: PinCodeTextField(
        length: 6,
        appContext: context,
        keyboardType: TextInputType.phone,
        hintCharacter: "-",
        controller: _otpController,
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
        onChanged: (value) {},
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Selector<LoginProvider, bool>(
      selector: (_, p) => p.isVerifying,
      builder: (context, isVerifying, _) {
        return RoundedButtonFill(
          title: isVerifying ? "Verifying...".tr : "Verify & Next".tr,
          color: AppThemeData.primary300,
          textColor: AppThemeData.grey50,
          onPress: isVerifying ? null : _verifyOtp,
        );
      },
    );
  }

  Widget _buildResendSection() {
    return Selector<LoginProvider, ({int resendSeconds, bool isVerifying})>(
      selector: (_, p) =>
          (resendSeconds: p.resendSeconds, isVerifying: p.isVerifying),
      builder: (context, data, _) {
        return Text.rich(
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
                text: data.resendSeconds > 0
                    ? '  Resend in ${data.resendSeconds}s'
                    : '  Send Again'.tr,
                recognizer: data.resendSeconds > 0 || data.isVerifying
                    ? null
                    : (TapGestureRecognizer()..onTap = _controller.resendOtp),
                style: TextStyle(
                  color: data.resendSeconds > 0
                      ? AppThemeData.grey400
                      : AppThemeData.primary300,
                  decoration: data.resendSeconds > 0
                      ? null
                      : TextDecoration.underline,
                  fontFamily: AppThemeData.medium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
