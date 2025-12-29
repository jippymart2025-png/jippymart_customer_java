# Facebook App Events SDK - Testing Guide

## ✅ Integration Complete

The Facebook App Events SDK has been successfully integrated into your Flutter app with the following configuration:

- **App ID**: 640838582128923
- **Client Token**: Configured in `android/app/src/main/res/values/strings.xml`
- **Automatic Events**: Enabled (App Install, App Launch, In-App Purchases)
- **SDK Initialization**: Automatic on app startup

## 🧪 Testing the Integration

### Method 1: Automatic Test (Debug Mode)

The SDK automatically runs a verification test when you launch the app in **debug mode**. 

1. Run your app in debug mode:
   ```bash
   flutter run
   ```

2. Check the console logs. You should see:
   ```
   ✅ Facebook App Events initialized successfully
   🔍 [FB TEST] Verifying Facebook SDK integration...
   ✅ [FB TEST] SDK verification completed successfully
   ```

### Method 2: Manual Test via Code

You can manually trigger tests by calling:

```dart
import 'package:jippymart_customer/utils/facebook_app_events_test.dart';

// Run all tests
await FacebookAppEventsTest.runAllTests();

// Or run individual tests
await FacebookAppEventsTest.testPurchaseEvent();
await FacebookAppEventsTest.testAddToCartEvent();
await FacebookAppEventsTest.testViewContentEvent();
```

### Method 3: Test Individual Events

You can test specific events using the service directly:

```dart
import 'package:jippymart_customer/services/facebook_app_events_service.dart';

// Test purchase event
await FacebookAppEventsService().logPurchase(
  amount: 99.99,
  currency: 'INR',
  parameters: {
    'fb_content_id': 'product_123',
    'fb_content_type': 'product',
  },
);

// Test add to cart
await FacebookAppEventsService().logAddToCart(
  amount: 49.99,
  currency: 'INR',
  contentId: 'product_456',
  contentType: 'product',
);

// Test custom event
await FacebookAppEventsService().logEvent(
  'custom_event_name',
  parameters: {'key': 'value'},
);
```

## 📊 Verify Events in Facebook Events Manager

1. Go to [Facebook Events Manager](https://business.facebook.com/events_manager2)
2. Select your app (App ID: 640838582128923)
3. Navigate to **Test Events** tab
4. You should see events appearing in real-time when you trigger them

### Using App Ads Helper (Recommended)

1. Open [App Ads Helper](https://developers.facebook.com/tools/app-ads-helper/)
2. Select your app: **640838582128923**
3. Click **Submit**
4. Go to the bottom and click **Test App Events**
5. Start your app and trigger events
6. Events should appear on the web page in real-time

## 🔍 Debug Logging

Debug logs are automatically enabled in debug mode. You'll see detailed logs in your console:

- `✅ Facebook App Events initialized successfully` - SDK initialized
- `📊 Facebook App Event logged: [event_name]` - Event logged successfully
- `📤 Facebook App Events flushed` - Events sent to Facebook

## 🚀 Automatic Events

The following events are automatically logged by the SDK:

1. **App Install** - First time the app is launched
2. **App Launch** - Every time the app is opened (throttled to once per 60 seconds)
3. **In-App Purchase** - Automatically detected for Google Play purchases

## 📝 Next Steps

1. **Test the integration**: Run the app in debug mode and check console logs
2. **Verify in Events Manager**: Check Facebook Events Manager to see events
3. **Add custom events**: Integrate event logging into your app's key user actions:
   - Product views
   - Add to cart
   - Checkout initiation
   - Purchase completion
   - Search queries

## 🔧 Troubleshooting

### Events not appearing in Events Manager?

1. **Check App ID**: Verify `640838582128923` is correct in `AndroidManifest.xml`
2. **Check Client Token**: Ensure Client Token is set in `strings.xml`
3. **Wait a few minutes**: Events may take 1-2 minutes to appear
4. **Check network**: Ensure device has internet connection
5. **Check logs**: Look for error messages in console

### SDK not initializing?

1. Check console for error messages
2. Verify `AndroidManifest.xml` has correct meta-data
3. Ensure `facebook_app_events` package is installed: `flutter pub get`

## 📚 Available Event Methods

The `FacebookAppEventsService` provides these methods:

- `logEvent()` - Log any custom event
- `logPurchase()` - Log purchase events
- `logAddToCart()` - Log add to cart events
- `logViewContent()` - Log content view events
- `logSearch()` - Log search events
- `logInitiateCheckout()` - Log checkout initiation
- `flush()` - Force send pending events immediately

## 🎯 Integration Points

Consider adding Facebook App Events to these areas:

1. **Product Views**: When user views a product
2. **Add to Cart**: When items are added to cart
3. **Checkout**: When user initiates checkout
4. **Purchase**: When order is completed
5. **Search**: When user searches for products
6. **Category Views**: When user browses categories

---

**Need Help?** Check the [Facebook App Events Documentation](https://developers.facebook.com/docs/app-events/getting-started-app-events-android)


















