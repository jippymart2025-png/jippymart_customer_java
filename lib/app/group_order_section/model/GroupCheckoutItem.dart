import 'ProductItem.dart';

class GroupCheckoutItem {
  final int customerId;
  final String customerName;
  final double amountToPay;
  final List<ProductItem> products;

  GroupCheckoutItem({
    required this.customerId,
    required this.customerName,
    required this.amountToPay,
    required this.products,
  });

  factory GroupCheckoutItem.fromJson(Map<String, dynamic> json) {
    return GroupCheckoutItem(
      customerId: json["customerId"],
      customerName: json["customerName"],
      amountToPay: (json["amountToPay"] ?? 0).toDouble(),
      products: (json["productsList"] as List)
          .map((e) => ProductItem.fromJson(e))
          .toList(),
    );
  }
}
