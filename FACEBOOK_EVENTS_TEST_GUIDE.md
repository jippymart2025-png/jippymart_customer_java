# Facebook App Events Testing Guide

## Overview
This guide explains how to test if Facebook App Events SDK is working correctly in the app.

## Test Suite Status
The app has a comprehensive test suite that runs automatically in **debug mode**. The tests verify:
- SDK initialization
- Basic event logging
- Purchase events
- Add to cart events
- View content events
- Search events
- Initiate checkout events

## How to Test

### Option 1: Run the App in Debug Mode (Recommended)
1. Run the app in debug mode:
   ```bash
   flutter run
   ```

2. Watch the console/logs. You should see output like:
   ```
   ✅ [FB EVENTS] Facebook App Events initialized successfully
   🔍 [FB TEST] Verifying Facebook SDK integration...
   🧪 [FB TEST] Testing SDK initialization...
   ✅ [FB TEST] SDK initialized successfully
   🧪 [FB TEST] Testing basic event logging...
   📊 [FB EVENTS] Logged event: test_event
   ✅ [FB TEST] Basic event logged successfully
   ...
   🚀 [FB TEST] Starting Facebook App Events Test Suite...
   ✅ [FB TEST] All tests completed!
   ```

3. **All test events run automatically** when the app starts in debug mode.

### Option 2: Check Logs on Android
If running on Android device/emulator:
```bash
flutter run
# In another terminal, watch logs:
adb logcat | grep -i "FB"
```

### Option 3: Verify Events in Facebook Events Manager
After running the app, events should appear in Facebook Events Manager:
- URL: https://business.facebook.com/events_manager2/list/app/640838582128923
- Note: Events may take a few minutes to appear

## Test Events Being Sent

The test suite sends the following events:

1. **test_event** - Basic test event
2. **fb_mobile_purchase** - Purchase event (99.99 INR)
3. **fb_mobile_add_to_cart** - Add to cart event (49.99 INR)
4. **fb_mobile_content_view** - View content event
5. **fb_mobile_search** - Search event
6. **fb_mobile_initiated_checkout** - Initiate checkout event (149.99 INR)

## Expected Console Output

When tests run successfully, you should see:
```
✅ [FB EVENTS] Facebook App Events initialized successfully
🔍 [FB TEST] Verifying Facebook SDK integration...
🧪 [FB TEST] Testing SDK initialization...
✅ [FB TEST] SDK initialized successfully
🧪 [FB TEST] Testing basic event logging...
📊 [FB EVENTS] Logged event: test_event
✅ [FB TEST] Basic event logged successfully
📤 [FB EVENTS] Flushed pending events
✅ [FB TEST] SDK verification completed successfully
🚀 [FB TEST] Starting Facebook App Events Test Suite...
🧪 [FB TEST] Testing basic event logging...
📊 [FB EVENTS] Logged event: test_event
✅ [FB TEST] Basic event logged successfully
🧪 [FB TEST] Testing purchase event...
💰 [FB EVENTS] Logged purchase: 99.99 INR
✅ [FB TEST] Purchase event logged successfully
🧪 [FB TEST] Testing add to cart event...
🛒 [FB EVENTS] Logged add to cart: 49.99 INR
✅ [FB TEST] Add to cart event logged successfully
🧪 [FB TEST] Testing view content event...
👁️ [FB EVENTS] Logged view content: test_product_789
✅ [FB TEST] View content event logged successfully
🧪 [FB TEST] Testing search event...
🔍 [FB EVENTS] Logged search: test search query
✅ [FB TEST] Search event logged successfully
🧪 [FB TEST] Testing initiate checkout event...
🛍️ [FB EVENTS] Logged initiate checkout: 149.99 INR
✅ [FB TEST] Initiate checkout event logged successfully
📤 [FB EVENTS] Flushed pending events
✅ [FB TEST] All tests completed!
```

## Troubleshooting

### If tests don't run:
- Make sure you're running in **debug mode** (not release mode)
- Check that `kDebugMode` is true
- Verify Facebook App Events service initialized successfully

### If events don't appear in Facebook Events Manager:
- Events are batched and sent periodically (not immediately)
- Wait 5-10 minutes and refresh the Events Manager
- Check your Facebook App ID configuration
- Verify internet connectivity

### If you see errors:
- Check that Facebook SDK is properly configured in AndroidManifest.xml
- Verify the Facebook App ID is set correctly
- Check Android logs for detailed error messages

## Disabling Tests

To disable automatic tests, comment out the test calls in `lib/main.dart`:
```dart
void _runFacebookAppEventsTests() {
  Future.microtask(() async {
    // Comment out test calls if needed
    // await FacebookAppEventsTest.verifySDK();
    // await FacebookAppEventsTest.runAllTests();
  });
}
```

## Manual Testing

You can also manually test events by calling:
```dart
// Test individual events
await FacebookAppEventsTest.testBasicEvent();
await FacebookAppEventsTest.testPurchaseEvent();
await FacebookAppEventsTest.testAddToCartEvent();

// Or run all tests
await FacebookAppEventsTest.runAllTests();

// Or just verify SDK
await FacebookAppEventsTest.verifySDK();
```



