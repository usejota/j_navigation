/// Tracks time spent on screens for analytics.
final class ScreenTimeTracker {
  final Map<String, Stopwatch> _screenStopwatches = {};

  /// Records when a screen was entered.
  void recordScreenEnter(String screenName) {
    final stopwatch = Stopwatch()..start();
    _screenStopwatches[screenName] = stopwatch;
  }

  /// Records when a screen was exited and returns time spent in seconds.
  int? recordScreenExit(String screenName) {
    final stopwatch = _screenStopwatches.remove(screenName);
    if (stopwatch == null) return null;

    stopwatch.stop();

    return stopwatch.elapsed.inSeconds;
  }

  /// Clears all tracked screen times (useful for testing).
  void clear() {
    _screenStopwatches.clear();
  }
}
