import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:jippymart_customer/app/address_screens/address_list_screen.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/auth_screen/login_screen.dart';
import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/profile_screen/profile_screen.dart';
import 'package:jippymart_customer/app/profile_screen/provider/my_profile_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/widget/initials_avatar.dart';
import 'package:jippymart_customer/widget/osm_map/map_picker_page.dart';
import 'package:provider/provider.dart';

import '../../../../../models/user_model.dart';

Widget homeProfileAddressWidget({
  required HomeProvider homeProvider,
  required BuildContext context,
}) {
  return Row(
    children: [
      Consumer<MyProfileProvider>(
        builder: (context, myProfileProvider, _) {
          return InkWell(
            onTap: () {
              myProfileProvider.initFunction(context: context);
              Get.to(const ProfileScreen());
            },
            child: buildProfileAvatar(),
          );
        },
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Constant.userModel == null
                ? InkWell(
                    onTap: () {
                      Get.offAll(const PhoneNumberScreen());
                    },
                    child: Text(
                      "Login".tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppThemeData.medium,
                        color: AppThemeData.grey900,
                        fontSize: 12,
                      ),
                    ),
                  )
                : Text(
                    Constant.userModel!.fullName().toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppThemeData.medium,
                      color: AppThemeData.grey900,
                      fontSize: 12,
                    ),
                  ),
            Consumer2<AddressListProvider, HomeProvider>(
              builder: (context, addressListProvider, homeProviderConsumer, _) {
                return InkWell(
                  onTap: () async {
                    if (Constant.userModel != null) {
                      addressListProvider.initFunction(context: context);
                      Get.to(const AddressListScreen())?.then((value) {
                        if (value != null) {
                          homeProvider.changeLocationAddressFunction(
                            addressModel: value,
                            context: context,
                          );
                        }
                      });
                    } else {
                      Constant.checkPermission(
                        onTap: () async {
                          ShowToastDialog.showLoader("Please wait".tr);
                          ShippingAddress addressModel = ShippingAddress();
                          try {
                            await Geolocator.requestPermission();
                            await Geolocator.getCurrentPosition();
                            ShowToastDialog.closeLoader();
                            if (Constant.selectedMapType == 'osm') {
                              final result = await Get.to(
                                () => MapPickerPage(),
                              );
                              if (result != null) {
                                final firstPlace = result;
                                final lat = firstPlace.coordinates.latitude;
                                final lng = firstPlace.coordinates.longitude;
                                final address = firstPlace.address;
                                addressModel.addressAs = "Home";
                                addressModel.locality = address.toString();
                                addressModel.address = address
                                    .toString(); // Set address field too
                                addressModel.location = UserLocation(
                                  latitude: lat,
                                  longitude: lng,
                                );
                                homeProvider.changeLocationAddressFunction(
                                  addressModel: addressModel,
                                  context: context,
                                );
                                Get.back();
                              }
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlacePicker(
                                    apiKey: Constant.mapAPIKey,
                                    onPlacePicked: (result) async {
                                      ShippingAddress addressModel =
                                          ShippingAddress();
                                      addressModel.addressAs = "Home";
                                      addressModel.locality = result
                                          .formattedAddress!
                                          .toString();
                                      addressModel.address = result
                                          .formattedAddress!
                                          .toString(); // Set address field too
                                      addressModel.location = UserLocation(
                                        latitude: result.geometry!.location.lat,
                                        longitude:
                                            result.geometry!.location.lng,
                                      );
                                      homeProvider
                                          .changeLocationAddressFunction(
                                            addressModel: addressModel,
                                            context: context,
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
                          } catch (e) {
                            print("placemarkFromCoordinates $e");
                            await placemarkFromCoordinates(
                              19.228825,
                              72.854118,
                            ).then((valuePlaceMaker) {
                              Placemark placeMark = valuePlaceMaker[0];
                              addressModel.addressAs = "Home";
                              addressModel.location = UserLocation(
                                latitude: 19.228825,
                                longitude: 72.854118,
                              );
                              String currentLocation =
                                  "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.administrativeArea}, ${placeMark.postalCode}, ${placeMark.country}";
                              addressModel.locality = currentLocation;
                              addressModel.address =
                                  currentLocation; // Set address field too
                            });
                            ShowToastDialog.closeLoader();
                            homeProvider.changeLocationAddressFunction(
                              addressModel: addressModel,
                              context: context,
                            );
                          }
                        },
                        context: context,
                      );
                    }
                  },
                  child: Text.rich(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    TextSpan(
                      children: [
                        TextSpan(
                          text: Constant.selectedLocation.getFullAddress(),
                          style: TextStyle(
                            fontFamily: AppThemeData.medium,
                            overflow: TextOverflow.ellipsis,
                            color: AppThemeData.grey900,
                            fontSize: 14,
                          ),
                        ),
                        WidgetSpan(
                          child: SvgPicture.asset("assets/icons/ic_down.svg"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      const SizedBox(width: 5),
    ],
  );
}

Widget buildProfileAvatar() {
  final user = Constant.userModel;
  final hasProfileImage =
      user != null &&
      user.profilePictureURL != null &&
      user.profilePictureURL!.isNotEmpty &&
      user.profilePictureURL!.toLowerCase() != "null";

  if (hasProfileImage) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppThemeData.primary300,
      backgroundImage: NetworkImage(user.profilePictureURL!),
    );
  } else {
    return InitialsAvatar(
      firstName: user?.firstName,
      lastName: user?.lastName,
      radius: 20,
      backgroundColor: AppThemeData.primary300,
      textColor: Colors.white,
    );
  }
}
