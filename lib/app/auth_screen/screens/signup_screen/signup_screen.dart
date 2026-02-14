import 'package:jippymart_customer/app/auth_screen/screens/signup_screen/provider/signup_provider.dart';
import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/themes/text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  late SignupProvider _signupProvider;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _signupProvider = Provider.of<SignupProvider>(context, listen: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppThemeData.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppThemeData.grey900),
          onPressed: () => Get.back(),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildNameFields(),
              const SizedBox(height: 16),
              _buildEmailField(),
              const SizedBox(height: 16),
              _buildPhoneField(),
              const SizedBox(height: 24),
              _buildSignupButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Create an Account 🚀".tr,
          style: TextStyle(
            color: AppThemeData.grey900,
            fontSize: 22,
            fontFamily: AppThemeData.semiBold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Sign up to start your food adventure with Foodie".tr,
          style: TextStyle(
            color: AppThemeData.grey500,
            fontSize: 16,
            fontFamily: AppThemeData.regular,
          ),
        ),
      ],
    );
  }

  Widget _buildNameFields() {
    return Row(
      children: [
        Expanded(child: _buildFirstNameField()),
        const SizedBox(width: 10),
        Expanded(child: _buildLastNameField()),
      ],
    );
  }

  Widget _buildFirstNameField() {
    return Consumer<SignupProvider>(
      builder: (context, controller, _) {
        return TextFieldWidget(
          title: 'First Name'.tr,
          controller: controller.firstNameEditingController,
          hintText: 'Enter First Name'.tr,
          prefix: _buildIcon("assets/icons/ic_user.svg"),
        );
      },
    );
  }

  Widget _buildLastNameField() {
    return Consumer<SignupProvider>(
      builder: (context, controller, _) {
        return TextFieldWidget(
          title: 'Last Name'.tr,
          controller: controller.lastNameEditingController,
          hintText: 'Enter Last Name'.tr,
          prefix: _buildIcon("assets/icons/ic_user.svg"),
        );
      },
    );
  }

  Widget _buildEmailField() {
    return Consumer<SignupProvider>(
      builder: (context, controller, _) {
        return TextFieldWidget(
          title: 'Email Address'.tr,
          textInputType: TextInputType.emailAddress,
          controller: controller.emailEditingController,
          hintText: 'Enter Email Address'.tr,
          prefix: _buildIcon("assets/icons/ic_mail.svg"),
        );
      },
    );
  }

  Widget _buildPhoneField() {
    return Consumer<SignupProvider>(
      builder: (context, controller, _) {
        return TextFieldWidget(
          readOnly: true,
          title: 'Phone Number'.tr,
          controller: controller.phoneNUmberEditingController,
          hintText: 'Enter Phone Number'.tr,
          textInputType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: true,
          ),
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          prefix: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🇮🇳 +91',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppThemeData.grey900,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignupButton(BuildContext context) {
    return Consumer2<SignupProvider, SplashProvider>(
      builder: (context, controller, splashProvider, _) {
        return RoundedButtonFill(
          title: _isProcessing ? "Creating Account..." : "Signup".tr,
          color: AppThemeData.primary300,
          textColor: AppThemeData.grey50,
          onPress: _isProcessing
              ? null
              : () => _handleSignup(context, controller, splashProvider),
        );
      },
    );
  }

  // In the _handleSignup method of SignupScreen, add more error handling:
  Future<void> _handleSignup(
    BuildContext context,
    SignupProvider controller,
    SplashProvider splashProvider,
  ) async {
    // Validate inputs
    final firstName = controller.firstNameEditingController.value.text.trim();
    final lastName = controller.lastNameEditingController.value.text.trim();
    final email = controller.emailEditingController.value.text.trim();
    final phone = controller.phoneNUmberEditingController.value.text.trim();

    print(
      '[SIGNUP_SCREEN] Validating inputs: $firstName, $lastName, $email, $phone',
    );

    if (firstName.isEmpty) {
      ShowToastDialog.showToast("Please enter first name".tr);
      return;
    }

    if (lastName.isEmpty) {
      ShowToastDialog.showToast("Please enter last name".tr);
      return;
    }

    if (email.isEmpty) {
      ShowToastDialog.showToast("Please enter email address".tr);
      return;
    }

    if (!controller.isValidEmail(email)) {
      ShowToastDialog.showToast("Invalid email format".tr);
      return;
    }

    if (phone.isEmpty) {
      ShowToastDialog.showToast("Please enter phone number".tr);
      return;
    }

    if (phone.length != 10) {
      ShowToastDialog.showToast("Phone number must be 10 digits".tr);
      return;
    }

    // Dismiss keyboard
    _dismissKeyboard();

    // Prevent multiple submissions
    if (_isProcessing) {
      print('[SIGNUP_SCREEN] Already processing, ignoring duplicate request');
      return;
    }

    setState(() => _isProcessing = true);
    print('[SIGNUP_SCREEN] Starting signup process...');

    try {
      await controller.signUpWithEmailAndPassword(context, splashProvider);
      print('[SIGNUP_SCREEN] Signup process completed');
    } catch (e) {
      print('[SIGNUP_SCREEN] Error in signup: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        print('[SIGNUP_SCREEN] Reset processing state');
      }
    }
  }

  Widget _buildIcon(String assetPath) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SvgPicture.asset(
        assetPath,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(AppThemeData.grey600, BlendMode.srcIn),
      ),
    );
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
