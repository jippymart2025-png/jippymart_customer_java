# Cart Price Update Guide

## Problem Statement
When a user adds products to cart and returns days later to place an order, the cart uses old prices stored when items were added, not the current backend prices. This results in incorrect order totals.

## Current Implementation Analysis

### Where Prices Are Stored
1. **CartProductModel** (`lib/models/cart_product_model.dart`):
   - `price`: String - Regular price stored when added to cart
   - `discountPrice`: String - Discount price stored when added to cart
   - Prices are saved to local SQLite database

2. **Price Calculation** (`lib/app/cart_screen/provider/cart_provider.dart`):
   - Line 2701-2723: `calculatePrice()` method uses prices directly from cart items
   - Uses `element.price` and `element.discountPrice` from stored cart data
   - No validation against current backend prices

### Current Flow
```
User adds product → Price saved to CartProductModel → Saved to SQLite DB
User returns days later → Cart loads from DB → calculatePrice() uses old prices → Order placed with wrong total
```

## Solution Approach

### Option 1: Real-time Price Validation (Recommended)
**Best for:** Ensuring accurate pricing and preventing price discrepancies

**Implementation Steps:**

1. **Add Price Validation Method** in `CartControllerProvider`:
```dart
/// Validates and updates cart prices against current backend prices
Future<Map<String, PriceUpdateResult>> validateAndUpdateCartPrices() async {
  final Map<String, PriceUpdateResult> results = {};
  
  for (var cartItem in HomeProvider.cartItem) {
    try {
      // Fetch current product from backend
      ProductModel? currentProduct;
      
      if (_isMartItem(cartItem)) {
        // For mart items
        final martService = Get.find<MartFirestoreService>();
        currentProduct = await martService.getItemById(cartItem.id!);
      } else {
        // For restaurant items
        currentProduct = await FireStoreUtils.getProductById(cartItem.id!);
      }
      
      if (currentProduct == null) {
        results[cartItem.id!] = PriceUpdateResult(
          productId: cartItem.id!,
          status: PriceStatus.productNotFound,
          oldPrice: cartItem.price,
          newPrice: null,
        );
        continue;
      }
      
      // Get current price (considering variants, promotions, etc.)
      final currentPrice = _getCurrentProductPrice(currentProduct, cartItem);
      final storedPrice = double.parse(cartItem.price ?? "0");
      
      if (currentPrice != storedPrice) {
        // Price has changed
        results[cartItem.id!] = PriceUpdateResult(
          productId: cartItem.id!,
          status: PriceStatus.priceChanged,
          oldPrice: cartItem.price,
          newPrice: currentPrice.toString(),
          productName: cartItem.name,
        );
      } else {
        results[cartItem.id!] = PriceUpdateResult(
          productId: cartItem.id!,
          status: PriceStatus.noChange,
          oldPrice: cartItem.price,
          newPrice: currentPrice.toString(),
        );
      }
    } catch (e) {
      results[cartItem.id!] = PriceUpdateResult(
        productId: cartItem.id!,
        status: PriceStatus.error,
        oldPrice: cartItem.price,
        newPrice: null,
        error: e.toString(),
      );
    }
  }
  
  return results;
}

/// Helper to get current product price considering variants and promotions
double _getCurrentProductPrice(ProductModel product, CartProductModel cartItem) {
  // Handle variants
  if (cartItem.variantInfo != null && product.itemAttribute != null) {
    final variantSku = cartItem.variantInfo!.variantSku;
    final variant = product.itemAttribute!.variants?.firstWhere(
      (v) => v.variantSku == variantSku,
      orElse: () => null,
    );
    
    if (variant != null) {
      // Get vendor for commission calculation
      final vendor = vendorModel;
      if (vendor != null) {
        return double.parse(Constant.productCommissionPrice(
          vendor,
          variant.variantPrice ?? product.price ?? "0",
        ));
      }
      return double.parse(variant.variantPrice ?? product.price ?? "0");
    }
  }
  
  // Handle regular price with commission
  final vendor = vendorModel;
  if (vendor != null) {
    // Check for promotional price
    if (cartItem.promoId != null && cartItem.promoId!.isNotEmpty) {
      return double.parse(Constant.productCommissionPrice(
        vendor,
        product.price ?? "0",
      ));
    }
    
    // Check for discount
    if (product.disPrice != null && 
        double.parse(product.disPrice!) > 0 &&
        double.parse(product.disPrice!) < double.parse(product.price ?? "0")) {
      return double.parse(Constant.productCommissionPrice(
        vendor,
        product.disPrice ?? "0",
      ));
    }
    
    return double.parse(Constant.productCommissionPrice(
      vendor,
      product.price ?? "0",
    ));
  }
  
  return double.parse(product.price ?? "0");
}
```

