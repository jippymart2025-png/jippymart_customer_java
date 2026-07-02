class CustomerCartItemModel {
  final int productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double totalPrice;

  const CustomerCartItemModel({
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.totalPrice,
  });

  factory CustomerCartItemModel.fromJson(Map<String, dynamic> json) {
    return CustomerCartItemModel(
      productId: json['productId'] is int
          ? json['productId'] as int
          : int.tryParse(json['productId']?.toString() ?? '') ?? 0,
      productName: json['productName']?.toString() ?? '',
      productImage: json['productImage']?.toString(),
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      totalPrice: json['totalPrice'] is num
          ? (json['totalPrice'] as num).toDouble()
          : double.tryParse(json['totalPrice']?.toString() ?? '') ?? 0,
    );
  }
}

class CustomerCartModel {
  final int customerId;
  final List<CustomerCartItemModel> items;
  final double grandTotal;

  const CustomerCartModel({
    required this.customerId,
    required this.items,
    required this.grandTotal,
  });

  factory CustomerCartModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map(
              (item) => CustomerCartItemModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <CustomerCartItemModel>[];

    return CustomerCartModel(
      customerId: json['customerId'] is int
          ? json['customerId'] as int
          : int.tryParse(json['customerId']?.toString() ?? '') ?? 0,
      items: items,
      grandTotal: json['grandTotal'] is num
          ? (json['grandTotal'] as num).toDouble()
          : double.tryParse(json['grandTotal']?.toString() ?? '') ?? 0,
    );
  }
}
