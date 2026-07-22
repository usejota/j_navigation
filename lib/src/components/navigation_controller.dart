// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:j_navigation/src/analytics/analytics_identifiable.dart';
import 'package:j_navigation/src/analytics/analytics_queue.dart';
import 'package:j_navigation/src/analytics/navigation_analytics_sink.dart';
import 'package:j_navigation/src/analytics/navigation_screen_enter_event.dart';
import 'package:j_navigation/src/analytics/navigation_screen_exit_event.dart';
import 'package:j_navigation/src/analytics/screen_time_tracker.dart';
import 'package:j_navigation/src/branch/navigation_branch.dart';
import 'package:j_navigation/src/custom_types/same_page_replace_type.dart';
import 'package:j_navigation/src/navigation_type/navigation_type.dart';

/// A controller for managing the navigation stack.
///
/// When `analyticsSink` is provided, the controller emits screen-enter and
/// screen-exit events to it as navigation happens. When omitted (or the const
/// no-op sink is used), the controller runs without analytics — the
/// "no analytics" build.
interface class NavigationController extends ChangeNotifier {
  NavigationController(
    ViewNavigationType initialNavigation, {
    NavigationAnalyticsSink? analyticsSink,
  }) : this._(
         branches: {
           _defaultBranchId: [initialNavigation],
         },
         branchMetadata: {
           _defaultBranchId: _BranchMetadata(
             wantsKeepAlive: true,
             screenName: initialNavigation.screenName,
           ),
         },
         activeBranchId: _defaultBranchId,
         initialNavigation: initialNavigation,
         analyticsSink: analyticsSink,
       );

  /// Constructs a tabbed controller with independent per-branch stacks.
  ///
  /// [branches] must be non-empty and have unique [NavigationBranch.id]s.
  /// When [initialBranchId] is omitted, the first branch is active. The active
  /// branch's [NavigationBranch.initialNavigation] seeds analytics.
  factory NavigationController.tabbed({
    required List<NavigationBranch> branches,
    NavigationBranchId? initialBranchId,
    NavigationAnalyticsSink? analyticsSink,
  }) {
    if (branches.isEmpty) {
      throw ArgumentError.value(
        branches,
        'branches',
        'At least one branch is required.',
      );
    }
    final seen = <NavigationBranchId>{};
    final branchMap = <NavigationBranchId, List<ViewNavigationType>>{};
    final metadataMap = <NavigationBranchId, _BranchMetadata>{};
    for (final branch in branches) {
      if (!seen.add(branch.id)) {
        throw ArgumentError.value(
          branch.id,
          'branches',
          'Duplicate branch id.',
        );
      }
      branchMap[branch.id] = [branch.initialNavigation];
      metadataMap[branch.id] = _BranchMetadata(
        wantsKeepAlive: branch.wantsKeepAlive,
        screenName: branch.resolvedScreenName,
      );
    }
    final activeId = initialBranchId ?? branches.first.id;
    if (!branchMap.containsKey(activeId)) {
      throw ArgumentError.value(
        initialBranchId,
        'initialBranchId',
        'Not a registered branch id.',
      );
    }
    return NavigationController._(
      branches: branchMap,
      branchMetadata: metadataMap,
      activeBranchId: activeId,
      initialNavigation: branchMap[activeId]!.first,
      analyticsSink: analyticsSink,
    );
  }

  NavigationController._({
    required this._branches,
    required this._branchMetadata,
    required this._activeBranchId,
    required ViewNavigationType initialNavigation,
    required NavigationAnalyticsSink? analyticsSink,
  }) : _analyticsQueue = analyticsSink != null
           ? AnalyticsQueue(analyticsSink)
           : null,
       _screenTimeTracker = ScreenTimeTracker() {
    final newScreenName = _getScreenName(initialNavigation, 'initial');
    _breadcrumb = 'root:$newScreenName';
    _analyticsQueue?.enqueue(
      NavigationScreenEnterEvent(
        screenName: newScreenName,
        sourceScreen: 'root',
        navigationMethod: 'initial',
        breadcrumb: _breadcrumb,
      ),
    );
    _screenTimeTracker.recordScreenEnter(newScreenName);
    _currentScreenName = newScreenName;
  }

