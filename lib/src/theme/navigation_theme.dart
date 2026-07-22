import 'package:flutter/widgets.dart';

import 'package:j_navigation/src/theme/navigation_theme_data.dart';

/// Makes a [NavigationThemeData] available to descendant navigation pages.
///
/// `NavigationConfig` injects this above its `Navigator` when a `theme` is
/// supplied to it. Host apps may also wrap subtrees directly to override the
/// theme per-screen:
///
/// ```dart
/// NavigationTheme(
///   data: NavigationThemeData(scrimColor: Colors.black87),
///   child: MyApp(),
/// );
/// ```
class NavigationTheme extends InheritedWidget {
  /// Creates a navigation theme provider.
  const NavigationTheme({
    required this.data,
    required super.child,
    super.key,
  });

  /// The navigation theme data exposed to descendants.
  final NavigationThemeData data;

  /// The [NavigationThemeData] for [context].
  ///
  /// Returns Material defaults when no [NavigationTheme] is present in the
  /// tree above [context], so navigation pages always render with valid
  /// colors even in an unconfigured app.
  static NavigationThemeData of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<NavigationTheme>();
    return inherited?.data ?? const NavigationThemeData();
  }

  @override
  bool updateShouldNotify(covariant NavigationTheme oldWidget) =>
      data != oldWidget.data;
}
