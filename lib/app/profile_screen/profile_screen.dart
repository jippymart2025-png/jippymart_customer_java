import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/app/auth_screen/provider/login_provider.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart'
    show CartControllerProvider;
import 'package:jippymart_customer/app/edit_profile_screen/edit_profile_screen.dart';
import 'package:jippymart_customer/app/profile_screen/provider/my_profile_provider.dart';
import 'package:jippymart_customer/app/profile_screen/widget/buildSliverHeader.dart';
import 'package:jippymart_customer/app/terms_and_condition/terms_and_condition_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/services/database_helper.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/custom_dialog_box.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../edit_profile_screen/provider/edit_profile_provider.dart'
    show EditProfileProvider;
import '../favourite_screens/favourite_screen.dart';
import '../favourite_screens/provider/favorite_provider.dart';
import '../wallet_screen/wallet_home_screen.dart';
import '../wallet_screen/provider/wallet_provider.dart';

final InAppReview inAppReview = InAppReview.instance;

Future rateApp() async {
  try {
    String? storeUrl;
    if (Platform.isIOS) {
      storeUrl = Constant.appStoreLink.isNotEmpty
          ? Constant.appStoreLink
          : 'https://apps.apple.com/in/app/jippy-mart/id6755069616';
    } else if (Platform.isAndroid) {
      storeUrl = Constant.googlePlayLink.isNotEmpty
          ? Constant.googlePlayLink
          : 'https://play.google.com/store/apps/details?id=com.jippymart.customer';
    }

    if (storeUrl != null && storeUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(storeUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        debugPrint('[RATE_APP] Error launching URL: $e');
      }
    }

    try {
      await inAppReview.openStoreListing();
    } catch (e) {
      try {
        if (await inAppReview.isAvailable()) {
          await inAppReview.requestReview();
        }
      } catch (e2) {
        debugPrint('[RATE_APP] All methods failed: $e2');
      }
    }
  } catch (e) {
    try {
      await inAppReview.openStoreListing();
    } catch (_) {}
  }
}

