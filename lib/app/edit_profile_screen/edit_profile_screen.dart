import 'dart:io';

import 'package:jippymart_customer/app/edit_profile_screen/provider/edit_profile_provider.dart';
import 'package:jippymart_customer/app/profile_screen/provider/my_profile_provider.dart';
import 'package:jippymart_customer/app/splash_screen/provider/splash_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/app/address_screens/address_list_screen.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/themes/text_field_widget.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer3<EditProfileProvider, SplashProvider, MyProfileProvider>(
        builder: (context, controller, splashProvider, myProfileProvider, _) {
          return Scaffold(
            appBar: AppBar(
              centerTitle: false,
              titleSpacing: 0,
              backgroundColor: AppThemeData.surface,
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Profile Information".tr,
                      style: TextStyle(
                        fontSize: 24,
                        color: AppThemeData.grey900,
                        fontFamily: AppThemeData.semiBold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "View and update your personal details, contact information, and preferences."
                          .tr,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppThemeData.grey900,
                        fontFamily: AppThemeData.regular,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        children: [
                          controller.profileImage.isEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: Image.asset(
                                    Constant.userPlaceHolder,
                                    height: Responsive.width(24, context),
                                    width: Responsive.width(24, context),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Constant().hasValidUrl(
                                      controller.profileImage,
                                    ) ==
                                    false
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: Image.file(
                                    File(controller.profileImage),
                                    height: Responsive.width(24, context),
                                    width: Responsive.width(24, context),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: NetworkImageWidget(
                                    fit: BoxFit.cover,
                                    imageUrl: controller.profileImage,
                                    height: Responsive.width(24, context),
                                    width: Responsive.width(24, context),
                                    errorWidget: Image.asset(
                                      Constant.userPlaceHolder,
                                      fit: BoxFit.cover,
                                      height: Responsive.width(24, context),
                                      width: Responsive.width(24, context),
                                    ),
                                  ),
                                ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () {
                                buildBottomSheet(context, controller);
                              },
                              child: SvgPicture.asset(
                                "assets/icons/ic_edit.svg",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextFieldWidget(
                            title: 'First Name'.tr,
                            controller: controller.firstNameController,
                            hintText: 'First Name'.tr,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFieldWidget(
                            title: 'Last Name'.tr,
                            controller: controller.lastNameController,
                            hintText: 'Last Name'.tr,
                          ),
                        ),
                      ],
                    ),
                    TextFieldWidget(
                      title: 'Email'.tr,
                      textInputType: TextInputType.emailAddress,
                      controller: controller.emailController,
                      hintText: 'Email'.tr,
                      enable: true,
                    ),
                    TextFieldWidget(
                      title: 'Phone Number'.tr,
                      textInputType: TextInputType.phone,
                      controller: controller.phoneNumberController,
                      hintText: 'Phone Number'.tr,
                      enable: controller.phoneNumberController.text
                          .trim()
                          .isEmpty,
                    ),
                    // Address field - display only
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Address'.tr,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppThemeData.grey900,
                              fontFamily: AppThemeData.semiBold,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            // onTap: () async {
                            //   final selectedAddress = await Get.to(
                            //         () => const AddressListScreen(),
                            //   );
                            //   if (selectedAddress != null &&
                            //       selectedAddress is ShippingAddress) {
                            //     controller.updateSelectedAddress(selectedAddress);
                            //   }
                            // },
                            onTap: () {
                              Get.to(() => const AddressListScreen());
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppThemeData.grey50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppThemeData.grey200,
                                  width: 1,
                                ),
                              ),
                              child: _buildAddressContent(controller),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: Container(
              color: AppThemeData.grey50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: RoundedButtonFill(
                  title: "Save Details".tr,
                  height: 5.5,
                  color: AppThemeData.primary300,
                  textColor: AppThemeData.grey50,
                  fontSizes: 16,
                  onPress: () async {
                    await controller.saveData(context);
                    myProfileProvider.initFunction(context: context);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  buildBottomSheet(BuildContext context, EditProfileProvider controller) {
    return showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              height: Responsive.height(22, context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Text(
                      "please select".tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () => controller.pickFile(
                                source: ImageSource.camera,
                              ),
                              icon: const Icon(Icons.camera_alt, size: 32),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                "camera".tr,
                                style: const TextStyle(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () => controller.pickFile(
                                source: ImageSource.gallery,
                              ),
                              icon: const Icon(
                                Icons.photo_library_sharp,
                                size: 32,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                "gallery".tr,
                                style: const TextStyle(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to build address content
  Widget _buildAddressContent(EditProfileProvider controller) {
    final userModel = controller.userModel;
    if (userModel.shippingAddress != null &&
        userModel.shippingAddress!.isNotEmpty) {
      final addresses = userModel.shippingAddress!;
      if (addresses.length == 1) {
        final address = addresses.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              address.addressAs ?? 'Address',
              style: TextStyle(
                fontSize: 14,
                color: AppThemeData.grey600,
                fontFamily: AppThemeData.medium,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              address.getFullAddress(),
              style: TextStyle(
                fontSize: 16,
                color: AppThemeData.grey800,
                fontFamily: AppThemeData.regular,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        );
      } else {
        final defaultAddress = addresses.firstWhere(
          (a) => a.isDefault == true,
          orElse: () => addresses.first,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${addresses.length} Addresses Saved',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppThemeData.grey600,
                      fontFamily: AppThemeData.medium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'Tap to view all',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppThemeData.primary300,
                    fontFamily: AppThemeData.regular,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Show default address
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppThemeData.grey100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppThemeData.primary300.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        defaultAddress.addressAs ?? 'Address',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppThemeData.primary300,
                          fontFamily: AppThemeData.semiBold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppThemeData.primary300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'DEFAULT',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontFamily: AppThemeData.semiBold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    defaultAddress.getFullAddress(),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppThemeData.grey700,
                      fontFamily: AppThemeData.regular,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    } else {
      return Text(
        'No address saved'.tr,
        style: TextStyle(
          fontSize: 16,
          color: AppThemeData.grey500,
          fontFamily: AppThemeData.regular,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
      );
    }
  }
}