2. **Create Price Update Result Model**:
```dart
enum PriceStatus {
  noChange,
  priceChanged,
  productNotFound,
  error,
}

class PriceUpdateResult {
  final String productId;
  final PriceStatus status;
  final String? oldPrice;
  final String? newPrice;
  final String? productName;
  final String? error;
  
  PriceUpdateResult({
    required this.productId,
    required this.status,
    this.oldPrice,
    this.newPrice,
    this.productName,
    this.error,
  });
  
  bool get hasPriceChange => status == PriceStatus.priceChanged;
  bool get isError => status == PriceStatus.error || status == PriceStatus.productNotFound;
}
```

3. **Update calculatePrice() Method** (around line 2700):
```dart
Future<void> calculatePrice() async {
  // ... existing code ...
  
  // BEFORE calculating subtotal, validate prices
  final priceUpdates = await validateAndUpdateCartPrices();
  final hasPriceChanges = priceUpdates.values.any((r) => r.hasPriceChange);
  
  if (hasPriceChanges) {
    // Show dialog to user about price changes
    final shouldUpdate = await _showPriceUpdateDialog(priceUpdates);
    
    if (shouldUpdate == true) {
      // Update cart prices
      await _updateCartPrices(priceUpdates);
      // Recalculate with new prices
    } else if (shouldUpdate == false) {
      // User cancelled - don't proceed
      return;
    }
    // If null, user dismissed - continue with old prices (not recommended)
  }
  
  // Continue with existing calculation logic
  subTotal = 0.0;
  for (var element in HomeProvider.cartItem) {
    // Use updated prices if available, otherwise use stored prices
    final updatedPrice = priceUpdates[element.id]?.newPrice;
    final priceToUse = updatedPrice ?? element.price;
    
    // ... rest of calculation ...
  }
}
```

4. **Add Price Update Dialog**:
```dart
Future<bool?> _showPriceUpdateDialog(Map<String, PriceUpdateResult> updates) async {
  final changedItems = updates.values.where((r) => r.hasPriceChange).toList();
  
  if (changedItems.isEmpty) return true;
  
  return await showDialog<bool>(
    context: Get.context!,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text("Price Updates Detected".tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "The following items have price changes:".tr,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          ...changedItems.map((item) => Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.productName ?? "Product",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "₹${item.oldPrice}",
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "₹${item.newPrice}",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
          SizedBox(height: 12),
          Text(
            "Would you like to update your cart with the new prices?".tr,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text("Cancel".tr),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: Text("Update Prices".tr),
        ),
      ],
    ),
  );
}
```

5. **Add Update Cart Prices Method**:
```dart
Future<void> _updateCartPrices(Map<String, PriceUpdateResult> updates) async {
  for (var cartItem in HomeProvider.cartItem) {
    final update = updates[cartItem.id];
    if (update != null && update.hasPriceChange && update.newPrice != null) {
      // Update cart item price
      cartItem.price = update.newPrice;
      
      // Update in database
      await DatabaseHelper.instance.updateCartProduct(cartItem);
    }
  }
  
  // Refresh cart
  HomeProvider.cartItem.refresh();
  notifyListeners();
}
```

### Option 2: Price Validation Before Order Placement
**Best for:** Simpler implementation, validates only when user tries to order

**Implementation Steps:**

1. **Add validation in `validateAndPlaceOrderBulletproof()` method** (before order creation):
```dart
Future<bool> validateAndPlaceOrderBulletproof(BuildContext context) async {
  // ... existing validations ...
  
  // NEW: Validate prices before placing order
  ShowToastDialog.showLoader("Validating prices...".tr);
  
  try {
    final priceUpdates = await validateAndUpdateCartPrices();
    final hasPriceChanges = priceUpdates.values.any((r) => r.hasPriceChange);
    
    if (hasPriceChanges) {
      ShowToastDialog.closeLoader();
      final shouldUpdate = await _showPriceUpdateDialog(priceUpdates);
      
      if (shouldUpdate == true) {
        ShowToastDialog.showLoader("Updating cart...".tr);
        await _updateCartPrices(priceUpdates);
        // Recalculate totals with new prices
        await calculatePrice();
        ShowToastDialog.closeLoader();
      } else {
        // User cancelled
        return false;
      }
    } else {
      ShowToastDialog.closeLoader();
    }
  } catch (e) {
    ShowToastDialog.closeLoader();
    ShowToastDialog.showToast("Error validating prices: ${e.toString()}".tr);
    // Optionally: continue with old prices or cancel
    return false;
  }
  
  // Continue with existing order placement logic
  // ...
}
```

