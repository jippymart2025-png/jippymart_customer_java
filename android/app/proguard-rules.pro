# Flutter
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-dontwarn com.google.android.gms.maps.**

# Google Wallet
-keep class com.google.android.gms.wallet.** { *; }
-dontwarn com.google.android.gms.wallet.**

# WeChat SDK
-keep class com.tencent.mm.opensdk.** { *; }
-dontwarn com.tencent.mm.opensdk.**

# Card.io SDK
-keep class io.card.** { *; }
-dontwarn io.card.**
# Required to prevent Flutter Play Core / SplitInstallManager crashes
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Stripe push provisioning
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**

# Keep Razorpay analytics classes
-keep class proguard.annotation.** { *; }
-dontwarn proguard.annotation.**

# 🔑 CRITICAL: Keep Razorpay AnalyticsUtil class to prevent NoSuchMethodError
-keep class com.razorpay.AnalyticsUtil { *; }
-keepclassmembers class com.razorpay.AnalyticsUtil {
    public static *** logFunctionEntry(...);
    public static *** logFunctionExit(...);
    public static *** logEvent(...);
    public static *** log(...);
}

# Razorpay SDK - CRITICAL for release builds
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-keepclassmembers class com.razorpay.** { *; }

# Keep Razorpay native classes
-keep class io.flutter.plugins.razorpay_flutter.** { *; }
-dontwarn io.flutter.plugins.razorpay_flutter.**

# Keep Razorpay payment response classes
-keep class * extends com.razorpay.PaymentData { *; }
-keep class * implements com.razorpay.PaymentResultWithDataListener { *; }

# Keep Razorpay JSON classes
-keepclassmembers class * {
    @com.razorpay.** <methods>;
}

# Prevent obfuscation of Razorpay constants
-keepclassmembers class com.razorpay.Constants {
    public static final *;
}

# Keep Razorpay CheckoutActivity and related classes
-keep class com.razorpay.CheckoutActivity { *; }
-keep class com.razorpay.CheckoutBridge { *; }
-keep class com.razorpay.CheckoutBridgeImpl { *; }

# Keep Razorpay WebView classes
-keep class com.razorpay.**.WebView { *; }
-keep class com.razorpay.**.RazorpayWebView { *; }

# Keep all Razorpay methods and fields
-keepclassmembers class com.razorpay.** {
    *;
}

# Keep Razorpay enums
-keepclassmembers enum com.razorpay.** {
    *;
}

# Keep Razorpay annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Prevent removal of Flutter deferred component handling
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# General keep rules for reflection-heavy code
-keepclassmembers class * {
    public <init>(...);
}

# Aggressive optimization for smaller APK
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification

# Remove unused classes and methods
-dontwarn **
-keep class com.jippymart.customer.MainActivity { *; }

# Remove logging
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
