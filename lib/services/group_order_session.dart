import 'package:flutter/foundation.dart';
import 'package:jippymart_customer/models/vendor_model.dart';

class GroupOrderSession extends ChangeNotifier {
  GroupOrderSession._();

  static final GroupOrderSession instance = GroupOrderSession._();

  int? groupOrdersInvitationId;
  int? hostCustomerId;
  String? groupCode;
  int? deliveryAddressId;
  VendorModel? restaurant;

  final Map<String, int> _productQuantities = {};

  bool get isActive => groupOrdersInvitationId != null && hostCustomerId != null;

  int quantityFor(String productId) => _productQuantities[productId] ?? 0;

  int get totalItemCount =>
      _productQuantities.values.fold<int>(0, (sum, qty) => sum + qty);

  void start({
    required int groupOrdersInvitationId,
    required int hostCustomerId,
    required String groupCode,
    required VendorModel restaurant,
    int? deliveryAddressId,
  }) {
    this.groupOrdersInvitationId = groupOrdersInvitationId;
    this.hostCustomerId = hostCustomerId;
    this.groupCode = groupCode;
    this.restaurant = restaurant;
    this.deliveryAddressId = deliveryAddressId;
    notifyListeners();
  }

  void setQuantitiesFromCheckout(Map<String, int> quantities) {
    _productQuantities
      ..clear()
      ..addAll(quantities);
    notifyListeners();
  }

  void incrementProduct(String productId, int by) {
    if (productId.isEmpty || by <= 0) return;
    _productQuantities[productId] = quantityFor(productId) + by;
    notifyListeners();
  }

  void clear() {
    groupOrdersInvitationId = null;
    hostCustomerId = null;
    groupCode = null;
    deliveryAddressId = null;
    restaurant = null;
    _productQuantities.clear();
    notifyListeners();
  }
}
