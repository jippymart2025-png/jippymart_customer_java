class OrderBillDetails {
  final double subTotal;
  final double deliveryCharges;
  final double originalDeliveryFee;
  final double couponAmount;
  final double specialDiscountAmount;
  final double taxAmount;
  final double deliveryTips;
  final double totalAmount;
  final bool isFreeDelivery;

  OrderBillDetails({
    required this.subTotal,
    required this.deliveryCharges,
    required this.originalDeliveryFee,
    required this.couponAmount,
    required this.specialDiscountAmount,
    required this.taxAmount,
    required this.deliveryTips,
    required this.totalAmount,
    required this.isFreeDelivery,
  });
}
