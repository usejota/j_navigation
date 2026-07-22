// ignore_for_file: avoid-dynamic

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:j_navigation/src/theme/navigation_theme.dart';

/// A [Page] that presents a system-style alert dialog.
///
/// This uses a dialog [Route] so it behaves like a system alert (modal),
/// while still participating in the declarative navigation stack.
final class AlertDialogPage<T> extends Page<T> {
  const AlertDialogPage({
    required this.title,
    required this.actionsBuilder,
    this.description,
    this.barrierDismissible = true,
    super.key,
    super.name,
    super.arguments,
  });

  final String title;
  final String? description;
  final bool barrierDismissible;
  final List<Widget> Function(BuildContext dialogContext) actionsBuilder;

  @override
  Route<T> createRoute(BuildContext context) {
    return DialogRoute<T>(
      context: context,
      settings: this,
      barrierDismissible: barrierDismissible,
      barrierColor: NavigationTheme.of(context).scrimColor,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      builder: (dialogContext) {
        final platform = Theme.of(dialogContext).platform;
        final isCupertino = platform == TargetPlatform.iOS;
        final actions = actionsBuilder(dialogContext);

        if (isCupertino) {
          final cupertinoTheme = CupertinoTheme.of(dialogContext);
          final description = this.description;

          return CupertinoTheme(
            data: cupertinoTheme.copyWith(
              primaryColor: NavigationTheme.of(
                dialogContext,
              ).cupertinoPrimaryColor,
            ),
            child: CupertinoAlertDialog(
              title: Text(title),
              content: description == null ? null : Text(description),
              actions: actions,
            ),
          );
        }

        return AlertDialog(
          title: Text(title),
          content: description == null ? null : Text(description!),
          actions: actions,
        );
      },
    );
  }
}
