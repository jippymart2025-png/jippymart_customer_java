import 'package:geolocator/geolocator.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/widget/osm_map/map_picker_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:provider/provider.dart';
import '../../themes/text_field_widget.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  static void showAddAddressModal(BuildContext context) {
    final controller = Provider.of<AddressListProvider>(context, listen: false);
    _showAddAddressModal(context, controller);
  }

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  late AddressListProvider _controller;

  @override
  void initState() {
    super.initState();
    _controller = Provider.of<AddressListProvider>(context, listen: false);

    // Initialize addresses after a short delay to prevent jank
    Future.delayed(const Duration(milliseconds: 100), () {
      _controller.initFunction(context: context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: AppThemeData.surface,
        title: Text(
          "Add Address".tr,
          style: TextStyle(
            fontSize: 16,
            color: AppThemeData.grey900,
            fontFamily: AppThemeData.medium,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<AddressListProvider>(
          builder: (context, controller, _) {
            if (controller.isInitializing) {
              return _buildLoadingState();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActionButtons(controller),
                  const SizedBox(height: 32),
                  _buildSavedAddressesHeader(),
                  const SizedBox(height: 10),
                  _buildAddressList(controller),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppThemeData.primary300),
          ),
          const SizedBox(height: 16),
          Text(
            "Loading addresses...".tr,
            style: TextStyle(color: AppThemeData.grey500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AddressListProvider controller) {
    return Column(
      children: [
        _buildActionButton(
          icon: "assets/icons/ic_send_one.svg",
          text: "Use my current location".tr,
          onTap: () => controller.useMyCurrentLocation(),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: "assets/icons/ic_plus.svg",
          text: "Add Location".tr,
          onTap: () {
            controller.clearData();
            _showAddAddressModal(context, controller);
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: AppThemeData.primary50,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(icon),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: AppThemeData.primary300,
                fontFamily: AppThemeData.medium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedAddressesHeader() {
    return Text(
      "Saved Addresses".tr,
      style: TextStyle(
        fontSize: 16,
        color: AppThemeData.grey900,
        fontFamily: AppThemeData.semiBold,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildAddressList(AddressListProvider controller) {
    if (controller.shippingAddressList.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 64,
                color: AppThemeData.grey300,
              ),
              const SizedBox(height: 16),
              Text(
                "No saved addresses".tr,
                style: TextStyle(
                  fontSize: 16,
                  color: AppThemeData.grey500,
                  fontFamily: AppThemeData.medium,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Add your first address to get started".tr,
                style: TextStyle(fontSize: 14, color: AppThemeData.grey400),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: () async {
          await controller.initFunction(context: context, forceRefresh: true);
        },
        color: AppThemeData.primary300,
        child: ListView.builder(
          itemCount: controller.shippingAddressList.length,
          itemBuilder: (context, index) {
            return _buildAddressItem(
              controller.shippingAddressList[index],
              index,
              controller,
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddressItem(
    ShippingAddress shippingAddress,
    int index,
    AddressListProvider controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.back(result: shippingAddress);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: AppThemeData.grey50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        "assets/icons/ic_send_one.svg",
                        colorFilter: ColorFilter.mode(
                          AppThemeData.grey800,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                shippingAddress.addressAs.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppThemeData.grey800,
                                  fontFamily: AppThemeData.semiBold,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (shippingAddress.isDefault == true)
                              _buildDefaultBadge(),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            _showActionSheet(context, index, controller),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: SvgPicture.asset(
                            "assets/icons/ic_more_one.svg",
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    shippingAddress.getFullAddress().toString(),
                    style: TextStyle(
                      color: AppThemeData.grey500,
                      fontFamily: AppThemeData.regular,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppThemeData.primary50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "Default".tr,
        style: TextStyle(
          fontSize: 12,
          color: AppThemeData.primary300,
          fontFamily: AppThemeData.semiBold,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showActionSheet(
    BuildContext context,
    int index,
    AddressListProvider controller,
  ) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => _setDefaultAddress(index, controller),
            child: Text(
              'Set as Default'.tr,
              style: TextStyle(color: AppThemeData.primary300),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Get.back();
              controller.setData(controller.shippingAddressList[index]);
              _showAddAddressModal(context, controller, index: index);
            },
            child: Text('Edit'.tr),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => controller.deleteAddressFunction(index: index),
            child: Text('Delete'.tr),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Get.back(),
          child: Text('Cancel'.tr),
        ),
      ),
    );
  }

  Future<void> _setDefaultAddress(
    int index,
    AddressListProvider controller,
  ) async {
    ShowToastDialog.showLoader("Please wait".tr);
    try {
      // Create new list with updated default status
      final tempShippingAddress = controller.shippingAddressList.map((element) {
        return ShippingAddress(
          id: element.id,
          address: element.address,
          addressAs: element.addressAs,
          landmark: element.landmark,
          locality: element.locality,
          location: element.location != null
              ? UserLocation(
                  latitude: element.location!.latitude,
                  longitude: element.location!.longitude,
                )
              : null,
          isDefault: element.id == controller.shippingAddressList[index].id,
          zoneId: element.zoneId,
        );
      }).toList();

      controller.userModel.shippingAddress = tempShippingAddress;

      final success = await controller.updateUser(controller.userModel);

      if (success) {
        final homeProvider = Provider.of<HomeProvider>(context, listen: false);
        homeProvider.ensureUserModelIsLoaded();

        ShowToastDialog.closeLoader();
        Get.back();
        ShowToastDialog.showToast("Default address updated".tr);
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Failed to update default address".tr);
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
    }
  }
}

// Helper function to show add address modal
void _showAddAddressModal(
  BuildContext context,
  AddressListProvider controller, {
  int? index,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) =>
        _AddAddressBottomSheet(controller: controller, index: index),
  );
}

class _AddAddressBottomSheet extends StatefulWidget {
  final AddressListProvider controller;
  final int? index;

  const _AddAddressBottomSheet({required this.controller, this.index});

  @override
  State<_AddAddressBottomSheet> createState() => _AddAddressBottomSheetState();
}

class _AddAddressBottomSheetState extends State<_AddAddressBottomSheet> {
  bool _isLoadingLocation = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildDragHandle(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLocationPicker(),
                      const SizedBox(height: 20),
                      _buildSaveAsSection(),
                      const SizedBox(height: 20),
                      _buildAddressFields(),
                    ],
                  ),
                ),
              ),
              _buildSaveButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppThemeData.grey300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationPicker() {
    return InkWell(
      onTap: _pickLocation,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _isLoadingLocation
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppThemeData.primary300,
                      ),
                    ),
                  )
                : Icon(
                    Icons.location_on,
                    color: AppThemeData.primary300,
                    size: 20,
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isLoadingLocation
                    ? "Getting location...".tr
                    : widget.controller.localityEditingController.text.isEmpty
                    ? "Choose Current Location".tr
                    : widget.controller.localityEditingController.text,
                style: TextStyle(
                  fontSize: 16,
                  color: AppThemeData.primary300,
                  fontFamily: AppThemeData.medium,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveAsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Save as'.tr,
          style: TextStyle(
            fontSize: 16,
            fontFamily: AppThemeData.semiBold,
            color: AppThemeData.grey900,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.builder(
            itemCount: widget.controller.saveAsList.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final type = widget.controller.saveAsList[index].toString();
              final isSelected = widget.controller.selectedSaveAs == type;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getIconForType(type, isSelected),
                      const SizedBox(width: 6),
                      Text(type.tr),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: AppThemeData.primary300,
                  backgroundColor: AppThemeData.grey100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppThemeData.grey700,
                    fontWeight: FontWeight.w500,
                  ),
                  onSelected: (_) {
                    setState(() {
                      widget.controller.selectedSaveAs = type;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _getIconForType(String type, bool isSelected) {
    final icon = switch (type) {
      'Home' => "assets/icons/ic_home_add.svg",
      'Work' => "assets/icons/ic_work.svg",
      'Hotel' => "assets/icons/ic_building.svg",
      _ => "assets/icons/ic_location.svg",
    };

    return SvgPicture.asset(
      icon,
      width: 18,
      height: 18,
      colorFilter: ColorFilter.mode(
        isSelected ? Colors.white : AppThemeData.grey600,
        BlendMode.srcIn,
      ),
    );
  }

  Widget _buildAddressFields() {
    return Column(
      children: [
        TextField(
          controller: widget.controller.houseBuildingTextEditingController,
          decoration: InputDecoration(
            labelText: 'House/Flat/Floor No.'.tr,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppThemeData.grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppThemeData.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppThemeData.primary300),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLocalityField(),
        const SizedBox(height: 16),
        TextField(
          controller: widget.controller.landmarkEditingController,
          decoration: InputDecoration(
            labelText: 'Nearby landmark (Optional)'.tr,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppThemeData.grey300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppThemeData.grey300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppThemeData.primary300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocalityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apartment/Road/Area'.tr,
          style: TextStyle(
            fontSize: 16,
            fontFamily: AppThemeData.semiBold,
            color: AppThemeData.grey900,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickLocation,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppThemeData.grey300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      widget
                              .controller
                              .localityEditingController
                              .text
                              .isNotEmpty
                          ? widget.controller.localityEditingController.text
                          : 'Please add address using icon'.tr,
                      style: TextStyle(
                        color:
                            widget
                                .controller
                                .localityEditingController
                                .text
                                .isNotEmpty
                            ? AppThemeData.grey900
                            : AppThemeData.grey400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _isLoadingLocation
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppThemeData.primary300,
                            ),
                          ),
                        )
                      : Icon(Icons.location_on, color: AppThemeData.primary300),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<AddressListProvider>(
          builder: (context, addressListProvider, _) {
            return RoundedButtonFill(
              isEnabled: !widget.controller.isLoading,
              title: "Save Address Details".tr,
              height: 5.5,
              color: AppThemeData.primary300,
              fontSizes: 16,
              onPress: () async {
                final addressIndex = widget.index ?? -1;
                await widget.controller.saveAddressFunction(
                  addressIndex,
                  context,
                  addressListProvider,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickLocation() async {
    if (_isLoadingLocation) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      if (Constant.selectedMapType == 'osm') {
        final result = await Get.to(() => MapPickerPage());
        if (result != null) {
          final firstPlace = result;
          final lat = firstPlace.coordinates.latitude;
          final lng = firstPlace.coordinates.longitude;
          final address = firstPlace.address;

          widget.controller.localityEditingController.text = address.toString();
          widget.controller.localityText = address.toString();
          widget.controller.location = UserLocation(
            latitude: lat,
            longitude: lng,
          );

          setState(() {});
        }
      } else {
        // Check location permissions
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          Get.snackbar(
            "Location Disabled".tr,
            "Please enable location services.".tr,
          );
          await Geolocator.openLocationSettings();
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            Get.snackbar(
              "Permission Denied".tr,
              "Location permission is required.".tr,
            );
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          Get.snackbar(
            "Permission Denied Forever".tr,
            "Please enable location permission in Settings.".tr,
          );
          await Geolocator.openAppSettings();
          return;
        }

        // Open PlacePicker
        final result = await Get.to(
          () => PlacePicker(
            apiKey: Constant.mapAPIKey,
            onPlacePicked: (result) {
              widget.controller.localityEditingController.text =
                  result.formattedAddress?.toString() ?? '';
              widget.controller.localityText =
                  result.formattedAddress?.toString() ?? '';
              widget.controller.location = UserLocation(
                latitude: result.geometry!.location.lat,
                longitude: result.geometry!.location.lng,
              );
              Get.back();
            },
            initialPosition: const LatLng(-33.8567844, 151.213108),
            useCurrentLocation: true,
            selectInitialPosition: true,
            usePinPointingSearch: true,
            usePlaceDetailSearch: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            resizeToAvoidBottomInset: false,
          ),
        );

        if (result != null) {
          setState(() {});
        }
      }
    } catch (e) {
      print("Location picker error: $e");
      Get.snackbar("Error".tr, "Failed to pick location".tr);
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }
}
