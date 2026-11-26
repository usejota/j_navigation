import 'package:material_ui/material_ui.dart';

class NoAnimationPage<T> extends Page<T> {
  const new({required this.child, super.key, super.name, super.arguments});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (_, _, _) => child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}
