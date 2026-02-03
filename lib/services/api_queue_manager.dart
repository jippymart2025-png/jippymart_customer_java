import 'dart:async';
import 'dart:collection';

enum RequestPriority {
  low,
  normal,
  high,
  critical,
}

enum CancellableRequest {
  cancellable,
  nonCancellable,
}

class QueuedRequest {
  final RequestPriority priority;
  final Future Function() request;
  final CancellableRequest cancellable;
  final Completer completer;
  final String? key; // For deduplication

  QueuedRequest({
    required this.priority,
    required this.request,
    required this.cancellable,
    this.key,
  }) : completer = Completer();

  int get priorityValue {
    switch (priority) {
      case RequestPriority.critical:
        return 4;
      case RequestPriority.high:
        return 3;
      case RequestPriority.normal:
        return 2;
      case RequestPriority.low:
        return 1;
    }
  }
}

class ApiQueueManager {
  static const int MAX_CONCURRENT_REQUESTS = 3;
  final Queue<QueuedRequest> _requestQueue = Queue<QueuedRequest>();
  final Set<String> _activeRequests = {};
  final Map<String, QueuedRequest> _deduplicationMap = {};
  bool _isProcessing = false;
  Timer? _processingTimer;

  static final ApiQueueManager _instance = ApiQueueManager._internal();

  factory ApiQueueManager() => _instance;

  ApiQueueManager._internal() {
    _startProcessing();
  }

  void _startProcessing() {
    _processingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_isProcessing && _requestQueue.isNotEmpty && _activeRequests.length < MAX_CONCURRENT_REQUESTS) {
        _processNextRequest();
      }
    });
  }

  Future<T> enqueue<T>({
    required RequestPriority priority,
    required Future<T> Function() request,
    CancellableRequest cancellable = CancellableRequest.cancellable,
    String? key,
  }) async {
    // Check for deduplication
    if (key != null && _deduplicationMap.containsKey(key)) {
      print('[API_QUEUE] 🔄 Request deduplicated: $key');
      return await _deduplicationMap[key]!.completer.future;
    }

    final queuedRequest = QueuedRequest(
      priority: priority,
      request: request,
      cancellable: cancellable,
      key: key,
    );

    if (key != null) {
      _deduplicationMap[key] = queuedRequest;
    }

    _requestQueue.add(queuedRequest);

    // Sort queue by priority (higher priority first)
    final queueList = _requestQueue.toList();
    queueList.sort((a, b) => b.priorityValue.compareTo(a.priorityValue));
    _requestQueue.clear();
    _requestQueue.addAll(queueList);

    print('[API_QUEUE] 📋 Request enqueued (priority: ${priority.name}, queue size: ${_requestQueue.length})');

    return await queuedRequest.completer.future;
  }

  void _processNextRequest() {
    if (_requestQueue.isEmpty || _activeRequests.length >= MAX_CONCURRENT_REQUESTS) {
      return;
    }

    _isProcessing = true;

    final request = _requestQueue.removeFirst();
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();

    _activeRequests.add(requestId);

    print('[API_QUEUE] 🚀 Processing request (active: ${_activeRequests.length}, queue: ${_requestQueue.length})');

    request.request().then((result) {
      if (!request.completer.isCompleted) {
        request.completer.complete(result);
      }
    }).catchError((error) {
      if (!request.completer.isCompleted) {
        request.completer.completeError(error);
      }
    }).whenComplete(() {
      _activeRequests.remove(requestId);
      if (request.key != null) {
        _deduplicationMap.remove(request.key);
      }
      _isProcessing = false;
      print('[API_QUEUE] ✅ Request completed (active: ${_activeRequests.length})');
    });
  }

  /// Cancel all cancellable requests
  void cancelCancellableRequests() {
    final cancellableRequests = _requestQueue.where((req) => req.cancellable == CancellableRequest.cancellable).toList();
    for (final request in cancellableRequests) {
      _requestQueue.remove(request);
      if (!request.completer.isCompleted) {
        request.completer.completeError(Exception('Request cancelled'));
      }
      if (request.key != null) {
        _deduplicationMap.remove(request.key);
      }
    }
    print('[API_QUEUE] 🛑 Cancelled ${cancellableRequests.length} cancellable requests');
  }

  /// Get queue statistics
  Map<String, dynamic> getStats() {
    return {
      'queueSize': _requestQueue.length,
      'activeRequests': _activeRequests.length,
      'deduplicationSize': _deduplicationMap.length,
      'isProcessing': _isProcessing,
    };
  }

  /// Clear all queues and cancel pending requests
  void clear() {
    _requestQueue.clear();
    _deduplicationMap.clear();

    for (final request in _requestQueue) {
      if (!request.completer.isCompleted) {
        request.completer.completeError(Exception('Queue cleared'));
      }
    }

    print('[API_QUEUE] 🧹 Queue cleared');
  }

  void dispose() {
    _processingTimer?.cancel();
    clear();
  }
}
