import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/services/cart_provider.dart';
import 'package:get/get.dart';

class OrderDetailsProvider extends ChangeNotifier {
  bool isLoading = true;

  void initFunction() {
    getArgument();
  }

  OrderModel orderModel = OrderModel();

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderModel = argumentData['orderModel'];
    }
    calculatePrice();
    notifyListeners();
  }

  double subTotal = 0.0;
  double specialDiscountAmount = 0.0;
  double taxAmount = 0.0;
  double totalAmount = 0.0;

  calculatePrice() async {
    subTotal = 0.0;
    specialDiscountAmount = 0.0;
    taxAmount = 0.0;
    totalAmount = 0.0;

    // Calculate subtotal using promotional prices if available
    for (var element in orderModel.products!) {
      final hasPromo = element.promoId != null && element.promoId!.isNotEmpty;
      double itemPrice;
      if (hasPromo) {
        itemPrice = double.parse(element.price.toString());
      } else if (double.parse(element.discountPrice.toString()) <= 0) {
        itemPrice = double.parse(element.price.toString());
      } else {
        // Regular discount (non-promo) - use discount price
        itemPrice = double.parse(element.discountPrice.toString());
      }

      final quantity = double.parse(element.quantity.toString());
      final extrasPrice = double.parse(element.extrasPrice.toString());

      final itemTotal = (itemPrice * quantity) + (extrasPrice * quantity);
      subTotal += itemTotal;
    }

    if (orderModel.specialDiscount != null &&
        orderModel.specialDiscount!['special_discount'] != null) {
      specialDiscountAmount = double.parse(
        orderModel.specialDiscount!['special_discount'].toString(),
      );
    }

    // Check if order has promotional items for delivery charge calculation
    final hasPromotionalItems =
        orderModel.products?.any(
          (item) => item.promoId != null && item.promoId!.isNotEmpty,
        ) ??
        false;

    double sgst = 0.0;
    double gst = 0.0;
    if (orderModel.taxSetting != null) {
      for (var element in orderModel.taxSetting!) {
        if ((element.title?.toLowerCase() ?? '').contains('sgst')) {
          sgst = Constant.calculateTax(
            amount: subTotal.toString(),
            taxModel: element,
          );
          print(
            'DEBUG: Order Details Controller - SGST (5%) on item total: ₹$sgst',
          );
        } else if ((element.title?.toLowerCase() ?? '').contains('gst')) {
          // Calculate GST on delivery charge
          gst = Constant.calculateTax(
            amount: double.parse(
              orderModel.deliveryCharge.toString(),
            ).toString(),
            taxModel: element,
          );
          print(
            'DEBUG: Order Details Controller - GST (18%) on delivery fee: ₹$gst',
          );
        }
      }
    }
    taxAmount = sgst + gst;

    totalAmount =
        (subTotal -
            double.parse(orderModel.discount.toString()) -
            specialDiscountAmount) +
        taxAmount +
        double.parse(orderModel.deliveryCharge.toString()) +
        double.parse(orderModel.tipAmount.toString());

    isLoading = false;
    notifyListeners();
  }

  final CartProvider cartProvider = CartProvider();

  addToCart({required CartProductModel cartProductModel}) {
    cartProvider.addToCart(
      Get.context!,
      cartProductModel,
      cartProductModel.quantity!,
    );
    notifyListeners();
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
          itemPrice = double.parse(product.price.toString());
          print('  - Using promotional price: ₹$itemPrice');
        } else if (double.parse(product.discountPrice.toString()) <= 0) {
          itemPrice = double.parse(product.price.toString());
          print('  - Using regular price: ₹$itemPrice');
        } else {
          itemPrice = double.parse(product.discountPrice.toString());
          print('  - Using discount price: ₹$itemPrice');
        }

        final quantity = double.parse(product.quantity.toString());
        final extrasPrice = double.parse(product.extrasPrice.toString());
        final itemTotal = (itemPrice * quantity) + (extrasPrice * quantity);

        print('  - Item total: ₹$itemTotal');
        print('');
      }

      // Test overall promotional detection
      final hasAnyPromotionalItems = orderModel.products!.any(
        (item) => item.promoId != null && item.promoId!.isNotEmpty,
      );

      print('Overall has promotional items: $hasAnyPromotionalItems');
    } else {
      print('No products found in order');
    }

    print('=== END MANUAL TEST ===');
  }
}
