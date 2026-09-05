import 'package:jippymart_customer/models/customer_cart_model.dart';

class CustomerCheckoutModel {
  final List<CustomerCartItemModel> items;
  final double itemTotal;
  final double orderAmountDiscounted;
  final double deliveryCharge;
  final double driverDeliveryCharge;
  final double customerGrossDeliveryCharge;
  final double customerFreeDistanceBenefit;
  final double customerDeliveryCharge;
  final double platformFee;
  final double platformFeeTax;
  final bool platformFeeToggle;
  final double surgeFee;
  final double surgeFeeTax;
  final bool surgeFeeToggle;
  final double packagingFee;
  final double packagingFeeTax;
  final bool packagingFeeToggle;
  final double foodTax;
  final double deliveryTax;
  final double customerDeliveryTax;
  final double taxesAndCharges;
  final double couponDiscount;
  final double deliveryTip;
  final double toPay;
  final bool codAvailable;
  final String? message;

  const CustomerCheckoutModel({
    required this.items,
    required this.itemTotal,
    required this.orderAmountDiscounted,
    required this.deliveryCharge,
    required this.driverDeliveryCharge,
    required this.customerGrossDeliveryCharge,
    required this.customerFreeDistanceBenefit,
    required this.customerDeliveryCharge,
    required this.platformFee,
    required this.platformFeeTax,
    required this.platformFeeToggle,
    required this.surgeFee,
    required this.surgeFeeTax,
    required this.surgeFeeToggle,
    required this.packagingFee,
    required this.packagingFeeTax,
    required this.packagingFeeToggle,
    required this.foodTax,
    required this.deliveryTax,
    required this.customerDeliveryTax,
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
      orderAmountDiscounted: _toDouble(json['orderAmountDiscounted']),
      deliveryCharge: _toDouble(json['deliveryCharge']),
      driverDeliveryCharge: _toDouble(json['driverDeliveryCharge']),
      customerGrossDeliveryCharge: _toDouble(
        json['customerGrossDeliveryCharge'],
      ),
      customerFreeDistanceBenefit: _toDouble(
        json['customerFreeDistanceBenefit'],
      ),
      customerDeliveryCharge: _toDouble(json['customerDeliveryCharge']),
      platformFee: _toDouble(json['platformFee']),
      platformFeeTax: _toDouble(json['platformFeeTax']),
      platformFeeToggle: json['platformFeeToggle'] == true,
      surgeFee: _toDouble(json['surgeFee']),
      surgeFeeTax: _toDouble(json['surgeFeeTax']),
      surgeFeeToggle: json['surgeFeeToggle'] == true,
      packagingFee: _toDouble(json['packagingFee']),
      packagingFeeTax: _toDouble(json['packagingFeeTax']),
      packagingFeeToggle: json['packagingFeeToggle'] == true,
      foodTax: _toDouble(json['foodTax']),
      deliveryTax: _toDouble(json['deliveryTax']),
      customerDeliveryTax: _toDouble(json['customerDeliveryTax']),
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
