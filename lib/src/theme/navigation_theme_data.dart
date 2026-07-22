import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Colors used by navigation-presented UI (alerts, modal bottom sheets).
///
/// Supply a customized instance to `NavigationConfig` via its `theme`
/// parameter, or expose one to the widget tree via the `NavigationTheme`
/// inherited widget. Fields default to the Material defaults, so an
/// unconfigured package still renders with standard colors.
@immutable
class NavigationThemeData {
  /// Creates navigation theme data.
  ///
  /// Every field has a Material default; pass only the colors you want to
  /// override.
  const NavigationThemeData({
    this.scrimColor = Colors.black54,
    this.cupertinoPrimaryColor = CupertinoColors.activeBlue,
  });

  /// Color of the modal barrier drawn behind dialogs and bottom sheets.
  final Color scrimColor;

  /// Accent used for the primary action in Cupertino-style alerts.
  final Color cupertinoPrimaryColor;

  @override
  bool operator ==(Object other) =>
      other is NavigationThemeData &&
      other.scrimColor == scrimColor &&
      other.cupertinoPrimaryColor == cupertinoPrimaryColor;

  @override
  int get hashCode => Object.hash(scrimColor, cupertinoPrimaryColor);
}
