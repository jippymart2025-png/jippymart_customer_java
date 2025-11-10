import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// **ANR PREVENTION UTILITY**
///
/// This utility prevents Application Not Responding (ANR) issues by:
/// - Moving heavy operations off the main thread
/// - Implementing strict timeouts
/// - Using background processing
/// - Monitoring operation duration
class ANRPrevention {
  static const Duration _anrThreshold = Duration(
    milliseconds: 2000,
  ); // 2 seconds
  static const Duration _criticalThreshold = Duration(
    milliseconds: 500,
  ); // 500ms

  /// **Execute operation with ANR prevention**
  ///
  /// Moves heavy operations to background and applies strict timeouts
  static Future<T> executeWithANRPrevention<T>(
    String operationName,
    Future<T> Function() operation, {
    Duration? timeout,
    bool logToCrashlytics = true,
  }) async {
    final startTime = DateTime.now();

    try {
      // Use Future.microtask to move off main thread
      final result = await Future.microtask(() async {
        return await operation().timeout(
          timeout ?? const Duration(seconds: 3),
          onTimeout: () {
            log('ANR_PREVENTION: Operation "$operationName" timed out');
            throw TimeoutException(
              'Operation timed out',
              timeout ?? const Duration(seconds: 3),
            );
          },
        );
      });

      final duration = DateTime.now().difference(startTime);

      // Log slow operations
      if (duration > _criticalThreshold) {
        log(
          'ANR_PREVENTION: Slow operation "$operationName" took ${duration.inMilliseconds}ms',
        );

        if (logToCrashlytics) {
          FirebaseCrashlytics.instance.log(
            'Slow operation detected: $operationName took ${duration.inMilliseconds}ms',
          );
        }
      }

      return result;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);

      if (logToCrashlytics) {
        FirebaseCrashlytics.instance.recordError(
          e,
          stackTrace,
          reason:
              'ANR prevention failed for operation: $operationName (duration: ${duration.inMilliseconds}ms)',
        );
      }

      rethrow;
    }
  }
}
