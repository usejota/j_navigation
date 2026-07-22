part of 'navigation_type.dart';

/// A navigation type that dismisses the current view.
///
/// When the dismissed view is a presented screen awaited via
/// `NavigationController.present<T>`, pass [result] to resolve that future
/// with a value — the idiomatic, action-based equivalent of
/// `Navigator.pop(context, result)`.
final class Dismiss extends NavigationType {
  const Dismiss({this.result, this.skipKeyboardDismissal = false});

  /// The value to resolve an in-flight `present<T>` with, if the dismissed
  /// view is a presented screen. `null` (the default) resolves with `null`.
  final Object? result;

  @override
  String get analyticsName => 'Dismiss';

  @override
  final bool skipKeyboardDismissal;

  @override
  List<ViewNavigationType> navigationStackFrom(
    List<ViewNavigationType> currentStack,
  ) {
    return currentStack.length <= 1
        ? currentStack
        : currentStack.sublist(0, currentStack.length - 1);
  }
}
