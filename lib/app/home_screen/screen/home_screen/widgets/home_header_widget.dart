import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/address_screens/address_list_screen.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/profile_screen/profile_screen.dart';
import 'package:jippymart_customer/app/profile_screen/provider/my_profile_provider.dart';
import 'package:jippymart_customer/app/wallet_screen/provider/wallet_provider.dart';
import 'package:jippymart_customer/app/wallet_screen/wallet_home_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/widget/initials_avatar.dart';
import 'package:jippymart_customer/app/swiggy_search_screen/provider/swiggy_search_provider.dart';
import 'package:jippymart_customer/app/swiggy_search_screen/swiggy_search_screen.dart';
import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
import 'package:jippymart_customer/app/mart/screens/mart_navigation_screen/provider/mart_navigation_provider.dart';
import 'package:jippymart_customer/app/mart/screens/mart_navigation_screen/mart_navigation_screen.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/utils/mart_zone_utils.dart';
import 'package:jippymart_customer/widgets/coming_soon_dialog.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';

/// Reference-style home header: location (pin + name + address), profile, wallet, optional FOOD|MART bar, search.
class HomeHeaderWidget extends StatefulWidget {
  const HomeHeaderWidget({
    super.key,
    required this.homeProvider,
    required this.context,
  });

  final HomeProvider homeProvider;
  final BuildContext context;

  @override
  State<HomeHeaderWidget> createState() => _HomeHeaderWidgetState();
}

class _HomeHeaderWidgetState extends State<HomeHeaderWidget> {
  bool? _martAvailableInZone;
  bool _walletRefreshScheduled = false;