### Option 3: Background Price Sync
**Best for:** Keeping prices updated automatically without user interaction

**Implementation Steps:**

1. **Add timestamp to CartProductModel**:
```dart
class CartProductModel {
  // ... existing fields ...
  DateTime? priceLastUpdated; // Add this field
}
```

2. **Update database schema** (add migration):
```dart
// In DatabaseHelper, add migration
static const int _dbVersion = 2; // Increment version

Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('''
      ALTER TABLE cart_products 
      ADD COLUMN price_last_updated INTEGER
    ''');
  }
}
```

3. **Add background sync method**:
```dart
/// Syncs cart prices in background (call when cart screen opens)
Future<void> syncCartPricesInBackground() async {
  try {
    final priceUpdates = await validateAndUpdateCartPrices();
    
    // Auto-update prices silently if change is small (< 5%)
    for (var entry in priceUpdates.entries) {
      final result = entry.value;
      if (result.hasPriceChange && 
          result.oldPrice != null && 
          result.newPrice != null) {
        final oldPrice = double.parse(result.oldPrice!);
        final newPrice = double.parse(result.newPrice!);
        final changePercent = ((newPrice - oldPrice) / oldPrice * 100).abs();
        
        if (changePercent < 5) {
          // Small change - auto-update
          final cartItem = HomeProvider.cartItem.firstWhere(
            (item) => item.id == result.productId,
          );
          cartItem.price = result.newPrice;
          await DatabaseHelper.instance.updateCartProduct(cartItem);
        } else {
          // Large change - show notification
          _showPriceChangeNotification(result);
        }
      }
    }
    
    // Recalculate if any prices were updated
    if (priceUpdates.values.any((r) => r.hasPriceChange)) {
      await calculatePrice();
    }
  } catch (e) {
    print('Error syncing cart prices: $e');
  }
}
```

## Recommended Implementation Strategy

### Phase 1: Basic Validation (Quick Fix)
1. Implement Option 2 (validation before order placement)
2. Show dialog when prices change
3. Update prices if user confirms

### Phase 2: Enhanced Experience
1. Add Option 1 (real-time validation)
2. Show price change indicators in cart UI
3. Add "Last Updated" timestamp display

### Phase 3: Advanced Features
1. Implement Option 3 (background sync)
2. Add price change history
3. Add price alerts for saved carts

## Key Files to Modify

1. **`lib/app/cart_screen/provider/cart_provider.dart`**:
   - Add `validateAndUpdateCartPrices()` method
   - Modify `calculatePrice()` method (line ~2700)
   - Modify `validateAndPlaceOrderBulletproof()` method
   - Add dialog methods

2. **`lib/models/cart_product_model.dart`**:
   - Optionally add `priceLastUpdated` field

3. **`lib/services/database_helper.dart`**:
   - Add migration for new fields (if needed)

4. **UI Files** (optional):
   - `lib/app/cart_screen/cart_screen.dart` - Add price change indicators
   - `lib/app/cart_screen/widget/cart_bill_details_widget.dart` - Show price warnings

## Testing Checklist

- [ ] Add product to cart with price ₹100
- [ ] Change product price in backend to ₹120
- [ ] Open cart after price change
- [ ] Verify price validation is triggered
- [ ] Verify dialog shows correct old/new prices
- [ ] Test "Update Prices" action
- [ ] Test "Cancel" action
- [ ] Verify order total uses updated prices
- [ ] Test with multiple products with different price changes
- [ ] Test with products that no longer exist
- [ ] Test with variant products
- [ ] Test with promotional items
- [ ] Test network error scenarios

## Additional Considerations

1. **Performance**: Batch price validation to avoid multiple API calls
2. **Caching**: Cache product prices for a short duration (5-10 minutes)
3. **User Experience**: Show loading states during price validation
4. **Error Handling**: Handle cases where products are deleted or unavailable
5. **Edge Cases**: 
   - Products with variants
   - Promotional items
   - Items that are out of stock
   - Items that are no longer available

## Benefits of This Solution

1. ✅ **Accurate Pricing**: Always uses current backend prices
2. ✅ **User Transparency**: Shows price changes before order placement
3. ✅ **Prevents Disputes**: Reduces customer complaints about wrong prices
4. ✅ **Flexible**: Can be implemented incrementally
5. ✅ **Maintainable**: Clear separation of concerns


