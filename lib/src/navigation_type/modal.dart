// ignore_for_file: avoid-dynamic

part of 'navigation_type.dart';

/// A navigation type for showing modal bottom sheets as screens.
final class Modal extends ViewNavigationType {
  Modal({
    required super.analyticsIdentifiable,
    super.skipKeyboardDismissal,
    super.navigationKey,
    this.isDismissible = true,
    this.enableDrag = true,
    this.isScrollControlled = false,
  });

  @override
  String get analyticsName => 'Modal';

  final bool isDismissible;
  final bool enableDrag;
  final bool isScrollControlled;

  @override
  List<ViewNavigationType> navigationStackFrom(
    List<ViewNavigationType> currentStack,
  ) {
    return [...currentStack, this];
  }

  @override
  Page<dynamic> buildAnimatedPage(BuildContext context) {
    return ModalBottomSheetPage<dynamic>(
      key: key,
      name: screenName,
      child: builder(context),
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
    );
  }
}
