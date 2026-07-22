import 'package:j_navigation/src/analytics/navigation_analytics_event.dart';

/// A navigation analytics event emitted when a screen is entered.
///
/// Emitted to a `NavigationAnalyticsSink` when one is provided to the
/// navigation controller.
class NavigationScreenEnterEvent implements NavigationAnalyticsEvent {
  const NavigationScreenEnterEvent({
    required this.screenName,
    this.navigationMethod,
    this.sourceScreen,
    this.breadcrumb,
  });

  /// The name of the screen being entered.
  @override
  final String screenName;

  /// The navigation method that triggered the enter (push, present,
  /// replace, etc.).
  final String? navigationMethod;

  /// The screen the user navigated from.
  final String? sourceScreen;

  /// The breadcrumb trail of the navigation at enter time.
  final String? breadcrumb;

  @override
  String toString() =>
      'NavigationScreenEnterEvent(screenName: $screenName, '
      'navigationMethod: $navigationMethod, sourceScreen: $sourceScreen)';
}
