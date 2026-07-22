import 'package:j_navigation/src/analytics/navigation_analytics_event.dart';

/// A navigation analytics event emitted when a screen is exited.
///
/// Emitted to a `NavigationAnalyticsSink` when one is provided to the
/// navigation controller.
class NavigationScreenExitEvent implements NavigationAnalyticsEvent {
  const NavigationScreenExitEvent({
    required this.screenName,
    this.exitMethod,
    this.destinationScreen,
    this.timeSpent,
  });

  /// The name of the screen being exited.
  @override
  final String screenName;

  /// The method used to exit (dismiss, pop, replace, etc.).
  final String? exitMethod;

  /// The screen the user navigated to.
  final String? destinationScreen;

  /// Time spent on the screen in seconds, if tracked.
  final int? timeSpent;

  @override
  String toString() =>
      'NavigationScreenExitEvent(screenName: $screenName, '
      'exitMethod: $exitMethod, destinationScreen: $destinationScreen, '
      'timeSpent: $timeSpent)';
}
