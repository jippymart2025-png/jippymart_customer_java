import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';

import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/utils/preferences.dart';
import 'package:jippymart_customer/services/database_helper.dart';
import 'package:jippymart_customer/themes/custom_dialog_box.dart';
import 'package:jippymart_customer/app/auth_screen/phone_number_screen.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CartProvider with ChangeNotifier {
  CartProvider._internal() {
    _initialize();
  }

  static final CartProvider _instance = CartProvider._internal();

  factory CartProvider() => _instance;

  void _initialize() {
    if (_initialized) return;
    _initialized = true;
    initCart();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initCart();
    });
  }

  bool _initialized = false;
  Completer<void>? _activeCartSync;

  final _cartStreamController =
      StreamController<List<CartProductModel>>.broadcast();
  List<CartProductModel> _cartItems = [];

  // Cache location data to avoid repeated Preferences calls
  bool _locationSaved = false;
  DateTime? _lastLocationSaveTime;

  Stream<List<CartProductModel>> get cartStream => _cartStreamController.stream;

  Future<void> initCart() async {
    while (_activeCartSync != null) {
      await _activeCartSync!.future;
    }

    final currentSync = Completer<void>();
    _activeCartSync = currentSync;

    try {
      if (kDebugMode) {
        print('DEBUG: CartProvider _initCart() called');
      }
      _cartItems = await DatabaseHelper.instance.fetchCartProducts();
      if (kDebugMode) {
        print(
          'DEBUG: CartProvider - Fetched ${_cartItems.length} items from database',
        );
      }
      HomeProvider.cartItem.clear();
      HomeProvider.cartItem.addAll(_cartItems);
      if (kDebugMode) {
        print(
          'DEBUG: CartProvider - Synced ${HomeProvider.cartItem.length} items to global cartItem',
        );
      }
      _cartStreamController.sink.add(_cartItems);
      notifyListeners();
      print(
        'DEBUG: CartProvider - Stream updated with ${_cartItems.length} items',
      );
      if (!currentSync.isCompleted) {
        currentSync.complete();
      }
    } catch (e, stackTrace) {
      if (!currentSync.isCompleted) {
        currentSync.completeError(e, stackTrace);
      }
      rethrow;
    } finally {
      if (identical(_activeCartSync, currentSync)) {
        _activeCartSync = null;
      }
    }
  }

  Future<bool> addToCart(
    BuildContext context,
    CartProductModel product,
    int quantity,
  ) async {
    // Check if user is logged in before adding to cart
    final isLoggedIn = await SqlStorageConst.isUserLoggedIn();
    if (!isLoggedIn) {
      _showLoginRequiredDialog(context);
      return false;
    }

    print('DEBUG: CartProvider addToCart called');
    print('DEBUG: Cart Provider - Product: ${product.name}');
    print('DEBUG: Cart Provider - Price: ${product.price}');
    print('DEBUG: Cart Provider - DiscountPrice: ${product.discountPrice}');
    print('DEBUG: Cart Provider - PromoId: ${product.promoId}');
    final now = DateTime.now();
    if (!_locationSaved ||
        _lastLocationSaveTime == null ||
        now.difference(_lastLocationSaveTime!).inMinutes > 5) {
      await _saveLocationForTaxCalculation();
      _locationSaved = true;
      _lastLocationSaveTime = now;
    }
    _cartItems = await DatabaseHelper.instance.fetchCartProducts();
    print(
      'DEBUG: CartProvider - Fetched ${_cartItems.length} items from database',
    );
    final existingItemIndex = _cartItems.indexWhere(
      (item) => item.id == product.id,
    );
    if (existingItemIndex >= 0) {
      _cartItems[existingItemIndex].quantity = quantity;
      _cartItems[existingItemIndex].price = product.price;
      _cartItems[existingItemIndex].discountPrice = product.discountPrice;
      _cartItems[existingItemIndex].promoId = product.promoId;
      if (product.extras != null && product.extras!.isNotEmpty) {
        _cartItems[existingItemIndex].extras = product.extras;
        _cartItems[existingItemIndex].extrasPrice = product.extrasPrice;
      } else {
        _cartItems[existingItemIndex].extras = [];
        _cartItems[existingItemIndex].extrasPrice = "0";
      }
      await DatabaseHelper.instance.updateCartProduct(
        _cartItems[existingItemIndex],
      );
    } else {
      bool isMartItem =
          product.vendorID?.startsWith("demo_") == true ||
          product.vendorID?.contains("mart") == true ||
          product.vendorID?.contains("vendor") == true;
      bool cartHasFoodItems = _cartItems.any(
        (item) =>
            !(item.vendorID?.startsWith("demo_") == true ||
                item.vendorID?.contains("mart") == true ||
                item.vendorID?.contains("vendor") == true),
      );
      if (_cartItems.isEmpty ||
          (isMartItem && !cartHasFoodItems) ||
          (!isMartItem &&
              cartHasFoodItems &&
              _cartItems.every((item) => item.vendorID == product.vendorID))) {
        product.quantity = quantity;
        await DatabaseHelper.instance.insertCartProduct(product);
        _cartItems.add(product);
      } else {
        if (isMartItem && cartHasFoodItems) {
          ShowToastDialog.showToast(
            "You can't add mart items when you have food items in cart".tr,
          );
        } else if (!isMartItem && cartHasFoodItems) {
          _showRestaurantConflictDialog(context, product, quantity);
          return false;
        } else {
          ShowToastDialog.showToast(
            "You can't add food items when you have mart items in cart".tr,
          );
        }
        return false;
      }
    }
    HomeProvider.cartItem.clear();
    HomeProvider.cartItem.addAll(_cartItems);
    _cartStreamController.sink.add(_cartItems);
    print(
      'DEBUG: CartProvider - Cart updated, total items: ${_cartItems.length}',
    );
    notifyListeners();
    return true;
  }

  /// Save current location data for tax calculation
  Future<void> _saveLocationForTaxCalculation() async {
    try {
      // Check if location is available
      if (Constant.selectedLocation.location?.latitude != null &&
          Constant.selectedLocation.location?.longitude != null) {
        // Save location data to preferences for cart calculation
        await Preferences.setString(
          Preferences.selectedLocationLat,
          Constant.selectedLocation.location!.latitude.toString(),
        );
        await Preferences.setString(
          Preferences.selectedLocationLng,
          Constant.selectedLocation.location!.longitude.toString(),
        );
        await Preferences.setString(
          Preferences.selectedLocationAddress,
          Constant.selectedLocation.address ?? '',
        );
        await Preferences.setString(
          Preferences.selectedLocationAddressAs,
          Constant.selectedLocation.addressAs ?? '',
        );

        print(
          'DEBUG: CartProvider - Location saved for tax calculation: ${Constant.selectedLocation.location!.latitude}, ${Constant.selectedLocation.location!.longitude}',
        );
      } else {
        print(
          'DEBUG: CartProvider - No location available to save for tax calculation',
        );
      }
    } catch (e) {
      print(
        'DEBUG: CartProvider - Error saving location for tax calculation: $e',
      );
    }
  }

  /// Returns true if any cart item is a promo item (for COD restriction)
  Future<bool> cartContainsPromoItem() async {
    final cartItems = await DatabaseHelper.instance.fetchCartProducts();
    return cartItems.any(
      (item) => item.promoId != null && item.promoId!.isNotEmpty,
    );
  }

  Future<void> removeFromCart(CartProductModel product, int quantity) async {
    print(
      'DEBUG: CartProvider removeFromCart called for: ${product.name}, quantity: $quantity',
    );
    _cartItems = await DatabaseHelper.instance.fetchCartProducts();
    var index = _cartItems.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      _cartItems[index].quantity = quantity;
      if (_cartItems[index].quantity == 0) {
        await DatabaseHelper.instance.deleteCartProduct(product.id!);
        _cartItems.removeAt(index);
        print(
          'DEBUG: CartProvider - Item removed from cart, remaining items: ${_cartItems.length}',
        );
        notifyListeners();
      } else {
        await DatabaseHelper.instance.updateCartProduct(_cartItems[index]);
        print('DEBUG: CartProvider - Item quantity updated to: $quantity');
      }
    }
    notifyListeners();
    await initCart();
    print('DEBUG: CartProvider - Stream updated after removeFromCart');
  }

  // New method to remove item by product ID
  Future<void> removeFromCartById(String productId) async {
    print('DEBUG: CartProvider removeFromCartById called for: $productId');
    _cartItems = await DatabaseHelper.instance.fetchCartProducts();
    var index = _cartItems.indexWhere((item) => item.id == productId);
    if (index >= 0) {
      await DatabaseHelper.instance.deleteCartProduct(productId);
      _cartItems.removeAt(index);
      print(
        'DEBUG: CartProvider - Item removed, remaining items: ${_cartItems.length}',
      );
    }
    await initCart();
    print('DEBUG: CartProvider - Stream updated after removal');
  }

  // New method to update item quantity by product ID
  Future<void> updateCartItemQuantity(String productId, int newQuantity) async {
    print(
      'DEBUG: CartProvider updateCartItemQuantity called for: $productId, quantity: $newQuantity',
    );
    _cartItems = await DatabaseHelper.instance.fetchCartProducts();
    var index = _cartItems.indexWhere((item) => item.id == productId);
    if (index >= 0) {
      if (newQuantity <= 0) {
        await DatabaseHelper.instance.deleteCartProduct(productId);
        _cartItems.removeAt(index);
        print('DEBUG: CartProvider - Item removed due to quantity 0');
      } else {
        _cartItems[index].quantity = newQuantity;
        await DatabaseHelper.instance.updateCartProduct(_cartItems[index]);
        print('DEBUG: CartProvider - Item quantity updated to: $newQuantity');
      }
    }
    await initCart();
    print('DEBUG: CartProvider - Stream updated after quantity change');
  }

  Future<void> clearDatabase() async {
    _cartItems.clear();
    HomeProvider.cartItem.clear();
    await DatabaseHelper.instance.deleteAllCartProducts();
    _cartStreamController.sink.add(_cartItems);
    notifyListeners();
  }

  // Method to manually refresh cart from database
  Future<void> refreshCart() async {
    print('DEBUG: CartProvider refreshCart() called');
    await initCart();
  }

  // Method to force stream update
  void forceStreamUpdate() {
    print('DEBUG: CartProvider forceStreamUpdate() called');
    _cartStreamController.sink.add(_cartItems);
  }

  // Method to check cart persistence
  Future<void> checkCartPersistence() async {
    print('DEBUG: CartProvider checkCartPersistence() called');
    final dbItems = await DatabaseHelper.instance.fetchCartProducts();
    print('DEBUG: CartProvider - Database has ${dbItems.length} items');
    print('DEBUG: CartProvider - Memory has ${_cartItems.length} items');
    print(
      'DEBUG: CartProvider - Global cartItem has ${HomeProvider.cartItem.length} items',
    );

    if (dbItems.length != _cartItems.length) {
      print('DEBUG: CartProvider - Syncing cart with database...');
      await initCart();
    }
  }

  // Show dialog when trying to add items from different restaurants
  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialogBox(
          title: "Login Required".tr,
          descriptions:
              "Please login to add items to your cart and continue shopping."
                  .tr,
          positiveString: "Login".tr,
          negativeString: "Cancel".tr,
          positiveClick: () {
            Get.back(); // Close dialog
            Get.to(() => PhoneNumberScreen());
          },
          negativeClick: () {
            Get.back(); // Close dialog
          },
          img: Image.asset(
            'assets/images/ic_launcher.png',
            height: 50,
            width: 50,
          ),
        );
      },
    );
  }

  void _showRestaurantConflictDialog(
    BuildContext context,
    CartProductModel product,
    int quantity,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialogBox(
          title: "Different Restaurant".tr,
          descriptions:
              "You have items from a different restaurant in your cart. Do you want to replace them with items from this restaurant?"
                  .tr,
          positiveString: "Replace".tr,
          negativeString: "Cancel".tr,
          positiveClick: () async {
            // Clear existing cart items
            await DatabaseHelper.instance.deleteAllCartProducts();
            _cartItems.clear();
            // Add the new item
            product.quantity = quantity;
            await DatabaseHelper.instance.insertCartProduct(product);
            _cartItems.add(product);
            await initCart();
            Get.back(); // Close dialog
            ShowToastDialog.showToast(
              "Cart updated with new restaurant items".tr,
            );
          },
          negativeClick: () {
            Get.back(); // Close dialog
          },
          img: null,
        );
      },
    );
  }
}
