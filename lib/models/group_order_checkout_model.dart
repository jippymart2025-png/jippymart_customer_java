class GroupOrderCheckoutModel {
  final int groupOrdersInvitationId;
  final double platformFee;
  final double surgeFee;
  final double packagingFee;
  final double totalNetAmount;
  final List<DeliveryCheckOutItem> deliveryCheckOutItems;

  GroupOrderCheckoutModel({
    required this.groupOrdersInvitationId,
    required this.platformFee,
    required this.surgeFee,
    required this.packagingFee,
    required this.totalNetAmount,
    required this.deliveryCheckOutItems,
  });

  factory GroupOrderCheckoutModel.fromJson(Map<String, dynamic> json) {
    final deliveryItems = json['deliveryCheckOutItemsDtoList'];
    return GroupOrderCheckoutModel(
      groupOrdersInvitationId:
          (json['groupOrdersInvitationId'] as num?)?.toInt() ?? 0,
      platformFee: _toDouble(json['platformFee']),
      surgeFee: _toDouble(json['surgeFee']),
      packagingFee: _toDouble(json['packagingFee']),
      totalNetAmount: _toDouble(json['totalNetAmount']),
      deliveryCheckOutItems: deliveryItems is List
          ? deliveryItems
              .whereType<Map>()
              .map((e) => DeliveryCheckOutItem.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : [],
    );
  }

  int get totalProductCount {
    var count = 0;
    for (final delivery in deliveryCheckOutItems) {
      for (final member in delivery.groupOrderCheckoutItems) {
        for (final product in member.products) {
          count += product.quantity;
        }
      }
    }
    return count;
  }

  int get memberCount {
    final ids = <int>{};
    for (final delivery in deliveryCheckOutItems) {
      for (final member in delivery.groupOrderCheckoutItems) {
        ids.add(member.customerId);
      }
    }
    return ids.length;
  }
}

class DeliveryCheckOutItem {
  final double deliveryDistanceKm;
  final double deliveryCharge;
  final double taxAmount;
  final double totalDeliveryCharge;
  final double itemsTotal;
  final double foodTax;
  final int deliveryAddressId;
  final List<GroupOrderCheckoutMember> groupOrderCheckoutItems;

  DeliveryCheckOutItem({
    required this.deliveryDistanceKm,
    required this.deliveryCharge,
    required this.taxAmount,
    required this.totalDeliveryCharge,
    required this.itemsTotal,
    required this.foodTax,
    required this.deliveryAddressId,
    required this.groupOrderCheckoutItems,
  });

  factory DeliveryCheckOutItem.fromJson(Map<String, dynamic> json) {
    final members = json['groupOrderCheckoutItemsDtoList'];
    return DeliveryCheckOutItem(
      deliveryDistanceKm: _toDouble(json['deliveryDistanceKm']),
      deliveryCharge: _toDouble(json['deliveryCharge']),
      taxAmount: _toDouble(json['taxAmount']),
      totalDeliveryCharge: _toDouble(json['totalDeliveryCharge']),
      itemsTotal: _toDouble(json['itemsTotal']),
      foodTax: _toDouble(json['foodTax']),
      deliveryAddressId: (json['deliveryAddressId'] as num?)?.toInt() ?? 0,
      groupOrderCheckoutItems: members is List
          ? members
              .whereType<Map>()
              .map((e) => GroupOrderCheckoutMember.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : [],
    );
  }
}

class GroupOrderCheckoutMember {
  final int customerId;
  final String customerName;
  final double amountToPay;
  final List<GroupOrderCheckoutProduct> products;

  GroupOrderCheckoutMember({
    required this.customerId,
    required this.customerName,
    required this.amountToPay,
    required this.products,
  });

  factory GroupOrderCheckoutMember.fromJson(Map<String, dynamic> json) {
    final products = json['productsList'];
    return GroupOrderCheckoutMember(
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      customerName: json['customerName']?.toString() ?? '',
      amountToPay: _toDouble(json['amountToPay']),
      products: products is List
          ? products
              .whereType<Map>()
              .map((e) => GroupOrderCheckoutProduct.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : [],
    );
  }
}

class GroupOrderCheckoutProduct {
  final int productId;
  final String productName;
  final double onlinePrice;
  final int quantity;

  GroupOrderCheckoutProduct({
    required this.productId,
    required this.productName,
    required this.onlinePrice,
    required this.quantity,
  });

  factory GroupOrderCheckoutProduct.fromJson(Map<String, dynamic> json) {
    return GroupOrderCheckoutProduct(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      productName: json['productName']?.toString() ?? '',
      onlinePrice: _toDouble(json['onlinePrice']),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
