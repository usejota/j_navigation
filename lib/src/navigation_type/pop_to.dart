part of 'navigation_type.dart';

/// Pops back to the first occurrence of [screenName] when searching from the
/// top of the stack (last to first).
///
/// If no page with [screenName] exists, this action is a no-op.
final class PopTo extends NavigationType with PageNavigationType {
  const PopTo(this.screenName, {this.skipKeyboardDismissal = false});

  @override
  final String screenName;

  @override
  String get analyticsName => 'PopTo';

  @override
  final bool skipKeyboardDismissal;

  @override
  List<ViewNavigationType> navigationStackFrom(
    List<ViewNavigationType> currentStack,
  ) {
    final targetIndex = currentStack.lastIndexWhere(
      (page) => page.screenName == screenName,
    );

    if (targetIndex == -1) {
      return currentStack;
    }

    return currentStack.sublist(0, targetIndex + 1);
  }
}
