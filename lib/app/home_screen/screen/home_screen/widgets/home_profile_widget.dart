// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
// import 'package:jippymart_customer/app/address_screens/address_list_screen.dart';
// import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
// import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
// import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
// import 'package:jippymart_customer/app/profile_screen/profile_screen.dart';
// import 'package:jippymart_customer/app/profile_screen/provider/my_profile_provider.dart';
// import 'package:jippymart_customer/app/wallet_screen/provider/wallet_provider.dart';
// import 'package:jippymart_customer/app/wallet_screen/wallet_home_screen.dart';
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/constant/show_toast_dialog.dart';
// import 'package:jippymart_customer/themes/app_them_data.dart';
// import 'package:jippymart_customer/widget/initials_avatar.dart';
// import 'package:jippymart_customer/widget/osm_map/map_picker_page.dart';
// import 'package:provider/provider.dart';
//
// import '../../../../../models/user_model.dart';
//
// Widget homeProfileAddressWidget({
//   required HomeProvider homeProvider,
//   required BuildContext context,
// }) {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     mainAxisSize: MainAxisSize.min,
//     children: [
//       // ── Row: Avatar + Name / Address ──────────────────────────────────────
//       Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           // Avatar → Profile
//           Consumer<MyProfileProvider>(
//             builder: (context, myProfileProvider, _) {
//               return InkWell(
//                 onTap: () {
//                   myProfileProvider.initFunction(context: context);
//                   Get.to(const ProfileScreen());
//                 },
//                 borderRadius: BorderRadius.circular(18),
//                 child: buildProfileAvatar(),
//               );
//             },
//           ),
//           const SizedBox(width: 8),
//
//           // Name + small address inline
//           Expanded(
//             child: Consumer<MyProfileProvider>(
//               builder: (context, myProfileProvider, _) {
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Name / Login
//                     Constant.userModel == null
//                         ? InkWell(
//                             onTap: () => Get.offAll(() => PhoneNumberScreen()),
//                             child: Text(
//                               'Login'.tr,
//                               style: TextStyle(
//                                 fontFamily: AppThemeData.medium,
//                                 color: AppThemeData.grey900,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           )
//                         : Text(
//                             Constant.userModel?.fullName().toString() ?? '',
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: TextStyle(
//                               fontFamily: AppThemeData.semiBold,
//                               color: AppThemeData.grey900,
//                               fontSize: 13,
//                             ),
//                           ),
//
//                     const SizedBox(height: 2),
//
//                     // Address (small) + Wallet & Coins chips side by side
//                     Consumer2<AddressListProvider, HomeProvider>(
//                       builder:
//                           (
//                             context,
//                             addressListProvider,
//                             homeProviderConsumer,
//                             _,
//                           ) {
//                             return Row(
//                               children: [
//                                 // Small address tap
//                                 Flexible(
//                                   child: InkWell(
//                                     onTap: () async => _handleLocationTap(
//                                       context: context,
//                                       addressListProvider: addressListProvider,
//                                       homeProvider: homeProvider,
//                                     ),
//                                     child: Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         Flexible(
//                                           child: Text(
//                                             Constant.selectedLocation
//                                                 .getFullAddress(),
//                                             maxLines: 1,
//                                             overflow: TextOverflow.ellipsis,
//                                             style: TextStyle(
//                                               fontFamily: AppThemeData.medium,
//                                               color: AppThemeData.grey600,
//                                               fontSize: 10,
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(width: 2),
//                                         SvgPicture.asset(
//                                           'assets/icons/ic_down.svg',
//                                           width: 8,
//                                           height: 8,
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//
//                                 const SizedBox(width: 6),
//
//                                 // Wallet + Coins chips inline
//                                 const _HomeWalletCoinsRow(),
//                               ],
//                             );
//                           },
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     ],
//   );
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // Location tap handler (unchanged logic)
// // ─────────────────────────────────────────────────────────────────────────────
//
// Future<void> _handleLocationTap({
//   required BuildContext context,
//   required AddressListProvider addressListProvider,
//   required HomeProvider homeProvider,
// }) async {
//   if (Constant.userModel != null) {
//     addressListProvider.initFunction(context: context);
//     final value = await Get.to(const AddressListScreen());
//     if (value != null) {
//       homeProvider.changeLocationAddressFunction(
//         addressModel: value,
//         context: context,
//       );
//     }
//   } else {
//     Constant.checkPermission(
//       context: context,
//       onTap: () async {
//         ShowToastDialog.showLoader('Please wait'.tr);
//         final ShippingAddress addressModel = ShippingAddress();
//         try {
//           await Geolocator.requestPermission();
//           await Geolocator.getCurrentPosition();
//           ShowToastDialog.closeLoader();
//
//           if (Constant.selectedMapType == 'osm') {
//             final result = await Get.to(() => MapPickerPage());
//             if (result != null) {
//               addressModel
//                 ..addressAs = 'Home'
//                 ..locality = result.address.toString()
//                 ..address = result.address.toString()
//                 ..location = UserLocation(
//                   latitude: result.coordinates.latitude,
//                   longitude: result.coordinates.longitude,
//                 );
//               homeProvider.changeLocationAddressFunction(
//                 addressModel: addressModel,
//                 context: context,
//               );
//               Get.back();
//             }
//           } else {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => PlacePicker(
//                   apiKey: Constant.mapAPIKey,
//                   onPlacePicked: (result) async {
//                     final ShippingAddress model = ShippingAddress()
//                       ..addressAs = 'Home'
//                       ..locality = result.formattedAddress!
//                       ..address = result.formattedAddress!
//                       ..location = UserLocation(
//                         latitude: result.geometry!.location.lat,
//                         longitude: result.geometry!.location.lng,
//                       );
//                     homeProvider.changeLocationAddressFunction(
//                       addressModel: model,
//                       context: context,
//                     );
//                     Get.back();
//                   },
//                   initialPosition: const LatLng(-33.8567844, 151.213108),
//                   useCurrentLocation: true,
//                   selectInitialPosition: true,
//                   usePinPointingSearch: true,
//                   usePlaceDetailSearch: true,
//                   zoomGesturesEnabled: true,
//                   zoomControlsEnabled: true,
//                   resizeToAvoidBottomInset: false,
//                 ),
//               ),
//             );
//           }
//         } catch (e) {
//           debugPrint('placemarkFromCoordinates $e');
//           await placemarkFromCoordinates(19.228825, 72.854118).then((places) {
//             final Placemark p = places[0];
//             addressModel
//               ..addressAs = 'Home'
//               ..location = UserLocation(
//                 latitude: 19.228825,
//                 longitude: 72.854118,
//               )
//               ..locality =
//                   '${p.name}, ${p.subLocality}, ${p.locality}, ${p.administrativeArea}, ${p.postalCode}, ${p.country}'
//               ..address = addressModel.locality!;
//           });
//           ShowToastDialog.closeLoader();
//           homeProvider.changeLocationAddressFunction(
//             addressModel: addressModel,
//             context: context,
//           );
//         }
//       },
//     );
//   }
// }
//
// // ─────────────────────────────────────────────────────────────────────────────
// // Wallet + Coins row (below address)
// // ─────────────────────────────────────────────────────────────────────────────
//
// class _HomeWalletCoinsRow extends StatefulWidget {
//   const _HomeWalletCoinsRow();
//
//   @override
//   State<_HomeWalletCoinsRow> createState() => _HomeWalletCoinsRowState();
// }
//
// class _HomeWalletCoinsRowState extends State<_HomeWalletCoinsRow> {
//   bool _loadedOnce = false;
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (!_loadedOnce && Constant.userModel != null) {
//       _loadedOnce = true;
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (mounted) context.read<WalletProvider>().refreshWallet();
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<WalletProvider>(
//       builder: (context, wp, _) {
//         if (Constant.userModel == null) return const SizedBox.shrink();
//
//         final coins = wp.coinBalance;
//         final rupees = wp.moneyBalanceRupees;
//         final loading = wp.loadingWallet;
//
//         return Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _WalletChip(
//               icon: Icons.monetization_on_rounded,
//               iconColor: AppThemeData.warning400,
//               label: loading ? '...' : '$coins ',
//               onTap: () => Get.to(() => const WalletHomeScreen()),
//             ),
//             const SizedBox(width: 4),
//             _WalletChip(
//               icon: Icons.account_balance_wallet_rounded,
//               iconColor: AppThemeData.success400,
//               label: loading
//                   ? '...'
//                   : '₹${rupees == rupees.truncateToDouble() ? rupees.toInt() : rupees.toStringAsFixed(1)}',
//               onTap: () => Get.to(() => const WalletHomeScreen()),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
//
// class _WalletChip extends StatelessWidget {
//   final IconData icon;
//   final Color iconColor;
//   final String label;
//   final VoidCallback onTap;
//
//   const _WalletChip({
//     required this.icon,
//     required this.iconColor,
//     required this.label,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(50),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//           decoration: BoxDecoration(
//             color: AppThemeData.grey100,
//             borderRadius: BorderRadius.circular(50),
//             border: Border.all(color: AppThemeData.grey200, width: 1),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(icon, size: 14, color: iconColor),
//               const SizedBox(width: 4),
//               Text(
//                 label,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   fontFamily: AppThemeData.semiBold,
//                   fontSize: 11,
//                   color: AppThemeData.grey800,
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
// // ─────────────────────────────────────────────────────────────────────────────
// // Profile avatar (unchanged)
// // ─────────────────────────────────────────────────────────────────────────────
//
// Widget buildProfileAvatar() {
//   final user = Constant.userModel;
//   final hasProfileImage =
//       user != null &&
//       user.profilePictureURL != null &&
//       user.profilePictureURL!.isNotEmpty &&
//       user.profilePictureURL!.toLowerCase() != 'null';
//
//   if (hasProfileImage) {
//     return CircleAvatar(
//       radius: 18,
//       backgroundColor: AppThemeData.primary300,
//       backgroundImage: NetworkImage(user.profilePictureURL!),
//     );
//   } else {
//     return InitialsAvatar(
//       firstName: user?.firstName,
//       lastName: user?.lastName,
//       radius: 18,
//       backgroundColor: AppThemeData.primary300,
//       textColor: Colors.white,
//     );
//   }
// }
