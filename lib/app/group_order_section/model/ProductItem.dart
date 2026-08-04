class ProductItem {
  final int productId;
  final String productName;
  final double onlinePrice;
  final int quantity;

  ProductItem({
    required this.productId,
    required this.productName,
    required this.onlinePrice,
    required this.quantity,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      productId: json["productId"],
      productName: json["productName"],
      onlinePrice: (json["onlinePrice"] ?? 0).toDouble(),
      quantity: json["quantity"],
    );
  }
}
