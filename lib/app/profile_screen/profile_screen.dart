import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/app/auth_screen/provider/login_provider.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart'
    show CartControllerProvider;
import 'package:jippymart_customer/app/change%20langauge/change_language_screen.dart';
import 'package:jippymart_customer/app/chat_screens/driver_inbox_screen.dart';
import 'package:jippymart_customer/app/chat_screens/restaurant_inbox_screen.dart';
import 'package:jippymart_customer/app/edit_profile_screen/edit_profile_screen.dart';
import 'package:jippymart_customer/app/profile_screen/provider/my_profile_provider.dart';
import 'package:jippymart_customer/app/terms_and_condition/terms_and_condition_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/services/database_helper.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/custom_dialog_box.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../edit_profile_screen/provider/edit_profile_provider.dart'
    show EditProfileProvider;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeData.surface,
      body: Consumer<MyProfileProvider>(
        builder: (context, controller, _) {
          return controller.isLoading.value
              ? Constant.loader(message: "Loading profile...".tr)
              : Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).viewPadding.top,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "My Profile".tr,
                            style: TextStyle(
                              fontSize: 24,
                              color: AppThemeData.grey900,
                              fontFamily: AppThemeData.semiBold,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "Manage your personal information, preferences, and settings all in one place."
                                .tr,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppThemeData.grey900,
                              fontFamily: AppThemeData.regular,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "General Information".tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppThemeData.grey500,
                              fontFamily: AppThemeData.semiBold,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: Responsive.width(100, context),
                            decoration: ShapeDecoration(
                              color: AppThemeData.grey50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: Column(
                                children: [
                                  Constant.userModel == null
                                      ? const SizedBox()
                                      : cardDecoration(
                                          controller,
                                          "assets/images/ic_profile.svg",
                                          "Profile Information".tr,
                                          () {
                                            Get.to(const EditProfileScreen());
                                          },
                                        ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          const SizedBox(height: 10),
                          Text(
                            "Preferences".tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppThemeData.grey500,
                              fontFamily: AppThemeData.semiBold,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: Responsive.width(100, context),
                            decoration: ShapeDecoration(
                              color: AppThemeData.grey50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: Column(
                                children: [
                                  cardDecoration(
                                    controller,
                                    "assets/icons/ic_change_language.svg",
                                    "Change Language".tr,
                                    () {
                                      Get.to(const ChangeLanguageScreen());
                                    },
                                  ),
                                  // cardDecoration(themeChange, controller, "assets/icons/ic_light_dark.svg", "Dark Mode".tr, () {}),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Social".tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppThemeData.grey500,
                              fontFamily: AppThemeData.semiBold,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: Responsive.width(100, context),
                            decoration: ShapeDecoration(
                              color: AppThemeData.grey50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: Column(
                                children: [
                                  Constant.userModel == null
                                      ? const SizedBox()
                                      // : cardDecoration(themeChange, controller, "assets/icons/ic_refer.svg", "Refer a Friend", () {
                                      //     Get.to(const ReferFriendScreen());
                                      //   }),
                                      : cardDecoration(
                                          controller,
                                          "assets/icons/ic_share.svg",
                                          "Share app",
                                          () {
                                            SharePlus.instance.share(
                                              ShareParams(
                                                text:
                                                    'Hey! Just downloaded JippyMart and loving it!\nYou should try it too - get Rs.100 off on your first order!\nDon\'t miss out on this deal!\n\nGoogle Play: ${Constant.googlePlayLink}\nApp Store: ${Constant.appStoreLink}',
                                                subject: 'Look what I made!',
                                              ),
                                            );
                                          },
                                        ),
                                  cardDecoration(
                                    controller,
                                    "assets/icons/ic_rate.svg",
                                    "Rate the app",
                                    () {
                                      final InAppReview inAppReview =
                                          InAppReview.instance;
                                      inAppReview.requestReview();
                                    },
                                  ),
                                  // Test button for GIF generation (remove in production)
                                  // cardDecoration(themeChange, controller, "assets/icons/ic_gift.svg", "Test GIF Generator", () {
                                  //   Get.to(() => const FaceInCloTestScreen());
                                  // }),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Constant.userModel == null
                              ? const SizedBox()
                              : Visibility(
                                  visible: false,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Communication".tr,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppThemeData.grey500,
                                          fontFamily: AppThemeData.semiBold,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        width: Responsive.width(100, context),
                                        decoration: ShapeDecoration(
                                          color: AppThemeData.grey50,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          child: Column(
                                            children: [
                                              cardDecoration(
                                                controller,
                                                "assets/icons/ic_restaurant_chat.svg",
                                                "Restaurant Inbox",
                                                () async {
                                                  final userId =
                                                      await SqlStorageConst.getFirebaseId();
                                                  Get.to(
                                                    RestaurantInboxScreen(
                                                      userId: userId,
                                                    ),
                                                  );
                                                },
                                              ),
                                              cardDecoration(
                                                controller,
                                                "assets/icons/ic_restaurant_driver.svg",
                                                "Driver Inbox",
                                                () async {
                                                  final userId =
                                                      await SqlStorageConst.getFirebaseId();
                                                  Get.to(
                                                    DriverInboxScreen(
                                                      userId: userId.toString(),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                          Text(
                            "Legal".tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppThemeData.grey500,
                              fontFamily: AppThemeData.semiBold,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: Responsive.width(100, context),
                            decoration: ShapeDecoration(
                              color: AppThemeData.grey50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: Column(
                                children: [
                                  cardDecoration(
                                    controller,
                                    "assets/icons/ic_privacy_policy.svg",
                                    "Privacy Policy",
                                    () {
                                      Get.to(
                                        const TermsAndConditionScreen(
                                          type: "privacy",
                                        ),
                                      );
                                    },
                                  ),
                                  cardDecoration(
                                    controller,
                                    "assets/icons/ic_tearm_condition.svg",
                                    "Terms and Conditions",
                                    () {
                                      Get.to(
                                        const TermsAndConditionScreen(
                                          type: "termAndCondition",
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const SizedBox(height: 10),
                          Consumer<LoginProvider>(
                            builder: (context, loginProvider, _) {
                              return Container(
                                width: Responsive.width(100, context),
                                decoration: ShapeDecoration(
                                  color: AppThemeData.grey50,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  child: Column(
                                    children: [
                                      Constant.userModel == null
                                          ? cardDecoration(
                                              controller,
                                              "assets/icons/ic_logout.svg",
                                              "Log In",
                                              () {
                                                Get.offAll(
                                                  const PhoneNumberScreen(),
                                                );
                                              },
                                            )
                                          : cardDecoration(
                                              controller,
                                              "assets/icons/ic_logout.svg",
                                              "Log out",
                                              () {
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return CustomDialogBox(
                                                      title: "Log out".tr,
                                                      descriptions:
                                                          "Are you sure you want to log out? You will need to enter your credentials to log back in."
                                                              .tr,
                                                      positiveString:
                                                          "Log out".tr,
                                                      negativeString:
                                                          "Cancel".tr,
                                                      positiveClick: () async {
                                                        Constant
                                                                .userModel!
                                                                .fcmToken =
                                                            "";
                                                        await EditProfileProvider.updateUser(
                                                          Constant.userModel!,
                                                        );
                                                        Constant.userModel =
                                                            null;
                                                        FireStoreUtils
                                                                .backendUserId =
                                                            null;
                                                        // Clear auth token if used
                                                        try {
                                                          loginProvider
                                                                  .authToken =
                                                              '';
                                                        } catch (_) {}
                                                        // Clear preferences (or use your Preferences.clear() if available)
                                                        await Preferences.clearSharPreference();
                                                        // Delete API token from secure storage
                                                        final FlutterSecureStorage
                                                        secureStorage =
                                                            const FlutterSecureStorage();
                                                        await secureStorage
                                                            .delete(
                                                              key: 'api_token',
                                                            );
                                                        // Clear cart data before logout
                                                        print(
                                                          'DEBUG: Profile logout - Starting cart clearing process',
                                                        );
                                                        try {
                                                          // Force clear cart from database directly
                                                          await DatabaseHelper
                                                              .instance
                                                              .deleteAllCartProducts();

                                                          // Also try to clear via CartController if available
                                                          CartControllerProvider
                                                          cartControllerProvider =
                                                              Provider.of<
                                                                CartControllerProvider
                                                              >(
                                                                context,
                                                                listen: false,
                                                              );
                                                          print(
                                                            'DEBUG: Profile logout - CartController found, clearing cart',
                                                          );
                                                          await cartControllerProvider
                                                              .clearCart();
                                                        } catch (e) {
                                                          print(
                                                            'DEBUG: Profile logout - Error clearing cart: $e',
                                                          );
                                                        }
                                                        Get.deleteAll(
                                                          force: true,
                                                        );
                                                        Get.offAll(
                                                          const PhoneNumberScreen(),
                                                        );
                                                      },
                                                      negativeClick: () {
                                                        Get.back();
                                                      },
                                                      img: Image.asset(
                                                        'assets/images/ic_logout.gif',
                                                        height: 50,
                                                        width: 50,
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          Constant.userModel == null
                              ? const SizedBox()
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return CustomDialogBox(
                                            title: "Delete Account".tr,
                                            descriptions:
                                                "Are you sure you want to delete your account? This action is irreversible and will permanently remove all your data."
                                                    .tr,
                                            positiveString: "Delete".tr,
                                            negativeString: "Cancel".tr,
                                            positiveClick: () async {
                                              ShowToastDialog.showLoader(
                                                "Please wait".tr,
                                              );
                                              // Clear cart data before account deletion
                                              try {
                                                CartControllerProvider
                                                cartControllerProvider =
                                                    Provider.of<
                                                      CartControllerProvider
                                                    >(context, listen: false);
                                                await cartControllerProvider
                                                    .clearCart();
                                              } catch (_) {}
                                            },
                                            negativeClick: () {
                                              Get.back();
                                            },
                                            img: Image.asset(
                                              'assets/icons/delete_dialog.gif',
                                              height: 50,
                                              width: 50,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          "assets/icons/ic_delete.svg",
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          "Delete Account".tr,
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontFamily: AppThemeData.medium,
                                            fontSize: 16,
                                            color: AppThemeData.danger300,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          Center(
                            child: Text(
                              "V : ${Constant.appVersion}",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                fontSize: 14,
                                color: AppThemeData.grey900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
        },
      ),
    );
  }

  cardDecoration(
    MyProfileProvider controller,
    String image,
    String title,
    Function()? onPress,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          onPress!();
        },
        child: Row(
          children: [
            SvgPicture.asset(
              image,
              colorFilter: title == "Log In"
                  ? const ColorFilter.mode(
                      AppThemeData.success500,
                      BlendMode.srcIn,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title.tr,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  fontSize: 16,
                  color: title == "Log out"
                      ? AppThemeData.danger300
                      : title == "Log In"
                      ? AppThemeData.success500
                      : AppThemeData.grey800,
                ),
              ),
            ),
            title == "Dark Mode"
                ? Transform.scale(
                    scale: 0.8,
                    child: CupertinoSwitch(
                      value: controller.isDarkModeSwitch.value,
                      activeColor: AppThemeData.primary300,
                      onChanged: (value) {
                        controller.isDarkModeSwitch.value = value;
                        if (controller.isDarkModeSwitch.value == true) {
                          Preferences.setString(Preferences.themKey, "Dark");
                        } else if (controller.isDarkMode.value == "Light") {
                          Preferences.setString(Preferences.themKey, "Light");
                        } else {
                          Preferences.setString(Preferences.themKey, "");
                        }
                      },
                    ),
                  )
                : const Icon(Icons.keyboard_arrow_right),
          ],
        ),
      ),
    );
  }
}
