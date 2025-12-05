import '../services/facebook_app_events_service.dart';

/// Test utility for Facebook App Events
/// 
/// This class provides methods to test Facebook App Events integration
class FacebookAppEventsTest {
  static final FacebookAppEventsService _service = FacebookAppEventsService();

  /// Test basic event logging
  static Future<void> testBasicEvent() async {
    try {
      print('🧪 [FB TEST] Testing basic event logging...');
      await _service.logEvent(
        'test_event',
        parameters: {
          'test_param': 'test_value',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      print('✅ [FB TEST] Basic event logged successfully');
    } catch (e) {
      print('❌ [FB TEST] Error logging basic event: $e');
    }
  }

  /// Test purchase event
  static Future<void> testPurchaseEvent() async {
    try {
      print('🧪 [FB TEST] Testing purchase event...');
      await _service.logPurchase(
        amount: 99.99,
        currency: 'INR',
        parameters: {
          'fb_content_id': 'test_product_123',
          'fb_content_type': 'product',
          'test_order_id': 'test_order_${DateTime.now().millisecondsSinceEpoch}',
        },
      );
      print('✅ [FB TEST] Purchase event logged successfully');
    } catch (e) {
      print('❌ [FB TEST] Error logging purchase event: $e');
    }
  }

  /// Test add to cart event
  static Future<void> testAddToCartEvent() async {
    try {
      print('🧪 [FB TEST] Testing add to cart event...');
      await _service.logAddToCart(
        amount: 49.99,
        currency: 'INR',
        contentId: 'test_product_456',
        contentType: 'product',
      );
      print('✅ [FB TEST] Add to cart event logged successfully');
    } catch (e) {
      print('❌ [FB TEST] Error logging add to cart event: $e');
    }
  }

  /// Test view content event
  static Future<void> testViewContentEvent() async {
    try {
      print('🧪 [FB TEST] Testing view content event...');
      await _service.logViewContent(
        contentId: 'test_product_789',
        contentType: 'product',
        currency: 'INR',
        value: 29.99,
      );
      print('✅ [FB TEST] View content event logged successfully');
    } catch (e) {
      print('❌ [FB TEST] Error logging view content event: $e');
    }
  }

  /// Test search event
  static Future<void> testSearchEvent() async {
    try {
      print('🧪 [FB TEST] Testing search event...');
      await _service.logSearch(
        searchString: 'test search query',
        contentType: 'product',
      );
      print('✅ [FB TEST] Search event logged successfully');
    } catch (e) {
      print('❌ [FB TEST] Error logging search event: $e');
    }
  }

  /// Test initiate checkout event
  static Future<void> testInitiateCheckoutEvent() async {
    try {
      print('🧪 [FB TEST] Testing initiate checkout event...');
      await _service.logInitiateCheckout(
        amount: 149.99,
        currency: 'INR',
        numItems: 3,
      );
      print('✅ [FB TEST] Initiate checkout event logged successfully');
    } catch (e) {
      print('❌ [FB TEST] Error logging initiate checkout event: $e');
    }
  }

  /// Run all tests
  static Future<void> runAllTests() async {
    print('\n🚀 [FB TEST] Starting Facebook App Events Test Suite...\n');
    
    await Future.delayed(const Duration(seconds: 1));
    await testBasicEvent();
    
    await Future.delayed(const Duration(seconds: 1));
    await testPurchaseEvent();
    
    await Future.delayed(const Duration(seconds: 1));
    await testAddToCartEvent();
    
    await Future.delayed(const Duration(seconds: 1));
    await testViewContentEvent();
    
    await Future.delayed(const Duration(seconds: 1));
    await testSearchEvent();
    
    await Future.delayed(const Duration(seconds: 1));
    await testInitiateCheckoutEvent();
    
    await Future.delayed(const Duration(seconds: 1));
    await _service.flush();
    
    print('\n✅ [FB TEST] All tests completed!');
    print('📊 [FB TEST] Check Facebook Events Manager to verify events:');
    print('   https://business.facebook.com/events_manager2/list/app/640838582128923\n');
  }

  /// Test SDK initialization
  static Future<void> testInitialization() async {
    try {
      print('🧪 [FB TEST] Testing SDK initialization...');
      await _service.initialize();
      print('✅ [FB TEST] SDK initialized successfully');
    } catch (e) {
      print('❌ [FB TEST] Error initializing SDK: $e');
    }
  }

  /// Verify SDK is working by checking if events can be logged
  static Future<bool> verifySDK() async {
    try {
      print('🔍 [FB TEST] Verifying Facebook SDK integration...');
      
      // Test initialization
      await testInitialization();
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Test basic event
      await testBasicEvent();
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Flush events
      await _service.flush();
      
      print('✅ [FB TEST] SDK verification completed successfully');
      return true;
    } catch (e) {
      print('❌ [FB TEST] SDK verification failed: $e');
      return false;
    }
  }
}

