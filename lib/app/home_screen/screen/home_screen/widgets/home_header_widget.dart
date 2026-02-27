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
        // gradient: LinearGradient(
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        //   colors: [
        //     const Color(0xFFFFF8F0),
        //     const Color(0xFFFFF0E0),
        //     AppThemeData.primary50,
        //   ],
        // ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).viewPadding.top + 12,
          left: 16,
          right: 16,
          bottom: 12,
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
                  child: InkWell(
                    onTap: () => _onLocationTap(),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 22,
                          color: AppThemeData.danger300,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _locationTitle(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppThemeData.semiBold,
                                  fontSize: 15,
                                  color: AppThemeData.grey900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                Constant.selectedLocation
                                        .getFullAddress()
                                        .isEmpty
                                    ? "Set delivery address".tr
                                    : Constant.selectedLocation
                                          .getFullAddress(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppThemeData.medium,
                                  fontSize: 12,
                                  color: AppThemeData.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: AppThemeData.grey600,
                        ),
                      ],
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
      child: _buildProfileAvatar(),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 18,
                  color: AppThemeData.danger300,
                ),
                const SizedBox(width: 4),
                Text(
                  loading
                      ? "..."
                      : "₹${rupees == rupees.truncateToDouble() ? rupees.toInt() : rupees.toStringAsFixed(1)}",
                  style: TextStyle(
                    fontFamily: AppThemeData.semiBold,
                    fontSize: 12,
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
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppThemeData.primary300,
                borderRadius: BorderRadius.circular(19),
              ),
              child: const Center(
                child: Text(
                  'FOOD',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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
        return InkWell(
          onTap: () {
            swiggySearchProvider.initFunction();
            Get.to(() => const SwiggySearchScreen());
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  "assets/icons/ic_search.svg",
                  color: AppThemeData.primary300,
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Search 'dishes', 'restaurants'".tr,
                    style: TextStyle(
                      fontFamily: AppThemeData.medium,
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Icon(
                  Icons.mic_none_rounded,
                  size: 22,
                  color: AppThemeData.grey500,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
