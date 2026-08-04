import 'DeliveryCheckoutItem.dart';

class GroupOrderCheckoutModel {
  final int groupOrdersInvitationId;
  final double platformFee;
  final double surgeFee;
  final double packagingFee;
  final double totalNetAmount;
  final List<DeliveryCheckoutItem> deliveryCheckOutItems;

  GroupOrderCheckoutModel({
    required this.groupOrdersInvitationId,
    required this.platformFee,
    required this.surgeFee,
    required this.packagingFee,
    required this.totalNetAmount,
    required this.deliveryCheckOutItems,
  });

  factory GroupOrderCheckoutModel.fromJson(Map<String, dynamic> json) {
    return GroupOrderCheckoutModel(
      groupOrdersInvitationId: json["groupOrdersInvitationId"],
      platformFee: (json["platformFee"] ?? 0).toDouble(),
      surgeFee: (json["surgeFee"] ?? 0).toDouble(),
      packagingFee: (json["packagingFee"] ?? 0).toDouble(),
      totalNetAmount: (json["totalNetAmount"] ?? 0).toDouble(),
      deliveryCheckOutItems: (json["deliveryCheckOutItemsDtoList"] as List)
          .map((e) => DeliveryCheckoutItem.fromJson(e))
          .toList(),
    );
  }
}
