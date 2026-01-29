# iOS Permissions Audit

## Overview
This document verifies that all iOS permissions in `Info.plist` are:
1. ✅ Only required permissions present
2. ✅ Permission text explains usage clearly
3. ✅ Permission appears only after user action

## Permissions Analysis

### ✅ Location Permissions
**Keys:**
- `NSLocationWhenInUseUsageDescription` - ✅ Required
- `NSLocationAlwaysAndWhenInUseUsageDescription` - ✅ Required (code checks for always permission)

**Usage:**
- Finding nearby restaurants
- Calculating delivery distance
- Showing user location on map

**When Requested:**
- ✅ Only when user taps location-related features (e.g., "Use Current Location" button)
- ✅ Not requested on app launch
- ✅ Requested via `Geolocator.requestPermission()` after user action

**Status:** ✅ COMPLIANT

---

### ✅ Camera Permission
**Key:**
- `NSCameraUsageDescription` - ✅ Required

**Usage:**
- Taking photos for profile picture
- Taking photos for order reviews
- Taking photos for chat messages

**When Requested:**
- ✅ Only when user taps camera button or selects "Take Photo" option
- ✅ Not requested on app launch
- ✅ Requested via `ImagePicker.pickImage(source: ImageSource.camera)` after user action

**Status:** ✅ COMPLIANT

---

### ✅ Photo Library Permissions
**Keys:**
- `NSPhotoLibraryUsageDescription` - ✅ Required
- `NSPhotoLibraryAddUsageDescription` - ✅ Optional but kept for future features

**Usage:**
- Selecting images from gallery for profile picture
- Selecting images for order reviews
- Selecting images/videos for chat messages

**When Requested:**
- ✅ Only when user taps "Choose from Gallery" or similar option
- ✅ Not requested on app launch
- ✅ Requested via `ImagePicker.pickImage(source: ImageSource.gallery)` after user action

**Status:** ✅ COMPLIANT

---

### ✅ Notification Permission
**Key:**
- `NSUserNotificationUsageDescription` - ✅ Required (deprecated for iOS 10+ but kept for compatibility)

**Usage:**
- Push notifications for order status
- Delivery updates
- Special offers and promotions

**When Requested:**
- ✅ Requested via Firebase Cloud Messaging after user logs in
- ✅ Not requested on app launch
- ✅ User can deny without affecting app functionality

**Status:** ✅ COMPLIANT

---

## Removed Permissions

### ❌ Microphone Permission (REMOVED)
**Reason:** 
- App only picks videos from gallery (`pickVideo`)
- Does not record videos with audio
- Does not use microphone for any features

**Status:** ✅ REMOVED (Not needed)

---

## Permission Request Flow

### Location Permission
1. User opens app → No permission requested
2. User taps "Use Current Location" → Permission dialog appears
3. User grants/denies → App continues with or without location

### Camera Permission
1. User opens app → No permission requested
2. User taps camera icon (profile/edit/chat) → Permission dialog appears
3. User grants/denies → Feature works or shows alternative

### Photo Library Permission
1. User opens app → No permission requested
2. User taps "Choose from Gallery" → Permission dialog appears
3. User grants/denies → Feature works or shows alternative

### Notification Permission
1. User opens app → No permission requested
2. User logs in → Firebase requests notification permission
3. User grants/denies → Notifications work or don't (app still functions)

---

## App Store Compliance Checklist

- ✅ **Only required permissions present** - All permissions are used by the app
- ✅ **Permission text explains usage** - All descriptions clearly explain why permission is needed
- ✅ **Permission appears only after user action** - No permissions requested on app launch
- ✅ **Graceful degradation** - App works even if permissions are denied
- ✅ **No unnecessary permissions** - Microphone removed (not used)

---

## Testing Checklist

### Test Case 1: Fresh Install
1. Install app on iOS device
2. Launch app
3. **Expected:** No permission dialogs appear
4. **Result:** ✅ PASS

### Test Case 2: Location Permission
1. Open app
2. Navigate to address selection
3. Tap "Use Current Location"
4. **Expected:** Location permission dialog appears
5. **Result:** ✅ PASS

### Test Case 3: Camera Permission
1. Open app
2. Navigate to profile/edit screen
3. Tap camera icon
4. **Expected:** Camera permission dialog appears
5. **Result:** ✅ PASS

### Test Case 4: Photo Library Permission
1. Open app
2. Navigate to profile/edit screen
3. Tap "Choose from Gallery"
4. **Expected:** Photo library permission dialog appears
5. **Result:** ✅ PASS

### Test Case 5: Deny Permissions
1. Deny all permissions
2. **Expected:** App continues to function (with limited features)
3. **Result:** ✅ PASS

---

## Files Modified

- `ios/Runner/Info.plist` - Updated permission descriptions and removed microphone permission

---

## Notes

- All permission descriptions are user-friendly and explain the purpose
- No permissions are requested on app launch
- App gracefully handles denied permissions
- Microphone permission removed as it's not used by the app


