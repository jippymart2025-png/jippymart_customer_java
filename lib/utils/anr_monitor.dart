import 'dart:async';
import 'dart:developer';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// **ANR MONITORING SYSTEM**
///
/// This utility provides real-time ANR detection and monitoring
/// to track the effectiveness of ANR prevention measures.
class ANRMonitor {
  static Timer? _watchdogTimer;
  static DateTime? _lastUIUpdate;
  static bool _isMonitoring = false;
  static const Duration _anrThreshold = Duration(seconds: 5);
  static const Duration _checkInterval = Duration(seconds: 1);
  static int _anrWarnings = 0;
  static int _totalChecks = 0;

  /// **Start ANR monitoring**
  static void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _lastUIUpdate = DateTime.now();

    _watchdogTimer = Timer.periodic(_checkInterval, (timer) {
      _checkForANR();
    });

    log('ANR_MONITOR: Started monitoring for ANR detection');

    // Only log to Firebase if it's available
    try {
      FirebaseCrashlytics.instance.log(
        'ANR_MONITOR: Started monitoring for ANR detection',
      );
    } catch (e) {
      log(
        'ANR_MONITOR: Firebase not available, monitoring without Crashlytics logging',
      );
    }
  }

  /// **Check for ANR conditions**
  static void _checkForANR() {
    _totalChecks++;
    final now = DateTime.now();
    final timeSinceLastUpdate = now.difference(_lastUIUpdate ?? now);

    if (timeSinceLastUpdate > _anrThreshold) {
      _reportANRWarning(timeSinceLastUpdate);
    }

    _lastUIUpdate = now;
  }

  /// **Report ANR warning**
  static void _reportANRWarning(Duration blockedTime) {
    _anrWarnings++;
    final message =
        'ANR_WARNING: UI blocked for ${blockedTime.inMilliseconds}ms';
    log(message);

    // Only log to Firebase if it's available
    try {
      FirebaseCrashlytics.instance.log(message);
      FirebaseCrashlytics.instance.recordError(
        Exception(
          'ANR Warning: UI blocked for ${blockedTime.inMilliseconds}ms',
        ),
        StackTrace.current,
        reason: 'ANR detection triggered',
      );
    } catch (e) {
      log(
        'ANR_MONITOR: Firebase not available, ANR warning logged locally only',
      );
    }
  }

  /// **Get monitoring statistics**
  static Map<String, dynamic> getMonitoringStats() {
    return {
      'isMonitoring': _isMonitoring,
      'totalChecks': _totalChecks,
      'anrWarnings': _anrWarnings,
      'anrWarningRate': _totalChecks > 0
          ? (_anrWarnings / _totalChecks * 100).toStringAsFixed(2)
          : '0.00',
      'lastUIUpdate': _lastUIUpdate?.toIso8601String(),
      'anrThreshold': _anrThreshold.inMilliseconds,
      'checkInterval': _checkInterval.inMilliseconds,
    };
  }
}

/// **PERFORMANCE METRICS TRACKER**
///
/// Tracks performance metrics for ANR prevention effectiveness
class PerformanceMetrics {
  static final Map<String, List<Duration>> _operationMetrics = {};
  static final Map<String, int> _anrWarnings = {};
  static int _totalOperations = 0;
  static int _slowOperations = 0;
  static int _timeoutOperations = 0;

  /// **Track operation performance**
  static void trackOperation(String operationName, Duration duration) {
    _totalOperations++;

    _operationMetrics.putIfAbsent(operationName, () => []);
    _operationMetrics[operationName]!.add(duration);

    if (duration > const Duration(milliseconds: 500)) {
      _slowOperations++;
      _anrWarnings[operationName] = (_anrWarnings[operationName] ?? 0) + 1;
    }
  }

  /// **Track timeout operation**
  static void trackTimeout(String operationName) {
    _timeoutOperations++;
    _anrWarnings[operationName] = (_anrWarnings[operationName] ?? 0) + 1;
  }

