import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/address_screens/address_list_screen.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/services/group_order_api_service.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:provider/provider.dart';

import 'GroupOrderDashboardScreen.dart';

class JoinGroupOrderScreen extends StatefulWidget {
  final int groupOrdersInvitationId;
  final String invitationCode;
  final VendorModel? restaurant;

  const JoinGroupOrderScreen({
    super.key,
    required this.groupOrdersInvitationId,
    required this.invitationCode,
    this.restaurant,
  });

  @override
  State<JoinGroupOrderScreen> createState() => _JoinGroupOrderScreenState();
}

class _JoinGroupOrderScreenState extends State<JoinGroupOrderScreen> {
  List<ShippingAddress> _addresses = [];
  ShippingAddress? _selectedAddress;
  bool _isLoading = true;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAddresses());
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);

    try {
      final addressProvider = Provider.of<AddressListProvider>(
        context,
        listen: false,
      );
      await addressProvider.initFunction(context: context, forceRefresh: true);

      final fromProvider = addressProvider.shippingAddressList;
      final fromUser = Constant.userModel?.shippingAddress ?? <ShippingAddress>[];

      final merged = <ShippingAddress>[
        ...fromProvider,
        ...fromUser.where(
          (a) => !fromProvider.any((p) => p.id != null && p.id == a.id),
        ),
      ];

      ShippingAddress? defaultAddress;
      if (merged.isNotEmpty) {
        defaultAddress = merged.firstWhere(
          (a) => a.isDefault == true,
          orElse: () => merged.first,
        );
      }

      if (!mounted) return;
      setState(() {
        _addresses = merged;
        _selectedAddress = defaultAddress;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  int? _deliveryAddressIdFor(ShippingAddress address) {
    return int.tryParse(address.id ?? '');
  }

  String _addressLabel(ShippingAddress address) {
    final title = address.addressAs?.trim();
    final line = [
      address.address,
      address.locality,
      address.landmark,
    ].where((e) => e != null && e.trim().isNotEmpty).join(', ');
    if (title != null && title.isNotEmpty) {
      return '$title · $line';
    }
    return line.isEmpty ? 'Saved address' : line;
  }

  Future<void> _pickAddressFromList() async {
    final selected = await Get.to<ShippingAddress?>(
      () => const AddressListScreen(),
    );
    if (selected != null) {
      setState(() => _selectedAddress = selected);
    }
    await _loadAddresses();
  }

  Future<void> _joinGroup({bool isDropped = false}) async {
    if (_isJoining) return;

    final customerId = int.tryParse(await SqlStorageConst.getUserId() ?? '');
    if (customerId == null) {
      ShowToastDialog.showToast('Please log in to join the group');
      return;
    }

    if (!isDropped) {
      if (_selectedAddress == null) {
        ShowToastDialog.showToast('Please select a delivery address');
        return;
      }

      final deliveryAddressId = _deliveryAddressIdFor(_selectedAddress!);
      if (deliveryAddressId == null) {
        ShowToastDialog.showToast(
          'Please add a valid delivery address before joining',
        );
        await _pickAddressFromList();
        return;
      }
    }

    final deliveryAddressId = isDropped
        ? int.tryParse(_selectedAddress?.id ?? '') ?? 0
        : _deliveryAddressIdFor(_selectedAddress!)!;

    setState(() => _isJoining = true);
    ShowToastDialog.showLoader(isDropped ? 'Leaving group...' : 'Joining group...');

    try {
      final result = await GroupOrderApiService.joinGroupMembers(
        groupOrdersInvitationId: widget.groupOrdersInvitationId,
        customerId: customerId,
        deliveryAddressId: deliveryAddressId,
        invitationCode: widget.invitationCode,
        createdBy: customerId,
        isDropped: isDropped,
      );

      ShowToastDialog.closeLoader();
      if (!mounted) return;
      setState(() => _isJoining = false);

      if (result == null || !result.success) {
        ShowToastDialog.showToast(
          result?.statusMsg ?? 'Failed to join group order',
        );
        return;
      }

      ShowToastDialog.showToast(result.statusMsg);

      if (isDropped) {
        Get.back();
        return;
      }

      if (widget.restaurant == null) {
        Get.back(result: true);
        return;
      }

      Get.off(
        () => GroupOrderDashboardScreen(
          groupCode: widget.invitationCode,
          restaurant: widget.restaurant!,
          groupOrdersInvitationId: widget.groupOrdersInvitationId,
          deliveryAddressId: deliveryAddressId,
        ),
      );
    } catch (_) {
      ShowToastDialog.closeLoader();
      if (mounted) setState(() => _isJoining = false);
      ShowToastDialog.showToast('Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppThemeData.grey900,
            size: 18,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Join Group Order',
          style: TextStyle(
            fontFamily: AppThemeData.extraBold,
            color: AppThemeData.grey900,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildGroupInfoCard(),
                const SizedBox(height: 20),
                Text(
                  'Select delivery address',
                  style: TextStyle(
                    fontFamily: AppThemeData.semiBold,
                    color: AppThemeData.grey900,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your order will be delivered to this address.',
                  style: TextStyle(
                    fontFamily: AppThemeData.medium,
                    color: AppThemeData.grey500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                if (_addresses.isEmpty)
                  _buildEmptyAddressState()
                else
                  ..._addresses.map(_buildAddressTile),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isJoining ? null : _pickAddressFromList,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Add or choose address'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6B2C),
                    side: const BorderSide(color: Color(0xFFFFCBA8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B2C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isJoining ? null : () => _joinGroup(),
                    child: Text(
                      _isJoining ? 'Joining...' : 'Join Group',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGroupInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group code',
            style: TextStyle(
              fontFamily: AppThemeData.medium,
              color: AppThemeData.grey500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.invitationCode,
            style: TextStyle(
              fontFamily: AppThemeData.extraBold,
              color: AppThemeData.grey900,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          if (widget.restaurant?.title != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.restaurant!.title!,
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                color: AppThemeData.grey800,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyAddressState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEF2)),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off_outlined, color: AppThemeData.grey400, size: 36),
          const SizedBox(height: 8),
          Text(
            'No delivery address found',
            style: TextStyle(
              fontFamily: AppThemeData.semiBold,
              color: AppThemeData.grey800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add an address to join this group order.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppThemeData.medium,
              color: AppThemeData.grey500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTile(ShippingAddress address) {
    final selected = _selectedAddress?.id == address.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isJoining ? null : () => setState(() => _selectedAddress = address),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFFFF6B2C)
                    : const Color(0xFFEEEEF2),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected
                      ? const Color(0xFFFF6B2C)
                      : AppThemeData.grey400,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _addressLabel(address),
                    style: TextStyle(
                      fontFamily: AppThemeData.medium,
                      color: AppThemeData.grey900,
                      fontSize: 13.5,
                    ),
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

Future<void> openJoinGroupOrderFromLink({
  required int groupOrdersInvitationId,
  required String invitationCode,
  VendorModel? restaurant,
}) async {
  await Get.to(
    () => JoinGroupOrderScreen(
      groupOrdersInvitationId: groupOrdersInvitationId,
      invitationCode: invitationCode,
      restaurant: restaurant,
    ),
  );
}
