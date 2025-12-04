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

class AddressListScreen extends StatelessWidget {
  const AddressListScreen({super.key});

  static void showAddAddressModal(BuildContext context) {
    final controller = Provider.of<AddressListProvider>(context, listen: false);
    addAddressBottomSheet(context, controller);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddressListProvider>(
      builder: (context, controller, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Force refresh addresses every time page opens
          controller.initFunction(context: context, forceRefresh: true);
        });
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
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () async {
                    controller.useMyCurrentLocation();
                  },
                  child: Row(
                    children: [
                      SvgPicture.asset("assets/icons/ic_send_one.svg"),
                      const SizedBox(width: 10),
                      Text(
                        "Use my current location".tr,
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
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    controller.clearData();
                    AddressListScreen.addAddressBottomSheet(
                      context,
                      controller,
                    );
                  },
                  child: Row(
                    children: [
                      SvgPicture.asset("assets/icons/ic_plus.svg"),
                      const SizedBox(width: 10),
                      Text(
                        "Add Location".tr,
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
                const SizedBox(height: 32),
                Text(
                  "Saved Addresses".tr,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppThemeData.grey900,
                    fontFamily: AppThemeData.semiBold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: controller.shippingAddressList.isEmpty
                      ? Constant.showEmptyView(
                          message: "Saved addresses not found".tr,
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: controller.shippingAddressList.length,
                          itemBuilder: (context, index) {
                            ShippingAddress shippingAddress =
                                controller.shippingAddressList[index];
                            return InkWell(
                              onTap: () {
                                Get.back(result: shippingAddress);
                                print(
                                  "ListViewBuilder ${shippingAddress.toJson()} ",
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                child: Container(
                                  decoration: ShapeDecoration(
                                    color: AppThemeData.grey50,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                  Text(
                                                    shippingAddress.addressAs
                                                        .toString(),
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color:
                                                          AppThemeData.grey800,
                                                      fontFamily:
                                                          AppThemeData.semiBold,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  shippingAddress.isDefault ==
                                                          false
                                                      ? const SizedBox()
                                                      : Container(
                                                          decoration: ShapeDecoration(
                                                            color: AppThemeData
                                                                .primary50,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 5,
                                                                ),
                                                            child: Text(
                                                              "Default".tr,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: AppThemeData
                                                                    .primary300,
                                                                fontFamily:
                                                                    AppThemeData
                                                                        .semiBold,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                ],
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                showActionSheet(
                                                  context,
                                                  index,
                                                  controller,
                                                );
                                              },
                                              child: SvgPicture.asset(
                                                "assets/icons/ic_more_one.svg",
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          shippingAddress
                                              .getFullAddress()
                                              .toString(),
                                          style: TextStyle(
                                            color: AppThemeData.grey500,
                                            fontFamily: AppThemeData.regular,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showActionSheet(
    BuildContext context,
    int index,
    AddressListProvider controller,
  ) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) =>
          Consumer2<AddressListProvider, HomeProvider>(
            builder: (context, addressListProvider, homeProvider, _) {
              return CupertinoActionSheet(
                actions: <CupertinoActionSheetAction>[
                  CupertinoActionSheetAction(
                    onPressed: () async {
                      ShowToastDialog.showLoader("Please wait".tr);
                      try {
                        List<ShippingAddress> tempShippingAddress = [];
                        for (var element in controller.shippingAddressList) {
                          ShippingAddress addressModel = element;
                          if (addressModel.id ==
                              controller.shippingAddressList[index].id) {
                            addressModel.isDefault = true;
                          } else {
                            addressModel.isDefault = false;
                          }
                          tempShippingAddress.add(element);
                        }
                        controller.userModel.shippingAddress =
                            tempShippingAddress;
                        final success = await addressListProvider.updateUser(
                          controller.userModel,
                        );
                        if (success) {
                          homeProvider
                              .ensureUserModelIsLoaded(); // Refresh from API
                          ShowToastDialog.closeLoader();
                          Get.back();
                          ShowToastDialog.showToast(
                            "Default address updated".tr,
                          );
                        } else {
                          ShowToastDialog.closeLoader();
                          ShowToastDialog.showToast(
                            "Failed to update default address".tr,
                          );
                        }
                      } catch (e) {
                        ShowToastDialog.closeLoader();
                      }
                    },
                    child: Text(
                      'Default'.tr,
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                  CupertinoActionSheetAction(
                    onPressed: () async {
                      Get.back();
                      controller.clearData();
                      controller.setData(controller.shippingAddressList[index]);
                      AddressListScreen.addAddressBottomSheet(
                        context,
                        controller,
                        index: index,
                      );
                    },
                    child: const Text(
                      'Edit',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  CupertinoActionSheetAction(
                    onPressed: () async {
                      await controller.deleteAddressFunction(index: index);
                    },
                    child: Text(
                      'Delete'.tr,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  // CupertinoActionSheetAction(
                  //   onPressed: () async {
                  //     ShowToastDialog.showLoader("Please wait".tr);
                  //     try {
                  //       controller.shippingAddressList.removeAt(index);
                  //       controller.userModel.shippingAddress =
                  //           controller.shippingAddressList;
                  //       final success = await addressListProvider.updateUser(
                  //         controller.userModel,
                  //       );
                  //       if (success) {
                  //         controller.getUser();
                  //         ShowToastDialog.closeLoader();
                  //         Get.back();
                  //         ShowToastDialog.showToast("Address deleted".tr);
                  //       } else {
                  //         ShowToastDialog.closeLoader();
                  //         ShowToastDialog.showToast("Failed to delete address".tr);
                  //       }
                  //     } catch (e) {
                  //       ShowToastDialog.closeLoader();
                  //     }
                  //   },
                  //   child: Text(
                  //     'Delete'.tr,
                  //     style: const TextStyle(color: Colors.red),
                  //   ),
                  // ),
                ],
                cancelButton: CupertinoActionSheetAction(
                  isDefaultAction: true,
                  onPressed: () {
                    Get.back();
                  },
                  child: Text('Cancel'.tr),
                ),
              );
            },
          ),
    );
  }

  static addAddressBottomSheet(
    BuildContext context,
    AddressListProvider controller, {
    int? index,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.6,
        child: StatefulBuilder(
          builder: (context1, setState) {
            return Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Container(
                          width: 134,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: ShapeDecoration(
                            color: AppThemeData.grey800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InkWell(
                        onTap: () async {
                          if (Constant.selectedMapType == 'osm') {
                            final result = await Get.to(() => MapPickerPage());
                            if (result != null) {
                              final firstPlace = result;
                              final lat = firstPlace.coordinates.latitude;
                              final lng = firstPlace.coordinates.longitude;
                              final address = firstPlace.address;
                              controller.localityEditingController.text =
                                  address.toString();
                              controller.localityText = address
                                  .toString(); // Update reactive string
                              controller.location = UserLocation(
                                latitude: lat,
                                longitude: lng,
                              );
                            }
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlacePicker(
                                  apiKey: Constant.mapAPIKey,
                                  onPlacePicked: (result) {
                                    controller.localityEditingController.text =
                                        result.formattedAddress!.toString();
                                    controller.localityText = result
                                        .formattedAddress!
                                        .toString(); // Update reactive string
                                    controller.location = UserLocation(
                                      latitude: result.geometry!.location.lat,
                                      longitude: result.geometry!.location.lng,
                                    );
                                    Get.back();
                                  },
                                  initialPosition: const LatLng(
                                    -33.8567844,
                                    151.213108,
                                  ),
                                  useCurrentLocation: true,
                                  selectInitialPosition: true,
                                  usePinPointingSearch: true,
                                  usePlaceDetailSearch: true,
                                  zoomGesturesEnabled: true,
                                  zoomControlsEnabled: true,
                                  resizeToAvoidBottomInset:
                                      false, // only works in page mode, less flickery, remove if wrong offsets
                                ),
                              ),
                            );
                          }
                        },
                        child: Row(
                          children: [
                            SvgPicture.asset("assets/icons/ic_focus.svg"),
                            const SizedBox(width: 10),
                            Text(
                              "Choose Current Location".tr,
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
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
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
                            height: 34,
                            child: ListView.builder(
                              itemCount: controller.saveAsList.length,
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      controller.selectedSaveAs = controller
                                          .saveAsList[index]
                                          .toString();
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            controller.selectedSaveAs ==
                                                controller.saveAsList[index]
                                                    .toString()
                                            ? AppThemeData.primary300
                                            : AppThemeData.grey100,
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(20),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        child: Row(
                                          children: [
                                            SvgPicture.asset(
                                              controller.saveAsList[index] ==
                                                      "Home".tr
                                                  ? "assets/icons/ic_home_add.svg"
                                                  : controller
                                                            .saveAsList[index] ==
                                                        "Work".tr
                                                  ? "assets/icons/ic_work.svg"
                                                  : controller
                                                            .saveAsList[index] ==
                                                        "Hotel".tr
                                                  ? "assets/icons/ic_building.svg"
                                                  : "assets/icons/ic_location.svg",
                                              width: 18,
                                              height: 18,
                                              colorFilter: ColorFilter.mode(
                                                controller.selectedSaveAs ==
                                                        controller
                                                            .saveAsList[index]
                                                            .toString()
                                                    ? AppThemeData.grey50
                                                    : AppThemeData.grey300,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              controller.saveAsList[index]
                                                  .toString()
                                                  .tr,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: AppThemeData.medium,
                                                color:
                                                    controller.selectedSaveAs ==
                                                        controller
                                                            .saveAsList[index]
                                                            .toString()
                                                    ? AppThemeData.grey50
                                                    : AppThemeData.grey300,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFieldWidget(
                            title: 'House/Flat/Floor No.'.tr,
                            controller:
                                controller.houseBuildingTextEditingController,
                            hintText: 'House/Flat/Floor No.'.tr,
                          ),
                          // Apartment/Road/Area field with clickable location icon
                          Column(
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
                                onTap: () async {
                                  if (Constant.selectedMapType == 'osm') {
                                    final result = await Get.to(
                                      () => MapPickerPage(),
                                    );
                                    if (result != null) {
                                      final firstPlace = result;
                                      final lat =
                                          firstPlace.coordinates.latitude;
                                      final lng =
                                          firstPlace.coordinates.longitude;
                                      final address = firstPlace.address;
                                      controller
                                          .localityEditingController
                                          .text = address
                                          .toString();
                                      controller.localityText = address
                                          .toString();
                                      controller.location = UserLocation(
                                        latitude: lat,
                                        longitude: lng,
                                      );
                                    }
                                  } else {
                                    bool serviceEnabled =
                                        await Geolocator.isLocationServiceEnabled();
                                    if (!serviceEnabled) {
                                      Get.snackbar(
                                        "Location Disabled",
                                        "Please enable location services.",
                                      );
                                      await Geolocator.openLocationSettings();
                                      return;
                                    }
                                    LocationPermission permission =
                                        await Geolocator.checkPermission();
                                    if (permission ==
                                        LocationPermission.denied) {
                                      permission =
                                          await Geolocator.requestPermission();
                                      if (permission ==
                                          LocationPermission.denied) {
                                        Get.snackbar(
                                          "Permission Denied",
                                          "Location permission is required.",
                                        );
                                        return;
                                      }
                                    }
                                    if (permission ==
                                        LocationPermission.deniedForever) {
                                      Get.snackbar(
                                        "Permission Denied Forever",
                                        "Please enable location permission in Settings.",
                                      );
                                      await Geolocator.openAppSettings();
                                      return;
                                    }
                                    // ✅ 2. Safe to open PlacePicker now
                                    Get.to(
                                      () => PlacePicker(
                                        apiKey: Constant.mapAPIKey,
                                        onPlacePicked: (result) {
                                          controller
                                                  .localityEditingController
                                                  .text =
                                              result.formattedAddress
                                                  ?.toString() ??
                                              '';
                                          controller.localityText =
                                              result.formattedAddress
                                                  ?.toString() ??
                                              '';
                                          controller.location = UserLocation(
                                            latitude:
                                                result.geometry!.location.lat,
                                            longitude:
                                                result.geometry!.location.lng,
                                          );
                                          Get.back();
                                        },
                                        initialPosition: const LatLng(
                                          -33.8567844,
                                          151.213108,
                                        ),
                                        useCurrentLocation: true,
                                        selectInitialPosition: true,
                                        usePinPointingSearch: true,
                                        usePlaceDetailSearch: true,
                                        zoomGesturesEnabled: true,
                                        zoomControlsEnabled: true,
                                        resizeToAvoidBottomInset: false,
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppThemeData.grey300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: IgnorePointer(
                                          // 👈 prevents TextField from catching taps
                                          child: TextField(
                                            controller: controller
                                                .localityEditingController,
                                            readOnly: true,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: AppThemeData.grey900,
                                            ),
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Please add address using icon'
                                                      .tr,
                                              hintStyle: TextStyle(
                                                color: AppThemeData.grey300,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        child: Icon(
                                          Icons.location_on,
                                          color: AppThemeData.primary300,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextFieldWidget(
                            title: 'Nearby landmark'.tr,
                            controller: controller.landmarkEditingController,
                            hintText: 'Nearby landmark (Optional)'.tr,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: SafeArea(
                child: Container(
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child: Consumer<AddressListProvider>(
                    builder: (context, addressListProvider, _) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: RoundedButtonFill(
                          isEnabled: !controller.isLoading,
                          title: "Save Address Details".tr,
                          height: 5.5,
                          color: AppThemeData.primary300,
                          fontSizes: 16,
                          // With this:
                          onPress: () async {
                            final addressIndex = index ?? -1;
                            controller.saveAddressFunction(
                              addressIndex,
                              context,
                              addressListProvider,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
