import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/provider/restaurant_details_provider.dart';
import 'package:jippymart_customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:jippymart_customer/models/group_order_checkout_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/services/group_order_api_service.dart';
import 'package:jippymart_customer/services/group_order_session.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:provider/provider.dart';

import 'SharedCartScreen.dart';
import 'create_group_orders_model.dart';

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
    _loadCheckout();
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

  Future<void> _loadCheckout() async {
    setState(() => _isLoadingCheckout = true);

    final checkout = await GroupOrderApiService.groupOrderCheckOut(
      groupOrdersInvitationId: widget.groupOrdersInvitationId,
      hostCustomerId: widget.hostCustomerId,
    );

    if (!mounted) return;

    final quantities =
        GroupOrderApiService.quantitiesFromCheckout(checkout);
    GroupOrderSession.instance.setQuantitiesFromCheckout(quantities);

    setState(() {
      _checkout = checkout;
      _cartItemCount = checkout?.totalProductCount ?? 0;
      _activity = _buildActivityFromCheckout(checkout);
      _isLoadingCheckout = false;
    });
  }

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

  String _two(int n) => n.toString().padLeft(2, '0');

  void _openRestaurantMenu() async {
    final provider = context.read<RestaurantDetailsProvider>();
    provider.setGroupOrderContext(
      groupOrderInvitationId: widget.groupOrdersInvitationId,
      hostCustomerId: widget.hostCustomerId,
      groupCode: widget.groupCode,
      restaurant: widget.restaurant,
      deliveryAddressId: widget.deliveryAddressId,
    );
    await provider.initFunction(vendorModels: widget.restaurant);
    await Get.to(() => const RestaurantDetailsScreen());
    await _loadCheckout();
  }

  Future<void> _openSharedCart() async {
    await Get.to(
      () => SharedCartScreen(
        groupOrdersInvitationId: widget.groupOrdersInvitationId,
        hostCustomerId: widget.hostCustomerId,
        initialCheckout: _checkout,
      ),
    );
    await _loadCheckout();
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
        child: RefreshIndicator(
          onRefresh: _loadCheckout,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHeaderCard(minutes, seconds, memberCount),
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
                      ..._activity.map(_buildActivityRow),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
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

  Widget _buildHeaderCard(int minutes, int seconds, int memberCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF5A5F), Color(0xFFE63950)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🎉 ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            widget.restaurant.title ?? 'Group Order',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Group ID: ${widget.groupCode}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: _isLeavingGroup ? null : () => Get.back(),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                onSelected: (value) {
                  if (value == 'leave') _leaveGroup();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'leave',
                    child: Text('Leave group'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                height: 28,
                width: _memberAvatars.length * 18 + 14,
                child: Stack(
                  children: [
                    for (int i = 0; i < _memberAvatars.length; i++)
                      Positioned(
                        left: i * 18.0,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 13,
                            backgroundImage: NetworkImage(_memberAvatars[i]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                memberCount > 0 ? '$memberCount members' : 'Group members',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text(
                  'Order closes in',
                  style: TextStyle(
                    fontFamily: AppThemeData.semiBold,
                    color: AppThemeData.grey900,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                _timeBox(_two(minutes), 'min'),
                const SizedBox(width: 6),
                Text(
                  ':',
                  style: TextStyle(
                    color: AppThemeData.grey900,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 6),
                _timeBox(_two(seconds), 'sec'),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, color: AppThemeData.grey500),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeBox(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppThemeData.grey900,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppThemeData.grey500, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildActivityRow(GroupActivityEvent e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 17, backgroundImage: NetworkImage(e.avatarUrl)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  color: AppThemeData.grey800,
                  fontSize: 13.5,
                ),
                children: [
                  TextSpan(
                    text: '${e.memberName} ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: '${e.action} '),
                  TextSpan(
                    text: e.detail,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          Text(
            e.timeAgo,
            style: TextStyle(
              fontFamily: AppThemeData.medium,
              color: e.isLive ? const Color(0xFF2EBD59) : AppThemeData.grey500,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
