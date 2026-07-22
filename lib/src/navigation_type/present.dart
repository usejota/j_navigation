// ignore_for_file: avoid-dynamic

part of 'navigation_type.dart';

/// Controls the visual transition used when presenting a page.
enum PresentTransition {
  /// Default platform present transition (slide up from bottom).
  standard,

  /// Cross-fade transition — the new page fades in over the previous one.
  fade,
}

/// A navigation type that presents a new view on top of the current view.
///
/// A presented screen can return a result by calling
/// `Navigator.pop(context, result)`. Await `NavigationController.present` (or
/// `dismissed`) to receive it. `dismissed` requires `animated` (the default);
/// a non-animated presentation does not wire a result.
final class Present extends ViewNavigationType {
  Present({
    required super.analyticsIdentifiable,
    super.animated,
    super.navigationKey,
    this.transition = .standard,
    super.skipKeyboardDismissal,
  });

  final Completer<Object?> _dismissedCompleter = Completer<Object?>();

  /// Completes with the result the presented screen was dismissed with.
  ///
  /// Resolves with the [Dismiss.result] when a `Dismiss(result: ...)` action
  /// dismisses this screen, with the value passed to `Navigator.pop` when the
  /// screen pops itself, or with `null` on a bare programmatic dismiss.
  /// Prefer `NavigationController.present` for a typed result.
  Future<Object?> get dismissed => _dismissedCompleter.future;

  /// Completes [dismissed] with [result] if it has not already completed.
  ///
  /// Called by the controller when a `Dismiss(result: ...)` action dismisses
  /// this presented screen, so an in-flight `present<T>` resolves with the
  /// action's value instead of `null`.
  void completeWith(Object? result) {
    if (!_dismissedCompleter.isCompleted) {
      _dismissedCompleter.complete(result);
    }
  }

  @override
  String get analyticsName => 'Present';

  /// The visual transition style for this presentation.
  final PresentTransition transition;

  @override
  List<ViewNavigationType> navigationStackFrom(
    List<ViewNavigationType> currentStack,
  ) {
    return [...currentStack, this];
  }

  @override
  Page<Object?> buildAnimatedPage(BuildContext context) {
    return _PresentResultPage(
      key: key,
      name: screenName,
      child: builder(context),
      completer: _dismissedCompleter,
      transition: transition,
    );
  }
}

/// A [Page] that wires the route's `popped` result into a [Completer] so a
/// [Present] action can await the value the presented screen returns from
/// `Navigator.pop(context, result)`.
class _PresentResultPage extends Page<Object?> {
  const _PresentResultPage({
    required this.child,
    required this.completer,
    required this.transition,
    required super.key,
    required super.name,
  });

  final Widget child;
  final Completer<Object?> completer;
  final PresentTransition transition;

  @override
  Route<Object?> createRoute(BuildContext context) {
    final Route<Object?> route = switch (transition) {
      PresentTransition.fade => PageRouteBuilder<Object?>(
        settings: this,
        pageBuilder: (_, _, _) => child,
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      PresentTransition.standard => MaterialPageRoute<Object?>(
        settings: this,
        builder: (_) => child,
        fullscreenDialog: true,
      ),
    };

    // Complete with the pop result. `ModalRoute.popped` resolves when the
    // route is popped (user back, Navigator.pop(result), or declarative
    // removal from the pages list — which resolves with `null`).
    unawaited(
      route.popped.then((result) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      }),
    );
    return route;
  }
}
