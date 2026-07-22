import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:j_navigation/src/branch/navigation_shell.dart';
import 'package:j_navigation/src/components/navigation_controller.dart';
import 'package:j_navigation/src/components/navigation_route_information_parser.dart';
import 'package:j_navigation/src/components/navigation_router_delegate.dart';
import 'package:j_navigation/src/theme/navigation_theme_data.dart';

/// A configuration for the navigation system.
final class NavigationConfig extends RouterConfig<Object> {
  NavigationConfig({
    required NavigationController controller,
    FeatureProvider? featureProvider,
    List<NavigatorObserver>? observers,
    NavigationThemeData? theme,
    NavigationShellBuilder? shellBuilder,
  }) : this._(
         controller: controller,
         parser: NavigationRouteInformationParser(
           featureProvider: featureProvider,
         ),
         observers: observers,
         theme: theme,
         shellBuilder: shellBuilder,
       );

  NavigationConfig._({
    required NavigationController controller,
    required NavigationRouteInformationParser parser,
    List<NavigatorObserver>? observers,
    this.theme,
    this.shellBuilder,
  }) : super(
         routerDelegate: NavigationRouterDelegate(
           controller,
           routeInformationParser: parser,
           observers: observers,
           theme: theme,
           shellBuilder: shellBuilder,
         ),
         routeInformationParser: parser,
         routeInformationProvider: PlatformRouteInformationProvider(
           // On Android cold start, the deep link URI from the intent is
           // only available via [PlatformDispatcher.defaultRouteName] — it
           // is not delivered as a subsequent pushRoute system message like
           // on iOS. Parse defensively: a malformed platform route string
           // must never crash app startup.
           initialRouteInformation: RouteInformation(
             uri: _tryParseUri(PlatformDispatcher.instance.defaultRouteName),
           ),
         ),
         backButtonDispatcher: RootBackButtonDispatcher(),
       );

  /// Theme applied to navigation-presented UI (dialogs, bottom sheets).
  ///
  /// When `null`, pages fall back to a NavigationTheme ancestor in the
  /// widget tree, or the Material defaults if none is present.
  final NavigationThemeData? theme;

  /// Builds the shell (e.g. bottom navigation bar) around the branch content
  /// swap when the controller is tabbed. Ignored for single-stack controllers.
  final NavigationShellBuilder? shellBuilder;
}

/// Parses [value] as a [Uri], returning `Uri.parse('/')` when the platform
/// route string is malformed — so a bad cold-start deep link never crashes
/// the app.
Uri _tryParseUri(String value) {
  try {
    return Uri.parse(value);
  } on FormatException {
    return Uri.parse('/');
  }
}