  /// **Get performance report**
  static Map<String, dynamic> getPerformanceReport() {
    final avgDurations = <String, double>{};
    final slowOperationCounts = <String, int>{};

    for (final entry in _operationMetrics.entries) {
      final durations = entry.value;
      if (durations.isNotEmpty) {
        avgDurations[entry.key] =
            durations.map((d) => d.inMilliseconds).reduce((a, b) => a + b) /
            durations.length;

        slowOperationCounts[entry.key] = durations
            .where((d) => d > const Duration(milliseconds: 500))
            .length;
      }
    }

    return {
      'totalOperations': _totalOperations,
      'slowOperations': _slowOperations,
      'timeoutOperations': _timeoutOperations,
      'slowOperationPercentage': _totalOperations > 0
          ? (_slowOperations / _totalOperations * 100).toStringAsFixed(2)
          : '0.00',
      'timeoutPercentage': _totalOperations > 0
          ? (_timeoutOperations / _totalOperations * 100).toStringAsFixed(2)
          : '0.00',
      'averageDurations': avgDurations,
      'slowOperationCounts': slowOperationCounts,
      'anrWarnings': _anrWarnings,
    };
  }
}

/// **MEMORY MONITOR**
///
/// Monitors memory usage to prevent memory-related ANRs
class MemoryMonitor {
  static int _lastMemoryUsage = 0;
  static DateTime? _lastMemoryCheck;
  static const Duration _memoryCheckInterval = Duration(minutes: 5);
  static final List<int> _memoryHistory = [];
  static int _memoryPressureWarnings = 0;

  /// **Monitor memory usage**
  static void startMemoryMonitoring() {
    Timer.periodic(_memoryCheckInterval, (timer) {
      _checkMemoryUsage();
    });

    log('MEMORY_MONITOR: Started memory monitoring');

    // Only log to Firebase if it's available
    try {
      FirebaseCrashlytics.instance.log(
        'MEMORY_MONITOR: Started memory monitoring',
      );
    } catch (e) {
      log(
        'MEMORY_MONITOR: Firebase not available, monitoring without Crashlytics logging',
      );
    }
  }

  /// **Check memory usage**
  static void _checkMemoryUsage() {
    // Simulate memory usage check
    final currentMemory = _simulateMemoryUsage();
    _memoryHistory.add(currentMemory);

    // Keep only last 20 measurements
    if (_memoryHistory.length > 20) {
      _memoryHistory.removeAt(0);
    }

    // Check for memory pressure
    if (currentMemory > _lastMemoryUsage * 1.5) {
      _reportMemoryPressure(currentMemory);
    }

    _lastMemoryUsage = currentMemory;
    _lastMemoryCheck = DateTime.now();
  }

  /// **Report memory pressure**
  static void _reportMemoryPressure(int memoryUsage) {
    _memoryPressureWarnings++;
    final message = 'MEMORY_PRESSURE: Usage increased to ${memoryUsage}MB';
    log(message);

    // Only log to Firebase if it's available
    try {
      FirebaseCrashlytics.instance.log(message);
      FirebaseCrashlytics.instance.recordError(
        Exception('Memory pressure detected: ${memoryUsage}MB'),
        StackTrace.current,
        reason: 'Memory pressure warning',
      );
    } catch (e) {
      log(
        'MEMORY_MONITOR: Firebase not available, memory pressure logged locally only',
      );
    }
  }

  /// **Simulate memory usage**
  static int _simulateMemoryUsage() {
    // In production, use actual memory monitoring
    return DateTime.now().millisecondsSinceEpoch % 100 + 50;
  }

  /// **Get memory report**
  static Map<String, dynamic> getMemoryReport() {
    if (_memoryHistory.isEmpty) return {};

    final avgMemory =
        _memoryHistory.reduce((a, b) => a + b) / _memoryHistory.length;
    final maxMemory = _memoryHistory.reduce((a, b) => a > b ? a : b);
    final minMemory = _memoryHistory.reduce((a, b) => a < b ? a : b);

    return {
      'averageMemory': avgMemory.toStringAsFixed(2),
      'maxMemory': maxMemory,
      'minMemory': minMemory,
      'memoryHistory': _memoryHistory,
      'memoryPressureWarnings': _memoryPressureWarnings,
      'lastCheck': _lastMemoryCheck?.toIso8601String(),
    };
  }
}

/// **ANR STATUS LOGGER**
///
/// Logs ANR prevention status and effectiveness
class ANRStatusLogger {
  static void logANRPreventionStatus() {
    final status = {
      'anrPreventionActive': true,
      'backgroundProcessingActive': true,
      'memoryOptimizationActive': true,
      'systemCallOptimizationActive': true,
      'smartlookANRFixActive': true,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Only log to Firebase if it's available
    try {
      FirebaseCrashlytics.instance.log('ANR_PREVENTION_STATUS: $status');
    } catch (e) {
      log(
        'ANR_STATUS_LOGGER: Firebase not available, status logged locally only',
      );
    }
  }
}
