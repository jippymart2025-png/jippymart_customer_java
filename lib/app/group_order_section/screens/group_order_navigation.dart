import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/group_order_invitation_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/services/group_order_session.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';

import '../../Communityscreen/screens/community_list_screen.dart';
import '../service/group_order_api_service.dart';
import 'GroupOrderDashboardScreen.dart';
import 'create_group_order.dart';

VendorModel resolveGroupOrderRestaurant(int outletId) {
  final cached = Constant.restaurantList ?? <VendorModel>[];
  for (final vendor in cached) {
    if (int.tryParse(vendor.id ?? '') == outletId) {
      return vendor;
    }
  }

  return VendorModel(
    id: outletId.toString(),
    title: 'Restaurant',
    isActive: true,
    vType: 'restaurant',
  );
}

bool _isActiveInvitation(GroupOrderInvitationModel? invitation) {
  return invitation != null &&
      invitation.groupOrdersInvitationId > 0 &&
      invitation.invitationCode.isNotEmpty &&
      invitation.status.toUpperCase() == 'ACTIVE';
}

Future<void> openGroupOrderFlow({String orderType = 'GROUP_ORDER'}) async {
  final customerId = int.tryParse(await SqlStorageConst.getUserId() ?? '');
  if (customerId == null) {
    ShowToastDialog.showToast('Please log in to start a group order');
    return;
  }

  ShowToastDialog.showLoader('Loading group order...');

  try {
    final invitation = await GroupOrderApiService.getGroupOrderInvitation(
      hostCustomerId: customerId,
    );

    ShowToastDialog.closeLoader();

    if (_isActiveInvitation(invitation)) {
      final activeInvitation = invitation!;
      final restaurant = resolveGroupOrderRestaurant(activeInvitation.outletId);

      await Get.to(
        () => GroupOrderDashboardScreen(
          groupCode: activeInvitation.invitationCode,
          restaurant: restaurant,
          groupOrdersInvitationId: activeInvitation.groupOrdersInvitationId,
          hostCustomerId: activeInvitation.hostCustomerId,
        ),
      );
      return;
    }

    GroupOrderSession.instance.clear();
    await Get.to(() => CreateGroupOrderScreen(orderType: orderType));
  } catch (e) {
    ShowToastDialog.closeLoader();

    debugPrint('Group order invitation failed: $e');

    GroupOrderSession.instance.clear();
    await Get.to(() => CreateGroupOrderScreen(orderType: orderType));
  }
}

Future<void> openHomeMadeMeals() async {
  await Get.to(() => const CommunityListScreen());
}