  // Navigation properties
  bool _isPerformingUserInitiatedNavigation = false;
  Set<String> _pagesToIgnoreRemoval = {};

  /// Identity of the anonymous branch used when the controller is constructed
  /// without branches. A private const sentinel so app-supplied branch ids can
  /// never collide with it.
  static const _defaultBranchId = _DefaultBranchId();

  /// Per-branch navigation stacks. The active branch's stack is what the router
  /// renders.
  final Map<NavigationBranchId, List<ViewNavigationType>> _branches;

  /// Per-branch metadata (keep-alive, screen name).
  final Map<NavigationBranchId, _BranchMetadata> _branchMetadata;

  /// The currently active branch. Mutated by a branch-switch navigation type.
  NavigationBranchId _activeBranchId;

  /// The active branch's mutable stack. Existing in-place mutations
  /// (`..clear()..addAll(...)`) operate on this list.
  List<ViewNavigationType> get _resolvedNavigationStack =>
      _branches[_activeBranchId]!;

  final Map<ValueKey<String>, bool Function()> _dismissCallbacks = {};
  final Map<ValueKey<String>, bool Function(NavigationType action)>
  _navigationCallbacks = {};
  _KeyboardDismissObserver? _pendingKeyboardObserver;
  final List<
    ({NavigationType action, SamePageNavigationReplaceType samePageReplaceType})
  >
  _pendingNavigations = [];

  // Analytics properties
  final AnalyticsQueue? _analyticsQueue;
  final ScreenTimeTracker _screenTimeTracker;
  late String _currentScreenName;
  late String _breadcrumb;

  Uri? _pendingDeepLinkUri;

  /// Returns the current navigation stack
  List<ViewNavigationType> get currentNavigationStack =>
      List.unmodifiable(_resolvedNavigationStack);

  /// The active branch identifier.
  NavigationBranchId get activeBranchId => _activeBranchId;

  /// Whether the controller was configured with multiple branches.
  bool get isTabbed => _branches.length > 1;

  /// All configured branch ids, in registration order.
  List<NavigationBranchId> get branchIds => _branches.keys.toList();

  /// The keep-alive preference for [id]. Defaults to `true` for the anonymous
  /// default branch and unknown ids.
  bool wantsKeepAlive(NavigationBranchId id) =>
      _branchMetadata[id]?.wantsKeepAlive ?? true;

  /// The screen name used to serialize the active branch in the web URL.
  String? get activeBranchScreenName =>
      _branchMetadata[_activeBranchId]?.screenName;

  /// Returns the stack for [id], or an empty list when unregistered.
  List<ViewNavigationType> stackForBranch(NavigationBranchId id) =>
      List<ViewNavigationType>.unmodifiable(
        _branches[id] ?? const <ViewNavigationType>[],
      );

  String get breadcrumb => _breadcrumb;

  /// Registers a dismiss callback for a specific page.
  void registerDismissCallback(
    ValueKey<String> pageKey,
    bool Function() callback,
  ) {
    _dismissCallbacks[pageKey] = callback;
  }

  /// Registers a navigation callback for a specific page.
  ///
  /// The callback can block navigation actions while a given page is on top.
  /// Return `true` to allow the navigation action, `false` to block it.
  void registerNavigationCallback(
    ValueKey<String> pageKey,
    bool Function(NavigationType action) callback,
  ) {
    _navigationCallbacks[pageKey] = callback;
  }

  /// Unregisters a dismiss callback for a specific page.
  void unregisterDismissCallback(ValueKey<String> pageKey) {
    _dismissCallbacks.remove(pageKey);
  }

  /// Unregisters a navigation callback for a specific page.
  void unregisterNavigationCallback(ValueKey<String> pageKey) {
    _navigationCallbacks.remove(pageKey);
  }

