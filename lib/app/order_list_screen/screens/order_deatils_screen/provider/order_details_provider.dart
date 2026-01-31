// import 'package:flutter/cupertino.dart';
// import 'package:jippymart_customer/constant/constant.dart';
// import 'package:jippymart_customer/models/cart_product_model.dart';
// import 'package:jippymart_customer/models/order_model.dart';
// import 'package:jippymart_customer/services/cart_provider.dart';
// import 'package:get/get.dart';
//
// class OrderDetailsProvider extends ChangeNotifier {
//   bool isLoading = true;
//
//   OrderModel orderModel = OrderModel();
//
//   initFunction({required OrderModel orderModels}) async {
//     orderModel = orderModels;
//     print("orderModel ${orderModel.id} ");
//     notifyListeners();
//     calculatePrice();
//     notifyListeners();
//   }
//
//   double subTotal = 0.0;
//   double specialDiscountAmount = 0.0;
//   double taxAmount = 0.0;
//   double totalAmount = 0.0;
//
//   calculatePrice() async {
//     subTotal = 0.0;
//     specialDiscountAmount = 0.0;
//     taxAmount = 0.0;
//     totalAmount = 0.0;
//     // Calculate subtotal using promotional prices if available
//     for (var element in orderModel.products!) {
//       final hasPromo = element.promoId != null && element.promoId!.isNotEmpty;
//       double itemPrice;
//       if (hasPromo) {
//         itemPrice = double.parse(element.price.toString());
//       } else if (double.parse(element.discountPrice.toString()) <= 0) {
//         itemPrice = double.parse(element.price.toString());
//       } else {
//         // Regular discount (non-promo) - use discount price
//         itemPrice = double.parse(element.discountPrice.toString());
//       }
//       final quantity = double.parse(element.quantity.toString());
//       final extrasPrice = double.parse(element.extrasPrice.toString());
//       final itemTotal = (itemPrice * quantity) + (extrasPrice * quantity);
//       subTotal += itemTotal;
//     }
//
//     if (orderModel.specialDiscount != null &&
//         orderModel.specialDiscount!['special_discount'] != null) {
//       specialDiscountAmount = double.parse(
//         orderModel.specialDiscount!['special_discount'].toString(),
//       );
//     }
//
//     double sgst = 0.0;
//     double gst = 0.0;
//     if (orderModel.taxSetting != null) {
//       for (var element in orderModel.taxSetting!) {
//         if ((element.title?.toLowerCase() ?? '').contains('sgst')) {
//           sgst = Constant.calculateTax(
//             amount: subTotal.toString(),
//             taxModel: element,
//           );
//           print(
//             'DEBUG: Order Details Controller - SGST (5%) on item total: ₹$sgst',
//           );
//         } else if ((element.title?.toLowerCase() ?? '').contains('gst')) {
//           // Calculate GST on delivery charge
//           gst = Constant.calculateTax(
//             amount: double.parse(
//               orderModel.deliveryCharge.toString(),
//             ).toString(),
//             taxModel: element,
//           );
//           print(
//             'DEBUG: Order Details Controller - GST (18%) on delivery fee: ₹$gst',
//           );
//         }
//       }
//     }
//     taxAmount = sgst + gst;
//     totalAmount =
//         (subTotal -
//             double.parse(orderModel.discount.toString()) -
//             specialDiscountAmount) +
//         taxAmount +
//         double.parse(orderModel.deliveryCharge.toString()) +
//         double.parse(orderModel.tipAmount.toString());
//
//     isLoading = false;
//     notifyListeners();
//   }
//
//   final CartProvider cartProvider = CartProvider();
//
//   addToCart({required CartProductModel cartProductModel}) {
//     cartProvider.addToCart(
//       Get.context!,
//       cartProductModel,
//       cartProductModel.quantity!,
//     );
//     notifyListeners();
//   }
//
//   // Test function to manually test promotional calculations
//   void testPromotionalCalculation() {
//     print('=== MANUAL PROMOTIONAL CALCULATION TEST ===');
//
//     if (orderModel.products != null) {
//       print('Testing ${orderModel.products!.length} products:');
//
//       for (int i = 0; i < orderModel.products!.length; i++) {
//         final product = orderModel.products![i];
//         print('Product ${i + 1}: ${product.name}');
//         print('  - ID: ${product.id}');
//         print('  - Price: ${product.price}');
//         print('  - DiscountPrice: ${product.discountPrice}');
//         print('  - PromoId: ${product.promoId}');
//         print('  - Quantity: ${product.quantity}');
//
//         // Test promotional detection
//         final hasPromo = product.promoId != null && product.promoId!.isNotEmpty;
//         print('  - Has PromoId: $hasPromo');
//
//         // Test price calculation
//         double itemPrice;
//         if (hasPromo) {
//           itemPrice = double.parse(product.price.toString());
//           print('  - Using promotional price: ₹$itemPrice');
//         } else if (double.parse(product.discountPrice.toString()) <= 0) {
//           itemPrice = double.parse(product.price.toString());
//           print('  - Using regular price: ₹$itemPrice');
//         } else {
//           itemPrice = double.parse(product.discountPrice.toString());
//           print('  - Using discount price: ₹$itemPrice');
//         }
//
//         final quantity = double.parse(product.quantity.toString());
//         final extrasPrice = double.parse(product.extrasPrice.toString());
//         final itemTotal = (itemPrice * quantity) + (extrasPrice * quantity);
//
//         print('  - Item total: ₹$itemTotal');
//         print('');
//       }
//
//       // Test overall promotional detection
//       final hasAnyPromotionalItems = orderModel.products!.any(
//         (item) => item.promoId != null && item.promoId!.isNotEmpty,
//       );
//
//       print('Overall has promotional items: $hasAnyPromotionalItems');
//     } else {
//       print('No products found in order');
//     }
//
//     print('=== END MANUAL TEST ===');
//   }
// }

