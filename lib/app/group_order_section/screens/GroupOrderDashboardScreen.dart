import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/models/group_order_checkout_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/services/group_order_session.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:provider/provider.dart';

import '../model/create_group_orders_model.dart';
import '../service/group_order_api_service.dart';
import '../widgets/buildActivityRow.dart';
import '../widgets/buildHeaderCard.dart';
import 'SharedCartScreen.dart';

class GroupOrderDashboardScreen extends StatefulWidget {
  final String groupCode;
  final VendorModel restaurant;
  final int groupOrdersInvitationId;
  final int hostCustomerId;
  final int? deliveryAddressId;

  const GroupOrderDashboardScreen({
    super.key,
    required this.groupCode,
    required this.restaurant,
    required this.groupOrdersInvitationId,
    required this.hostCustomerId,
    this.deliveryAddressId,
  });

  @override
  State<GroupOrderDashboardScreen> createState() =>
      _GroupOrderDashboardScreenState();
}

class _GroupOrderDashboardScreenState extends State<GroupOrderDashboardScreen> {
  Duration _remaining = const Duration(minutes: 12, seconds: 14);
  Timer? _timer;
  bool _isLeavingGroup = false;
  bool _isLoadingCheckout = true;
  GroupOrderCheckoutModel? _checkout;
  int _cartItemCount = 0;

  final List<String> _memberAvatars = [
    'https://i.pravatar.cc/100?img=1',
    'https://i.pravatar.cc/100?img=2',
    'https://i.pravatar.cc/100?img=3',
    'https://i.pravatar.cc/100?img=4',
  ];

  List<GroupActivityEvent> _activity = [];

  @override
  void initState() {
    super.initState();
    GroupOrderSession.instance.start(
      groupOrdersInvitationId: widget.groupOrdersInvitationId,
      hostCustomerId: widget.hostCustomerId,
      groupCode: widget.groupCode,
      restaurant: widget.restaurant,
      deliveryAddressId: widget.deliveryAddressId,
    );
    // _loadCheckout();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 0) {
        _timer?.cancel();
        return;
      }
      setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Future<void> _loadCheckout() async {
  //   setState(() => _isLoadingCheckout = true);
  //
  //   final checkout = await GroupOrderApiService.groupOrderCheckOut(
  //     groupOrdersInvitationId: widget.groupOrdersInvitationId,
  //     hostCustomerId: widget.hostCustomerId,
  //   );
  //
  //   if (!mounted) return;
  //
  //   final quantities = GroupOrderApiService.quantitiesFromCheckout(checkout);
  //   GroupOrderSession.instance.setQuantitiesFromCheckout(quantities);
  //
  //   setState(() {
  //     _checkout = checkout;
  //     _cartItemCount = checkout?.totalProductCount ?? 0;
  //     _activity = _buildActivityFromCheckout(checkout);
  //     _isLoadingCheckout = false;
  //   });
  // }

  List<GroupActivityEvent> _buildActivityFromCheckout(
    GroupOrderCheckoutModel? checkout,
  ) {
    if (checkout == null) return [];

    final events = <GroupActivityEvent>[];
    for (final delivery in checkout.deliveryCheckOutItems) {
      for (final member in delivery.groupOrderCheckoutItems) {
        for (final product in member.products) {
          events.add(
            GroupActivityEvent(
              memberName: member.customerName,
              avatarUrl: 'https://i.pravatar.cc/100?u=${member.customerId}',
              action: 'added',
              detail: product.productName,
              timeAgo: 'Recently',
            ),
          );
        }
      }
    }
    return events.take(10).toList();
  }

  void _openRestaurantMenu() async {
    final provider = context.read<RestaurantDetailsProvider>();
    await provider.initFunction(vendorModels: widget.restaurant);
    provider.setGroupOrderContext(
      groupOrderInvitationId: widget.groupOrdersInvitationId,
      hostCustomerId: widget.hostCustomerId,
      groupCode: widget.groupCode,
      restaurant: widget.restaurant,
      deliveryAddressId: widget.deliveryAddressId,
    );
    await Get.to(() => const RestaurantDetailsScreen());
    provider.clearGroupOrderContext();
    // await _loadCheckout();
  }

  Future<void> _openSharedCart() async {
    await Get.to(
      () => SharedCartScreen(
        groupOrdersInvitationId: widget.groupOrdersInvitationId,
        hostCustomerId: widget.hostCustomerId,
        initialCheckout: _checkout,
      ),
    );
    // await _loadCheckout();
  }

  Future<void> _leaveGroup() async {
    if (_isLeavingGroup) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave group?'),
        content: const Text(
          'You will be removed from this group order. You can join again using the group code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Leave',
              style: TextStyle(color: Color(0xFFE63950)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final customerId = int.tryParse(await SqlStorageConst.getUserId() ?? '');
    final deliveryAddressId = widget.deliveryAddressId;
    if (customerId == null || deliveryAddressId == null) {
      ShowToastDialog.showToast('Unable to leave group right now');
      return;
    }

    setState(() => _isLeavingGroup = true);
    ShowToastDialog.showLoader('Leaving group...');

    try {
      final result = await GroupOrderApiService.joinGroupMembers(
        groupOrdersInvitationId: widget.groupOrdersInvitationId,
        customerId: customerId,
        deliveryAddressId: deliveryAddressId,
        invitationCode: widget.groupCode,
        createdBy: customerId,
        isDropped: true,
      );

      ShowToastDialog.closeLoader();
      if (!mounted) return;
      setState(() => _isLeavingGroup = false);

      if (result == null || !result.success) {
        ShowToastDialog.showToast(result?.statusMsg ?? 'Failed to leave group');
        return;
      }

      GroupOrderSession.instance.clear();
      if (mounted) {
        context.read<RestaurantDetailsProvider>().clearGroupOrderContext();
      }
      ShowToastDialog.showToast(result.statusMsg);
      Get.back();
    } catch (_) {
      ShowToastDialog.closeLoader();
      if (mounted) setState(() => _isLeavingGroup = false);
      ShowToastDialog.showToast('Failed to leave group');
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    final memberCount = _checkout?.memberCount ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            GroupOrderHeaderCard(
              restaurant: widget.restaurant,
              groupCode: widget.groupCode,
              minutes: minutes,
              seconds: seconds,
              memberCount: memberCount,
              isLeavingGroup: _isLeavingGroup,
              memberAvatars: _memberAvatars,
              onLeaveGroup: _leaveGroup,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity',
                    style: TextStyle(
                      fontFamily: AppThemeData.semiBold,
                      color: AppThemeData.grey900,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_isLoadingCheckout)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_activity.isEmpty)
                    Text(
                      'No items added yet. Tap Add items to start ordering.',
                      style: TextStyle(
                        fontFamily: AppThemeData.medium,
                        color: AppThemeData.grey500,
                        fontSize: 13,
                      ),
                    )
                  else
                    ..._activity.map(buildActivityRow),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFFCBA8)),
                    backgroundColor: const Color(0xFFFFF1E6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _openRestaurantMenu,
                  child: const Text(
                    'Add items',
                    style: TextStyle(
                      color: Color(0xFFFF6B2C),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B2C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _openSharedCart,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'View Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (_cartItemCount > 0) ...[
                        const SizedBox(width: 6),
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.white,
                          child: Text(
                            '$_cartItemCount',
                            style: const TextStyle(
                              color: Color(0xFFFF6B2C),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
