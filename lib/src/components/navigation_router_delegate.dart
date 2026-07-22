import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:j_navigation/src/branch/navigation_branch.dart';
import 'package:j_navigation/src/branch/navigation_shell.dart';
import 'package:j_navigation/src/components/navigation_controller.dart';
import 'package:j_navigation/src/components/navigation_route_information_parser.dart';
import 'package:j_navigation/src/navigation_type/navigation_type.dart';
import 'package:j_navigation/src/theme/navigation_theme.dart';
import 'package:j_navigation/src/theme/navigation_theme_data.dart';

/// A router delegate for managing the navigation stack.
final class NavigationRouterDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  NavigationRouterDelegate(
    this._controller, {
    required this._routeInformationParser,
    List<NavigatorObserver>? observers,
    NavigationThemeData? theme,
    this.shellBuilder,
  }) : _observers = observers ?? const [],
       // ignore: prefer_initializing_formals, public param name differs from private field
       _theme = theme {
    _controller.addListener(_onNavigationStateChanged);
  }

  final NavigationController _controller;
  final NavigationRouteInformationParser _routeInformationParser;
  final List<NavigatorObserver> _observers;
  final NavigationThemeData? _theme;
  final NavigationShellBuilder? shellBuilder;
  RouteConfig? _pendingRouteConfig;
  bool _navigationScheduled = false;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Per-branch navigator keys, lazily created so each branch's [Navigator]
  /// keeps its own state across tab switches.
  final Map<NavigationBranchId, GlobalKey<NavigatorState>>
  _branchNavigatorKeys = {};

  GlobalKey<NavigatorState> _branchKey(NavigationBranchId id) =>
      _branchNavigatorKeys.putIfAbsent(id, GlobalKey<NavigatorState>.new);

  /// The key of the [Navigator] currently on stage.
  ///
  /// For single-stack controllers this is [navigatorKey]. For tabbed
  /// controllers it is the active branch's key — [navigatorKey] is unused in
  /// tabbed mode (each branch owns its own [Navigator]). Read this instead of
  /// [navigatorKey] when you need the live [NavigatorState] for programmatic
  /// push/pop or route inspection.
  GlobalKey<NavigatorState> get currentNavigatorKey => _controller.isTabbed
      ? _branchKey(_controller.activeBranchId)
      : navigatorKey;

  /// Current route configuration, reported to the [Router] so the browser
  /// address bar reflects navigation on web.
  ///
  /// Returns a [RouteConfig] describing the top-of-stack screen, or `null`
  /// when the stack is empty. See
  /// `NavigationRouteInformationParser.restoreRouteInformation` for the URL
  /// serialization.
  @override
  RouteConfig? get currentConfiguration {
    final stack = _controller.currentNavigationStack;
    if (stack.isEmpty) return null;
    return (
      requiredPriorNavigation: const <String>[],
      navigationType: stack.last,
      branchScreenName: _controller.isTabbed
          ? _controller.activeBranchScreenName
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isTabbed) {
      return _buildTabbed(context);
    }
    return _buildSingle(context);
  }

  Widget _buildSingle(BuildContext context) {
    final pages = _controller.currentNavigationStack
        .map((action) => action.buildPage(context))
        .toList();

    final navigator = Navigator(
      key: navigatorKey,
      pages: pages,
      observers: _observers,
      onDidRemovePage: (page) {
        _controller.removePoppedPageIfNotUserInitiated(page.name);
      },
    );

    return _wrapWithTheme(navigator);
  }

  /// Renders an [IndexedStack] of per-branch [Navigator]s. The active branch
  /// is on stage; off-stage branches with keep-alive off render
  /// [SizedBox.shrink] so their subtree is disposed and rebuilt on return.
  Widget _buildTabbed(BuildContext context) {
    final branchIds = _controller.branchIds;
    final activeIndex = branchIds.indexOf(_controller.activeBranchId);

    final stack = IndexedStack(
      index: activeIndex,
      children: [
        for (final id in branchIds) _buildBranchNavigator(context, id),
      ],
    );

    final shell = shellBuilder;
    if (shell == null) return _wrapWithTheme(stack);

    return _wrapWithTheme(
      Builder(
        builder: (context) => shell(
          context,
          stack,
          _controller.activeBranchId,
          activeIndex,
          (target) => _controller.navigate(SwitchTab(target)),
        ),
      ),
    );
  }

  Widget _buildBranchNavigator(
    BuildContext context,
    NavigationBranchId id,
  ) {
    final isActive = id == _controller.activeBranchId;
    if (!isActive && !_controller.wantsKeepAlive(id)) {
      return const SizedBox.shrink();
    }

    final pages = _controller
        .stackForBranch(id)
        .map((action) => action.buildPage(context))
        .toList();

    final navigator = Navigator(
      key: _branchKey(id),
      pages: pages,
      observers: _observers,
      onDidRemovePage: (page) {
        // Only the active branch's pops mutate the controller; off-stage
        // branches are not expected to pop while inactive.
        if (isActive) {
          _controller.removePoppedPageIfNotUserInitiated(page.name);
        }
      },
    );

    return navigator;
  }

  Widget _wrapWithTheme(Widget child) {
    final theme = _theme;
    if (theme == null) return child;
    return NavigationTheme(data: theme, child: child);
  }

  @override
  Future<bool> popRoute() {
    _controller.removePoppedPageIfNotUserInitiated(null);

    // Always return true to indicate we handled the pop request
    // This prevents the app from closing on Android
    return SynchronousFuture(true);
  }

  @override
  Future<void> setNewRoutePath(Object configuration) async {
    if (configuration is! RouteConfig) return;
    if (configuration.navigationType is! NavigationType) return;
    final routeConfig = configuration;

    if (_canApplyRouteConfig(routeConfig)) {
      _applyRouteConfig(routeConfig);

      return;
    }

    _pendingRouteConfig = routeConfig;
    _tryResolvePendingDeepLink();
  }

  void _onNavigationStateChanged() {
    final deepLinkUri = _controller.consumePendingDeepLink();
    if (deepLinkUri != null) {
      unawaited(_handleDeepLinkUri(deepLinkUri));
    }
    _tryResolvePendingDeepLink();
    notifyListeners();
  }

  Future<void> _handleDeepLinkUri(Uri uri) async {
    final configuration = await _routeInformationParser.parseRouteInformation(
      RouteInformation(uri: uri),
    );
    await setNewRoutePath(configuration);
  }

  bool _canApplyRouteConfig(RouteConfig routeConfig) {
    final required = routeConfig.requiredPriorNavigation;
    if (required.isEmpty) return true;

    return _controller.currentNavigationStack.any(
      (page) => required.contains(page.screenName),
    );
  }

  void _applyRouteConfig(RouteConfig routeConfig) {
    final navigationType = routeConfig.navigationType;
    if (navigationType is! NavigationType) return;

    // Always keep the latest route config pending until it is actually applied.
    // This prevents a newer deep link from being dropped when a navigation
    // post-frame callback is already scheduled.
    _pendingRouteConfig = routeConfig;

    // Avoid mutating navigation state while the router is still updating.
    if (_navigationScheduled) return;

    _navigationScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _navigationScheduled = false;

      final pending = _pendingRouteConfig;
      _pendingRouteConfig = null;
      if (pending == null) return;

      final pendingNavigationType = pending.navigationType;
      if (pendingNavigationType is! NavigationType) return;
      _controller.navigate(pendingNavigationType);
    });
  }

  void _tryResolvePendingDeepLink() {
    final pending = _pendingRouteConfig;
    if (pending == null) return;
    if (!_canApplyRouteConfig(pending)) return;

    _applyRouteConfig(pending);
  }

  @override
  void dispose() {
    _controller.removeListener(_onNavigationStateChanged);
    super.dispose();
  }
}
