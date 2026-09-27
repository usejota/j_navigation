import 'package:flutter/widgets.dart';

/// Marks the single-stack Navigator; RootPopScope is inert without it
/// (tabbed mode).
final class SingleStackScope extends InheritedWidget {
  const SingleStackScope({required super.child, super.key});
  static bool isSingleStack(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SingleStackScope>() != null;
  @override
  bool updateShouldNotify(SingleStackScope old) => false;
}

/// Blocks OS-level pop on the bottom route so Flutter keeps canHandlePop=true
/// at a 1-page stack (predictive back). Back still reaches popRoute.
final class RootPopScope extends StatelessWidget {
  const RootPopScope({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (!SingleStackScope.isSingleStack(context)) return child;
    return PopScope(
      canPop: !(ModalRoute.isFirstOf(context) ?? false),
      child: child,
    );
  }
}
