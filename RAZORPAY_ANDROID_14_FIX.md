# Razorpay Android 14+ Crash Fix

## Problem
The Razorpay SDK crashes on Android 14+ (API 34+) with the following error:
```
java.lang.SecurityException: One of RECEIVER_EXPORTED or RECEIVER_NOT_EXPORTED should be specified when a receiver isn't being registered exclusively for system broadcasts
```

This happens because Razorpay SDK tries to register a broadcast receiver dynamically without specifying the export flag, which is required on Android 14+.

## Root Cause
The crash occurs in `com.razorpay.CheckoutPresenterImpl.lambda$onLoad$0` when the SDK calls `registerReceiver()` without the `RECEIVER_EXPORTED` or `RECEIVER_NOT_EXPORTED` flag.

## Current Status
- ✅ Enhanced error handling in `razorpay_crash_prevention.dart`
- ✅ Added receiver declarations in `AndroidManifest.xml`
- ✅ Updated Razorpay SDK version to 1.6.36
- ⚠️ **Still crashing** - The SDK needs to be patched or updated

## Solutions

### Option 1: Update Razorpay Flutter Plugin (Recommended)
Check for a newer version of `razorpay_flutter` plugin that fixes this issue:
```yaml
dependencies:
  razorpay_flutter: ^1.4.0  # Check for newer version
```

### Option 2: Patch the Razorpay Flutter Plugin
The plugin's native Android code needs to be modified to add the export flag:

1. Locate the Razorpay Flutter plugin in your Flutter cache:
   ```
   ~/.pub-cache/hosted/pub.dev/razorpay_flutter-1.4.0/android/src/main/java/
   ```

2. Find the file that registers the broadcast receiver (likely in `RazorpayFlutterPlugin.java`)

3. Modify the `registerReceiver` call to include the flag:
   ```java
   if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
       context.registerReceiver(receiver, intentFilter, Context.RECEIVER_NOT_EXPORTED);
   } else {
       context.registerReceiver(receiver, intentFilter);
   }
   ```

### Option 3: Use a Forked Version
If available, use a forked version of the Razorpay Flutter plugin that has this fix.

### Option 4: Contact Razorpay Support
Report this issue to Razorpay support and request an update that fixes Android 14+ compatibility.

## Temporary Workaround
The current error handling will catch and log the error, but the app will still crash because the exception occurs in native code before reaching Flutter.

## Files Modified
1. `lib/utils/razorpay_crash_prevention.dart` - Enhanced error handling
2. `android/app/src/main/AndroidManifest.xml` - Added receiver declarations
3. `android/build.gradle.kts` - Updated Razorpay SDK version to 1.6.36

## Next Steps
1. Check if Razorpay has released a fix for this issue
2. Consider patching the plugin if no fix is available
3. Monitor Razorpay GitHub issues: https://github.com/razorpay/razorpay-flutter/issues
