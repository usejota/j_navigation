import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:j_navigation/src/navigation_type/navigation_type.dart';

// Interface for feature providers
abstract interface class FeatureProvider {
  FutureOr<FeatureRoute?> featureRouteFor(String featureName);
}

// Route interface for features
abstract interface class FeatureRoute {
  List<String> get piorNavigationRequired;

  FutureOr<NavigationType>? navigationFor({
    required Map<String, String> parameters,
    String? screenName,
  });
}

typedef RouteConfig = ({
  List<String> requiredPriorNavigation,
  Object navigationType,
  // The active branch's screen name, used to serialize the active branch in
  // the web URL (`/<branchScreen>/<topScreen>`). `null` for single-stack
  // (non-tabbed) controllers or parsed deep-links that don't carry branch info.
  String? branchScreenName,
});

/// Returned when a route can't be parsed into a [NavigationType].
final class _NoNavigationConfiguration {
  const _NoNavigationConfiguration();
}

final class NavigationRouteInformationParser
    extends RouteInformationParser<Object> {
  NavigationRouteInformationParser({
    this._featureProvider,
  });

  /// Resolves deep-link feature routes. When `null`, deep-link URIs resolve
  /// to no navigation — apps that don't need deep linking can omit it.
  final FeatureProvider? _featureProvider;
  static const _noNavigation = _NoNavigationConfiguration();

  @override
  Future<Object> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final segments = routeInformation.uri.pathSegments;
    if (segments.isEmpty) {
      return SynchronousFuture(
        const (
          requiredPriorNavigation: <String>[],
          navigationType: _noNavigation,
          branchScreenName: null,
        ),
      );
    }

    final featureName = segments.first;
    final provider = _featureProvider;
    if (provider == null) {
      return SynchronousFuture(
        const (
          requiredPriorNavigation: <String>[],
          navigationType: _noNavigation,
          branchScreenName: null,
        ),
      );
    }
    final featureRoute = await provider.featureRouteFor(featureName);
    if (featureRoute == null) {
      return SynchronousFuture(
        const (
          requiredPriorNavigation: <String>[],
          navigationType: _noNavigation,
          branchScreenName: null,
        ),
      );
    }

    final featureParameters = routeInformation.uri.queryParameters;
    final featurePage = await featureRoute.navigationFor(
      parameters: featureParameters,
      screenName: segments.length > 1 ? segments[1] : null,
    );
    if (featurePage == null) {
      return SynchronousFuture(
        const (
          requiredPriorNavigation: <String>[],
          navigationType: _noNavigation,
          branchScreenName: null,
        ),
      );
    }

    return SynchronousFuture((
      requiredPriorNavigation: featureRoute.piorNavigationRequired,
      navigationType: featurePage,
      branchScreenName: null,
    ));
  }

  /// Restores the browser route information from the current configuration.
  ///
  /// The URL path reflects the top-of-stack screen's `screenName`. Screens the
  /// host's [FeatureProvider] recognizes round-trip fully (URL → navigation →
  /// URL); screens pushed programmatically reflect in the address bar but, on
  /// reload, resolve to no navigation unless the host also maps that screen
  /// name to a [FeatureRoute].
  /// Restores the browser route information from the current configuration.
  ///
  /// For single-stack controllers the URL path is `/<topScreen>`. For tabbed
  /// controllers the active branch's screen name is prepended:
  /// `/<branchScreen>/<topScreen>`.
  ///
  /// Per-branch stack restoration is out of scope — only the active branch is
  /// encoded. Screens the host's [FeatureProvider] recognizes round-trip fully
  /// (URL → navigation → URL); screens pushed programmatically reflect in the
  /// address bar but, on reload, resolve to no navigation unless the host also
  /// maps that screen name to a [FeatureRoute].
  @override
  RouteInformation? restoreRouteInformation(Object configuration) {
    if (configuration is! RouteConfig) return null;
    final navigationType = configuration.navigationType;
    if (navigationType is! ViewNavigationType) return null;
    final screenName = navigationType.analyticsIdentifiable.screenName;
    if (screenName.isEmpty) return null;

    final branchScreenName = configuration.branchScreenName;
    if (branchScreenName != null && branchScreenName.isNotEmpty) {
      // Pass raw segment values: [Uri] percent-encodes each path segment
      // itself, so pre-encoding with [Uri.encodeComponent] would double-escape
      // (e.g. a space -> `%20` -> `%2520`).
      return RouteInformation(
        uri: Uri(pathSegments: <String>[branchScreenName, screenName]),
      );
    }
    return RouteInformation(
      uri: Uri(pathSegments: <String>[screenName]),
    );
  }
}
