# iOS Simulator Location Setup Guide

## How to Enable Location Services in Xcode Simulator

### Method 1: Using Simulator Menu (Recommended)

1. **Launch your app in the iOS Simulator**
   - Run your Flutter app: `flutter run` or press Run in Xcode

2. **Open Simulator Menu**
   - In the Simulator, go to: **Features → Location**
   - Or use keyboard shortcut: `Cmd + Shift + L` (while Simulator is active)

3. **Select Location Option**
   - **None** - No location (for testing permission denied)
   - **Custom Location...** - Set specific coordinates
   - **Apple** - Apple Park, Cupertino, CA
   - **City Bicycle Ride** - Simulated bike ride
   - **City Run** - Simulated run
   - **Freeway Drive** - Simulated drive
   - **Custom Location...** - Enter custom coordinates

### Method 2: Set Custom Location Coordinates

1. **Open Simulator Menu**
   - **Features → Location → Custom Location...**

2. **Enter Coordinates**
   - **Latitude:** e.g., `28.6139` (Delhi, India)
   - **Longitude:** e.g., `77.2090` (Delhi, India)
   - Click **OK**

### Method 3: Using Xcode Debug Menu

1. **While app is running in Simulator**
   - In Xcode, go to: **Debug → Simulate Location**
   - Select from predefined locations or add custom location

### Method 4: Programmatically Set Location (For Testing)

You can also set location programmatically in your code for testing:

```dart
// In your test/debug code
import 'package:geolocator/geolocator.dart';

// Set a test location (Delhi, India)
final testLocation = Position(
  latitude: 28.6139,
  longitude: 77.2090,
  timestamp: DateTime.now(),
  accuracy: 10.0,
  altitude: 0.0,
  heading: 0.0,
  speed: 0.0,
  speedAccuracy: 0.0,
);
```

## Common Test Locations

### India Locations (for JippyMart testing)

**Delhi:**
- Latitude: `28.6139`
- Longitude: `77.2090`

**Mumbai:**
- Latitude: `19.0760`
- Longitude: `72.8777`

**Bangalore:**
- Latitude: `12.9716`
- Longitude: `77.5946`

**Chennai:**
- Latitude: `13.0827`
- Longitude: `80.2707`

## Testing Different Location Scenarios

### 1. Test Location Permission Denied
- **Features → Location → None**
- App should handle gracefully without crashing

### 2. Test Location Permission Granted
- **Features → Location → Custom Location...**
- Enter coordinates
- App should show nearby restaurants

### 3. Test Location Services Disabled
- **Features → Location → None**
- Then disable location services in Settings
- App should prompt user to enable location

### 4. Test Moving Location (for delivery tracking)
- **Features → Location → City Run** or **Freeway Drive**
- Simulates movement
- Useful for testing live tracking features

## Troubleshooting

### Location Not Working?

1. **Check Simulator Settings**
   - Go to: **Settings → Privacy → Location Services**
   - Ensure Location Services is **ON**
   - Ensure your app has permission

2. **Reset Location & Privacy**
   - **Settings → General → Reset → Reset Location & Privacy**
   - This resets all location permissions

3. **Restart Simulator**
   - Sometimes location needs a restart to take effect

4. **Check App Permissions**
   - In Simulator: **Settings → Privacy → Location Services → [Your App]**
   - Should be set to "While Using the App"

## Quick Reference

| Action | Menu Path | Shortcut |
|--------|-----------|----------|
| Open Location Menu | Features → Location | `Cmd + Shift + L` |
| Set Custom Location | Features → Location → Custom Location... | - |
| Reset Location | Settings → General → Reset → Reset Location & Privacy | - |

## Testing Checklist

- [ ] Test with location enabled (Custom Location)
- [ ] Test with location disabled (None)
- [ ] Test permission denied scenario
- [ ] Test location services disabled in Settings
- [ ] Test moving location (City Run/Freeway Drive)
- [ ] Verify app doesn't crash when location is unavailable
- [ ] Verify "Use Current Location" button works
- [ ] Verify nearby restaurants load correctly

## Notes

- Location in Simulator is simulated and may not be 100% accurate
- For more accurate testing, use a real device
- Simulator location persists until changed or Simulator is restarted
- You can set different locations for different simulators


