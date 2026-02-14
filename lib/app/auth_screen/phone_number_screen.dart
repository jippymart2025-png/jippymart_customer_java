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

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  String selectedCountryCode = '+91';
  bool _isSendingOtp = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeData.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Stack(
      children: [
        _buildBackgroundDecorations(),
        SafeArea(child: _buildContent(context)),
      ],
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

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildLogo(),
            const SizedBox(height: 32),
            _buildWelcomeText(),
            const SizedBox(height: 48),
            _buildPhoneNumberField(context),
            const SizedBox(height: 32),
            _buildSendOtpButton(context),
            const SizedBox(height: 32),
            _buildPrivacyNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
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
            color: AppThemeData.primary300.withOpacity(0.3),
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
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildPhoneNumberField(BuildContext context) {
    final controller = Provider.of<LoginProvider>(context, listen: false);

    return TextFieldWidget(
      title: 'Phone Number'.tr,
      controller: controller.phoneEditingController,
      hintText: 'Enter Phone Number'.tr,
      textInputType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[0-9]')),
        LengthLimitingTextInputFormatter(10), // Limit to 10 digits
      ],
      prefix: CountryCodePicker(
        onChanged: (CountryCode countryCode) {
          setState(() {
            selectedCountryCode = countryCode.dialCode ?? '+91';
          });
        },
        dialogTextStyle: TextStyle(
          color: AppThemeData.grey900,
          fontWeight: FontWeight.w500,
          fontFamily: AppThemeData.medium,
        ),
        dialogBackgroundColor: AppThemeData.grey100,
        initialSelection: 'IN',
        countryFilter: const ['IN'],
        textStyle: TextStyle(
          fontSize: 14,
          color: AppThemeData.grey900,
          fontFamily: AppThemeData.medium,
        ),
      ),
    );
  }

  Widget _buildSendOtpButton(BuildContext context) {
    return Consumer<LoginProvider>(
      builder: (context, controller, _) {
        final isProcessing = controller.isVerifying || _isSendingOtp;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppThemeData.primary300.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: RoundedButtonFill(
            title: isProcessing ? "Sending...".tr : "Send OTP".tr,
            color: AppThemeData.primary300,
            textColor: AppThemeData.grey50,
            onPress: isProcessing ? null : () => _sendOtp(context, controller),
          ),
        );
      },
    );
  }

  Future<void> _sendOtp(BuildContext context, LoginProvider controller) async {
    setState(() => _isSendingOtp = true);
    try {
      await controller.sendOtp(countryCode: selectedCountryCode);
    } finally {
      if (mounted) {
        setState(() => _isSendingOtp = false);
      }
    }
  }

  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeData.grey100.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: AppThemeData.grey500, size: 20),
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
    );
  }
}