  /// Checks if the current page can be dismissed.
  bool _canDismissCurrentPage() {
    final topPage = _resolvedNavigationStack.lastOrNull;
    if (topPage == null) return true;

    final callback = _dismissCallbacks[topPage.key];
    if (callback != null) {
      return callback();
    }

    return true; // Default: allow dismiss
  }

  bool _canNavigateFromCurrentPage(NavigationType action) {
    final topPage = _resolvedNavigationStack.lastOrNull;
    if (topPage == null) return true;

    final callback = _navigationCallbacks[topPage.key];
    if (callback != null) {
      return callback(action);
    }

    return true; // Default: allow navigation
  }

  /// Navigates using the given action.
  ///
  /// If the software keyboard is visible, it is dismissed first and the
  /// navigation is deferred until the keyboard dismiss animation completes.
  ///
  /// Analytics events are emitted only when an `analyticsSink` was provided
  /// to the constructor; otherwise navigation runs without analytics.
  bool navigate(
    NavigationType action, {
    SamePageNavigationReplaceType samePageReplaceType =
        const SamePageNavigationReplaceTop(),
  }) {
    final hasKeyboard =
        (WidgetsBinding
                .instance
                .platformDispatcher
                .implicitView
                ?.viewInsets
                .bottom ??
            0) >
        0;

    if (!action.skipKeyboardDismissal && hasKeyboard) {
      FocusManager.instance.primaryFocus?.unfocus();
      _pendingNavigations.add(
        (action: action, samePageReplaceType: samePageReplaceType),
      );
      _pendingKeyboardObserver ??= _KeyboardDismissObserver(
        onDismissed: () {
          _pendingKeyboardObserver = null;
          final navigations = List.of(_pendingNavigations);
          _pendingNavigations.clear();
          for (final pending in navigations) {
            _performNavigation(
              pending.action,
              samePageReplaceType: pending.samePageReplaceType,
            );
          }
        },
      );

      return true;
    }

    return _performNavigation(action, samePageReplaceType: samePageReplaceType);
  }

  /// Presents a screen and awaits the result it returns via
  /// `Navigator.pop(context, result)`.
  ///
  /// Navigates with [action] and awaits its `dismissed` future, cast to
  /// `T?`. Resolves with `null` on a programmatic dismiss (e.g. a `Dismiss`
  /// action) or when the screen pops without a result. Declare `T` to match
  /// the type your screen pops with; a mismatch throws at await time.
  ///
  /// Requires `action.animated` (the default); a non-animated presentation
  /// does not wire a result.
  Future<T?> present<T>(Present action) {
    final didNavigate = navigate(action);

    // If the presentation was blocked (navigation callback, blocked dismiss),
    // no route is pushed and `Present.dismissed` would never complete. Resolve
    // with `null` immediately instead of awaiting a future that hangs.
    if (!didNavigate) {
      return Future<T?>.value();
    }

    return action.dismissed.then((result) => result as T?);
  }

