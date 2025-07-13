import 'dart:async';

class Debouncer {
  final Map<dynamic, Timer?> _operations = {};

  call(
    dynamic tag,
    Function func, {
    List<dynamic>? args,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    final timer = _operations[tag];
    if (timer != null) {
      timer.cancel();
    }
    _operations[tag] = Timer(
      duration,
      () {
        _operations[tag]?.cancel();
        _operations.remove(tag);
        Function.apply(
          func,
          args,
        );
      },
    );
  }

  cancel(dynamic tag) {
    _operations[tag]?.cancel();
    _operations[tag] = null;
  }
}

class Throttler {
  final Map<dynamic, Timer?> _operations = {};

  call(
    dynamic tag,
    Function func, {
    List<dynamic>? args,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    final timer = _operations[tag];
    if (timer != null) {
      return true;
    }
    _operations[tag] = Timer(
      duration,
      () {
        _operations[tag]?.cancel();
        _operations.remove(tag);
        Function.apply(
          func,
          args,
        );
      },
    );
    return false;
  }

  cancel(dynamic tag) {
    _operations[tag]?.cancel();
    _operations[tag] = null;
  }
}

Future<T> retry<T>({
  required Future<T> Function() task,
  int maxAttempts = 3,
  required bool Function(T res) retryIf,
  Duration delay = Duration.zero,
}) async {
  int attempts = 0;
  Exception? lastException;
  T? lastResult;

  while (attempts < maxAttempts) {
    try {
      final res = await task();
      lastResult = res;
      
      // If we shouldn't retry based on the result, return immediately
      if (!retryIf(res)) {
        return res;
      }
      
      attempts++;
      
      // If this was our last attempt, break the loop
      if (attempts >= maxAttempts) {
        break;
      }
      
      // Wait before retrying if delay is specified
      if (delay > Duration.zero) {
        await Future.delayed(delay);
      }
    } catch (e) {
      lastException = e is Exception ? e : Exception(e.toString());
      attempts++;
      
      // If this was our last attempt, break the loop
      if (attempts >= maxAttempts) {
        break;
      }
      
      // Wait before retrying if delay is specified
      if (delay > Duration.zero) {
        await Future.delayed(delay);
      }
    }
  }
  
  // If we have an exception from the last attempt, throw it
  if (lastException != null) {
    throw lastException!;
  }
  
  // If we have a result but it didn't meet our criteria, return it anyway
  if (lastResult != null) {
    return lastResult!;
  }
  
  // This should not happen, but provide a meaningful error message
  throw Exception("Retry failed after $maxAttempts attempts with no result or exception captured");
}

final debouncer = Debouncer();

final throttler = Throttler();
