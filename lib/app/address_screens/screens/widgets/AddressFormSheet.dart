import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart'
    show PlacePicker;
import 'package:jippymart_customer/app/address_screens/screens/widgets/tokan.dart';

import '../../../../constant/constant.dart';
import '../../../../models/user_model.dart';
import '../../../../themes/app_them_data.dart';
import '../../../../themes/text_field_widget.dart';
import '../../../../widget/osm_map/map_picker_page.dart';
import '../../provider/address_list_provider.dart';
import 'SaveAsChip.dart';
import 'SheetDragHandle.dart';

const kBrandGradient = LinearGradient(
  colors: [Tokens.gradStart, Tokens.gradMid, Tokens.gradEnd],
  stops: [0.0, 0.5, 1.0],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class AddressFormSheet extends ConsumerStatefulWidget {
  final AddressListProvider ctrl;
  final int? editIndex;

  const AddressFormSheet({super.key, required this.ctrl, this.editIndex});

  @override
  ConsumerState<AddressFormSheet> createState() => AddressFormSheetState();
}

class AddressFormSheetState extends ConsumerState<AddressFormSheet> {
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
            color: Tokens.card,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(Tokens.rXXL),
            ),
          ),
          child: Column(
            children: [
              SheetDragHandle(),
              Expanded(
                child: CustomScrollView(
                  controller: scrollCtrl,
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        Tokens.sp20,
                        Tokens.sp8,
                        Tokens.sp20,
                        Tokens.sp24,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildLocationPickerCard(),
                          const SizedBox(height: Tokens.sp24),
                          _buildSaveAsSection(),
                          const SizedBox(height: Tokens.sp24),
                          _buildFormFields(),
                          const SizedBox(height: Tokens.sp8),
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
        Tokens.sp20,
        Tokens.sp4,
        Tokens.sp12,
        Tokens.sp8,
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
                    horizontal: Tokens.sp10,
                    vertical: Tokens.sp4,
                  ),
                  decoration: BoxDecoration(
                    gradient: kBrandGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isEditing ? "EDITING".tr : "NEW ADDRESS".tr,
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
                  _isEditing ? "Edit address".tr : "Add a new address".tr,
                  style: const TextStyle(
                    fontSize: Tokens.textXXL,
                    color: Tokens.textPrimary,
                    fontFamily: AppThemeData.bold,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: Tokens.sp6),
                Text(
                  "Pin your exact location for faster, hassle-free deliveries."
                      .tr,
                  style: const TextStyle(
                    fontSize: Tokens.textSM,
                    height: 1.45,
                    color: Tokens.textMuted,
                    fontFamily: AppThemeData.regular,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Tokens.sp8),
          // Close button
          Material(
            color: Tokens.chipBg,
            borderRadius: BorderRadius.circular(50),
            child: InkWell(
              onTap: Get.back,
              borderRadius: BorderRadius.circular(50),
              child: const Padding(
                padding: EdgeInsets.all(Tokens.sp8),
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Tokens.textSecondary,
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
        padding: const EdgeInsets.all(Tokens.sp16),
        decoration: BoxDecoration(
          color: hasLocation ? Tokens.orangeChip : Tokens.chipBg,
          borderRadius: BorderRadius.circular(Tokens.rXL),
          border: Border.all(
            color: hasLocation ? Tokens.selectedBorder : Tokens.cardBorder,
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
                gradient: hasLocation ? kBrandGradient : null,
                color: hasLocation ? null : Tokens.card,
                borderRadius: BorderRadius.circular(Tokens.rMD),
                boxShadow: Tokens.cardShadow,
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
                      color: hasLocation ? Colors.white : Tokens.mutedIcon,
                      size: 22,
                    ),
            ),

            const SizedBox(width: Tokens.sp14),

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
                      fontSize: Tokens.textMD,
                      color: hasLocation
                          ? Tokens.orangeChipText
                          : Tokens.textPrimary,
                      fontFamily: AppThemeData.semiBold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Tokens.sp4),
                  Text(
                    _isPickingLocation
                        ? "Just a moment…".tr
                        : hasLocation
                        ? _ctrl.localityEditingController.text
                        : "Tap to pin your exact address on the map.".tr,
                    style: TextStyle(
                      fontSize: Tokens.textSM,
                      height: 1.4,
                      color: hasLocation
                          ? Tokens.textSecondary
                          : Tokens.textMuted,
                      fontFamily: AppThemeData.regular,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: Tokens.sp8),
            Icon(Icons.chevron_right_rounded, color: Tokens.mutedIcon),
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
            fontSize: Tokens.textMD,
            color: Tokens.textPrimary,
            fontFamily: AppThemeData.semiBold,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: Tokens.sp4),
        const Text(
          "Pick a label to recognise this address quickly.",
          style: TextStyle(
            fontSize: Tokens.textSM,
            color: Tokens.textMuted,
            fontFamily: AppThemeData.regular,
          ),
        ),
        const SizedBox(height: Tokens.sp14),
        Wrap(
          spacing: Tokens.sp10,
          runSpacing: Tokens.sp10,
          children: _ctrl.saveAsList.map<Widget>((dynamic value) {
            final type = value.toString();
            final selected = _ctrl.selectedSaveAs == type;
            return SaveAsChip(
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
          fillColor: Tokens.chipBg,
        ),
        const SizedBox(height: Tokens.sp16),
        TextFieldWidget(
          title: 'Apartment / Road / Area',
          hintText: 'Pin a location on the map',
          controller: _ctrl.localityEditingController,
          readOnly: true,
          fillColor: Tokens.chipBg,
          suffix: IconButton(
            onPressed: _pickLocation,
            icon: Icon(
              Icons.location_on_rounded,
              color: AppThemeData.primary300,
            ),
          ),
        ),
        const SizedBox(height: Tokens.sp16),
        TextFieldWidget(
          title: 'Nearby landmark (Optional)',
          hintText: 'Landmark for easier delivery',
          controller: _ctrl.landmarkEditingController,
          textInputAction: TextInputAction.done,
          fillColor: Tokens.chipBg,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Tokens.sp20,
          Tokens.sp12,
          Tokens.sp20,
          Tokens.sp20,
        ),
        child: SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: _isEditing ? "Update Address".tr : "Save Address".tr,
            icon: _isEditing
                ? Icons.check_circle_outline_rounded
                : Icons.save_alt_rounded,
            onTap: _ctrl.isLoading
                ? null
                : () async {
                    final idx = widget.editIndex ?? -1;

                    await _ctrl.saveAddressFunction(idx, context, _ctrl);
                  },
          ),
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

class GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const GradientButton({
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
            gradient: kBrandGradient,
            borderRadius: BorderRadius.circular(50),
            // boxShadow: [
            //   BoxShadow(
            //     color: Tokens.gradStart.withOpacity(0.32),
            //     blurRadius: 18,
            //     offset: const Offset(0, 8),
            //   ),
            // ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Tokens.sp24,
              vertical: Tokens.sp14,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: Tokens.sp8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: Tokens.textMD,
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