  bool _performNavigation(
    NavigationType action, {
    required SamePageNavigationReplaceType samePageReplaceType,
  }) {
    final canNavigate = _canNavigateFromCurrentPage(action);
    if (!canNavigate) return false;

    // Check if dismiss is allowed
    if (action is Dismiss) {
      final allowed = _canDismissCurrentPage();
      if (!allowed) {
        return false;
      }
      // A Dismiss can carry a result value (e.g. `Dismiss(result: 'Red')`)
      // that resolves an in-flight `present<T>` on the presented screen.
      // Only complete when the dismiss will actually pop the top — a Dismiss
      // against a single-entry stack is a no-op (the screen stays visible), so
      // resolving `present` then would hand back a value for a screen that's
      // still showing.
      if (action.result != null && _resolvedNavigationStack.length > 1) {
        final top = _resolvedNavigationStack.lastOrNull;
        if (top is Present) {
          top.completeWith(action.result);
        }
      }
    }

    // Branch switch is handled out-of-band: it flips the active branch pointer
    // without modifying either branch's stack. An optional chained navigation
    // is then applied on the new branch.
    if (action is SwitchTab) {
      return _performSwitchTab(
        action,
        samePageReplaceType: samePageReplaceType,
      );
    }

    var effectiveAction = action;
    _setIgnoreRemovalForAction(effectiveAction);
    var newNavigationStack = _resolveNavigationStack(effectiveAction);

    // Apply same-page handling only for non-dismiss actions
    if (effectiveAction is! Dismiss) {
      final newAction = _samePageReplaceTypeAction(
        newNavigationStack,
        samePageReplaceType,
      );

      if (newAction != null) {
        effectiveAction = newAction;
        _setIgnoreRemovalForAction(effectiveAction);
        newNavigationStack = _resolveNavigationStack(effectiveAction);
      }
    }

    _commitNavigationStack(newNavigationStack, effectiveAction);

    _scheduleUserInitiatedNotify();

    _trackNavigationAnalytics(effectiveAction);

    return true;
  }

