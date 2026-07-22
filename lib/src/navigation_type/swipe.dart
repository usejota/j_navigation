// ignore_for_file: avoid-dynamic

part of 'navigation_type.dart';

/// A navigation type that pushes a new view onto the navigation stack.
final class Swipe extends NoPageViewNavigationType {
  Swipe({
    required super.analyticsIdentifiable,
  });

  @override
  String get analyticsName => 'Swipe';

  @override
  bool get skipKeyboardDismissal => false;
}