// ─── Zomato Brand Colors ──────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final controller = Provider.of<MyProfileProvider>(
          context,
          listen: false,
        );
        if (controller.isLoading.value) {
          controller.initFunction(context: context);
        }
        if (Constant.userModel != null) {
          context.read<WalletProvider>().refreshWallet();
        }
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZColors.surface,
      body: Consumer<MyProfileProvider>(
        builder: (context, controller, _) {
          if (controller.isLoading.value) {
            return _buildLoadingState();
          }
          return FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: CustomScrollView(
                slivers: [
                  buildSliverHeader(controller, context),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // ── Account Section ──
                          _sectionLabel('Account'),
                          const SizedBox(height: 10),
                          _buildCard([
                            _menuTile(
                              icon: Icons.person_outline_rounded,
                              label: 'Profile Information',
                              onTap: () {
                                if (!controller.isUserLoggedIn &&
                                    Constant.userModel == null) {
                                  _showLoginDialog(context);
                                  return;
                                }
                                context
                                    .read<EditProfileProvider>()
                                    .initFunction();
                                Get.to(() => const EditProfileScreen());
                              },
                            ),
                            _divider(),
                            _menuTile(
                              icon: Icons.favorite_border_rounded,
                              label: 'Favourites',
                              iconColor: ZColors.primary,
                              onTap: () {
                                if (!controller.isUserLoggedIn &&
                                    Constant.userModel == null) {
                                  _showLoginDialog(context);
                                  return;
                                }
                                Get.to(() => const FavouriteScreen());
                                context.read<FavouriteProvider>().refreshData();
                              },
                            ),
                            _divider(),
                            _menuTile(
                              icon: Icons.account_balance_wallet_outlined,
                              label: 'Wallet',
                              trailing: Consumer<WalletProvider>(
                                builder: (_, wp, __) =>
                                    _walletBadge(controller, wp),
                              ),
                              onTap: () {
                                if (!controller.isUserLoggedIn &&
                                    Constant.userModel == null) {
                                  _showLoginDialog(context);
                                  return;
                                }
                                Get.to(() => const WalletHomeScreen());
                              },
                            ),
                          ]),

                          const SizedBox(height: 24),

                          // ── App Section ──
                          _sectionLabel('More'),
                          const SizedBox(height: 10),
                          _buildCard([
                            if (Constant.userModel != null)
                              _menuTile(
                                icon: Icons.share_outlined,
                                label: 'Share App',
                                onTap: () {
                                  final playStoreUrl =
                                      Constant.googlePlayLink.isNotEmpty
                                      ? Constant.googlePlayLink
                                      : 'https://play.google.com/store/apps/details?id=com.jippymart.customer';
                                  final appStoreUrl =
                                      Constant.appStoreLink.isNotEmpty
                                      ? Constant.appStoreLink
                                      : 'https://apps.apple.com/in/app/jippy-mart/id6755069616';
                                  SharePlus.instance.share(
                                    ShareParams(
                                      text:
                                          'Hey! Just downloaded JippyMart and loving it!\nYou should try it too - get Rs.100 off on your first order!\n\nGoogle Play: $playStoreUrl\nApp Store: $appStoreUrl',
                                      subject: 'Check out JippyMart!',
                                    ),
                                  );
                                },
                              ),
                            if (Constant.userModel != null) _divider(),
                            _menuTile(
                              icon: Icons.star_border_rounded,
                              label: 'Rate the App',
                              iconColor: ZColors.amberAccent,
                              onTap: () async => await rateApp(),
                            ),
                          ]),

                          const SizedBox(height: 24),

                          // ── Legal Section ──
                          _sectionLabel('Legal'),
                          const SizedBox(height: 10),
                          _buildCard([
                            _menuTile(
                              icon: Icons.shield_outlined,
                              label: 'Privacy Policy',
                              onTap: () => Get.to(
                                () => const TermsAndConditionScreen(
                                  type: 'privacy',
                                ),
                              ),
                            ),
                            _divider(),
                            _menuTile(
                              icon: Icons.description_outlined,
                              label: 'Terms and Conditions',
                              onTap: () => Get.to(
                                () => const TermsAndConditionScreen(
                                  type: 'termAndCondition',
                                ),
                              ),
                            ),
                          ]),

                          const SizedBox(height: 24),

                          // ── Login / Logout ──
                          Consumer<LoginProvider>(
                            builder: (context, loginProvider, _) {
                              return _buildCard([
                                Constant.userModel == null
                                    ? _menuTile(
                                        icon: Icons.login_rounded,
                                        label: 'Log In',
                                        iconColor: ZColors.greenAccent,
                                        labelColor: ZColors.greenAccent,
                                        showArrow: false,
                                        onTap: () => Get.offAll(
                                          () => PhoneNumberScreen(),
                                        ),
                                      )
                                    : _menuTile(
                                        icon: Icons.logout_rounded,
                                        label: 'Log Out',
                                        iconColor: ZColors.primary,
                                        labelColor: ZColors.primary,
                                        showArrow: false,
                                        onTap: () => _confirmLogout(
                                          context,
                                          controller,
                                          loginProvider,
                                        ),
                                      ),
                              ]);
                            },
                          ),

                          // ── Delete Account ──
                          if (Constant.userModel != null) ...[
                            const SizedBox(height: 12),
                            _buildDeleteAccountButton(controller),
                          ],

                          const SizedBox(height: 24),

                          // ── Version ──
                          Center(
                            child: Text(
                              controller.versionText,
                              style: const TextStyle(
                                fontSize: 12,
                                color: ZColors.textTertiary,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Sliver Header ──────────────────────────────────────────────────────────

  // ─── Loading ────────────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: ZColors.surface,
      body: Column(
        children: [
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE23744), Color(0xFFC0000F)],
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                color: ZColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Label ──────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: ZColors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ─── Card ────────────────────────────────────────────────────────────────────
  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: ZColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ─── Menu Tile ───────────────────────────────────────────────────────────────
  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? labelColor,
    Widget? trailing,
    bool showArrow = true,
  }) {
    final ic = iconColor ?? const Color(0xFF555555);
    final lc = labelColor ?? ZColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: ZColors.primaryLight,
        highlightColor: ZColors.primaryLight.withOpacity(0.4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ic == ZColors.primary
                      ? ZColors.primaryLight
                      : ic == ZColors.amberAccent
                      ? const Color(0xFFFFF8EC)
                      : ic == ZColors.greenAccent
                      ? const Color(0xFFEEFBF1)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: ic, size: 19),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label.tr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: lc,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              trailing ??
                  (showArrow
                      ? const Icon(
                          Icons.chevron_right_rounded,
                          color: ZColors.textTertiary,
                          size: 20,
                        )
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.only(left: 66),
      child: Divider(height: 1, color: ZColors.divider),
    );
  }

  Widget _walletBadge(MyProfileProvider controller, WalletProvider wp) {
    // Use same source as wallet screen (WalletProvider.moneyBalanceRupees) so balance matches
    final amount = wp.moneyBalanceRupees;
    final value = Constant.amountShow(amount: amount.toStringAsFixed(2));
    final hasBalance = amount > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.account_balance_wallet_rounded,
          color: hasBalance ? ZColors.greenAccent : ZColors.textTertiary,
          size: 14,
        ),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            color: hasBalance ? ZColors.greenAccent : ZColors.textTertiary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.chevron_right_rounded,
          color: ZColors.textTertiary,
          size: 20,
        ),
      ],
    );
  }

  // ─── Delete Account Button ──────────────────────────────────────────────────
  Widget _buildDeleteAccountButton(MyProfileProvider controller) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => CustomDialogBox(
            title: 'Delete Account'.tr,
            descriptions:
                'Are you sure you want to delete your account? This action is irreversible and will permanently remove all your data.'
                    .tr,
            positiveString: 'Delete'.tr,
            negativeString: 'Cancel'.tr,
            positiveClick: () async {
              try {
                controller.deleteUserAccount(context: context);
              } catch (_) {}
            },
            negativeClick: () => Get.back(),
            img: Image.asset(
              'assets/icons/delete_dialog.gif',
              height: 50,
              width: 50,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ZColors.primary.withOpacity(0.2), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: ZColors.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Delete Account'.tr,
              style: const TextStyle(
                color: ZColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────────────
  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CustomDialogBox(
        title: 'Login Required'.tr,
        descriptions:
            'Please login to access your profile information and manage your account.'
                .tr,
        positiveString: 'Login'.tr,
        negativeString: 'Cancel'.tr,
        positiveClick: () {
          Get.back();
          Get.to(() => PhoneNumberScreen());
        },
        negativeClick: () => Get.back(),
        img: Image.asset(
          'assets/images/ic_launcher.png',
          height: 50,
          width: 50,
        ),
      ),
    );
  }

  void _confirmLogout(
    BuildContext context,
    MyProfileProvider controller,
    LoginProvider loginProvider,
  ) {
    showDialog(
      context: context,
      builder: (_) => CustomDialogBox(
        title: 'Log out'.tr,
        descriptions:
            'Are you sure you want to log out? You will need to enter your credentials to log back in.'
                .tr,
        positiveString: 'Log out'.tr,
        negativeString: 'Cancel'.tr,
        positiveClick: () async {
          Constant.userModel!.fcmToken = '';
          await EditProfileProvider.updateUserStatic(Constant.userModel!);
          Constant.userModel = null;
          FireStoreUtils.backendUserId = null;
          try {
            loginProvider.authToken = '';
          } catch (_) {}
          await Preferences.clearSharPreference();
          const FlutterSecureStorage secureStorage = FlutterSecureStorage();
          await secureStorage.delete(key: 'api_token');
          try {
            await DatabaseHelper.instance.deleteAllCartProducts();
            CartControllerProvider cartControllerProvider =
                Provider.of<CartControllerProvider>(context, listen: false);
            await cartControllerProvider.clearCart();
          } catch (e) {
            if (kDebugMode) print('DEBUG: Error clearing cart: $e');
          }
          controller.clearCache();
          Get.deleteAll(force: true);
          Get.offAll(() => PhoneNumberScreen());
        },
        negativeClick: () => Get.back(),
        img: Image.asset('assets/images/ic_logout.gif', height: 50, width: 50),
      ),
    );
  }
}