  /// Marks the current navigation as user-initiated, notifies listeners, and
  /// schedules the guard reset for the next frame. Shared by every navigation
  /// path so the guard/notify/reset sequencing is maintained in one place.
  void _scheduleUserInitiatedNotify() {
    _isPerformingUserInitiatedNavigation = true;
    notifyListeners();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _isPerformingUserInitiatedNavigation = false;
    });
  }

  /// Handles a [SwitchTab]: flips the active branch pointer and optionally
  /// applies a chained navigation on the new branch.
  ///
  /// Analytics:
  /// - A bare switch (no [SwitchTab.thenNavigate]) emits one exit(old top) →
  ///   enter(new branch top) transition.
  /// - A chained switch that succeeds emits no switch-level analytics — the
  ///   chained action's own transition (exit(old top) → enter(destination)) is
  ///   the sole record, so no phantom branch-root view is produced.
  /// - A chained switch that is blocked (per-page callback) still committed
  ///   the branch flip, so it emits the bare-switch transition (exit(old) →
  ///   enter(new branch top)) to keep analytics/screen-time aligned with the
  ///   now-visible branch.
  ///
  /// Per-branch stack restoration is intentionally out of scope — only the
  /// active branch pointer changes; each branch's stack is preserved as-is.
  bool _performSwitchTab(
    SwitchTab action, {
    required SamePageNavigationReplaceType samePageReplaceType,
  }) {
    final targetId = action.targetBranchId;
    if (!_branches.containsKey(targetId)) {
      assert(false, 'SwitchTab target branch not registered: $targetId');

      return false;
    }
    final thenNavigate = action.thenNavigate;
    // Same branch, nothing to chain → no-op.
    if (targetId == _activeBranchId && thenNavigate == null) {
      return true;
    }

    final previousScreenName = _currentScreenName;
    final branchChanged = targetId != _activeBranchId;

    if (branchChanged) {
      // Flip the pointer first so a chained action acts on the new branch's
      // stack.
      _activeBranchId = targetId;
      _scheduleUserInitiatedNotify();
    }

    if (thenNavigate case final chained?) {
      // _currentScreenName is still the old top, so the chained action emits
      // exit(old top) → enter(chained destination) — the only transition when
      // it succeeds.
      final didChain = _performNavigation(
        chained,
        samePageReplaceType: samePageReplaceType,
      );
      if (didChain || !branchChanged) {
        return didChain;
      }
      // The branch flipped but the chained action was blocked. Record the
      // transition to the new branch's top so analytics/screen-time match the
      // visible branch instead of the previous one.
      _emitSwitchTransition(previousScreenName, action);

      return false;
    }

    if (branchChanged) {
      _emitSwitchTransition(previousScreenName, action);
    }

    return true;
  }

  /// Emits the exit(old top) → enter(new active-branch top) transition for a
  /// [SwitchTab] and updates the current screen name, breadcrumb, and
  /// screen-time tracker. Used for bare switches and for chained switches
  /// whose chained action was blocked.
  void _emitSwitchTransition(String previousScreenName, SwitchTab action) {
    final newScreenName = _resolvedNavigationStack.last.screenName;
    _analyticsQueue?.enqueue(
      NavigationScreenExitEvent(
        screenName: previousScreenName,
        exitMethod: action.analyticsName,
        destinationScreen: newScreenName,
        timeSpent: _screenTimeTracker.recordScreenExit(previousScreenName),
      ),
    );
    _screenTimeTracker.recordScreenEnter(newScreenName);
    _analyticsQueue?.enqueue(
      NavigationScreenEnterEvent(
        screenName: newScreenName,
        sourceScreen: previousScreenName,
        navigationMethod: action.analyticsName,
        breadcrumb: _breadcrumb,
      ),
    );
    _currentScreenName = newScreenName;
    _breadcrumb += ' > ${action.analyticsName}:$newScreenName';
  }

  void _setIgnoreRemovalForAction(NavigationType navigationType) {
    if (navigationType is ReplaceStack) {
      _pagesToIgnoreRemoval = _resolvedNavigationStack
          .map((page) => page.screenName)
          .toSet();
    } else if (navigationType is ReplaceTop) {
      _pagesToIgnoreRemoval = {
        if (_resolvedNavigationStack.lastOrNull != null)
          _resolvedNavigationStack.last.screenName,
      };
    } else {
      _pagesToIgnoreRemoval = {};
    }
  }

  List<ViewNavigationType> _resolveNavigationStack(NavigationType action) {
    final newNavigationStack = List<NavigationType>.of(_resolvedNavigationStack)
      ..add(action);

    return newNavigationStack.fold<List<ViewNavigationType>>([], (acc, action) {
      return action.navigationStackFrom(acc);
    });
  }

  void _commitNavigationStack(
    List<ViewNavigationType> newNavigationStack,
    NavigationType action,
  ) {
    _resolvedNavigationStack
      ..clear()
      ..addAll(newNavigationStack);
    _breadcrumb += ' > ${_getBreadcrumbScreenName(action)}';
  }

  NavigationType? _samePageReplaceTypeAction(
    List<ViewNavigationType> newNavigationStack,
    SamePageNavigationReplaceType samePageReplaceType,
  ) {
    if (samePageReplaceType is SamePageNavigationNoReplace ||
        newNavigationStack.length < 2) {
      return null;
    }

    final currentPage = newNavigationStack.last;
    final previousPage = newNavigationStack[newNavigationStack.length - 2];
    if (currentPage.screenName != previousPage.screenName) {
      return null;
    }

    switch (samePageReplaceType) {
      case SamePageNavigationReplaceTop(:final animationType):
        return ReplaceTop(
          analyticsIdentifiable: AnalyticsIdentifiable(
            screenName: currentPage.screenName,
            builder: currentPage.builder,
          ),
          navigationKey: currentPage.key,
          animationType: animationType,
        );

      case SamePageNavigationCustomReplace():
        return samePageReplaceType.handler(currentPage);

      case SamePageNavigationNoReplace():
        return null; // Not reached
    }
  }

  String _getBreadcrumbScreenName(NavigationType navigation) {
    final typeName = navigation.analyticsName;
    if (navigation is PageNavigationType) {
      return '$typeName:${navigation.screenName}';
    }

    return typeName;
  }

  void _trackNavigationAnalytics(NavigationType action) {
    final queue = _analyticsQueue;
    if (queue == null) return;

    final navigationMethod = action.analyticsName;
    final newScreenName = _getScreenName(
      action is PageNavigationType ? action : _resolvedNavigationStack.last,
      navigationMethod,
    );
    queue.enqueue(
      NavigationScreenExitEvent(
        screenName: _currentScreenName,
        exitMethod: navigationMethod,
        destinationScreen: newScreenName,
        timeSpent: _screenTimeTracker.recordScreenExit(_currentScreenName),
      ),
    );
    _screenTimeTracker.recordScreenEnter(newScreenName);
    queue.enqueue(
      NavigationScreenEnterEvent(
        screenName: newScreenName,
        sourceScreen: _currentScreenName,
        navigationMethod: navigationMethod,
        breadcrumb: _breadcrumb,
      ),
    );
    _currentScreenName = newScreenName;
  }

  String _getScreenName(NavigationType navigation, String navigationMethod) {
    if (navigation is PageNavigationType) {
      return navigation.screenName;
    }

    return navigationMethod;
  }

  /// Removes the popped page if the navigation was not user initiated and
  /// there is a page to be removed.
  bool removePoppedPageIfNotUserInitiated(String? removedPageName) {
    // If this page was marked to ignore (from Replace), ignore it
    if (removedPageName != null &&
        _pagesToIgnoreRemoval.contains(removedPageName)) {
      _pagesToIgnoreRemoval.remove(removedPageName);

      return false;
    }

    if (_isPerformingUserInitiatedNavigation ||
        _resolvedNavigationStack.length < 2) {
      return false;
    }

    // Check if dismiss is allowed
    final allowed = _canDismissCurrentPage();
    if (!allowed) {
      return false;
    }

    // Add the action to keep breadcrumb navigation.
    // Do not notify listeners to prevent duplicated navigation.
    const dismissAction = Dismiss();
    final canNavigate = _canNavigateFromCurrentPage(dismissAction);
    if (!canNavigate) return false;
    _commitNavigationStack(
      _resolveNavigationStack(dismissAction),
      dismissAction,
    );
    _trackNavigationAnalytics(dismissAction);

    // When the system removes a page (e.g. tapping outside a modal bottom
    // sheet), we still need to notify listeners so UI and view models that
    // depend on navigation state can react. Schedule it post-frame to avoid
    // potential duplicated removals while `Navigator` is already processing.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    return true;
  }

  @override
  Future<void> dispose() async {
    _pendingKeyboardObserver?.removeObserver();
    _pendingKeyboardObserver = null;
    _pendingNavigations.clear();
    await _analyticsQueue?.flush();
    super.dispose();
  }

  /// Pushes a deep-link URI so that it is resolved by the route information
  /// parser and respects `requiredPriorNavigation`.
  ///
  /// Listeners pick this up and feed it through the standard route-parsing
  /// pipeline.
  void handleDeepLink(Uri uri) {
    _pendingDeepLinkUri = uri;
    notifyListeners();
  }

  /// Consumes the pending deep-link URI, if any.
  Uri? consumePendingDeepLink() {
    final uri = _pendingDeepLinkUri;
    _pendingDeepLinkUri = null;

    return uri;
  }

  /// Flushes pending analytics events. Only for testing.
  @visibleForTesting
  Future<void> flushAnalytics() async => _analyticsQueue?.flush();
}

/// Listens for [WidgetsBinding] metric changes and invokes [onDismissed]
/// once the keyboard view insets reach zero, then removes itself.
final class _KeyboardDismissObserver with WidgetsBindingObserver {
  _KeyboardDismissObserver({required this.onDismissed}) {
    WidgetsBinding.instance.addObserver(this);
  }

  final VoidCallback onDismissed;

  @override
  void didChangeMetrics() {
    final bottomInset =
        WidgetsBinding
            .instance
            .platformDispatcher
            .implicitView
            ?.viewInsets
            .bottom ??
        0;
    if (bottomInset > 0) return;

    removeObserver();

    // Schedule after the current frame so layout has settled.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      onDismissed();
    });
  }

  void removeObserver() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

/// Sentinel identity for the anonymous default branch. A private const
/// instance so app-supplied [NavigationBranchId]s can never collide with it.
final class _DefaultBranchId {
  const _DefaultBranchId();
}

/// Controller-internal metadata for a branch.
final class _BranchMetadata {
  const _BranchMetadata({
    required this.wantsKeepAlive,
    required this.screenName,
  });

  final bool wantsKeepAlive;
  final String screenName;
}
