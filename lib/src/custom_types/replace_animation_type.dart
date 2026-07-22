import 'package:flutter/material.dart';
import 'package:j_navigation/src/analytics/analytics_identifiable.dart';
import 'package:j_navigation/src/navigation_type/navigation_type.dart';

abstract base class ReplaceAnimationType {
  const ReplaceAnimationType({required this.animated});

  final bool animated;
  bool get swipeToDismissEnabled;

  ViewNavigationType navigationType(
    AnalyticsIdentifiable analyticsIdentifiable,
    ValueKey<String> key,
  );
}

final class ReplaceAnimationTypeNone extends ReplaceAnimationType {
  const ReplaceAnimationTypeNone({this.swipeToDismissEnabled = true})
    : super(animated: false);

  @override
  final bool swipeToDismissEnabled;

  @override
  ViewNavigationType navigationType(
    AnalyticsIdentifiable analyticsIdentifiable,
    ValueKey<String> key,
  ) => Push(
    analyticsIdentifiable: analyticsIdentifiable,
    navigationKey: key,
    animated: animated,
    swipeToDismissEnabled: swipeToDismissEnabled,
  );
}

final class ReplaceAnimationTypePush extends ReplaceAnimationType {
  const ReplaceAnimationTypePush({
    this.swipeToDismissEnabled = true,
    super.animated = true,
  });

  @override
  final bool swipeToDismissEnabled;

  @override
  ViewNavigationType navigationType(
    AnalyticsIdentifiable analyticsIdentifiable,
    ValueKey<String> key,
  ) => Push(
    analyticsIdentifiable: analyticsIdentifiable,
    navigationKey: key,
    animated: animated,
    swipeToDismissEnabled: swipeToDismissEnabled,
  );
}

final class ReplaceAnimationTypePresent extends ReplaceAnimationType {
  const ReplaceAnimationTypePresent({super.animated = true});

  @override
  bool get swipeToDismissEnabled => true;

  @override
  ViewNavigationType navigationType(
    AnalyticsIdentifiable analyticsIdentifiable,
    ValueKey<String> key,
  ) => Present(
    analyticsIdentifiable: analyticsIdentifiable,
    navigationKey: key,
    animated: animated,
  );
}

final class ReplaceAnimationTypeCustom extends ReplaceAnimationType {
  const ReplaceAnimationTypeCustom({
    required this.handler,
    required this.swipeToDismissEnabled,
    super.animated = true,
  });

  final ViewNavigationType Function(
    AnalyticsIdentifiable analyticsIdentifiable,
    ValueKey<String> key, {
    required bool animated,
  })
  handler;
  @override
  final bool swipeToDismissEnabled;

  @override
  ViewNavigationType navigationType(
    AnalyticsIdentifiable analyticsIdentifiable,
    ValueKey<String> key,
  ) => handler(analyticsIdentifiable, key, animated: animated);
}
