part of 'navigation_type.dart';

final class PushMultiple extends ViewNavigationType {
  PushMultiple({
    required super.analyticsIdentifiable,
    required this.hiddenPages,
    super.animated,
    super.navigationKey,
    super.skipKeyboardDismissal,
  });

  @override
  String get analyticsName => 'PushMultiple';

  final List<ViewNavigationType> hiddenPages;

  @override
  List<ViewNavigationType> navigationStackFrom(
    List<ViewNavigationType> currentStack,
  ) {
    return [
      ...currentStack,
      ...hiddenPages,
      Push(
        analyticsIdentifiable: AnalyticsIdentifiable(
          screenName: screenName,
          builder: builder,
        ),
        navigationKey: key,
        animated: animated,
      ),
    ];
  }
}