import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:get/get.dart';

class OrderDetailsProvider extends ChangeNotifier {
  bool isLoading = true;

  OrderModel orderModel = OrderModel();

  double subTotal = 0.0;
  double specialDiscountAmount = 0.0;
  double taxAmount = 0.0;
  double totalAmount = 0.0;

  final CartProvider cartProvider = CartProvider();

  initFunction({required OrderModel orderModels}) async {
    orderModel = orderModels;
    print("orderModel ${orderModel.id} ");
    notifyListeners();
    await calculatePrice();
    isLoading = false;
    notifyListeners();
  }

  Future<void> calculatePrice() async {
    // Reset all values
    subTotal = 0.0;
    specialDiscountAmount = 0.0;
    taxAmount = 0.0;
    totalAmount = 0.0;

    // Calculate subtotal using promotional prices if available
    if (orderModel.products != null) {
      for (var element in orderModel.products!) {
        subTotal += _calculateProductTotal(element);
      }
    }

    // Special discount
    specialDiscountAmount = _calculateSpecialDiscount();

    // Taxes
    taxAmount = _calculateTaxes();

    // Total amount
    totalAmount = _calculateTotalAmount();
  }

  double _calculateProductTotal(CartProductModel product) {
    final hasPromo = product.promoId != null && product.promoId!.isNotEmpty;
    double itemPrice;

    if (hasPromo) {
      itemPrice = _parseDouble(product.price);
    } else if (_parseDouble(product.discountPrice) <= 0) {
      itemPrice = _parseDouble(product.price);
    } else {
      itemPrice = _parseDouble(product.discountPrice);
    }

    final quantity = _parseDouble(product.quantity);
    final extrasPrice = _parseDouble(product.extrasPrice);

    return (itemPrice * quantity) + (extrasPrice * quantity);
  }

