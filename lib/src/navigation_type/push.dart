// ignore_for_file: avoid-dynamic

part of 'navigation_type.dart';

/// A navigation type that pushes a new view onto the navigation stack.
final class Push extends ViewNavigationType with DismissableNavigationType {
  Push({
    required super.analyticsIdentifiable,
    super.navigationKey,
    this.swipeToDismissEnabled = true,
    bool animated = true,
    super.skipKeyboardDismissal,
  }) : super(
         animated:
             animated ||
             !swipeToDismissEnabled &&
                 defaultTargetPlatform == TargetPlatform.iOS,
       );

  @override
  String get analyticsName => 'Push';

  @override
  final bool swipeToDismissEnabled;

  @override
  List<ViewNavigationType> navigationStackFrom(
    List<ViewNavigationType> currentStack,
  ) {
    return [...currentStack, this];
  }

  @override
  Page<dynamic> buildAnimatedPage(BuildContext context) {
    if (!swipeToDismissEnabled && defaultTargetPlatform == TargetPlatform.iOS) {
      return NoSwipePage<dynamic>(
        key: key,
        name: screenName,
        child: builder(context),
      );
    }

    return super.buildAnimatedPage(context);
  }
}
