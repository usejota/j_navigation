import 'package:j_navigation/src/custom_types/replace_animation_type.dart';
import 'package:j_navigation/src/navigation_type/navigation_type.dart';

sealed class SamePageNavigationReplaceType {}

final class SamePageNavigationReplaceTop
    implements SamePageNavigationReplaceType {
  const SamePageNavigationReplaceTop({
    this.animationType = const ReplaceAnimationTypeNone(),
  });

  final ReplaceAnimationType animationType;
}

final class SamePageNavigationNoReplace
    implements SamePageNavigationReplaceType {
  const SamePageNavigationNoReplace();
}

final class SamePageNavigationCustomReplace
    implements SamePageNavigationReplaceType {
  const SamePageNavigationCustomReplace({required this.handler});

  final NavigationType Function(ViewNavigationType) handler;
}
