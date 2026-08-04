import 'GroupCheckoutItem.dart';

class DeliveryCheckoutItem {
  final double deliveryDistanceKm;
  final double deliveryCharge;
  final double taxAmount;
  final double totalDeliveryCharge;
  final double itemsTotal;
  final double foodTax;
  final int deliveryAddressId;
  final List<GroupCheckoutItem> groupOrderCheckoutItems;

  DeliveryCheckoutItem({
    required this.deliveryDistanceKm,
    required this.deliveryCharge,
    required this.taxAmount,
    required this.totalDeliveryCharge,
    required this.itemsTotal,
    required this.foodTax,
    required this.deliveryAddressId,
    required this.groupOrderCheckoutItems,
  });

  factory DeliveryCheckoutItem.fromJson(Map<String, dynamic> json) {
    return DeliveryCheckoutItem(
      deliveryDistanceKm: (json["deliveryDistanceKm"] ?? 0).toDouble(),
      deliveryCharge: (json["deliveryCharge"] ?? 0).toDouble(),
      taxAmount: (json["taxAmount"] ?? 0).toDouble(),
      totalDeliveryCharge: (json["totalDeliveryCharge"] ?? 0).toDouble(),
      itemsTotal: (json["itemsTotal"] ?? 0).toDouble(),
      foodTax: (json["foodTax"] ?? 0).toDouble(),
      deliveryAddressId: json["deliveryAddressId"],
      groupOrderCheckoutItems: (json["groupOrderCheckoutItemsDtoList"] as List)
          .map((e) => GroupCheckoutItem.fromJson(e))
          .toList(),
    );
  }
}
