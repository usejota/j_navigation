// ignore_for_file: avoid-dynamic

part of 'navigation_type.dart';

final class ReplaceTop extends ViewNavigationType
    with DismissableNavigationType {
  ReplaceTop({
    required super.analyticsIdentifiable,
    required this.animationType,
    super.navigationKey,
    super.skipKeyboardDismissal,
  });

  @override
  String get analyticsName => 'ReplaceTop';

  final ReplaceAnimationType animationType;

  @override
  bool get swipeToDismissEnabled => animationType.swipeToDismissEnabled;
  @override
  bool get animated => animationType.animated;

  @override
  List<ViewNavigationType> navigationStackFrom(
    List<ViewNavigationType> currentStack,
  ) {
    return [
      ...currentStack.take(currentStack.length - 1),
      animationType.navigationType(analyticsIdentifiable, key),
    ];
  }
}
