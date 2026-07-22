import 'package:j_navigation/navigation.dart';

/// Mock analytics sink for the example app — captures navigation events so
/// the Analytics page can display them. Real apps adapt this to their own
/// analytics stack (Firebase, AppsFlyer, PostHog, etc.).
final class MockAnalyticsSink implements NavigationAnalyticsSink {
  final List<Object> events = [];

  @override
  void onScreenEnter(NavigationScreenEnterEvent event) => events.add(event);

  @override
  void onScreenExit(NavigationScreenExitEvent event) => events.add(event);

  @override
  Future<void> flush() async {}
}
