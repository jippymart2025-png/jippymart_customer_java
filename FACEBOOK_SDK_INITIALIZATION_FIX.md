# Facebook SDK Initialization Fix

## Issue
The Facebook App Events SDK was failing with the error:
```
kotlin.UninitializedPropertyAccessException: lateinit property appEventsLogger has not been initialized
```

This occurs because the Facebook SDK requires both the Application ID and Client Token to be configured in the Android manifest.

## Solution Applied

### 1. Added Facebook Configuration to `strings.xml`
- ✅ Added Facebook App ID: `640838582128923`
- ⚠️ **ACTION REQUIRED:** Added placeholder for Facebook Client Token

### 2. Added Facebook Meta-Data to `AndroidManifest.xml`
- ✅ Added `com.facebook.sdk.ApplicationId` meta-data
- ✅ Added `com.facebook.sdk.ClientToken` meta-data

## Required Action: Get Facebook Client Token

You need to obtain your Facebook Client Token from the Facebook App Dashboard:

1. Go to: https://developers.facebook.com/apps/640838582128923/settings/basic/
2. Scroll down to find the "App Secret" section
3. Click "Show" next to the Client Token (not the App Secret)
4. Copy the Client Token
5. Replace `YOUR_FACEBOOK_CLIENT_TOKEN` in `android/app/src/main/res/values/strings.xml`

**Example:**
```xml
<string name="facebook_client_token">your_actual_client_token_here</string>
```

## Files Modified

1. `android/app/src/main/res/values/strings.xml`
   - Added `facebook_app_id` string resource
   - Added `facebook_client_token` string resource (placeholder)

2. `android/app/src/main/AndroidManifest.xml`
   - Added Facebook ApplicationId meta-data
   - Added Facebook ClientToken meta-data

## After Adding Client Token

1. Rebuild the app:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. The Facebook SDK should now initialize properly
3. Test events should work without the initialization error

## Verification

After adding the Client Token and rebuilding, you should see:
- ✅ No more `UninitializedPropertyAccessException` errors
- ✅ Facebook App Events logs successfully
- ✅ Test events execute without errors
- ✅ Events appear in Facebook Events Manager

## Notes

- The Client Token is different from the App Secret
- The Client Token is safe to include in your app (unlike the App Secret)
- Make sure to replace the placeholder before building for release