  @override
  void initState() {
    super.initState();
    _checkMart();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_walletRefreshScheduled && Constant.userModel != null) {
      _walletRefreshScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<WalletProvider>().refreshWallet();
      });
    }
  }

  Future<void> _checkMart() async {
    MartZoneUtils.prefetchMartVendors();
    final available = await MartZoneUtils.isMartAvailableInCurrentZone();
    if (mounted) setState(() => _martAvailableInZone = available);
  }

  static bool _isMartChecking = false;

  Future<void> _onMartTap() async {
    if (_isMartChecking) return;
    _isMartChecking = true;
    final martProvider = context.read<MartProvider>();
    final martNav = context.read<MartNavigationProvider>();
    final location = Constant.selectedLocation.location;
    final zoneId = Constant.selectedZone?.id;
    if (location?.latitude == null ||
        location?.longitude == null ||
        location!.latitude == 0.0 ||
        location.longitude == 0.0) {
      ComingSoonDialogHelper.show(
        title: "LOCATION REQUIRED".tr,
        message:
            "Please set your location to check mart availability in your area.",
      );
      _isMartChecking = false;
      return;
    }
    if (zoneId == null || zoneId.isEmpty) {
      ComingSoonDialogHelper.show(
        title: "COMING SOON".tr,
        message:
            "We're working hard to bring Jippy Mart to your area. Stay tuned!",
      );
      _isMartChecking = false;
      return;
    }
    bool loaderShown = false;
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_isMartChecking && !loaderShown) {
        loaderShown = true;
        ShowToastDialog.showLoader("Checking mart availability...".tr);
      }
    });
    try {
      final isMartAvailable =
          await MartZoneUtils.isMartAvailableInCurrentZone();
      if (loaderShown) ShowToastDialog.closeLoader();
      if (!isMartAvailable) {
        ComingSoonDialogHelper.show(
          title: "COMING SOON".tr,
          message:
              "We're working hard to bring Jippy Mart to your area. Stay tuned!",
        );
        _isMartChecking = false;
        return;
      }
      martNav.initFunction(context: context);
      Get.to(() => const MartNavigationScreen());
      martProvider.initFunction();
    } catch (_) {
      if (loaderShown) ShowToastDialog.closeLoader();
    } finally {
      ShowToastDialog.closeLoader();
      _isMartChecking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // [UI] Layered glow overlay on top of hero gradient.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.16),
            Colors.white.withOpacity(0.07),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).viewPadding.top + 6,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row: Location (left) | Profile + Wallet (right)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => _onLocationTap(),
                      borderRadius: BorderRadius.circular(16),
                      splashColor: Colors.white.withOpacity(0.12),
                      highlightColor: Colors.white.withOpacity(0.08),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.11),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.22),
                            width: 0.9,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.24),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _locationTitle(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: AppThemeData.semiBold,
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                        height: 1.15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Delivering to address".tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: AppThemeData.medium,
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.82),
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 21,
                                color: Colors.white.withOpacity(0.92),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _profileButton(),
                const SizedBox(width: 8),
                _walletButton(),
              ],
            ),
            // FOOD | MART bar only when mart available
            if (_martAvailableInZone == true) ...[
              const SizedBox(height: 12),
              _buildFoodMartBar(),
            ],
            const SizedBox(height: 12),
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  String _locationTitle() {
    final loc = Constant.selectedLocation;
    if (loc.locality != null && loc.locality!.trim().isNotEmpty) {
      return loc.locality!.trim();
    }
    if (loc.addressAs != null && loc.addressAs!.trim().isNotEmpty) {
      return loc.addressAs!.trim();
    }
    final full = loc.getFullAddress();
    if (full.length > 25) return '${full.substring(0, 25)}...';
    return full.isEmpty ? "Delivery location".tr : full;
  }

  void _onLocationTap() {
    if (Constant.userModel != null) {
      context.read<AddressListProvider>().initFunction(context: context);
      Get.to(const AddressListScreen())?.then((value) {
        if (value != null) {
          widget.homeProvider.changeLocationAddressFunction(
            addressModel: value,
            context: context,
          );
        }
      });
    } else {
      Constant.checkPermission(
        context: context,
        onTap: () => Get.offAll(() => PhoneNumberScreen()),
      );
    }
  }

  Widget _profileButton() {
    final user = Constant.userModel;
    return InkWell(
      onTap: () {
        context.read<MyProfileProvider>().initFunction(context: context);
        Get.to(const ProfileScreen());
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 42,
        height: 42,
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.22), width: 0.9),
        ),
        child: _buildProfileAvatar(),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final user = Constant.userModel;
    if (user == null) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppThemeData.grey300,
        child: Icon(Icons.person, color: AppThemeData.grey600, size: 22),
      );
    }
    final hasImage =
        user.profilePictureURL != null &&
        user.profilePictureURL!.isNotEmpty &&
        user.profilePictureURL!.toLowerCase() != 'null';
    if (hasImage) {
      return ClipOval(
        child: SizedBox(
          width: 40,
          height: 40,
          child: NetworkImageWidget(
            imageUrl: user.profilePictureURL!,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return InitialsAvatar(
      firstName: user.firstName,
      lastName: user.lastName,
      radius: 20,
      backgroundColor: AppThemeData.primary300,
      textColor: Colors.white,
    );
  }

  Widget _walletButton() {
    return Consumer<WalletProvider>(
      builder: (context, wp, _) {
        if (Constant.userModel == null) return const SizedBox.shrink();
        final rupees = wp.moneyBalanceRupees;
        final loading = wp.loadingWallet;
        return InkWell(
          onTap: () => Get.to(() => const WalletHomeScreen()),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: Colors.white.withOpacity(0.45),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppThemeData.danger300.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 15,
                    color: AppThemeData.danger300,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  loading
                      ? "..."
                      : "₹${rupees == rupees.truncateToDouble() ? rupees.toInt() : rupees.toStringAsFixed(1)}",
                  style: TextStyle(
                    fontFamily: AppThemeData.semiBold,
                    fontSize: 12.5,
                    color: AppThemeData.grey800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFoodMartBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD6162A), Color(0xFFFF6035)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(19),
              ),
              child: const Center(
                child: Text(
                  'FOOD',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _onMartTap,
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Center(
                  child: Text(
                    'MART',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Consumer<SwiggySearchProvider>(
      builder: (context, swiggySearchProvider, _) {
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              swiggySearchProvider.initFunction();
              Get.to(() => const SwiggySearchScreen());
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withOpacity(0.14),
            highlightColor: Colors.white.withOpacity(0.08),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.55),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppThemeData.primary50,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      "assets/icons/ic_search.svg",
                      color: AppThemeData.primary300,
                      width: 16,
                      height: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Search for dishes, restaurants".tr,
                      style: TextStyle(
                        fontFamily: AppThemeData.medium,
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.mic_none_rounded,
                    size: 21,
                    color: AppThemeData.grey600,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