  double _calculateSpecialDiscount() {
    if (orderModel.specialDiscount != null &&
        orderModel.specialDiscount!['special_discount'] != null) {
      return _parseDouble(
        orderModel.specialDiscount!['special_discount'].toString(),
      );
    }
    return 0.0;
  }

  double _calculateTaxes() {
    double sgst = 0.0;
    double gst = 0.0;

    if (orderModel.taxSetting != null) {
      for (var element in orderModel.taxSetting!) {
        final title = element.title?.toLowerCase() ?? '';

        if (title.contains('sgst')) {
          sgst = Constant.calculateTax(
            amount: subTotal.toString(),
            taxModel: element,
          );
          print(
            'DEBUG: Order Details Controller - SGST (5%) on item total: ₹$sgst',
          );
        } else if (title.contains('gst')) {
          gst = Constant.calculateTax(
            amount: _parseDouble(orderModel.deliveryCharge).toString(),
            taxModel: element,
          );
          print(
            'DEBUG: Order Details Controller - GST (18%) on delivery fee: ₹$gst',
          );
        }
      }
    }

    return sgst + gst;
  }

  double _calculateTotalAmount() {
    return (subTotal -
            _parseDouble(orderModel.discount) -
            specialDiscountAmount) +
        taxAmount +
        _parseDouble(orderModel.deliveryCharge) +
        _parseDouble(orderModel.tipAmount);
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  addToCart({required CartProductModel cartProductModel}) {
    // Check if context is available
    final context = Get.context;
    if (context != null) {
      cartProvider.addToCart(
        context,
        cartProductModel,
        _parseDouble(cartProductModel.quantity).toInt(),
      );
      notifyListeners();
    } else {
      print('ERROR: Get.context is null in addToCart');
    }
  }

  // Test function to manually test promotional calculations
  void testPromotionalCalculation() {
    print('=== MANUAL PROMOTIONAL CALCULATION TEST ===');

    if (orderModel.products != null) {
      print('Testing ${orderModel.products!.length} products:');

      for (int i = 0; i < orderModel.products!.length; i++) {
        final product = orderModel.products![i];
        print('Product ${i + 1}: ${product.name}');
        print('  - ID: ${product.id}');
        print('  - Price: ${product.price}');
        print('  - DiscountPrice: ${product.discountPrice}');
        print('  - PromoId: ${product.promoId}');
        print('  - Quantity: ${product.quantity}');

        // Test promotional detection
        final hasPromo = product.promoId != null && product.promoId!.isNotEmpty;
        print('  - Has PromoId: $hasPromo');

        // Test price calculation
        double itemPrice;
        if (hasPromo) {
          itemPrice = _parseDouble(product.price);
          print('  - Using promotional price: ₹$itemPrice');
        } else if (_parseDouble(product.discountPrice) <= 0) {
          itemPrice = _parseDouble(product.price);
          print('  - Using regular price: ₹$itemPrice');
        } else {
          itemPrice = _parseDouble(product.discountPrice);
          print('  - Using discount price: ₹$itemPrice');
        }

        final quantity = _parseDouble(product.quantity);
        final extrasPrice = _parseDouble(product.extrasPrice);
        final itemTotal = (itemPrice * quantity) + (extrasPrice * quantity);

        print('  - Item total: ₹$itemTotal');
        print('');
      }

      // Test overall promotional detection
      final hasAnyPromotionalItems = orderModel.products!.any(
        (item) => item.promoId != null && item.promoId!.isNotEmpty,
      );

      print('Overall has promotional items: $hasAnyPromotionalItems');
      print('Calculated subtotal: ₹$subTotal');
      print('Special discount: ₹$specialDiscountAmount');
      print('Tax amount: ₹$taxAmount');
      print('Total amount: ₹$totalAmount');
    } else {
      print('No products found in order');
    }

    print('=== END MANUAL TEST ===');
  }
}
