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

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SignupProvider>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(backgroundColor: AppThemeData.surface),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: SingleChildScrollView(
                child: Column(
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
                    const SizedBox(height: 32),
                    // First & Last Name
                    Row(
                      children: [
                        Expanded(
                          child: TextFieldWidget(
                            title: 'First Name'.tr,
                            controller: controller.firstNameEditingController,
                            hintText: 'Enter First Name'.tr,
                            prefix: Padding(
                              padding: const EdgeInsets.all(12),
                              child: SvgPicture.asset(
                                "assets/icons/ic_user.svg",
                                colorFilter: ColorFilter.mode(
                                  AppThemeData.grey600,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFieldWidget(
                            title: 'Last Name'.tr,
                            controller: controller.lastNameEditingController,
                            hintText: 'Enter Last Name'.tr,
                            prefix: Padding(
                              padding: const EdgeInsets.all(12),
                              child: SvgPicture.asset(
                                "assets/icons/ic_user.svg",
                                colorFilter: ColorFilter.mode(
                                  AppThemeData.grey600,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Email
                    TextFieldWidget(
                      title: 'Email Address'.tr,
                      textInputType: TextInputType.emailAddress,
                      controller: controller.emailEditingController,
                      enable:
                          controller.type == "google" ||
                              controller.type == "apple"
                          ? false
                          : true,
                      hintText: 'Enter Email Address'.tr,
                      prefix: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.asset(
                          "assets/icons/ic_mail.svg",
                          colorFilter: ColorFilter.mode(
                            AppThemeData.grey600,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFieldWidget(
                      readOnly: true,
                      title: 'Phone Number'.tr,
                      controller: controller.phoneNUmberEditingController,
                      hintText: 'Enter Phone Number'.tr,
                      enable: controller.type == "mobileNumber" ? false : true,
                      textInputType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9]')),
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
                    ),
                    const SizedBox(height: 16),
                    Consumer<SplashProvider>(
                      builder: (context, splashProvider, _) {
                        return RoundedButtonFill(
                          title: "Signup".tr,
                          color: AppThemeData.primary300,
                          textColor: AppThemeData.grey50,
                          onPress: () async {
                            if (controller.firstNameEditingController.value.text
                                .trim()
                                .isEmpty) {
                              ShowToastDialog.showToast(
                                "Please enter first name".tr,
                              );
                            } else if (controller
                                .lastNameEditingController
                                .value
                                .text
                                .trim()
                                .isEmpty) {
                              ShowToastDialog.showToast(
                                "Please enter last name".tr,
                              );
                            } else if (controller
                                .emailEditingController
                                .value
                                .text
                                .trim()
                                .isEmpty) {
                              ShowToastDialog.showToast(
                                "Please enter valid email".tr,
                              );
                            } else if (controller
                                .phoneNUmberEditingController
                                .value
                                .text
                                .trim()
                                .isEmpty) {
                              ShowToastDialog.showToast(
                                "Please enter Phone number".tr,
                              );
                            } else {
                              controller.signUpWithEmailAndPassword(
                                context,
                                splashProvider,
                              );
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
