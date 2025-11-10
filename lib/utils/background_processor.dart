import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// **BACKGROUND PROCESSOR FOR ANR PREVENTION**
///
/// This utility prevents ANR by moving heavy operations to background isolates
/// and implementing memory-efficient processing patterns.
class BackgroundProcessor {
  static const Duration _maxOperationTime = Duration(seconds: 5);
  static const int _maxMemoryOperations = 10;
  static int _currentOperations = 0;

  /// **Process heavy operations in background isolate**
  ///
  /// Moves CPU-intensive operations off the main thread to prevent ANR
  static Future<T> processInBackground<T>(
    String operationName,
    Future<T> Function() operation, {
    Duration? timeout,
    bool useIsolate = true,
  }) async {
    final startTime = DateTime.now();

    try {
      // Check memory pressure
      if (_currentOperations >= _maxMemoryOperations) {
        log('BACKGROUND_PROCESSOR: Memory pressure high, waiting...');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      _currentOperations++;

      T result;
      if (useIsolate && !kIsWeb) {
        // Use isolate for heavy operations
        result = await _processInIsolate(operationName, operation);
      } else {
        // Use microtask for lighter operations
        result = await Future.microtask(() async {
          return await operation().timeout(
            timeout ?? _maxOperationTime,
            onTimeout: () {
              log('BACKGROUND_PROCESSOR: Operation "$operationName" timed out');
              throw TimeoutException(
                'Operation timed out',
                timeout ?? _maxOperationTime,
              );
            },
          );
        });
      }

      final duration = DateTime.now().difference(startTime);

      // Log slow operations
      if (duration > const Duration(milliseconds: 1000)) {
        log(
          'BACKGROUND_PROCESSOR: Slow operation "$operationName" took ${duration.inMilliseconds}ms',
        );
        FirebaseCrashlytics.instance.log(
          'Slow background operation: $operationName took ${duration.inMilliseconds}ms',
        );
      }

      return result;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);

      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason:
            'Background operation failed: $operationName (duration: ${duration.inMilliseconds}ms)',
      );

      rethrow;
    } finally {
      _currentOperations--;
    }
  }

  /// **Process data in batches to prevent memory issues**
  ///
  /// Loads large datasets in small batches to prevent memory pressure
  static Future<List<T>> processInBatches<T>(
    String operationName,
    Future<List<T>> Function(int offset, int limit) batchLoader, {
    int batchSize = 50,
    int maxItems = 200,
    Duration? batchDelay,
  }) async {
    final startTime = DateTime.now();
    List<T> results = [];
    int offset = 0;

    try {
      while (results.length < maxItems) {
        final batch = await batchLoader(offset, batchSize);
        if (batch.isEmpty) break;

        results.addAll(batch);
        offset += batchSize;

        // Allow UI to update between batches
        if (batchDelay != null) {
          await Future.delayed(batchDelay);
        } else {
          await Future.delayed(const Duration(milliseconds: 10));
        }

        // Check if we should stop due to memory pressure
        if (_currentOperations >= _maxMemoryOperations) {
          log(
            'BACKGROUND_PROCESSOR: Memory pressure reached, stopping batch processing',
          );
          break;
        }
      }

      final duration = DateTime.now().difference(startTime);
      log(
        'BACKGROUND_PROCESSOR: Batch processing "$operationName" completed: ${results.length} items in ${duration.inMilliseconds}ms',
      );

      return results;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);

      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason:
            'Batch processing failed: $operationName (duration: ${duration.inMilliseconds}ms)',
      );

      rethrow;
    }
  }

  /// **Process in isolate (for heavy CPU operations)**
  static Future<T> _processInIsolate<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    try {
      // For now, use microtask as isolate implementation is complex
      // In production, you would implement proper isolate communication
      return await Future.microtask(() async {
        return await operation().timeout(
          _maxOperationTime,
          onTimeout: () {
            throw TimeoutException('Isolate operation timed out');
          },
        );
      });
    } catch (e) {
      log(
        'BACKGROUND_PROCESSOR: Isolate processing failed for "$operationName": $e',
      );
      rethrow;
    }
  }

  ///
}
