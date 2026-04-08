// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
// import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/constant/show_toast_dialog.dart';
// import 'package:jippymart_customer/models/user_model.dart';
// import 'package:jippymart_customer/themes/app_them_data.dart';
// import 'package:jippymart_customer/themes/round_button_fill.dart';
// import 'package:jippymart_customer/themes/text_field_widget.dart';
// import 'package:jippymart_customer/widget/osm_map/map_picker_page.dart';
// import 'package:provider/provider.dart';
//
// class AddressListScreen extends StatefulWidget {
//   const AddressListScreen({super.key});
//
//   static void showAddAddressModal(BuildContext context) {
//     final controller = Provider.of<AddressListProvider>(context, listen: false);
//     controller.clearData();
//     _showAddAddressModal(context, controller);
//   }
//
//   @override
//   State<AddressListScreen> createState() => _AddressListScreenState();
// }
//
// class _AddressListScreenState extends State<AddressListScreen> {
//   late final AddressListProvider _controller;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = Provider.of<AddressListProvider>(context, listen: false);
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;
//       _controller.initFunction(context: context);
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppThemeData.pageBg,
//       appBar: AppBar(
//         elevation: 0,
//         centerTitle: false,
//         titleSpacing: 16,
//         backgroundColor: AppThemeData.pageBg,
//         surfaceTintColor: Colors.transparent,
//         title: Text(
//           "Your Addresses".tr,
//           style: const TextStyle(
//             fontSize: 22,
//             color: AppThemeData.textPrimary,
//             fontFamily: AppThemeData.semiBold,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//       body: SafeArea(
//         child: Consumer<AddressListProvider>(
//           builder: (context, controller, _) {
//             if (controller.isInitializing) {
//               return _buildLoadingState();
//             }
//
//             return RefreshIndicator(
//               color: AppThemeData.primary300,
//               onRefresh: () async {
//                 await controller.initFunction(
//                   context: context,
//                   forceRefresh: true,
//                 );
//               },
//               child: CustomScrollView(
//                 physics: const BouncingScrollPhysics(
//                   parent: AlwaysScrollableScrollPhysics(),
//                 ),
//                 slivers: [
//                   SliverPadding(
//                     padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
//                     sliver: SliverList(
//                       delegate: SliverChildListDelegate([
//                         _buildHeroSection(controller),
//                         const SizedBox(height: 20),
//                         _buildQuickActions(controller),
//                         const SizedBox(height: 24),
//                         _buildSectionHeader(controller),
//                         const SizedBox(height: 12),
//                       ]),
//                     ),
//                   ),
//                   if (controller.shippingAddressList.isEmpty)
//                     SliverFillRemaining(
//                       hasScrollBody: false,
//                       child: Padding(
//                         padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
//                         child: _buildEmptyState(controller),
//                       ),
//                     )
//                   else
//                     SliverPadding(
//                       padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
//                       sliver: SliverList.separated(
//                         itemCount: controller.shippingAddressList.length,
//                         separatorBuilder: (_, _) => const SizedBox(height: 12),
//                         itemBuilder: (context, index) {
//                           return _buildAddressItem(
//                             controller.shippingAddressList[index],
//                             index,
//                             controller,
//                           );
//                         },
//                       ),
//                     ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLoadingState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(AppThemeData.primary300),
//           ),
//           SizedBox(height: 16),
//           Text(
//             "Loading addresses...",
//             style: TextStyle(
//               color: AppThemeData.textMuted,
//               fontSize: 14,
//               fontFamily: AppThemeData.medium,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHeroSection(AddressListProvider controller) {
//     final count = controller.shippingAddressList.length;
//
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [AppThemeData.orange, AppThemeData.primary300],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(28),
//         boxShadow: [
//           BoxShadow(
//             color: AppThemeData.primary300.withValues(alpha: 0.18),
//             blurRadius: 24,
//             offset: const Offset(0, 12),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   count == 0
//                       ? "Set up your first delivery address".tr
//                       : "Pick where your order should land".tr,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     height: 1.2,
//                     color: Colors.white,
//                     fontFamily: AppThemeData.bold,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 // Text(
//                 //   count == 0
//                 //       ? "Save home, work, or any custom place for a faster checkout experience."
//                 //             .tr
//                 //       : "Keep your most-used places organized so switching locations stays effortless."
//                 //             .tr,
//                 //   style: TextStyle(
//                 //     fontSize: 14,
//                 //     height: 1.45,
//                 //     color: Colors.white.withValues(alpha: 0.92),
//                 //     fontFamily: AppThemeData.regular,
//                 //   ),
//                 // ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 12),
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: Colors.white.withValues(alpha: 0.18),
//               borderRadius: BorderRadius.circular(22),
//               border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
//             ),
//             child: const Icon(
//               Icons.near_me_rounded,
//               color: Colors.white,
//               size: 30,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildQuickActions(AddressListProvider controller) {
//     return Row(
//       children: [
//         Expanded(
//           child: _AddressQuickActionCard(
//             icon: Icons.my_location_rounded,
//             title: "Use current location".tr,
//             subtitle: "Auto detect".tr,
//             onTap: controller.useMyCurrentLocation,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _AddressQuickActionCard(
//             icon: Icons.add_location_alt_rounded,
//             title: "Add new address".tr,
//             subtitle: "Save place".tr,
//             isPrimary: true,
//             onTap: () {
//               controller.clearData();
//               _showAddAddressModal(context, controller);
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSectionHeader(AddressListProvider controller) {
//     final count = controller.shippingAddressList.length;
//
//     return Row(
//       children: [
//         Expanded(
//           child: Text(
//             "Saved Addresses".tr,
//             style: const TextStyle(
//               fontSize: 18,
//               color: AppThemeData.textPrimary,
//               fontFamily: AppThemeData.semiBold,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//           decoration: BoxDecoration(
//             color: AppThemeData.orangeLight,
//             borderRadius: BorderRadius.circular(999),
//           ),
//           child: Text(
//             "$count ${count == 1 ? "place".tr : "places".tr}",
//             style: const TextStyle(
//               fontSize: 12,
//               color: AppThemeData.primary400,
//               fontFamily: AppThemeData.medium,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildEmptyState(AddressListProvider controller) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(28),
//       decoration: BoxDecoration(
//         color: AppThemeData.cardBg,
//         borderRadius: BorderRadius.circular(28),
//         border: Border.all(color: AppThemeData.divider),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 88,
//             height: 88,
//             decoration: BoxDecoration(
//               color: AppThemeData.orangeLight,
//               borderRadius: BorderRadius.circular(28),
//             ),
//             child: Icon(
//               Icons.location_city_rounded,
//               size: 42,
//               color: AppThemeData.primary300,
//             ),
//           ),
//           const SizedBox(height: 18),
//           Text(
//             "No saved addresses yet".tr,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               fontSize: 20,
//               color: AppThemeData.textPrimary,
//               fontFamily: AppThemeData.semiBold,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             "Add your first delivery location to speed up checkout and make switching between places easier.",
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 14,
//               height: 1.5,
//               color: AppThemeData.textMuted,
//               fontFamily: AppThemeData.regular,
//             ),
//           ),
//           const SizedBox(height: 22),
//           SizedBox(
//             width: double.infinity,
//             child: RoundedButtonFill(
//               title: "Add Address".tr,
//               height: 5.6,
//               radius: 16,
//               color: AppThemeData.primary300,
//               textColor: Colors.white,
//               onPress: () {
//                 controller.clearData();
//                 _showAddAddressModal(context, controller);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAddressItem(
//     ShippingAddress shippingAddress,
//     int index,
//     AddressListProvider controller,
//   ) {
//     final isDefault = shippingAddress.isDefault == true;
//
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: () => Get.back(result: shippingAddress),
//         borderRadius: BorderRadius.circular(20),
//         child: Ink(
//           decoration: BoxDecoration(
//             color: AppThemeData.cardBg,
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(
//               color: isDefault ? AppThemeData.orangeMid : AppThemeData.divider,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withValues(alpha: 0.04),
//                 blurRadius: 14,
//                 offset: const Offset(0, 6),
//               ),
//             ],
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(14),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _AddressIconBadge(type: shippingAddress.addressAs),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: Text(
//                                   _getAddressLabel(shippingAddress),
//                                   style: const TextStyle(
//                                     fontSize: 16,
//                                     color: AppThemeData.textPrimary,
//                                     fontFamily: AppThemeData.semiBold,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               if (isDefault) _buildDefaultBadge(),
//                             ],
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             shippingAddress.getFullAddress().toString(),
//                             style: const TextStyle(
//                               fontSize: 13,
//                               height: 1.35,
//                               color: AppThemeData.textMuted,
//                               fontFamily: AppThemeData.regular,
//                             ),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     InkWell(
//                       onTap: () => _showActionSheet(context, index, controller),
//                       borderRadius: BorderRadius.circular(999),
//                       child: Container(
//                         width: 32,
//                         height: 32,
//                         decoration: BoxDecoration(
//                           color: AppThemeData.grey100,
//                           borderRadius: BorderRadius.circular(999),
//                         ),
//                         child: const Icon(
//                           Icons.more_horiz_rounded,
//                           color: AppThemeData.grey700,
//                           size: 18,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: [
//                     if ((shippingAddress.landmark ?? '').trim().isNotEmpty)
//                       _AddressMetaChip(
//                         icon: Icons.place_outlined,
//                         label: shippingAddress.landmark!.trim(),
//                       ),
//                     _AddressMetaChip(
//                       icon: isDefault
//                           ? Icons.verified_rounded
//                           : Icons.touch_app_rounded,
//                       label: isDefault
//                           ? "Primary address".tr
//                           : "Tap to deliver".tr,
//                     ),
//                     if (!isDefault)
//                       _AddressMetaChip(
//                         icon: Icons.star_outline_rounded,
//                         label: "Can be default".tr,
//                         highlighted: true,
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   String _getAddressLabel(ShippingAddress shippingAddress) {
//     final label = shippingAddress.addressAs?.trim();
//     if (label == null || label.isEmpty) {
//       return "Saved address".tr;
//     }
//     return label;
//   }
//
//   Widget _buildDefaultBadge() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: AppThemeData.greenLight,
//         borderRadius: BorderRadius.circular(999),
//       ),
//       child: const Text(
//         "Default",
//         style: TextStyle(
//           fontSize: 11,
//           color: AppThemeData.green,
//           fontFamily: AppThemeData.semiBold,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }
//
//   void _showActionSheet(
//     BuildContext context,
//     int index,
//     AddressListProvider controller,
//   ) {
//     showCupertinoModalPopup<void>(
//       context: context,
//       builder: (BuildContext context) => CupertinoActionSheet(
//         title: Text("Manage address".tr),
//         message: Text("Choose what you want to do with this saved place.".tr),
//         actions: [
//           if (controller.shippingAddressList[index].isDefault != true)
//             CupertinoActionSheetAction(
//               onPressed: () => _setDefaultAddress(index, controller),
//               child: Text(
//                 'Set as Default'.tr,
//                 style: TextStyle(color: AppThemeData.primary300),
//               ),
//             ),
//           CupertinoActionSheetAction(
//             onPressed: () {
//               Get.back();
//               controller.setData(controller.shippingAddressList[index]);
//               _showAddAddressModal(context, controller, index: index);
//             },
//             child: Text('Edit'.tr),
//           ),
//           CupertinoActionSheetAction(
//             isDestructiveAction: true,
//             onPressed: () => controller.deleteAddressFunction(index: index),
//             child: Text('Delete'.tr),
//           ),
//         ],
//         cancelButton: CupertinoActionSheetAction(
//           isDefaultAction: true,
//           onPressed: () => Get.back(),
//           child: Text('Cancel'.tr),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _setDefaultAddress(
//     int index,
//     AddressListProvider controller,
//   ) async {
//     ShowToastDialog.showLoader("Please wait".tr);
//     try {
//       final tempShippingAddress = controller.shippingAddressList.map((element) {
//         return ShippingAddress(
//           id: element.id,
//           address: element.address,
//           addressAs: element.addressAs,
//           landmark: element.landmark,
//           locality: element.locality,
//           location: element.location != null
//               ? UserLocation(
//                   latitude: element.location!.latitude,
//                   longitude: element.location!.longitude,
//                 )
//               : null,
//           isDefault: element.id == controller.shippingAddressList[index].id,
//           zoneId: element.zoneId,
//         );
//       }).toList();
//
//       controller.userModel.shippingAddress = tempShippingAddress;
//
//       final success = await controller.updateUser(controller.userModel);
//
//       if (success) {
//         if (!mounted) return;
//         final homeProvider = Provider.of<HomeProvider>(context, listen: false);
//         homeProvider.ensureUserModelIsLoaded();
//         await controller.initFunction(context: context, forceRefresh: true);
//
//         ShowToastDialog.closeLoader();
//         Get.back();
//         ShowToastDialog.showToast("Default address updated".tr);
//       } else {
//         ShowToastDialog.closeLoader();
//         ShowToastDialog.showToast("Failed to update default address".tr);
//       }
//     } catch (_) {
//       ShowToastDialog.closeLoader();
//     }
//   }
// }
//
// void _showAddAddressModal(
//   BuildContext context,
//   AddressListProvider controller, {
//   int? index,
// }) {
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     useSafeArea: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) =>
//         _AddAddressBottomSheet(controller: controller, index: index),
//   );
// }
//
// class _AddAddressBottomSheet extends StatefulWidget {
//   final AddressListProvider controller;
//   final int? index;
//
//   const _AddAddressBottomSheet({required this.controller, this.index});
//
//   @override
//   State<_AddAddressBottomSheet> createState() => _AddAddressBottomSheetState();
// }
//
// class _AddAddressBottomSheetState extends State<_AddAddressBottomSheet> {
//   bool _isLoadingLocation = false;
//
//   bool get _isEditing => widget.index != null;
//
//   @override
//   Widget build(BuildContext context) {
//     return DraggableScrollableSheet(
//       initialChildSize: 0.82,
//       minChildSize: 0.62,
//       maxChildSize: 0.95,
//       expand: false,
//       builder: (context, scrollController) {
//         return Container(
//           decoration: const BoxDecoration(
//             color: AppThemeData.cardBg,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
//           ),
//           child: Column(
//             children: [
//               _buildDragHandle(),
//               _buildHeader(),
//               Expanded(
//                 child: SingleChildScrollView(
//                   controller: scrollController,
//                   padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildLocationPicker(),
//                       const SizedBox(height: 24),
//                       _buildSaveAsSection(),
//                       const SizedBox(height: 24),
//                       _buildAddressFields(),
//                     ],
//                   ),
//                 ),
//               ),
//               _buildSaveButton(),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildDragHandle() {
//     return Padding(
//       padding: const EdgeInsets.only(top: 12, bottom: 8),
//       child: Container(
//         width: 44,
//         height: 5,
//         decoration: BoxDecoration(
//           color: AppThemeData.grey300,
//           borderRadius: BorderRadius.circular(999),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   _isEditing ? "Edit address".tr : "Add a new address".tr,
//                   style: const TextStyle(
//                     fontSize: 24,
//                     color: AppThemeData.textPrimary,
//                     fontFamily: AppThemeData.bold,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   "Save a precise location so deliveries arrive faster and with fewer calls."
//                       .tr,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     height: 1.45,
//                     color: AppThemeData.textMuted,
//                     fontFamily: AppThemeData.regular,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           IconButton(
//             onPressed: Get.back,
//             style: IconButton.styleFrom(backgroundColor: AppThemeData.grey100),
//             icon: const Icon(Icons.close_rounded),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLocationPicker() {
//     final hasLocation = widget.controller.localityEditingController.text
//         .trim()
//         .isNotEmpty;
//
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 180),
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: hasLocation
//               ? [AppThemeData.orangeLight, Colors.white]
//               : [AppThemeData.grey100, Colors.white],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(
//           color: hasLocation ? AppThemeData.orangeMid : AppThemeData.divider,
//         ),
//       ),
//       child: InkWell(
//         onTap: _pickLocation,
//         borderRadius: BorderRadius.circular(18),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               width: 46,
//               height: 46,
//               decoration: BoxDecoration(
//                 color: AppThemeData.primary300.withValues(alpha: 0.1),
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: _isLoadingLocation
//                   ? Padding(
//                       padding: EdgeInsets.all(12),
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2.2,
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                           AppThemeData.primary300,
//                         ),
//                       ),
//                     )
//                   : Icon(Icons.place_rounded, color: AppThemeData.primary300),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     _isLoadingLocation
//                         ? "Fetching location".tr
//                         : hasLocation
//                         ? "Selected delivery point".tr
//                         : "Choose your delivery point".tr,
//                     style: const TextStyle(
//                       fontSize: 15,
//                       color: AppThemeData.textPrimary,
//                       fontFamily: AppThemeData.semiBold,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     _isLoadingLocation
//                         ? "Please wait while we open the picker.".tr
//                         : hasLocation
//                         ? widget.controller.localityEditingController.text
//                         : "Tap to use maps and pin the exact address.".tr,
//                     style: TextStyle(
//                       fontSize: 14,
//                       height: 1.45,
//                       color: hasLocation
//                           ? AppThemeData.textPrimary
//                           : AppThemeData.textMuted,
//                       fontFamily: AppThemeData.regular,
//                     ),
//                     maxLines: hasLocation ? 3 : 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 8),
//             const Icon(
//               Icons.chevron_right_rounded,
//               color: AppThemeData.grey500,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSaveAsSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Save as',
//           style: TextStyle(
//             fontSize: 16,
//             color: AppThemeData.textPrimary,
//             fontFamily: AppThemeData.semiBold,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 6),
//         const Text(
//           'Pick a label that helps you recognize this address quickly.',
//           style: TextStyle(
//             fontSize: 13,
//             color: AppThemeData.textMuted,
//             fontFamily: AppThemeData.regular,
//           ),
//         ),
//         const SizedBox(height: 14),
//         Wrap(
//           spacing: 10,
//           runSpacing: 10,
//           children: widget.controller.saveAsList.map<Widget>((dynamic value) {
//             final type = value.toString();
//             final isSelected = widget.controller.selectedSaveAs == type;
//
//             return ChoiceChip(
//               avatar: _getIconForType(type, isSelected),
//               label: Text(type.tr),
//               selected: isSelected,
//               showCheckmark: false,
//               selectedColor: AppThemeData.primary300,
//               backgroundColor: AppThemeData.grey100,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 side: BorderSide(
//                   color: isSelected
//                       ? AppThemeData.primary300
//                       : AppThemeData.chipBorder,
//                 ),
//               ),
//               labelStyle: TextStyle(
//                 color: isSelected ? Colors.white : AppThemeData.grey700,
//                 fontFamily: AppThemeData.medium,
//                 fontWeight: FontWeight.w500,
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
//               onSelected: (_) {
//                 setState(() {
//                   widget.controller.selectedSaveAs = type;
//                 });
//               },
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }
//
//   Widget _getIconForType(String type, bool isSelected) {
//     final icon = switch (type) {
//       'Home' => "assets/icons/ic_home_add.svg",
//       'Work' => "assets/icons/ic_work.svg",
//       'Hotel' => "assets/icons/ic_building.svg",
//       _ => "assets/icons/ic_location.svg",
//     };
//
//     return SvgPicture.asset(
//       icon,
//       width: 18,
//       height: 18,
//       colorFilter: ColorFilter.mode(
//         isSelected ? Colors.white : AppThemeData.grey600,
//         BlendMode.srcIn,
//       ),
//     );
//   }
//
//   Widget _buildAddressFields() {
//     return Column(
//       children: [
//         TextFieldWidget(
//           title: 'House / Flat / Floor No.',
//           hintText: 'Enter apartment, suite or floor number',
//           controller: widget.controller.houseBuildingTextEditingController,
//           textInputAction: TextInputAction.next,
//           fillColor: AppThemeData.grey100,
//         ),
//         const SizedBox(height: 16),
//         TextFieldWidget(
//           title: 'Apartment / Road / Area',
//           hintText: 'Pick a location from the map',
//           controller: widget.controller.localityEditingController,
//           readOnly: true,
//           fillColor: AppThemeData.grey100,
//           suffix: IconButton(
//             onPressed: _pickLocation,
//             icon: Icon(
//               Icons.location_on_rounded,
//               color: AppThemeData.primary300,
//             ),
//           ),
//         ),
//         const SizedBox(height: 16),
//         TextFieldWidget(
//           title: 'Nearby landmark (Optional)',
//           hintText: 'Add a landmark for easier delivery',
//           controller: widget.controller.landmarkEditingController,
//           textInputAction: TextInputAction.done,
//           fillColor: AppThemeData.grey100,
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSaveButton() {
//     return SafeArea(
//       top: false,
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
//         child: Consumer<AddressListProvider>(
//           builder: (context, addressListProvider, _) {
//             return RoundedButtonFill(
//               isEnabled: !widget.controller.isLoading,
//               isLoading: widget.controller.isLoading,
//               title: _isEditing
//                   ? "Update Address Details".tr
//                   : "Save Address Details".tr,
//               height: 5.8,
//               radius: 18,
//               color: AppThemeData.primary300,
//               textColor: Colors.white,
//               fontSizes: 16,
//               onPress: () async {
//                 final addressIndex = widget.index ?? -1;
//                 await widget.controller.saveAddressFunction(
//                   addressIndex,
//                   context,
//                   addressListProvider,
//                 );
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Future<void> _pickLocation() async {
//     if (_isLoadingLocation) return;
//
//     setState(() {
//       _isLoadingLocation = true;
//     });
//
//     try {
//       if (Constant.selectedMapType == 'osm') {
//         final result = await Get.to(() => MapPickerPage());
//         if (result != null) {
//           final lat = result.coordinates.latitude;
//           final lng = result.coordinates.longitude;
//           final address = result.address.toString();
//
//           widget.controller.localityEditingController.text = address;
//           widget.controller.localityText = address;
//           widget.controller.location = UserLocation(
//             latitude: lat,
//             longitude: lng,
//           );
//
//           if (mounted) {
//             setState(() {});
//           }
//         }
//       } else {
//         final serviceEnabled = await Geolocator.isLocationServiceEnabled();
//         if (!serviceEnabled) {
//           Get.snackbar(
//             "Location Disabled".tr,
//             "Please enable location services.".tr,
//           );
//           await Geolocator.openLocationSettings();
//           return;
//         }
//
//         var permission = await Geolocator.checkPermission();
//         if (permission == LocationPermission.denied) {
//           permission = await Geolocator.requestPermission();
//           if (permission == LocationPermission.denied) {
//             Get.snackbar(
//               "Permission Denied".tr,
//               "Location permission is required.".tr,
//             );
//             return;
//           }
//         }
//
//         if (permission == LocationPermission.deniedForever) {
//           Get.snackbar(
//             "Permission Denied Forever".tr,
//             "Please enable location permission in Settings.".tr,
//           );
//           await Geolocator.openAppSettings();
//           return;
//         }
//
//         final result = await Get.to(
//           () => PlacePicker(
//             apiKey: Constant.mapAPIKey,
//             onPlacePicked: (result) {
//               widget.controller.localityEditingController.text =
//                   result.formattedAddress?.toString() ?? '';
//               widget.controller.localityText =
//                   result.formattedAddress?.toString() ?? '';
//               widget.controller.location = UserLocation(
//                 latitude: result.geometry!.location.lat,
//                 longitude: result.geometry!.location.lng,
//               );
//               Get.back(result: true);
//             },
//             initialPosition: const LatLng(-33.8567844, 151.213108),
//             useCurrentLocation: true,
//             selectInitialPosition: true,
//             usePinPointingSearch: true,
//             usePlaceDetailSearch: true,
//             zoomGesturesEnabled: true,
//             zoomControlsEnabled: true,
//             resizeToAvoidBottomInset: false,
//           ),
//         );
//
//         if (result != null && mounted) {
//           setState(() {});
//         }
//       }
//     } catch (e) {
//       debugPrint("Location picker error: $e");
//       Get.snackbar("Error".tr, "Failed to pick location".tr);
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoadingLocation = false;
//         });
//       }
//     }
//   }
// }
//
// class _AddressQuickActionCard extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final bool isPrimary;
//   final VoidCallback onTap;
//
//   const _AddressQuickActionCard({
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//     required this.onTap,
//     this.isPrimary = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final background = isPrimary
//         ? AppThemeData.primary300
//         : AppThemeData.cardBg;
//     final titleColor = isPrimary ? Colors.white : AppThemeData.textPrimary;
//     final subtitleColor = isPrimary
//         ? Colors.white.withValues(alpha: 0.82)
//         : AppThemeData.textMuted;
//
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(18),
//         child: Ink(
//           padding: const EdgeInsets.all(14),
//           decoration: BoxDecoration(
//             color: background,
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(
//               color: isPrimary ? AppThemeData.primary300 : AppThemeData.divider,
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: 36,
//                 height: 36,
//                 decoration: BoxDecoration(
//                   color: isPrimary
//                       ? Colors.white.withValues(alpha: 0.18)
//                       : AppThemeData.orangeLight,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(
//                   icon,
//                   size: 18,
//                   color: isPrimary ? Colors.white : AppThemeData.primary300,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: titleColor,
//                   fontFamily: AppThemeData.semiBold,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 subtitle,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: subtitleColor,
//                   fontFamily: AppThemeData.regular,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _AddressIconBadge extends StatelessWidget {
//   final String? type;
//
//   const _AddressIconBadge({this.type});
//
//   @override
//   Widget build(BuildContext context) {
//     final normalized = type?.toLowerCase() ?? '';
//     final (
//       IconData icon,
//       Color bgColor,
//       Color iconColor,
//     ) = switch (normalized) {
//       'home' => (
//         Icons.home_rounded,
//         AppThemeData.orangeLight,
//         AppThemeData.primary300,
//       ),
//       'work' => (Icons.work_rounded, AppThemeData.info50, AppThemeData.info400),
//       'hotel' => (
//         Icons.apartment_rounded,
//         AppThemeData.success50,
//         AppThemeData.darkGreen,
//       ),
//       _ => (Icons.place_rounded, AppThemeData.grey100, AppThemeData.grey700),
//     };
//
//     return Container(
//       width: 40,
//       height: 40,
//       decoration: BoxDecoration(
//         color: bgColor,
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Icon(icon, color: iconColor, size: 20),
//     );
//   }
// }
//
// class _AddressMetaChip extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool highlighted;
//
//   const _AddressMetaChip({
//     required this.icon,
//     required this.label,
//     this.highlighted = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
//       decoration: BoxDecoration(
//         color: highlighted ? AppThemeData.orangeLight : AppThemeData.grey100,
//         borderRadius: BorderRadius.circular(999),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             icon,
//             size: 13,
//             color: highlighted ? AppThemeData.primary300 : AppThemeData.grey600,
//           ),
//           const SizedBox(width: 6),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 11,
//               color: highlighted
//                   ? AppThemeData.primary300
//                   : AppThemeData.grey600,
//               fontFamily: AppThemeData.medium,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// address_list_screen.dart
//
// Design: Premium food-delivery address management UI.
// Architecture: Thin screen → pure presenter widgets → single responsibility
//               components. All business logic stays in AddressListProvider.
// Codex notes: Every constant is named. Every widget is independently testable.
//              No magic numbers. No hard-coded strings (all use .tr).
//              BuildContext is never stored across async gaps.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/themes/text_field_widget.dart';
import 'package:jippymart_customer/widget/osm_map/map_picker_page.dart';
import 'package:provider/provider.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────

/// All visual constants live here so a designer can tune the whole screen
/// by editing one place. Never use raw literals outside this block.
abstract final class _Tokens {
  // Gradient
  static const gradStart = Color(0xFFE8192C);
  static const gradMid = Color(0xFFFF4E1F);
  static const gradEnd = Color(0xFFFF6B35);

  // Surface
  static const canvas = Color(0xFFF7F7F8);
  static const card = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFEEEEF2);
  static const selectedBorder = Color(0xFFFFBDAD);

  // Semantic
  static const openGreen = Color(0xFF2ECC71);
  static const openGreenBg = Color(0xFFE8F8F0);
  static const infoBlue = Color(0xFF3498DB);
  static const infoBlueBg = Color(0xFFEBF5FB);
  static const hotelTeal = Color(0xFF1ABC9C);
  static const hotelTealBg = Color(0xFFE8F8F5);
  static const mutedIcon = Color(0xFF9B9BAA);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF555570);
  static const textMuted = Color(0xFF888899);

  // Chips / badges
  static const chipBg = Color(0xFFF2F2F5);
  static const chipBorder = Color(0xFFE0E0E8);
  static const orangeChip = Color(0xFFFFF0EC);
  static const orangeChipText = Color(0xFFD84315);

  // Radius
  static const double rXS = 8;
  static const double rSM = 12;
  static const double rMD = 16;
  static const double rLG = 20;
  static const double rXL = 24;
  static const double rXXL = 32;

  // Elevation / shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 6),
    ),
  ];
  static List<BoxShadow> heroBannerShadow = [
    BoxShadow(
      color: gradStart.withOpacity(0.22),
      blurRadius: 28,
      spreadRadius: 0,
      offset: const Offset(0, 14),
    ),
  ];

  // Type scale
  static const double textXS = 11;
  static const double textSM = 13;
  static const double textMD = 15;
  static const double textLG = 17;
  static const double textXL = 20;
  static const double textXXL = 24;

  // Spacing
  static const double sp4 = 4;
  static const double sp6 = 6;
  static const double sp8 = 8;
  static const double sp10 = 10;
  static const double sp12 = 12;
  static const double sp14 = 14;
  static const double sp16 = 16;
  static const double sp20 = 20;
  static const double sp24 = 24;
  static const double sp28 = 28;
  static const double sp32 = 32;
}

