part of 'navigation_type.dart';

final class ReplaceStack extends ViewNavigationType
    with DismissableNavigationType {
  ReplaceStack({
    required super.analyticsIdentifiable,
    required this.animationType,
    super.navigationKey,
    this.hiddenPages = const [],
    super.skipKeyboardDismissal,
  });

  @override
  String get analyticsName => 'ReplaceStack';

  final List<ViewNavigationType> hiddenPages;

  final ReplaceAnimationType animationType;

  @override
  bool get animated => animationType.animated;

  @override
  bool get swipeToDismissEnabled => animationType.swipeToDismissEnabled;

  @override
  List<ViewNavigationType> navigationStackFrom(
    List<ViewNavigationType> currentStack,
  ) {
    return [
      ...hiddenPages,
      animationType.navigationType(analyticsIdentifiable, key),
    ];
  }
}
