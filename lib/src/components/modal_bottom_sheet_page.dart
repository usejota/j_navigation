// ignore_for_file: avoid-dynamic

import 'package:flutter/material.dart';

import 'package:j_navigation/src/theme/navigation_theme.dart';

final class ModalBottomSheetPage<T> extends Page<T> {
  const ModalBottomSheetPage({
    required this.child,
    required this.isScrollControlled,
    required this.isDismissible,
    required this.enableDrag,
    super.key,
    super.name,
    super.arguments,
  });

  final Widget child;
  final bool isScrollControlled;
  final bool isDismissible;
  final bool enableDrag;

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute<T>(
      settings: this,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      modalBarrierColor: NavigationTheme.of(context).scrimColor,
      builder: (_) => child,
    );
  }
}
