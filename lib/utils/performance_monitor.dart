import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// **COMPREHENSIVE PERFORMANCE MONITORING UTILITY**
///
/// This utility provides:
/// - ANR detection and prevention
/// - Performance metrics tracking
/// - Memory usage monitoring
/// - Background task management
/// - Crash reporting integration
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();

  factory PerformanceMonitor() => _instance;

  PerformanceMonitor._internal();

  // **PERFORMANCE METRICS**
  final Map<String, List<Duration>> _operationDurations = {};
  final Map<String, int> _operationCounts = {};
  final Map<String, int> _slowOperationCounts = {};

  // **ANR PREVENTION**
  static const Duration _anrThreshold = Duration(milliseconds: 500);
  static const Duration _criticalThreshold = Duration(milliseconds: 1000);
  final List<Timer> _activeTimers = [];
  final List<Completer<void>> _pendingOperations = [];

  // **MEMORY MONITORING**
  int _lastMemoryUsage = 0;
  DateTime? _lastMemoryCheck;
  static const Duration _memoryCheckInterval = Duration(minutes: 5);

  /// **START OPERATION MONITORING**
  ///
  /// Wraps an operation with performance monitoring and ANR prevention
  static Future<T> monitorOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    Duration? timeout,
    bool logToCrashlytics = true,
  }) async {
    final monitor = PerformanceMonitor();
    return monitor._monitorOperationInternal(
      operationName,
      operation,
      timeout: timeout,
      logToCrashlytics: logToCrashlytics,
    );
  }

  /// **MONITOR SYNC OPERATION**

  /// **BACKGROUND TASK EXECUTOR**
  ///
  /// Ensures heavy operations run in background to prevent ANR
  static Future<T> executeInBackground<T>(
    String taskName,
    Future<T> Function() task, {
    Duration? timeout,
  }) async {
    final monitor = PerformanceMonitor();
    return monitor._executeInBackgroundInternal(
      taskName,
      task,
      timeout: timeout,
    );
  }

  /// **MEMORY USAGE CHECK**

  /// **CLEANUP RESOURCES**

  /// **GET PERFORMANCE REPORT**

  // **INTERNAL IMPLEMENTATION**

  Future<T> _monitorOperationInternal<T>(
    String operationName,
    Future<T> Function() operation, {
    Duration? timeout,
    bool logToCrashlytics = true,
  }) async {
    final startTime = DateTime.now();
    final completer = Completer<T>();
    Timer? timeoutTimer;

    try {
      // Add to pending operations for ANR detection
      _pendingOperations.add(completer);

      // Set timeout if specified
      if (timeout != null) {
        timeoutTimer = Timer(timeout, () {
          if (!completer.isCompleted) {
            final error = TimeoutException(
              'Operation timed out: $operationName',
              timeout,
            );
            completer.completeError(error);

            if (logToCrashlytics) {
              FirebaseCrashlytics.instance.recordError(
                error,
                StackTrace.current,
                reason: 'Operation timeout: $operationName',
              );
            }
          }
        });
        _activeTimers.add(timeoutTimer);
      }

      // Execute operation
      final result = await operation();

      // Record performance metrics
      _recordOperationPerformance(operationName, startTime);

      // Complete successfully
      if (!completer.isCompleted) {
        completer.complete(result);
      }

      return result;
    } catch (e, stackTrace) {
      // Record error
      if (logToCrashlytics) {
        FirebaseCrashlytics.instance.recordError(
          e,
          stackTrace,
          reason: 'Operation failed: $operationName',
        );
      }

      // Complete with error
      if (!completer.isCompleted) {
        completer.completeError(e, stackTrace);
      }

      rethrow;
    } finally {
      // Cleanup
      _pendingOperations.remove(completer);
      if (timeoutTimer != null) {
        timeoutTimer.cancel();
        _activeTimers.remove(timeoutTimer);
      }
    }
  }

  Future<T> _executeInBackgroundInternal<T>(
    String taskName,
    Future<T> Function() task, {
    Duration? timeout,
  }) async {
    return monitorOperation('Background: $taskName', () async {
      // Use compute for CPU-intensive tasks
      if (_isCpuIntensive(taskName)) {
        return await compute((_) async => await task(), null);
      } else {
        // Use Future.delayed to move to next frame for UI tasks
        await Future.delayed(Duration.zero);
        return await task();
      }
    }, timeout: timeout);
  }

  void _recordOperationPerformance(String operationName, DateTime startTime) {
    final duration = DateTime.now().difference(startTime);

    // Initialize lists if needed
    _operationDurations.putIfAbsent(operationName, () => []);
    _operationCounts[operationName] =
        (_operationCounts[operationName] ?? 0) + 1;

    // Record duration
    _operationDurations[operationName]!.add(duration);

    // Check for slow operations
    if (duration > _anrThreshold) {
      _slowOperationCounts[operationName] =
          (_slowOperationCounts[operationName] ?? 0) + 1;

      if (duration > _criticalThreshold) {
        log(
          'CRITICAL: Very slow operation detected: $operationName took ${duration.inMilliseconds}ms',
        );
        FirebaseCrashlytics.instance.log(
          'Critical slow operation: $operationName - ${duration.inMilliseconds}ms',
        );
      } else {
        log(
          'WARNING: Slow operation detected: $operationName took ${duration.inMilliseconds}ms',
        );
      }
    }

    // Log performance metrics
    if (kDebugMode) {
      print(
        'PERFORMANCE: $operationName completed in ${duration.inMilliseconds}ms',
      );
    }
  }

  bool _isCpuIntensive(String taskName) {
    final cpuIntensiveTasks = [
      'search',
      'parse',
      'encode',
      'decode',
      'compress',
      'decompress',
      'calculate',
      'process',
    ];

    return cpuIntensiveTasks.any(
      (keyword) => taskName.toLowerCase().contains(keyword),
    );
  }
}

/// **ANR PREVENTION MIXIN**
///
/// Add this mixin to controllers that need ANR prevention
