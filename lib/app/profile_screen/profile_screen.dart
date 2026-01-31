import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/app/auth_screen/provider/login_provider.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart'
    show CartControllerProvider;
import 'package:jippymart_customer/app/edit_profile_screen/edit_profile_screen.dart';
import 'package:jippymart_customer/app/profile_screen/provider/my_profile_provider.dart';
import 'package:jippymart_customer/app/terms_and_condition/terms_and_condition_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/services/database_helper.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/custom_dialog_box.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../edit_profile_screen/provider/edit_profile_provider.dart'
    show EditProfileProvider;
import '../favourite_screens/favourite_screen.dart';
import '../favourite_screens/provider/favorite_provider.dart';

final InAppReview inAppReview = InAppReview.instance;

void rateApp() async {
  if (await inAppReview.isAvailable()) {
    inAppReview.requestReview();
  } else {
    inAppReview.openStoreListing(); // fallback
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the provider after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final controller = Provider.of<MyProfileProvider>(
          context,
          listen: false,
        );
        // Only initialize if still loading (not already initialized)
        if (controller.isLoading.value) {
          controller.initFunction(context: context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeData.surface,
      body: Consumer<MyProfileProvider>(
        builder: (context, controller, _) {
          return controller.isLoading.value
              ? Constant.loader(message: "Loading profile...".tr)
              : Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: Responsive.getMaxContentWidth(context),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).viewPadding.top,
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: Responsive.getScreenPadding(
                              context,
                            ).horizontal,
                            right: Responsive.getScreenPadding(
                              context,
                            ).horizontal,
                            bottom: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "My Profile".tr,
                                style: TextStyle(
                                  fontSize: Responsive.getFontSize(context, 24),
                                  color: AppThemeData.grey900,
                                  fontFamily: AppThemeData.semiBold,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "Manage your personal information, preferences, and settings all in one place."
                                    .tr,
                                style: TextStyle(
                                  fontSize: Responsive.getFontSize(context, 16),
                                  color: AppThemeData.grey900,
                                  fontFamily: AppThemeData.regular,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              SizedBox(
                                height: Responsive.getSpacing(
                                  context,
                                  baseSpacing: 20,
                                ),
                              ),
                              Text(
                                "General Information".tr,
                                style: TextStyle(
                                  fontSize: Responsive.getFontSize(context, 12),
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
                                  child: Consumer<EditProfileProvider>(
                                    builder: (context, editProfileProvider, _) {
                                      return Column(
                                        children: [
                                          cardDecoration(
                                            controller,
                                            "assets/images/ic_profile.svg",
                                            "Profile Information".tr,
                                            () {
                                              // Use cached login state (no async call needed)
                                              if (!controller.isUserLoggedIn &&
                                                  Constant.userModel == null) {
                                                _showLoginRequiredDialog(
                                                  context,
                                                );
                                                return;
                                              }
                                              editProfileProvider
                                                  .initFunction();
                                              Get.to(
                                                () => const EditProfileScreen(),
                                              );
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  ),
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
                                        "assets/images/ic_favourite.svg",
                                        "Favorites".tr,
                                        () {
                                          // Use cached login state (no async call needed)
                                          if (!controller.isUserLoggedIn &&
                                              Constant.userModel == null) {
                                            _showLoginRequiredDialog(context);
                                            return;
                                          }

                                          // Navigate first for faster perceived performance
                                          // FavouriteScreen will load data on init
                                          Get.to(() => const FavouriteScreen());
                                          // Trigger refresh in background
                                          context
                                              .read<FavouriteProvider>()
                                              .refreshData();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Text(
                              //   "Preferences".tr,
                              //   style: TextStyle(
                              //     fontSize: 12,
                              //     color: AppThemeData.grey500,
                              //     fontFamily: AppThemeData.semiBold,
                              //     fontWeight: FontWeight.w500,
                              //   ),
                              // ),
                              // const SizedBox(height: 10),
                              // Container(
                              //   width: Responsive.width(100, context),
                              //   decoration: ShapeDecoration(
                              //     color: AppThemeData.grey50,
                              //     shape: RoundedRectangleBorder(
                              //       borderRadius: BorderRadius.circular(8),
                              //     ),
                              //   ),
                              //   child: Padding(
                              //     padding: const EdgeInsets.symmetric(
                              //       horizontal: 10,
                              //       vertical: 8,
                              //     ),
                              //     child: Column(
                              //       children: [
                              //         cardDecoration(
                              //           controller,
                              //           "assets/icons/ic_change_language.svg",
                              //           "Change Language".tr,
                              //           () {
                              //             Get.to(const ChangeLanguageScreen());
                              //           },
                              //         ),
                              //       ],
                              //     ),
                              //   ),
                              // ),
                              Text(
                                "Social".tr,
                                style: TextStyle(
                                  fontSize: Responsive.getFontSize(context, 12),
                                  color: AppThemeData.grey500,
                                  fontFamily: AppThemeData.semiBold,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                decoration: ShapeDecoration(
                                  color: AppThemeData.grey50,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Responsive.getHorizontalSpacing(
                                      context,
                                      baseSpacing: 10,
                                    ),
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    children: [
                                      Constant.userModel == null
                                          ? const SizedBox()
                                          : cardDecoration(
                                              controller,
                                              "assets/icons/ic_share.svg",
                                              "Share app",
                                              () {
                                                SharePlus.instance.share(
                                                  ShareParams(
                                                    text:
                                                        'Hey! Just downloaded JippyMart and loving it!\nYou should try it too - get Rs.100 off on your first order!\nDon\'t miss out on this deal!\n\nGoogle Play: ${Constant.googlePlayLink}\nApp Store: ${Constant.appStoreLink}',
                                                    subject:
                                                        'Look what I made!',
                                                  ),
                                                );
                                              },
                                            ),
                                      cardDecoration(
                                        controller,
                                        "assets/icons/ic_rate.svg",
                                        "Rate the app",
                                        () async {
                                          final inAppReview =
                                              InAppReview.instance;
                                          if (await inAppReview.isAvailable()) {
                                            await inAppReview.requestReview();
                                          } else {
                                            await inAppReview
                                                .openStoreListing();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Legal".tr,
                                style: TextStyle(
                                  fontSize: Responsive.getFontSize(context, 12),
                                  color: AppThemeData.grey500,
                                  fontFamily: AppThemeData.semiBold,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                decoration: ShapeDecoration(
                                  color: AppThemeData.grey50,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: Responsive.getHorizontalSpacing(
                                      context,
                                      baseSpacing: 10,
                                    ),
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
                                            () => const TermsAndConditionScreen(
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
                                            () => const TermsAndConditionScreen(
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
                              Consumer<LoginProvider>(
                                builder: (context, loginProvider, _) {
                                  return Container(
                                    width: double.infinity,
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
                                                      () => PhoneNumberScreen(),
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
                                                            await EditProfileProvider.updateUserStatic(
                                                              Constant
                                                                  .userModel!,
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
                                                                  key:
                                                                      'api_token',
                                                                );
                                                            // Clear cart data before logout
                                                            if (kDebugMode) {
                                                              print(
                                                                'DEBUG: Profile logout - Starting cart clearing process',
                                                              );
                                                            }
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
                                                                    listen:
                                                                        false,
                                                                  );
                                                              if (kDebugMode) {
                                                                print(
                                                                  'DEBUG: Profile logout - CartController found, clearing cart',
                                                                );
                                                              }
                                                              await cartControllerProvider
                                                                  .clearCart();
                                                            } catch (e) {
                                                              if (kDebugMode) {
                                                                print(
                                                                  'DEBUG: Profile logout - Error clearing cart: $e',
                                                                );
                                                              }
                                                            }
                                                            // Clear provider cache
                                                            controller
                                                                .clearCache();
                                                            Get.deleteAll(
                                                              force: true,
                                                            );
                                                            Get.offAll(
                                                              () =>
                                                                  PhoneNumberScreen(),
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
                                                  try {
                                                    controller
                                                        .deleteUserAccount(
                                                          context: context,
                                                        );
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
                              // Use cached version text from provider (avoids API call on every rebuild)
                              Center(
                                child: Text(
                                  controller.versionText,
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
                    ),
                  ),
                );
        },
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialogBox(
          title: "Login Required".tr,
          descriptions:
              "Please login to access your profile information and manage your account."
                  .tr,
          positiveString: "Login".tr,
          negativeString: "Cancel".tr,
          positiveClick: () {
            Get.back(); // Close dialog
            Get.to(() => PhoneNumberScreen());
          },
          negativeClick: () {
            Get.back(); // Close dialog
          },
          img: Image.asset(
            'assets/images/ic_launcher.png',
            height: 50,
            width: 50,
          ),
        );
      },
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
            SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.asset(
                image,
                width: 24,
                height: 24,
                colorFilter: title == "Log In"
                    ? const ColorFilter.mode(
                        AppThemeData.success500,
                        BlendMode.srcIn,
                      )
                    : null,
              ),
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
            if (title == "Dark Mode")
              Transform.scale(
                scale: 0.8,
                child: CupertinoSwitch(
                  value: controller.isDarkModeSwitch,
                  activeColor: AppThemeData.primary300,
                  onChanged: (value) {
                    controller.isDarkModeSwitch = value;
                    if (controller.isDarkModeSwitch == true) {
                      Preferences.setString(Preferences.themKey, "Dark");
                    } else if (controller.isDarkMode == "Light") {
                      Preferences.setString(Preferences.themKey, "Light");
                    } else {
                      Preferences.setString(Preferences.themKey, "");
                    }
                  },
                ),
              )
            else
              const Icon(Icons.keyboard_arrow_right),
          ],
        ),
      ),
    );
  }
}
