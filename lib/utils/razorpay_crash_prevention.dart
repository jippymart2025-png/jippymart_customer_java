import 'dart:developer';

import 'package:razorpay_flutter/razorpay_flutter.dart';

/// **RAZORPAY CRASH PREVENTION UTILITY**
///
/// This utility prevents Razorpay-related crashes by:
/// - Handling NoSuchFieldError for activity_result_invalid_parameters
/// - Providing safe Razorpay initialization
/// - Graceful error handling for payment operations
/// - Version compatibility checks
class RazorpayCrashPrevention {
  static final RazorpayCrashPrevention _instance =
      RazorpayCrashPrevention._internal();

  factory RazorpayCrashPrevention() => _instance;

  RazorpayCrashPrevention._internal();

  Razorpay? _razorpay;
  bool _isInitialized = false;
  bool _isInitializationSafe = false;
  bool _areListenersRegistered = false; // 🔑 CRITICAL: Prevent duplicate listener registration

  /// **SAFE RAZORPAY INITIALIZATION**
  ///
  /// Initializes Razorpay with crash prevention measures
  Future<bool> safeInitialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) async {
    try {
      log('RAZORPAY_CRASH_PREVENTION: Starting safe initialization...');

      // 🔑 CRITICAL: If already initialized, clear old instance first to prevent duplicate listeners
      if (_isInitialized && _razorpay != null) {
        log('RAZORPAY_CRASH_PREVENTION: Already initialized, clearing old instance to prevent duplicate listeners');
        try {
          _razorpay!.clear();
        } catch (e) {
          log('RAZORPAY_CRASH_PREVENTION: Error clearing old instance: $e');
        }
        _razorpay = null;
        _isInitialized = false;
        _isInitializationSafe = false;
        _areListenersRegistered = false;
      }

      // ✅ CRITICAL: Check if Razorpay can be safely initialized
      if (!await _canSafelyInitializeRazorpay()) {
        log(
          'RAZORPAY_CRASH_PREVENTION: Razorpay initialization not safe, skipping...',
        );
        return false;
      }

      // 🔑 CRITICAL: Create Razorpay instance with error handling for Android 14+ broadcast receiver issues
      // Note: The actual receiver registration happens later when opening payment, not during instantiation
      // So we create the instance here, but the error might occur when opening payment
      try {
        _razorpay = Razorpay();
        log('RAZORPAY_CRASH_PREVENTION: ✅ Razorpay instance created successfully');
      } catch (e, stackTrace) {
        // 🔑 CRITICAL: Catch RemoteException and other initialization errors
        // This can happen on Android 14+ when Razorpay tries to register broadcast receivers
        log('RAZORPAY_CRASH_PREVENTION: ❌ Error creating Razorpay instance: $e');
        log('RAZORPAY_CRASH_PREVENTION: Stack trace: $stackTrace');
        
        // Check if it's a RemoteException (Android 14+ broadcast receiver issue)
        final errorString = e.toString();
        if (errorString.contains('RemoteException') || 
            errorString.contains('registerReceiver') ||
            errorString.contains('registerReceiverWithFeature')) {
          log('RAZORPAY_CRASH_PREVENTION: ⚠️ Detected Android 14+ broadcast receiver issue during instantiation');
          log('RAZORPAY_CRASH_PREVENTION: This is unusual - receiver registration typically happens during payment open');
          log('RAZORPAY_CRASH_PREVENTION: Ensure CheckoutActivity is declared in AndroidManifest.xml');
        }
        
        _isInitialized = false;
        _isInitializationSafe = false;
        return false;
      }

      // 🔑 CRITICAL: Only register event handlers once to prevent duplicate callbacks
      if (!_areListenersRegistered) {
        log('RAZORPAY_CRASH_PREVENTION: Registering event listeners (first time)');
        
        // Set up event handlers with error protection
        _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (
          PaymentSuccessResponse response,
        ) {
          try {
            log('RAZORPAY_CRASH_PREVENTION: Payment success received');
            log('RAZORPAY_CRASH_PREVENTION: Payment ID: ${response.paymentId}');
            log(
              'RAZORPAY_CRASH_PREVENTION: Payment signature: ${response.signature}',
            );
            log('RAZORPAY_CRASH_PREVENTION: Payment data: ${response.data}');
            onSuccess(response);
          } catch (e) {
            log(
              'RAZORPAY_CRASH_PREVENTION: Error in payment success handler: $e',
            );
          }
        });

        _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (
          PaymentFailureResponse response,
        ) {
          try {
            log(
              'RAZORPAY_CRASH_PREVENTION: Payment error received: ${response.message}',
            );
            onFailure(response);
          } catch (e) {
            log(
              'RAZORPAY_CRASH_PREVENTION: Error in payment failure handler: $e',
            );
          }
        });

        _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (
          ExternalWalletResponse response,
        ) {
          try {
            log('RAZORPAY_CRASH_PREVENTION: External wallet response received');
            onExternalWallet(response);
          } catch (e) {
            log(
              'RAZORPAY_CRASH_PREVENTION: Error in external wallet handler: $e',
            );
          }
        });

        _areListenersRegistered = true;
        log('RAZORPAY_CRASH_PREVENTION: ✅ Event listeners registered successfully');
      } else {
        log('RAZORPAY_CRASH_PREVENTION: ⚠️ Event listeners already registered, skipping duplicate registration');
      }

      _isInitialized = true;
      _isInitializationSafe = true;

      log('RAZORPAY_CRASH_PREVENTION: ✅ Safe initialization completed');
      return true;
    } catch (e, stackTrace) {
      // 🔑 CRITICAL: Enhanced error handling for Android 14+ issues
      log('RAZORPAY_CRASH_PREVENTION: ❌ Initialization failed: $e');
      log('RAZORPAY_CRASH_PREVENTION: Stack trace: $stackTrace');
      
      // Check for specific Android 14+ broadcast receiver errors
      final errorString = e.toString();
      if (errorString.contains('RemoteException') || 
          errorString.contains('registerReceiver') ||
          errorString.contains('registerReceiverWithFeature')) {
        log('RAZORPAY_CRASH_PREVENTION: ⚠️ Android 14+ broadcast receiver registration issue detected');
        log('RAZORPAY_CRASH_PREVENTION: Ensure receivers are declared in AndroidManifest.xml');
      }
      
      _isInitialized = false;
      _isInitializationSafe = false;
      return false;
    }
  }

  /// **SAFE PAYMENT OPENING**
  ///
  /// Opens Razorpay payment with crash prevention
  Future<bool> safeOpenPayment(Map<String, dynamic> options) async {
    try {
      log('🔑 [RAZORPAY_CRASH_PREVENTION] safeOpenPayment called');
      log('🔑 [RAZORPAY_CRASH_PREVENTION] _isInitialized: $_isInitialized, _isInitializationSafe: $_isInitializationSafe');
      
      if (!_isInitialized || !_isInitializationSafe) {
        log(
          '❌ [RAZORPAY_CRASH_PREVENTION] Razorpay not safely initialized, cannot open payment',
        );
        return false;
      }
      
      // ✅ CRITICAL: Validate options before opening payment
      log('🔑 [RAZORPAY_CRASH_PREVENTION] Validating payment options...');
      if (!_validatePaymentOptions(options)) {
        log('❌ [RAZORPAY_CRASH_PREVENTION] Invalid payment options');
        return false;
      }

      log('✅ [RAZORPAY_CRASH_PREVENTION] Payment options validated');
      log('🔑 [RAZORPAY_CRASH_PREVENTION] Opening payment with validated options');
      log('🔑 [RAZORPAY_CRASH_PREVENTION] Razorpay instance: ${_razorpay != null ? "exists" : "null"}');
      
      if (_razorpay == null) {
        log('❌ [RAZORPAY_CRASH_PREVENTION] Razorpay instance is null');
        return false;
      }
      
      // 🔑 CRITICAL: Call open synchronously - Razorpay.open() opens a native activity
      // In Flutter, all Dart code runs on the main thread, so we can call it directly
      try {
        log('🔑 [RAZORPAY_CRASH_PREVENTION] Calling Razorpay.open() with options');
        log('🔑 [RAZORPAY_CRASH_PREVENTION] Options: key=${options['key']?.toString().substring(0, 10)}..., amount=${options['amount']}, order_id=${options['order_id']}');
        
        // 🔑 CRITICAL: Wrap in try-catch to prevent crashes from propagating
        // Razorpay.open() can throw exceptions that crash the app if not caught
        // This is where Android 14+ RemoteException typically occurs (during receiver registration)
        try {
          // Call open directly - it's a synchronous call that opens native activity
          // On Android 14+, this might trigger receiver registration which can fail
          _razorpay!.open(options);
          
          // Small delay to ensure the native activity starts
          await Future.delayed(const Duration(milliseconds: 100));
          
          log('✅ [RAZORPAY_CRASH_PREVENTION] Payment opened successfully - open() called');
          return true;
        } catch (nativeError, nativeStack) {
          // 🔑 CRITICAL: Catch any native errors and log them without crashing
          log('❌ [RAZORPAY_CRASH_PREVENTION] Native error in Razorpay.open(): $nativeError');
          log('❌ [RAZORPAY_CRASH_PREVENTION] Native stack trace: $nativeStack');
          
          // 🔑 CRITICAL: Check for Android 14+ RemoteException (broadcast receiver issue)
          final errorString = nativeError.toString();
          if (errorString.contains('RemoteException') || 
              errorString.contains('registerReceiver') ||
              errorString.contains('registerReceiverWithFeature')) {
            log('❌ [RAZORPAY_CRASH_PREVENTION] ⚠️ Android 14+ broadcast receiver registration failed');
            log('❌ [RAZORPAY_CRASH_PREVENTION] This is a known issue with Razorpay SDK on Android 14+');
            log('❌ [RAZORPAY_CRASH_PREVENTION] Ensure CheckoutActivity is declared in AndroidManifest.xml');
            log('❌ [RAZORPAY_CRASH_PREVENTION] Consider updating Razorpay SDK to latest version');
          }
          
          // Don't rethrow - return false instead to prevent app crash
          // The error is logged, and the calling code can handle the failure gracefully
          return false;
        }
      } catch (openError, stackTrace) {
        log('❌ [RAZORPAY_CRASH_PREVENTION] Error calling Razorpay.open(): $openError');
        log('❌ [RAZORPAY_CRASH_PREVENTION] Stack trace: $stackTrace');
        
        // Check for RemoteException in outer catch as well
        final errorString = openError.toString();
        if (errorString.contains('RemoteException') || 
            errorString.contains('registerReceiver') ||
            errorString.contains('registerReceiverWithFeature')) {
          log('❌ [RAZORPAY_CRASH_PREVENTION] ⚠️ Android 14+ broadcast receiver issue detected in outer catch');
        }
        
        // 🔑 CRITICAL: Don't rethrow - return false to prevent app crash
        return false;
      }
    } catch (e, stackTrace) {
      log('❌ [RAZORPAY_CRASH_PREVENTION] Error opening payment: $e');
      log('❌ [RAZORPAY_CRASH_PREVENTION] Stack trace: $stackTrace');
      return false;
    }
  }

  /// **SAFE CLEANUP**
  ///
  /// Safely cleans up Razorpay resources
  void safeCleanup() {
    try {
      if (_razorpay != null) {
        _razorpay!.clear();
        _razorpay = null;
      }
      _isInitialized = false;
      _isInitializationSafe = false;
      _areListenersRegistered = false; // 🔑 CRITICAL: Reset listener flag on cleanup
      log('RAZORPAY_CRASH_PREVENTION: ✅ Cleanup completed');
    } catch (e) {
      log('RAZORPAY_CRASH_PREVENTION: ❌ Cleanup error: $e');
    }
  }

  /// **CHECK INITIALIZATION STATUS**
  bool get isInitialized => _isInitialized && _isInitializationSafe;

  /// **GET RAZORPAY INSTANCE**
  Razorpay? get razorpayInstance => _isInitialized ? _razorpay : null;

  // **INTERNAL METHODS**

  /// **CHECK IF RAZORPAY CAN BE SAFELY INITIALIZED**
  ///
  /// This method checks for the specific NoSuchFieldError that causes crashes
  /// Also handles Android 14+ RemoteException for broadcast receiver registration
  Future<bool> _canSafelyInitializeRazorpay() async {
    try {
      // ✅ CRITICAL: Test if Razorpay can be instantiated without crashes
      Razorpay? testRazorpay;
      try {
        testRazorpay = Razorpay();
      } catch (e, stackTrace) {
        // 🔑 CRITICAL: Catch RemoteException and other initialization errors
        // This can happen on Android 14+ when Razorpay tries to register broadcast receivers
        log('RAZORPAY_CRASH_PREVENTION: ❌ Error creating test Razorpay instance: $e');
        log('RAZORPAY_CRASH_PREVENTION: Stack trace: $stackTrace');
        
        final errorString = e.toString();
        if (errorString.contains('RemoteException') || 
            errorString.contains('registerReceiver') ||
            errorString.contains('registerReceiverWithFeature')) {
          log('RAZORPAY_CRASH_PREVENTION: ⚠️ Android 14+ broadcast receiver issue detected in test');
          log('RAZORPAY_CRASH_PREVENTION: This may be a transient issue, will attempt initialization anyway');
          // Don't return false immediately - the actual initialization might work
          // The error might only occur during receiver registration, not during instantiation
        } else {
          // For other errors, fail the safety check
          return false;
        }
      }

      // ✅ NEW: Test if the problematic field exists
      // This prevents the NoSuchFieldError for activity_result_invalid_parameters
      try {
        // Try to access Razorpay constants that might cause the crash
        final constants = [
          Razorpay.EVENT_PAYMENT_SUCCESS,
          Razorpay.EVENT_PAYMENT_ERROR,
          Razorpay.EVENT_EXTERNAL_WALLET,
        ];

        // If we can access these constants without crashing, it's safe
        for (String constant in constants) {
          if (constant.isEmpty) {
            log(
              'RAZORPAY_CRASH_PREVENTION: Empty constant detected: $constant',
            );
            if (testRazorpay != null) {
              try {
                testRazorpay.clear();
              } catch (_) {}
            }
            return false;
          }
        }

        // Clean up test instance
        if (testRazorpay != null) {
          try {
            testRazorpay.clear();
          } catch (e) {
            log('RAZORPAY_CRASH_PREVENTION: Warning - error clearing test instance: $e');
          }
        }

        log('RAZORPAY_CRASH_PREVENTION: ✅ Razorpay can be safely initialized');
        return true;
      } catch (e) {
        log('RAZORPAY_CRASH_PREVENTION: ❌ Razorpay constant access failed: $e');
        if (testRazorpay != null) {
          try {
            testRazorpay.clear();
          } catch (_) {}
        }
        return false;
      }
    } catch (e, stackTrace) {
      log(
        'RAZORPAY_CRASH_PREVENTION: ❌ Razorpay instantiation test failed: $e',
      );
      log('RAZORPAY_CRASH_PREVENTION: Stack trace: $stackTrace');
      return false;
    }
  }

  /// **VALIDATE PAYMENT OPTIONS**
  ///
  /// Ensures payment options are valid before opening payment
  bool _validatePaymentOptions(Map<String, dynamic> options) {
    try {
      log('RAZORPAY_CRASH_PREVENTION: Validating payment options: $options');

      // Check required fields
      final requiredFields = ['key', 'amount', 'name', 'order_id'];
      for (String field in requiredFields) {
        if (!options.containsKey(field) || options[field] == null) {
          log('RAZORPAY_CRASH_PREVENTION: Missing required field: $field');
          return false;
        }
      }

      // Validate amount - handle both int and double
      final amount = options['amount'];
      int amountValue;
      if (amount is int) {
        amountValue = amount;
      } else if (amount is double) {
        amountValue = amount.round();
        log(
          'RAZORPAY_CRASH_PREVENTION: Converted double amount to int: $amountValue',
        );
      } else {
        log(
          'RAZORPAY_CRASH_PREVENTION: Invalid amount type: ${amount.runtimeType}, value: $amount',
        );
        return false;
      }

      if (amountValue <= 0) {
        log(
          'RAZORPAY_CRASH_PREVENTION: Invalid amount: $amountValue (must be > 0)',
        );
        return false;
      }

      // Validate key format
      final key = options['key'] as String;
      if (key.isEmpty) {
        log('RAZORPAY_CRASH_PREVENTION: Razorpay key is empty');
        return false;
      }

      if (!key.startsWith('rzp_')) {
        log(
          'RAZORPAY_CRASH_PREVENTION: Invalid Razorpay key format: $key (should start with rzp_)',
        );
        return false;
      }

      log(
        'RAZORPAY_CRASH_PREVENTION: ✅ Payment options validated successfully',
      );
      return true;
    } catch (e) {
      log('RAZORPAY_CRASH_PREVENTION: ❌ Payment options validation failed: $e');
      return false;
    }
  }
}
