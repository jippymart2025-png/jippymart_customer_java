import 'package:get/get.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/group_order_invitation_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/app/home_screen/screen/group_order_section/service/group_order_api_service.dart';
import 'package:jippymart_customer/services/group_order_session.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';

import '../../../../Communityscreen/screens/community_home_screen.dart';

import 'GroupOrderDashboardScreen.dart';
import 'InviteFriendsScreen.dart';
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

Future<void> openGroupOrderFlow() async {
  final customerId = int.tryParse(await SqlStorageConst.getUserId() ?? '');
  if (customerId == null) {
    ShowToastDialog.showToast('Please log in to start a group order');
    return;
  }

  final session = GroupOrderSession.instance;
  if (session.isActive &&
      session.groupCode != null &&
      session.restaurant != null &&
      session.groupOrdersInvitationId != null &&
      session.hostCustomerId != null) {
    await Get.to(
      () => GroupOrderDashboardScreen(
        groupCode: session.groupCode!,
        restaurant: session.restaurant!,
        groupOrdersInvitationId: session.groupOrdersInvitationId!,
        hostCustomerId: session.hostCustomerId!,
        deliveryAddressId: session.deliveryAddressId,
      ),
    );
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
      final groupLink =
          'https://jippymart.in/g/${activeInvitation.groupOrdersInvitationId}/${activeInvitation.invitationCode}/${activeInvitation.hostCustomerId}';

      await Get.to(
        () => InviteFriendsScreen(
          groupCode: activeInvitation.invitationCode,
          groupLink: groupLink,
          restaurant: restaurant,
          groupOrdersInvitationId: activeInvitation.groupOrdersInvitationId,
          hostCustomerId: activeInvitation.hostCustomerId,
        ),
      );
      return;
    }

    await Get.to(() => const CreateGroupOrderScreen());
  } catch (_) {
    ShowToastDialog.closeLoader();
    ShowToastDialog.showToast('Failed to load group order');
  }
}

Future<void> openHomeMadeMeals() async {
  await Get.to(() => const CommunityHomeScreen());
}
