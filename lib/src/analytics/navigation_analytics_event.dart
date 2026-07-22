/// A navigation analytics event.
///
/// Implemented by the screen-enter and screen-exit event types so the
/// analytics queue can accept a single `enqueue(event)` entry point and
/// dispatch by type. Host sinks consume the concrete subtypes via
/// `onScreenEnter` / `onScreenExit`.
abstract interface class NavigationAnalyticsEvent {
  /// The screen this event concerns.
  String get screenName;
}
