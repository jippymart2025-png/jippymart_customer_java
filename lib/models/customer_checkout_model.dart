import 'package:jippymart_customer/models/customer_cart_model.dart';

class CustomerCheckoutModel {
  final List<CustomerCartItemModel> items;
  final double itemTotal;
  final double deliveryCharge;
  final double platformFee;
  final double surgeFee;
  final double packagingFee;
  final double foodTax;
  final double deliveryTax;
  final double taxesAndCharges;
  final double couponDiscount;
  final double deliveryTip;
  final double toPay;
  final bool codAvailable;
  final String? message;

  const CustomerCheckoutModel({
    required this.items,
    required this.itemTotal,
    required this.deliveryCharge,
    required this.platformFee,
    required this.surgeFee,
    required this.packagingFee,
    required this.foodTax,
    required this.deliveryTax,
    required this.taxesAndCharges,
    required this.couponDiscount,
    required this.deliveryTip,
    required this.toPay,
    required this.codAvailable,
    this.message,
  });

  factory CustomerCheckoutModel.fromJson(Map<String, dynamic> json) {
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

    return CustomerCheckoutModel(
      items: items,
      itemTotal: _toDouble(json['itemTotal']),
      deliveryCharge: _toDouble(json['deliveryCharge']),
      platformFee: _toDouble(json['platformFee']),
      surgeFee: _toDouble(json['surgeFee']),
      packagingFee: _toDouble(json['packagingFee']),
      foodTax: _toDouble(json['foodTax']),
      deliveryTax: _toDouble(json['deliveryTax']),
      taxesAndCharges: _toDouble(json['taxesAndCharges']),
      couponDiscount: _toDouble(json['couponDiscount']),
      deliveryTip: _toDouble(json['deliveryTip']),
      toPay: _toDouble(json['toPay']),
      codAvailable: json['codAvailable'] == true,
      message: json['message']?.toString(),
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
