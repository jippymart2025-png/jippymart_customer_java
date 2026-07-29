import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/address_screens/screens/widgets/AddressAppBar.dart';
import 'package:jippymart_customer/app/address_screens/screens/widgets/AddressCard.dart';
import 'package:jippymart_customer/app/address_screens/screens/widgets/AddressFormSheet.dart';
import 'package:jippymart_customer/app/address_screens/screens/widgets/EmptyState.dart';
import 'package:jippymart_customer/app/address_screens/screens/widgets/LoadingView.dart';
import 'package:jippymart_customer/app/address_screens/screens/widgets/QuickActionTile.dart';
import 'package:jippymart_customer/app/address_screens/screens/widgets/SectionHeader.dart';
import 'package:jippymart_customer/app/address_screens/screens/widgets/tokan.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/utils/location_zone_navigation.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/themes/text_field_widget.dart';
import 'package:jippymart_customer/widget/osm_map/map_picker_page.dart';
import 'package:provider/provider.dart';

import '../../cart_screen/provider/cart_provider.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  /// Public helper used by other screens to launch the add-address bottom sheet.
  static void showAddAddressModal(BuildContext context) {
    final ctrl = Provider.of<AddressListProvider>(context, listen: false);
    ctrl.clearData();
    _showAddressBottomSheet(context, ctrl);
  }

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  late final AddressListProvider _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Provider.of<AddressListProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ctrl.initFunction(context: context);
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tokens.canvas,
      appBar: AddressAppBar(),
      body: SafeArea(
        child: Consumer<AddressListProvider>(
          builder: (context, ctrl, _) {
            if (ctrl.isInitializing) return const LoadingView();

            return RefreshIndicator(
              color: AppThemeData.primary300,
              backgroundColor: Colors.white,
              strokeWidth: 2.5,
              onRefresh: () =>
                  ctrl.initFunction(context: context, forceRefresh: true),
              child: _AddressScrollBody(
                ctrl: ctrl,
                onAddNew: () {
                  ctrl.clearData();
                  _showAddressBottomSheet(context, ctrl);
                },
                onItemAction: (index) =>
                    _handleItemAction(context, index, ctrl),
                onItemTap: (addr) => _selectAddress(context, addr),
                onUseMyLocation: () async {
                  final addr = await ctrl.useMyCurrentLocation();
                  if (addr != null && context.mounted) {
                    await _selectAddress(context, addr);
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Action handlers ────────────────────────────────────────────────────────

  Future<void> _selectAddress(
    BuildContext context,
    ShippingAddress addr,
  ) async {
    final lat = addr.location?.latitude;
    final lng = addr.location?.longitude;

    if (lat == null || lng == null || lat == 0.0 || lng == 0.0) {
      Get.back(result: addr);
      return;
    }

    ShowToastDialog.showLoader("Checking service availability...".tr);

    try {
      final zoneModel = await HomeProvider.getCurrentZone(lat, lng);
      final inZone = LocationZoneNavigation.isZoneModelInService(zoneModel);

      ShowToastDialog.closeLoader();

      final homeProvider = Provider.of<HomeProvider>(context, listen: false);

      // Update address & zone
      final success = await homeProvider.changeLocationAddressFunction(
        context: context,
        addressModel: addr,
      );

      if (!success) {
        return;
      }

      // // Reload delivery charge for the newly selected zone
      // final cartProvider = Provider.of<CartControllerProvider>(
      //   context,
      //   listen: false,
      // );
      //
      // print("====== CALLING RELOAD DELIVERY CHARGE ======");
      //
      // // await cartProvider.reloadDeliveryCharge();

      // changeLocationAddressFunction() will navigate.
      if (!inZone) {
        return;
      }

      if (mounted) {
        Get.back(result: addr);
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      print("[ADDRESS_LIST] Zone check error: $e");

      if (mounted) {
        Get.back(result: addr);
      }
    }
  }

  void _handleItemAction(
    BuildContext context,
    int index,
    AddressListProvider ctrl,
  ) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text("Manage address".tr),
        message: Text("Choose what you want to do with this saved place.".tr),
        actions: [
          if (ctrl.shippingAddressList[index].isDefault != true)
            CupertinoActionSheetAction(
              onPressed: () => _setDefault(context, index, ctrl),
              child: Text(
                'Set as Default'.tr,
                style: TextStyle(color: AppThemeData.primary300),
              ),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              ctrl.setData(ctrl.shippingAddressList[index]);
              _showAddressBottomSheet(context, ctrl, index: index);
            },
            child: Text('Edit'.tr),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => ctrl.deleteAddressFunction(index: index),
            child: Text('Delete'.tr),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: Get.back,
          child: Text('Cancel'.tr),
        ),
      ),
    );
  }

  Future<void> _setDefault(
    BuildContext context,
    int index,
    AddressListProvider ctrl,
  ) async {
    ShowToastDialog.showLoader("Please wait".tr);
    try {
      final target = ctrl.shippingAddressList[index];
      final updated = ctrl.shippingAddressList.map((e) {
        return ShippingAddress(
          id: e.id,
          address: e.address,
          addressAs: e.addressAs,
          landmark: e.landmark,
          locality: e.locality,
          location: e.location != null
              ? UserLocation(
                  latitude: e.location!.latitude,
                  longitude: e.location!.longitude,
                )
              : null,
          isDefault: e.id == target.id,
          zoneId: e.zoneId,
        );
      }).toList();

      ctrl.userModel.shippingAddress = updated;

      final ok = await ctrl.updateUser(ctrl.userModel);
      if (ok) {
        if (!mounted) return;
        Provider.of<HomeProvider>(
          context,
          listen: false,
        ).ensureUserModelIsLoaded();
        await ctrl.initFunction(context: context, forceRefresh: true);
        ShowToastDialog.closeLoader();
        Get.back();
        ShowToastDialog.showToast("Default address updated".tr);
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Failed to update default address".tr);
      }
    } catch (_) {
      ShowToastDialog.closeLoader();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AddressScrollBody — orchestrates the full scrollable layout
// ─────────────────────────────────────────────────────────────────────────────

class _AddressScrollBody extends StatelessWidget {
  final AddressListProvider ctrl;
  final VoidCallback onAddNew;
  final void Function(int) onItemAction;
  final void Function(ShippingAddress) onItemTap;
  final Future<void> Function() onUseMyLocation;

  const _AddressScrollBody({
    required this.ctrl,
    required this.onAddNew,
    required this.onItemAction,
    required this.onItemTap,
    required this.onUseMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    final addresses = ctrl.shippingAddressList;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // Hero banner + quick actions
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            Tokens.sp16,
            Tokens.sp8,
            Tokens.sp16,
            Tokens.sp16,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _HeroBanner(count: addresses.length),
              const SizedBox(height: Tokens.sp16),
              QuickActionRow(
                ctrl: ctrl,
                onAddNew: onAddNew,
                onUseMyLocation: onUseMyLocation,
              ),
              const SizedBox(height: Tokens.sp24),
              SectionHeader(count: addresses.length),
              const SizedBox(height: Tokens.sp12),
            ]),
          ),
        ),

        // Empty state OR address list
        if (addresses.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Tokens.sp16,
                0,
                Tokens.sp16,
                Tokens.sp24,
              ),
              child: EmptyState(onAddNew: onAddNew),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.sp16,
              0,
              Tokens.sp16,
              Tokens.sp32,
            ),
            sliver: SliverList.separated(
              itemCount: addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: Tokens.sp12),
              itemBuilder: (_, i) => AddressCard(
                address: addresses[i],
                onTap: () => onItemTap(addresses[i]),
                onAction: () => onItemAction(i),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HeroBanner — gradient card at top
// ─────────────────────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final int count;

  const _HeroBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    final headline = count == 0
        ? "Set up your first delivery address".tr
        : "Where should your order land?".tr;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.sp20,
        vertical: Tokens.sp20,
      ),
      decoration: BoxDecoration(
        gradient: kBrandGradient,
        borderRadius: BorderRadius.circular(Tokens.rXXL),
        boxShadow: Tokens.heroBannerShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Eyebrow label
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Tokens.sp10,
                    vertical: Tokens.sp4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    count == 0 ? "GET STARTED".tr : "$count SAVED".tr,
                    style: const TextStyle(
                      fontSize: Tokens.textXS,
                      color: Colors.white,
                      fontFamily: AppThemeData.semiBold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: Tokens.sp10),
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: Tokens.textLG,
                    height: 1.25,
                    color: Colors.white,
                    fontFamily: AppThemeData.bold,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Tokens.sp14),
          // Circular icon container
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.28),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.near_me_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _showAddressBottomSheet — module-private launcher (not re-exported)
// ─────────────────────────────────────────────────────────────────────────────

void _showAddressBottomSheet(
  BuildContext context,
  AddressListProvider ctrl, {
  int? index,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddressFormSheet(ctrl: ctrl, editIndex: index),
  );
}
