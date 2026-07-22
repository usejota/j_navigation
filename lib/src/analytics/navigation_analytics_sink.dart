import 'package:j_navigation/src/analytics/navigation_screen_enter_event.dart';
import 'package:j_navigation/src/analytics/navigation_screen_exit_event.dart';

/// A sink for navigation analytics events.
///
/// `j_navigation` does not depend on a concrete analytics package. Instead it
/// emits screen-enter / screen-exit events to an optional
/// [NavigationAnalyticsSink] provided to `NavigationController`. Host apps
/// implement this interface and adapt the events to whatever analytics stack
/// they use.
///
/// When no sink is provided, `NavigationController` silently skips analytics —
/// the "no analytics" build.
interface class NavigationAnalyticsSink {
  /// Creates a navigation analytics sink.
  ///
  /// Subclasses override [onScreenEnter], [onScreenExit], and optionally
  /// [flush] to receive events. Use the default const constructor for a
  /// no-op sink.
  const NavigationAnalyticsSink();

  /// Called when a screen is entered via navigation.
  void onScreenEnter(NavigationScreenEnterEvent event) {}

  /// Called when a screen is exited via navigation.
  void onScreenExit(NavigationScreenExitEvent event) {}

  /// Flushes any buffered events. Called on controller dispose.
  ///
  /// Default is a no-op; subclasses buffering events should override.
  Future<void> flush() async {}
}
