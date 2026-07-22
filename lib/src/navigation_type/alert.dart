// ignore_for_file: avoid-dynamic

part of 'navigation_type.dart';

@immutable
final class AlertButton {
  const AlertButton({
    required this.title,
    this.onPressed,
    this.dismissAlert = true,
    this.isDestructive = false,
    this.isDefault = false,
  });

  static const AlertButton cancel = AlertButton(title: 'Cancelar');

  final String title;
  final VoidCallback? onPressed;

  /// If true, the alert will be dismissed before calling [onPressed].
  final bool dismissAlert;

  /// iOS only: marks the action as destructive.
  final bool isDestructive;

  /// iOS only: marks the action as the default action.
  final bool isDefault;
}

/// A navigation type that presents a system alert dialog.
final class Alert extends ViewNavigationType {
  Alert({
    required this.title,
    required this.buttons,
    required String analyticsScreenName,
    this.description,
    this.barrierDismissible = true,
    super.skipKeyboardDismissal,
    super.navigationKey,
  }) : super(
         analyticsIdentifiable: AnalyticsIdentifiable(
           screenName: analyticsScreenName,
           // Not used; [buildAnimatedPage] builds the dialog directly.
           builder: (_) => const SizedBox.shrink(),
         ),
       );

  final String title;
  final String? description;
  final bool barrierDismissible;
  final List<AlertButton> buttons;

  @override
  String get analyticsName => 'Alert';

  @override
  List<ViewNavigationType> navigationStackFrom(
    List<ViewNavigationType> currentStack,
  ) {
    return [...currentStack, this];
  }

  @override
  Page<dynamic> buildAnimatedPage(BuildContext context) {
    return AlertDialogPage<dynamic>(
      key: key,
      name: screenName,
      title: title,
      description: description,
      barrierDismissible: barrierDismissible,
      actionsBuilder: (dialogContext) {
        final platform = Theme.of(dialogContext).platform;
        final isCupertino = platform == TargetPlatform.iOS;

        return buttons
            .map((button) {
              void handlePressed() {
                if (button.dismissAlert) {
                  Navigator.of(dialogContext, rootNavigator: true).pop();
                }
                button.onPressed?.call();
              }

              if (isCupertino) {
                return CupertinoDialogAction(
                  onPressed: handlePressed,
                  isDefaultAction: button.isDefault,
                  isDestructiveAction: button.isDestructive,
                  child: Text(button.title),
                );
              }

              return TextButton(
                onPressed: handlePressed,
                child: Text(button.title),
              );
            })
            .toList(growable: false);
      },
    );
  }
}
