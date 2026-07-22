import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'package:j_navigation/src/analytics/navigation_analytics_event.dart';
import 'package:j_navigation/src/analytics/navigation_analytics_sink.dart';
import 'package:j_navigation/src/analytics/navigation_screen_enter_event.dart';
import 'package:j_navigation/src/analytics/navigation_screen_exit_event.dart';

/// A background queue for processing navigation analytics events to prevent
/// UI blocking.
///
/// Events are [NavigationAnalyticsEvent]s (screen-enter or screen-exit). They
/// are forwarded to the provided [NavigationAnalyticsSink] after the current
/// frame is painted.
final class AnalyticsQueue {
  AnalyticsQueue(this._sink);

  final NavigationAnalyticsSink _sink;
  final Queue<NavigationAnalyticsEvent> _eventQueue =
      Queue<NavigationAnalyticsEvent>();
  bool _isProcessing = false;
  bool _isShutdown = false;

  /// The in-flight `flush` future, if any. Re-entrant callers await this so
  /// they do not resolve before `NavigationAnalyticsSink.flush` has run.
  Future<void>? _flushInFlight;

  /// Queues a navigation analytics event for background processing. The queue
  /// dispatches enter/exit events to the sink's `onScreenEnter` /
  /// `onScreenExit`.
  void enqueue(NavigationAnalyticsEvent event) {
    if (_isShutdown) return;

    _eventQueue.add(event);
    _scheduleProcessing();
  }

  void _scheduleProcessing() {
    if (_isProcessing || _eventQueue.isEmpty) return;

    // Schedule processing after frame is painted to avoid blocking navigation
    SchedulerBinding.instance.addPostFrameCallback((_) => _processQueue());
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _eventQueue.isEmpty) return;

    _isProcessing = true;

    try {
      while (_eventQueue.isNotEmpty) {
        final event = _eventQueue.removeFirst();

        try {
          switch (event) {
            case NavigationScreenEnterEvent():
              _sink.onScreenEnter(event);
            case NavigationScreenExitEvent():
              _sink.onScreenExit(event);
          }
        } on Object catch (e) {
          // Log error but continue processing other events. Debug-only so a
          // published package stays quiet on analytics sink failures.
          if (kDebugMode) {
            debugPrint('Navigation analytics event failed: $e');
          }
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Flushes all remaining events through the sink and shuts down the queue.
  ///
  /// Re-entrant calls await the same in-flight flush, so a caller that
  /// awaits `flush` while another flush is already running does not resolve
  /// before `NavigationAnalyticsSink.flush` has completed. This matters for
  /// `NavigationController.dispose`, which awaits `flush` before calling
  /// `super.dispose()` — without this guard a concurrent flush could let
  /// disposal proceed while the sink is still flushing.
  Future<void> flush() {
    if (_isShutdown) return _flushInFlight ?? Future<void>.value();

    _isShutdown = true;
    final future = _performFlush();
    _flushInFlight = future;
    return future;
  }

  Future<void> _performFlush() async {
    // Drain any remaining events synchronously first.
    await _processQueue();

    try {
      await _sink.flush();
    } on Object catch (e) {
      // Best-effort: a flush failure must not propagate into dispose().
      if (kDebugMode) {
        debugPrint('Navigation analytics flush failed: $e');
      }
    }
  }
}
