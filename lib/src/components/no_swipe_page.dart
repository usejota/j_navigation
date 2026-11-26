import 'package:cupertino_ui/cupertino_ui.dart';

class NoSwipePage<T> extends Page<T> {
  const new({required this.child, super.name, super.key});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (_, _, _) => child,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        return CupertinoPageTransition(
          primaryRouteAnimation: animation,
          secondaryRouteAnimation: secondaryAnimation,
          linearTransition: false,
          child: child,
        );
      },
    );
  }
}