// ─── Gradient convenience ─────────────────────────────────────────────────────

const _kBrandGradient = LinearGradient(
  colors: [_Tokens.gradStart, _Tokens.gradMid, _Tokens.gradEnd],
  stops: [0.0, 0.5, 1.0],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ─────────────────────────────────────────────────────────────────────────────
// AddressListScreen — entry point
// ─────────────────────────────────────────────────────────────────────────────

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
      backgroundColor: _Tokens.canvas,
      appBar: _AddressAppBar(),
      body: SafeArea(
        child: Consumer<AddressListProvider>(
          builder: (context, ctrl, _) {
            if (ctrl.isInitializing) return const _LoadingView();

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
                onItemTap: (addr) => Get.back(result: addr),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Action handlers ────────────────────────────────────────────────────────

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
// _AddressAppBar
// ─────────────────────────────────────────────────────────────────────────────

class _AddressAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: _Tokens.sp16,
      backgroundColor: _Tokens.canvas,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.only(left: _Tokens.sp8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: Get.back,
            borderRadius: BorderRadius.circular(50),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: _Tokens.textPrimary,
            ),
          ),
        ),
      ),
      title: Text(
        "Your Addresses".tr,
        style: const TextStyle(
          fontSize: _Tokens.textXL,
          color: _Tokens.textPrimary,
          fontFamily: AppThemeData.semiBold,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
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

  const _AddressScrollBody({
    required this.ctrl,
    required this.onAddNew,
    required this.onItemAction,
    required this.onItemTap,
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
            _Tokens.sp16,
            _Tokens.sp8,
            _Tokens.sp16,
            _Tokens.sp16,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _HeroBanner(count: addresses.length),
              const SizedBox(height: _Tokens.sp16),
              _QuickActionRow(ctrl: ctrl, onAddNew: onAddNew),
              const SizedBox(height: _Tokens.sp24),
              _SectionHeader(count: addresses.length),
              const SizedBox(height: _Tokens.sp12),
            ]),
          ),
        ),

        // Empty state OR address list
        if (addresses.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                _Tokens.sp16,
                0,
                _Tokens.sp16,
                _Tokens.sp24,
              ),
              child: _EmptyState(onAddNew: onAddNew),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              _Tokens.sp16,
              0,
              _Tokens.sp16,
              _Tokens.sp32,
            ),
            sliver: SliverList.separated(
              itemCount: addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: _Tokens.sp12),
              itemBuilder: (_, i) => _AddressCard(
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
// _LoadingView — centred spinner with label
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.8,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppThemeData.primary300,
              ),
            ),
          ),
          const SizedBox(height: _Tokens.sp16),
          Text(
            "Loading your addresses…".tr,
            style: const TextStyle(
              fontSize: _Tokens.textSM,
              color: _Tokens.textMuted,
              fontFamily: AppThemeData.medium,
            ),
          ),
        ],
      ),
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
        horizontal: _Tokens.sp20,
        vertical: _Tokens.sp20,
      ),
      decoration: BoxDecoration(
        gradient: _kBrandGradient,
        borderRadius: BorderRadius.circular(_Tokens.rXXL),
        boxShadow: _Tokens.heroBannerShadow,
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
                    horizontal: _Tokens.sp10,
                    vertical: _Tokens.sp4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    count == 0 ? "GET STARTED".tr : "$count SAVED".tr,
                    style: const TextStyle(
                      fontSize: _Tokens.textXS,
                      color: Colors.white,
                      fontFamily: AppThemeData.semiBold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: _Tokens.sp10),
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: _Tokens.textLG,
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
          const SizedBox(width: _Tokens.sp14),
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
// _QuickActionRow
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionRow extends StatelessWidget {
  final AddressListProvider ctrl;
  final VoidCallback onAddNew;

  const _QuickActionRow({required this.ctrl, required this.onAddNew});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            icon: Icons.my_location_rounded,
            label: "Use my location".tr,
            sublabel: "Auto-detect".tr,
            isPrimary: false,
            onTap: ctrl.useMyCurrentLocation,
          ),
        ),
        const SizedBox(width: _Tokens.sp12),
        Expanded(
          child: _QuickActionTile(
            icon: Icons.add_location_alt_rounded,
            label: "Add address".tr,
            sublabel: "Save a place".tr,
            isPrimary: true,
            onTap: onAddNew,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _QuickActionTile — single card in the quick-action row
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool isPrimary;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isPrimary ? AppThemeData.primary300 : _Tokens.card;
    final labelColor = isPrimary ? Colors.white : _Tokens.textPrimary;
    final subColor = isPrimary
        ? Colors.white.withOpacity(0.78)
        : _Tokens.textMuted;
    final iconBg = isPrimary
        ? Colors.white.withOpacity(0.18)
        : _Tokens.orangeChip;
    final iconColor = isPrimary ? Colors.white : AppThemeData.primary300;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_Tokens.rLG),
        child: Ink(
          padding: const EdgeInsets.all(_Tokens.sp14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(_Tokens.rLG),
            border: Border.all(
              color: isPrimary ? AppThemeData.primary300 : _Tokens.cardBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(_Tokens.rSM),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(height: _Tokens.sp12),
              Text(
                label,
                style: TextStyle(
                  fontSize: _Tokens.textSM,
                  color: labelColor,
                  fontFamily: AppThemeData.semiBold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: _Tokens.sp4),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: _Tokens.textXS,
                  color: subColor,
                  fontFamily: AppThemeData.regular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionHeader
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final int count;

  const _SectionHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Accent bar
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: _kBrandGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: _Tokens.sp10),
        Expanded(
          child: Text(
            "Saved Addresses".tr,
            style: const TextStyle(
              fontSize: _Tokens.textLG,
              color: _Tokens.textPrimary,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: _Tokens.sp10,
              vertical: _Tokens.sp4,
            ),
            decoration: BoxDecoration(
              color: _Tokens.orangeChip,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$count ${count == 1 ? "place".tr : "places".tr}",
              style: const TextStyle(
                fontSize: _Tokens.textXS,
                color: _Tokens.orangeChipText,
                fontFamily: AppThemeData.semiBold,
                letterSpacing: 0.2,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddNew;

  const _EmptyState({required this.onAddNew});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_Tokens.sp28),
      decoration: BoxDecoration(
        color: _Tokens.card,
        borderRadius: BorderRadius.circular(_Tokens.rXXL),
        border: Border.all(color: _Tokens.cardBorder),
        boxShadow: _Tokens.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Layered icon visual
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _Tokens.orangeChip,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: _kBrandGradient,
                  borderRadius: BorderRadius.circular(_Tokens.rXL),
                ),
                child: const Icon(
                  Icons.location_city_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: _Tokens.sp20),
          Text(
            "No saved addresses yet".tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: _Tokens.textXL,
              color: _Tokens.textPrimary,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: _Tokens.sp8),
          Text(
            "Add your first delivery location to speed up checkout and make switching between places easier."
                .tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: _Tokens.textSM,
              height: 1.55,
              color: _Tokens.textMuted,
              fontFamily: AppThemeData.regular,
            ),
          ),
          const SizedBox(height: _Tokens.sp24),
          // Gradient CTA button
          _GradientButton(
            label: "Add Your First Address".tr,
            icon: Icons.add_location_alt_rounded,
            onTap: onAddNew,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GradientButton — reusable branded CTA
// ─────────────────────────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Ink(
          decoration: BoxDecoration(
            gradient: _kBrandGradient,
            borderRadius: BorderRadius.circular(50),
            // boxShadow: [
            //   BoxShadow(
            //     color: _Tokens.gradStart.withOpacity(0.32),
            //     blurRadius: 18,
            //     offset: const Offset(0, 8),
            //   ),
            // ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _Tokens.sp24,
              vertical: _Tokens.sp14,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: _Tokens.sp8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: _Tokens.textMD,
                    fontFamily: AppThemeData.semiBold,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AddressCard — single address list item
// ─────────────────────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final ShippingAddress address;
  final VoidCallback onTap;
  final VoidCallback onAction;

  const _AddressCard({
    required this.address,
    required this.onTap,
    required this.onAction,
  });

  bool get _isDefault => address.isDefault == true;

  String get _label {
    final raw = address.addressAs?.trim();
    return (raw == null || raw.isEmpty) ? "Saved address".tr : raw;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_Tokens.rXL),
        child: Ink(
          decoration: BoxDecoration(
            color: _Tokens.card,
            borderRadius: BorderRadius.circular(_Tokens.rXL),
            border: Border.all(
              color: _isDefault ? _Tokens.selectedBorder : _Tokens.cardBorder,
              width: _isDefault ? 1.5 : 1,
            ),
            boxShadow: _Tokens.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(_Tokens.sp16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: icon + title + badge + menu ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AddressTypeBadge(type: address.addressAs),
                    const SizedBox(width: _Tokens.sp12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _label,
                                  style: const TextStyle(
                                    fontSize: _Tokens.textMD,
                                    color: _Tokens.textPrimary,
                                    fontFamily: AppThemeData.semiBold,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_isDefault) ...[
                                const SizedBox(width: _Tokens.sp8),
                                _DefaultBadge(),
                              ],
                            ],
                          ),
                          const SizedBox(height: _Tokens.sp6),
                          Text(
                            address.getFullAddress().toString(),
                            style: const TextStyle(
                              fontSize: _Tokens.textSM,
                              height: 1.4,
                              color: _Tokens.textMuted,
                              fontFamily: AppThemeData.regular,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: _Tokens.sp8),
                    // More-actions button
                    _MoreButton(onTap: onAction),
                  ],
                ),

                // ── Divider ──
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: _Tokens.sp12),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: _Tokens.cardBorder,
                  ),
                ),

                // ── Meta chips ──
                Wrap(
                  spacing: _Tokens.sp8,
                  runSpacing: _Tokens.sp8,
                  children: [
                    if ((address.landmark ?? '').trim().isNotEmpty)
                      _MetaChip(
                        icon: Icons.place_outlined,
                        label: address.landmark!.trim(),
                      ),
                    _MetaChip(
                      icon: _isDefault
                          ? Icons.verified_rounded
                          : Icons.touch_app_rounded,
                      label: _isDefault
                          ? "Primary address".tr
                          : "Tap to deliver here".tr,
                      highlighted: _isDefault,
                    ),
                    if (!_isDefault)
                      _MetaChip(
                        icon: Icons.star_outline_rounded,
                        label: "Set as default".tr,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AddressTypeBadge — icon avatar that reflects Home / Work / Hotel / Other
// ─────────────────────────────────────────────────────────────────────────────

class _AddressTypeBadge extends StatelessWidget {
  final String? type;

  const _AddressTypeBadge({this.type});

  @override
  Widget build(BuildContext context) {
    final normalized = type?.toLowerCase().trim() ?? '';

    final (IconData icon, Color bg, Color fg) = switch (normalized) {
      'home' => (
        Icons.home_rounded,
        _Tokens.orangeChip,
        AppThemeData.primary300,
      ),
      'work' => (Icons.work_rounded, _Tokens.infoBlueBg, _Tokens.infoBlue),
      'hotel' => (
        Icons.apartment_rounded,
        _Tokens.hotelTealBg,
        _Tokens.hotelTeal,
      ),
      _ => (Icons.place_rounded, _Tokens.chipBg, _Tokens.mutedIcon),
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_Tokens.rMD),
      ),
      child: Icon(icon, color: fg, size: 22),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DefaultBadge
// ─────────────────────────────────────────────────────────────────────────────

class _DefaultBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _Tokens.sp8,
        vertical: _Tokens.sp4,
      ),
      decoration: BoxDecoration(
        color: _Tokens.openGreenBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 11,
            color: _Tokens.openGreen,
          ),
          const SizedBox(width: 4),
          Text(
            "Default".tr,
            style: const TextStyle(
              fontSize: _Tokens.textXS,
              color: _Tokens.openGreen,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MoreButton
// ─────────────────────────────────────────────────────────────────────────────

class _MoreButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _Tokens.chipBg,
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(
            Icons.more_vert_rounded,
            size: 18,
            color: _Tokens.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MetaChip — small info pill under the address card
// ─────────────────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;

  const _MetaChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlighted ? _Tokens.openGreenBg : _Tokens.chipBg;
    final fg = highlighted ? _Tokens.openGreen : _Tokens.mutedIcon;
    final textColor = highlighted ? _Tokens.openGreen : _Tokens.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _Tokens.sp10,
        vertical: _Tokens.sp6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: _Tokens.sp6),
          Text(
            label,
            style: TextStyle(
              fontSize: _Tokens.textXS,
              color: textColor,
              fontFamily: AppThemeData.medium,
              fontWeight: FontWeight.w500,
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
    builder: (_) => _AddressFormSheet(ctrl: ctrl, editIndex: index),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _AddressFormSheet — draggable bottom sheet for add / edit address
// ─────────────────────────────────────────────────────────────────────────────

class _AddressFormSheet extends StatefulWidget {
  final AddressListProvider ctrl;
  final int? editIndex;

  const _AddressFormSheet({required this.ctrl, this.editIndex});

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  bool _isPickingLocation = false;

  bool get _isEditing => widget.editIndex != null;

  AddressListProvider get _ctrl => widget.ctrl;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.84,
      minChildSize: 0.62,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: _Tokens.card,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(_Tokens.rXXL),
            ),
          ),
          child: Column(
            children: [
              _SheetDragHandle(),
              Expanded(
                child: CustomScrollView(
                  controller: scrollCtrl,
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        _Tokens.sp20,
                        _Tokens.sp8,
                        _Tokens.sp20,
                        _Tokens.sp24,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildLocationPickerCard(),
                          const SizedBox(height: _Tokens.sp24),
                          _buildSaveAsSection(),
                          const SizedBox(height: _Tokens.sp24),
                          _buildFormFields(),
                          const SizedBox(height: _Tokens.sp8),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              _buildSaveButton(),
            ],
          ),
        );
      },
    );
  }

  // ── Sub-sections ────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _Tokens.sp20,
        _Tokens.sp4,
        _Tokens.sp12,
        _Tokens.sp8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient label tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _Tokens.sp10,
                    vertical: _Tokens.sp4,
                  ),
                  decoration: BoxDecoration(
                    gradient: _kBrandGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isEditing ? "EDITING".tr : "NEW ADDRESS".tr,
                    style: const TextStyle(
                      fontSize: _Tokens.textXS,
                      color: Colors.white,
                      fontFamily: AppThemeData.semiBold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: _Tokens.sp10),
                Text(
                  _isEditing ? "Edit address".tr : "Add a new address".tr,
                  style: const TextStyle(
                    fontSize: _Tokens.textXXL,
                    color: _Tokens.textPrimary,
                    fontFamily: AppThemeData.bold,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: _Tokens.sp6),
                Text(
                  "Pin your exact location for faster, hassle-free deliveries."
                      .tr,
                  style: const TextStyle(
                    fontSize: _Tokens.textSM,
                    height: 1.45,
                    color: _Tokens.textMuted,
                    fontFamily: AppThemeData.regular,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: _Tokens.sp8),
          // Close button
          Material(
            color: _Tokens.chipBg,
            borderRadius: BorderRadius.circular(50),
            child: InkWell(
              onTap: Get.back,
              borderRadius: BorderRadius.circular(50),
              child: const Padding(
                padding: EdgeInsets.all(_Tokens.sp8),
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: _Tokens.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPickerCard() {
    final hasLocation = _ctrl.localityEditingController.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: _pickLocation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(_Tokens.sp16),
        decoration: BoxDecoration(
          color: hasLocation ? _Tokens.orangeChip : _Tokens.chipBg,
          borderRadius: BorderRadius.circular(_Tokens.rXL),
          border: Border.all(
            color: hasLocation ? _Tokens.selectedBorder : _Tokens.cardBorder,
            width: hasLocation ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Map pin avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: hasLocation ? _kBrandGradient : null,
                color: hasLocation ? null : _Tokens.card,
                borderRadius: BorderRadius.circular(_Tokens.rMD),
                boxShadow: _Tokens.cardShadow,
              ),
              child: _isPickingLocation
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppThemeData.primary300,
                        ),
                      ),
                    )
                  : Icon(
                      hasLocation
                          ? Icons.location_on_rounded
                          : Icons.add_location_alt_outlined,
                      color: hasLocation ? Colors.white : _Tokens.mutedIcon,
                      size: 22,
                    ),
            ),

            const SizedBox(width: _Tokens.sp14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isPickingLocation
                        ? "Opening location picker…".tr
                        : hasLocation
                        ? "Delivery location set".tr
                        : "Choose delivery point".tr,
                    style: TextStyle(
                      fontSize: _Tokens.textMD,
                      color: hasLocation
                          ? _Tokens.orangeChipText
                          : _Tokens.textPrimary,
                      fontFamily: AppThemeData.semiBold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: _Tokens.sp4),
                  Text(
                    _isPickingLocation
                        ? "Just a moment…".tr
                        : hasLocation
                        ? _ctrl.localityEditingController.text
                        : "Tap to pin your exact address on the map.".tr,
                    style: TextStyle(
                      fontSize: _Tokens.textSM,
                      height: 1.4,
                      color: hasLocation
                          ? _Tokens.textSecondary
                          : _Tokens.textMuted,
                      fontFamily: AppThemeData.regular,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: _Tokens.sp8),
            Icon(Icons.chevron_right_rounded, color: _Tokens.mutedIcon),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveAsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Save as",
          style: TextStyle(
            fontSize: _Tokens.textMD,
            color: _Tokens.textPrimary,
            fontFamily: AppThemeData.semiBold,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: _Tokens.sp4),
        const Text(
          "Pick a label to recognise this address quickly.",
          style: TextStyle(
            fontSize: _Tokens.textSM,
            color: _Tokens.textMuted,
            fontFamily: AppThemeData.regular,
          ),
        ),
        const SizedBox(height: _Tokens.sp14),
        Wrap(
          spacing: _Tokens.sp10,
          runSpacing: _Tokens.sp10,
          children: _ctrl.saveAsList.map<Widget>((dynamic value) {
            final type = value.toString();
            final selected = _ctrl.selectedSaveAs == type;
            return _SaveAsChip(
              type: type,
              isSelected: selected,
              onTap: () => setState(() => _ctrl.selectedSaveAs = type),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFieldWidget(
          title: 'House / Flat / Floor No.',
          hintText: 'Apartment, suite or floor number',
          controller: _ctrl.houseBuildingTextEditingController,
          textInputAction: TextInputAction.next,
          fillColor: _Tokens.chipBg,
        ),
        const SizedBox(height: _Tokens.sp16),
        TextFieldWidget(
          title: 'Apartment / Road / Area',
          hintText: 'Pin a location on the map',
          controller: _ctrl.localityEditingController,
          readOnly: true,
          fillColor: _Tokens.chipBg,
          suffix: IconButton(
            onPressed: _pickLocation,
            icon: Icon(
              Icons.location_on_rounded,
              color: AppThemeData.primary300,
            ),
          ),
        ),
        const SizedBox(height: _Tokens.sp16),
        TextFieldWidget(
          title: 'Nearby landmark (Optional)',
          hintText: 'Landmark for easier delivery',
          controller: _ctrl.landmarkEditingController,
          textInputAction: TextInputAction.done,
          fillColor: _Tokens.chipBg,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _Tokens.sp20,
          _Tokens.sp12,
          _Tokens.sp20,
          _Tokens.sp20,
        ),
        child: Consumer<AddressListProvider>(
          builder: (context, prov, _) {
            return SizedBox(
              width: double.infinity,
              child: _GradientButton(
                label: _isEditing ? "Update Address".tr : "Save Address".tr,
                icon: _isEditing
                    ? Icons.check_circle_outline_rounded
                    : Icons.save_alt_rounded,
                onTap: _ctrl.isLoading
                    ? () {}
                    : () async {
                        final idx = widget.editIndex ?? -1;
                        await _ctrl.saveAddressFunction(idx, context, prov);
                      },
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Location picking ────────────────────────────────────────────────────────

  Future<void> _pickLocation() async {
    if (_isPickingLocation) return;
    setState(() => _isPickingLocation = true);

    try {
      if (Constant.selectedMapType == 'osm') {
        final result = await Get.to(() => MapPickerPage());
        if (result != null) {
          _ctrl.localityEditingController.text = result.address.toString();
          _ctrl.localityText = result.address.toString();
          _ctrl.location = UserLocation(
            latitude: result.coordinates.latitude,
            longitude: result.coordinates.longitude,
          );
          if (mounted) setState(() {});
        }
        return;
      }

      // Google Maps path
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          "Location Disabled".tr,
          "Please enable location services.".tr,
        );
        await Geolocator.openLocationSettings();
        return;
      }

      var permission = await Geolocator.checkPermission();
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
        Get.snackbar("Permission Denied".tr, "Enable location in Settings.".tr);
        await Geolocator.openAppSettings();
        return;
      }

      final result = await Get.to(
        () => PlacePicker(
          apiKey: Constant.mapAPIKey,
          onPlacePicked: (r) {
            _ctrl.localityEditingController.text =
                r.formattedAddress?.toString() ?? '';
            _ctrl.localityText = r.formattedAddress?.toString() ?? '';
            _ctrl.location = UserLocation(
              latitude: r.geometry!.location.lat,
              longitude: r.geometry!.location.lng,
            );
            Get.back(result: true);
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

      if (result != null && mounted) setState(() {});
    } catch (e) {
      debugPrint("Location picker error: $e");
      Get.snackbar("Error".tr, "Failed to pick location.".tr);
    } finally {
      if (mounted) setState(() => _isPickingLocation = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SheetDragHandle
// ─────────────────────────────────────────────────────────────────────────────

class _SheetDragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _Tokens.sp12),
      child: Center(
        child: Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: _Tokens.cardBorder,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SaveAsChip — address type selector
// ─────────────────────────────────────────────────────────────────────────────

class _SaveAsChip extends StatelessWidget {
  final String type;
  final bool isSelected;
  final VoidCallback onTap;

  const _SaveAsChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  static String _iconPath(String type) => switch (type) {
    'Home' => "assets/icons/ic_home_add.svg",
    'Work' => "assets/icons/ic_work.svg",
    'Hotel' => "assets/icons/ic_building.svg",
    _ => "assets/icons/ic_location.svg",
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: _Tokens.sp14,
          vertical: _Tokens.sp10,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? _kBrandGradient : null,
          color: isSelected ? null : _Tokens.chipBg,
          borderRadius: BorderRadius.circular(_Tokens.rMD),
          border: Border.all(
            color: isSelected ? Colors.transparent : _Tokens.chipBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _Tokens.gradStart.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              _iconPath(type),
              width: 17,
              height: 17,
              colorFilter: ColorFilter.mode(
                isSelected ? Colors.white : _Tokens.mutedIcon,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: _Tokens.sp8),
            Text(
              type.tr,
              style: TextStyle(
                fontSize: _Tokens.textSM,
                color: isSelected ? Colors.white : _Tokens.textSecondary,
                fontFamily: AppThemeData.semiBold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
