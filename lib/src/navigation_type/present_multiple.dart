// ignore_for_file: avoid-dynamic

part of 'navigation_type.dart';

/// A navigation type that presents a new view on top of the current view.
final class PresentMultiple extends ViewNavigationType {
  PresentMultiple({
    required super.analyticsIdentifiable,
    required this.hiddenPages,
    super.animated,
    super.navigationKey,
    super.skipKeyboardDismissal,
  });

  @override
  String get analyticsName => 'PresentMultiple';

  final List<ViewNavigationType> hiddenPages;

  @override
  List<ViewNavigationType> navigationStackFrom(
    List<ViewNavigationType> currentStack,
  ) {
    return [
      ...currentStack,
      ...hiddenPages,
      Present(
        analyticsIdentifiable: AnalyticsIdentifiable(
          screenName: screenName,
          builder: builder,
        ),
        navigationKey: key,
        animated: animated,
      ),
    ];
  }

  @override
  Page<dynamic> buildAnimatedPage(BuildContext context) {
    return MaterialPage<dynamic>(
      key: key,
      name: screenName,
      fullscreenDialog: true,
      child: builder(context),
    );
  }
}
